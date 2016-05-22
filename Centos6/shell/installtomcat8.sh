#!/bin/sh

# 二进制安装
# Tomcat8官方稳定版
# 确保关闭SELinux

### bin包名，请根据实际情况修改
tomcat_name=apache-tomcat-8.0.33

### 可自定义信息，但是不建议修改
# tomcat安装位置/opt/tomcat8，链接到/usr/local/tomcat8
tomcat_install_dir=/usr/local/tomcat8
tomcat_install_dir_real=/opt/tomcat8
# 运行用户
run_user=tomcat
# 站点根目录
tomcat_web_dir=/data/tomcatwebroot/default
# tomcat运行日志位置
tomcat_log_dir=/data/tomcatlog
# tomcat Host网站访问日志位置
tomcat_weblog_dir=/data/tomcatweblog

# 创建用户
useradd -M -s /bin/bash $run_user 
# 创建相关目录，并授权
mkdir -p $tomcat_install_dir_real $tomcat_web_dir $tomcat_log_dir $tomcat_weblog_dir
chown -R $run_user.$run_user $tomcat_install_dir_real $tomcat_web_dir $tomcat_log_dir $tomcat_weblog_dir
# 链接安装目录
ln -s $tomcat_install_dir_real $tomcat_install_dir

# 将tomcat二进制包解压到指定路径
tar xzf bin/$tomcat_name.tar.gz
cp -rf $tomcat_name/* $tomcat_install_dir
rm -rf $tomcat_name

### server.xml：Tomcat配置文件
# 备份server.xml，记录tomcat安装路径
cp $tomcat_install_dir/conf/server.xml{,_bk} -n
### 使用config/server.xml提供的模板
# 修改默认编码为UTF-8
# 配置默认虚拟主机分离
cp -f config/server.xml $tomcat_install_dir/conf
# 配置默认虚拟主机，访问日志
[ ! -d "$tomcat_install_dir/conf/vhost" ] && mkdir $tomcat_install_dir/conf/vhost
cat > $tomcat_install_dir/conf/vhost/localhost.xml << EOF
<Host name="localhost" appBase="webapps" unpackWARs="true" autoDeploy="true">
  <Context path="" docBase="$tomcat_web_dir" debug="0" reloadable="false" crossContext="true"/>
  <Valve className="org.apache.catalina.valves.AccessLogValve" directory="$tomcat_weblog_dir" 
         prefix="localhost_access_log." suffix=".txt" pattern="%h %l %u %t &quot;%r&quot; %s %b" />
</Host>
EOF
# 修改虚拟主机vhost路径
sed -i "s@/usr/local/tomcat@$tomcat_install_dir@g" $tomcat_install_dir/conf/server.xml

# 访问日志迁移
sed -i "s@directory=\"logs\"@directory=\"$tomcat_weblog_dir\"@g" $tomcat_install_dir/conf/server.xml

# 运行日志和管理日志迁移
cp $tomcat_install_dir/bin/catalina.sh{,_bk} -n
sed -i "s@\"\$CATALINA_BASE\"/logs/catalina.out@$tomcat_log_dir/catalina.out@" $tomcat_install_dir/bin/catalina.sh
cp $tomcat_install_dir/conf/logging.properties{,_bk} -n
sed -i "s@\${catalina.base}/logs@$tomcat_log_dir@" $tomcat_install_dir/conf/logging.properties

### Tomcat Connector的三种不同的运行模式
# ■ BIO：
# 一个线程处理一个请求。
# 缺点：并发量高时，线程数较多，浪费资源。
# Tomcat7或以下，在Linux系统中默认使用这种方式。
# ■ NIO：
# 利用Java的异步IO处理，可以通过少量的线程处理大量的请求。
# Tomcat8在Linux系统中默认使用这种方式。
# Tomcat7必须修改Connector配置来启动.
# ■ APR：
# 即Apache Portable Runtime，从操作系统层面解决io阻塞问题。
# Linux如果安装了apr和native，Tomcat 7/8都直接支持启动apr。

# 安装 tomcat-native依赖库apr apr-devel apr-util
# yum安装的版本太低，必须源码编译安装
# yum -y install apr apr-devel apr-util openssl-devel

# 源码安装 apr
apr_version=1.5.2
tar xzf src/apr-$apr_version.tar.gz
cd apr-$apr_version
./configure
make && make install
cd ..
rm -rf apr-$apr_version

# 源码安装 apr_util
apr_util_version=1.5.4
tar xzf src/apr-util-$apr_util_version.tar.gz
cd apr-util-$apr_util_version
./configure \
--with-apr=/usr/local/apr/bin/apr-1-config
make && make install
cd ..
rm -rf apr-util-$apr_util_version

# 源码安装 openssl
# 默认安装到/usr/local/ssl
openssl_version=1.0.2h
tar xzf src/openssl-$openssl_version.tar.gz
cd openssl-$openssl_version
export CFLAGS="-fPIC"
./config shared no-ssl2 no-ssl3 --openssldir=/usr/local/ssl
make depend
make all
make install
cd ..
rm -rf openssl-$openssl_version

# 源码编译安装tomcat-native
# 安装帮助文档：http://tomcat.apache.org/native-doc/
# 注意：tomcat 7和8编译文件深度不一样
tar xzf $tomcat_install_dir/bin/tomcat-native.tar.gz 
cd tomcat-native-*-src/native/
./configure \
--with-apr=/usr/local/apr/bin/apr-1-config \
--with-ssl=/usr/local/ssl 
make && make install
cd ../..
rm -rf tomcat-native-*-src

### 优化tomcat，并启用apr模式
# 以上几个apr相关的lib文件全部安装到了/usr/local/apr/lib
# 创建环境变量，tomcat启动程序自动调用setenv.sh
Mem=`free -m | awk '/Mem:/{print $2}'`
[ $Mem -le 768 ] && Xms_Mem=`expr $Mem / 3` || Xms_Mem=256
cat > $tomcat_install_dir/bin/setenv.sh << EOF
JAVA_OPTS='-Djava.security.egd=file:/dev/./urandom -server -Xms${Xms_Mem}m -Xmx`expr $Mem / 2`m'
CATALINA_OPTS="-Djava.library.path=/usr/local/apr/lib"
EOF

# 源码编译安装commons-daemon，生成jsvc
# 让tomcat服务以$run_user身份运行，否则是以root身份运行
tar zxf $tomcat_install_dir/bin/commons-daemon-native.tar.gz
cd commons-daemon-*-native-src/unix/
./configure
make
cp jsvc $tomcat_install_dir/bin -f 
cd ../..
rm -rf commons-daemon-*-native-src

# 自启动服务设置
cp -f init.d/tomcat-init /etc/init.d/tomcat
sed -i "s@^CATALINA_HOME=.*@CATALINA_HOME=$tomcat_install_dir@" /etc/init.d/tomcat
sed -i "s@^TOMCAT_USER=.*@TOMCAT_USER=$run_user@" /etc/init.d/tomcat
chmod +x /etc/init.d/tomcat
chkconfig --add tomcat
chkconfig tomcat on

# 日志轮转
# tomcat自己维护日志系统，跳过

# 修正配置文件修改后无法读取的Bug
chown -R $run_user.$run_user $tomcat_install_dir_real $tomcat_web_dir $tomcat_log_dir $tomcat_weblog_dir
# 说明：Tomcat 权限设置非常严格，修改配置文件后，非root身份运行脚本无法读取配置文件。

# 编译软件后建议加载一次
ldconfig
service tomcat start
echo "Tomcat install successfully! "
$tomcat_install_dir/bin/version.sh

# Nginx 中启用tomcat
[ -z "`grep 'location ~ \\\.jsp' /etc/nginx/nginx.conf`" ] &&  sed -i "s@index index.html index.php;@index index.html index.php index.jsp;\n\n    location ~ \\\.jsp$ {\n        index index.jsp index.html;\n        proxy_pass http://localhost:8080;\n        }@" /etc/nginx/nginx.conf

service nginx restart

# 创建测试页面
echo "This is my JSP page." > $tomcat_web_dir/index.jsp

#!/bin/sh

# 官方源代码安装方式
# php5.6官方stable版
# 确保关闭SELinux
# 因版权问题，部分依赖库必须源码编译，如果这些库升级，必须调整脚本

### rpm/src包名，请根据实际情况修改
# php请下tar.gz版
php_version=5.6.21

### 可自定义信息，但是不建议修改
# php安装位置/opt/php6，链接到/usr/local/php6
php_install_dir=/usr/local/php6
php_install_dir_real=/opt/php6
# php和php-fpm日志位置，相对路径指的是安装目录var/，建议以下设置
php_log_dir=/data/phplog
php_log=${php_log_dir}/php_errors.log
php_fpm_log=${php_log_dir}/php-fpm.log
# 站点根目录及访问日志
php_web_dir=/data/phpwebroot/default
php_weblog_dir=/data/phpweblog

# PHP-FPM 进程运行账号，如果Nginx，Apache作为服务器，可以考虑统一
run_user=php
useradd -M -s /sbin/nologin $run_user 

# 创建php目录
mkdir -p $php_install_dir_real
ln -s $php_install_dir_real $php_install_dir
mkdir -p $php_log_dir
mkdir -p $php_web_dir
mkdir -p $php_weblog_dir

# 读取系统参数
Mem=`free -m | awk '/Mem:/{print $2}'`
if [ $Mem -le 640 ];then
    Mem_level=512M
    Memory_limit=64
elif [ $Mem -gt 640 -a $Mem -le 1280 ];then
    Mem_level=1G
    Memory_limit=128
elif [ $Mem -gt 1280 -a $Mem -le 2500 ];then
    Mem_level=2G
    Memory_limit=192
elif [ $Mem -gt 2500 -a $Mem -le 3500 ];then
    Mem_level=3G
    Memory_limit=256
elif [ $Mem -gt 3500 -a $Mem -le 4500 ];then
    Mem_level=4G
    Memory_limit=320
elif [ $Mem -gt 4500 -a $Mem -le 8000 ];then
    Mem_level=6G
    Memory_limit=384
elif [ $Mem -gt 8000 ];then
    Mem_level=8G
    Memory_limit=448
fi

### 安装必要的依赖库，因版权问题必须编译源码安装
# libiconv为需要做转换的应用提供了一个iconv()的函数，以实现一个字符编码到另一个字符编码的转换
libiconv_version=1.14
tar xzf src/libiconv-$libiconv_version.tar.gz
patch -d libiconv-$libiconv_version -p0 < src/libiconv-glibc-2.16.patch
cd libiconv-$libiconv_version
./configure --prefix=/usr/local
make && make install
cd ..
rm -rf libiconv-$libiconv_version

# libmcrypt是加密算法扩展库。支持DES,3DES,RIJNDAEL,Twofish,IDEA,GOST,CAST-256,ARCFOUR,SERPENT,SAFER+等算法。
libmcrypt_version=2.5.8
tar xzf src/libmcrypt-$libmcrypt_version.tar.gz
cd libmcrypt-$libmcrypt_version
./configure
make && make install
ldconfig
cd libltdl
./configure --enable-ltdl-install
make && make install
cd ../../
rm -rf libmcrypt-$libmcrypt_version

# mhash是基于离散数学原理的不可逆向的php加密方式扩展库，mhash可以用于创建校验数值，消息摘要，消息认证码，以及无需原文的关键信息保存（如密码）等。
mhash_version=0.9.9.9
tar xzf src/mhash-$mhash_version.tar.gz
cd mhash-$mhash_version
./configure
make && make install
cd ..
rm -rf mhash-$mhash_version

# lib全局可认
echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf
ldconfig
ln -s /usr/local/bin/libmcrypt-config /usr/bin/libmcrypt-config
ln -s /lib64/libpcre.so.0.0.1 /lib64/libpcre.so.1

# mcrypt是php里面重要的加密扩展库
mcrypt_version=2.6.8
tar xzf src/mcrypt-$mcrypt_version.tar.gz
cd mcrypt-$mcrypt_version
ldconfig
./configure
make && make install
cd ..
rm -rf mcrypt-$mcrypt_version

# 正式安装php

tar zxf src/php-$php_version.tar.gz
cd php-$php_version
make clean
./buildconf
PHP_cache_tmp='--enable-opcache'

./configure \
--prefix=$php_install_dir \
--with-config-file-path=$php_install_dir/etc \
--with-config-file-scan-dir=$php_install_dir/etc/php.d \
--with-fpm-user=$run_user \
--with-fpm-group=$run_user \
--enable-fpm $PHP_cache_tmp \
--disable-fileinfo \
--enable-mysqlnd \
--with-mysqli=mysqlnd \
--with-pdo-mysql=mysqlnd \
--with-iconv-dir=/usr/local \
--with-freetype-dir \
--with-jpeg-dir \
--with-png-dir \
--with-zlib \
--with-libxml-dir=/usr \
--enable-xml \
--disable-rpath \
--enable-bcmath \
--enable-shmop \
--enable-exif \
--enable-sysvsem \
--enable-inline-optimization \
--with-curl \
--enable-mbregex \
--enable-inline-optimization \
--enable-mbstring \
--with-mcrypt \
--with-gd \
--enable-gd-native-ttf \
--with-openssl \
--with-mhash \
--enable-pcntl \
--enable-sockets \
--with-xmlrpc \
--enable-ftp \
--enable-intl \
--with-xsl \
--with-gettext \
--enable-zip \
--enable-soap \
--disable-ipv6 \
--disable-debug

make ZEND_EXTRA_LIBS='-liconv'
make install

if [ -e "$php_install_dir/bin/phpize" ];then
    echo "PHP install successfully!"
else
    rm -rf $php_install_dir
    echo "PHP install failed, Please Contact the author! "
    kill -9 $$
fi

# 配置PHP环境变量
[ -z "`grep ^'export PATH=' /etc/profile`" ] && echo "export PATH=$php_install_dir/bin:\$PATH" >> /etc/profile 
[ -n "`grep ^'export PATH=' /etc/profile`" -a -z "`grep $php_install_dir /etc/profile`" ] && sed -i "s@^export PATH=\(.*\)@export PATH=$php_install_dir/bin:\1@" /etc/profile
. /etc/profile

# 生成php.ini文件
[ ! -e "$php_install_dir/etc/php.d" ] && mkdir -p $php_install_dir/etc/php.d
cp php.ini-production $php_install_dir/etc/php.ini
# 说明：php.ini-development适合开发测试，如本地测试环境， php.ini-production拥有较高的安全性设定，适合服务器上线运营。

# php优化，php.ini
sed -i "s@^memory_limit.*@memory_limit = ${Memory_limit}M@" $php_install_dir/etc/php.ini
sed -i 's@^output_buffering =@output_buffering = On\noutput_buffering =@' $php_install_dir/etc/php.ini
sed -i 's@^;cgi.fix_pathinfo.*@cgi.fix_pathinfo=0@' $php_install_dir/etc/php.ini
sed -i 's@^short_open_tag = Off@short_open_tag = On@' $php_install_dir/etc/php.ini
sed -i 's@^expose_php = On@expose_php = Off@' $php_install_dir/etc/php.ini
sed -i 's@^request_order.*@request_order = "CGP"@' $php_install_dir/etc/php.ini
sed -i 's@^;date.timezone.*@date.timezone = Asia/Shanghai@' $php_install_dir/etc/php.ini
sed -i 's@^post_max_size.*@post_max_size = 100M@' $php_install_dir/etc/php.ini
sed -i 's@^upload_max_filesize.*@upload_max_filesize = 50M@' $php_install_dir/etc/php.ini
sed -i 's@^max_execution_time.*@max_execution_time = 600@' $php_install_dir/etc/php.ini
sed -i 's@^;realpath_cache_size.*@realpath_cache_size = 2M@' $php_install_dir/etc/php.ini
sed -i 's@^disable_functions.*@disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,fsocket,popen@' $php_install_dir/etc/php.ini
# 设置日志路径
[ -z "`grep '^error_log.*' $php_install_dir/etc/php.ini`"] && 
sed -i "s@^\(;error_log.*php_errors.log.*\)@\1\nerror_log = ${php_log}/@" $php_install_dir/etc/php.ini || sed -i "s@^error_log.*@error_log = ${php_log}/@" $php_install_dir/etc/php.ini
# 关联邮件服务
[ -e /usr/sbin/sendmail ] && sed -i 's@^;sendmail_path.*@sendmail_path = /usr/sbin/sendmail -t -i@' $php_install_dir/etc/php.ini

# 配置opcache，代码缓存加速
#opcache是代码缓存,比如一个页面有多个include文件,他会合并成一个文件作为缓存,减少服务器的io操作,加载更快
cat > $php_install_dir/etc/php.d/ext-opcache.ini << EOF
[opcache]
zend_extension=opcache.so
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=$Memory_limit
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=100000
opcache.max_wasted_percentage=5
opcache.use_cwd=1
opcache.validate_timestamps=1
opcache.revalidate_freq=60
opcache.save_comments=0
opcache.fast_shutdown=1
opcache.consistency_checks=0
;opcache.optimization_level=0
EOF

# php-fpm初始化脚本
cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm -f
chmod +x /etc/init.d/php-fpm
chkconfig --add php-fpm
chkconfig php-fpm on

# 编写php-fpm.conf配置文件
cat > $php_install_dir/etc/php-fpm.conf <<EOF
;;;;;;;;;;;;;;;;;;;;;
; FPM Configuration ;
;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;
; Global Options ;
;;;;;;;;;;;;;;;;;;

[global]
pid = run/php-fpm.pid
error_log = ${php_log_dir}/php-fpm.log
log_level = warning 

emergency_restart_threshold = 30
emergency_restart_interval = 60s 
process_control_timeout = 5s
daemonize = yes

;;;;;;;;;;;;;;;;;;;;
; Pool Definitions ;
;;;;;;;;;;;;;;;;;;;;

[$run_user]
listen = /dev/shm/php-cgi.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = $run_user 
listen.group = $run_user 
listen.mode = 0666
user = $run_user 
group = $run_user 

pm = dynamic
pm.max_children = 12 
pm.start_servers = 8 
pm.min_spare_servers = 6 
pm.max_spare_servers = 12
pm.max_requests = 2048
pm.process_idle_timeout = 10s
request_terminate_timeout = 120
request_slowlog_timeout = 0

pm.status_path = /php-fpm_status
slowlog = log/slow.log
rlimit_files = 51200
rlimit_core = 0

;open log output
catch_workers_output = yes
;env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
EOF

if [ $Mem -le 3000 ];then
    sed -i "s@^pm.max_children.*@pm.max_children = $(($Mem/3/20))@" $php_install_dir/etc/php-fpm.conf
    sed -i "s@^pm.start_servers.*@pm.start_servers = $(($Mem/3/30))@" $php_install_dir/etc/php-fpm.conf
    sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = $(($Mem/3/40))@" $php_install_dir/etc/php-fpm.conf
    sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = $(($Mem/3/20))@" $php_install_dir/etc/php-fpm.conf
elif [ $Mem -gt 3000 -a $Mem -le 4500 ];then
    sed -i "s@^pm.max_children.*@pm.max_children = 50@" $php_install_dir/etc/php-fpm.conf
    sed -i "s@^pm.start_servers.*@pm.start_servers = 30@" $php_install_dir/etc/php-fpm.conf
    sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 20@" $php_install_dir/etc/php-fpm.conf
    sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 50@" $php_install_dir/etc/php-fpm.conf
elif [ $Mem -gt 4500 -a $Mem -le 6500 ];then
    sed -i "s@^pm.max_children.*@pm.max_children = 60@" $php_install_dir/etc/php-fpm.conf
    sed -i "s@^pm.start_servers.*@pm.start_servers = 40@" $php_install_dir/etc/php-fpm.conf
    sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 30@" $php_install_dir/etc/php-fpm.conf
    sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 60@" $php_install_dir/etc/php-fpm.conf
elif [ $Mem -gt 6500 -a $Mem -le 8500 ];then
    sed -i "s@^pm.max_children.*@pm.max_children = 70@" $php_install_dir/etc/php-fpm.conf
    sed -i "s@^pm.start_servers.*@pm.start_servers = 50@" $php_install_dir/etc/php-fpm.conf
    sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 40@" $php_install_dir/etc/php-fpm.conf
    sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 70@" $php_install_dir/etc/php-fpm.conf
elif [ $Mem -gt 8500 ];then
    sed -i "s@^pm.max_children.*@pm.max_children = 80@" $php_install_dir/etc/php-fpm.conf
    sed -i "s@^pm.start_servers.*@pm.start_servers = 60@" $php_install_dir/etc/php-fpm.conf
    sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 50@" $php_install_dir/etc/php-fpm.conf
    sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 80@" $php_install_dir/etc/php-fpm.conf
fi

# Unix Socket通信速度比TCP端口通信快，/dev/shm是个tmpfs，速度比磁盘快得多，不过不能在网络上传播，分布式要启用下面脚本
# Nginx也要启用#fastcgi_pass remote_php_ip:9000;
# sed -i "s@^listen =.*@listen = 127.0.0.1:9000@" $php_install_dir/etc/php-fpm.conf 

# 编译软件后建议加载一下
ldconfig
service php-fpm start
echo "php-$php_version install successfully! "
php -version

cd ..
[ -e "$php_install_dir/bin/phpize" ] && rm -rf php-$php_version

# 日志轮转
cat > /etc/logrotate.d/php6 << EOF
$php_log_dir/*.log $php_weblog_dir/*.log{
    daily
    rotate 15
    missingok
    dateext
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF

# Nginx 中启用PHP
# /etc/nginx/nginx.conf
# 备份
mv /etc/nginx/nginx.conf{,_bk} -n
mv /etc/nginx/conf.d/default.conf{,_bk} -n
sed -i "s@access_log.*access_nginx\.log.*;@access_log $php_weblog_dir/access_nginx\.log combined;@" /etc/nginx/nginx.conf 
sed -i "s@root /usr/share/nginx/html;@root $php_web_dir;@" /etc/nginx/nginx.conf 
[ -z "`grep '/php-fpm_status' /etc/nginx/nginx.conf`" ] &&  sed -i "s@index index.html index.php;@index index.html index.php;\n\n    location ~ /php-fpm_status {\n        #fastcgi_pass remote_php_ip:9000;\n        fastcgi_pass unix:/dev/shm/php-cgi.sock;\n        fastcgi_index index.php;\n        allow 127.0.0.1;\n        deny all;\n        }@" /etc/nginx/nginx.conf
[ -z "`grep 'location ~ \\\.php' /etc/nginx/nginx.conf`" ] &&  sed -i "s@index index.html index.php;@index index.html index.php;\n\n    location ~ \\\.php$ {\n        #fastcgi_pass remote_php_ip:9000;\n        fastcgi_pass unix:/dev/shm/php-cgi.sock;\n        fastcgi_index index.php;\n        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;\n        include fastcgi_params;\n        }@" /etc/nginx/nginx.conf

service nginx restart

# 创建测试页面
echo "<?php phpinfo(); ?>" > $php_web_dir/index.php
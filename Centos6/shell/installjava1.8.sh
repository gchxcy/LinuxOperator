#!/bin/sh

# rpm安装方式

### rpm/src包名，请根据实际情况修改
Jdk_rpm=jdk-8u92-linux-x64.rpm
Jdk_name=jdk1.8.0_92

# 卸载openjdk
rpm -e java-1.6.0-openjdk
rpm -e java-1.7.0-openjdk

# 正式安装JDK
yum -y localinstall rpm/$Jdk_rpm

### 配置系统环境
#在/etc/profile底部加入如下内容：

# export JAVA_HOME=/usr/java/jdk1.8.0_92
# export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar 
# export PATH=$JAVA_HOME/bin:$PATH

# 注意：JAVA_HOME的地址一定要填写正确的安装路径。

# 备份/etc/profile
cp /etc/profile{,_bk} -n
# /etc/profile
# 写入：export JAVA_HOME=/usr/java/jdk1.8.0_92
[ ! -z "`grep ^'export JAVA_HOME=' /etc/profile`" ] && sed -i "s@^export JAVA_HOME.*@export JAVA_HOME=/usr/java/${Jdk_name}@" /etc/profile || echo "export JAVA_HOME=/usr/java/${Jdk_name}" >> /etc/profile
# 写入：export CLASSPATH=$CLASSPATH:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
[ ! -z "`grep ^'export CLASSPATH=' /etc/profile `" -a -z "`grep ^'export CLASSPATH=.*$JAVA_HOME/lib.*' /etc/profile `" ] && echo 'export CLASSPATH=$CLASSPATH:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar' >> /etc/profile
# 写入：export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar 
[ -z "`grep ^'export CLASSPATH=' /etc/profile `" ] && echo 'export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar' >> /etc/profile
# 写入：export PATH=$JAVA_HOME/bin:$PATH
[ -z "`grep ^'export PATH=' /etc/profile | grep '$JAVA_HOME/bin'`" ] && echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/profile
. /etc/profile

echo "$Jdk_name install successfully!"
java -version

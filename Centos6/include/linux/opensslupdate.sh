#!/bin/sh

clear
printf "
====================================================
功能：
  升级openssl到最新版，源代码方式
未完成！
====================================================
"
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

wget http://www.openssl.org/source/openssl-1.0.1h.tar.gz   
tar zxvf openssl-1.0.1h.tar.gz   
cd openssl-1.0.1h   
./config --prefix=/usr/local/openssl   
make && make install   
mv /usr/bin/openssl /usr/bin/openssl.OFF   
mv /usr/include/openssl /usr/include/openssl.OFF   
ln -s /usr/local/openssl/bin/openssl /usr/bin/openssl   
ln -s /usr/local/openssl/include/openssl /usr/include/openssl   
echo "/usr/local/openssl/lib">>/etc/ld.so.conf   
ldconfig -v   
openssl version -a  

printf "
----------------------------------------------------
 创建数据库：$newdb 用户：$newuser 成功！
----------------------------------------------------
"
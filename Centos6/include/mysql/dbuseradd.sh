#!/bin/sh

clear
printf "
====================================================
功能：
  Mariadb/Mysql创建数据库/设定管理员/设定密码/访问IP

====================================================
"
read -p "请输入新数据库名:" newdb 2>&1
read -p "请输入管理员名称:" newuser 2>&1
read -p "请设定管理员密码:" newpasswd 2>&1

printf "
----------------------------------------------------
 管理员用户登陆IP，如：
 （1）localhost		本机登陆，建议
 （2）127.0.0.1		指定IP，或IP段
 （3）%%			远程任意IP
----------------------------------------------------
"
read -p "请设定访问ip（默认：localhost）:" loginip  2>&1
loginip=${loginip:=localhost}

printf "输入正确数据库root密码，才能进行操作!\n"
read -p "输入密码:" dbrootpwd 2>&1

# 创建数据库
mysql -uroot -p$dbrootpwd -e "create database "$newdb";"
# 创建用户并授权
mysql -uroot -p$dbrootpwd -e "grant all privileges on "$newdb".* to "$newuser"@'"$loginip"' identified by \"$newpasswd\";"
mysql -uroot -p$dbrootpwd -e "flush privileges;"

printf "
----------------------------------------------------
 创建数据库：$newdb 用户：$newuser 成功！
----------------------------------------------------
"
#!/bin/sh

### RHEL 需要注册才可以升级，更换为CentOS7源，否则无法使用yum升级
# 删除默认的yum源
rpm -qa |grep yum|xargs rpm -e --nodeps
# 添加CentOS7的yum，以及将Linux版本号改为CentOS7，注意安装顺序
rpm -ivh yum/python-*
rpm -ivh yum/yum-*
rpm -ivh yum/centos-*

# 启用CentOS7标准源
# cp yum/CentOS-Base.repo /etc/yum.repos.d/ -f
# 启用国内163源
cp yum/CentOS7-Base-163.repo /etc/yum.repos.d/ -f
# 启用国内aliyun源
# cp yum/Centos-7-aliyun.repo /etc/yum.repos.d/ -f
# 修正$releasever无法读取的bug
#sed -i "s@\$releasever@`cat /etc/redhat-release |awk '{print $7}'`@g" /etc/yum.repos.d/Cent*.repo
sed -i "s@\$releasever@7.2.1511@g" /etc/yum.repos.d/Cent*.repo

### 使用企业版Linux附加软件包（EPEL）
# 使用说明：https://fedoraproject.org/wiki/EPEL/zh-cn
# 企业版 Linux 附加软件包（EPEL）是一个由特别兴趣小组创建、维护并管理的，针对 红帽企业版 Linux(RHEL)及其衍生发行版(比如 CentOS、Scientific Linux、Oracle Enterprise Linux)的一个高质量附加软件包项目。 
# EPEL 的软件包通常不会与企业版 Linux 官方源中的软件包发生冲突，或者互相替换文件。EPEL 项目与 Fedora 基本一致，包含完整的构建系统、升级管理器、镜像管理器等等。 
yum -y install epel-release

# 生成缓存
yum clean all
yum makecache
# yum repolist all

# 安装yum加速插件
yum -y install yum-axelget


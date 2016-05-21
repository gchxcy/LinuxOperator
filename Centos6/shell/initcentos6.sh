#!/bin/sh

# 关闭SeLinux，修改后必须重启才生效
sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config

# 关闭防火墙，建议使用硬件防火墙
service iptables stop
chkconfig iptables off

# 限制root用户ssh登录
sed -i 's/.*PermitRootLogin yes.*/PermitRootLogin no/' /etc/ssh/sshd_config
/etc/rc.d/init.d/sshd reload

# 设置仅限wheel组可以使用su命令
sed -i 's/#\(.*required.*pam_wheel\.so.*\)/\1/' /etc/pam.d/su

# 启用wheel组sudo权限
sed -i 's/^#\(.*%wheel.*\)/\1/' /etc/sudoers
sed -i 's/^\(.*%wheel.*NOPASSWD.*\)/#\1/' /etc/sudoers

# 更新系统到最新
yum check-update
yum -y upgrade

# 安装必要基础包
for Package in deltarpm gcc gcc-c++ make cmake autoconf libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel libaio readline-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5-devel libidn libidn-devel openssl openssl-devel libxslt-devel libicu-devel libevent-devel libtool libtool-ltdl bison gd-devel vim-enhanced pcre-devel zip unzip ntpdate sysstat patch bc expect rsync git lsof lrzsz
do
    yum -y install $Package
done

# 升级重要的具有典型漏洞的软件包
yum -y update bash openssl glibc

# 安装setup管理网络
yum install setuptool system-config-network-tui -y

# 使用gcc-4.4
if [ -n "`gcc --version | head -n1 | grep '4\.1\.'`" ];then
    yum -y install gcc44 gcc44-c++ libstdc++44-devel
    export CC="gcc44" CXX="g++44"
fi

# 关联localhost和127.0.0.1
echo "127.0.0.1 `hostname` localhost localhost.localdomain" >/etc/hosts

### 精简开机系统自启动
# 保留的服务列表：
# sshd 安全登陆服务
# rsyslog 日志相关软件
# network 网络接口服务
# crond 计划任务服务
# sysstat 一组监测系统性能及效率工具
# 最小安装，不建议精简
#for Service in `chkconfig --list | awk '{print $1}' | grep -vE 'sshd|network|crond|messagebus|irqbalance|syslog|rsyslog|nginx|httpd|tomcat|mysqld|php-fpm|pureftpd|redis-server|memcached|supervisord|aegis'`;do chkconfig --level 3 $Service off;done

# 设置时区
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 修改命令历史记录数
sed -i 's/^HISTSIZE=.*$/HISTSIZE=100/' /etc/profile
# 记录所有用户操作历史，保存到/tmp/目录下
[ -z "`cat ~/.bashrc | grep history-timestamp`" ] && echo "export PROMPT_COMMAND='{ msg=\$(history 1 | { read x y; echo \$y; });user=\$(whoami); echo \$(date \"+%Y-%m-%d %H:%M:%S\"):\$user:\`pwd\`/:\$msg ---- \$(who am i); } >> /tmp/\`hostname\`.\`whoami\`.history-timestamp'" >> ~/.bashrc

# 调整Linux系统文件描述符数量，提高并发度
# /etc/security/limits.conf
cp /etc/security/limits.conf{,_bk} -n
[ -e /etc/security/limits.d/*nproc.conf ] && rename nproc.conf nproc.conf_bk /etc/security/limits.d/*nproc.conf
sed -i '/^# End of file/,$d' /etc/security/limits.conf
cat >> /etc/security/limits.conf <<EOF
# End of file
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
EOF
[ -z "`grep 'ulimit -SH 65535' /etc/rc.local`" ] && echo "ulimit -SH 65535" >> /etc/rc.local

### 内核参数优化，提高并发度
# /etc/sysctl.conf
cp /etc/sysctl.conf{,_bk} -n
sed -i 's/net.ipv4.tcp_syncookies.*$/net.ipv4.tcp_syncookies = 1/g' /etc/sysctl.conf
[ -z "`cat /etc/sysctl.conf | grep 'fs.file-max'`" ] && cat >> /etc/sysctl.conf << EOF
fs.file-max=65535
fs.inotify.max_user_instances = 8192
net.core.somaxconn = 65535 
net.core.netdev_max_backlog = 262144
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_fin_timeout = 30 
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_max_syn_backlog = 65536 
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_timestamps = 0
EOF

# 防火墙优化，提高并发度，防火墙不开会提示，可以忽略
[ -z "`grep net.netfilter.nf_conntrack_max /etc/sysctl.conf`" ] && cat >> /etc/sysctl.conf << EOF
net.netfilter.nf_conntrack_max = 1048576 
net.netfilter.nf_conntrack_tcp_timeout_established = 1200
EOF

# 让/etc/sysctl.conf配置立即生效
sysctl -p

# 限制控制台tty只开启2个
sed -i 's@^ACTIVE_CONSOLES.*@ACTIVE_CONSOLES=/dev/tty[1-2]@' /etc/sysconfig/init	

# 禁止Ctrl+Alt+Del重启
sed -i 's@^start@#start@' /etc/init/control-alt-delete.conf

# 修改系统的区域语言
sed -i 's@LANG=.*$@LANG="zh_CN.UTF-8"@g' /etc/sysconfig/i18n

# 使用ntpdate校正linux系统的时间，计划每天1点校正
# 时间服务器列表:
# pool.ntp.org
ntpdate pool.ntp.org 
[ -z "`grep 'ntpdate' /var/spool/cron/root`" ] && { echo "0 1 * * * `which ntpdate` pool.ntp.org > /dev/null 2>&1" >> /var/spool/cron/root;chmod 600 /var/spool/cron/root; }
service crond restart

# 配置后重启
shutdown -r +1 "将重启系统..."
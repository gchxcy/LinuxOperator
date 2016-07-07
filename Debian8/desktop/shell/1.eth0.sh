#!/bin/sh

### Debian的版本信息
# 8 Jessie 
# 7 wheezy
# 6 squeeze 　

. ./include/utils/color.sh &>/dev/null

# 删除不兼容的LANGUAGE设定
sed -i '/LANGUAGE=/d' /etc/default/locale
export LANGUAGE=en_US.UTF-8

### Linux网络有两种管理模式
# networking		:字符模式
# network-manager	:图形模式

### network-manager无线网络图形管理工具原理
# networking不处理的，就属于漫游状态，network-manager接管漫游状态的网络

cat >/etc/network/interfaces<<EOF
source /etc/network/interfaces.d/*
auto lo
iface lo inet loopback
allow-hotplug eth0
iface eth0 inet dhcp
EOF

ifup eth0
/etc/init.d/network-manager stop
/etc/init.d/networking restart

printf "
----------------------------------------------------
  eth0 config Success,try ping!
----------------------------------------------------
"

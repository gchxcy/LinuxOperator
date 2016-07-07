#!/bin/sh

### Debian的版本信息
# 8 Jessie 
# 7 wheezy
# 6 squeeze 　

. ./include/utils/color.sh &>/dev/null

# 删除不兼容的LANGUAGE设定
sed -i '/LANGUAGE=/d' /etc/default/locale
export LANGUAGE=en_US.UTF-8

printf "
----------------------------------------------------
Hint:
  Auto connect wifi with networking shell
  networking模式自动连接wifi脚本
----------------------------------------------------
	[Enter] continue, ${CYELLOW}[Ctrl]+c${CEND} cancel
"
read -p ':'

### Linux网络有两种管理模式
# networking		:字符模式
# network-manager	:图形模式

### networking无线网络连接原理
# https://wiki.debian.org/WiFi/HowToUse
# http://manpages.debian.org/man/5/wpa_supplicant.conf
# 查看无线网卡模块
# iwconfig
# ip addr
# 查看无线wifi列表
# iwlist wlan0 scan
# iwlist wlan0 scan | grep ESSID
# 生成连接配置文件
# wpa_passphrase 路由器ssid 路由器密码 > wifi.conf
# 连接
# wpa_supplicant -B -i wlan0 -c wifi.conf
# 启用无线网络
# ifdown wlan0 && ifup wlan0
# ip link set wlan0 up
# 获取IP
# dhcpcd 或 dhclient

### network-manager无线网络图形管理工具原理
# networking不处理的，就属于漫游状态，network-manager接管漫游状态的网络

ip link set wlan0 up 
iwlist wlan0 scan | grep ESSID |awk -F '[:"]' '{print $3}'> wifis
echo ----------------------------------------------------
nl wifis
echo ----------------------------------------------------
read -p 'please select the wifi index :' wifiindex
read -p 'please input the wifi passwd :' wifipasswd

wpa_passphrase `sed -n ${wifiindex}p wifis` $wifipasswd > wifi.conf
sed -i '/#psk/d' wifi.conf

wifisid=`sed -n ${wifiindex}p wifis`
wifipwd=`awk -F= '/psk/{print $2}' wifi.conf`

cat >/etc/network/interfaces<<EOF
source /etc/network/interfaces.d/*
auto lo
iface lo inet loopback
auto wlan0
iface wlan0 inet dhcp
wpa-driver wext
wpa-key-mgmt WPA-PSK
wpa-proto WPA
EOF
echo wpa-ssid $wifisid >>/etc/network/interfaces
echo wpa-psk $wifipwd >>/etc/network/interfaces

/etc/init.d/network-manager stop
/etc/init.d/networking restart
rm -f wifis
rm -f wifi.conf

printf "
----------------------------------------------------
  Wlan0 config Success,try ping!
----------------------------------------------------
"

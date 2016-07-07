#!/bin/sh

### Debian的版本信息
# 8 Jessie 
# 7 wheezy
# 6 squeeze 　

. ./include/utils/color.sh &>/dev/null

# 删除不兼容的LANGUAGE设定
sed -i '/LANGUAGE=/d' /etc/default/locale
export LANGUAGE=en_US.UTF-8

# 挂载DVD文件源 
# 最小化安装Debian8使用DVD文件源能提高安装速度
# 如果已经安装MATE桌面，可跳过

### 使用DVD文件本地源
sed -i '/deb cdrom/d' /etc/apt/sources.list
cat >/etc/apt/sources.list.d/cdrom.list<<EOF
deb file:///media/cdrom/ jessie main contrib
EOF

printf "
----------------------------------------------------
Hint:
${CYELLOW}
  mount -t iso9660 -o loop /mnt/debian.iso /media/cdrom/
${CEND}
----------------------------------------------------
"

#!/bin/sh

### Debian的版本信息
# 8 Jessie 
# 7 wheezy
# 6 squeeze 　

. ./include/utils/color.sh &>/dev/null

# 删除不兼容的LANGUAGE设定
sed -i '/LANGUAGE=/d' /etc/default/locale
export LANGUAGE=en_US.UTF-8

clear
printf "
----------------------------------------------------
Info:
  Imitation Mint-Mate desktop build Debian 8
  Based on minimizing installation stable version
  仿Mint-Mate打造Debian8桌面系统
  基于最小化安装稳定版
Hint:
  Minimal Debian 8 recommend using DVD source
  最小化安装Debian8使用光驱源能提高安装速度
  已经安装MATE桌面，可以跳过本地DVD源设置
----------------------------------------------------
	[Enter] continue, ${CYELLOW}[Ctrl]+c${CEND} cancel
"
read -p ':' 

# 卸载不需要的app，提高安装速度
apt remove libreoffice* -y
apt remove pidgin -y 
apt remove firefox* -y

# 删除光驱源
sed -i '/deb cdrom/d' /etc/apt/sources.list

### 使用[163][中科大]源
cat >/etc/apt/sources.list.d/official-package-repositories.list<<EOF
deb http://mirrors.ustc.edu.cn/linuxmint betsy main upstream import 

deb http://mirrors.163.com/debian/ jessie main non-free contrib
deb http://mirrors.163.com/debian/ jessie-updates main non-free contrib
deb http://mirrors.163.com/debian/ jessie-backports main non-free contrib
deb http://mirrors.163.com/debian-security/ jessie/updates main non-free contrib

deb http://www.deb-multimedia.org jessie main non-free

deb http://extra.linuxmint.com betsy main
EOF

### 安装linuxmint密钥
# 原理：通过密钥序号的最后8位数字导入密钥文件
# gpg --keyserver subkeys.pgp.net --recv 0FF405B2
# gpg --export --armor 0FF405B2 | apt-key add -
# --force-yes，表示在没有密钥的情况下，强制安装
# 163源为什么不用安装密钥？
# 说明：163源是官方源的镜像，官方源密钥默认已经安装

# 更新缓存，否则无法安装密钥
apt update
# 安装linuxmint密钥
apt install linuxmint-keyring -y --force-yes
# 安装deb-multimedia密钥
apt install deb-multimedia-keyring -y --force-yes
# 重新更新缓存，使密钥生效
apt update -y

# 修正vim方向键变字母问题
apt install vim -y 

# 更新系统
apt upgrade -y 

### 安装linux mint mate桌面
# mate安装帮助：http://wiki.mate-desktop.org/download
# 注意：mint mate不完全同于mate，还需要安装mint特性的一些主题
# mate基本桌面
apt install mate-desktop-environment-core -y
# mint-mate主题依赖软件包，安装完之后可以卸载
apt install thunderbird -y
# mint-mate主题
apt install mint-meta-debian-mate -y
# 登录管理器mdm及主题
apt remove lightdm -y
apt install mdm -y
apt install mint-mdm-themes -y

# PPA：Personal Package Archives(个人软件包档案)是Ubuntu Launchpad网站提供的一项服务，允许个人用户上传软件源代码，通过Launchpad进行编译并发布为二进制软件包，作为apt/新立得源供其他用户下载和更新。在Launchpad网站上的每一个用户和团队都可以拥有一个或多个PPA。
# 可能影响稳定性
# 安装mint特性后自动添加add-apt-repository命令

# 设置未安装命令安装提示，否则只是报错
update-command-not-found

### 系统管理
# mate-system-tools，包括：
# * Users and groups，用户和组，添加或删除用户和组
# * Date and time ，时间和日期，更改系统时间、日期和时区
# * Network options ，网络，配置网络设备和连接
# * Services ，服务
# * Shares (NFS and Samba)，共享的文件夹
apt install mate-system-tools -y
# printers，打印机
apt install system-config-printer -y
# mintupload，上传管理器
# apt install mintupload -y
# mintnanny，域名拦截器
# apt install mintnanny -y
# mintbackup，备份工具
# apt install mintbackup -y
# synaptic-pkexec，新立得软件包管理器，apt图形化界面，基本被“软件管理器”取代
# gksu mintinstall，软件管理器，对apt提供更丰富的检索功能
# software-sources，软件源，软件源配置界面
# gksu /usr/sbin/mdmsetup，登陆窗口，登陆窗口的配置界面
# driver-manager，驱动管理器，目前不兼容
# apt install mintdrivers -y

### 首选项配置
# 启动应用程序
# mate-session-manager
# 辅助技术、网络代理、窗口、显示器设置、
# 默认应用程序、键盘、键盘快捷键、鼠标、字体查看器
# mate-control-center
# 弹出通知
# mate-notification-daemon
# 桌面设置
# mintdesktop
# 文件管理
# caja
# 输入法
# im-config
# gnome-disks，磁盘，管理驱动器及媒体
apt install gnome-disk-utility -y
# 电源管理，配置电源管理
apt install mate-power-manager -y
# 屏幕保护程序
apt install mate-screensaver -y
# 蓝牙
# apt install blueberry -y
# 网络连接
apt install network-manager-gnome -y
# gufw，防火墙配置，配置防火墙的简单图形化方法，目前不兼容
apt install gufw -y

# 任务管理器，系统监视器
apt remove mate-system-monitor -y
apt install gnome-system-monitor -y

# 语言设置
apt install mintlocale -y

### 中文输入法
# 建议只选择一个输入法平台

# fcitx输入法平台：sun输入法
apt install fcitx-sunpinyin -y
# fcitx输入法平台：谷歌输入法
# apt install fcitx-googlepinyin -y
# fcitx输入法平台：五笔输入法
# apt install fcitx-table-wubi -y

# ibus输入法平台：sun输入法
# 安装IBus框架
# apt install ibus ibus-clutter ibus-gtk ibus-gtk3 ibus-qt4 -y
# 安装ibus-sun输入法
# apt install ibus-sunpinyin -y

# 输入法平台切换，安装后注销生效
# im-config，手动切换

### 附件
# mate-utils，包括：
# * mate-disk-usage-analyzer, MATE磁盘用量分析器
# * mate-dictionary, MATE字典
# * mate-search-tool, MATE搜索工具 
# * mate-system-log, 系统日志查看器 
# * mate-screenshot， 抓图，屏幕截图
apt install mate-utils -y
# 计算器
apt remove galculator -y
apt install gnome-calculator -y
# 记事本
apt remove pluma -y
apt install xed -y 
# pdf阅读器
apt remove atril -y
apt install xreader -y 
# 播放器
apt remove vlc -y
apt install xplayer -y
# 图像查看器
apt remove eom -y
apt install xviewer -y
# 图像编辑器
apt install gimp -y
# 便签
# apt install tomboy -y
# 归档管理器，engrampa，能解压多数压缩文档
apt install engrampa -y
# 字符命令归档
apt install zip unzip -y
apt install rar unrar -y
# deb安装器，gdebi

# 修正依赖
apt-get -f install -y

# 网络漫游托管
cat >/etc/network/interfaces<<EOF
source /etc/network/interfaces.d/*
auto lo
iface lo inet loopback
EOF

# 恢复初始化安装，删除个人Home目录的配置文件
rm -rf /home/*/.*

printf "
----------------------------------------------------
${CSUCCESS}
	安装完成，建议重启
${CEND}
----------------------------------------------------
	[Enter] reboot, ${CYELLOW}[Ctrl]+c${CEND} cancel
"
read -p ':' 
shutdown -r now

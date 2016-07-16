#!/bin/sh

### Debian的版本信息
# 8 Jessie 
# 7 wheezy
# 6 squeeze 　

. ./include/utils/color.sh &>/dev/null

clear
printf "
----------------------------------------------------
功能：
  Debian8桌面系统，安装非自由软件
建议：
  建议在图形界面运行
----------------------------------------------------
	[Enter] continue, ${CYELLOW}[Ctrl]+c${CEND} cancel
"
read -p ':' 

# 卸载不需要的app
# apt remove libreoffice* -y
# 修正，mint-meta-mate依赖部分libreoffice库
# apt install mint-meta-mate -y
apt remove thunderbird -y
apt remove pidgin -y 
apt remove firefox* -y
apt remove blueberry -y
apt remove mintupdate -y

# 更新系统
apt upgrade -y 

# wine模拟器
# https://www.winehq.org/download
# https://wiki.winehq.org/Debian
# apt支持https
apt install apt-transport-https -y
dpkg --add-architecture i386 
wget https://dl.winehq.org/wine-builds/Release.key
apt-key add Release.key
rm Release.key -f
cat >/etc/apt/sources.list.d/wine.list<<EOF
deb https://dl.winehq.org/wine-builds/debian/ jessie main
EOF
apt update
apt install winehq-staging -y
# apt install winehq-devel -y

# 搜狗输入法
# dpkg -i app/sogoupinyin*deb
# 修正依赖
# apt-get -f install -y

# chrom浏览器
# 下载地址：http://www.google.cn/chrome/browser/desktop/index.html
# dpkg -i app/google-chrome*.deb
# wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
apt-key add app/linux_signing_key.pub
cat >/etc/apt/sources.list.d/google-chrome.list<<EOF
deb http://dl.google.com/linux/chrome/deb/ stable main
EOF
apt update
# 密钥文件可能无法正确安装，必须强制无密钥安装chrome
apt install google-chrome-stable -y --force-yes
# apt install google-chrome-beta -y --force-yes

# 下载工具
# 安装完成后，还要在uGet设置中启用aria2插件，并添加参数“--enable-rpc=true”
apt install uget aria2 -y
apt install qbittorrent -y
# apt install transmission -y

# WPS Office 
# 最新版下载：http://wps-community.org/download.html
dpkg -i app/wps-office_*deb
dpkg -i app/wps-office-fonts_*deb
dpkg -i app/symbol-fonts_*deb
# 修正依赖
# apt-get -f install -y

# 植入Windows字体
mkdir /usr/share/fonts/truetype/winfonts
cp -f winfonts/* /usr/share/fonts/truetype/winfonts
# 字体必须具有可执行权限才可以使用
chmod -R 755 /usr/share/fonts/truetype/winfonts
fc-cache -fv /usr/share/fonts/truetype/winfonts

# 安装Windows字体包
dpkg -i app/winfonts_*deb

# Google Android字体
# fonts-noto-cjk:思源黑体
# cjk:Chinese/Japanese/Korean
# 思源黑体是Adobe与Google宣布推出的一款开源字体
# apt install fonts-noto-cjk

# 植入Mac/IOS字体
mkdir /usr/share/fonts/truetype/macfonts
cp -f winfonts/* /usr/share/fonts/truetype/macfonts
# 字体必须具有可执行权限才可以使用
chmod -R 755 /usr/share/fonts/truetype/macfonts
fc-cache -fv /usr/share/fonts/truetype/macfonts

### 字体渲染
# FreeType库是一个完全免费开源的、高质量的且可移植的字体引擎，它提供统一的接口来访问多种字体格式文件，包括TrueType, OpenType, Type1, CID, CFF, Windows FON/FNT, X11 PCF等。支持单色位图、反走样位图的渲染。FreeType库是高度模块化的程序库，虽然它是使用ANSI C开发，但是采用面向对象的思想。因此，FreeType的用户可以灵活地对它进行裁剪。
# FreeType库 libfreetype6 一般默认已安装
apt install libfreetype6 -y
# infinality渲染
# 源码地址：https://github.com/Infinality/fontconfig-infinality
# rpm转deb地址：https://github.com/chenxiaolong/Debian-Packages.git
# bin源：http://ppa.launchpad.net/no1wantdthisname/ppa/ubuntu/pool/main/f/
dpkg -i app/fontconfig-infinality_*.deb
# 开启渲染：在桌面右键，选择“更改桌面背景”->“主题”->“字体”->“细节…”，打开字体渲染细节，“微调”选择“完全”。

# Beyond Compare，文本比较工具
dpkg -i app/bcompare*.deb
# TODO::安装到右键菜单
# cp bcompare.sh ~/.gnome2/nautilus-scripts/  

# Sublime Text 3，文本编辑器
dpkg -i app/sublime-text*.deb

# Wine QQ 国际版
dpkg -i app/fonts-wqy-microhei_*.deb
dpkg -i app/ttf-wqy-microhei_*.deb
dpkg -i app/wine-qqintl_*.deb
# 修正依赖
# apt-get -f install -y

# 有道词典，版本不能太高，高版本只支持Ubuntu的deb格式
dpkg -i app/python3-xlib_*.deb
dpkg -i app/youdao-dict_*.deb

# FFmpeg是一套可以用来记录、转换数字音频、视频，并能将其转化为流的开源计算机程序
# apt install ffmpeg

# 网易云播放器，版本不能太高，高版本只支持Ubuntu的deb格式
dpkg -i app/netease-cloud-music_*.deb

### cmd_markdown解压安装
CMD_MARK_DIR=/opt/cmd_markdown_linux64
rm -rf $CMD_MARK_DIR
tar zxf app/cmd_markdown_linux64.tar.gz
mv cmd_markdown_linux64 $CMD_MARK_DIR
# 处理不规则文件名
mv $CMD_MARK_DIR/Cmd\ Markdown $CMD_MARK_DIR/Cmd_Markdown
chmod 755 $CMD_MARK_DIR/Cmd_Markdown
# 安装到开始菜单，必须以.desktop后缀命名
cat>>/usr/share/applications/Cmd_Markdown.desktop<<EOF
[Desktop Entry]
Comment=Cmd Markdown.
Comment[zh_CN]=使用Cmd Markdown整理笔记，记录文档
Exec=$CMD_MARK_DIR/Cmd_Markdown %U
GenericName=Cmd Markdown
GenericName[zh_CN]=Cmd Markdown
MimeType=application/Cmd_Markdown;text/plain;
Name=Cmd Markdown
Name[zh_CN]=Cmd Markdown
StartupNotify=true
Terminal=false
Type=Application
Categories=Office;Markdown;TextEditor;
Icon=accessories-text-editor
EOF

# VMware-Workstation虚拟机
cp app/VMware-Workstation-* /tmp
chmod +x /tmp/VMware-Workstation-*
/tmp/VMware-Workstation-*
rm -f /tmp/VMware-Workstation-*

# TODO::仿Windows桌面主题设置
# Windows桌面字体：微软雅黑; 等款字体,Consolas;
# 图标：themes/Win10.Icons，整个文件夹复制/usr/share/icons下
# 指针: themes/Win8.Cursors，整个文件夹复制/usr/share/icons下

# TODO::仿Mac OS X桌面主题设置
# Mac OS X桌面字体：黑体-简，苹方-简; 等款字体,Monaco
# http://www.uisdc.com/ios-9-font-transition
# 图标：
# 指针: 

# 修正依赖
apt-get -f install -y

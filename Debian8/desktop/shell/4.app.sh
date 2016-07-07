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
mkdir /usr/share/fonts/winfonts
cp -f winfonts/* /usr/share/fonts/winfonts
chmod -R 744 /usr/share/fonts/winfonts
mkfontscale
mkfontdir
fc-cache -fv

# 安装Windows字体包
dpkg -i app/winfonts_*deb

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
apt install python3-xlib -y
dpkg -i app/youdao-dict_*.deb

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
# Windows桌面字体：西文,Tahoma;等线体,Arial;中文,宋体;
# 图标：themes/Win10.Icons，整个文件夹复制/usr/share/icons下
# 指针: themes/Win8.Cursors，整个文件夹复制/usr/share/icons下

# 修正依赖
apt-get -f install -y

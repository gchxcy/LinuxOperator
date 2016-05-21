
###app包信息，请务必根据实际情况修改
# 压缩格式.zip
app_name=phpMyAdmin
# 安装目录名
uri_name=pma

### 安装初始信息，必须跟php安装时指定的一致
# 站点根目录及日志
php_web_dir=/data/phpwebroot/default
# 运行账号
run_user=php

# 安装
unzip app/$app_name*.zip
rm -rf $php_web_dir/$uri_name
mv $app_name* $php_web_dir/$uri_name -n

# 安全权限设置
chown -R $run_user.$run_user $php_web_dir/$uri_name
chmod -R 755 $php_web_dir/$uri_name

### 个性定制
# 请查看安装包自带帮助文档：doc/html/setup.html#quick-install

# 拷贝config.sample.inc.php=>config.sample.inc.php
cp $php_web_dir/$uri_name/{config.sample.inc.php,config.inc.php} -f

# 配置config.inc.php
mkdir $php_web_dir/$uri_name/{upload,save}
sed -i "s@UploadDir.*@UploadDir'\] = 'upload';@" $php_web_dir/$uri_name/config.inc.php
sed -i "s@SaveDir.*@SaveDir'\] = 'save';@" $php_web_dir/$uri_name/config.inc.php
sed -i "s@blowfish_secret.*;@blowfish_secret\'\] = \'`cat /dev/urandom | head -1 | md5sum | head -c 10`\';@" $php_web_dir/$uri_name/config.inc.php
chown -R $run_user.$run_user $php_web_dir/$uri_name

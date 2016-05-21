#!/bin/sh

# RPM包安装方式
# 确保关闭SELinux

### rpm/src包名，请根据实际情况修改
MariaDB_server_rpm=MariaDB-10.1.13-centos6-x86_64-server.rpm
MariaDB_client_rpm=MariaDB-10.1.13-centos6-x86_64-client.rpm
MariaDB_common_rpm=MariaDB-10.1.13-centos6-x86_64-common.rpm
MariaDB_compat_rpm=MariaDB-10.1.13-centos6-x86_64-compat.rpm
galera_rpm=galera-25.3.15-1.rhel6.el6.x86_64.rpm
jemalloc_rpm=jemalloc-3.6.0-1.el6.x86_64.rpm
jemalloc_devel_rpm=jemalloc-devel-3.6.0-1.el6.x86_64.rpm

### 可自定义信息，但是不建议修改
# 定义变量存放数据库的数据和日志文件目录
mysql_data_dir=/data/mysql
mysql_log_dir=/data/mysqllog

# 设定数据库root密码
read -p "请预先设定数据库root密码:" dbrootpwd 2>&1

# 卸载mysql，会与已经安装的Mysql冲突
yum -y remove mysql*

# 新建mysql用户及用户组
useradd -M -s /sbin/nologin mysql

# 建立数据库数据存放路径，并授权
mkdir -p $mysql_data_dir
chown mysql.mysql -R $mysql_data_dir
mkdir -p $mysql_log_dir
chown mysql.mysql -R $mysql_log_dir

# 安装依赖软件包jemalloc
yum -y localinstall rpm/${jemalloc_rpm}
yum -y localinstall rpm/${jemalloc_devel_rpm}

# 安装依赖软件包galera
yum -y localinstall rpm/${galera_rpm}

# 安装依赖软件包MariaDB-common、MariaDB_compat
yum -y localinstall rpm/${MariaDB_common_rpm} rpm/${MariaDB_compat_rpm}

# 正式安装依赖MariaDB包
yum -y localinstall rpm/${MariaDB_client_rpm}
yum -y localinstall rpm/${MariaDB_server_rpm}

# 启用jemalloc内存管理
cp /usr/bin/mysqld_safe{,_bk} -n
sed -i 's@executing mysqld_safe@executing mysqld_safe\nexport LD_PRELOAD=/usr/lib64/libjemalloc.so@' /usr/bin/mysqld_safe

# 设置为自启动服务，迁移/etc/init.d/mysql中的数据位置
sed -i "s@^datadir=.*@datadir=$mysql_data_dir@" /etc/init.d/mysql

### 配置/etc/my.cnf
# my.cnf
mv /etc/my.cnf{,_bk} -n
cat > /etc/my.cnf << EOF
[client]
port = 3306
socket = /tmp/mysql.sock
default-character-set = utf8

[mysql]
prompt="MySQL [\\d]> "
no-auto-rehash

[mysqld]
port = 3306
socket = /tmp/mysql.sock

datadir = $mysql_data_dir
pid-file = $mysql_data_dir/mysql.pid
user = mysql
bind-address = 0.0.0.0
server-id = 1

init-connect = 'SET NAMES utf8'
character-set-server = utf8

skip-name-resolve
#skip-networking
back_log = 300

max_connections = 1000
max_connect_errors = 6000
open_files_limit = 65535
table_open_cache = 128 
max_allowed_packet = 500M
binlog_cache_size = 1M
max_heap_table_size = 8M
tmp_table_size = 16M

read_buffer_size = 2M
read_rnd_buffer_size = 8M
sort_buffer_size = 8M
join_buffer_size = 8M
key_buffer_size = 4M

thread_cache_size = 8

query_cache_type = 1
query_cache_size = 8M
query_cache_limit = 2M

ft_min_word_len = 4

log_bin = mysql-bin
binlog_format = mixed
expire_logs_days = 7 

log_error = $mysql_log_dir/mysql-error.log
slow_query_log = 1
long_query_time = 1
slow_query_log_file = $mysql_log_dir/mysql-slow.log

performance_schema = 0
explicit_defaults_for_timestamp

lower_case_table_names = 1

skip-external-locking

default_storage_engine = InnoDB
#default-storage-engine = MyISAM
innodb_file_per_table = 1
innodb_open_files = 500
innodb_buffer_pool_size = 64M
innodb_write_io_threads = 4
innodb_read_io_threads = 4
innodb_thread_concurrency = 0
innodb_purge_threads = 1
innodb_flush_log_at_trx_commit = 2
innodb_log_buffer_size = 2M
innodb_log_file_size = 32M
innodb_log_files_in_group = 3
innodb_max_dirty_pages_pct = 75
innodb_lock_wait_timeout = 120

bulk_insert_buffer_size = 8M
myisam_sort_buffer_size = 8M
myisam_max_sort_file_size = 10G
myisam_repair_threads = 1

interactive_timeout = 28800
wait_timeout = 28800

[mysqldump]
quick
max_allowed_packet = 500M

[myisamchk]
key_buffer_size = 8M
sort_buffer_size = 8M
read_buffer = 4M
write_buffer = 4M
EOF

Mem=`free -m | awk '/Mem:/{print $2}'`

sed -i "s@max_connections.*@max_connections = $(($Mem/2))@" /etc/my.cnf 
if [ $Mem -gt 1500 -a $Mem -le 2500 ];then
    sed -i 's@^thread_cache_size.*@thread_cache_size = 16@' /etc/my.cnf
    sed -i 's@^query_cache_size.*@query_cache_size = 16M@' /etc/my.cnf
    sed -i 's@^myisam_sort_buffer_size.*@myisam_sort_buffer_size = 16M@' /etc/my.cnf
    sed -i 's@^key_buffer_size.*@key_buffer_size = 16M@' /etc/my.cnf
    sed -i 's@^innodb_buffer_pool_size.*@innodb_buffer_pool_size = 128M@' /etc/my.cnf
    sed -i 's@^tmp_table_size.*@tmp_table_size = 32M@' /etc/my.cnf
    sed -i 's@^table_open_cache.*@table_open_cache = 256@' /etc/my.cnf
elif [ $Mem -gt 2500 -a $Mem -le 3500 ];then
    sed -i 's@^thread_cache_size.*@thread_cache_size = 32@' /etc/my.cnf
    sed -i 's@^query_cache_size.*@query_cache_size = 32M@' /etc/my.cnf
    sed -i 's@^myisam_sort_buffer_size.*@myisam_sort_buffer_size = 32M@' /etc/my.cnf
    sed -i 's@^key_buffer_size.*@key_buffer_size = 64M@' /etc/my.cnf
    sed -i 's@^innodb_buffer_pool_size.*@innodb_buffer_pool_size = 512M@' /etc/my.cnf
    sed -i 's@^tmp_table_size.*@tmp_table_size = 64M@' /etc/my.cnf
    sed -i 's@^table_open_cache.*@table_open_cache = 512@' /etc/my.cnf
elif [ $Mem -gt 3500 ];then
    sed -i 's@^thread_cache_size.*@thread_cache_size = 64@' /etc/my.cnf
    sed -i 's@^query_cache_size.*@query_cache_size = 64M@' /etc/my.cnf
    sed -i 's@^myisam_sort_buffer_size.*@myisam_sort_buffer_size = 64M@' /etc/my.cnf
    sed -i 's@^key_buffer_size.*@key_buffer_size = 256M@' /etc/my.cnf
    sed -i 's@^innodb_buffer_pool_size.*@innodb_buffer_pool_size = 1024M@' /etc/my.cnf
    sed -i 's@^tmp_table_size.*@tmp_table_size = 128M@' /etc/my.cnf
    sed -i 's@^table_open_cache.*@table_open_cache = 1024@' /etc/my.cnf
fi

# 初始化安装数据库
mysql_install_db --user=mysql --datadir=$mysql_data_dir

service mysql start

# 初始化数据库配置
mysql -e "grant all privileges on *.* to root@'127.0.0.1' identified by \"$dbrootpwd\" with grant option;"
mysql -e "grant all privileges on *.* to root@'localhost' identified by \"$dbrootpwd\" with grant option;"
mysql -uroot -p$dbrootpwd -e "delete from mysql.user where Password='';"
mysql -uroot -p$dbrootpwd -e "delete from mysql.db where User='';"
mysql -uroot -p$dbrootpwd -e "delete from mysql.proxies_priv where Host!='localhost';"
mysql -uroot -p$dbrootpwd -e "drop database test;"
mysql -uroot -p$dbrootpwd -e "reset master;"

# 日志轮转
cat > /etc/logrotate.d/mysql << EOF
$mysql_log_dir/*.log{
    daily
    rotate 15
    missingok
    dateext
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF

echo "Mysql install successfully! "
mysql -V

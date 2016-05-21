#!/bin/sh

# 官方自定义yum源安装方式
# nginx官方stable版
# 确保关闭SELinux

# 自动创建运行账号，跳过
# run_user=nginx

### 可自定义信息，但是不建议修改
# 日志文件
nginx_log_dir=/data/nginxlog

# 创建目录
mkdir -p $nginx_log_dir

# 安装依赖包pcre
# pcre实现rewrite功能，yum安装自动解决依赖问题，跳过

# 官方提供了自定义的yum源
cat > /etc/yum.repos.d/nginx.repo <<EOF
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=0
enabled=1
EOF

# 检查更新本地缓存，并安装
# yum clean all
# yum makecache
yum check-update
yum -y install nginx

# Nginx修改配置文件，并迁移日志文件
# /etc/nginx/nginx.conf
# 备份
mv /etc/nginx/nginx.conf{,_bk} -n
mv /etc/nginx/conf.d/default.conf{,_bk} -n

cat > /etc/nginx/nginx.conf << EOF
user nginx;
worker_processes 1;

error_log $nginx_log_dir/error.log;
pid /var/run/nginx.pid;
worker_rlimit_nofile 51200;

events {
    use epoll;
    worker_connections 51200;
    multi_accept on;
    }

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  $nginx_log_dir/access.log  main;

    server_names_hash_bucket_size 128;
    client_header_buffer_size 32k;
    large_client_header_buffers 4 32k;
    client_max_body_size 1024m;
    sendfile on;
    tcp_nopush on;
    keepalive_timeout 120;
    server_tokens off;
    tcp_nodelay on;
    
    fastcgi_connect_timeout 300;
    fastcgi_send_timeout 300;
    fastcgi_read_timeout 300;
    fastcgi_buffer_size 64k;
    fastcgi_buffers 4 64k;
    fastcgi_busy_buffers_size 128k;
    fastcgi_temp_file_write_size 128k;

    #Gzip Compression
    gzip on;
    gzip_buffers 16 8k;
    gzip_comp_level 6;
    gzip_http_version 1.1;
    gzip_min_length 256;
    gzip_proxied any;
    gzip_vary on;
    gzip_types
        text/xml application/xml application/atom+xml application/rss+xml application/xhtml+xml image/svg+xml
        text/javascript application/javascript application/x-javascript
        text/x-json application/json application/x-web-app-manifest+json
        text/css text/plain text/x-component
        font/opentype application/x-font-ttf application/vnd.ms-fontobject
        image/x-icon;
    gzip_disable "MSIE [1-6]\.(?!.*SV1)";

    #If you have a lot of static files to serve through Nginx then caching of the files' metadata (not the actual files' contents) can save some latency.
    open_file_cache max=1000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;

    # default #
    server {
    listen 80;
    server_name localhost;
    access_log $nginx_log_dir/access_nginx.log combined;

    root /usr/share/nginx/html;
    index index.html index.php;

    #error_page  404              /404.html;
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
        }

    location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|flv|ico)$ {
        expires 30d;
        access_log off;
        }

    location ~ .*\.(js|css)?$ {
        expires 7d;
        access_log off;
        }

    location = /favicon.ico {
        log_not_found off;
        }

    }

    include /etc/nginx/conf.d/*.conf;
    # vhost    
    include /etc/nginx/conf.d/vhost/*.conf;
}
EOF

# 代理配置
mv /etc/nginx/conf.d/proxy.conf{,_bk} -n &> /dev/null
cat > /etc/nginx/conf.d/proxy.conf << EOF
proxy_connect_timeout 300s;
proxy_send_timeout 900;
proxy_read_timeout 900;
proxy_buffer_size 32k;
proxy_buffers 4 64k;
proxy_busy_buffers_size 128k;
proxy_redirect off;
proxy_hide_header Vary;
proxy_set_header Accept-Encoding '';
proxy_set_header Referer \$http_referer;
proxy_set_header Cookie \$http_cookie;
proxy_set_header Host \$host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
EOF

# 日志轮转
# 日志默认在/var/log/nginx/，日志轮转中日志地址迁移
sed -i "s@/var/log/nginx/\*\.log@$nginx_log_dir/\*\.log@" /etc/logrotate.d/nginx 

service nginx start
echo "Nginx install successfully!"
nginx -v

# 开启80端口，修改防火墙规则
[ -z "`grep ^'-A INPUT.*--dport 80.*ACCEPT.*' /etc/sysconfig/iptables`" ] && sed -i "s@^\(\(-A INPUT.*--dport\) 22\(.*ACCEPT.*\)\)@\1\n\2 80\3@" /etc/sysconfig/iptables 

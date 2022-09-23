#!/bin/bash

#declare variables
WEBID="123456"
DOMAIN="viktor$WEBID"
MYSQL_VERSION="5.7.13"
MYSQL_USER_ENV="user"
MYSQL_PASSWORD_ENV="password"
SFTP_USERNAME="viktor"
SFTP_PASSWORD="viktor"


echo "configuration for $WEBID is being created.
Please wait..."

#create directory structure
mkdir $WEBID
mkdir $WEBID/www
mkdir $WEBID/laravel
mkdir $WEBID/mysql
mkdir $WEBID/mysql/docker-entrypoint-initdb.d
mkdir $WEBID/nginx_laravel_conf
mkdir $WEBID/php_laravel_conf



#create nesscecary files
touch $WEBID/docker-compose.yml
touch $WEBID/laravel/dockerfile
touch $WEBID/nginx_laravel_conf/app.conf
touch $WEBID/php_laravel_conf/local.ini
touch $WEBID/mysql/docker-entrypoint-initdb.d/init_db.sql
touch $WEBID/mysql/my.cnf

#create docker-compose file in main folder
echo 'version: "3.1"
services:

 web:
  build:
   args:
    user: www
    uid: 1000
   context: ./laravel
   dockerfile: dockerfile
  image: laravel-image
  container_name: 'contlaravel-$WEBID'
  restart: unless-stopped
  working_dir: /var/www/
  volumes:
  - ./www:/var/www
  - ./php_laravel_conf/local.ini:/usr/local/etc/php/conf.d/local.ini



 nginx:
  image: nginx:alpine
  restart: unless-stopped
  expose:
  - "80"
  environment:
   VIRTUAL_HOST: 'web.$DOMAIN.teamsixhosting'
  volumes:
  - ./www:/var/www
  - ./nginx_laravel_conf:/etc/nginx/conf.d/
  container_name: 'contweb-$WEBID'

 db:
  image: mysql:'$MYSQL_VERSION'
  restart: unless-stopped
  environment:
   MYSQL_DATABASE: 'db'
   MYSQL_USER: '$MYSQL_USER_ENV'
   MYSQL_PASSWORD: '$MYSQL_PASSWORD_ENV'
   MYSQL_ROOT_PASSWORD: '$MYSQL_PASSWORD_ENV'
   SERVICE_TAGS: dev
   SERVICE_NAME: mysql
  expose:
  - "3306"
  container_name: 'contsql-$WEBID'
  volumes:
  - ./mysql/my.cnf:/etc/mysql/my.cnf
  - ./mysql/docker-entrypoint-initdb.d/:/docker-entrypoint-initdb.d/

 phpmyadmin:
  image: phpmyadmin/phpmyadmin
  restart: unless-stopped
  expose:
  - "80"
  environment:
   PMA_HOST: 'contsql-$WEBID'
   MYSQL_USER: '$MYSQL_USER_ENV'
   MYSQL_PASSWORD: '$MYSQL_PASSWORD_ENV'
   MYSQL_ROOT_PASSWORD: '$MYSQL_PASSWORD_ENV'
   VIRTUAL_HOST: 'phpmyadmin.$DOMAIN.teamsixhosting'
  container_name: 'contphpmyadmin-$WEBID'


networks: 
 default: 
  name: net-hosting' > $WEBID/docker-compose.yml



#create dockerfile in laravel folder
echo 'FROM php:7.4-fpm

# Arguments defined in docker-compose.yml
ARG user
ARG uid

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Set working directory
WORKDIR /var/www

USER $user' > $WEBID/laravel/dockerfile

#---------------------------------------------------
# CREATE CONFIG FILES
#---------------------------------------------------

#create nginx conf file
echo 'server {
    listen 80;
    index index.php index.html;
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    root /var/www/public;
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass 'contlaravel-$WEBID':9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
    location / {
        try_files $uri $uri/ /index.php?$query_string;
        gzip_static on;
    }
}' > $WEBID/nginx_laravel_conf/app.conf

#create php conf file
echo 'error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = Off
display_startup_errors = Off
log_errors = On
log_errors_max_len = 1024
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
' > $WEBID/php_laravel_conf/local.ini

#create mysql conf file
echo '[mysqld]
general_log = 1
general_log_file = /var/lib/mysql/general.log
' > $WEBID/mysql/my.cnf

#------------------------------
# CREATE CONTAINERS
#------------------------------

echo "starting containers..."

docker-compose -f $WEBID/docker-compose.yml up -d



echo "useraccount for  $SFTP_USERNAME is being created."

PASS=$(perl -e 'print crypt($ARGV[0], "password")' $SFTP_PASSWORD)

sudo useradd $SFTP_USERNAME -p $PASS -m -d /home/ubuntu/projecthosting/docker/$WEBID/www
sudo chown -R $SFTP_USERNAME /home/ubuntu/projecthosting/docker/$WEBID/www  
echo $SFTP_USERNAME >> /etc/vsftpd.userlist

echo "User and FTP login has been created!!!"

echo "Finished!"
echo "Your virtual host names are 'web.$DOMAIN.teamsixhosting' & 'phpmyadmin.$DOMAIN.teamsixhosting'"
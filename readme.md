# Magento 2 development enviroment under Docker

# Technologies Used
- Docker, Docker-Compose
- Nginx
- PHP
- Mysql
- Elasticsearch
- Redis
- Composer

# Contents Overview
1. [Pre-Requistices](#1-pre-requistices)
2. [Follow these steps to setup the enviroment](#2-follow-these-steps-to-setup-the-enviroment)
3. [Setup enviroment variables for easy commands](#3-setup-enviroment-variables-for-easy-commands)
4. [Install Magento 2 & Sample Data](#4-install-magento-2-sample-data)
5. [Extra optimizations](#5-extra-optimizations)

# 1. Pre-Requistices

## Create folders in host that will be mounted to docker containers
- Replace the `$user` with your current user
```
sudo mkdir -p /home/$user/html/magento
sudo mkdir -p /home/$user/.composer
sudo mkdir -p /var/lib/mysql
sudo mkdir -p /var/lib/redis
sudo mkdir -p /usr/share/elasticsearch/data
```

## Set correct folder permissions
- Elasticsearch data needs `$user` as owner and group, `1000` will be resolved to current system user
```
sudo chown -R 1000:1000 /usr/share/elasticsearch/data
```

## Redis/Elasticsearch optimization
- Open `/etc/sysctl.conf` and add these lines at the end
```
# Elasticsearch Compatibility
vm.max_map_count=262144

# Redis Compatibility
net.core.somaxconn=1024
vm.overcommit_memory=1
```
- Create a new file `/etc/rc.local` and add this
```
#!/bin/bash
echo never > /sys/kernel/mm/transparent_hugepage/enabled
```
- Make `rc.local` file executable
```
sudo chmod +x /etc/rc.local
```
- start `rc.local` service and verify that is active
```
sudo systemctl start rc.local
sudo systemctl status rc.local
```

## Install Docker and Docker-Compose

## Get the composer access keys from Magento Marketplace
[Composer access keys](https://devdocs.magento.com/guides/v2.3/install-gde/prereq/connect-auth.html)

# 2. Follow these steps to setup the enviroment

## `git clone` this repository and cd into it

## open docker-compose.yml in editor
```
version: '3'

services:
    nginx:
        image: nginx:1.16.1
        container_name: nginx
        ports:
            - "80:80"
        volumes:
            - ./server/nginx/default.conf:/etc/nginx/conf.d/default.conf
            - ./server/nginx/magento.sample:/etc/nginx/conf.d/magento.sample
            - /home/$user/html/magento:/var/www/html/magento
        depends_on:
            - php
            - mysql
        
    php:
        build: ./server/php
        image: magento-php:7.2-fpm
        container_name: php
        environment:
            COMPOSER_ALLOW_SUPERUSER : 1
        volumes:
            - ./server/php/php-fpm.ini:/usr/local/etc/php/conf.d/php-fpm.ini
            - ./server/php/www2.conf:/usr/local/etc/php-fpm.d/www2.conf
            - /home/$user/html/magento:/var/www/html/magento    
            - /home/$user/.composer:/root/.composer
           
    mysql:
        image: mysql:5.7
        container_name: mysql       
        ports: 
            - "3306:3306"
        environment:
            MYSQL_ROOT_PASSWORD: f4m5kyb8R34zx5a
            MYSQL_USER: $User
            MYSQL_PASSWORD: 5hKh5EVswD
            MYSQL_DATABASE: magento
        volumes:
            - /var/lib/mysql:/var/lib/mysql
            - ./server/mysql/mysql.cnf:/etc/mysql/conf.d/mysql.cnf

    elasticsearch:
        image: elasticsearch:6.8.0
        container_name: elasticsearch       
        ports: 
            - "9200:9200"
        environment:
            ES_JAVA_OPTS: -Xms256m -Xmx256m
        volumes:
            - /usr/share/elasticsearch/data:/usr/share/elasticsearch/data

    redis:
        image: redis:5.0.7
        container_name: redis       
        ports: 
            - "6379:6379"
        volumes:
            - /var/lib/redis:/data
        sysctls:
            net.core.somaxconn: 1024
```
- Update the `$user` variable with your own user, change mysql `root` and `user` password if required and save the file

## Run this command to build images and start the containers
```
docker-compose up -d
```

# 3. Setup enviroment variables for easy commands
- Open `/etc/enviroment/` in editor and add the following
- Replace `$path_to_docker_magento2` with correct path
```
magento_stack="docker-compose -f $path_to_docker_magento2/docker-compose.yml"
php_magento="docker exec -it -w /var/www/html/magento php php bin/magento"
php_composer="docker exec -it -w /var/www/html/magento php composer"
redis_cli="docker exec -it redis redis-cli"
```
- Restart the computer
- Now all the containers in magento stack can be commanded using `$magento_stack command` example `$magento_stack start`
- Magento 2 CLI can be used using `$php_magento command` example `$php_magento setup:upgrade`
- Composer can be used using `$php_composer command` example `$php_composer info`
- Redis Cli can be used using `$redis_cli command` example `$redis_cli info`

# 4. Install Magento 2 & Sample Data

## Use Composer to download latest Magento 2
- Run this command to download latest Magento 2 
```
$php_composer create-project --repository=https://repo.magento.com/ magento/project-community-edition .
```
- Enter the composer access keys from magento marketplace and save it

## Set proper file permissions
```
cd /home/$user/html/magento

find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
sudo chmod u+x bin/magento
```

```
cd /home/$user/html

sudo chown -R www-data:www-data magento/
sudo chmod -R 775 magento/
sudo chmod -R g+s magento/
```
- Now you can browse `http://localhost` in the browser and magento setup wizard will begin
- Finish the wizard to sucessfully setup Magento 2

## Install Magento 2 sample data
- Use this command to download sample data
```
$php_magento sampledata:deploy
```
- Install sample data
```
$php_magento setup:upgrade
```
Now you should have a fully working Magento 2 instance with sample data

# 5. Extra optimizations

## Elasticsearch replicas configuration
- Elasticsearch tries to create an additional replica of each indexes by default on second node, since local development will only have one node this will never succeed.
- This causes half the shards to be unassigned and cluster health to be yellow.
- Use these commands to set default replica configuration to 0 for current and all future indexes.
```
# Replica setting for all new index

curl -XPUT "localhost:9200/_template/default_template" -H 'Content-Type: application/json' -d'
{
  "index_patterns": ["*"],
  "settings": {
    "index": {
      "number_of_replicas": 0
    }
  }
}'

# Replica setting for current index

curl -XPUT 'localhost:9200/_settings' -H 'Content-Type: application/json' -d'
{
  "index" : {
    "number_of_replicas" : 0
  }
}'
```
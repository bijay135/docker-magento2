# Magento 2 development enviroment under Docker

# Technologies Used
- Docker, Docker-Compose
- LEMP stack
- Composer

# 1. Pre-Requistices

## Install Docker and Docker-Compose

## Install PHP, Composer and all required extensions by Magento 2

[Magento 2 reqired PHP extensions](https://devdocs.magento.com/guides/v2.3/install-gde/system-requirements-tech.html#required-php-extensions)

## Get the composer access keys from Magento Marketplace

[Composer access keys](https://devdocs.magento.com/guides/v2.3/install-gde/prereq/connect-auth.html)

## Use Composer to download latest Magento 2

- Create a directory in /home/$user/html/magento and cd into it

- Run this command to download latest Magento 2 
```
composer create-project --repository=https://repo.magento.com/ magento/project-community-edition .

```

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
            - "443:443"  
        volumes:
            - ./server/nginx/default.conf:/etc/nginx/conf.d/default.conf
            - /home/$user/html:/var/www/html
        links:
            - php
            - mysql
        
    php:
        build: ./server
        image: magento-php:7.2-fpm
        container_name: php
        volumes:
            - ./server/php/php.ini:/usr/local/etc/php/conf.d/php.ini
            - /home/$user/html:/var/www/html
           
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

```

Update the `$user` variable with your own user and save the file

## Run this command to build images and start the containers
```
docker-compose up -d
```

# 3. Setup downloaded Magento 2
- Now you can browse `http://localhost` in the browser and magento setup wizard will begin
- Finish the wizard to sucessfully setup Magento 2

# 4. Post-Requisties

## Setup enviroment variables for magento CLI and LEMP stack
- Open `/etc/enviroment/` in editor and add the following
```
php_magento="docker exec -it php php /var/www/html/magento/bin/magento"
lemp_stack="nginx php mysql"
```
- Restart the computer
- Now Magento 2 CLI can be used using `$php_magento command` example `$php_magento setup:upgrade`
- Also all the containers in LEMP stack can be commanded using `docker command $lemp_stack` example `docker stop $lemp_stack`

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

# 5. To-Do list
- Move composer to php container

- Setup redis for cache and session storage

- Setup Varnish for php cache and reverse proxy
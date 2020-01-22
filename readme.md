# Magento 2 development enviroment under Docker

# Technologies Used
- Docker, Docker-Compose
- LEMP stack
- Composer

# 1. Pre-Requistices

## Create folders in host that will be mounted to docker containers
- Replace the `$user` with your current user

```
sudo mkdir -p /home/$user/html/magento
sudo mkdir -p /home/$user/.composer
sudo mkdir -p /var/lib/mysql
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

```

- Update the `$user` variable with your own user and save the file

## Run this command to build images and start the containers
```
docker-compose up -d
```

# 3. Setup enviroment variables for easy commands
- Open `/etc/enviroment/` in editor and add the following
```
lemp_stack="nginx php mysql"
php_magento="docker exec -it -w /var/www/html/magento php php bin/magento"
php_composer="docker exec -it -w /var/www/html/magento php composer"
php_npm="docker exec -it -w /var/www/html/magento php npm"
php_grunt="docker exec -it -w /var/www/html/magento php grunt"
```
- Restart the computer
- Now all the containers in LEMP stack can be commanded using `docker command $lemp_stack` example `docker stop $lemp_stack`
- Magento 2 CLI can be used using `$php_magento command` example `$php_magento setup:upgrade`
- Composer can be used using `$php_composer command` example `$php_composer info`
- Npm package manager can be used using `$php_npm command` example `$php_npm install`
- Grunt can be used using `$php_grunt command` example `$php_grunt exec`

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

# 5. To-Do list

- Setup redis for cache and session storage

- Setup Varnish for php cache and reverse proxy
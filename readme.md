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
4. [Install Magento 2](#4-install-magento-2)
5. [Finalize permissions and setup](#5-finalize-permissions-and-setup)
6. [Extra optimizations](#6-extra-optimizations)

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

## Set proper folder permissions
- Replace the `$user` with your current user
- Elasticsearch data needs `$user` as owner and group, `1000` will be resolved to current system user
```
sudo chown -R 1000:1000 /usr/share/elasticsearch/data
sudo chown -R www-data:www-data /home/$user/html/magento

sudo chmod -R 2775 magento /home/$user/html/magento
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
[Composer access keys](https://devdocs.magento.com/guides/v2.4/install-gde/prereq/connect-auth.html)

# 2. Follow these steps to setup the enviroment

## `git clone` this repository and cd into it

## open docker-compose.yml in editor
- Update the `$user` variable with your own user, change mysql `root` and `user` password if required and save the file

## Run this command to build images and start the containers
```
docker-compose up -d
```

# 3. Setup enviroment variables for easy commands
- Open `/etc/enviroment` in editor and add the following
- Replace `$path_to_docker_magento2` with correct path
```
magento_stack="docker-compose -f $path_to_docker_magento2/docker-compose.yml"
php_magento="docker exec -it -w /var/www/html/magento php bin/magento"
php_composer="docker exec -it -w /var/www/html/magento php composer"
redis_cli="docker exec -it redis redis-cli"
```
- Restart the pc
- Now all the containers in magento stack can be commanded using `$magento_stack command` example `$magento_stack start`
- Magento 2 CLI can be used using `$php_magento command` example `$php_magento setup:upgrade`
- Composer can be used using `$php_composer command` example `$php_composer info`
- Redis Cli can be used using `$redis_cli command` example `$redis_cli info`

# 4. Install Magento 2

## Existing project

### Clone your project and install packages
- Replace `$user` with your current user and `$repository_link` with your project link
```
cd /home/$user/html/magento

git clone $repository_link .

composer install
```
- Enter the composer access keys from magento marketplace and save it

### Configure existing enviroment
- Copy over existing `env.php` and update services credentals

### Install existing data
- Clone your existing database and import it

## Fresh instance

### Create new composer project and install packages
- Replace `$user` with your current user
```
cd /home/$user/html/magento
```
- For community edition
```
$php_composer create-project --repository=https://repo.magento.com/ magento/project-community-edition .
```
- For enterprise edttion
```
$php_composer create-project --repository=https://repo.magento.com/ magento/project-enterprise-edition .
```
- Enter the composer access keys from magento marketplace and save it

### Configure new enviroment
- Browse `http://localhost` in the browser and magento setup wizard will begin
- Finish the wizard to configure magento enviroment

### Install sample data
- Use this command to deploy sample data
```
$php_magento sampledata:deploy
```

# 5. Finalize permissions and setup

## Finalize permissions
- Replace `$user` with your current user
```
cd /home/$user/html/magento

sudo find . -type d -exec chmod g+ws {} +
sudo find . -type f -exec chmod g+w {} +
```

## Finalize setup
```
$php_magento setup:upgrade
```
Now you should have a fully working Magento 2 instance

# 6. Extra optimizations

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
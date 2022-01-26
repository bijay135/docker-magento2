# Magento 2.4 environment under Docker

# Technologies Used
- Docker / Docker-Compose
- Nginx
- Php Fpm
- Varnish
- Php Cli / Composer / Node / Npm / Grunt
- Cron
- Mysql
- Elasticsearch
- Redis
- Rabbitmq

# Contents Overview
1. [Pre-Requistices](#1-pre-requistices)
2. [Follow these steps to setup the enviroment](#2-follow-these-steps-to-setup-the-enviroment)
3. [Install Magento 2](#4-install-magento-2)
4. [Finalize setup](#5-finalize-setup)
5. [Extra optimizations](#6-extra-optimizations)

# 1. Pre-Requistices

- Install docker / docker-compose
- Get the composer access keys from magento marketplace
  [magento devdocs](https://devdocs.magento.com/guides/v2.4/install-gde/prereq/connect-auth.html)
- Install mysql-client optionally to ease database admin tasks
- Install certbot for installation on server

# 2. Follow these steps to setup the enviroment
- Clone this repository using `git clone` and `cd` into it
- Initilization can be done either for [local](#local-initialize) or [server](#server-initialize)
- Both of these scripts will do the following tasks, check for specific comparison in table below
```
- Create folders in host that will be mounted to docker containers
- Configure proper permissions
- Optimize host for elasticsearch / redis
- Configure docker-compose environment file
- Configure host environment for frequent commands
```

| **subject**                | **local initialize**             | **server initialize**            |
|----------------------------|----------------------------------|----------------------------------|
| **override compose file**  | docker-compose.local.yml         | docker-compose.server.yml        |
| **mage_root**              | /home/$HOST_USER/html/magento    | /var/www/html/$DOMAIN_NAME       |
| **auto restart policy**    | never                            | unless-stopped                   |
| **nginx sever_name / ssl** | localhost / no ssl               | $DOMAIN_NAME / with ssl          |
| **php fpm pool max child** | static, 6                        | static, 14                       |
| **varnish memory**         | 256 mb                           | 512 mb                           |
| **elasticsearch memory**   | 256 mb                           | 512 mb                           |
| **cron / rabbitmq**        | optional, add manually if needed | installed                        |

## Local initialize
- Run the script
```
sudo ./local-initialize.sh
```

## Server initialize
- Replace `$domain_name` with your domain name without `protocol` and run the script
```
sudo ./server-initialize.sh $domain_name
```

## Enviroment variables for frequent commands
- Restart the pc to apply enviroment variables set by initilization script
- All containers in magento stack use `$magento_stack command` example `$magento_stack ps`
- Magento 2 cli use `$cli_magento command` example `$cli_magento setup:upgrade`
- Composer use  `$cli_composer command` example `$cli_composer info`
- Npm use `$cli_npm command` example `$cli_npm install`
- Grunt cli use `$cli_grunt command` example `$cli_grunt exec`
- Redis cli use `$redis_cli command` example `$redis_cli info`
- Rabbitmq cli use `$rabbitmq_ctl command` example `$rabbitmq_ctl info`

## Commands for other services
- Nginx use `docker exec` example `docker exec -it nginx nginx -s reload`
- Varnish use `docker exec` example `docker exec -it varnish varnishstat`
- Mysql cli use `docker exec` for example `docker exec -it mysql mysql -u $user -p`
- Mysql admin tasks use host based `mysql-client` for example `mysqldump -h 127.0.0.1 -u $user -p`
- Elasticsearch use `curl localhost:port` example `curl localhost:9200/_cat/health?pretty`

## Up the docker enviromnment
- Edit the `.env` file set by initilization script and make any changes if required
- Run the command to build images and start the containers
```
$magento_stack up -d
```
- Run this command after previous step finishes to check if all containers are up and running
```
$magento_stack ps
```

## Generate ssl certificates and setup renew hook for installation on server
- Clear the dummy certificates set by initilization script
```
sudo rm -r /etc/letsencrypt/live/*
```
- Run the command to generate live cerificates
```
 sudo certbot certonly --webroot -w /var/www/html/$domain_name -d $domain_name
```
- For deploy hook open `/etc/letsencrypt/cli.ini` and update as follows
```
deploy-hook = docker exec -it nginx nginx -s reload
```

# 3. Install Magento 2
- Cd into your `mage_root` in host
- Installation can be done either for [existing](#existing-project) or [new](#new-project) project

## Existing project

### Clone your project and install packages
- Replace `$project_repository_link` with your project link
```
git clone $project_repository_link .

$cli_composer install
```
- Enter the composer access keys from magento marketplace and save it

### Configure existing enviroment
- Copy over existing `env.php` and update services credentals

### Install existing data and media
- Clone your existing database and import it
- Clone your existing media

## New project

### Create new composer project and install packages
- For community edition
```
$cli_composer create-project --repository=https://repo.magento.com/ magento/project-community-edition .
```
- For enterprise edttion
```
$cli_composer create-project --repository=https://repo.magento.com/ magento/project-enterprise-edition .
```
- Enter the composer access keys from magento marketplace and save it

### Configure new enviroment
- Magento web setup wizard has now been removed so follow the official devdocs to [install using cli](https://devdocs.magento.com/guides/v2.4/install-gde/composer.html#install-magento)

### Install sample data
- Use this command to deploy sample data
```
$cli_magento sampledata:deploy
```

# 4. Finalize setup
- Run the commands to finish up installation
```
$cli_magento setup:upgrade
$cli_magento indexer:reindex
$cli_magento cache:flush
```
- Now you should have a fully working Magento 2 instance

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
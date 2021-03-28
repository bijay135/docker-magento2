#!/bin/bash
set -euo pipefail

echo "Running local initialize script"

# Create folders in host that will be mounted to docker containers
echo -e "\nCreating folders in host"
mkdir -p /home/$USER/html/magento
mkdir -p /home/$USER/.composer
mkdir -p /var/lib/mysql
mkdir -p /var/lib/redis
mkdir -p /usr/share/elasticsearch/data
echo -e "Created all folders in host"

# Configure proper permissions
echo -e "\nConfiguring proper permissions"
usermod -aG www-data $USER
chown www-data:www-data /home/$USER/html/magento
chmod 2775 /home/$USER/html/magento
chown $USER:www-data /home/$USER/.composer
chmod 2775 /home/$USER/.composer
chown $USER:$USER /usr/share/elasticsearch/data
echo -e "Proper permissions configured"

# Optimize host for elasticsearch / redis
echo -e "\nOptimizing host for elasticsearch / redis"
if ! cat /etc/sysctl.conf | grep -q "Elasticsearch compatibility" ; then
	echo "
	# Elasticsearch compatibility
	vm.max_map_count=262144" >> /etc/sysctl.conf
fi
if ! cat /etc/sysctl.conf | grep -q "Redis compatibility" ; then
	echo "
	# Redis compatibility
	net.core.somaxconn=1024
	vm.overcommit_memory=1" >> /etc/sysctl.conf
fi
if [ ! -f "/etc/rc.local" ] ; then
	echo "
	#!/bin/bash
	echo never > /sys/kernel/mm/transparent_hugepage/enabled" > /etc/rc.local
	chmod +x /etc/rc.local
	systemctl start rc-local
fi
echo "Host redis / elasticsearch optimized"

# Configure docker-compose environment file
echo -e "\nConfiguring docker-compose enviroment file"
cp -af .env.dis .env
sed -i 's/$domain_name/null/g' .env
sed -i 's/$user/'"$USER"'/g' .env
sed -i 's/$es_java_opts/-Xms256m -Xmx256m/g' .env
echo "Configured docker-compose enviroment file"

# Configure host environment for frequent commands
if ! cat /etc/environment | grep -q "Magento stack" ; then
	echo -e "\nConfiguring host enviroment for frequent commands"
	echo "
	# Magento stack
	magento_stack="docker-compose -f $PWD/docker-compose.yml -f $PWD/docker-compose.local.yml "
	php_magento="docker exec -it -u www-data -w /var/www/html/magento php bin/magento"
	php_composer="docker exec -it -u www-data -w /var/www/html/magento php bash -ic $@ -- composer"
	redis_cli="docker exec -it redis redis-cli"
	rabbitmq_ctl="docker exec -it rabbitmq rabbitmqctl"" >> /etc/environment
	echo "Configured host enviroment"
else
	echo -e "\nHost enviroment already configured, skipping"
fi

echo -e "\nLocal initialize script complete"

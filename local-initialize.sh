#!/bin/bash
set -euo pipefail

echo "Running local initialize script"

# Create folders in host that will be mounted to docker containers
echo -e "\nCreating folders in host"
mkdir -p /home/$SUDO_USER/html/magento
mkdir -p /home/$SUDO_USER/.composer
mkdir -p /home/$SUDO_USER/.npm
mkdir -p /var/lib/mysql
mkdir -p /var/lib/redis
mkdir -p /usr/share/elasticsearch/data
echo -e "Created all folders in host"

# Configure proper permissions
echo -e "\nConfiguring proper permissions"
usermod -aG www-data $SUDO_USER
chown www-data:www-data /home/$SUDO_USER/html/magento
chmod 2775 /home/$SUDO_USER/html/magento
chown $SUDO_USER:www-data /home/$SUDO_USER/.composer
chmod 2775 /home/$SUDO_USER/.composer
chown $SUDO_USER:www-data /home/$SUDO_USER/.npm
chmod 2775 /home/$SUDO_USER/.npm
chown $SUDO_USER:$SUDO_USER /usr/share/elasticsearch/data
echo -e "Proper permissions configured"

# Optimize host for elasticsearch / redis
echo -e "\nRunning host optimization"
if ! cat /etc/sysctl.conf | grep -q "Elasticsearch optimization" ; then
	echo "Optimizing host for elasticsearch"
	cat >> /etc/sysctl.conf <<- EOS

	# Elasticsearch optimization
	vm.max_map_count=262144
	EOS
else
	echo "Elasticsearch already optimized, skipping"
fi
if ! cat /etc/sysctl.conf | grep -q "Redis optimization" ; then
	echo "Optimizing host for redis"
	cat >> /etc/sysctl.conf <<- EOS

	# Redis optimization
	net.core.somaxconn=1024
	vm.overcommit_memory=1
	EOS
	cat > /etc/rc.local <<- EOS
	#!/bin/bash
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	EOS
	chmod +x /etc/rc.local
	systemctl start rc-local
else
	echo "Redis already optimized skipping"
fi
sysctl -p
echo "Host optimization complete"

# Configure docker-compose environment file
if [ ! -f ".env" ] ; then
	echo -e "\nConfiguring docker-compose enviroment file"
	cp -af .env.dis .env
	sed -i 's/$varnish_size/256m/g' .env
	sed -i 's/$domain_name/null/g' .env
	sed -i 's/$user/'"$SUDO_USER"'/g' .env
	sed -i 's/$es_java_opts/-Xms256m -Xmx256m/g' .env
	echo "Configured docker-compose enviroment file"
else
	echo -e "\nEnviroment file for docker-compose already present, skipping"
fi

# Configure host environment for frequent commands
if ! cat /etc/environment | grep -q "Magento stack" ; then
	echo -e "\nConfiguring host enviroment for frequent commands"
	cat >> /etc/environment <<- EOS

	# Magento stack
	magento_stack="docker-compose -f $PWD/docker-compose.yml -f $PWD/docker-compose.local.yml"
	cli_magento="docker exec -it -u www-data -w /var/www/html/magento cli bin/magento"
	cli_composer="docker exec -it -u www-data -w /var/www/html/magento cli bash -ic \$@ -- composer"
	cli_npm="docker exec -it -u www-data -w /var/www/html/magento cli bash -ic \$@ -- npm"
	cli_grunt="docker exec -it -u www-data -w /var/www/html/magento cli bash -ic \$@ -- grunt"
	redis_cli="docker exec -it redis redis-cli"
	rabbitmq_ctl="docker exec -it rabbitmq rabbitmqctl"
	EOS
	echo "Configured host enviroment"
else
	echo -e "\nHost enviroment already configured, skipping"
fi

echo -e "\nLocal initialize script complete"

#!/bin/bash
set -euo pipefail

# Variables
DOMAIN_NAME=$1
LETSENCRYPT_PATH="/etc/letsencrypt"

echo "Running server initialize script"

# Create folders in host that will be mounted to docker containers
echo -e "\nCreating folders in host"
mkdir -p /var/www/html/$DOMAIN_NAME
mkdir -p /home/$SUDO_USER/.composer
mkdir -p /var/lib/mysql
mkdir -p /var/lib/redis
mkdir -p /usr/share/elasticsearch/data
mkdir -p /var/lib/rabbitmq
echo -e "Created all folders in host"

# Configure proper permissions
echo -e "\nConfiguring proper permissions"
usermod -aG www-data $SUDO_USER
chown www-data:www-data /var/www/html/$DOMAIN_NAME
chmod 2775 /var/www/html/$DOMAIN_NAME
chown $SUDO_USER:www-data /home/$SUDO_USER/.composer
chmod 2775 /home/$SUDO_USER/.composer
chown $SUDO_USER:$SUDO_USER /usr/share/elasticsearch/data
echo -e "Proper permissions configured"

# Optimize host for elasticsearch / redis
echo -e "\nStarting host optimization"
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
	sed -i 's/$domain_name/'"$DOMAIN_NAME"'/g' .env
	sed -i 's/$user/'"$SUDO_USER"'/g' .env
	sed -i 's/$es_java_opts/-Xms512m -Xmx512m/g' .env
	echo "Configured docker-compose enviroment file"
else
	echo -e "\nEnviroment file for docker-compose already present, skipping"
fi

# Configure host environment for frequent commands
if ! cat /etc/environment | grep -q "Magento stack" ; then
	echo -e "\nConfiguring host enviroment for frequent commands"
	cat >> /etc/environment <<- EOS

	# Magento stack
	magento_stack="docker-compose -f $PWD/docker-compose.yml -f $PWD/docker-compose.server.yml"
	php_magento="docker exec -it -u www-data -w /var/www/html/magento php bin/magento"
	php_composer="docker exec -it -u www-data -w /var/www/html/magento php bash -ic \$@ -- composer"
	redis_cli="docker exec -it redis redis-cli"
	rabbitmq_ctl="docker exec -it rabbitmq rabbitmqctl"
	node_npm="docker exec -it -u www-data -w /var/www/html/magento node bash -ic \$@ -- npm"
	node_grunt="docker exec -it -u www-data -w /var/www/html/magento node bash -ic \$@ -- grunt"
	EOS
	echo "Configured host enviroment"
else
	echo -e "\nHost enviroment already configured, skipping"
fi

# Create dummy certificates and download recommended ssl paramaters
if [ ! -d "$LETSENCRYPT_PATH/live/$DOMAIN_NAME" ] ; then
	echo -e "\nCreating dummy certificates and recommended ssl paramaters"
	mkdir -p "$LETSENCRYPT_PATH/live/$DOMAIN_NAME"
	openssl req -x509 -nodes -newkey rsa:4096 -days 1 -keyout "$LETSENCRYPT_PATH/live/$DOMAIN_NAME/privkey.pem" \
	    -out "$LETSENCRYPT_PATH/live/$DOMAIN_NAME/fullchain.pem" -subj "/CN=localhost"
	echo "Downloading recommended ssl parameters"
	curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf \
	    > "$LETSENCRYPT_PATH/options-ssl-nginx.conf"
	curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem \
	    > "$LETSENCRYPT_PATH/ssl-dhparams.pem"
	echo "Dummy certificates and recommended ssl paramaters created"
else
	echo -e "\nCertificates already present, skipping"
fi

echo -e "\nServer initialize script complete"

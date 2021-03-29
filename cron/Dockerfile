FROM php:7.4-cli

# Install required packages
RUN apt-get update && apt-get install --no-install-recommends -y \
    sudo \
    cron \
    rsyslog \
    logrotate \
\
# Configure umask module for pam
 && echo "\n# Load pam_umask module\nsession optional pam_umask.so" >> /etc/pam.d/common-session \
 && echo "\n# Load pam_umask module\nsession optional pam_umask.so" >> /etc/pam.d/common-session-noninteractive \
\
# Configure www-data user
 && chsh -s /bin/bash www-data && usermod -c "umask=002" www-data \
\
# Configure docker php extension installer
 && curl -L https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
    -o /usr/local/bin/install-php-extensions && chmod +x /usr/local/bin/install-php-extensions \
\
# Install required php extensions
 && install-php-extensions \
    bcmath \
    gd \
    intl \
    pdo_mysql \
    soap \
    xsl \
    zip \
    sockets \
    pcntl \
\
# Configure cron
 && echo "* * * * * www-data /usr/local/bin/php /var/www/html/magento/bin/magento cron:run 2>&1 | grep -v \"Ran jobs by schedule\" >> /var/www/html/magento/var/log/magento.cron.log" > /etc/cron.d/magento \
 && echo '\n# Disable mail\nMAILTO=""' >> /etc/crontab \
\
# Disable kernel logging for rsyslog
 && sed -i '/imklog/s/^/#/' /etc/rsyslog.conf
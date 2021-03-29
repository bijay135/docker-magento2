FROM php:7.4-fpm

# Install required packages
RUN apt-get update && apt-get install --no-install-recommends -y \
    sudo \
    unzip \
\
# Configure umask module for pam
 && echo "\n# Load pam_umask module\nsession optional pam_umask.so" >> /etc/pam.d/common-session \
 && echo "\n# Load pam_umask module\nsession optional pam_umask.so" >> /etc/pam.d/common-session-noninteractive \
\
# Configure www-data user
 && chsh -s /bin/bash www-data && usermod -c "umask=002" www-data \
 && chown :www-data /var/www && chmod g+w /var/www && su www-data -c 'echo "umask 002" >> /var/www/.bashrc' \
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
# Install composer
 && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=1.10.10
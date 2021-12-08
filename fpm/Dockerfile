FROM php:7.4-fpm

# Configure docker php extension installer
RUN curl -L https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
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
    pcntl
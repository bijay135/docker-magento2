FROM php:7.2-fpm

# Install dependencies
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \ 
    libicu-dev \ 
    libjpeg62-turbo-dev \ 
    libmcrypt-dev \ 
    libpng-dev \ 
    libxslt1-dev \ 
    sendmail-bin \ 
    sendmail \ 
    sudo \
\
# Configure the gd library
 && docker-php-ext-configure \
    gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
\
# Install required PHP extensions
 && docker-php-ext-install \
    sockets \
    bcmath \
    gd \
    intl \
    pdo_mysql \
    soap \
    xsl \
    zip \
    pcntl \
\
# Install Composer
 && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
\
# Install nodejs, npm and grunt-cli
 && apt-get install -y \ 
    nodejs \
    npm \
 && npm install -g \ 
    npm@latest \
    grunt-cli

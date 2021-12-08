FROM php:7.4-cli

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
    pcntl \
\
# Install required packages
 && apt-get update && apt-get install --no-install-recommends -y \
    sudo \
    unzip \
    nodejs \
    npm \
\
# Configure www-data user
 && chown :www-data /var/www && chmod g+w /var/www \
 && chsh -s /bin/bash www-data && su www-data -c 'echo "umask 002" >> /var/www/.bashrc' \
\
# Install composer
 && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=1.10.10 \
\
# Update npm and grunt-cli
 && npm install -g npm@latest grunt-cli
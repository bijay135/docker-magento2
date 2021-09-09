FROM node:16.8.0-bullseye

# Install required php extensions
RUN apt-get update && apt-get install --no-install-recommends -y \
    php7.4-cli \
    php7.4-xsl \
    php7.4-mysql \
    php7.4-intl \
\
# Install required packages
 && npm install -g npm@latest grunt-cli \
\
# Configure www-data user
 && mkdir /var/www && chown :www-data /var/www && chmod g+w /var/www \
 && chsh -s /bin/bash www-data && su www-data -c 'echo "umask 002" >> /var/www/.bashrc'
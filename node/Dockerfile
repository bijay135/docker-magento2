FROM node:16.8.0-bullseye

# Install required packages
RUN npm install -g npm@latest grunt-cli \
\
# Configure www-data user
 && mkdir /var/www && chown :www-data /var/www && chmod g+w /var/www \
 && chsh -s /bin/bash www-data && su www-data -c 'echo "umask 002" >> /var/www/.bashrc'
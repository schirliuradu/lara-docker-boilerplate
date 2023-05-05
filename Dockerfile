FROM php:8.2-fpm

# Arguments defined in docker-compose.yml
ARG PGID
ARG PUID
ARG DEFAULT_USER
ARG APP_NAME

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN groupadd -g ${PGID} ${DEFAULT_USER} && \
   useradd -l -u ${PUID} -g ${DEFAULT_USER} -m ${DEFAULT_USER} && \
   usermod -p "*" ${DEFAULT_USER} && \
   usermod -a -G ${DEFAULT_USER} www-data && \
   mkdir -p /home/${DEFAULT_USER}/.composer && \
   chown -R ${DEFAULT_USER}:${DEFAULT_USER} /home/${DEFAULT_USER}

# XDEBUG
RUN pecl install xdebug \
    &&  rm -rf /tmp/pear \
    && docker-php-ext-enable xdebug \
    && touch /var/log/xdebug_remote.log && chmod 777 /var/log/xdebug_remote.log

COPY ./xdebug.ini "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini"

RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

# Set working directory
WORKDIR /var/www

USER ${DEFAULT_USER}

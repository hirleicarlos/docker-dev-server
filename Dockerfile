FROM php:8.3-apache

ARG UID=1000
ARG GID=1000

RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libicu-dev \
    libonig-dev \
    libxml2-dev \
    unzip \
    git \
    curl \
    zip \
    nano \
    default-mysql-client \
    gnupg \
    ca-certificates \
    lsb-release \
    openssl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        mysqli \
        pdo \
        pdo_mysql \
        gd \
        intl \
        zip \
        exif \
        bcmath \
        opcache \
    && a2enmod rewrite vhost_alias ssl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY php/php.ini /usr/local/etc/php/php.ini
COPY apache/sites/vhost.conf /etc/apache2/sites-available/000-default.conf
COPY apache/sites/vhost-ssl.conf /etc/apache2/sites-available/default-ssl.conf
COPY apache/conf/servername.conf /etc/apache2/conf-enabled/servername.conf
COPY ssl/localhost.crt /etc/apache2/ssl/localhost.crt
COPY ssl/localhost.key /etc/apache2/ssl/localhost.key

RUN mkdir -p /etc/apache2/ssl \
    && a2ensite default-ssl \
    && touch /var/log/php_errors.log \
    && chmod 666 /var/log/php_errors.log

# Faz www-data usar o mesmo UID/GID do seu usuário do Linux/WSL
RUN usermod -u ${UID} www-data \
    && groupmod -g ${GID} www-data \
    && chown -R www-data:www-data /var/www \
    && chown -R www-data:www-data /var/log/apache2 \
    && chown -R www-data:www-data /var/log/php_errors.log

WORKDIR /var/www/html

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
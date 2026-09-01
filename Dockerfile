ARG PHP_VERSION=8.3
FROM php:${PHP_VERSION}-apache

# ARG declarado antes do FROM so vale na propria linha do FROM.
# Precisa ser redeclarado aqui para ficar disponivel nas instrucoes abaixo.
ARG PHP_VERSION
ARG UID=1000
ARG GID=1000

# OPcache nao entra na lista de docker-php-ext-install abaixo de proposito.
# Ja vem carregado nas imagens oficiais 8.3, 8.4 e 8.5, e a partir do 8.5 e
# compilado estaticamente - instalar de novo quebra o build. Mesmo motivo
# documentado no Dockerfile.fpm.
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libfreetype6-dev \
    libzip-dev \
    libicu-dev \
    libonig-dev \
    libxml2-dev \
    libpq-dev \
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
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install \
        mysqli \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        pgsql \
        gd \
        intl \
        mbstring \
        zip \
        exif \
        bcmath \
        soap \
        sockets \
    && a2enmod rewrite vhost_alias ssl proxy proxy_fcgi \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# O PHP passa a ser executado pelos containers PHP-FPM, nao pelo mod_php.
# Isso permite que Apache e Nginx usem sempre a mesma versao de PHP e que a
# troca entre 8.3 e 8.4 seja feita sem rebuild. Ver apache/conf/php-version.conf.
# O PHP CLI da imagem continua disponivel para Composer e scripts.
# O nome do modulo varia entre versoes da imagem oficial: nas atuais e "php",
# em outras e "php8.3". Tenta os dois e depois confirma que nenhum sobrou,
# para o build falhar aqui em vez de subir um Apache com mod_php ativo.
RUN for m in php "php${PHP_VERSION}"; do a2dismod "$m" 2>/dev/null || true; done \
    && ! ls /etc/apache2/mods-enabled/ | grep -q '^php'

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

RUN mkdir -p /etc/apache2/ssl

COPY ssl/localhost.crt /etc/apache2/ssl/localhost.crt
COPY ssl/localhost.key /etc/apache2/ssl/localhost.key

RUN a2ensite default-ssl \
    && touch /var/log/php_errors.log \
    && chmod 666 /var/log/php_errors.log

# Faz www-data usar o mesmo UID/GID do usuario Linux/WSL
RUN usermod -u ${UID} www-data \
    && groupmod -g ${GID} www-data \
    && chown -R www-data:www-data /var/www \
    && chown -R www-data:www-data /var/log/apache2 \
    && chown -R www-data:www-data /var/log/php_errors.log

WORKDIR /var/www/html

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]

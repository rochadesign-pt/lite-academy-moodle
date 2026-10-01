# Imagem do Moodle: PHP 8.3 + Apache, código oficial do Moodle "congelado" na imagem.
FROM composer:2 AS composer

FROM php:8.3-apache

ARG MOODLE_VERSION=v5.2.3

RUN apt-get update && apt-get install -y --no-install-recommends \
        git unzip ghostscript aspell graphviz \
        libpq-dev libzip-dev libicu-dev libxml2-dev \
        libpng-dev libjpeg62-turbo-dev libfreetype-dev libwebp-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j"$(nproc)" pgsql intl zip gd soap exif opcache \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && rm -rf /var/lib/apt/lists/* /tmp/pear

COPY --from=composer /usr/bin/composer /usr/bin/composer

# Código do Moodle (pertence ao root: o servidor web só lê, não escreve)
RUN git clone --depth 1 --branch "${MOODLE_VERSION}" https://github.com/moodle/moodle.git /var/www/moodle \
    && cd /var/www/moodle \
    && composer install --no-dev --classmap-authoritative --no-interaction --no-progress \
    && rm -rf .git /root/.composer \
    && mkdir -p /var/moodledata && chown www-data:www-data /var/moodledata

COPY config.php /var/www/moodle/config.php
COPY php.ini /usr/local/etc/php/conf.d/moodle.ini
COPY apache.conf /etc/apache2/sites-available/000-default.conf
COPY mpm.conf /etc/apache2/mods-available/mpm_prefork.conf

RUN a2enmod rewrite remoteip headers expires

WORKDIR /var/www/moodle

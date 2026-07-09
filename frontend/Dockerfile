FROM php:8.3-cli

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      libpq-dev curl unzip git && \
    rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install pdo_pgsql

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

COPY composer.json composer.lock ./
RUN COMPOSER_POLICY_ADVISORIES_BLOCK=false composer install --no-dev --no-interaction --no-progress --optimize-autoloader --no-scripts

COPY . .

RUN cp .env.example .env && \
    php artisan package:discover --ansi && \
    php artisan key:generate --ansi && \
    chmod -R 777 storage bootstrap/cache

EXPOSE 80

CMD php artisan serve --host=0.0.0.0 --port=80

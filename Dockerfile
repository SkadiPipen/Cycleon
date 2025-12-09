FROM php:8.3-fpm

# System dependencies
RUN apt-get update && apt-get install -y \
    curl git unzip libzip-dev build-essential nodejs npm python3 \
    && docker-php-ext-install zip bcmath \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

# Copy composer files first
COPY composer.json composer.lock ./
RUN php -d memory_limit=-1 /usr/bin/composer install --no-dev --no-interaction --prefer-dist --ignore-platform-reqs --no-scripts

# Copy rest of the app
COPY . .

# Node build
RUN npm install --legacy-peer-deps
RUN npm run build

# Permissions
RUN chown -R www-data:www-data storage bootstrap/cache

EXPOSE 10000

CMD ["php-fpm"]

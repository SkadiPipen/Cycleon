# Use PHP-FPM for production
FROM php:8.3-fpm

# System dependencies
RUN apt-get update && apt-get install -y \
    curl git unzip libzip-dev build-essential nodejs npm python3 \
    && docker-php-ext-install zip bcmath \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /var/www/html

# Copy project
COPY . .

# PHP dependencies
RUN php -d memory_limit=-1 /usr/bin/composer install --no-dev --optimize-autoloader --ignore-platform-reqs --no-scripts

# Node packages + build
RUN npm install --legacy-peer-deps
RUN npm run build

# Fix permissions
RUN chown -R www-data:www-data storage bootstrap/cache

# Expose port Render will use
EXPOSE 10000

# Start PHP-FPM
CMD ["php-fpm"]

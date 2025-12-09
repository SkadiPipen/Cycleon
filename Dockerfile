FROM php:8.3-cli

# Install system dependencies + build tools
RUN apt-get update && apt-get install -y \
    curl git unzip libzip-dev build-essential python3 \
    && docker-php-ext-install zip bcmath \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Node 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .

# Install PHP dependencies without scripts
RUN php -d memory_limit=-1 /usr/bin/composer install --no-dev --optimize-autoloader --ignore-platform-reqs --no-scripts

# Install Node packages and build frontend
RUN npm install --legacy-peer-deps
RUN npm run build

EXPOSE 10000

# Render: use PORT env variable
CMD php artisan serve --host=0.0.0.0 --port=${PORT:-10000}

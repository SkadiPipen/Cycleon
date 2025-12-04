FROM php:8.5-cli

# 1. Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

# 2. Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 3. Copy your code
WORKDIR /var/www/html
COPY . .

# 4. Install everything and build - WITH PHP 8.4 FLAG
RUN composer install --no-dev --optimize-autoloader --ignore-platform-reqs \
    && npm ci \
    && npm run build

# 5. Start the server
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=${PORT:-8080}"]

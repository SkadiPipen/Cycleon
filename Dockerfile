FROM php:8.2-cli

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .

# Install all dependencies and build
RUN composer install --no-dev --optimize-autoloader \
    && npm ci \
    && npm run build

# Start server on Render's dynamic port
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=${PORT:-8080}"]

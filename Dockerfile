FROM php:8.3-cli

# 1. Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

# 2. Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .

# 3. Create a fresh composer.lock if needed
RUN if [ ! -f "composer.lock" ]; then \
        composer update --no-dev --ignore-platform-reqs; \
    fi

# 4. Try to install with more memory and retry on failure
RUN php -d memory_limit=-1 /usr/bin/composer install --no-dev --optimize-autoloader --ignore-platform-reqs || \
    php -d memory_limit=-1 /usr/bin/composer update --no-dev --optimize-autoloader --ignore-platform-reqs

# 5. Install Node.js dependencies and build
RUN npm ci && npm run build

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=${PORT:-8080}"]

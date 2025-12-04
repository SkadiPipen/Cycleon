FROM php:8.3-cli

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libzip-dev \
    && docker-php-ext-install zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 1. Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm

# 2. Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# 3. Copy composer files first for better caching
COPY composer.json composer.lock* ./

# 4. Install Composer dependencies with more robust approach
RUN if [ -f composer.lock ]; then \
        php -d memory_limit=-1 /usr/bin/composer install --no-dev --optimize-autoloader --ignore-platform-reqs --no-scripts; \
    else \
        php -d memory_limit=-1 /usr/bin/composer update --no-dev --optimize-autoloader --ignore-platform-reqs --no-scripts; \
    fi

# 5. Copy the rest of the application
COPY . .

# 6. Run Composer scripts after copying all files
RUN php -d memory_limit=-1 /usr/bin/composer run-script post-install-cmd --no-interaction || true

# 7. Install Node.js dependencies and build
COPY package.json package-lock.json* ./
RUN if [ -f package-lock.json ]; then \
        npm ci --only=production; \
    else \
        npm install --production; \
    fi

# 8. Build assets (if you have build script)
RUN npm run build --if-present

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=${PORT:-8080}"]

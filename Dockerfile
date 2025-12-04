FROM php:8.3-cli

# Install system dependencies including for Vite
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

# 3. Copy composer files
COPY composer.json composer.lock* ./

# 4. Install Composer dependencies
RUN if [ -f composer.lock ]; then \
        COMPOSER_MEMORY_LIMIT=-1 composer install --no-dev --optimize-autoloader --ignore-platform-reqs --no-scripts; \
    else \
        COMPOSER_MEMORY_LIMIT=-1 composer update --no-dev --optimize-autoloader --ignore-platform-reqs --no-scripts; \
    fi

# 5. Copy package files
COPY package.json package-lock.json* ./

# 6. Install npm dependencies WITH dev dependencies (needed for Vite)
# Force clean install to avoid lockfile issues
RUN npm ci --no-audit --no-fund || npm install --no-audit --no-fund --legacy-peer-deps

# 7. Copy the rest of the application
COPY . .

# 8. Generate Laravel key if needed
RUN if [ -f artisan ]; then \
        php artisan key:generate --force --no-interaction || true; \
    fi

# 9. Build Vite assets
RUN npm run build

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=${PORT:-8080}"]

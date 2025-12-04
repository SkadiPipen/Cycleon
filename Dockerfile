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

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy application
COPY . .

# Install PHP dependencies
RUN if [ -f composer.lock ]; then \
        php -d memory_limit=-1 /usr/bin/composer install --no-dev --optimize-autoloader --ignore-platform-reqs; \
    else \
        php -d memory_limit=-1 /usr/bin/composer update --no-dev --optimize-autoloader --ignore-platform-reqs; \
    fi

# Install Node dependencies
RUN npm install --no-audit --no-fund --legacy-peer-deps

# Build assets
RUN npm run build

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8080"]

FROM php:8.3-cli

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libzip-dev \
    && docker-php-ext-install zip bcmath \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .

# Set production environment variables
ENV APP_ENV=production
ENV APP_DEBUG=false

RUN php -d memory_limit=-1 /usr/bin/composer install --no-dev --optimize-autoloader --ignore-platform-reqs

# Clear any existing config cache
RUN php artisan config:clear

# IMPORTANT: Set APP_URL to HTTPS during build
ENV APP_URL=https://cycleonn.onrender.com
ENV ASSET_URL=https://cycleonn.onrender.com  # CRITICAL FOR ASSETS

# Build assets with correct URL
RUN npm install --no-audit --no-fund --legacy-peer-deps
RUN npm run build

# Force HTTPS in Laravel
RUN echo "<?php \
// Force HTTPS middleware - add to public/index.php
if (!empty(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https') { \
    \$_SERVER['HTTPS'] = 'on'; \
} \
if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] == 'http') { \
    \$redirect = 'https://' . \$_SERVER['HTTP_HOST'] . \$_SERVER['REQUEST_URI']; \
    header('HTTP/1.1 301 Moved Permanently'); \
    header('Location: ' . \$redirect); \
    exit(); \
} \
?>" > /tmp/force_https.php

# Prepend force HTTPS code to index.php
RUN cat /tmp/force_https.php public/index.php > /tmp/index.php && mv /tmp/index.php public/index.php

# Clear all caches AFTER setting environment
RUN php artisan config:cache
RUN php artisan route:clear
RUN php artisan view:clear

EXPOSE 10000

CMD php artisan serve --host=0.0.0.0 --port=10000

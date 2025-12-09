# ------------------------------
# Stage 1: Composer (multi-stage)
# ------------------------------
FROM composer:latest AS composer

# ------------------------------
# Stage 2: PHP + Node.js
# ------------------------------
FROM php:8.3-cli

# Install PHP extensions and basic tools
RUN apt-get update && apt-get install -y \
    git unzip curl libzip-dev \
    && docker-php-ext-install zip bcmath \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (v22)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

# Set working directory
WORKDIR /var/www/html

# Copy project files
COPY . .
COPY .env.example .env

# Copy Composer from stage 1
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Install PHP dependencies (skip scripts to avoid DB errors)
RUN php -d memory_limit=-1 /usr/bin/composer install --no-dev --optimize-autoloader --ignore-platform-reqs --no-scripts

# Optional: generate APP_KEY
RUN php artisan key:generate

# Install Node dependencies and build assets
RUN npm install --no-audit --no-fund --legacy-peer-deps
RUN npm run build

# Force Laravel to generate HTTPS URLs
RUN php artisan config:clear
RUN php artisan cache:clear
RUN php artisan route:clear
RUN php artisan view:clear

# Expose port for Laravel
EXPOSE 10000

# Run Laravel
CMD php artisan serve --host=0.0.0.0 --port=10000

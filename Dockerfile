# Dockerfile
# Stage 1: Build frontend with Node 20
FROM node:20-alpine AS frontend

WORKDIR /app

# Copy package files first
COPY package*.json ./

# Install ALL dependencies (including devDependencies for build)
RUN npm ci

# Copy the rest
COPY . .

# Build with more memory
RUN NODE_OPTIONS="--max-old-space-size=4096" npm run build

# Stage 2: Build backend
FROM php:8.2-cli-alpine

WORKDIR /app

# Install system dependencies
RUN apk add --no-cache \
    curl \
    git \
    unzip \
    libzip-dev \
    oniguruma-dev \
    sqlite \
    && docker-php-ext-install \
        pdo \
        pdo_sqlite \
        zip \
        mbstring

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy Laravel files
COPY . .

# Copy built assets from frontend stage
COPY --from=frontend /app/public/build ./public/build

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Set permissions
RUN chmod -R 775 storage bootstrap/cache

# Generate application key
RUN php artisan key:generate --force

# Cache config for production
RUN php artisan config:cache && \
    php artisan route:cache

EXPOSE 8000

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]

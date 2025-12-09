FROM php:8.3-cli

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libzip-dev \
    build-essential \
    python3 \
    && docker-php-ext-install zip bcmath \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy PHP files first
COPY composer.json composer.lock ./
RUN php -d memory_limit=-1 /usr/bin/composer install --no-dev --optimize-autoloader --ignore-platform-reqs --no-scripts

# Copy frontend files and build
COPY package*.json ./
COPY resources/js resources/js
COPY resources/css resources/css
RUN npm install --legacy-peer-deps
RUN npm run build --verbose

# Copy rest of Laravel files
COPY . .

EXPOSE 10000
CMD php artisan serve --host=0.0.0.0 --port=10000

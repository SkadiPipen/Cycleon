FROM php:8.3-cli

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libzip-dev \
    libpq-dev \
    postgresql-client \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install \
        zip \
        pdo \
        pdo_pgsql \
        pgsql \
        bcmath \
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
RUN php -d memory_limit=-1 /usr/bin/composer install --no-dev --optimize-autoloader --ignore-platform-reqs

# Install Node dependencies
RUN npm install --no-audit --no-fund --legacy-peer-deps

# Setup Laravel
RUN if [ -f artisan ]; then \
        # Create .env if it doesn't exist
        [ -f .env ] || cp .env.example .env 2>/dev/null || echo "No .env.example found" && \
        # Generate key
        php artisan key:generate --force --no-interaction || true; \
        # Cache configuration
        php artisan config:cache || true; \
        php artisan route:cache || true; \
        php artisan view:cache || true; \
    fi

# Build assets
RUN npm run build

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8080"]

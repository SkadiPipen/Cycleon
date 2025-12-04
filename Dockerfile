FROM php:8.3-cli

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libzip-dev \
    libpq-dev \
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

# Copy application WITHOUT .env (we'll create it)
COPY . .

# Create .env from .env.example if .env doesn't exist
RUN if [ ! -f .env ]; then \
        if [ -f .env.example ]; then \
            cp .env.example .env; \
            echo "Created .env from .env.example"; \
        else \
            echo "No .env.example found"; \
        fi; \
    fi

# Install PHP dependencies
RUN php -d memory_limit=-1 /usr/bin/composer install --no-dev --optimize-autoloader --ignore-platform-reqs

# Install Node dependencies
RUN npm install --no-audit --no-fund --legacy-peer-deps

# Setup Laravel - NO CONFIG CACHING!
RUN if [ -f artisan ]; then \
        # Generate app key \
        php artisan key:generate --force --no-interaction 2>/dev/null || true; \
        # Clear any cached config \
        php artisan config:clear 2>/dev/null || true; \
    fi

# Build assets
RUN npm run build

# Start command - NO CONFIG CACHING HERE EITHER!
CMD php artisan serve --host=0.0.0.0 --port=8080

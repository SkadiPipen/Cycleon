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

# 5. Copy package.json and package-lock.json for npm
COPY package.json package-lock.json* ./

# 6. Install Node.js dependencies - FIXED APPROACH
# First update npm to latest
RUN npm install -g npm@latest

# Install npm dependencies (use npm install instead of npm ci to handle lockfile mismatch)
RUN if [ -f package-lock.json ]; then \
        # Try npm ci first, if it fails use npm install
        npm ci --only=production --omit=dev || npm install --production --no-audit --no-fund; \
    else \
        npm install --production --no-audit --no-fund; \
    fi

# 7. Copy the rest of the application
COPY . .

# 8. Run Composer scripts after copying all files
RUN php -d memory_limit=-1 /usr/bin/composer run-script post-install-cmd --no-interaction || true

# 9. Build assets (if you have build script)
RUN npm run build --if-present

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=${PORT:-8080}"]

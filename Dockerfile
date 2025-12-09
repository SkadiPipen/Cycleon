WORKDIR /var/www/html

COPY . .
COPY .env.example .env

# Install PHP dependencies, skip scripts to avoid package:discover errors
RUN php -d memory_limit=-1 /usr/bin/composer install --no-dev --optimize-autoloader --ignore-platform-reqs --no-scripts

# Install Node dependencies
RUN npm install --no-audit --no-fund --legacy-peer-deps
RUN npm run build

# Optional: generate APP_KEY
RUN php artisan key:generate

EXPOSE 10000
CMD php artisan serve --host=0.0.0.0 --port=10000

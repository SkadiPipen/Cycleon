#!/bin/bash
# .platform/setup.sh

echo "Installing PHP and dependencies..."
apt-get update
apt-get install -y software-properties-common
add-apt-repository ppa:ondrej/php -y
apt-get update
apt-get install -y php8.2 php8.2-common php8.2-cli php8.2-mbstring php8.2-xml php8.2-zip php8.2-curl composer

echo "PHP version:"
php --version
echo "Composer version:"
composer --version

#!/bin/bash

# Update system
sudo apt update && sudo apt upgrade -y

# Install Nginx
sudo apt install nginx -y

# Install PHP and necessary extensions
sudo apt install php-fpm php-mysql php-xml php-mbstring php-curl php-zip -y

# Install MySQL
sudo apt install mysql-server -y

# Secure MySQL installation
sudo mysql_secure_installation

# Install Composer
sudo apt install curl php-cli php-mbstring git unzip -y
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Install Laravel
composer global require laravel/installer

# Configure Nginx for Laravel
sudo bash -c 'cat > /etc/nginx/sites-available/laravel <<EOF
server {
    listen 80;
    server_name your_domain_or_IP;

    root /var/www/laravel/public;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$SCRIPT_FILENAME;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF'

# Enable Laravel site and restart Nginx
sudo ln -s /etc/nginx/sites-available/laravel /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Create Laravel project
mkdir -p /var/www/laravel
cd /var/www/laravel
composer create-project --prefer-dist laravel/laravel .

# Set appropriate permissions
sudo chown -R www-data:www-data /var/www/laravel
sudo chmod -R 775 /var/www/laravel/storage
sudo chmod -R 775 /var/www/laravel/bootstrap/cache

echo "Setup complete! Please configure your MySQL database and update your .env file accordingly."

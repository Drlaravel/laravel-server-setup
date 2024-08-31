#!/bin/bash

# Enable debugging for the script
set -euo pipefail

# Function to display a dynamic menu
function show_menu() {
    echo "------------------------------------------------"
    echo " Laravel Server Configuration Script - Ultimate Edition"
    echo "------------------------------------------------"
    echo "1. Check and Install Apache"
    echo "2. Check and Install PHP & Required Extensions"
    echo "3. Check and Install Composer"
    echo "4. Check and Install MySQL Server"
    echo "5. Configure Apache Virtual Host"
    echo "6. Enable SSL (Let's Encrypt)"
    echo "7. Configure Firewall"
    echo "8. Backup Database"
    echo "9. Install Supervisor for Laravel Queues"
    echo "10. Switch Environment (Production/Development)"
    echo "11. Exit"
    echo "------------------------------------------------"
    echo -n "Please enter your choice [1-11]: "
}

# Function to check if a package is installed
function check_and_install() {
    local pkg=$1
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "$pkg is already installed."
    else
        echo "$pkg is not installed. Installing..."
        sudo apt install -y "$pkg"
    fi
}

# Function to install and configure Apache
function configure_apache() {
    check_and_install "apache2"
}

# Function to install PHP and required extensions
function configure_php() {
    PHP_VERSION="8.2"
    echo "Checking and Installing PHP $PHP_VERSION and required extensions..."
    sudo apt install software-properties-common -y
    sudo add-apt-repository ppa:ondrej/php -y
    sudo apt update
    local php_packages=("php$PHP_VERSION" "libapache2-mod-php$PHP_VERSION" "php${PHP_VERSION}-mysql" "php${PHP_VERSION}-xml" "php${PHP_VERSION}-mbstring" "php${PHP_VERSION}-zip" "php${PHP_VERSION}-curl" "php${PHP_VERSION}-gd" "php${PHP_VERSION}-bcmath" "php${PHP_VERSION}-dom")
    for package in "${php_packages[@]}"; do
        check_and_install "$package"
    done
}

# Function to install Composer
function install_composer() {
    if command -v composer >/dev/null 2>&1; then
        echo "Composer is already installed."
    else
        echo "Installing Composer..."
        curl -sS https://getcomposer.org/installer | php
        sudo mv composer.phar /usr/local/bin/composer
    fi
}

# Function to install MySQL Server
function install_mysql() {
    check_and_install "mysql-server"
    echo "Running MySQL secure installation..."
    sudo mysql_secure_installation
}

# Function to configure Apache Virtual Host
function configure_virtual_host() {
    echo -n "Enter your project domain (e.g., example.com): "
    read DOMAIN
    echo -n "Enter the path to your Laravel project (e.g., /var/www/html/yourproject): "
    read PROJECT_PATH

    VHOST_CONFIG="/etc/apache2/sites-available/${DOMAIN}.conf"
    echo "Configuring Apache Virtual Host for $DOMAIN..."
    sudo bash -c "cat > $VHOST_CONFIG" << EOL
<VirtualHost *:80>
    ServerAdmin admin@${DOMAIN}
    ServerName ${DOMAIN}
    DocumentRoot ${PROJECT_PATH}/public

    <Directory ${PROJECT_PATH}>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

    echo "Enabling site ${DOMAIN}..."
    sudo a2ensite "${DOMAIN}.conf"
    sudo a2enmod rewrite
    echo "Restarting Apache..."
    sudo systemctl restart apache2
}

# Function to enable SSL using Let's Encrypt
function enable_ssl() {
    check_and_install "certbot"
    echo -n "Enter your project domain (e.g., example.com): "
    read DOMAIN
    sudo certbot --apache -d "$DOMAIN"
    echo "SSL has been enabled for $DOMAIN!"
}

# Function to configure the firewall
function configure_firewall() {
    echo "Configuring UFW firewall..."
    sudo ufw allow OpenSSH
    sudo ufw allow 'Apache Full'
    sudo ufw enable
    echo "Firewall has been configured and enabled."
}

# Function to backup MySQL database
function backup_database() {
    echo -n "Enter the database name to backup: "
    read DB_NAME
    echo -n "Enter MySQL username: "
    read DB_USER
    echo -n "Enter MySQL password: "
    read -s DB_PASS
    BACKUP_PATH="./backup_${DB_NAME}_$(date +%F_%T).sql"
    echo "Backing up database $DB_NAME to $BACKUP_PATH..."
    mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_PATH"
    echo "Backup completed: $BACKUP_PATH"
}

# Function to install Supervisor for Laravel Queues
function install_supervisor() {
    check_and_install "supervisor"
    echo "Supervisor has been installed."
    echo "Configuring Supervisor for Laravel Queues..."
    echo -n "Enter the path to your Laravel project (e.g., /var/www/html/yourproject): "
    read PROJECT_PATH
    sudo bash -c "cat > /etc/supervisor/conf.d/laravel-worker.conf" << EOL
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php ${PROJECT_PATH}/artisan queue:work --sleep=3 --tries=3
autostart=true
autorestart=true
user=www-data
numprocs=1
redirect_stderr=true
stdout_logfile=${PROJECT_PATH}/storage/logs/worker.log
EOL
    sudo supervisorctl reread
    sudo supervisorctl update
    sudo supervisorctl start laravel-worker:*
    echo "Supervisor has been configured for Laravel Queues."
}

# Function to switch environment settings
function switch_environment() {
    echo -n "Enter the path to your Laravel project (e.g., /var/www/html/yourproject): "
    read PROJECT_PATH
    echo "Switching Laravel environment..."
    if grep -q "APP_ENV=production" "${PROJECT_PATH}/.env"; then
        sed -i 's/APP_ENV=production/APP_ENV=local/' "${PROJECT_PATH}/.env"
        sed -i 's/APP_DEBUG=false/APP_DEBUG=true/' "${PROJECT_PATH}/.env"
        echo "Switched to Development environment."
    else
        sed -i 's/APP_ENV=local/APP_ENV=production/' "${PROJECT_PATH}/.env"
        sed -i 's/APP_DEBUG=true/APP_DEBUG=false/' "${PROJECT_PATH}/.env"
        echo "Switched to Production environment."
    fi
}

# Main script execution
while true; do
    show_menu
    read choice
    case $choice in
        1) configure_apache ;;
        2) configure_php ;;
        3) install_composer ;;
        4) install_mysql ;;
        5) configure_virtual_host ;;
        6) enable_ssl ;;
        7) configure_firewall ;;
        8) backup_database ;;
        9) install_supervisor ;;
        10) switch_environment ;;
        11) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option! Please try again."; continue ;;
    esac
done

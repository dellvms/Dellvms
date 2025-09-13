#!/bin/bash
# Pterodactyl Panel + Wings + Node Automated Setup
# Tested on Ubuntu 22.04 / Debian 12

# Exit on error
set -e

# Update system
echo "Updating system..."
apt update -y && apt upgrade -y

# Install dependencies
echo "Installing dependencies..."
apt install -y curl wget unzip tar git software-properties-common gnupg lsb-release ca-certificates apt-transport-https

# Install PHP and extensions (required for panel)
echo "Installing PHP..."
add-apt-repository ppa:ondrej/php -y
apt update -y
apt install -y php8.2 php8.2-cli php8.2-fpm php8.2-mysql php8.2-xml php8.2-mbstring php8.2-bcmath php8.2-curl php8.2-gd php8.2-intl php8.2-zip composer unzip

# Install MariaDB
echo "Installing MariaDB..."
apt install -y mariadb-server mariadb-client
systemctl enable mariadb
systemctl start mariadb

# Secure MariaDB
echo "Securing MariaDB..."
mysql_secure_installation

# Install Node.js (for Wings)
echo "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Install Docker (required for Wings)
echo "Installing Docker..."
curl -fsSL https://get.docker.com | bash
systemctl enable docker
systemctl start docker

# Install Pterodactyl Panel
echo "Installing Pterodactyl Panel..."
cd /var/www/
git clone https://github.com/pterodactyl/panel.git pterodactyl
cd pterodactyl
composer install --no-dev --optimize-autoloader
cp .env.example .env
php artisan key:generate

# Set permissions
chown -R www-data:www-data /var/www/pterodactyl
chmod -R 755 /var/www/pterodactyl/storage /var/www/pterodactyl/bootstrap/cache

# Install Wings
echo "Installing Wings..."
curl -L https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64 -o /usr/local/bin/wings
chmod +x /usr/local/bin/wings

# Enable Wings service
echo "Setting up Wings service..."
cat <<EOF >/etc/systemd/system/wings.service
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/local/bin/wings
Restart=on-failure
User=root
WorkingDirectory=/root
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

systemctl enable wings
systemctl start wings

echo "Pterodactyl Panel + Wings setup completed!"
echo "Please configure your .env file and run 'php artisan migrate --seed' to finish panel setup."

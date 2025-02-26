#!/bin/bash
# AutoServer Setup Script
# This script will install and configure a web server (Nginx/Apache, PHP, MySQL),
# set up a firewall using UFW, deploy a Let's Encrypt SSL certificate,
# and create a simple backup of your server configuration.
#
# NOTE: This script is intended for Ubuntu/Debian-based systems.
# Make sure to run this script as root (or with sudo).

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Please run with sudo."
    exit 1
fi

echo "Starting AutoServer setup..."

# Prompt the user to choose the web server
echo "Select your web server:"
echo "1) Nginx"
echo "2) Apache"
read -p "Enter choice [1 or 2]: " SERVER_CHOICE

if [ "$SERVER_CHOICE" == "1" ]; then
    WEB_SERVER="nginx"
    CERTBOT_PLUGIN="nginx"
    FIREWALL_SERVICE="Nginx Full"
elif [ "$SERVER_CHOICE" == "2" ]; then
    WEB_SERVER="apache2"
    CERTBOT_PLUGIN="apache"
    FIREWALL_SERVICE="Apache Full"
else
    echo "Invalid choice. Defaulting to Nginx."
    WEB_SERVER="nginx"
    CERTBOT_PLUGIN="nginx"
    FIREWALL_SERVICE="Nginx Full"
fi

echo "Selected web server: $WEB_SERVER"

# Update package list and install required packages
echo "Updating package list..."
apt update

echo "Installing $WEB_SERVER, PHP, MySQL, Certbot, UFW, and other required packages..."
apt install -y $WEB_SERVER php php-fpm php-mysql mysql-server certbot python3-certbot-$CERTBOT_PLUGIN ufw htop

echo "$WEB_SERVER, PHP, MySQL, Certbot, UFW, and htop installed."

# Configure UFW Firewall
echo "Configuring UFW firewall..."
ufw allow OpenSSH
ufw allow "$FIREWALL_SERVICE"
ufw --force enable

echo "Firewall configured: OpenSSH and $FIREWALL_SERVICE are allowed."

# Deploy Let's Encrypt SSL certificate
read -p "Enter your domain name for the SSL certificate (e.g., example.com): " DOMAIN
read -p "Enter your email address for SSL registration: " EMAIL

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "Domain name and email are required for SSL certificate deployment. Skipping SSL setup."
else
    echo "Obtaining SSL certificate for $DOMAIN..."
    certbot --$CERTBOT_PLUGIN -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL"
    echo "SSL certificate deployed for $DOMAIN."
fi

# Create a backup of server configuration
BACKUP_DIR="/root/server_backup_$(date +'%Y%m%d')"
echo "Creating backup of server configuration at $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"

if [ "$WEB_SERVER" == "nginx" ]; then
    cp -r /etc/nginx "$BACKUP_DIR/"
elif [ "$WEB_SERVER" == "apache2" ]; then
    cp -r /etc/apache2 "$BACKUP_DIR/"
fi

cp -r /etc/mysql "$BACKUP_DIR/"
echo "Backup completed at $BACKUP_DIR."

echo "AutoServer setup complete. Your server is now configured!"

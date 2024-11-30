#!/bin/bash

# Script version
SCRIPT_VERSION="1.0.0"

# Configure error handling
set -e
set -o pipefail

# Setup logging
LOG_FILE="/var/log/orchardcms_install.log"
exec 1> >(tee -a "$LOG_FILE") 2>&1

# Configuration variables
: "${ORCHARD_PORT:=5000}"
: "${NGINX_PORT:=80}"
: "${ORCHARD_USER:=ec2-user}"
: "${INSTALL_DIR:=/var/www/orchardcms}"
: "${DOTNET_VERSION:=8.0}"
: "${ORCHARD_TEMPLATE_VERSION:=2.1.0}"
PUBLIC_IP=""

# Logging functions
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

# Enhanced error checking
check_status() {
    if [ $? -ne 0 ]; then
        log_error "$1"
        exit 1
    fi
}

# Dependency verification
verify_dependencies() {
    local deps=("curl" "sudo" "systemctl")
    for dep in "${deps[@]}"; do
        if ! command -v $dep &> /dev/null; then
            log_error "Required dependency not found: $dep"
            return 1
        fi
    done
}

# Check .NET version
check_dotnet_version() {
    if ! command -v dotnet &> /dev/null; then
        log_error ".NET SDK not found"
        return 1
    fi
    local installed_version=$(dotnet --version)
    log_message "Found .NET version: $installed_version"
}

# Backup existing installation
backup_existing_installation() {
    if [ -d "$INSTALL_DIR" ]; then
        local backup_dir="${INSTALL_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
        log_message "Creating backup at $backup_dir"
        cp -r "$INSTALL_DIR" "$backup_dir"
    fi
}

# Get latest Orchard template version
get_latest_template_version() {
    local latest_version=$(curl -s https://api.nuget.org/v3-flatcontainer/orchardcore.projecttemplates/index.json | jq -r '.versions[-1]' 2>/dev/null)
    if [ $? -eq 0 ] && [ ! -z "$latest_version" ]; then
        ORCHARD_TEMPLATE_VERSION=$latest_version
        log_message "Using latest OrchardCore template version: $ORCHARD_TEMPLATE_VERSION"
    else
        log_message "Using default OrchardCore template version: $ORCHARD_TEMPLATE_VERSION"
    fi
}

# Cleanup function
cleanup() {
    log_message "Cleaning up temporary files..."
    rm -f /tmp/orchardcms_*
    if [ $? -eq 0 ]; then
        log_message "Installation completed successfully"
    else
        log_message "Installation completed with warnings"
    fi
}

# Register cleanup
trap cleanup EXIT

# Start main installation
log_message "Starting OrchardCMS installation script v${SCRIPT_VERSION}"

# Verify dependencies
verify_dependencies
check_status "Dependency verification failed"

# Function to check IMDS version and get public IP
get_public_ip() {
    # Try IMDSv2 first
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)
    if [ $? -eq 0 ]; then
        # IMDSv2 is available
        PUBLIC_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4)
        echo "Using IMDSv2"
    else
        # Fallback to IMDSv1
        PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
        echo "Using IMDSv1"
    fi

    if [ -z "$PUBLIC_IP" ]; then
        echo "Error: Could not retrieve public IP"
        exit 1
    fi
    echo "Public IP: $PUBLIC_IP"
}

# Install .NET SDK 8.0
echo "Installing .NET SDK 8.0..."
sudo curl -o /etc/yum.repos.d/packages-microsoft-com-prod.repo https://packages.microsoft.com/config/fedora/39/prod.repo
sudo dnf install -y dotnet-sdk-8.0
check_status "Failed to install .NET SDK"

# Install Nginx
echo "Installing Nginx..."
sudo dnf install -y nginx
check_status "Failed to install Nginx"

# Create application directory and set initial permissions
echo "Creating application directory..."
sudo mkdir -p /var/www/orchardcms
sudo chown -R ec2-user:ec2-user /var/www/orchardcms
sudo chmod -R 755 /var/www/orchardcms
cd /var/www/orchardcms || exit 1

# Ensure ec2-user has proper permissions
sudo -u ec2-user mkdir -p /var/www/orchardcms/MySite

# Install OrchardCore templates and create site as ec2-user
echo "Installing OrchardCore templates..."
sudo -u ec2-user dotnet new install OrchardCore.ProjectTemplates::2.1.0 --force
sudo -u ec2-user dotnet new occms -n MySite
check_status "Failed to create OrchardCMS site"

# Create appsettings.json with proper ownership
echo "Creating appsettings.json..."
sudo -u ec2-user bash -c 'cat << EOF > /var/www/orchardcms/MySite/appsettings.json
{
  "Logging": {
    "IncludeScopes": false,
    "LogLevel": {
      "Default": "Warning",
      "Microsoft.Hosting.Lifetime": "Information"
    }
  },
  "Kestrel": {
    "Endpoints": {
      "Http": {
        "Url": "http://0.0.0.0:5000"
      }
    }
  }
}
EOF'

# Get public IP
get_public_ip

# Create systemd service file
echo "Creating systemd service file..."
cat << EOF | sudo tee /etc/systemd/system/orchardcms.service
[Unit]
Description=Orchard CMS Web Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/var/www/orchardcms/MySite
ExecStart=/usr/bin/dotnet run --project MySite.csproj
Restart=always
RestartSec=10
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://*:5000
Environment=HOME=/home/ec2-user

[Install]
WantedBy=multi-user.target
EOF

# Create Nginx configuration
echo "Creating Nginx configuration..."
cat << EOF | sudo tee /etc/nginx/conf.d/orchardcms.conf
server {
    listen 80;
    server_name ${PUBLIC_IP};

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Test Nginx configuration
echo "Testing Nginx configuration..."
sudo nginx -t
check_status "Nginx configuration test failed"

# Set correct permissions for service files
echo "Setting permissions..."
sudo chmod 644 /etc/systemd/system/orchardcms.service
sudo chown root:root /etc/systemd/system/orchardcms.service

# Ensure proper permissions for application directory
sudo chown -R ec2-user:ec2-user /var/www/orchardcms
sudo chmod -R 755 /var/www/orchardcms
sudo chmod -R +x /var/www/orchardcms/MySite/bin 2>/dev/null || true

# Create and set permissions for log directory
sudo mkdir -p /var/log/orchardcms
sudo chown ec2-user:ec2-user /var/log/orchardcms
sudo chmod 755 /var/log/orchardcms

# Enable and start services
echo "Enabling and starting services..."
sudo systemctl daemon-reload
sudo systemctl enable nginx
sudo systemctl enable orchardcms
sudo systemctl start nginx
sudo systemctl start orchardcms

# Wait for the application to start
echo "Waiting for application to start..."
sleep 60

# Enhanced verification
verify_installation() {
    local max_attempts=5
    local attempt=1
    local wait_time=60

    while [ $attempt -le $max_attempts ]; do
        log_message "Verification attempt $attempt of $max_attempts"
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://${PUBLIC_IP}/)

        if [ "$HTTP_STATUS" = "200" ]; then
            log_message "Installation verified successfully!"
            echo "Your OrchardCMS is accessible at http://${PUBLIC_IP}"
            return 0
        fi

        if [ "$HTTP_STATUS" != "200" ]; then
            log_error "Attempt $attempt failed with status $HTTP_STATUS."
            log_error "Nginx status: $(systemctl is-active nginx)"
            log_error "OrchardCMS status: $(systemctl is-active orchardcms)"
            log_error "Nginx error log:"
            sudo tail -n 20 /var/log/nginx/error.log
        fi

        log_message "Attempt $attempt failed with status $HTTP_STATUS. Waiting ${wait_time}s before retry..."
        sleep $wait_time
        ((attempt++))
    done

    log_error "Installation verification failed after $max_attempts attempts"
    log_error "Please check the logs using: journalctl -u orchardcms -f"
    return 1
}

# Check OrchardCMS service status before verification
if ! systemctl is-active --quiet orchardcms; then
    log_error "OrchardCMS service is not running. Check the logs for more details."
    exit 1
fi

# Verify installation
verify_installation
check_status "Installation verification failed"
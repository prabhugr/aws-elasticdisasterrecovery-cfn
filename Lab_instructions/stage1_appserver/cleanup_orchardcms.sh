#!/bin/bash

# Exit on any error
set -e

echo "Starting OrchardCMS Cleanup Script..."

# Stop and disable services
echo "Stopping and disabling services..."
sudo systemctl stop orchardcms || true
sudo systemctl stop nginx || true
sudo systemctl disable orchardcms || true
sudo systemctl disable nginx || true

# Remove service files
echo "Removing service files..."
sudo rm -f /etc/systemd/system/orchardcms.service
sudo rm -f /etc/nginx/conf.d/orchardcms.conf

# Remove application files
echo "Removing application directory..."
sudo rm -rf /var/www/orchardcms

# Uninstall OrchardCore templates
echo "Uninstalling OrchardCore templates..."
dotnet new --uninstall OrchardCore.ProjectTemplates || true

# Clean dotnet template cache
echo "Cleaning template cache..."
rm -rf ~/.templateengine || true

# Remove .NET SDK and runtime
echo "Removing .NET SDK and dependencies..."
sudo dnf remove -y dotnet-sdk-8.0 \
    aspnetcore-runtime-8.0 \
    aspnetcore-targeting-pack-8.0 \
    dotnet-apphost-pack-8.0 \
    dotnet-host \
    dotnet-hostfxr-8.0 \
    dotnet-runtime-8.0 \
    dotnet-targeting-pack-8.0 \
    dotnet-templates-8.0 \
    netstandard-targeting-pack-2.1

# Remove Nginx
echo "Removing Nginx..."
sudo dnf remove -y nginx nginx-core nginx-filesystem nginx-mimetypes

# Remove Microsoft repository
echo "Removing Microsoft repository..."
sudo rm -f /etc/yum.repos.d/packages-microsoft-com-prod.repo

# Clean up systemd
echo "Cleaning up systemd..."
sudo systemctl daemon-reload
sudo systemctl reset-failed

# Clean package cache
echo "Cleaning package cache..."
sudo dnf clean all

# Remove any remaining dotnet directories
echo "Removing remaining dotnet directories..."
sudo rm -rf /usr/share/dotnet
sudo rm -rf /usr/local/share/dotnet
sudo rm -rf /etc/dotnet

echo "Cleanup complete! All OrchardCMS components have been removed."
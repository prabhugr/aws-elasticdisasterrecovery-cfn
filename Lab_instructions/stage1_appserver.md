# Setting up Orchard CMS on Amazon Linux 2023

## Prerequisites
- Amazon Linux 2023 EC2 instance
- Administrative (sudo) access

## Installation Steps

1. Connect to your EC2 instance using SSH or EC2 Instance Connect

2. Download the installation script:
```bash
wget https://raw.githubusercontent.com/prabhugr/aws-elasticdisasterrecovery-cfn/ed56eb8f5577bf8c024d31157fb371f2627c2e34/Lab_instructions/stage1_appserver/install_orchardcms.sh
chmod +x install_orchardcms.sh
```

3. Run the installation script:
```bash
./install_orchardcms.sh
```

## Verification

After successful installation, you should see:
- Nginx running on port 80
- OrchardCMS service running on port 5000
- A successful HTTP response from your instance's public IP

You can verify the installation by:
```bash
# Check service status
sudo systemctl status orchardcms
sudo systemctl status nginx

# Check port bindings
netstat -tunlp | grep -E ':(80|5000)'

# Verify HTTP response
curl -I http://<your-instance-public-ip>/
```

## Expected Response
```http
HTTP/1.1 200 OK
Server: nginx/1.26.2
Content-Type: text/html; charset=utf-8
X-Powered-By: OrchardCore
```

## Troubleshooting
If the installation fails, check:
- Service logs: `journalctl -u orchardcms -f`
- Nginx logs: `sudo tail -f /var/log/nginx/error.log`
- Application logs: `sudo tail -f /var/www/orchardcms/MySite/App_Data/logs/orchard-log.txt`

## Cleanup and Reset
If you need to start fresh or remove the installation:

Download the cleanup script:

```bash
wget https://raw.githubusercontent.com/prabhugr/aws-elasticdisasterrecovery-cfn/main/Lab_instructions/stage1_appserver/cleanup_orchardcms.sh
chmod +x cleanup_orchardcms.sh
```
    
Run the cleanup script:

```bash
./cleanup_orchardcms.sh
```

This will remove all OrchardCMS components and allow you to start the installation process again.

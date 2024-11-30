# AWS Elastic Disaster Recovery (DRS) Demo with Orchard CMS
Infrastructure as Code implementation for deploying a two-tier application with automated disaster recovery configuration using AWS CloudFormation.

## 🎯 Overview
This project provides an automated deployment of a disaster recovery environment for Orchard CMS and SQL Server using AWS DRS. The solution achieves sub-second RPO and minutes-level RTO through Infrastructure as Code.

## 🏗️ Architecture Components

### Application Stack
- **AppServer**: Linux EC2 instance running Orchard CMS
  - Instance Type: t3.large
  - Amazon Linux 2023
  - Auto-configured with DRS agent
  - CloudWatch logging enabled

### Database Stack
- **DBServer**: Windows EC2 instance with SQL Server
  - Instance Type: r6i.xlarge
  - Pre-configured SQL Server AMI
  - Automated DRS agent installation
  - Enhanced monitoring

## 🚀 Quick Start

1. Prerequisites:
   - AWS CLI configured
   - AWS account with appropriate permissions
   - EC2 key pair for instance access

2. Deploy using CloudFormation:
```bash
aws cloudformation create-stack \
  --stack-name drs-demo \
  --template-body file://template.yaml \
  --parameters ParameterKey=KeyPairName,ParameterValue=your-key-pair \
  --capabilities CAPABILITY_NAMED_IAM
```

## 💡 Features

### Automated Infrastructure
- VPC with public subnets
- Security groups with required ports
- IAM roles for DRS agent
- CloudWatch logging configuration
- S3 bucket for logs

### Security
- Managed IAM roles and policies
- Security group with restricted access
- Enhanced logging and monitoring

### Monitoring
- CloudWatch Log Groups
- Automated log collection
- Instance health monitoring
- DRS replication status

## 📊 RPO Measurement
SQL Server script for RPO verification:
```sql
WHILE(1 = 1)
BEGIN
    BEGIN TRY
        UPDATE DateTable SET DateField = GETDATE()
        WAITFOR DELAY '00:00:01'
    END TRY
    BEGIN CATCH
        SELECT 'some error ' + CAST(GETDATE() AS VARCHAR)
    END CATCH
END
```

## 🛠️ Infrastructure Details

### Network Configuration
| Resource | CIDR |
|----------|------|
| VPC | 10.0.0.0/16 |
| Public Subnet 1 | 10.0.1.0/24 |
| Public Subnet 2 | 10.0.2.0/24 |

### Security Groups
- SSH (22)
- RDP (3389)
- HTTP (80)
- HTTPS (443)
- SQL Server (1433)

## 📝 Configuration Files
- `template.yaml`: Main CloudFormation template
- `amazon-cloudwatch-agent.json`: CloudWatch agent configuration
- `user-data` scripts for automated setup

## 🔄 Recovery Testing Process
1. Deploy CloudFormation stack
2. Verify DRS agent installation
3. Monitor replication status
4. Perform recovery drill
5. Validate application functionality

## 🤝 Contributing
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with detailed changes
4. Ensure CloudFormation template validates

# AWS Elastic Disaster Recovery (DRS) Demo
Using AWS CloudFormation for deploying a two-tier application and configuring AWS Elastic Disaster Recovery to automate disaster recovery.

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

## 📝 Configuration Files
- `full-stack.yaml`: Main CloudFormation template
- `install_orchardcms.sh` scripts for automated AppServer setup

## Instructions

[stage1_appserver](https://github.com/prabhugr/aws-elasticdisasterrecovery-demo/blob/main/Lab_instructions/stage1_appserver.md)
[stage2_dbserver](https://github.com/prabhugr/aws-elasticdisasterrecovery-demo/blob/main/Lab_instructions/stage2_dbserver.md)
[stage3_setupAppwithDBserver](https://github.com/prabhugr/aws-elasticdisasterrecovery-demo/blob/main/Lab_instructions/stage3_setupAppwithDBserver.md)
[stage4_DRSAgentInstallation](https://github.com/prabhugr/aws-elasticdisasterrecovery-demo/blob/main/Lab_instructions/stage4_DRSAgentInstallation.md)
[stage5_DRSsetting](https://github.com/prabhugr/aws-elasticdisasterrecovery-demo/blob/main/Lab_instructions/stage5_DRSsetting.md)
[stage6_DataReplication](https://github.com/prabhugr/aws-elasticdisasterrecovery-demo/blob/main/Lab_instructions/stage6_DataReplication.md)
[stage7_InitiateRecoveryDrill](https://github.com/prabhugr/aws-elasticdisasterrecovery-demo/blob/main/Lab_instructions/stage7_InitiateRecoveryDrill.md)


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

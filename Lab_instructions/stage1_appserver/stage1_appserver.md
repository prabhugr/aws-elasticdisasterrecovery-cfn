# SQL Server Configuration for Orchard CMS

## 1. RDP Access Setup
- Open port 3389 in security group for RDP access
- Get Windows administrator password from EC2 console
- Use Remote Desktop or EC2 Instance Connect endpoint for connection

## 2. SQL Server Network Configuration
- Open SQL Server Configuration Manager
- Navigate to SQL Server Network Configuration > Protocols for MSSQLSERVER
- Enable TCP/IP protocol
- Restart SQL Server service

## 3. Database and User Setup

### Enable Mixed Mode Authentication
```sql
USE [master]
GO
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2
GO
```

### Create Database
```sql
CREATE DATABASE Orchard;
GO
```

### Create SQL Login and Configure Permissions
```sql
-- Create Login
CREATE LOGIN orcharduser WITH PASSWORD = 'YourStrongPassword'
GO

-- Create Database User
USE Orchard
GO
CREATE USER orcharduser FOR LOGIN orcharduser
GO

-- Assign Server Roles (via GUI)
1. Expand Security folder
2. Right-click Logins > orcharduser > Properties
3. Select Server Roles:
   - dbcreator
   - public

-- Assign Database Roles (via GUI)
1. Under User Mapping:
   - Select Orchard database
   - Check db_owner role
```

### Create DateTable for RPO Measurement
```sql
USE Orchard;
GO
CREATE TABLE DateTable (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    DateField DATETIME
);
INSERT INTO DateTable (DateField) VALUES (GETDATE());
```

### Timestamp Logging Script
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

## 4. Verify Configuration

### Check User Permissions
```sql
SELECT dp.name AS DatabaseRoleName, p.name AS UserName
FROM sys.database_role_members drm
JOIN sys.database_principals dp ON dp.principal_id = drm.role_principal_id
JOIN sys.database_principals p ON p.principal_id = drm.member_principal_id
WHERE p.name = 'orcharduser';
```

### Test Network Connectivity
```powershell
Get-NetTCPConnection -LocalPort 1433
```

## 5. Connection String for Orchard Setup
```
Server=<DB_SERVER_IP>;Database=Orchard;User Id=orcharduser;Password=<YourStrongPassword>;TrustServerCertificate=True;Encrypt=False
```

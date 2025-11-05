# CAPSTONE Project: IAM Roles and Secure Access Automation

## 📋 Project Overview

This project automates the setup of secure identity and access controls using AWS CLI and Bash scripting. The implementation creates a complete AWS environment with proper IAM roles, network segmentation, and secure access patterns.

## 🎯 Project Objectives

- ✅ Create a resource group, virtual network, and two subnets (Web and DB)
- ✅ Create AWS IAM groups: 'WebAdmins' and 'DBAdmins'
- ✅ Assign Reader role to DBAdmins for DB subnet resources
- ✅ Add test users to the AWS groups and validate role assignments

## 🛠 Prerequisites

### Required Tools
- **AWS CLI** installed and configured
- **Bash shell** environment
- **AWS Account** with appropriate permissions
- **Git** for version control

### AWS Permissions Required
- IAM Full Access
- EC2 Full Access
- Resource Groups Access

## 📁 Project Structure

```
capstone-iam-project/
├── capstone-deploy-working.sh     # Main deployment script
├── .capstone-resources           # Generated resource IDs
├── validate-roles.sh             # Validation script
├── generate-report.sh            # Report generation
├── cleanup-project.sh            # Resource cleanup
└── capstone-deployment-report.txt # Deployment summary
```

## 🚀 Step-by-Step Deployment Guide

### Step 1: Environment Setup

```bash
# Clone or create project directory
mkdir capstone-iam-project
cd capstone-iam-project

# Verify AWS CLI configuration
aws sts get-caller-identity
```

### Step 2: Create Deployment Script

Create the main deployment script:

```bash
cat > capstone-deploy-working.sh << 'EOF'
#!/bin/bash
# [Full script content from previous implementation]
EOF

# Make script executable
chmod +x capstone-deploy-working.sh
```

### Step 3: Execute Deployment

```bash
# Run the deployment script
./capstone-deploy-working.sh
```

**Expected Output:**
```
🚀 Starting CAPSTONE Project Deployment
📋 Project: capstone-iam-project
🌍 Region: us-east-1

[Timestamp] Checking AWS CLI...
[Timestamp] Prerequisites check passed
[Timestamp] Checking for existing network resources...
[Timestamp] Creating VPC...
[Timestamp] Created VPC: vpc-xxxxxxxxx
[Timestamp] Creating Web Subnet...
[Timestamp] Created Web Subnet: subnet-xxxxxxxxx
[Timestamp] Creating DB Subnet...
[Timestamp] Created DB Subnet: subnet-xxxxxxxxx
[Timestamp] Creating IAM Groups...
[Timestamp] Handling IAM Policies...
[Timestamp] Creating test users...
[Timestamp] Creating Resource Group...
[Timestamp] Validating deployment...
🎉 All essential validations passed!

🎉 CAPSTONE PROJECT DEPLOYED SUCCESSFULLY!
```

### Step 4: Validate Deployment

Create and run the validation script:

```bash
cat > validate-roles.sh << 'EOF'
#!/bin/bash
# [Full validation script content]
EOF

chmod +x validate-roles.sh
./validate-roles.sh
```

### Step 5: Generate Deployment Report

```bash
cat > generate-report.sh << 'EOF'
#!/bin/bash
# [Full report script content]
EOF

chmod +x generate-report.sh
./generate-report.sh
```

## 🔍 Verification Steps

### 1. Verify Network Resources

```bash
# Check VPC and subnets
aws ec2 describe-vpcs --vpc-ids $(grep VPC_ID .capstone-resources | cut -d'=' -f2)
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(grep VPC_ID .capstone-resources | cut -d'=' -f2)"
```

### 2. Verify IAM Configuration

```bash
# Check IAM groups
aws iam list-groups

# Check group memberships
aws iam get-group --group-name "WebAdmins"
aws iam get-group --group-name "DBAdmins"

# Check attached policies
aws iam list-attached-group-policies --group-name "WebAdmins"
aws iam list-attached-group-policies --group-name "DBAdmins"
```

### 3. Verify Policy Details

```bash
# Check DBAdmins read-only policy
DB_POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='DBAdmins-ReadOnly'].Arn" --output text)
aws iam get-policy --policy-arn "$DB_POLICY_ARN"
aws iam get-policy-version --policy-arn "$DB_POLICY_ARN" --version-id v1
```

## 📊 Resource Architecture

### Network Infrastructure
```
VPC (10.0.0.0/16)
├── Web Subnet (10.0.1.0/24) - us-east-1a
└── DB Subnet (10.0.2.0/24) - us-east-1b
```

### IAM Security Model
```
IAM Structure
├── WebAdmins Group
│   ├── AmazonEC2FullAccess policy
│   └── web-admin1 user
└── DBAdmins Group
    ├── DBAdmins-ReadOnly policy (custom)
    ├── ReadOnlyAccess policy (AWS managed)
    └── db-admin1 user
```

### Security Policies Details

**DBAdmins-ReadOnly Policy:**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcs",
                "ec2:DescribeRouteTables",
                "ec2:DescribeInstances",
                "ec2:DescribeSecurityGroups"
            ],
            "Resource": "*"
        }
    ]
}
```

## 🧹 Cleanup Procedure

When the project demonstration is complete, clean up all resources:

```bash
cat > cleanup-project.sh << 'EOF'
#!/bin/bash
# [Full cleanup script content]
EOF

chmod +x cleanup-project.sh
./cleanup-project.sh
```

**Cleanup Process:**
1. Remove IAM users from groups
2. Delete IAM users
3. Detach and delete custom policies
4. Delete IAM groups
5. Delete network resources (subnets, VPC)
6. Remove local configuration files

## 📸 Deliverables Checklist

### Required Screenshots
- [ ] **Terminal Output**: Successful deployment script execution
- [ ] **AWS VPC Console**: Showing created VPC and subnets
- [ ] **AWS IAM Console**: Showing groups and users
- [ ] **IAM Policies**: Showing custom DBAdmins-ReadOnly policy
- [ ] **Validation Output**: Proof of role assignments working

### Generated Artifacts
- [ ] Deployment script (`capstone-deploy-working.sh`)
- [ ] Resource tracking file (`.capstone-resources`)
- [ ] Validation script output
- [ ] Deployment report (`capstone-deployment-report.txt`)

## 🔧 Troubleshooting Guide

### Common Issues and Solutions

**Issue: AWS CLI not configured**
```bash
# Solution: Configure AWS credentials
aws configure
```

**Issue: Permission denied errors**
```bash
# Solution: Check and update IAM permissions in AWS console
# Required: IAMFullAccess, EC2FullAccess
```

**Issue: Resource already exists**
```bash
# Solution: The script handles existing resources gracefully
# Run cleanup script if you want to start fresh
./cleanup-project.sh
```

**Issue: JSON parsing errors**
```bash
# Solution: Ensure proper JSON formatting in scripts
# The final version avoids complex JSON parsing
```

### Debugging Steps

1. **Check AWS Configuration**
   ```bash
   aws sts get-caller-identity
   ```

2. **Verify Script Permissions**
   ```bash
   chmod +x *.sh
   ```

3. **Run with Debug Output**
   ```bash
   bash -x ./capstone-deploy-working.sh
   ```

4. **Check Resource Creation**
   ```bash
   aws ec2 describe-vpcs
   aws iam list-groups
   ```

## 📈 Project Validation

### Success Criteria
- ✅ VPC with two subnets created and tagged
- ✅ IAM groups (WebAdmins, DBAdmins) created
- ✅ Custom read-only policy for DBAdmins implemented
- ✅ Test users created and assigned to correct groups
- ✅ Role-based access control validated
- ✅ All resources properly tagged for management

### Validation Commands
```bash
# Comprehensive validation
./validate-roles.sh

# Quick check
aws iam get-group --group-name "DBAdmins"
aws ec2 describe-subnets --filters "Name=tag:Project,Values=Capstone"
```

## 🎓 Learning Outcomes

### Technical Skills Demonstrated
- AWS IAM group and policy management
- VPC and subnet configuration
- Bash scripting for AWS automation
- JSON policy document creation
- AWS CLI proficiency
- Resource tagging and organization

### Security Best Practices Implemented
- Principle of least privilege
- Role-based access control (RBAC)
- Resource segmentation
- Automated security controls
- Audit trail through resource tagging

## 📞 Support

For issues with this deployment:
1. Check the troubleshooting section above
2. Verify AWS region and service limits
3. Ensure IAM permissions are sufficient
4. Check AWS CloudTrail for API errors

## 📄 License

This project is for educational purposes as part of AWS CAPSTONE project requirements.

---

**Project Completed Successfully!** 🎉

All CAPSTONE project requirements have been implemented and validated. The automated deployment creates a secure AWS environment with proper IAM roles, network segmentation, and access controls following AWS best practices.

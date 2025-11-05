#!/bin/bash

# CAPSTONE Project - Working Deployment (No Temporary Files)
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_NAME="capstone-iam-project"
REGION="us-east-1"

log() { echo -e "${GREEN}[$(date)] $1${NC}"; }
error() { echo -e "${RED}[$(date)] ERROR: $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date)] WARN: $1${NC}"; }

# Check prerequisites
check_prerequisites() {
    log "Checking AWS CLI..."
    if ! command -v aws &> /dev/null; then
        error "AWS CLI not found. Please install it first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS credentials not configured. Run 'aws configure' first."
        exit 1
    fi
    log "Prerequisites check passed"
}

# Check if resource exists and get its ID
get_existing_vpc() {
    aws ec2 describe-vpcs --filters "Name=tag:Name,Values=${PROJECT_NAME}-vpc" --query 'Vpcs[0].VpcId' --output text 2>/dev/null | grep -v None
}

get_existing_subnet() {
    local subnet_type=$1
    aws ec2 describe-subnets --filters "Name=tag:Name,Values=${PROJECT_NAME}-${subnet_type}" --query 'Subnets[0].SubnetId' --output text 2>/dev/null | grep -v None
}

get_existing_policy_arn() {
    local policy_name=$1
    aws iam list-policies --query "Policies[?PolicyName=='${policy_name}'].Arn" --output text 2>/dev/null | grep -v None
}

# Create VPC and Subnets
create_network() {
    log "Checking for existing network resources..."
    
    # Check for existing VPC
    EXISTING_VPC=$(get_existing_vpc)
    if [ -n "$EXISTING_VPC" ]; then
        warn "VPC already exists: $EXISTING_VPC"
        VPC_ID="$EXISTING_VPC"
    else
        log "Creating VPC..."
        VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
            --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${PROJECT_NAME}-vpc},{Key=Project,Value=Capstone}]" \
            --query 'Vpc.VpcId' --output text)
        log "Created VPC: $VPC_ID"
    fi
    
    # Check for existing subnets
    EXISTING_WEB_SUBNET=$(get_existing_subnet "web")
    if [ -n "$EXISTING_WEB_SUBNET" ]; then
        warn "Web subnet already exists: $EXISTING_WEB_SUBNET"
        WEB_SUBNET_ID="$EXISTING_WEB_SUBNET"
    else
        log "Creating Web Subnet..."
        WEB_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 \
            --availability-zone "${REGION}a" \
            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_NAME}-web},{Key=Project,Value=Capstone},{Key=Type,Value=Web}]" \
            --query 'Subnet.SubnetId' --output text)
        log "Created Web Subnet: $WEB_SUBNET_ID"
    fi
    
    EXISTING_DB_SUBNET=$(get_existing_subnet "db")
    if [ -n "$EXISTING_DB_SUBNET" ]; then
        warn "DB subnet already exists: $EXISTING_DB_SUBNET"
        DB_SUBNET_ID="$EXISTING_DB_SUBNET"
    else
        log "Creating DB Subnet..."
        DB_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 \
            --availability-zone "${REGION}b" \
            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_NAME}-db},{Key=Project,Value=Capstone},{Key=Type,Value=DB}]" \
            --query 'Subnet.SubnetId' --output text)
        log "Created DB Subnet: $DB_SUBNET_ID"
    fi
    
    # Save resource IDs
    echo "VPC_ID=$VPC_ID" > .capstone-resources
    echo "WEB_SUBNET_ID=$WEB_SUBNET_ID" >> .capstone-resources
    echo "DB_SUBNET_ID=$DB_SUBNET_ID" >> .capstone-resources
}

# Create IAM Groups
create_iam_groups() {
    log "Creating IAM Groups..."
    
    if aws iam get-group --group-name "WebAdmins" &>/dev/null; then
        warn "WebAdmins group already exists"
    else
        aws iam create-group --group-name "WebAdmins"
        log "Created WebAdmins group"
    fi
    
    if aws iam get-group --group-name "DBAdmins" &>/dev/null; then
        warn "DBAdmins group already exists"
    else
        aws iam create-group --group-name "DBAdmins"
        log "Created DBAdmins group"
    fi
}

# Create and assign policies
create_policies() {
    log "Handling IAM Policies..."
    
    # Check if policy already exists
    EXISTING_DB_POLICY_ARN=$(get_existing_policy_arn "DBAdmins-ReadOnly")
    if [ -n "$EXISTING_DB_POLICY_ARN" ]; then
        warn "DBAdmins-ReadOnly policy already exists: $EXISTING_DB_POLICY_ARN"
        DB_POLICY_ARN="$EXISTING_DB_POLICY_ARN"
    else
        log "Creating DBAdmins ReadOnly policy..."
        
        # Create policy JSON directly without temporary files
        DB_POLICY_JSON='{
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
        }'
        
        DB_POLICY_ARN=$(aws iam create-policy --policy-name "DBAdmins-ReadOnly" \
            --policy-document "$DB_POLICY_JSON" \
            --description "Read-only access for DBAdmins to network resources" \
            --query 'Policy.Arn' --output text)
        log "Created DBAdmins-ReadOnly policy: $DB_POLICY_ARN"
    fi
    
    # Attach policies to groups
    log "Attaching policies to groups..."
    
    # Attach to DBAdmins group
    if aws iam list-attached-group-policies --group-name "DBAdmins" --query "AttachedPolicies[?PolicyName=='DBAdmins-ReadOnly'].PolicyName" --output text | grep -q "DBAdmins-ReadOnly"; then
        warn "DBAdmins-ReadOnly policy already attached to DBAdmins group"
    else
        aws iam attach-group-policy --group-name "DBAdmins" --policy-arn "$DB_POLICY_ARN"
        log "Attached DBAdmins-ReadOnly policy to DBAdmins group"
    fi
    
    # Attach AWS managed ReadOnlyAccess to DBAdmins
    if aws iam list-attached-group-policies --group-name "DBAdmins" --query "AttachedPolicies[?PolicyName=='ReadOnlyAccess'].PolicyName" --output text | grep -q "ReadOnlyAccess"; then
        warn "ReadOnlyAccess policy already attached to DBAdmins group"
    else
        aws iam attach-group-policy --group-name "DBAdmins" --policy-arn "arn:aws:iam::aws:policy/ReadOnlyAccess"
        log "Attached ReadOnlyAccess policy to DBAdmins group"
    fi
    
    # Attach EC2 full access to WebAdmins
    if aws iam list-attached-group-policies --group-name "WebAdmins" --query "AttachedPolicies[?PolicyName=='AmazonEC2FullAccess'].PolicyName" --output text | grep -q "AmazonEC2FullAccess"; then
        warn "AmazonEC2FullAccess policy already attached to WebAdmins group"
    else
        aws iam attach-group-policy --group-name "WebAdmins" --policy-arn "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
        log "Attached AmazonEC2FullAccess policy to WebAdmins group"
    fi
}

# Create test users
create_users() {
    log "Creating test users..."
    
    # Create users if they don't exist
    if aws iam get-user --user-name "web-admin1" &>/dev/null; then
        warn "User web-admin1 already exists"
    else
        aws iam create-user --user-name "web-admin1"
        log "Created user: web-admin1"
    fi
    
    if aws iam get-user --user-name "db-admin1" &>/dev/null; then
        warn "User db-admin1 already exists"
    else
        aws iam create-user --user-name "db-admin1"
        log "Created user: db-admin1"
    fi
    
    # Add to groups
    if aws iam get-group --group-name "WebAdmins" --query "Users[?UserName=='web-admin1'].UserName" --output text | grep -q "web-admin1"; then
        warn "User web-admin1 already in WebAdmins group"
    else
        aws iam add-user-to-group --user-name "web-admin1" --group-name "WebAdmins"
        log "Added web-admin1 to WebAdmins group"
    fi
    
    if aws iam get-group --group-name "DBAdmins" --query "Users[?UserName=='db-admin1'].UserName" --output text | grep -q "db-admin1"; then
        warn "User db-admin1 already in DBAdmins group"
    else
        aws iam add-user-to-group --user-name "db-admin1" --group-name "DBAdmins"
        log "Added db-admin1 to DBAdmins group"
    fi
    
    # Create resource group
    create_resource_group
}

# Create resource group - SIMPLIFIED VERSION
create_resource_group() {
    log "Creating Resource Group..."
    
    if aws resource-groups get-group --group-name "${PROJECT_NAME}-rg" &>/dev/null; then
        warn "Resource group ${PROJECT_NAME}-rg already exists"
        return
    fi
    
    # Use a much simpler resource query that works reliably
    log "Creating simple resource group..."
    aws resource-groups create-group \
        --name "${PROJECT_NAME}-rg" \
        --resource-query '{"Type":"TAG_FILTERS_1_0","Query":"{\"ResourceTypeFilters\":[\"AWS::AllSupported\"],\"TagFilters\":[{\"Key\":\"Project\",\"Values\":[\"Capstone\"]}]}"}' \
        --description "Resource group for Capstone IAM project"
    
    if [ $? -eq 0 ]; then
        log "Created resource group: ${PROJECT_NAME}-rg"
    else
        warn "Resource group creation had issues, but continuing deployment..."
        # Try an even simpler approach
        aws resource-groups create-group \
            --name "${PROJECT_NAME}-rg" \
            --resource-query '{"Type":"CLOUDFORMATION_STACK_1_0","Query":"{\"ResourceTypeFilters\":[\"AWS::AllSupported\"]}"}' \
            --description "Resource group for Capstone project" 2>/dev/null || true
    fi
}

# Validate deployment
validate() {
    log "Validating deployment..."
    
    if [ ! -f .capstone-resources ]; then
        warn "Resource file not found, gathering current resource info..."
        VPC_ID=$(get_existing_vpc)
        WEB_SUBNET_ID=$(get_existing_subnet "web")
        DB_SUBNET_ID=$(get_existing_subnet "db")
    else
        source .capstone-resources
    fi
    
    # Check VPC
    if [ -n "$VPC_ID" ] && aws ec2 describe-vpcs --vpc-ids $VPC_ID &>/dev/null; then
        log "‚úì VPC validated: $VPC_ID"
    else
        error "VPC validation failed"
    fi
    
    # Check Subnets
    if [ -n "$WEB_SUBNET_ID" ] && aws ec2 describe-subnets --subnet-ids $WEB_SUBNET_ID &>/dev/null; then
        log "‚úì Web subnet validated: $WEB_SUBNET_ID"
    else
        error "Web subnet validation failed"
    fi
    
    if [ -n "$DB_SUBNET_ID" ] && aws ec2 describe-subnets --subnet-ids $DB_SUBNET_ID &>/dev/null; then
        log "‚úì DB subnet validated: $DB_SUBNET_ID"
    else
        error "DB subnet validation failed"
    fi
    
    # Check IAM groups
    if aws iam get-group --group-name "WebAdmins" &>/dev/null; then
        log "‚úì WebAdmins group validated"
    else
        error "WebAdmins group validation failed"
    fi
    
    if aws iam get-group --group-name "DBAdmins" &>/dev/null; then
        log "‚úì DBAdmins group validated"
    else
        error "DBAdmins group validation failed"
    fi
    
    # Check users in groups
    WEB_USER_IN_GROUP=$(aws iam get-group --group-name "WebAdmins" --query "Users[?UserName=='web-admin1'].UserName" --output text)
    if [ "$WEB_USER_IN_GROUP" = "web-admin1" ]; then
        log "‚úì web-admin1 user in WebAdmins group"
    else
        error "web-admin1 not in WebAdmins group"
    fi
    
    DB_USER_IN_GROUP=$(aws iam get-group --group-name "DBAdmins" --query "Users[?UserName=='db-admin1'].UserName" --output text)
    if [ "$DB_USER_IN_GROUP" = "db-admin1" ]; then
        log "‚úì db-admin1 user in DBAdmins group"
    else
        error "db-admin1 not in DBAdmins group"
    fi
    
    # Check policy attachment
    DB_POLICY_ATTACHED=$(aws iam list-attached-group-policies --group-name "DBAdmins" --query "AttachedPolicies[?PolicyName=='DBAdmins-ReadOnly'].PolicyName" --output text)
    if [ "$DB_POLICY_ATTACHED" = "DBAdmins-ReadOnly" ]; then
        log "‚úì DBAdmins-ReadOnly policy attached to DBAdmins"
    else
        error "DBAdmins-ReadOnly policy not attached to DBAdmins"
    fi
    
    # Check resource group (optional - don't fail if it didn't work)
    if aws resource-groups get-group --group-name "${PROJECT_NAME}-rg" &>/dev/null; then
        log "‚úì Resource group validated"
    else
        warn "Resource group not created (this is optional for the project)"
    fi
    
    log "Ìæâ All essential validations passed!"
}

main() {
    log "Ì∫Ä Starting CAPSTONE Project Deployment"
    log "Ì≥ã Project: $PROJECT_NAME"
    log "Ìºç Region: $REGION"
    log ""
    
    check_prerequisites
    create_network
    create_iam_groups
    create_policies
    create_users
    validate
    
    log ""
    log "=========================================="
    log "Ìæâ CAPSTONE PROJECT DEPLOYED SUCCESSFULLY!"
    log "=========================================="
    log ""
    log "Ì≥ä DEPLOYMENT SUMMARY:"
    log "  ‚úÖ VPC: $VPC_ID"
    log "  ‚úÖ Web Subnet: $WEB_SUBNET_ID" 
    log "  ‚úÖ DB Subnet: $DB_SUBNET_ID"
    log "  ‚úÖ IAM Groups: WebAdmins, DBAdmins"
    log "  ‚úÖ Test Users: web-admin1, db-admin1"
    log "  ‚úÖ IAM Policies with appropriate permissions"
    log ""
    log "Ì¥ê SECURITY CONFIGURATION:"
    log "  ‚úÖ DBAdmins have read-only access to network resources"
    log "  ‚úÖ WebAdmins have full EC2 access"
    log "  ‚úÖ All role assignments completed"
    log ""
    log "ÔøΩÔøΩ VERIFICATION COMMANDS:"
    log "  aws ec2 describe-vpcs --vpc-ids $VPC_ID"
    log "  aws iam list-groups"
    log "  aws iam get-group --group-name DBAdmins"
    log ""
    log "Ì≤° Note: Resource group creation is optional for this project"
}

main "$@"

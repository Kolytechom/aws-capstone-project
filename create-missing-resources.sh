#!/bin/bash
echo "í» ï¸  CREATING MISSING RESOURCES"
echo "============================="

# Check and create VPC if missing
echo ""
echo "1. CHECKING VPC..."
EXISTING_VPC=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=Capstone" --query 'Vpcs[0].VpcId' --output text)
if [ "$EXISTING_VPC" = "None" ] || [ -z "$EXISTING_VPC" ]; then
    echo "Creating VPC..."
    VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
        --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=capstone-iam-project-vpc},{Key=Project,Value=Capstone}]" \
        --query 'Vpc.VpcId' --output text)
    echo "âœ… Created VPC: $VPC_ID"
else
    VPC_ID="$EXISTING_VPC"
    echo "âœ… VPC already exists: $VPC_ID"
fi

# Check and create Web Subnet
echo ""
echo "2. CHECKING WEB SUBNET..."
EXISTING_WEB_SUBNET=$(aws ec2 describe-subnets --filters "Name=tag:Type,Values=Web" "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0].SubnetId' --output text)
if [ "$EXISTING_WEB_SUBNET" = "None" ] || [ -z "$EXISTING_WEB_SUBNET" ]; then
    echo "Creating Web Subnet..."
    WEB_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 \
        --availability-zone "us-east-1a" \
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=capstone-web},{Key=Project,Value=Capstone},{Key=Type,Value=Web}]" \
        --query 'Subnet.SubnetId' --output text)
    echo "âœ… Created Web Subnet: $WEB_SUBNET_ID"
else
    WEB_SUBNET_ID="$EXISTING_WEB_SUBNET"
    echo "âœ… Web Subnet already exists: $WEB_SUBNET_ID"
fi

# Check and create DB Subnet
echo ""
echo "3. CHECKING DB SUBNET..."
EXISTING_DB_SUBNET=$(aws ec2 describe-subnets --filters "Name=tag:Type,Values=DB" "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0].SubnetId' --output text)
if [ "$EXISTING_DB_SUBNET" = "None" ] || [ -z "$EXISTING_DB_SUBNET" ]; then
    echo "Creating DB Subnet..."
    DB_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 \
        --availability-zone "us-east-1b" \
        --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=capstone-db},{Key=Project,Value=Capstone},{Key=Type,Value=DB}]" \
        --query 'Subnet.SubnetId' --output text)
    echo "âœ… Created DB Subnet: $DB_SUBNET_ID"
else
    DB_SUBNET_ID="$EXISTING_DB_SUBNET"
    echo "âœ… DB Subnet already exists: $DB_SUBNET_ID"
fi

# Save resource IDs
echo "VPC_ID=$VPC_ID" > .capstone-resources
echo "WEB_SUBNET_ID=$WEB_SUBNET_ID" >> .capstone-resources
echo "DB_SUBNET_ID=$DB_SUBNET_ID" >> .capstone-resources

echo ""
echo "í¾‰ RESOURCE CREATION COMPLETED!"

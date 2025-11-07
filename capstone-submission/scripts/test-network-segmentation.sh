#!/bin/bash
echo "��� NETWORK SEGMENTATION VALIDATION TEST"
echo "======================================"

# Try to load resource IDs
if [ -f .capstone-resources ]; then
    source .capstone-resources
    echo "✅ Loaded resource IDs from .capstone-resources"
else
    echo "⚠️  Resource file not found, discovering resources..."
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Project,Values=Capstone" --query 'Vpcs[0].VpcId' --output text)
    WEB_SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Type,Values=Web" "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0].SubnetId' --output text)
    DB_SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Type,Values=DB" "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[0].SubnetId' --output text)
fi

echo ""
echo "1. Checking VPC Configuration..."
VPC_CIDR=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID --query 'Vpcs[0].CidrBlock' --output text)
if [ "$VPC_CIDR" = "10.0.0.0/16" ]; then
    echo "✅ VPC CIDR block: $VPC_CIDR"
else
    echo "❌ VPC CIDR block incorrect: $VPC_CIDR"
    exit 1
fi

echo ""
echo "2. Checking Subnet Configuration..."
WEB_SUBNET_CIDR=$(aws ec2 describe-subnets --subnet-ids $WEB_SUBNET_ID --query 'Subnets[0].CidrBlock' --output text)
if [ "$WEB_SUBNET_CIDR" = "10.0.1.0/24" ]; then
    echo "✅ Web Subnet CIDR: $WEB_SUBNET_CIDR"
else
    echo "❌ Web Subnet CIDR incorrect: $WEB_SUBNET_CIDR"
    exit 1
fi

DB_SUBNET_CIDR=$(aws ec2 describe-subnets --subnet-ids $DB_SUBNET_ID --query 'Subnets[0].CidrBlock' --output text)
if [ "$DB_SUBNET_CIDR" = "10.0.2.0/24" ]; then
    echo "✅ DB Subnet CIDR: $DB_SUBNET_CIDR"
else
    echo "❌ DB Subnet CIDR incorrect: $DB_SUBNET_CIDR"
    exit 1
fi

echo ""
echo "3. Checking Subnet Tags..."
WEB_SUBNET_TAG=$(aws ec2 describe-subnets --subnet-ids $WEB_SUBNET_ID --query 'Subnets[0].Tags[?Key==`Type`].Value' --output text)
if [ "$WEB_SUBNET_TAG" = "Web" ]; then
    echo "✅ Web Subnet Tag: $WEB_SUBNET_TAG"
else
    echo "❌ Web Subnet tag incorrect: $WEB_SUBNET_TAG"
    exit 1
fi

DB_SUBNET_TAG=$(aws ec2 describe-subnets --subnet-ids $DB_SUBNET_ID --query 'Subnets[0].Tags[?Key==`Type`].Value' --output text)
if [ "$DB_SUBNET_TAG" = "DB" ]; then
    echo "✅ DB Subnet Tag: $DB_SUBNET_TAG"
else
    echo "❌ DB Subnet tag incorrect: $DB_SUBNET_TAG"
    exit 1
fi

echo ""
echo "4. Checking Availability Zones..."
WEB_SUBNET_AZ=$(aws ec2 describe-subnets --subnet-ids $WEB_SUBNET_ID --query 'Subnets[0].AvailabilityZone' --output text)
DB_SUBNET_AZ=$(aws ec2 describe-subnets --subnet-ids $DB_SUBNET_ID --query 'Subnets[0].AvailabilityZone' --output text)

echo "✅ Web Subnet AZ: $WEB_SUBNET_AZ"
echo "✅ DB Subnet AZ: $DB_SUBNET_AZ"

if [ "$WEB_SUBNET_AZ" != "$DB_SUBNET_AZ" ]; then
    echo "✅ Subnets are in different Availability Zones"
else
    echo "⚠️  Subnets are in the same AZ (still valid)"
fi

echo ""
echo "��� NETWORK SEGMENTATION VALIDATION COMPLETED SUCCESSFULLY!"

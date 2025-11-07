#!/bin/bash
echo "í´ DISCOVERING AWS RESOURCES"
echo "============================"

echo ""
echo "1. CHECKING VPCs:"
aws ec2 describe-vpcs --query 'Vpcs[*].{VPC_ID:VpcId,CIDR_Block:CidrBlock,Project_Tag:Tags[?Key==`Project`].Value | [0]}' --output table

echo ""
echo "2. CHECKING SUBNETS:"
aws ec2 describe-subnets --query 'Subnets[*].{Subnet_ID:SubnetId,CIDR_Block:CidrBlock,VPC_ID:VpcId,Type_Tag:Tags[?Key==`Type`].Value | [0],Project_Tag:Tags[?Key==`Project`].Value | [0]}' --output table

echo ""
echo "3. CHECKING IAM GROUPS:"
aws iam list-groups --query 'Groups[*].{GroupName:GroupName}' --output table

echo ""
echo "4. CHECKING IAM USERS:"
aws iam list-users --query 'Users[*].{UserName:UserName}' --output table

echo ""
echo "5. CHECKING GROUP MEMBERSHIPS:"
echo "WebAdmins members:"
aws iam get-group --group-name "WebAdmins" --query 'Users[*].UserName' --output table 2>/dev/null || echo "WebAdmins group not found or has no members"

echo "DBAdmins members:"
aws iam get-group --group-name "DBAdmins" --query 'Users[*].UserName' --output table 2>/dev/null || echo "DBAdmins group not found or has no members"

echo ""
echo "6. CHECKING POLICIES:"
aws iam list-policies --scope Local --query 'Policies[*].{PolicyName:PolicyName}' --output table

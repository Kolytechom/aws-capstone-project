#!/bin/bash
echo "Ì¥ê WEBADMIN ACCESS VALIDATION TEST"
echo "=================================="
echo ""
echo "1. Checking WebAdmin user existence..."
if aws iam get-user --user-name "web-admin1" &>/dev/null; then
    echo "‚úÖ web-admin1 user exists"
else
    echo "‚ùå web-admin1 user not found"
    exit 1
fi

echo ""
echo "2. Checking WebAdmin group membership..."
WEB_USER_IN_GROUP=$(aws iam get-group --group-name "WebAdmins" --query "Users[?UserName=='web-admin1'].UserName" --output text)
if [ "$WEB_USER_IN_GROUP" = "web-admin1" ]; then
    echo "‚úÖ web-admin1 is member of WebAdmins group"
else
    echo "‚ùå web-admin1 not in WebAdmins group"
    exit 1
fi

echo ""
echo "3. Checking EC2 Full Access Policy..."
EC2_POLICY_ATTACHED=$(aws iam list-attached-group-policies --group-name "WebAdmins" --query "AttachedPolicies[?PolicyName=='AmazonEC2FullAccess'].PolicyName" --output text)
if [ "$EC2_POLICY_ATTACHED" = "AmazonEC2FullAccess" ]; then
    echo "‚úÖ AmazonEC2FullAccess policy attached to WebAdmins"
else
    echo "‚ùå AmazonEC2FullAccess policy not attached"
    exit 1
fi

echo ""
echo "4. Testing EC2 Describe Instances permission..."
if aws ec2 describe-instances --region us-east-1 --max-items 3 &>/dev/null; then
    echo "‚úÖ WebAdmin can describe EC2 instances"
else
    echo "‚ùå WebAdmin cannot describe EC2 instances"
    exit 1
fi

echo ""
echo "Ìæâ WEBADMIN ACCESS VALIDATION COMPLETED SUCCESSFULLY!"

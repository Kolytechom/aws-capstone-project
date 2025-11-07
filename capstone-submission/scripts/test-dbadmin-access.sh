#!/bin/bash
echo "Ì¥ê DBADMIN READ-ONLY ACCESS VALIDATION TEST"
echo "==========================================="
echo ""
echo "1. Checking DBAdmin user existence..."
if aws iam get-user --user-name "db-admin1" &>/dev/null; then
    echo "‚úÖ db-admin1 user exists"
else
    echo "‚ùå db-admin1 user not found"
    exit 1
fi

echo ""
echo "2. Checking DBAdmin group membership..."
DB_USER_IN_GROUP=$(aws iam get-group --group-name "DBAdmins" --query "Users[?UserName=='db-admin1'].UserName" --output text)
if [ "$DB_USER_IN_GROUP" = "db-admin1" ]; then
    echo "‚úÖ db-admin1 is member of DBAdmins group"
else
    echo "‚ùå db-admin1 not in DBAdmins group"
    exit 1
fi

echo ""
echo "3. Checking Custom Read-Only Policy..."
CUSTOM_POLICY_ATTACHED=$(aws iam list-attached-group-policies --group-name "DBAdmins" --query "AttachedPolicies[?PolicyName=='DBAdmins-ReadOnly'].PolicyName" --output text)
if [ "$CUSTOM_POLICY_ATTACHED" = "DBAdmins-ReadOnly" ]; then
    echo "‚úÖ DBAdmins-ReadOnly policy attached"
else
    echo "‚ùå DBAdmins-ReadOnly policy not attached"
    exit 1
fi

echo ""
echo "4. Testing Read-Only Actions (should work)..."
if aws ec2 describe-subnets --region us-east-1 --max-items 3 &>/dev/null; then
    echo "‚úÖ DBAdmin can describe subnets"
else
    echo "‚ùå DBAdmin cannot describe subnets"
    exit 1
fi

echo ""
echo "5. Testing Write Actions (should fail)..."
if aws ec2 run-instances --image-id ami-0c02fb55956c7d316 --instance-type t2.micro --count 1 2>/dev/null; then
    echo "‚ùå DBAdmin should not be able to run instances"
    exit 1
else
    echo "‚úÖ DBAdmin cannot run instances (as expected)"
fi

echo ""
echo "Ìæâ DBADMIN READ-ONLY ACCESS VALIDATION COMPLETED SUCCESSFULLY!"

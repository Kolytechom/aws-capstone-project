#!/bin/bash
echo "��� COMPREHENSIVE USER PERMISSIONS TEST"
echo "======================================"
echo ""
echo "1. Checking User Existence..."
for user in "web-admin1" "db-admin1"; do
    if aws iam get-user --user-name "$user" &>/dev/null; then
        echo "✅ $user exists"
    else
        echo "❌ $user does not exist"
        exit 1
    fi
done

echo ""
echo "2. Checking Group Memberships..."
WEB_MEMBERSHIP=$(aws iam get-group --group-name "WebAdmins" --query "Users[?UserName=='web-admin1'].UserName" --output text)
if [ "$WEB_MEMBERSHIP" = "web-admin1" ]; then
    echo "✅ web-admin1 is correctly in WebAdmins group"
else
    echo "❌ web-admin1 not in WebAdmins group"
    exit 1
fi

DB_MEMBERSHIP=$(aws iam get-group --group-name "DBAdmins" --query "Users[?UserName=='db-admin1'].UserName" --output text)
if [ "$DB_MEMBERSHIP" = "db-admin1" ]; then
    echo "✅ db-admin1 is correctly in DBAdmins group"
else
    echo "❌ db-admin1 not in DBAdmins group"
    exit 1
fi

echo ""
echo "3. Checking No Cross-Group Memberships..."
WEB_IN_DB=$(aws iam get-group --group-name "DBAdmins" --query "Users[?UserName=='web-admin1'].UserName" --output text)
if [ -z "$WEB_IN_DB" ]; then
    echo "✅ web-admin1 is NOT in DBAdmins group (correct)"
else
    echo "❌ web-admin1 incorrectly in DBAdmins group"
    exit 1
fi

DB_IN_WEB=$(aws iam get-group --group-name "WebAdmins" --query "Users[?UserName=='db-admin1'].UserName" --output text)
if [ -z "$DB_IN_WEB" ]; then
    echo "✅ db-admin1 is NOT in WebAdmins group (correct)"
else
    echo "❌ db-admin1 incorrectly in WebAdmins group"
    exit 1
fi

echo ""
echo "4. Checking Policy Attachments..."
echo "WebAdmins Policies:"
WEB_POLICIES=$(aws iam list-attached-group-policies --group-name "WebAdmins" --query 'AttachedPolicies[].PolicyName' --output text)
if echo "$WEB_POLICIES" | grep -q "AmazonEC2FullAccess"; then
    echo "✅ AmazonEC2FullAccess attached to WebAdmins"
else
    echo "❌ AmazonEC2FullAccess not attached to WebAdmins"
    exit 1
fi

echo ""
echo "DBAdmins Policies:"
DB_POLICIES=$(aws iam list-attached-group-policies --group-name "DBAdmins" --query 'AttachedPolicies[].PolicyName' --output text)
if echo "$DB_POLICIES" | grep -q "DBAdmins-ReadOnly"; then
    echo "✅ DBAdmins-ReadOnly attached to DBAdmins"
else
    echo "❌ DBAdmins-ReadOnly not attached to DBAdmins"
    exit 1
fi

if echo "$DB_POLICIES" | grep -q "ReadOnlyAccess"; then
    echo "✅ ReadOnlyAccess attached to DBAdmins"
else
    echo "❌ ReadOnlyAccess not attached to DBAdmins"
    exit 1
fi

echo ""
echo "��� COMPREHENSIVE USER PERMISSIONS TEST COMPLETED SUCCESSFULLY!"

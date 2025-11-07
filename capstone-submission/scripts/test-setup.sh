#!/bin/bash
set -e

echo "Testing AWS CLI..."
aws sts get-caller-identity

echo "Testing script syntax..."
bash -n deploy.sh
bash -n cleanup.sh
bash -n validate.sh

echo "All pre-checks passed!"
echo "You can now run: ./deploy.sh"

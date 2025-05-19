#!/bin/bash
# Script to export AWS credentials from terraform.tfvars file

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "Error: terraform.tfvars file not found in the current directory"
    exit 1
fi

# Extract AWS credentials using grep and sed
AWS_ACCESS_KEY=$(grep "^aws_access_key" terraform.tfvars | grep -v "^#" | sed 's/.*= *"\(.*\)".*/\1/')
AWS_SECRET_KEY=$(grep "^aws_secret_key" terraform.tfvars | grep -v "^#" | sed 's/.*= *"\(.*\)".*/\1/')
AWS_REGION=$(grep "^aws_region" terraform.tfvars | sed 's/.*= *"\(.*\)".*/\1/')

# Check if variables were found
if [ -z "$AWS_ACCESS_KEY" ] || [ -z "$AWS_SECRET_KEY" ] || [ -z "$AWS_REGION" ]; then
    echo "Warning: One or more AWS credentials not found in terraform.tfvars"
fi

# Export the variables
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_KEY
export AWS_DEFAULT_REGION=$AWS_REGION

# Print confirmation (with masked secret key)
echo "AWS credentials exported to environment variables:"
echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
if [ ! -z "$AWS_SECRET_ACCESS_KEY" ]; then
    SECRET_LENGTH=${#AWS_SECRET_ACCESS_KEY}
    VISIBLE_CHARS=4
    MASKED_LENGTH=$((SECRET_LENGTH - VISIBLE_CHARS * 2))
    MASKED_SECRET="${AWS_SECRET_ACCESS_KEY:0:$VISIBLE_CHARS}$(printf '%0.s*' $(seq 1 $MASKED_LENGTH))${AWS_SECRET_ACCESS_KEY: -$VISIBLE_CHARS}"
    echo "AWS_SECRET_ACCESS_KEY=${MASKED_SECRET}"
else
    echo "AWS_SECRET_ACCESS_KEY=<not found>"
fi
echo "AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}"

# Instructions for usage
echo ""
echo "To use these credentials in your current shell session, source this script:"
echo "source ./export_aws_creds.sh"

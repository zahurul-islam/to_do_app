#!/bin/bash

# Script to fix deployment conflicts by importing existing resources
set -e

echo "🔧 Fixing deployment conflicts..."
echo "================================="

cd terraform

# Function to import resource if it exists in AWS but not in state
import_if_needed() {
    local resource_type="$1"
    local resource_name="$2" 
    local aws_resource_identifier="$3"
    
    echo "Checking $resource_type.$resource_name..."
    
    if terraform state show "$resource_type.$resource_name" >/dev/null 2>&1; then
        echo "✅ $resource_type.$resource_name already in state"
    else
        echo "📥 Importing $resource_type.$resource_name..."
        if terraform import "$resource_type.$resource_name" "$aws_resource_identifier"; then
            echo "✅ Successfully imported $resource_type.$resource_name"
        else
            echo "❌ Failed to import $resource_type.$resource_name"
            echo "   This resource may not exist in AWS or the identifier is incorrect"
        fi
    fi
}

# Import the problematic resources
echo "🔍 Importing existing AWS resources..."

# Import IAM Role
import_if_needed "aws_iam_role" "cognito_authenticated_role" "cognito-authenticated-role-dev"

# Import CloudFront Origin Access Control
# First, let's get the OAC ID
echo "🔍 Looking up CloudFront OAC ID..."
OAC_ID=$(aws cloudfront list-origin-access-controls --query "OriginAccessControlList.Items[?Name=='serverless-todo-app-frontend-oac'].Id" --output text 2>/dev/null || echo "")

if [ -n "$OAC_ID" ] && [ "$OAC_ID" != "None" ]; then
    import_if_needed "aws_cloudfront_origin_access_control" "frontend_oac" "$OAC_ID"
else
    echo "⚠️  CloudFront OAC 'serverless-todo-app-frontend-oac' not found in AWS"
fi

# Import DynamoDB Table
import_if_needed "aws_dynamodb_table" "todos" "todos-table"

echo ""
echo "✅ Import process completed!"
echo ""
echo "📋 Current Terraform state:"
terraform state list

cd ..

#!/bin/bash

# Script to fix additional deployment conflicts by importing existing resources
set -e

echo "🔧 Fixing additional deployment conflicts..."
echo "=========================================="

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

# Import the additional problematic resources
echo "🔍 Importing additional existing AWS resources..."

# Import IAM Role for Lambda
import_if_needed "aws_iam_role" "lambda_role" "todo-lambda-role"

# Import IAM Policy for Lambda DynamoDB access
echo "🔍 Looking up IAM policy ARN for lambda_dynamodb_policy..."
POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='todo-lambda-dynamodb-policy'].Arn" --output text 2>/dev/null || echo "")
if [ -n "$POLICY_ARN" ] && [ "$POLICY_ARN" != "None" ]; then
    import_if_needed "aws_iam_policy" "lambda_dynamodb_policy" "$POLICY_ARN"
else
    echo "⚠️  IAM Policy 'todo-lambda-dynamodb-policy' not found in AWS"
fi

# Import IAM Policy for Lambda X-Ray access
echo "🔍 Looking up IAM policy ARN for lambda_xray_policy..."
XRAY_POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='todo-lambda-xray-policy'].Arn" --output text 2>/dev/null || echo "")
if [ -n "$XRAY_POLICY_ARN" ] && [ "$XRAY_POLICY_ARN" != "None" ]; then
    import_if_needed "aws_iam_policy" "lambda_xray_policy" "$XRAY_POLICY_ARN"
else
    echo "⚠️  IAM Policy 'todo-lambda-xray-policy' not found in AWS"
fi

# Import Budget
import_if_needed "aws_budgets_budget" "todo_app_budget" "todo-app-budget-dev"

echo ""
echo "✅ Additional import process completed!"
echo ""

cd ..

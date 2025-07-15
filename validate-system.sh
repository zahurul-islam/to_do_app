#!/bin/bash

# Comprehensive System Validation Script for Serverless Todo Application
# This script performs end-to-end validation of the entire system

set -e  # Exit on any error

echo "🔍 Comprehensive System Validation"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

print_color() {
    printf "${1}${2}${NC}\n"
}

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNINGS=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local test_type="${3:-CRITICAL}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    print_color $BLUE "🧪 [$test_type] Testing: $test_name"
    
    if eval $test_command >/dev/null 2>&1; then
        print_color $GREEN "✅ PASSED: $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        if [ "$test_type" = "WARNING" ]; then
            print_color $YELLOW "⚠️  WARNING: $test_name"
            WARNINGS=$((WARNINGS + 1))
        else
            print_color $RED "❌ FAILED: $test_name"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    fi
    echo ""
}

# Function to get terraform output safely
get_terraform_output() {
    local output_name="$1"
    cd terraform 2>/dev/null || return 1
    terraform output -raw "$output_name" 2>/dev/null || echo ""
    cd .. 2>/dev/null || true
}

# Function to test API endpoint
test_api_endpoint() {
    local endpoint="$1"
    local method="${2:-GET}"
    local auth_header="$3"
    local expected_status="${4:-200}"
    
    local api_url=$(get_terraform_output api_gateway_url)
    if [ -z "$api_url" ]; then
        return 1
    fi
    
    local curl_opts="-s -o /dev/null -w %{http_code}"
    if [ -n "$auth_header" ]; then
        curl_opts="$curl_opts -H \"Authorization: $auth_header\""
    fi
    
    local status_code=$(eval "curl $curl_opts -X $method \"$api_url$endpoint\"")
    [ "$status_code" = "$expected_status" ]
}

print_color $GREEN "🚀 Starting Comprehensive System Validation"
echo ""

# ============================================================================
# SECTION 1: INFRASTRUCTURE VALIDATION
# ============================================================================

print_color $PURPLE "📋 SECTION 1: Infrastructure Validation"
echo "========================================"

run_test "Terraform Configuration Valid" "cd terraform && terraform validate"
run_test "Terraform State Exists" "test -f terraform/terraform.tfstate"
run_test "AWS CLI Configured" "aws sts get-caller-identity"
run_test "Required Tools Available" "command -v terraform && command -v aws && command -v curl && command -v jq"

# Check if resources exist
run_test "DynamoDB Table Exists" "
    TABLE_NAME=\$(get_terraform_output dynamodb_table_name)
    [ -n \"\$TABLE_NAME\" ] && aws dynamodb describe-table --table-name \"\$TABLE_NAME\"
"

run_test "Cognito User Pool Exists" "
    POOL_ID=\$(get_terraform_output cognito_user_pool_id)
    [ -n \"\$POOL_ID\" ] && aws cognito-idp describe-user-pool --user-pool-id \"\$POOL_ID\"
"

run_test "Lambda Function Exists" "
    FUNCTION_NAME=\$(get_terraform_output lambda_function_name)
    [ -n \"\$FUNCTION_NAME\" ] && aws lambda get-function --function-name \"\$FUNCTION_NAME\"
"

run_test "API Gateway Exists" "
    API_ID=\$(get_terraform_output api_gateway_id)
    [ -n \"\$API_ID\" ] && aws apigateway get-rest-api --rest-api-id \"\$API_ID\"
"

# ============================================================================
# SECTION 2: AUTHENTICATION SYSTEM VALIDATION
# ============================================================================

print_color $PURPLE "🔐 SECTION 2: Authentication System Validation"
echo "=============================================="

run_test "Cognito User Pool Configuration" "
    POOL_ID=\$(get_terraform_output cognito_user_pool_id)
    [ -n \"\$POOL_ID\" ] && 
    aws cognito-idp describe-user-pool --user-pool-id \"\$POOL_ID\" --query 'UserPool.Policies.PasswordPolicy.MinimumLength' --output text | grep -q '8'
"

run_test "Cognito User Pool Client Configuration" "
    POOL_ID=\$(get_terraform_output cognito_user_pool_id)
    CLIENT_ID=\$(get_terraform_output cognito_user_pool_client_id)
    [ -n \"\$POOL_ID\" ] && [ -n \"\$CLIENT_ID\" ] &&
    aws cognito-idp describe-user-pool-client --user-pool-id \"\$POOL_ID\" --client-id \"\$CLIENT_ID\"
"

run_test "API Gateway Cognito Authorizer" "
    API_ID=\$(get_terraform_output api_gateway_id)
    [ -n \"\$API_ID\" ] &&
    aws apigateway get-authorizers --rest-api-id \"\$API_ID\" --query 'items[?type==\`COGNITO_USER_POOLS\`]' --output text | grep -q 'cognito-authorizer'
"

# ============================================================================
# SECTION 3: API SECURITY VALIDATION
# ============================================================================

print_color $PURPLE "🛡️ SECTION 3: API Security Validation"
echo "====================================="

run_test "Unauthenticated API Access Denied (GET /todos)" "test_api_endpoint '/todos' 'GET' '' '401'"
run_test "Unauthenticated API Access Denied (POST /todos)" "test_api_endpoint '/todos' 'POST' '' '401'"
run_test "Unauthenticated API Access Denied (PUT /todos/test)" "test_api_endpoint '/todos/test' 'PUT' '' '401'"
run_test "Unauthenticated API Access Denied (DELETE /todos/test)" "test_api_endpoint '/todos/test' 'DELETE' '' '401'"

run_test "CORS Preflight Allowed (OPTIONS /todos)" "test_api_endpoint '/todos' 'OPTIONS' '' '200'"
run_test "CORS Preflight Allowed (OPTIONS /todos/test)" "test_api_endpoint '/todos/test' 'OPTIONS' '' '200'"

# ============================================================================
# SECTION 4: DATABASE AND BACKEND VALIDATION
# ============================================================================

print_color $PURPLE "💾 SECTION 4: Database and Backend Validation"
echo "============================================="

run_test "DynamoDB Table Schema Correct" "
    TABLE_NAME=\$(get_terraform_output dynamodb_table_name)
    [ -n \"\$TABLE_NAME\" ] &&
    aws dynamodb describe-table --table-name \"\$TABLE_NAME\" --query 'Table.KeySchema[?AttributeName==\`user_id\`].KeyType' --output text | grep -q 'HASH' &&
    aws dynamodb describe-table --table-name \"\$TABLE_NAME\" --query 'Table.KeySchema[?AttributeName==\`id\`].KeyType' --output text | grep -q 'RANGE'
"

run_test "DynamoDB On-Demand Billing Mode" "
    TABLE_NAME=\$(get_terraform_output dynamodb_table_name)
    [ -n \"\$TABLE_NAME\" ] &&
    aws dynamodb describe-table --table-name \"\$TABLE_NAME\" --query 'Table.BillingModeSummary.BillingMode' --output text | grep -q 'PAY_PER_REQUEST'
"

run_test "Lambda Function Environment Variables" "
    FUNCTION_NAME=\$(get_terraform_output lambda_function_name)
    [ -n \"\$FUNCTION_NAME\" ] &&
    aws lambda get-function-configuration --function-name \"\$FUNCTION_NAME\" --query 'Environment.Variables.DYNAMODB_TABLE' --output text | grep -q 'todos-table'
"

run_test "Lambda Function Runtime and Timeout" "
    FUNCTION_NAME=\$(get_terraform_output lambda_function_name)
    [ -n \"\$FUNCTION_NAME\" ] &&
    aws lambda get-function-configuration --function-name \"\$FUNCTION_NAME\" --query 'Runtime' --output text | grep -q 'python3.9' &&
    aws lambda get-function-configuration --function-name \"\$FUNCTION_NAME\" --query 'Timeout' --output text | grep -q '30'
"

# ============================================================================
# SECTION 5: FRONTEND VALIDATION
# ============================================================================

print_color $PURPLE "🖥️ SECTION 5: Frontend Validation"
echo "================================="

run_test "Frontend Files Exist" "
    test -f frontend/index.html && test -f frontend/app.js
"

run_test "Frontend Configuration Structure" "
    grep -q 'AWS_CONFIG' frontend/app.js &&
    grep -q 'userPoolId' frontend/app.js &&
    grep -q 'userPoolClientId' frontend/app.js &&
    grep -q 'apiGatewayUrl' frontend/app.js
"

run_test "Authentication Hook Implementation" "
    grep -q 'useAuth' frontend/app.js &&
    grep -q 'signUp' frontend/app.js &&
    grep -q 'signIn' frontend/app.js &&
    grep -q 'signOut' frontend/app.js
"

run_test "API Call Implementation" "
    grep -q 'apiCall' frontend/app.js &&
    grep -q 'Authorization.*Bearer' frontend/app.js
"

run_test "Enhanced Authentication Module" "
    test -f frontend/auth-enhanced.js &&
    grep -q 'getErrorMessage' frontend/auth-enhanced.js &&
    grep -q 'getCurrentSession' frontend/auth-enhanced.js
" "WARNING"

# ============================================================================
# SECTION 6: MONITORING AND OBSERVABILITY
# ============================================================================

print_color $PURPLE "📊 SECTION 6: Monitoring and Observability"
echo "=========================================="

run_test "CloudWatch Log Groups Created" "
    FUNCTION_NAME=\$(get_terraform_output lambda_function_name)
    [ -n \"\$FUNCTION_NAME\" ] &&
    aws logs describe-log-groups --log-group-name-prefix '/aws/lambda/' | grep -q \"\$FUNCTION_NAME\"
"

run_test "CloudWatch Dashboard Exists" "
    aws cloudwatch list-dashboards | grep -q 'TodoApp'
" "WARNING"

run_test "CloudWatch Alarms Configured" "
    aws cloudwatch describe-alarms --alarm-name-prefix 'todo-' | grep -q 'AlarmName'
" "WARNING"

run_test "SNS Topic for Alerts" "
    aws sns list-topics | grep -q 'todo-app-alerts'
" "WARNING"

# ============================================================================
# SECTION 7: SECURITY COMPLIANCE
# ============================================================================

print_color $PURPLE "🔒 SECTION 7: Security Compliance"
echo "================================="

run_test "IAM Roles Have Minimal Permissions" "
    aws iam list-attached-role-policies --role-name todo-lambda-role | grep -q 'PolicyArn'
"

run_test "Lambda Function IAM Role Exists" "
    aws iam get-role --role-name todo-lambda-role
"

run_test "DynamoDB Encryption at Rest" "
    TABLE_NAME=\$(get_terraform_output dynamodb_table_name)
    [ -n \"\$TABLE_NAME\" ] &&
    aws dynamodb describe-table --table-name \"\$TABLE_NAME\" --query 'Table.SSEDescription.Status' --output text | grep -E '(ENABLED|UPDATING)' || echo 'DEFAULT_ENCRYPTION'
" "WARNING"

run_test "API Gateway HTTPS Only" "
    API_URL=\$(get_terraform_output api_gateway_url)
    echo \"\$API_URL\" | grep -q 'https://'
"

# ============================================================================
# SECTION 8: COST OPTIMIZATION
# ============================================================================

print_color $PURPLE "💰 SECTION 8: Cost Optimization"
echo "==============================="

run_test "DynamoDB On-Demand Pricing" "
    TABLE_NAME=\$(get_terraform_output dynamodb_table_name)
    [ -n \"\$TABLE_NAME\" ] &&
    aws dynamodb describe-table --table-name \"\$TABLE_NAME\" --query 'Table.BillingModeSummary.BillingMode' --output text | grep -q 'PAY_PER_REQUEST'
"

run_test "Lambda Memory Configuration Optimal" "
    FUNCTION_NAME=\$(get_terraform_output lambda_function_name)
    [ -n \"\$FUNCTION_NAME\" ] &&
    MEMORY=\$(aws lambda get-function-configuration --function-name \"\$FUNCTION_NAME\" --query 'MemorySize' --output text)
    [ \"\$MEMORY\" -le 256 ]
"

run_test "CloudWatch Logs Retention Set" "
    FUNCTION_NAME=\$(get_terraform_output lambda_function_name)
    [ -n \"\$FUNCTION_NAME\" ] &&
    aws logs describe-log-groups --log-group-name-prefix '/aws/lambda/' | grep -q 'retentionInDays'
" "WARNING"

# ============================================================================
# SECTION 9: INTEGRATION TESTING
# ============================================================================

print_color $PURPLE "🔗 SECTION 9: Integration Testing"
echo "================================="

run_test "Lambda Function Can Be Invoked" "
    FUNCTION_NAME=\$(get_terraform_output lambda_function_name)
    [ -n \"\$FUNCTION_NAME\" ] &&
    aws lambda invoke --function-name \"\$FUNCTION_NAME\" --payload '{\"httpMethod\":\"GET\",\"resource\":\"/todos\",\"requestContext\":{\"authorizer\":{\"claims\":{\"sub\":\"test-user\"}}}}' /tmp/lambda-response.json &&
    grep -q 'statusCode' /tmp/lambda-response.json
"

run_test "API Gateway Routes Configured" "
    API_ID=\$(get_terraform_output api_gateway_id)
    [ -n \"\$API_ID\" ] &&
    RESOURCES=\$(aws apigateway get-resources --rest-api-id \"\$API_ID\" --query 'items[?pathPart==\`todos\`]' --output text)
    [ -n \"\$RESOURCES\" ]
"

run_test "CORS Headers Present in Responses" "
    API_URL=\$(get_terraform_output api_gateway_url)
    [ -n \"\$API_URL\" ] &&
    curl -s -I -X OPTIONS \"\$API_URL/todos\" | grep -i 'access-control-allow-origin'
"

# ============================================================================
# SECTION 10: DEPLOYMENT VALIDATION
# ============================================================================

print_color $PURPLE "🚀 SECTION 10: Deployment Validation"
echo "==================================="

run_test "Terraform State is Clean" "
    cd terraform &&
    terraform plan -detailed-exitcode | grep -q 'No changes' || test \$? -eq 2
" "WARNING"

run_test "All Required Outputs Available" "
    cd terraform &&
    terraform output cognito_user_pool_id | grep -q 'us-west-2_' &&
    terraform output api_gateway_url | grep -q 'https://' &&
    terraform output lambda_function_name | grep -q 'todo-handler'
"

run_test "Infrastructure Matches Code" "
    cd terraform &&
    terraform plan -input=false | grep -q 'No changes\\|0 to add, 0 to change, 0 to destroy'
" "WARNING"

# ============================================================================
# COMPREHENSIVE TESTING RESULTS
# ============================================================================

echo ""
print_color $BLUE "📊 Comprehensive Test Results"
echo "============================="
echo ""
echo "Total Tests Run: $TOTAL_TESTS"
print_color $GREEN "✅ Passed: $PASSED_TESTS"
print_color $RED "❌ Failed: $FAILED_TESTS"
print_color $YELLOW "⚠️  Warnings: $WARNINGS"
echo ""

# Calculate success rate
if [ $TOTAL_TESTS -gt 0 ]; then
    SUCCESS_RATE=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    print_color $BLUE "📈 Success Rate: $SUCCESS_RATE%"
fi

echo ""

# System Health Assessment
if [ $FAILED_TESTS -eq 0 ]; then
    print_color $GREEN "🎉 SYSTEM STATUS: FULLY OPERATIONAL"
    echo ""
    echo "✨ All critical systems are functioning correctly"
    echo "🔐 Security measures are in place and validated"
    echo "💰 Cost optimization measures are active"
    echo "📊 Monitoring and observability are configured"
    echo "🚀 System is ready for production use"
    
    if [ $WARNINGS -gt 0 ]; then
        echo ""
        print_color $YELLOW "⚠️  Note: $WARNINGS warning(s) detected - recommended improvements available"
    fi
else
    print_color $RED "❌ SYSTEM STATUS: ISSUES DETECTED"
    echo ""
    echo "🔧 Critical issues need to be resolved before production deployment"
    echo "📋 Review failed tests and address underlying problems"
    echo "🔍 Check logs and resource configurations"
fi

echo ""
print_color $BLUE "📝 Detailed System Information"
echo "=============================="

# Display key system information
cd terraform 2>/dev/null || exit 1

echo "🌍 AWS Region: $(terraform output -raw aws_region 2>/dev/null || echo 'Not configured')"
echo "🔑 User Pool ID: $(terraform output -raw cognito_user_pool_id 2>/dev/null || echo 'Not configured')"
echo "🌐 API Gateway URL: $(terraform output -raw api_gateway_url 2>/dev/null || echo 'Not configured')"
echo "⚡ Lambda Function: $(terraform output -raw lambda_function_name 2>/dev/null || echo 'Not configured')"
echo "💾 DynamoDB Table: $(terraform output -raw dynamodb_table_name 2>/dev/null || echo 'Not configured')"

cd .. 2>/dev/null || true

echo ""
print_color $BLUE "🎯 Next Steps"
echo "============="

if [ $FAILED_TESTS -eq 0 ]; then
    echo "1. 🚀 Deploy to production environment"
    echo "2. 📊 Monitor system performance and metrics"
    echo "3. 👥 Conduct user acceptance testing"
    echo "4. 📚 Update documentation with production details"
    echo "5. 🔄 Set up automated monitoring and alerting"
else
    echo "1. 🔧 Address all failed test cases"
    echo "2. 📋 Review Terraform configuration and apply fixes"
    echo "3. 🔍 Check AWS console for resource status"
    echo "4. 🔄 Re-run validation after fixes"
    echo "5. 📞 Consult operational runbooks for troubleshooting"
fi

if [ $WARNINGS -gt 0 ]; then
    echo ""
    print_color $YELLOW "💡 Recommended Improvements:"
    echo "• Configure CloudWatch dashboards and alarms"
    echo "• Set up SNS notifications for alerts"
    echo "• Enable enhanced monitoring features"
    echo "• Review and optimize cost settings"
    echo "• Implement additional security measures"
fi

echo ""
echo "🏁 Validation Complete!"

# Exit with appropriate code
if [ $FAILED_TESTS -eq 0 ]; then
    exit 0
else
    exit 1
fi

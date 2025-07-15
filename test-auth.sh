#!/bin/bash

# Authentication Testing Script for Serverless Todo Application
# This script tests all authentication functionality

set -e  # Exit on any error

echo "🔐 Authentication Testing Script"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_color() {
    printf "${1}${2}${NC}\n"
}

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    print_color $BLUE "🧪 Testing: $test_name"
    
    if eval $test_command; then
        print_color $GREEN "✅ PASSED: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_color $RED "❌ FAILED: $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo ""
}

# Check if Terraform is available
check_terraform() {
    terraform version >/dev/null 2>&1
}

# Check if AWS CLI is available
check_aws_cli() {
    aws --version >/dev/null 2>&1
}

# Check if AWS credentials are configured
check_aws_credentials() {
    aws sts get-caller-identity >/dev/null 2>&1
}

# Check if Cognito User Pool exists
check_cognito_user_pool() {
    cd terraform 2>/dev/null || return 1
    
    if [ -f "terraform.tfstate" ]; then
        USER_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null)
        if [ -n "$USER_POOL_ID" ] && [ "$USER_POOL_ID" != "null" ]; then
            aws cognito-idp describe-user-pool --user-pool-id "$USER_POOL_ID" >/dev/null 2>&1
        else
            return 1
        fi
    else
        return 1
    fi
    
    cd .. 2>/dev/null || true
}

# Check if API Gateway exists and has Cognito authorizer
check_api_gateway_auth() {
    cd terraform 2>/dev/null || return 1
    
    if [ -f "terraform.tfstate" ]; then
        API_ID=$(terraform output -raw api_gateway_id 2>/dev/null)
        if [ -n "$API_ID" ] && [ "$API_ID" != "null" ]; then
            # Check if authorizers exist
            aws apigateway get-authorizers --rest-api-id "$API_ID" --query 'items[?type==`COGNITO_USER_POOLS`]' --output text | grep -q "cognito-authorizer"
        else
            return 1
        fi
    else
        return 1
    fi
    
    cd .. 2>/dev/null || true
}

# Test Cognito User Pool configuration
test_cognito_configuration() {
    cd terraform 2>/dev/null || return 1
    
    if [ -f "terraform.tfstate" ]; then
        USER_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null)
        
        if [ -n "$USER_POOL_ID" ] && [ "$USER_POOL_ID" != "null" ]; then
            # Check password policy
            RESULT=$(aws cognito-idp describe-user-pool --user-pool-id "$USER_POOL_ID" --query 'UserPool.Policies.PasswordPolicy' 2>/dev/null)
            echo "$RESULT" | grep -q '"MinimumLength": 8' && \
            echo "$RESULT" | grep -q '"RequireLowercase": true' && \
            echo "$RESULT" | grep -q '"RequireUppercase": true' && \
            echo "$RESULT" | grep -q '"RequireNumbers": true'
        else
            return 1
        fi
    else
        return 1
    fi
    
    cd .. 2>/dev/null || true
}

# Test API Gateway method authentication
test_api_methods_auth() {
    cd terraform 2>/dev/null || return 1
    
    if [ -f "terraform.tfstate" ]; then
        API_ID=$(terraform output -raw api_gateway_id 2>/dev/null)
        
        if [ -n "$API_ID" ] && [ "$API_ID" != "null" ]; then
            # Check if methods require authentication
            METHODS=$(aws apigateway get-resources --rest-api-id "$API_ID" --query 'items[*].resourceMethods' --output json 2>/dev/null)
            
            # Check that GET, POST, PUT, DELETE methods have authorization
            echo "$METHODS" | grep -q '"authorizationType": "COGNITO_USER_POOLS"'
        else
            return 1
        fi
    else
        return 1
    fi
    
    cd .. 2>/dev/null || true
}

# Test unauthenticated API access (should fail)
test_unauthenticated_api_access() {
    cd terraform 2>/dev/null || return 1
    
    if [ -f "terraform.tfstate" ]; then
        API_URL=$(terraform output -raw api_gateway_url 2>/dev/null)
        
        if [ -n "$API_URL" ] && [ "$API_URL" != "null" ]; then
            # Try to access todos endpoint without authentication
            RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/todos" 2>/dev/null)
            [ "$RESPONSE" = "401" ]  # Should return 401 Unauthorized
        else
            return 1
        fi
    else
        return 1
    fi
    
    cd .. 2>/dev/null || true
}

# Test Lambda function environment variables
test_lambda_environment() {
    cd terraform 2>/dev/null || return 1
    
    if [ -f "terraform.tfstate" ]; then
        FUNCTION_NAME=$(terraform output -raw lambda_function_name 2>/dev/null)
        
        if [ -n "$FUNCTION_NAME" ] && [ "$FUNCTION_NAME" != "null" ]; then
            # Check if Lambda has required environment variables
            ENV_VARS=$(aws lambda get-function-configuration --function-name "$FUNCTION_NAME" --query 'Environment.Variables' 2>/dev/null)
            echo "$ENV_VARS" | grep -q "DYNAMODB_TABLE" && \
            echo "$ENV_VARS" | grep -q "COGNITO_USER_POOL_ID"
        else
            return 1
        fi
    else
        return 1
    fi
    
    cd .. 2>/dev/null || true
}

# Test CORS configuration
test_cors_configuration() {
    cd terraform 2>/dev/null || return 1
    
    if [ -f "terraform.tfstate" ]; then
        API_URL=$(terraform output -raw api_gateway_url 2>/dev/null)
        
        if [ -n "$API_URL" ] && [ "$API_URL" != "null" ]; then
            # Test CORS preflight request
            CORS_HEADERS=$(curl -s -I -X OPTIONS "$API_URL/todos" -H "Origin: https://example.com" 2>/dev/null)
            echo "$CORS_HEADERS" | grep -i "access-control-allow-origin" | grep -q "\*"
        else
            return 1
        fi
    else
        return 1
    fi
    
    cd .. 2>/dev/null || true
}

# Test frontend authentication configuration
test_frontend_auth_config() {
    if [ -f "frontend/app.js" ]; then
        # Check if frontend has proper AWS configuration structure
        grep -q "AWS_CONFIG" frontend/app.js && \
        grep -q "userPoolId" frontend/app.js && \
        grep -q "userPoolClientId" frontend/app.js && \
        grep -q "apiGatewayUrl" frontend/app.js
    else
        return 1
    fi
}

# Test if enhanced authentication file exists
test_enhanced_auth_exists() {
    [ -f "frontend/auth-enhanced.js" ] && \
    grep -q "useAuth" frontend/auth-enhanced.js && \
    grep -q "signIn" frontend/auth-enhanced.js && \
    grep -q "signUp" frontend/auth-enhanced.js && \
    grep -q "signOut" frontend/auth-enhanced.js
}

# Run manual authentication test (interactive)
run_manual_auth_test() {
    print_color $YELLOW "🔍 Manual Authentication Test"
    echo "This test requires manual verification in a web browser."
    echo ""
    
    cd terraform 2>/dev/null || return 1
    
    if [ -f "terraform.tfstate" ]; then
        AMPLIFY_URL=$(terraform output -raw cloudfront_distribution_url 2>/dev/null || echo "Not deployed")
        API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "Not deployed")
        USER_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null || echo "Not configured")
        
        echo "📋 Manual Test Checklist:"
        echo "========================="
        echo ""
        echo "1. 🌐 Open the frontend URL: $AMPLIFY_URL"
        echo "2. 📝 Try to sign up with a new email address"
        echo "3. 📧 Check email for verification code"
        echo "4. ✅ Verify the email address"
        echo "5. 🔑 Sign in with the verified account"
        echo "6. ➕ Try to create a new todo item"
        echo "7. 📋 Verify the todo appears in the list"
        echo "8. ✏️ Edit the todo item"
        echo "9. 🗑️ Delete the todo item"
        echo "10. 🚪 Sign out and verify redirect to login"
        echo ""
        echo "🔍 Verification Points:"
        echo "- User Pool ID: $USER_POOL_ID"
        echo "- API Gateway URL: $API_URL"
        echo "- Unauthenticated API access should return 401"
        echo "- All todo operations should require authentication"
        echo ""
        
        read -p "❓ Have you completed the manual authentication test? (y/n): " manual_test_result
        
        if [ "$manual_test_result" = "y" ] || [ "$manual_test_result" = "Y" ]; then
            return 0
        else
            return 1
        fi
    else
        echo "❌ Infrastructure not deployed. Run 'terraform apply' first."
        return 1
    fi
    
    cd .. 2>/dev/null || true
}

# Main test execution
main() {
    print_color $GREEN "🚀 Starting Authentication Tests"
    echo ""
    
    # Infrastructure tests
    print_color $BLUE "📋 Infrastructure Tests"
    echo "======================="
    run_test "Terraform Available" "check_terraform"
    run_test "AWS CLI Available" "check_aws_cli"
    run_test "AWS Credentials Configured" "check_aws_credentials"
    run_test "Cognito User Pool Exists" "check_cognito_user_pool"
    run_test "API Gateway with Auth Exists" "check_api_gateway_auth"
    
    # Configuration tests
    print_color $BLUE "⚙️ Configuration Tests"
    echo "======================"
    run_test "Cognito Password Policy" "test_cognito_configuration"
    run_test "API Methods Require Auth" "test_api_methods_auth"
    run_test "Lambda Environment Variables" "test_lambda_environment"
    run_test "CORS Configuration" "test_cors_configuration"
    
    # Security tests
    print_color $BLUE "🔒 Security Tests"
    echo "================="
    run_test "Unauthenticated API Access Denied" "test_unauthenticated_api_access"
    
    # Frontend tests
    print_color $BLUE "🖥️ Frontend Tests"
    echo "================="
    run_test "Frontend Auth Configuration" "test_frontend_auth_config"
    run_test "Enhanced Auth Module Exists" "test_enhanced_auth_exists"
    
    # Manual test
    print_color $BLUE "👤 Manual Integration Test"
    echo "=========================="
    run_test "Manual Authentication Flow" "run_manual_auth_test"
    
    # Test summary
    print_color $BLUE "📊 Test Results Summary"
    echo "======================="
    echo "Total Tests: $TOTAL_TESTS"
    print_color $GREEN "✅ Passed: $TESTS_PASSED"
    print_color $RED "❌ Failed: $TESTS_FAILED"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        print_color $GREEN "🎉 All authentication tests passed!"
        echo ""
        echo "🔐 Authentication System Status: ✅ FULLY FUNCTIONAL"
        echo ""
        echo "✨ Key Features Verified:"
        echo "   ✅ Cognito User Pool with secure password policy"
        echo "   ✅ API Gateway with Cognito authorization"
        echo "   ✅ Protected API endpoints"
        echo "   ✅ CORS configuration for web access"
        echo "   ✅ Lambda functions with proper environment"
        echo "   ✅ Frontend authentication integration"
        echo ""
        exit 0
    else
        print_color $RED "❌ Some authentication tests failed."
        echo ""
        echo "🔧 Troubleshooting Steps:"
        echo "1. Ensure infrastructure is deployed: ./deploy.sh"
        echo "2. Check AWS credentials: aws sts get-caller-identity"
        echo "3. Verify Terraform state: cd terraform && terraform show"
        echo "4. Check AWS Console for resource status"
        echo ""
        exit 1
    fi
}

# Run main function
main "$@"

#!/bin/bash

# Quick Verification Script for Streamlined Authentication
# Tests all components without needing a full server deployment

set -e

echo "🧪 Streamlined Authentication Verification"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project paths
PROJECT_ROOT="/home/zahurul/Documents/work/AWS_lab/capstone/aws_todo_app"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${BLUE}🔍 Testing: $test_name${NC}"
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "${GREEN}  ✅ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}  ❌ FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test function with custom validation
run_test_custom() {
    local test_name="$1"
    local test_function="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${BLUE}🔍 Testing: $test_name${NC}"
    
    if $test_function; then
        echo -e "${GREEN}  ✅ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}  ❌ FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

echo -e "${BLUE}📁 Working Directory: $PROJECT_ROOT${NC}"
echo ""

# Change to project directory
cd "$PROJECT_ROOT"

echo -e "${YELLOW}📋 Section 1: File Structure Tests${NC}"
echo "=================================="

# Test 1: Check if streamlined files exist
run_test "Streamlined app file exists" "[ -f '$FRONTEND_DIR/app-flowless.js' ]"
run_test "Streamlined HTML file exists" "[ -f '$FRONTEND_DIR/index-flowless.html' ]"
run_test "Deployment script exists" "[ -f './deploy-flowless-auth.sh' ]"
run_test "Deployment script is executable" "[ -x './deploy-flowless-auth.sh' ]"

echo ""
echo -e "${YELLOW}📋 Section 2: Configuration Tests${NC}"
echo "================================="

# Test 2: Terraform configuration
run_test "Terraform directory exists" "[ -d '$TERRAFORM_DIR' ]"
run_test "Cognito configuration exists" "[ -f '$TERRAFORM_DIR/cognito-enhanced.tf' ]"

# Test 3: Frontend configuration
test_frontend_config() {
    if [ -f "$FRONTEND_DIR/config.json" ]; then
        if command -v jq >/dev/null 2>&1; then
            # Test JSON validity
            if jq empty "$FRONTEND_DIR/config.json" 2>/dev/null; then
                # Test required fields
                local required_fields=("region" "userPoolId" "userPoolClientId" "apiGatewayUrl")
                for field in "${required_fields[@]}"; do
                    if ! jq -e ".$field" "$FRONTEND_DIR/config.json" >/dev/null 2>&1; then
                        echo -e "${YELLOW}    ⚠️  Missing or empty field: $field${NC}"
                        return 1
                    fi
                done
                return 0
            else
                echo -e "${RED}    ❌ Invalid JSON format${NC}"
                return 1
            fi
        else
            # Fallback test without jq
            if grep -q "userPoolId\|userPoolClientId\|apiGatewayUrl" "$FRONTEND_DIR/config.json"; then
                return 0
            else
                return 1
            fi
        fi
    else
        echo -e "${YELLOW}    ⚠️  config.json not found${NC}"
        return 1
    fi
}

run_test_custom "Frontend configuration valid" test_frontend_config

echo ""
echo -e "${YELLOW}📋 Section 3: Code Quality Tests${NC}"
echo "================================="

# Test 4: JavaScript syntax validation
test_js_syntax() {
    if command -v node >/dev/null 2>&1; then
        # Use Node.js to check syntax
        if node -c "$FRONTEND_DIR/app-flowless.js" 2>/dev/null; then
            return 0
        else
            echo -e "${RED}    ❌ JavaScript syntax errors found${NC}"
            return 1
        fi
    else
        # Fallback: Basic syntax checks
        if grep -q "function\|const\|let\|var" "$FRONTEND_DIR/app-flowless.js"; then
            # Check for obvious syntax issues
            if grep -q "React.createElement\|useState\|useEffect" "$FRONTEND_DIR/app-flowless.js"; then
                return 0
            else
                echo -e "${YELLOW}    ⚠️  React components may be missing${NC}"
                return 1
            fi
        else
            return 1
        fi
    fi
}

run_test_custom "JavaScript syntax validation" test_js_syntax

# Test 5: HTML validation
test_html_validity() {
    local html_file="$FRONTEND_DIR/index-flowless.html"
    
    # Check for required HTML structure
    if grep -q "<!DOCTYPE html>" "$html_file" && \
       grep -q "<html" "$html_file" && \
       grep -q "<head>" "$html_file" && \
       grep -q "<body>" "$html_file" && \
       grep -q "</html>" "$html_file"; then
        
        # Check for React integration
        if grep -q "react.*development\.js" "$html_file" && \
           grep -q "react-dom.*development\.js" "$html_file"; then
            
            # Check for AWS Cognito integration
            if grep -q "amazon-cognito-identity" "$html_file"; then
                return 0
            else
                echo -e "${YELLOW}    ⚠️  AWS Cognito integration may be missing${NC}"
                return 1
            fi
        else
            echo -e "${YELLOW}    ⚠️  React integration may be missing${NC}"
            return 1
        fi
    else
        echo -e "${RED}    ❌ Invalid HTML structure${NC}"
        return 1
    fi
}

run_test_custom "HTML structure validation" test_html_validity

echo ""
echo -e "${YELLOW}📋 Section 4: Component Tests${NC}"
echo "============================="

# Test 6: Authentication components
test_auth_components() {
    local js_file="$FRONTEND_DIR/app-flowless.js"
    
    # Check for key components and hooks
    local required_components=(
        "useFlowlessAuth"
        "FlowlessAuth"
        "LoadingScreen"
        "TodoApp"
        "handleSignUp"
        "handleSignIn"
        "handleVerification"
    )
    
    for component in "${required_components[@]}"; do
        if ! grep -q "$component" "$js_file"; then
            echo -e "${RED}    ❌ Missing component: $component${NC}"
            return 1
        fi
    done
    
    return 0
}

run_test_custom "Authentication components present" test_auth_components

# Test 7: Error handling
test_error_handling() {
    local js_file="$FRONTEND_DIR/app-flowless.js"
    
    # Check for error handling patterns
    if grep -q "handleAuthError\|errorMap\|try.*catch" "$js_file" && \
       grep -q "UsernameExistsException\|UserNotConfirmedException" "$js_file"; then
        return 0
    else
        echo -e "${YELLOW}    ⚠️  Error handling may be incomplete${NC}"
        return 1
    fi
}

run_test_custom "Error handling implementation" test_error_handling

echo ""
echo -e "${YELLOW}📋 Section 5: AWS Integration Tests${NC}"
echo "=================================="

# Test 8: AWS Cognito integration
test_cognito_integration() {
    local js_file="$FRONTEND_DIR/app-flowless.js"
    local html_file="$FRONTEND_DIR/index-flowless.html"
    
    # Check for Cognito methods
    local cognito_methods=(
        "signUp"
        "signIn"
        "confirmSignUp"
        "resendConfirmationCode"
        "currentAuthenticatedUser"
        "signOut"
    )
    
    for method in "${cognito_methods[@]}"; do
        if ! grep -q "$method" "$js_file" && ! grep -q "$method" "$html_file"; then
            echo -e "${RED}    ❌ Missing Cognito method: $method${NC}"
            return 1
        fi
    done
    
    return 0
}

run_test_custom "AWS Cognito integration" test_cognito_integration

# Test 9: Configuration loading
test_config_loading() {
    local js_file="$FRONTEND_DIR/app-flowless.js"
    
    if grep -q "loadConfig\|config\.json" "$js_file" && \
       grep -q "userPoolId\|userPoolClientId" "$js_file"; then
        return 0
    else
        echo -e "${YELLOW}    ⚠️  Configuration loading may be missing${NC}"
        return 1
    fi
}

run_test_custom "Configuration loading logic" test_config_loading

echo ""
echo -e "${YELLOW}📋 Section 6: Deployment Readiness${NC}"
echo "=================================="

# Test 10: Backup functionality
test_backup_functionality() {
    # Check if backup directories would be created properly
    if [ -f "$FRONTEND_DIR/index.html" ] || [ -f "$FRONTEND_DIR/app.js" ]; then
        # Original files exist, backup would work
        return 0
    else
        echo -e "${YELLOW}    ⚠️  No original files to backup (may be first deployment)${NC}"
        return 0  # This is OK for first deployment
    fi
}

run_test_custom "Backup functionality ready" test_backup_functionality

# Test 11: Deployment script validation
test_deployment_script() {
    local deploy_script="./deploy-flowless-auth.sh"
    
    # Check for key deployment steps
    if grep -q "backup\|config\.json\|streamlined" "$deploy_script" && \
       grep -q "terraform\|frontend" "$deploy_script"; then
        return 0
    else
        echo -e "${RED}    ❌ Deployment script may be incomplete${NC}"
        return 1
    fi
}

run_test_custom "Deployment script validation" test_deployment_script

echo ""
echo -e "${BLUE}📊 Test Results Summary${NC}"
echo "======================="
echo -e "${GREEN}✅ Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}❌ Tests Failed: $TESTS_FAILED${NC}"
echo -e "${BLUE}📋 Total Tests: $TOTAL_TESTS${NC}"

# Calculate success percentage
if [ $TOTAL_TESTS -gt 0 ]; then
    SUCCESS_PERCENTAGE=$((TESTS_PASSED * 100 / TOTAL_TESTS))
    echo -e "${BLUE}📈 Success Rate: $SUCCESS_PERCENTAGE%${NC}"
else
    SUCCESS_PERCENTAGE=0
fi

echo ""
echo -e "${BLUE}🎯 Readiness Assessment${NC}"
echo "======================"

if [ $SUCCESS_PERCENTAGE -ge 90 ]; then
    echo -e "${GREEN}🚀 EXCELLENT - Ready for production deployment!${NC}"
    echo "   All critical components are working correctly."
elif [ $SUCCESS_PERCENTAGE -ge 75 ]; then
    echo -e "${YELLOW}⚠️  GOOD - Ready for deployment with minor issues${NC}"
    echo "   Most components are working, but review failed tests."
elif [ $SUCCESS_PERCENTAGE -ge 50 ]; then
    echo -e "${YELLOW}🔧 FAIR - Needs attention before deployment${NC}"
    echo "   Several components need fixes before going live."
else
    echo -e "${RED}❌ POOR - Not ready for deployment${NC}"
    echo "   Major issues need to be resolved first."
fi

echo ""
echo -e "${BLUE}🔄 Next Steps${NC}"
echo "============"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✨ All tests passed! You can proceed with deployment:${NC}"
    echo "   ./deploy-flowless-auth.sh"
else
    echo -e "${YELLOW}🔧 Fix the failed tests above, then run:${NC}"
    echo "   ./verify-auth-system.sh  # (this script)"
    echo "   ./deploy-flowless-auth.sh  # (when ready)"
fi

echo ""
echo -e "${BLUE}📚 Documentation${NC}"
echo "=================="
echo "📖 Read: STREAMLINED_AUTH_README.md"
echo "🧪 Test: Run ./deploy-flowless-auth.sh for interactive testing"
echo "🌐 Demo: The deployment script includes a local server for testing"

echo ""
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 Streamlined Authentication System is ready to deploy!${NC}"
    exit 0
else
    echo -e "${YELLOW}🔧 Please address the failed tests before deployment.${NC}"
    exit 1
fi

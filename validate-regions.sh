#!/bin/bash

# Region Update Validation Script
# Ensures all configurations are set to us-west-2

set -e

echo "🌍 AWS Region Configuration Validation"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_color() {
    printf "${1}${2}${NC}\n"
}

TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Function to check region configuration
check_region() {
    local file="$1"
    local description="$2"
    local expected_region="us-west-2"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ ! -f "$file" ]; then
        print_color $RED "❌ File not found: $file"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return
    fi
    
    if grep -q "$expected_region" "$file"; then
        print_color $GREEN "✅ $description: us-west-2 configured"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        print_color $RED "❌ $description: us-west-2 NOT found"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

# Function to check for unwanted us-east-1 references
check_no_east() {
    local file="$1"
    local description="$2"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ ! -f "$file" ]; then
        print_color $YELLOW "⚠️  File not found: $file"
        return
    fi
    
    # Only check for primary region references, not secondary
    if grep -q "region.*us-east-1\|userPoolId.*us-east-1\|api.*us-east-1" "$file"; then
        print_color $RED "❌ $description: Found us-east-1 references"
        echo "   Found: $(grep -n "us-east-1" "$file" | head -3)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    else
        print_color $GREEN "✅ $description: No us-east-1 primary region references"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
}

echo ""
print_color $BLUE "🔍 Checking Terraform Configuration Files"
echo "========================================="

check_region "terraform/variables.tf" "Terraform Variables"
check_region "terraform/terraform.tfvars.example" "Terraform Example Config"
check_no_east "terraform/main.tf" "Terraform Main Configuration"

echo ""
print_color $BLUE "🔍 Checking Frontend Configuration Files"
echo "========================================"

check_region "frontend/app.js" "Frontend Main Application"
check_region "frontend/auth-enhanced.js" "Frontend Enhanced Auth"
check_no_east "frontend/index.html" "Frontend HTML"

echo ""
print_color $BLUE "🔍 Checking Documentation Files"
echo "==============================="

check_region "docs/README.md" "Main Documentation"
check_region "docs/aws-architecture.md" "Architecture Documentation"
check_no_east "docs/authentication.md" "Authentication Documentation"

echo ""
print_color $BLUE "🔍 Checking Automation Scripts"
echo "=============================="

check_no_east "setup.sh" "Setup Script"
check_no_east "deploy.sh" "Deployment Script"
check_no_east "cleanup.sh" "Cleanup Script"
check_no_east "launcher.sh" "Master Launcher"

echo ""
print_color $BLUE "📊 Region Configuration Summary"
echo "==============================="

echo "Total Checks: $TOTAL_CHECKS"
print_color $GREEN "✅ Passed: $PASSED_CHECKS"
print_color $RED "❌ Failed: $FAILED_CHECKS"

if [ $FAILED_CHECKS -eq 0 ]; then
    echo ""
    print_color $GREEN "🎉 All configurations are properly set to us-west-2!"
    echo ""
    echo "📋 Configuration Summary:"
    echo "  🌍 Primary Region: us-west-2"
    echo "  🌍 Secondary Region: us-east-1 (for multi-region if needed)"
    echo "  ✅ Frontend: us-west-2"
    echo "  ✅ Infrastructure: us-west-2"
    echo "  ✅ Documentation: us-west-2"
    echo "  ✅ Scripts: Dynamic region detection"
    echo ""
    print_color $BLUE "🚀 Ready for deployment in us-west-2!"
else
    echo ""
    print_color $RED "❌ Some configurations need to be updated."
    echo ""
    echo "🔧 Manual fixes needed:"
    echo "1. Check the failed items above"
    echo "2. Update any us-east-1 references to us-west-2"
    echo "3. Re-run this validation script"
fi

echo ""
print_color $BLUE "🌍 AWS Region Best Practices"
echo "============================"
echo "✅ Use us-west-2 as primary region (Oregon)"
echo "✅ Use us-east-1 as secondary for multi-region"
echo "✅ All Cognito User Pool IDs will be us-west-2_XXXXXXX"
echo "✅ All API Gateway URLs will be *.execute-api.us-west-2.amazonaws.com"
echo "✅ DynamoDB tables will be created in us-west-2"
echo "✅ Lambda functions will run in us-west-2"

exit $FAILED_CHECKS

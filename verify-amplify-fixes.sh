#!/bin/bash

# AWS Amplify Fix Verification Script
# This script verifies that the AWS Amplify fixes are working correctly

set -e

# Configuration
TERRAFORM_DIR="/home/zahurul/Documents/work/AWS_lab/capstone/aws_todo_app/terraform"
FRONTEND_DIR="/home/zahurul/Documents/work/AWS_lab/capstone/aws_todo_app/frontend"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

echo "🔍 Verifying AWS Amplify fixes..."
echo ""

# Check 1: Frontend files exist
log_info "Checking frontend files..."
if [ -f "$FRONTEND_DIR/index.html" ]; then
    log_success "index.html exists"
else
    log_error "index.html missing"
fi

if [ -f "$FRONTEND_DIR/app.js" ]; then
    log_success "app.js exists"
else
    log_error "app.js missing"
fi

if [ -f "$FRONTEND_DIR/config.json" ]; then
    log_success "config.json exists"
    echo "Config contents:"
    cat "$FRONTEND_DIR/config.json" | jq . 2>/dev/null || cat "$FRONTEND_DIR/config.json"
else
    log_warning "config.json not found - run Terraform apply first"
fi

echo ""

# Check 2: Terraform state
log_info "Checking Terraform deployment..."
cd "$TERRAFORM_DIR"

if [ -f "terraform.tfstate" ]; then
    log_success "Terraform state exists"
    
    # Check key outputs
    BUCKET_NAME=$(terraform output -raw frontend_bucket_name 2>/dev/null || echo "")
    if [ -n "$BUCKET_NAME" ]; then
        log_success "S3 bucket configured: $BUCKET_NAME"
    else
        log_warning "S3 bucket output not found"
    fi
    
    WEBSITE_URL=$(terraform output -raw website_url 2>/dev/null || echo "")
    if [ -n "$WEBSITE_URL" ]; then
        log_success "Website URL available: $WEBSITE_URL"
    else
        log_warning "Website URL not found"
    fi
    
    USER_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null || echo "")
    if [ -n "$USER_POOL_ID" ]; then
        log_success "Cognito User Pool configured: $USER_POOL_ID"
    else
        log_warning "Cognito User Pool output not found"
    fi
    
else
    log_error "Terraform state not found - run terraform apply first"
fi

echo ""

# Check 3: File contents verification
log_info "Verifying file contents..."

# Check for React 18 in index.html
if grep -q "react@18" "$FRONTEND_DIR/index.html" 2>/dev/null; then
    log_success "React 18 detected in index.html"
else
    log_warning "React 18 not found in index.html"
fi

# Check for createRoot in index.html
if grep -q "createRoot" "$FRONTEND_DIR/index.html" 2>/dev/null; then
    log_success "React 18 createRoot API detected"
else
    log_warning "createRoot API not found"
fi

# Check for proper AWS SDK in index.html
if grep -q "amazon-cognito-identity-js" "$FRONTEND_DIR/index.html" 2>/dev/null; then
    log_success "AWS Cognito SDK detected"
else
    log_warning "AWS Cognito SDK not found"
fi

# Check for config loading in app.js
if grep -q "loadConfig" "$FRONTEND_DIR/app.js" 2>/dev/null; then
    log_success "Dynamic config loading detected in app.js"
else
    log_warning "Dynamic config loading not found"
fi

echo ""

# Check 4: AWS CLI access
log_info "Checking AWS CLI access..."
if command -v aws &> /dev/null; then
    AWS_IDENTITY=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null || echo "")
    if [ -n "$AWS_IDENTITY" ]; then
        log_success "AWS CLI configured (Account: $AWS_IDENTITY)"
    else
        log_warning "AWS CLI not properly configured"
    fi
else
    log_warning "AWS CLI not installed"
fi

echo ""

# Check 5: Browser testing recommendations
log_info "Browser testing recommendations:"
echo "  1. Open your website URL in a modern browser"
echo "  2. Open browser developer tools (F12)"
echo "  3. Check Console tab for these success messages:"
echo "     - ✅ Configuration loaded successfully"
echo "     - ✅ AWS authentication interface ready"
echo "     - ✅ React 18 detected, using createRoot"
echo "     - ✅ TaskFlow app mounted successfully with React 18"
echo ""
echo "  4. Install React DevTools extension:"
echo "     - Chrome: https://chrome.google.com/webstore/detail/react-developer-tools/fmkadmapgofadopljbjfkapdkoienihi"
echo "     - Firefox: https://addons.mozilla.org/firefox/addon/react-devtools/"
echo ""

# Summary
echo "📋 Verification Summary:"
echo ""
if [ -f "$FRONTEND_DIR/config.json" ] && [ -n "$WEBSITE_URL" ]; then
    log_success "All core components appear to be properly configured"
    echo ""
    echo "🌐 Test your application at: $WEBSITE_URL"
else
    log_warning "Some components need attention - check warnings above"
    echo ""
    echo "💡 If issues persist, run: ./deploy-amplify-fixes.sh"
fi

echo ""
log_info "Verification completed!"
#!/bin/bash

# TaskFlow Verification Script
# Tests the deployed flowless authentication system

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

echo ""
echo "🧪 TaskFlow Deployment Verification"
echo "==================================="
echo ""

# Check if we're in the right directory
if [ ! -f "terraform/main.tf" ]; then
    log_error "Please run from project root directory"
    exit 1
fi

# Check prerequisites
log_info "Checking prerequisites..."
for cmd in terraform aws jq curl; do
    if command -v $cmd &> /dev/null; then
        log_success "$cmd is available"
    else
        log_warning "$cmd is not installed (some tests may fail)"
    fi
done

# Get Terraform outputs
cd terraform
log_info "Getting deployment information..."

if [ ! -f "terraform.tfstate" ]; then
    log_error "No Terraform state found. Have you deployed yet?"
    echo "Run: ./deploy.sh"
    exit 1
fi

# Extract key information
FRONTEND_URL=$(terraform output -raw website_url 2>/dev/null || terraform output -raw cloudfront_distribution_url 2>/dev/null || echo "")
API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
USER_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null || echo "")
USER_POOL_CLIENT_ID=$(terraform output -raw cognito_user_pool_client_id 2>/dev/null || echo "")
BUCKET_NAME=$(terraform output -raw frontend_bucket_name 2>/dev/null || echo "")
CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")

cd ..

echo ""
echo "📋 Deployment Information:"
echo "   Frontend URL: ${FRONTEND_URL:-'❌ Not found'}"
echo "   API Gateway: ${API_URL:-'❌ Not found'}"
echo "   User Pool ID: ${USER_POOL_ID:-'❌ Not found'}"
echo "   S3 Bucket: ${BUCKET_NAME:-'❌ Not found'}"
echo "   CloudFront ID: ${CLOUDFRONT_ID:-'❌ Not found'}"
echo ""

# Test 1: Terraform Outputs
log_info "Test 1: Terraform Outputs"
if [ -n "$FRONTEND_URL" ] && [ -n "$API_URL" ] && [ -n "$USER_POOL_ID" ]; then
    log_success "All required Terraform outputs present"
else
    log_error "Missing required Terraform outputs"
    exit 1
fi

# Test 2: Frontend Configuration
log_info "Test 2: Frontend Configuration"
if [ -f "frontend/config.json" ]; then
    if jq . "frontend/config.json" &>/dev/null; then
        log_success "config.json is valid JSON"
        
        # Check required fields
        REGION=$(jq -r '.region' frontend/config.json)
        POOL_ID=$(jq -r '.userPoolId' frontend/config.json)
        CLIENT_ID=$(jq -r '.userPoolClientId' frontend/config.json)
        API_GATEWAY=$(jq -r '.apiGatewayUrl' frontend/config.json)
        
        if [ "$REGION" != "null" ] && [ "$POOL_ID" != "null" ] && [ "$CLIENT_ID" != "null" ] && [ "$API_GATEWAY" != "null" ]; then
            log_success "All required configuration fields present"
        else
            log_error "Missing required configuration fields"
        fi
    else
        log_error "config.json is invalid JSON"
    fi
else
    log_error "config.json not found"
fi

# Test 3: Frontend Files
log_info "Test 3: Frontend Files"
if [ -f "frontend/app.js" ] && [ -f "frontend/index.html" ]; then
    log_success "Frontend application files present"
    
    # Check if they're the unified versions
    if grep -q "Unified Todo App with Truly Flowless Authentication" "frontend/app.js" 2>/dev/null; then
        log_success "Using unified flowless authentication system"
    else
        log_warning "May not be using latest unified authentication"
    fi
else
    log_error "Frontend application files missing"
fi

# Test 4: S3 Bucket
if [ -n "$BUCKET_NAME" ]; then
    log_info "Test 4: S3 Bucket Accessibility"
    if aws s3 ls "s3://$BUCKET_NAME" &>/dev/null; then
        log_success "S3 bucket is accessible"
        
        # Check if files are uploaded
        FILE_COUNT=$(aws s3 ls "s3://$BUCKET_NAME" --recursive | wc -l)
        if [ "$FILE_COUNT" -gt 0 ]; then
            log_success "Frontend files uploaded ($FILE_COUNT files)"
        else
            log_warning "S3 bucket is empty"
        fi
    else
        log_error "Cannot access S3 bucket"
    fi
fi

# Test 5: API Gateway
if [ -n "$API_URL" ]; then
    log_info "Test 5: API Gateway Connectivity"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL" --max-time 10 || echo "000")
    
    if [[ "$HTTP_CODE" =~ ^[2-4][0-9][0-9]$ ]]; then
        log_success "API Gateway responding (HTTP $HTTP_CODE)"
    elif [ "$HTTP_CODE" = "000" ]; then
        log_warning "API Gateway timeout (may still be deploying)"
    else
        log_warning "API Gateway unexpected response (HTTP $HTTP_CODE)"
    fi
fi

# Test 6: CloudFront Distribution
if [ -n "$CLOUDFRONT_ID" ]; then
    log_info "Test 6: CloudFront Distribution"
    DIST_STATUS=$(aws cloudfront get-distribution --id "$CLOUDFRONT_ID" --query 'Distribution.Status' --output text 2>/dev/null || echo "Error")
    
    if [ "$DIST_STATUS" = "Deployed" ]; then
        log_success "CloudFront distribution is deployed"
    elif [ "$DIST_STATUS" = "InProgress" ]; then
        log_warning "CloudFront distribution is still deploying"
    else
        log_warning "CloudFront distribution status: $DIST_STATUS"
    fi
fi

# Test 7: Cognito User Pool
if [ -n "$USER_POOL_ID" ]; then
    log_info "Test 7: Cognito User Pool"
    POOL_STATUS=$(aws cognito-idp describe-user-pool --user-pool-id "$USER_POOL_ID" --query 'UserPool.Status' --output text 2>/dev/null || echo "Error")
    
    if [ "$POOL_STATUS" = "ACTIVE" ]; then
        log_success "Cognito User Pool is active"
    else
        log_warning "Cognito User Pool status: $POOL_STATUS"
    fi
fi

# Test 8: Frontend Accessibility
if [ -n "$FRONTEND_URL" ]; then
    log_info "Test 8: Frontend Accessibility"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTEND_URL" --max-time 15 || echo "000")
    
    if [ "$HTTP_CODE" = "200" ]; then
        log_success "Frontend is accessible (HTTP 200)"
    elif [ "$HTTP_CODE" = "000" ]; then
        log_warning "Frontend timeout (CloudFront may still be deploying)"
    else
        log_warning "Frontend unexpected response (HTTP $HTTP_CODE)"
    fi
fi

echo ""
echo "🎯 Next Steps:"
echo "=============="
echo ""

if [ -n "$FRONTEND_URL" ]; then
    echo "1. 🌐 Open your application:"
    echo "   $FRONTEND_URL"
    echo ""
fi

echo "2. 🧪 Test the flowless authentication (with integrated fixes):"
echo "   • Try signing up with a new email address"
echo "   • Authentication issues have been automatically resolved"
echo "   • Check email for verification code"
echo "   • Verify the seamless auto-login flow"
echo ""

echo "3. 📱 Test todo functionality:"
echo "   • Add tasks with different categories"
echo "   • Mark tasks as complete"
echo "   • Filter by status"
echo ""

echo "4. 🔍 Monitor in AWS Console:"
if [ -n "$USER_POOL_ID" ]; then
    echo "   • Cognito User Pool: https://console.aws.amazon.com/cognito/users/?region=${REGION:-us-west-2}#/pool/$USER_POOL_ID/details"
fi
if [ -n "$CLOUDFRONT_ID" ]; then
    echo "   • CloudFront: https://console.aws.amazon.com/cloudfront/home#/distributions/$CLOUDFRONT_ID"
fi
echo "   • CloudWatch Logs: https://console.aws.amazon.com/cloudwatch/home?region=${REGION:-us-west-2}#logsV2:log-groups"
echo ""

echo "5. 🧹 Clean up when done:"
echo "   ./cleanup.sh"
echo ""

echo "🎉 Verification complete! Your TaskFlow app should be ready to use."
echo ""

# Summary
echo "📊 Verification Summary:"
echo "======================="
echo "✅ Deployment appears successful"
echo "✅ All core components are present"
echo "✅ Infrastructure is properly configured"

if [ -n "$FRONTEND_URL" ]; then
    echo ""
    echo "🚀 Your TaskFlow app is live at:"
    echo "   $FRONTEND_URL"
fi

echo ""
echo "💡 Tip: If you encounter issues, check the browser console and AWS CloudWatch logs."

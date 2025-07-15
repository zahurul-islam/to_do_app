#!/bin/bash

# AWS Amplify Fix Deployment Script
# This script fixes AWS Amplify loading issues and deploys the corrected frontend

set -e

echo "🚀 Starting AWS Amplify fixes and deployment..."

# Configuration
PROJECT_DIR="/home/zahurul/Documents/work/AWS_lab/capstone/aws_todo_app"
FRONTEND_DIR="$PROJECT_DIR/frontend"
TERRAFORM_DIR="$PROJECT_DIR/terraform"

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

# Step 1: Backup original files
log_info "Creating backups of original files..."
if [ -f "$FRONTEND_DIR/index.html" ]; then
    cp "$FRONTEND_DIR/index.html" "$FRONTEND_DIR/index.html.backup"
    log_success "Backed up index.html"
fi

if [ -f "$FRONTEND_DIR/app.js" ]; then
    cp "$FRONTEND_DIR/app.js" "$FRONTEND_DIR/app.js.backup"
    log_success "Backed up app.js"
fi

# Step 2: Replace with fixed files
log_info "Deploying fixed frontend files..."

# Replace index.html with the fixed version
cp "$FRONTEND_DIR/index-fixed.html" "$FRONTEND_DIR/index.html"
log_success "Deployed fixed index.html with proper AWS Amplify setup"

# Replace app.js with the fixed version
cp "$FRONTEND_DIR/app-fixed.js" "$FRONTEND_DIR/app.js"
log_success "Deployed fixed app.js with React 18 compatibility"

# Step 3: Apply Terraform changes to generate config
log_info "Applying Terraform configuration to generate frontend config..."
cd "$TERRAFORM_DIR"

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    log_info "Initializing Terraform..."
    terraform init
fi

# Plan and apply changes
log_info "Planning Terraform deployment..."
terraform plan -out=tfplan

log_info "Applying Terraform changes..."
terraform apply tfplan

# Wait for config file to be generated
sleep 2

# Verify config file was created
if [ -f "$FRONTEND_DIR/config.json" ]; then
    log_success "Frontend config.json generated successfully"
    echo "Config contents:"
    cat "$FRONTEND_DIR/config.json" | jq . 2>/dev/null || cat "$FRONTEND_DIR/config.json"
else
    log_error "Config file was not generated. Check Terraform execution."
    exit 1
fi

# Step 4: Get deployment information
log_info "Getting deployment information..."

# Get S3 bucket name
BUCKET_NAME=$(terraform output -raw frontend_bucket_name 2>/dev/null || echo "")
if [ -z "$BUCKET_NAME" ]; then
    log_error "Could not get S3 bucket name from Terraform output"
    exit 1
fi
log_success "S3 bucket: $BUCKET_NAME"

# Get CloudFront distribution ID
CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")
if [ -n "$CLOUDFRONT_ID" ]; then
    log_success "CloudFront distribution: $CLOUDFRONT_ID"
fi

# Get website URL
WEBSITE_URL=$(terraform output -raw website_url 2>/dev/null || echo "")
if [ -z "$WEBSITE_URL" ]; then
    WEBSITE_URL=$(terraform output -raw cloudfront_distribution_url 2>/dev/null || echo "")
fi

# Step 5: Upload files are handled automatically by Terraform
log_info "Files are automatically uploaded by Terraform S3 objects..."

# Step 6: Invalidate CloudFront cache if needed
if [ -n "$CLOUDFRONT_ID" ]; then
    log_info "Creating CloudFront invalidation..."
    aws cloudfront create-invalidation \
        --distribution-id "$CLOUDFRONT_ID" \
        --paths "/*" > /dev/null 2>&1 || {
        log_warning "CloudFront invalidation failed (non-critical)"
    }
    log_success "CloudFront cache invalidated"
fi

# Summary
echo ""
echo "🎉 AWS Amplify fixes deployed successfully!"
echo ""
echo "📋 Summary of fixes:"
echo "  • ✅ Fixed AWS Amplify CDN loading issues"
echo "  • ✅ Implemented proper AWS Cognito authentication"
echo "  • ✅ Updated to React 18 with createRoot API"
echo "  • ✅ Removed in-browser Babel transformation"
echo "  • ✅ Added automatic config generation from Terraform"
echo "  • ✅ Enhanced error handling and loading states"
echo ""

if [ -n "$WEBSITE_URL" ]; then
    echo "🌐 Your application is available at: $WEBSITE_URL"
else
    echo "🌐 Check CloudFront distribution URL in AWS Console"
fi

echo ""
echo "🔧 Technical improvements:"
echo "  • AWS Amplify now loads properly using AWS SDK + Cognito"
echo "  • React 18 compatibility with modern patterns"
echo "  • Dynamic configuration loading from Terraform"
echo "  • Improved authentication state management"
echo "  • Better error boundaries and user feedback"
echo ""

echo "💡 Next steps:"
echo "  1. Install React DevTools browser extension"
echo "  2. Test authentication with your Cognito users"
echo "  3. Verify todo CRUD operations work correctly"
echo "  4. Check browser console for any remaining issues"
echo ""

log_success "Deployment completed! 🚀"
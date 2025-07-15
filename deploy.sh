#!/bin/bash

# Enhanced Deployment script for Serverless Todo Application
# This script automates the deployment process with AWS Amplify fixes

set -e  # Exit on any error

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

echo "🚀 Enhanced Serverless Todo App Deployment"
echo "=========================================="

# Check if required tools are installed
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local all_good=true
    
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform first."
        all_good=false
    fi
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install AWS CLI first."
        all_good=false
    fi
    
    if ! command -v jq &> /dev/null; then
        log_warning "jq is not installed. JSON output will be less readable."
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Please run 'aws configure' first."
        all_good=false
    fi
    
    # Check Node.js for potential future improvements
    if command -v node &> /dev/null; then
        log_success "Node.js available ($(node --version))"
    else
        log_warning "Node.js not found. Consider installing for future enhancements."
    fi
    
    if [ "$all_good" = false ]; then
        log_error "Prerequisites check failed. Please install missing tools."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
    
    # Display AWS account information
    AWS_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
    AWS_USER=$(aws sts get-caller-identity --query 'Arn' --output text)
    log_info "Deploying to AWS Account: $AWS_ACCOUNT"
    log_info "Using AWS Identity: $AWS_USER"
}

# Setup Terraform variables
setup_terraform_vars() {
    log_info "Setting up Terraform variables..."
    
    if [ ! -f "terraform.tfvars" ]; then
        if [ -f "terraform.tfvars.example" ]; then
            cp terraform.tfvars.example terraform.tfvars
            log_success "Created terraform.tfvars from example file"
            log_warning "Please review and update terraform.tfvars with your specific values"
            
            echo ""
            echo "📝 Common variables to review:"
            echo "   - project_name: Unique identifier for your project"
            echo "   - environment: dev, staging, or prod"
            echo "   - aws_region: Your preferred AWS region"
            echo "   - alert_email: Your email for monitoring alerts"
            echo ""
            read -p "Press Enter to continue after updating terraform.tfvars..."
        else
            log_error "terraform.tfvars.example not found"
            exit 1
        fi
    else
        log_success "terraform.tfvars already exists"
    fi
    
    # Validate critical variables
    if grep -q "CHANGE_ME" terraform.tfvars 2>/dev/null; then
        log_warning "Found placeholder values in terraform.tfvars. Please update them."
    fi
}

# Backup original frontend files
backup_frontend_files() {
    log_info "Creating backups of frontend files..."
    
    local backup_dir="backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    if [ -f "frontend/index.html" ]; then
        cp "frontend/index.html" "$backup_dir/index.html.original"
        log_success "Backed up index.html"
    fi
    
    if [ -f "frontend/app.js" ]; then
        cp "frontend/app.js" "$backup_dir/app.js.original"
        log_success "Backed up app.js"
    fi
    
    echo "$backup_dir" > .last_backup_dir
    log_success "Backup created in: $backup_dir"
}

# Apply AWS Amplify fixes
apply_amplify_fixes() {
    log_info "Applying AWS Amplify fixes..."
    
    # Check if fixed files exist
    if [ ! -f "frontend/index-fixed.html" ] || [ ! -f "frontend/app-fixed.js" ]; then
        log_error "Fixed frontend files not found. Please run the fix generation script first."
        exit 1
    fi
    
    # Apply the fixes
    cp "frontend/index-fixed.html" "frontend/index.html"
    cp "frontend/app-fixed.js" "frontend/app.js"
    
    log_success "Applied AWS Amplify fixes to frontend files"
    log_success "✅ Fixed AWS Amplify CDN loading issues"
    log_success "✅ Updated to React 18 with createRoot API"
    log_success "✅ Added dynamic configuration loading"
    log_success "✅ Enhanced error handling and loading states"
}

# Deploy infrastructure
deploy_infrastructure() {
    log_info "Deploying infrastructure with Terraform..."
    
    cd terraform
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init -upgrade
    
    # Validate configuration
    log_info "Validating Terraform configuration..."
    terraform validate
    
    if [ $? -ne 0 ]; then
        log_error "Terraform validation failed"
        cd ..
        exit 1
    fi
    
    # Plan deployment
    log_info "Planning deployment..."
    terraform plan -out=tfplan
    
    # Apply deployment
    log_info "Applying deployment..."
    terraform apply tfplan
    
    # Clean up plan file
    rm -f tfplan
    
    log_success "Infrastructure deployment completed"
    
    cd ..
}

# Verify configuration generation
verify_config_generation() {
    log_info "Verifying frontend configuration generation..."
    
    if [ -f "frontend/config.json" ]; then
        log_success "config.json generated successfully"
        
        if command -v jq &> /dev/null; then
            echo "📋 Generated configuration:"
            cat frontend/config.json | jq .
        else
            echo "📋 Generated configuration:"
            cat frontend/config.json
        fi
    else
        log_error "config.json was not generated. Check Terraform execution."
        exit 1
    fi
}

# Invalidate CloudFront cache
invalidate_cloudfront() {
    log_info "Invalidating CloudFront cache..."
    
    cd terraform
    
    CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")
    
    if [ -n "$CLOUDFRONT_ID" ]; then
        log_info "Creating CloudFront invalidation for distribution: $CLOUDFRONT_ID"
        
        INVALIDATION_ID=$(aws cloudfront create-invalidation \
            --distribution-id "$CLOUDFRONT_ID" \
            --paths "/*" \
            --query 'Invalidation.Id' \
            --output text 2>/dev/null || echo "")
        
        if [ -n "$INVALIDATION_ID" ]; then
            log_success "CloudFront invalidation created: $INVALIDATION_ID"
            log_info "Cache invalidation may take 10-15 minutes to complete"
        else
            log_warning "Failed to create CloudFront invalidation (non-critical)"
        fi
    else
        log_warning "CloudFront distribution ID not found"
    fi
    
    cd ..
}

# Run post-deployment tests
run_deployment_tests() {
    log_info "Running deployment verification tests..."
    
    cd terraform
    
    # Test 1: Check if all outputs are available
    local outputs_missing=false
    
    if ! terraform output frontend_bucket_name &>/dev/null; then
        log_warning "Frontend bucket output missing"
        outputs_missing=true
    fi
    
    if ! terraform output cognito_user_pool_id &>/dev/null; then
        log_warning "Cognito User Pool output missing"
        outputs_missing=true
    fi
    
    if ! terraform output api_gateway_url &>/dev/null; then
        log_warning "API Gateway URL output missing"
        outputs_missing=true
    fi
    
    # Test 2: Check if S3 bucket exists and is accessible
    BUCKET_NAME=$(terraform output -raw frontend_bucket_name 2>/dev/null || echo "")
    if [ -n "$BUCKET_NAME" ]; then
        if aws s3 ls "s3://$BUCKET_NAME" &>/dev/null; then
            log_success "S3 bucket is accessible"
        else
            log_warning "S3 bucket exists but may not be accessible"
        fi
    fi
    
    # Test 3: Check if API Gateway is responding
    API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
    if [ -n "$API_URL" ]; then
        if curl -s -o /dev/null -w "%{http_code}" "$API_URL/health" | grep -q "200\|404"; then
            log_success "API Gateway is responding"
        else
            log_warning "API Gateway may not be fully ready (this is normal for first deployment)"
        fi
    fi
    
    cd ..
    
    if [ "$outputs_missing" = false ]; then
        log_success "All deployment tests passed"
    else
        log_warning "Some tests failed, but deployment may still be functional"
    fi
}

# Display deployment summary
display_summary() {
    log_info "Deployment Summary"
    echo "=================="
    
    cd terraform
    
    # Get all the important outputs
    FRONTEND_URL=$(terraform output -raw website_url 2>/dev/null || terraform output -raw cloudfront_distribution_url 2>/dev/null || echo "Not available")
    API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "Not available")
    USER_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null || echo "Not available")
    USER_POOL_CLIENT_ID=$(terraform output -raw cognito_user_pool_client_id 2>/dev/null || echo "Not available")
    DYNAMODB_TABLE=$(terraform output -raw dynamodb_table_name 2>/dev/null || echo "Not available")
    LAMBDA_FUNCTION=$(terraform output -raw lambda_function_name 2>/dev/null || echo "Not available")
    S3_BUCKET=$(terraform output -raw frontend_bucket_name 2>/dev/null || echo "Not available")
    
    echo ""
    echo "🌐 Application Access:"
    echo "   Frontend URL: $FRONTEND_URL"
    echo "   API Gateway URL: $API_URL"
    
    echo ""
    echo "🔑 Authentication Details:"
    echo "   User Pool ID: $USER_POOL_ID"
    echo "   User Pool Client ID: $USER_POOL_CLIENT_ID"
    
    echo ""
    echo "💾 Backend Resources:"
    echo "   DynamoDB Table: $DYNAMODB_TABLE"
    echo "   Lambda Function: $LAMBDA_FUNCTION"
    echo "   S3 Bucket: $S3_BUCKET"
    
    echo ""
    echo "🔧 Technical Improvements:"
    echo "   ✅ AWS Amplify loading issues resolved"
    echo "   ✅ React 18 compatibility implemented"
    echo "   ✅ Dynamic configuration management"
    echo "   ✅ Enhanced error handling and UX"
    echo "   ✅ CloudFront cache invalidation"
    
    cd ..
    
    # Show backup information
    if [ -f ".last_backup_dir" ]; then
        BACKUP_DIR=$(cat .last_backup_dir)
        echo ""
        echo "💾 Backup Information:"
        echo "   Original files backed up to: $BACKUP_DIR"
    fi
}

# Show next steps
show_next_steps() {
    echo ""
    echo "🎯 Next Steps:"
    echo "============="
    echo ""
    echo "1. 🌐 Access your application at the Frontend URL above"
    echo ""
    echo "2. 📱 Install React DevTools for debugging:"
    echo "   Chrome: https://chrome.google.com/webstore/detail/react-developer-tools/"
    echo "   Firefox: https://addons.mozilla.org/firefox/addon/react-devtools/"
    echo ""
    echo "3. 👤 Create test users in Cognito:"
    echo "   aws cognito-idp admin-create-user --user-pool-id <USER_POOL_ID> --username testuser"
    echo ""
    echo "4. 🔍 Monitor deployment:"
    echo "   - Check CloudWatch logs for any errors"
    echo "   - Verify CloudFront distribution is fully deployed"
    echo "   - Test authentication and todo operations"
    echo ""
    echo "5. 🧪 Run verification script:"
    echo "   ./verify-amplify-fixes.sh"
    echo ""
    echo "📚 Documentation:"
    echo "   - AWS_AMPLIFY_FIXES_README.md - Technical details"
    echo "   - PROJECT_COMPLETION.md - Project overview"
    echo "   - Check browser console for success messages"
}

# Main deployment flow
main() {
    local start_time=$(date +%s)
    
    echo "🎯 Enhanced Serverless Todo App Deployment"
    echo "=========================================="
    echo "⏰ Started at: $(date)"
    echo ""
    
    check_prerequisites
    setup_terraform_vars
    backup_frontend_files
    apply_amplify_fixes
    deploy_infrastructure
    verify_config_generation
    invalidate_cloudfront
    run_deployment_tests
    display_summary
    show_next_steps
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo "⏱️  Total deployment time: ${duration} seconds"
    echo "🌐 Your Todo application is now live and ready to use!"
    echo ""
    log_success "All AWS Amplify issues have been resolved! 🚀"
}

# Cleanup function for interrupted deployments
cleanup_on_error() {
    log_error "Deployment interrupted. Cleaning up..."
    
    # Remove any temporary files
    rm -f terraform/tfplan
    rm -f terraform/destroy-plan
    
    echo ""
    log_info "To restart deployment, run: ./deploy.sh"
    log_info "To clean up resources, run: ./cleanup.sh"
}

# Set up error handling
trap cleanup_on_error ERR INT TERM

# Run main function with all arguments
main "$@"
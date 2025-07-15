#!/bin/bash

# Enhanced Cleanup script for Serverless Todo Application
# This script destroys all AWS resources and cleans up local files

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

echo "🧹 Enhanced Serverless Todo App Cleanup Script"
echo "=============================================="

# Warning message
show_warning() {
    echo ""
    log_warning "DESTRUCTIVE OPERATION WARNING!"
    echo "================================================"
    echo ""
    echo "🔥 This script will destroy ALL AWS resources created for this project!"
    echo ""
    echo "📋 Resources to be deleted:"
    echo "   🗄️  DynamoDB table (and ALL todo data)"
    echo "   ⚡ Lambda function and execution role"
    echo "   🌐 API Gateway and deployment"
    echo "   👤 Cognito User Pool (and ALL users)"
    echo "   ☁️  CloudFront distribution"
    echo "   📦 S3 bucket (and ALL files)"
    echo "   🔐 IAM roles and policies"
    echo "   📊 CloudWatch log groups"
    echo "   💰 Budget alerts and monitoring"
    echo ""
    echo "💾 ALL DATA WILL BE PERMANENTLY DELETED!"
    echo "📊 This action CANNOT be undone!"
    echo ""
    
    # Show estimated cost savings
    log_info "💰 Cost impact: This will stop all ongoing AWS charges for this project"
    echo ""
}

# Confirm destruction
confirm_destruction() {
    echo "🤔 Confirmation Process"
    echo "======================"
    echo ""
    
    read -p "❓ Do you understand that ALL data will be permanently deleted? (type 'yes' to confirm): " confirmation
    
    if [ "$confirmation" != "yes" ]; then
        log_info "Cleanup cancelled by user"
        exit 0
    fi
    
    echo ""
    log_warning "FINAL WARNING: This is your last chance to cancel!"
    echo ""
    read -p "❓ Type 'DESTROY' in capital letters to proceed with deletion: " final_confirmation
    
    if [ "$final_confirmation" != "DESTROY" ]; then
        log_info "Cleanup cancelled by user"
        exit 0
    fi
    
    echo ""
    log_info "Proceeding with cleanup in 5 seconds... (Ctrl+C to cancel)"
    sleep 5
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local all_good=true
    
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed"
        all_good=false
    fi
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        all_good=false
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured"
        all_good=false
    fi
    
    # Check if terraform directory exists
    if [ ! -d "terraform" ]; then
        log_error "Terraform directory not found"
        all_good=false
    fi
    
    if [ "$all_good" = false ]; then
        log_error "Prerequisites check failed"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
    
    # Display AWS account information
    AWS_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
    AWS_USER=$(aws sts get-caller-identity --query 'Arn' --output text)
    log_info "Cleaning up from AWS Account: $AWS_ACCOUNT"
    log_info "Using AWS Identity: $AWS_USER"
}

# Show current resources
show_current_resources() {
    log_info "Analyzing current AWS resources..."
    echo "================================"
    
    cd terraform
    
    if [ ! -f "terraform.tfstate" ]; then
        log_warning "No Terraform state found!"
        echo ""
        echo "This could mean:"
        echo "  1. Resources were never created"
        echo "  2. State file was deleted"
        echo "  3. Resources were created manually"
        echo ""
        echo "If resources exist, they may need manual deletion from AWS Console."
        
        read -p "❓ Continue anyway to clean up local files? (y/n): " continue_cleanup
        if [ "$continue_cleanup" != "y" ] && [ "$continue_cleanup" != "Y" ]; then
            log_info "Cleanup cancelled"
            cd ..
            exit 0
        fi
        cd ..
        return
    fi
    
    # Show Terraform state
    log_info "Resources managed by Terraform:"
    terraform state list | while read resource; do
        echo "   🔹 $resource"
    done
    
    echo ""
    log_info "Resource details (first 30 lines):"
    terraform show -no-color | head -30
    if [ $(terraform show -no-color | wc -l) -gt 30 ]; then
        echo "   ... (truncated, see full output with 'terraform show')"
    fi
    
    # Show key outputs if available
    echo ""
    log_info "Key resource identifiers:"
    
    BUCKET_NAME=$(terraform output -raw frontend_bucket_name 2>/dev/null || echo "Not found")
    CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "Not found")
    USER_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null || echo "Not found")
    API_ID=$(terraform output -raw api_gateway_id 2>/dev/null || echo "Not found")
    
    echo "   📦 S3 Bucket: $BUCKET_NAME"
    echo "   ☁️  CloudFront: $CLOUDFRONT_ID"
    echo "   👤 User Pool: $USER_POOL_ID"
    echo "   🌐 API Gateway: $API_ID"
    
    cd ..
    
    echo ""
    read -p "❓ Proceed with destroying these resources? (y/n): " proceed
    if [ "$proceed" != "y" ] && [ "$proceed" != "Y" ]; then
        log_info "Cleanup cancelled"
        exit 0
    fi
}

# Handle S3 bucket cleanup (buckets with objects)
cleanup_s3_buckets() {
    log_info "Cleaning up S3 buckets with contents..."
    
    cd terraform
    
    BUCKET_NAME=$(terraform output -raw frontend_bucket_name 2>/dev/null || echo "")
    
    if [ -n "$BUCKET_NAME" ] && [ "$BUCKET_NAME" != "Not found" ]; then
        log_info "Emptying S3 bucket: $BUCKET_NAME"
        
        # Check if bucket exists
        if aws s3 ls "s3://$BUCKET_NAME" &>/dev/null; then
            # Delete all objects including versions
            aws s3 rm "s3://$BUCKET_NAME" --recursive --quiet || log_warning "Some S3 objects may remain"
            
            # Delete any versioned objects
            aws s3api delete-objects --bucket "$BUCKET_NAME" \
                --delete "$(aws s3api list-object-versions \
                --bucket "$BUCKET_NAME" \
                --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
                --output json)" &>/dev/null || true
            
            log_success "S3 bucket emptied successfully"
        else
            log_info "S3 bucket doesn't exist or not accessible"
        fi
    fi
    
    cd ..
}

# Disable CloudFront distribution (for faster deletion)
disable_cloudfront() {
    log_info "Disabling CloudFront distribution for faster cleanup..."
    
    cd terraform
    
    CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")
    
    if [ -n "$CLOUDFRONT_ID" ] && [ "$CLOUDFRONT_ID" != "Not found" ]; then
        log_info "Disabling CloudFront distribution: $CLOUDFRONT_ID"
        
        # Get current distribution config
        aws cloudfront get-distribution-config --id "$CLOUDFRONT_ID" \
            --query 'DistributionConfig' --output json > /tmp/cf-config.json 2>/dev/null || {
            log_warning "Could not retrieve CloudFront config"
            cd ..
            return
        }
        
        # Disable the distribution
        ETAG=$(aws cloudfront get-distribution-config --id "$CLOUDFRONT_ID" \
            --query 'ETag' --output text 2>/dev/null || echo "")
        
        if [ -n "$ETAG" ]; then
            # Modify config to disable
            jq '.Enabled = false' /tmp/cf-config.json > /tmp/cf-config-disabled.json
            
            aws cloudfront update-distribution \
                --id "$CLOUDFRONT_ID" \
                --distribution-config file:///tmp/cf-config-disabled.json \
                --if-match "$ETAG" &>/dev/null || log_warning "Could not disable CloudFront"
            
            rm -f /tmp/cf-config.json /tmp/cf-config-disabled.json
            log_success "CloudFront distribution disabled"
        fi
    fi
    
    cd ..
}

# Destroy infrastructure
destroy_infrastructure() {
    log_info "Destroying infrastructure with Terraform..."
    
    cd terraform
    
    # Plan destruction
    log_info "Planning destruction..."
    terraform plan -destroy -out=destroy-plan
    
    if [ $? -ne 0 ]; then
        log_error "Terraform destroy plan failed"
        cd ..
        exit 1
    fi
    
    # Apply destruction
    log_info "Executing destruction plan..."
    terraform apply destroy-plan
    
    if [ $? -eq 0 ]; then
        log_success "Infrastructure destroyed successfully"
    else
        log_warning "Some resources may not have been destroyed. Check AWS Console."
    fi
    
    # Clean up plan file
    rm -f destroy-plan
    
    cd ..
}

# Clean up local files
cleanup_local_files() {
    log_info "Cleaning up local files..."
    
    # Ask user about local file cleanup
    echo ""
    echo "🧹 Local File Cleanup Options:"
    echo "============================="
    echo ""
    echo "What would you like to clean up?"
    echo "1. Terraform state and cache files"
    echo "2. Generated frontend config.json"
    echo "3. Backup files from deployments"
    echo "4. All of the above"
    echo "5. Keep all local files"
    echo ""
    read -p "❓ Choose option (1-5): " cleanup_option
    
    case $cleanup_option in
        1|4)
            log_info "Cleaning up Terraform files..."
            cd terraform
            
            # Remove Terraform files
            rm -f terraform.tfstate*
            rm -f terraform.tfplan
            rm -f destroy-plan
            rm -f lambda_function.zip
            rm -f *_lambda_function.zip
            rm -rf .terraform/
            rm -f .terraform.lock.hcl
            
            cd ..
            log_success "Terraform files cleaned up"
            ;;
    esac
    
    case $cleanup_option in
        2|4)
            log_info "Cleaning up generated configuration..."
            
            # Remove generated config file
            if [ -f "frontend/config.json" ]; then
                rm -f "frontend/config.json"
                log_success "config.json removed"
            fi
            ;;
    esac
    
    case $cleanup_option in
        3|4)
            log_info "Cleaning up backup files..."
            
            # Remove backup directories
            find . -maxdepth 1 -name "backup_*" -type d -exec rm -rf {} + 2>/dev/null || true
            rm -f .last_backup_dir
            
            # Remove .backup files
            find frontend/ -name "*.backup" -delete 2>/dev/null || true
            find frontend/ -name "*.bak" -delete 2>/dev/null || true
            
            log_success "Backup files cleaned up"
            ;;
    esac
    
    case $cleanup_option in
        5)
            log_info "Local files preserved"
            ;;
    esac
    
    # Ask about restoring original frontend files
    if [ -f "frontend/index-fixed.html" ] && [ -f "frontend/app-fixed.js" ]; then
        echo ""
        read -p "❓ Restore original frontend files (remove AWS Amplify fixes)? (y/n): " restore_original
        
        if [ "$restore_original" = "y" ] || [ "$restore_original" = "Y" ]; then
            # Look for backup files
            BACKUP_DIR=""
            if [ -f ".last_backup_dir" ]; then
                BACKUP_DIR=$(cat .last_backup_dir)
            fi
            
            if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
                if [ -f "$BACKUP_DIR/index.html.original" ]; then
                    cp "$BACKUP_DIR/index.html.original" "frontend/index.html"
                    log_success "Restored original index.html"
                fi
                
                if [ -f "$BACKUP_DIR/app.js.original" ]; then
                    cp "$BACKUP_DIR/app.js.original" "frontend/app.js"
                    log_success "Restored original app.js"
                fi
            else
                log_warning "No backup files found. Cannot restore originals."
            fi
        fi
    fi
}

# Verify cleanup completion
verify_cleanup() {
    log_info "Verifying cleanup completion..."
    echo "==============================="
    
    # Check AWS resources
    log_info "Checking for remaining AWS resources..."
    
    local cleanup_complete=true
    
    # Check common resource types
    echo ""
    echo "🔍 Resource verification:"
    
    # DynamoDB tables
    DYNAMO_TABLES=$(aws dynamodb list-tables --query 'TableNames[?contains(@, `todo`)]' --output text 2>/dev/null || echo "")
    if [ -n "$DYNAMO_TABLES" ]; then
        echo "   ⚠️  DynamoDB tables found: $DYNAMO_TABLES"
        cleanup_complete=false
    else
        echo "   ✅ No DynamoDB tables found"
    fi
    
    # Lambda functions
    LAMBDA_FUNCTIONS=$(aws lambda list-functions --query 'Functions[?contains(FunctionName, `todo`)].FunctionName' --output text 2>/dev/null || echo "")
    if [ -n "$LAMBDA_FUNCTIONS" ]; then
        echo "   ⚠️  Lambda functions found: $LAMBDA_FUNCTIONS"
        cleanup_complete=false
    else
        echo "   ✅ No Lambda functions found"
    fi
    
    # API Gateways
    API_GATEWAYS=$(aws apigateway get-rest-apis --query 'items[?contains(name, `todo`)].name' --output text 2>/dev/null || echo "")
    if [ -n "$API_GATEWAYS" ]; then
        echo "   ⚠️  API Gateways found: $API_GATEWAYS"
        cleanup_complete=false
    else
        echo "   ✅ No API Gateways found"
    fi
    
    # Cognito User Pools
    USER_POOLS=$(aws cognito-idp list-user-pools --max-items 10 --query 'UserPools[?contains(Name, `todo`)].Name' --output text 2>/dev/null || echo "")
    if [ -n "$USER_POOLS" ]; then
        echo "   ⚠️  Cognito User Pools found: $USER_POOLS"
        cleanup_complete=false
    else
        echo "   ✅ No Cognito User Pools found"
    fi
    
    echo ""
    
    if [ "$cleanup_complete" = true ]; then
        log_success "All AWS resources appear to be cleaned up"
    else
        log_warning "Some resources may still exist. Please check AWS Console manually."
        echo ""
        echo "🔗 Manual cleanup links:"
        echo "   DynamoDB: https://console.aws.amazon.com/dynamodb/home#tables:"
        echo "   Lambda: https://console.aws.amazon.com/lambda/home#/functions"
        echo "   API Gateway: https://console.aws.amazon.com/apigateway/home#/apis"
        echo "   Cognito: https://console.aws.amazon.com/cognito/users/"
        echo "   S3: https://console.aws.amazon.com/s3/"
        echo "   CloudFront: https://console.aws.amazon.com/cloudfront/home"
    fi
    
    # Cost monitoring reminder
    echo ""
    log_info "💰 Cost monitoring recommendations:"
    echo "   - Check AWS Cost Explorer to verify no ongoing charges"
    echo "   - Review AWS Billing dashboard"
    echo "   - Set up billing alerts for future projects"
    echo "   - Monitor for any unexpected charges over the next few days"
}

# Show cleanup summary
show_cleanup_summary() {
    echo ""
    echo "📊 Cleanup Summary"
    echo "=================="
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    echo "⏱️  Cleanup completed in: ${duration} seconds"
    echo "🗑️  Resources destroyed: All Terraform-managed resources"
    echo "🧹 Local files: Cleaned according to user selection"
    echo ""
    echo "✅ Cleanup operations completed!"
    echo ""
    echo "🔍 Next steps:"
    echo "   1. Verify AWS Console shows no remaining resources"
    echo "   2. Check AWS billing to confirm charges have stopped"
    echo "   3. Remove any custom DNS records if configured"
    echo "   4. Clean up any external integrations"
    echo ""
    echo "💡 To redeploy the application:"
    echo "   ./deploy.sh"
    echo ""
    log_success "Thank you for using the Serverless Todo Application! 👋"
}

# Main cleanup flow
main() {
    local start_time=$(date +%s)
    
    echo "⏰ Started at: $(date)"
    echo ""
    
    show_warning
    confirm_destruction
    check_prerequisites
    show_current_resources
    
    echo ""
    log_info "🚀 Starting cleanup process..."
    
    cleanup_s3_buckets
    disable_cloudfront
    destroy_infrastructure
    cleanup_local_files
    verify_cleanup
    show_cleanup_summary
    
    echo ""
    log_success "🎉 Cleanup completed successfully!"
}

# Cleanup function for interrupted operations
cleanup_on_error() {
    log_error "Cleanup interrupted. Some resources may still exist."
    
    # Remove any temporary files
    rm -f terraform/destroy-plan
    rm -f /tmp/cf-config*.json
    
    echo ""
    log_info "To continue cleanup, run: ./cleanup.sh"
    log_info "To check remaining resources, visit AWS Console"
}

# Set up error handling
trap cleanup_on_error ERR INT TERM

# Run main function
main "$@"
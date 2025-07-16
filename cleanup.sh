#!/bin/bash

# Enhanced Cleanup Script for TaskFlow - Flowless Todo App
# This script destroys all AWS resources and cleans up local files

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

log_step() {
    echo -e "${PURPLE}🧹 $1${NC}"
}

echo ""
echo "🧹 TaskFlow - Flowless Todo App Cleanup"
echo "======================================="
echo "🔥 This will destroy ALL AWS resources and clean up local files"
echo ""

# Warning and confirmation
show_destruction_warning() {
    echo ""
    log_warning "⚠️  DESTRUCTIVE OPERATION WARNING! ⚠️"
    echo "====================================="
    echo ""
    echo "🔥 This script will permanently delete:"
    echo ""
    echo "☁️  AWS Resources:"
    echo "   🗄️  DynamoDB table (ALL todo data will be lost)"
    echo "   ⚡ Lambda functions and execution roles"
    echo "   🌐 API Gateway and all endpoints"
    echo "   👤 Cognito User Pool (ALL user accounts will be deleted)"
    echo "   ☁️  CloudFront distribution"
    echo "   📦 S3 bucket and ALL uploaded files"
    echo "   🔐 IAM roles and policies"
    echo "   📊 CloudWatch log groups"
    echo "   💰 Budget alerts and monitoring resources"
    echo ""
    echo "📁 Local Files (optional):"
    echo "   🏗️  Terraform state files"
    echo "   ⚙️  Generated configuration files"
    echo "   💾 Backup directories"
    echo ""
    echo "💰 Cost Impact: This will stop ALL ongoing AWS charges"
    echo "🚨 THIS ACTION CANNOT BE UNDONE!"
    echo ""
}

# Comprehensive confirmation process
confirm_destruction() {
    echo "🤔 Confirmation Process"
    echo "======================"
    echo ""
    
    # First confirmation
    read -p "❓ Do you understand that ALL data will be permanently deleted? (type 'yes'): " first_confirmation
    
    if [ "$first_confirmation" != "yes" ]; then
        log_info "Cleanup cancelled by user"
        exit 0
    fi
    
    # Show what will be preserved
    echo ""
    log_info "📋 What will be preserved:"
    echo "   ✅ Source code files (app-unified.js, index-unified.html, etc.)"
    echo "   ✅ Terraform configuration files"
    echo "   ✅ This cleanup script and deploy script"
    echo "   ✅ Documentation and README files"
    echo ""
    
    # Final confirmation
    log_warning "🔴 FINAL WARNING: Last chance to cancel!"
    echo ""
    read -p "❓ Type 'DESTROY' in capital letters to proceed: " final_confirmation
    
    if [ "$final_confirmation" != "DESTROY" ]; then
        log_info "Cleanup cancelled - smart choice to double-check! 👍"
        exit 0
    fi
    
    echo ""
    log_warning "⏳ Proceeding with cleanup in 3 seconds... (Ctrl+C to abort)"
    sleep 1
    echo "⏳ 2..."
    sleep 1
    echo "⏳ 1..."
    sleep 1
    echo "🚀 Starting cleanup process..."
    echo ""
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    local all_good=true
    
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform not found - cannot cleanup infrastructure"
        all_good=false
    fi
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI not found - cannot cleanup AWS resources"
        all_good=false
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured"
        all_good=false
    fi
    
    # Check if terraform directory exists
    if [ ! -d "terraform" ]; then
        log_warning "Terraform directory not found - may have been cleaned already"
    fi
    
    if [ "$all_good" = false ]; then
        log_error "Prerequisites check failed"
        echo ""
        echo "💡 Possible solutions:"
        echo "   • Install missing tools (terraform, aws cli)"
        echo "   • Configure AWS credentials: aws configure"
        echo "   • Run from correct directory (project root)"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
    
    # Display current AWS context
    AWS_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
    AWS_USER=$(aws sts get-caller-identity --query 'Arn' --output text)
    AWS_REGION=$(aws configure get region || echo "us-west-2")
    
    log_info "🔐 AWS Account: $AWS_ACCOUNT"
    log_info "👤 AWS Identity: $AWS_USER"
    log_info "🌍 AWS Region: $AWS_REGION"
    echo ""
}

# Analyze current resources
analyze_current_resources() {
    log_step "Analyzing current AWS resources..."
    
    cd terraform
    
    if [ ! -f "terraform.tfstate" ]; then
        log_warning "❌ No Terraform state found!"
        echo ""
        echo "This could mean:"
        echo "  1. ✅ Resources were never deployed"
        echo "  2. 🗑️  Resources were already cleaned up"
        echo "  3. 📁 State file was moved or deleted"
        echo "  4. 🏗️  Resources were created manually outside Terraform"
        echo ""
        echo "If AWS resources exist but state is missing, they need manual cleanup."
        
        read -p "❓ Continue anyway to clean up local files? (y/n): " continue_cleanup
        if [ "$continue_cleanup" != "y" ] && [ "$continue_cleanup" != "Y" ]; then
            log_info "Cleanup cancelled"
            cd ..
            exit 0
        fi
        cd ..
        return
    fi
    
    # Show current Terraform-managed resources
    log_info "📋 Current Terraform-managed resources:"
    local resource_count=0
    
    if terraform state list &>/dev/null; then
        terraform state list | while read resource; do
            echo "   🔹 $resource"
        done
        resource_count=$(terraform state list | wc -l)
    fi
    
    echo ""
    log_info "📊 Total managed resources: $resource_count"
    
    # Show key resource details
    if [ $resource_count -gt 0 ]; then
        echo ""
        log_info "🔍 Key resource identifiers:"
        
        BUCKET_NAME=$(terraform output -raw frontend_bucket_name 2>/dev/null || echo "❌ Not found")
        CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "❌ Not found")
        USER_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null || echo "❌ Not found")
        API_ID=$(terraform output -raw api_gateway_id 2>/dev/null || echo "❌ Not found")
        LAMBDA_NAME=$(terraform output -raw lambda_function_name 2>/dev/null || echo "❌ Not found")
        DYNAMODB_TABLE=$(terraform output -raw dynamodb_table_name 2>/dev/null || echo "❌ Not found")
        
        echo "   📦 S3 Bucket: $BUCKET_NAME"
        echo "   ☁️  CloudFront: $CLOUDFRONT_ID"
        echo "   👤 User Pool: $USER_POOL_ID"
        echo "   🌐 API Gateway: $API_ID"
        echo "   ⚡ Lambda Function: $LAMBDA_NAME"
        echo "   🗄️  DynamoDB Table: $DYNAMODB_TABLE"
    fi
    
    cd ..
    
    echo ""
    read -p "❓ Proceed with destroying these resources? (y/n): " proceed
    if [ "$proceed" != "y" ] && [ "$proceed" != "Y" ]; then
        log_info "Cleanup cancelled"
        exit 0
    fi
}

# Enhanced S3 cleanup
cleanup_s3_buckets() {
    log_step "Cleaning up S3 buckets..."
    
    cd terraform
    
    BUCKET_NAME=$(terraform output -raw frontend_bucket_name 2>/dev/null || echo "")
    
    if [ -n "$BUCKET_NAME" ] && [ "$BUCKET_NAME" != "❌ Not found" ]; then
        log_info "🗑️  Emptying S3 bucket: $BUCKET_NAME"
        
        if aws s3 ls "s3://$BUCKET_NAME" &>/dev/null; then
            # Delete all objects and versions
            log_info "Deleting all objects..."
            aws s3 rm "s3://$BUCKET_NAME" --recursive --quiet || log_warning "Some objects may remain"
            
            # Delete any object versions (for versioned buckets)
            log_info "Checking for versioned objects..."
            aws s3api list-object-versions --bucket "$BUCKET_NAME" --query 'Versions[].{Key:Key,VersionId:VersionId}' --output json > /tmp/versions.json 2>/dev/null || true
            
            if [ -s /tmp/versions.json ] && [ "$(cat /tmp/versions.json)" != "null" ]; then
                aws s3api delete-objects --bucket "$BUCKET_NAME" --delete file:///tmp/versions.json &>/dev/null || true
                log_info "Deleted versioned objects"
            fi
            
            # Clean up delete markers
            aws s3api list-object-versions --bucket "$BUCKET_NAME" --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output json > /tmp/delete-markers.json 2>/dev/null || true
            
            if [ -s /tmp/delete-markers.json ] && [ "$(cat /tmp/delete-markers.json)" != "null" ]; then
                aws s3api delete-objects --bucket "$BUCKET_NAME" --delete file:///tmp/delete-markers.json &>/dev/null || true
                log_info "Deleted delete markers"
            fi
            
            # Cleanup temp files
            rm -f /tmp/versions.json /tmp/delete-markers.json
            
            log_success "S3 bucket emptied successfully"
        else
            log_info "S3 bucket doesn't exist or not accessible"
        fi
    else
        log_info "No S3 bucket found to clean up"
    fi
    
    cd ..
}

# Disable CloudFront for faster deletion
disable_cloudfront() {
    log_step "Disabling CloudFront distribution..."
    
    cd terraform
    
    CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")
    
    if [ -n "$CLOUDFRONT_ID" ] && [ "$CLOUDFRONT_ID" != "❌ Not found" ]; then
        log_info "🌐 Processing CloudFront distribution: $CLOUDFRONT_ID"
        
        # Check if distribution exists and get its status
        DIST_STATUS=$(aws cloudfront get-distribution --id "$CLOUDFRONT_ID" --query 'Distribution.Status' --output text 2>/dev/null || echo "NotFound")
        
        if [ "$DIST_STATUS" = "NotFound" ]; then
            log_info "CloudFront distribution not found (may be already deleted)"
        elif [ "$DIST_STATUS" = "Deployed" ]; then
            log_info "Disabling CloudFront distribution for faster deletion..."
            
            # Get distribution config and ETag
            aws cloudfront get-distribution-config --id "$CLOUDFRONT_ID" > /tmp/cf-config.json 2>/dev/null || {
                log_warning "Could not retrieve CloudFront config"
                cd ..
                return
            }
            
            ETAG=$(jq -r '.ETag' /tmp/cf-config.json)
            
            # Disable the distribution
            jq '.DistributionConfig.Enabled = false' /tmp/cf-config.json | jq '.DistributionConfig' > /tmp/cf-config-disabled.json
            
            aws cloudfront update-distribution \
                --id "$CLOUDFRONT_ID" \
                --distribution-config file:///tmp/cf-config-disabled.json \
                --if-match "$ETAG" &>/dev/null && {
                log_success "CloudFront distribution disabled"
            } || {
                log_warning "Could not disable CloudFront (may affect deletion time)"
            }
            
            rm -f /tmp/cf-config.json /tmp/cf-config-disabled.json
        else
            log_info "CloudFront distribution status: $DIST_STATUS"
        fi
    else
        log_info "No CloudFront distribution found"
    fi
    
    cd ..
}

# Destroy infrastructure with Terraform
destroy_infrastructure() {
    log_step "Destroying infrastructure with Terraform..."
    
    cd terraform
    
    # Check if there's anything to destroy
    if [ ! -f "terraform.tfstate" ] || [ ! -s "terraform.tfstate" ]; then
        log_warning "No Terraform state found - nothing to destroy"
        cd ..
        return
    fi
    
    # Plan destruction
    log_info "📋 Planning destruction..."
    if terraform plan -destroy -out=destroy-plan; then
        log_success "Destruction plan created"
    else
        log_warning "Terraform plan failed, attempting force destroy"
    fi
    
    # Execute destruction
    log_info "🔥 Executing destruction..."
    if [ -f "destroy-plan" ]; then
        if terraform apply destroy-plan; then
            log_success "Infrastructure destroyed successfully"
        else
            log_warning "Terraform destroy had some issues - checking for remaining resources"
        fi
    else
        # Fallback: direct destroy
        log_info "Attempting direct destroy..."
        terraform destroy -auto-approve || log_warning "Some resources may not have been destroyed"
    fi
    
    # Clean up plan files
    rm -f destroy-plan
    
    cd ..
}

# Clean up local files
cleanup_local_files() {
    log_step "Cleaning up local files..."
    
    echo ""
    echo "🧹 Local File Cleanup Options:"
    echo "=============================="
    echo ""
    echo "What would you like to clean up?"
    echo "1. 🏗️  Terraform state and cache files only"
    echo "2. ⚙️  Generated configuration files only" 
    echo "3. 💾 Backup directories only"
    echo "4. 🗑️  All generated files (state + config + backups)"
    echo "5. 📁 Keep all local files (recommended)"
    echo ""
    read -p "❓ Choose option (1-5): " cleanup_option
    
    case $cleanup_option in
        1|4)
            log_info "🧹 Cleaning Terraform files..."
            cd terraform
            
            # Remove Terraform state and cache
            rm -f terraform.tfstate*
            rm -f terraform.tfplan
            rm -f destroy-plan
            rm -f lambda_function.zip
            rm -f *_lambda_function.zip
            rm -rf .terraform/
            rm -f .terraform.lock.hcl
            
            cd ..
            log_success "Terraform files cleaned"
            ;;
    esac
    
    case $cleanup_option in
        2|4)
            log_info "🧹 Cleaning generated configuration..."
            
            # Remove generated config
            if [ -f "frontend/config.json" ]; then
                rm -f "frontend/config.json"
                log_success "config.json removed"
            fi
            
            # Reset to unified files if they were applied
            if [ -f "frontend/app-unified.js" ] && [ -f "frontend/index-unified.html" ]; then
                log_info "Resetting to unified authentication files..."
                cp "frontend/app-unified.js" "frontend/app.js"
                cp "frontend/index-unified.html" "frontend/index.html"
                log_success "Reset to unified files"
            fi
            ;;
    esac
    
    case $cleanup_option in
        3|4)
            log_info "🧹 Cleaning backup files..."
            
            # Remove backup directories
            find . -maxdepth 1 -name "backup_*" -type d | while read backup_dir; do
                if [ -d "$backup_dir" ]; then
                    rm -rf "$backup_dir"
                    log_info "Removed backup: $backup_dir"
                fi
            done
            
            rm -f .last_backup_dir
            
            # Remove misc backup files
            find . -name "*.backup" -delete 2>/dev/null || true
            find . -name "*.bak" -delete 2>/dev/null || true
            
            log_success "Backup files cleaned"
            ;;
    esac
    
    case $cleanup_option in
        5)
            log_info "📁 Local files preserved (good choice for redeployment)"
            ;;
    esac
}

# Verify cleanup completion
verify_cleanup() {
    log_step "Verifying cleanup completion..."
    
    echo ""
    log_info "🔍 Checking for remaining AWS resources..."
    
    local cleanup_complete=true
    local found_resources=""
    
    # Check various AWS resource types
    echo ""
    echo "📊 Resource verification:"
    
    # DynamoDB tables
    if command -v aws &> /dev/null; then
        DYNAMO_TABLES=$(aws dynamodb list-tables --query 'TableNames[?contains(@, `todo`) || contains(@, `task`)]' --output text 2>/dev/null || echo "")
        if [ -n "$DYNAMO_TABLES" ]; then
            echo "   ⚠️  DynamoDB tables: $DYNAMO_TABLES"
            cleanup_complete=false
            found_resources="$found_resources DynamoDB"
        else
            echo "   ✅ DynamoDB: No tables found"
        fi
        
        # Lambda functions
        LAMBDA_FUNCTIONS=$(aws lambda list-functions --query 'Functions[?contains(FunctionName, `todo`) || contains(FunctionName, `task`)].FunctionName' --output text 2>/dev/null || echo "")
        if [ -n "$LAMBDA_FUNCTIONS" ]; then
            echo "   ⚠️  Lambda functions: $LAMBDA_FUNCTIONS"
            cleanup_complete=false
            found_resources="$found_resources Lambda"
        else
            echo "   ✅ Lambda: No functions found"
        fi
        
        # API Gateways
        API_GATEWAYS=$(aws apigateway get-rest-apis --query 'items[?contains(name, `todo`) || contains(name, `task`)].name' --output text 2>/dev/null || echo "")
        if [ -n "$API_GATEWAYS" ]; then
            echo "   ⚠️  API Gateways: $API_GATEWAYS"
            cleanup_complete=false
            found_resources="$found_resources API-Gateway"
        else
            echo "   ✅ API Gateway: No APIs found"
        fi
        
        # Cognito User Pools
        USER_POOLS=$(aws cognito-idp list-user-pools --max-items 10 --query 'UserPools[?contains(Name, `todo`) || contains(Name, `task`) || contains(Name, `TaskFlow`)].Name' --output text 2>/dev/null || echo "")
        if [ -n "$USER_POOLS" ]; then
            echo "   ⚠️  Cognito User Pools: $USER_POOLS"
            cleanup_complete=false
            found_resources="$found_resources Cognito"
        else
            echo "   ✅ Cognito: No user pools found"
        fi
        
        # S3 Buckets
        S3_BUCKETS=$(aws s3api list-buckets --query 'Buckets[?contains(Name, `todo`) || contains(Name, `task`) || contains(Name, `frontend`)].Name' --output text 2>/dev/null || echo "")
        if [ -n "$S3_BUCKETS" ]; then
            echo "   ⚠️  S3 Buckets: $S3_BUCKETS"
            cleanup_complete=false
            found_resources="$found_resources S3"
        else
            echo "   ✅ S3: No buckets found"
        fi
        
        # CloudFront Distributions  
        CF_DISTRIBUTIONS=$(aws cloudfront list-distributions --query 'DistributionList.Items[?contains(Comment, `todo`) || contains(Comment, `task`)].Id' --output text 2>/dev/null || echo "")
        if [ -n "$CF_DISTRIBUTIONS" ]; then
            echo "   ⚠️  CloudFront: $CF_DISTRIBUTIONS"
            cleanup_complete=false
            found_resources="$found_resources CloudFront"
        else
            echo "   ✅ CloudFront: No distributions found"
        fi
    fi
    
    echo ""
    
    if [ "$cleanup_complete" = true ]; then
        log_success "🎉 All AWS resources have been cleaned up!"
        echo ""
        echo "💰 Cost Impact:"
        echo "   ✅ No ongoing AWS charges for this project"
        echo "   ✅ All billable resources have been destroyed"
        echo ""
    else
        log_warning "⚠️  Some resources may still exist"
        echo ""
        echo "🔗 Manual cleanup may be needed for: $found_resources"
        echo ""
        echo "📋 AWS Console links for manual cleanup:"
        echo "   🗄️  DynamoDB: https://console.aws.amazon.com/dynamodb/home#tables:"
        echo "   ⚡ Lambda: https://console.aws.amazon.com/lambda/home#/functions"
        echo "   🌐 API Gateway: https://console.aws.amazon.com/apigateway/home#/apis"
        echo "   👤 Cognito: https://console.aws.amazon.com/cognito/users/"
        echo "   📦 S3: https://console.aws.amazon.com/s3/"
        echo "   ☁️  CloudFront: https://console.aws.amazon.com/cloudfront/home"
        echo ""
        echo "💡 Tip: Search for resources containing 'todo', 'task', or your project name"
    fi
}

# Show cleanup summary
show_cleanup_summary() {
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    echo "📋 Cleanup Summary"
    echo "=================="
    echo ""
    echo "⏱️  Cleanup completed in: ${duration} seconds"
    echo "🗑️  Resources processed: All Terraform-managed resources"
    echo "🧹 Local files: Cleaned according to user selection"
    echo "💰 AWS charges: Stopped (verify in billing console)"
    echo ""
    echo "✅ TaskFlow cleanup operations completed!"
    echo ""
    echo "🔍 Recommended next steps:"
    echo "   1. 💳 Check AWS billing dashboard to confirm no ongoing charges"
    echo "   2. 👀 Review AWS Cost Explorer for final cost breakdown"
    echo "   3. 🗑️  Remove any custom DNS records if configured"
    echo "   4. 🧹 Clean up external integrations or API keys"
    echo ""
    echo "🚀 To redeploy TaskFlow:"
    echo "   ./deploy.sh"
    echo ""
    echo "📚 To explore the code:"
    echo "   • frontend/app-unified.js - Unified authentication system"
    echo "   • frontend/index-unified.html - Modern responsive design"
    echo "   • terraform/ - Infrastructure as code"
    echo ""
    log_success "Thank you for using TaskFlow! 👋"
}

# Main cleanup execution
main() {
    local start_time=$(date +%s)
    
    echo "⏰ Started at: $(date)"
    echo ""
    
    show_destruction_warning
    confirm_destruction
    check_prerequisites
    analyze_current_resources
    
    log_step "🚀 Starting comprehensive cleanup..."
    echo ""
    
    cleanup_s3_buckets
    disable_cloudfront
    destroy_infrastructure
    cleanup_local_files
    verify_cleanup
    show_cleanup_summary
    
    echo ""
    log_success "🎉 TaskFlow cleanup completed successfully!"
}

# Error handling
cleanup_on_error() {
    log_error "Cleanup process interrupted!"
    
    # Remove temporary files
    rm -f terraform/destroy-plan
    rm -f /tmp/cf-config*.json
    rm -f /tmp/versions.json
    rm -f /tmp/delete-markers.json
    
    echo ""
    log_info "💡 To resume cleanup: ./cleanup.sh"
    log_info "🔍 To check remaining resources: visit AWS Console"
    log_info "🛠️  For manual cleanup: see AWS console links above"
}

# Set up error handling
trap cleanup_on_error ERR INT TERM

# Ensure we're in the right directory
if [ ! -f "deploy.sh" ]; then
    log_error "Please run this script from the project root directory"
    echo "Current directory: $(pwd)"
    echo "Expected files: deploy.sh, terraform/, frontend/"
    exit 1
fi

# Run main cleanup process
main "$@"

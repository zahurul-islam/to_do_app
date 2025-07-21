#!/bin/bash

# Enhanced AI-Powered TaskFlow Deployment Script
# This script deploys the complete TaskFlow AI application with modern UI and AI integration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project configuration
PROJECT_NAME="taskflow-ai"
REGION="us-west-2"
DEPLOYMENT_STAGE="prod"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if running from correct directory
    if [[ ! -f "terraform/main.tf" ]]; then
        print_error "Please run this script from the project root directory"
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed. Please install Python 3 first."
        exit 1
    fi
    
    # Check pip
    if ! command -v pip3 &> /dev/null; then
        print_error "pip3 is not installed. Please install pip3 first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    # Check if region is supported
    if ! aws ec2 describe-regions --region-names $REGION &> /dev/null; then
        print_error "Region $REGION is not valid or accessible."
        exit 1
    fi
    
    print_success "All prerequisites checked successfully"
}

# Function to prepare Lambda packages
prepare_lambda_packages() {
    print_header "Preparing Lambda Packages"
    
    # Create lambda packages directory if it doesn't exist
    mkdir -p terraform/lambda/packages
    
    # Package AI extractor Lambda
    print_status "Packaging AI extractor Lambda..."
    
    cd terraform/lambda/gemini_extractor
    
    # Install dependencies if requirements.txt exists
    if [[ -f "requirements.txt" ]]; then
        print_status "Installing Python dependencies..."
        pip3 install -r requirements.txt -t . --quiet
    fi
    
    cd ../../..
    
    print_success "Lambda packages prepared"
}

# Function to load environment variables
load_environment() {
    print_header "Loading Environment Configuration"
    
    # Load .env file if it exists
    if [[ -f ".env" ]]; then
        print_status "Loading variables from .env file..."
        
        # Export variables from .env file
        export $(grep -v '^#' .env | xargs)
        
        # Check if we have the Gemini API key
        if [[ ! -z "$GEMINI_API_KEY" && "$GEMINI_API_KEY" != "your_gemini_api_key_here" ]]; then
            print_success "Gemini API key loaded from .env file"
            HAS_GEMINI_KEY=true
        else
            print_warning "Gemini API key not found in .env file"
            HAS_GEMINI_KEY=false
        fi
        
        # Check if we have the OpenAI API key
        if [[ ! -z "$OPENAI_API_KEY" && "$OPENAI_API_KEY" != "your_openai_api_key_here" ]]; then
            print_success "OpenAI API key loaded from .env file"
            HAS_OPENAI_KEY=true
        else
            print_warning "OpenAI API key not found in .env file (optional)"
            HAS_OPENAI_KEY=false
        fi
    else
        print_warning ".env file not found - API keys will use placeholder values"
        HAS_GEMINI_KEY=false
        HAS_OPENAI_KEY=false
        GEMINI_API_KEY=""
        OPENAI_API_KEY=""
    fi
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_header "Deploying Infrastructure"
    
    cd terraform
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init -upgrade
    
    # Plan deployment
    print_status "Planning deployment..."
    terraform plan \
        -var="project_name=$PROJECT_NAME" \
        -var="aws_region=$REGION" \
        -var="gemini_api_key=$GEMINI_API_KEY" \
        -var="openai_api_key=$OPENAI_API_KEY" \
        -out=tfplan
    
    # Apply deployment
    print_status "Applying deployment..."
    terraform apply tfplan
    
    # Get outputs
    print_status "Getting deployment outputs..."
    API_URL=$(terraform output -raw api_gateway_url)
    USER_POOL_ID=$(terraform output -raw user_pool_id)
    USER_POOL_CLIENT_ID=$(terraform output -raw user_pool_client_id)
    CLOUDFRONT_URL=$(terraform output -raw cloudfront_url)
    AI_ENDPOINT=$(terraform output -raw ai_extraction_endpoint 2>/dev/null || echo "Not deployed")
    
    cd ..
    
    print_success "Infrastructure deployed successfully"
}

# Function to update AI secrets (now optional since we use environment variables)
update_ai_secrets() {
    print_header "Updating AI Secrets"
    
    if [[ $HAS_GEMINI_KEY == true ]]; then
        print_status "Storing Gemini API key in AWS Secrets Manager (backup)..."
        aws secretsmanager update-secret \
            --secret-id "${PROJECT_NAME}-gemini-api-key" \
            --secret-string "$GEMINI_API_KEY" \
            --region $REGION
        print_success "Gemini API key stored in secrets manager"
    else
        print_warning "No Gemini API key to store in secrets manager"
    fi
    
    if [[ $HAS_OPENAI_KEY == true ]]; then
        print_status "Storing OpenAI API key in AWS Secrets Manager (backup)..."
        aws secretsmanager update-secret \
            --secret-id "${PROJECT_NAME}-openai-api-key" \
            --secret-string "$OPENAI_API_KEY" \
            --region $REGION
        print_success "OpenAI API key stored in secrets manager"
    else
        print_warning "No OpenAI API key to store in secrets manager"
    fi
    
    print_success "AI configuration completed"
}

# Function to configure frontend
configure_frontend() {
    print_header "Configuring Frontend"
    
    # Create config.json for frontend
    cat > frontend/config.json << EOF
{
  "region": "$REGION",
  "userPoolId": "$USER_POOL_ID",
  "userPoolClientId": "$USER_POOL_CLIENT_ID",
  "apiGatewayUrl": "$API_URL"
}
EOF
    
    # Copy enhanced files to main frontend
    print_status "Setting up enhanced UI..."
    cp frontend/index-ai-enhanced.html frontend/index.html
    cp frontend/app-ai-enhanced.js frontend/app.js
    
    print_success "Frontend configured"
}

# Function to deploy frontend to S3
deploy_frontend() {
    print_header "Deploying Frontend"
    
    # Get S3 bucket name from Terraform output
    cd terraform
    S3_BUCKET=$(terraform output -raw s3_bucket_name)
    cd ..
    
    # Sync frontend files to S3
    print_status "Uploading frontend files to S3..."
    aws s3 sync frontend/ s3://$S3_BUCKET/ \
        --exclude "*.md" \
        --exclude "*.txt" \
        --exclude "*-ai-enhanced.*" \
        --exclude "*-unified.*" \
        --exclude "*-modern.*" \
        --exclude "*-fixed.*" \
        --exclude "*-enhanced.*" \
        --exclude "*-flowless.*" \
        --delete
    
    # Set correct content types
    aws s3 cp frontend/index.html s3://$S3_BUCKET/index.html --content-type "text/html"
    aws s3 cp frontend/app.js s3://$S3_BUCKET/app.js --content-type "application/javascript"
    aws s3 cp frontend/components-enhanced.js s3://$S3_BUCKET/components-enhanced.js --content-type "application/javascript"
    aws s3 cp frontend/config.json s3://$S3_BUCKET/config.json --content-type "application/json"
    
    print_success "Frontend deployed to S3"
}

# Function to create CloudFront invalidation
invalidate_cloudfront() {
    print_header "Invalidating CloudFront Cache"
    
    cd terraform
    DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)
    cd ..
    
    print_status "Creating CloudFront invalidation..."
    aws cloudfront create-invalidation \
        --distribution-id $DISTRIBUTION_ID \
        --paths "/*" > /dev/null
    
    print_success "CloudFront cache invalidated"
}

# Function to run tests
run_tests() {
    print_header "Running Tests"
    
    # Test API Gateway
    print_status "Testing API Gateway..."
    response=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/health" || echo "000")
    
    if [[ $response == "200" ]]; then
        print_success "API Gateway is responding"
    else
        print_warning "API Gateway test failed (HTTP $response)"
    fi
    
    # Test frontend
    print_status "Testing frontend..."
    response=$(curl -s -o /dev/null -w "%{http_code}" "$CLOUDFRONT_URL" || echo "000")
    
    if [[ $response == "200" ]]; then
        print_success "Frontend is accessible"
    else
        print_warning "Frontend test failed (HTTP $response)"
    fi
    
    print_success "Tests completed"
}

# Function to display deployment summary
display_summary() {
    print_header "Deployment Summary"
    
    echo -e "${GREEN}🚀 TaskFlow AI has been successfully deployed!${NC}"
    echo ""
    echo -e "${CYAN}📱 Application URL:${NC} $CLOUDFRONT_URL"
    echo -e "${CYAN}🔗 API Gateway URL:${NC} $API_URL"
    echo -e "${CYAN}🤖 AI Extraction Endpoint:${NC} $AI_ENDPOINT"
    echo -e "${CYAN}🔐 User Pool ID:${NC} $USER_POOL_ID"
    echo -e "${CYAN}📊 Region:${NC} $REGION"
    echo ""
    echo -e "${YELLOW}📋 Next Steps:${NC}"
    echo "1. Open $CLOUDFRONT_URL in your browser"
    echo "2. Create an account or sign in"
    echo "3. Try the AI task extraction feature"
    echo "4. Add your AI API keys in AWS Secrets Manager if not done during setup"
    echo ""
    echo -e "${CYAN}🔧 AI Configuration:${NC}"
    if [[ $HAS_GEMINI_KEY == true ]]; then
        echo "✅ Gemini API key configured from .env file"
    else
        echo "⚠️  Gemini API key not configured - add to .env file for AI features"
    fi
    
    if [[ $HAS_OPENAI_KEY == true ]]; then
        echo "✅ OpenAI API key configured from .env file"
    else
        echo "ℹ️  OpenAI API key not configured (optional fallback)"
    fi
    echo ""
    echo -e "${CYAN}🔧 Manual Configuration:${NC}"
    echo "• Update .env file with your API keys"
    echo "• Redeploy: ./deploy-ai-enhanced.sh"
    echo ""
    echo -e "${GREEN}✨ Features Available:${NC}"
    echo "• 🤖 AI-powered task extraction from emails, notes, and documents"
    echo "• 📱 Modern glassmorphism UI with dark theme"
    echo "• 🎯 Smart categorization and priority detection"
    echo "• 📅 Automatic due date extraction"
    echo "• 🔐 Secure AWS Cognito authentication"
    echo "• ☁️ Cloud-native architecture with DynamoDB and Lambda"
    echo ""
    echo -e "${PURPLE}Happy task managing! 🎉${NC}"
}

# Main execution
main() {
    print_header "TaskFlow AI - Enhanced Deployment"
    
    echo -e "${CYAN}This script will deploy TaskFlow AI with:${NC}"
    echo "• Modern glassmorphism UI with dark theme"
    echo "• AI-powered task extraction using Gemini and OpenAI"
    echo "• Smart categorization and priority detection"
    echo "• AWS Cognito authentication"
    echo "• CloudFront CDN for global performance"
    echo ""
    
    read -p "Continue with deployment? (y/n): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Deployment cancelled"
        exit 0
    fi
    
    # Execute deployment steps
    check_prerequisites
    load_environment
    prepare_lambda_packages
    deploy_infrastructure
    update_ai_secrets
    configure_frontend
    deploy_frontend
    invalidate_cloudfront
    run_tests
    display_summary
}

# Run main function
main "$@"

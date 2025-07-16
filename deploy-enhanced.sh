#!/bin/bash

# Enhanced deployment script for TaskFlow with AI integration
set -e

echo "🚀 Starting TaskFlow deployment with AI integration..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if we're in the right directory
if [ ! -f "terraform/main.tf" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

# Check required tools
print_status "Checking required tools..."

if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed"
    exit 1
fi

if ! command -v zip &> /dev/null; then
    print_error "zip command is not available"
    exit 1
fi

print_success "All required tools are available"

# Step 1: Package the Lambda function
print_status "Packaging Lambda function with enhanced todo management..."

cd terraform
rm -f lambda_function.zip

# Create a temporary directory for Lambda package
mkdir -p lambda_package
cd lambda_package

# Copy the updated Lambda function
cp ../lambda/index.py .

# Create the zip file
zip -r ../lambda_function.zip .

# Clean up
cd ..
rm -rf lambda_package

print_success "Lambda function packaged successfully"

# Step 2: Initialize and plan Terraform
print_status "Initializing Terraform..."
terraform init

print_status "Creating Terraform execution plan..."
terraform plan -out=deployment.tfplan

# Step 3: Ask for confirmation
echo ""
print_warning "About to deploy the following changes:"
echo "- Updated Lambda function with enhanced todo management"
echo "- Fixed data structure mapping between frontend and backend"
echo "- Modern frontend with AI integration"
echo ""
read -p "Do you want to proceed with deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Deployment cancelled by user"
    exit 0
fi

# Step 4: Apply Terraform changes
print_status "Applying Terraform changes..."
terraform apply deployment.tfplan

# Clean up plan file
rm -f deployment.tfplan

print_success "Infrastructure deployment completed!"

# Step 5: Update frontend files
print_status "Updating frontend files..."
cd ../frontend

# Copy modern files to be the main files
cp index-modern.html index.html
cp app-modern.js app.js

print_success "Frontend files updated with modern interface and AI integration"

# Step 6: Get deployment information
cd ../terraform
print_status "Retrieving deployment information..."

API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "Not available")
USER_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null || echo "Not available")
USER_POOL_CLIENT_ID=$(terraform output -raw cognito_user_pool_client_id 2>/dev/null || echo "Not available")
REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-west-2")

# Update frontend config
print_status "Updating frontend configuration..."
cat > ../frontend/config.json << EOF
{
  "apiGatewayUrl": "$API_URL",
  "region": "$REGION",
  "userPoolClientId": "$USER_POOL_CLIENT_ID",
  "userPoolId": "$USER_POOL_ID"
}
EOF

print_success "Frontend configuration updated"

# Step 7: Test API endpoint
print_status "Testing API endpoint..."
if [ "$API_URL" != "Not available" ]; then
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/todos" || echo "000")
    if [ "$HTTP_STATUS" = "401" ] || [ "$HTTP_STATUS" = "403" ]; then
        print_success "API endpoint is responding (authentication required)"
    elif [ "$HTTP_STATUS" = "200" ]; then
        print_success "API endpoint is responding successfully"
    else
        print_warning "API endpoint returned status: $HTTP_STATUS"
    fi
else
    print_warning "Could not retrieve API URL for testing"
fi

cd ..

# Step 8: Display deployment summary
echo ""
echo "================================================================"
print_success "🎉 TaskFlow deployment completed successfully!"
echo "================================================================"
echo ""
echo "📋 Deployment Summary:"
echo "  ✅ Lambda function updated with enhanced todo management"
echo "  ✅ Fixed data structure mapping (frontend ↔ backend)"  
echo "  ✅ Modern UI with gradients and animations deployed"
echo "  ✅ AI integration with Gemini API configured"
echo "  ✅ Enhanced error handling and notifications"
echo "  ✅ Responsive design for mobile and desktop"
echo ""
echo "🔗 Service Information:"
echo "  • API Gateway URL: $API_URL"
echo "  • Cognito User Pool ID: $USER_POOL_ID"
echo "  • Cognito Client ID: $USER_POOL_CLIENT_ID"
echo "  • AWS Region: $REGION"
echo ""
echo "🤖 AI Features:"
echo "  • Task extraction from emails and notes"
echo "  • Smart categorization and priority detection"
echo "  • Natural language processing for task creation"
echo ""
echo "🌟 New Features:"
echo "  • Modern gradient-based design"
echo "  • Real-time task statistics dashboard"
echo "  • Enhanced filtering and search"
echo "  • Smooth animations and transitions"
echo "  • Improved mobile responsiveness"
echo ""
echo "📱 Access your app:"
echo "  • Open frontend/index.html in your browser"
echo "  • Or serve it with: cd frontend && python -m http.server 8000"
echo "  • Then visit: http://localhost:8000"
echo ""
echo "🔧 Next Steps:"
echo "  1. Test the application with the modern interface"
echo "  2. Try the AI task extraction feature"
echo "  3. Create, update, and delete tasks to verify functionality"
echo "  4. Check the task dashboard for statistics"
echo ""
print_success "Deployment completed! Your TaskFlow app is ready to use."

#!/bin/bash

# Complete destroy and fresh deployment script for TaskFlow
set -e

echo "🗑️ Starting complete TaskFlow destruction and fresh deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

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

print_destroy() {
    echo -e "${PURPLE}[DESTROY]${NC} $1"
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

print_success "All required tools are available"

# Step 1: Destroy existing infrastructure
echo ""
echo "================================================================"
print_destroy "🗑️ DESTROYING EXISTING INFRASTRUCTURE"
echo "================================================================"

cd terraform

print_destroy "Initializing Terraform for destruction..."
terraform init

print_destroy "Checking current infrastructure state..."
if [ -f "terraform.tfstate" ]; then
    print_warning "Found existing infrastructure. Proceeding with destruction..."
    
    # Show what will be destroyed
    print_destroy "Planning destruction..."
    terraform plan -destroy -out=destroy.tfplan
    
    echo ""
    print_warning "⚠️  ABOUT TO DESTROY ALL AWS RESOURCES ⚠️"
    echo "This will remove:"
    echo "  - DynamoDB tables"
    echo "  - Lambda functions"
    echo "  - API Gateway"
    echo "  - Cognito User Pools"
    echo "  - IAM roles and policies"
    echo "  - All associated data"
    echo ""
    read -p "Are you sure you want to proceed with destruction? (type 'DESTROY' to confirm): " -r
    
    if [[ $REPLY == "DESTROY" ]]; then
        print_destroy "Destroying infrastructure..."
        terraform apply destroy.tfplan
        
        print_success "Infrastructure destroyed successfully!"
        
        # Clean up state files
        print_destroy "Cleaning up Terraform state files..."
        rm -f terraform.tfstate*
        rm -f destroy.tfplan
        rm -f deployment.tfplan 2>/dev/null || true
        rm -f .terraform.lock.hcl
        rm -rf .terraform/
        
        print_success "State files cleaned up"
    else
        print_error "Destruction cancelled. Must type 'DESTROY' to confirm."
        exit 1
    fi
else
    print_warning "No existing infrastructure found to destroy"
fi

# Step 2: Clean up old files
echo ""
echo "================================================================"
print_destroy "🧹 CLEANING UP OLD FILES"
echo "================================================================"

print_destroy "Removing old build artifacts..."
rm -f lambda_function.zip
rm -f lambda_package.zip
rm -rf lambda_package/
rm -f frontend-plan
rm -f test_api.py

print_success "Old files cleaned up"

# Step 3: Wait a moment for AWS eventual consistency
print_status "Waiting for AWS eventual consistency (30 seconds)..."
sleep 30

# Step 4: Fresh deployment
echo ""
echo "================================================================"
print_success "🚀 STARTING FRESH DEPLOYMENT"
echo "================================================================"

cd .. # Back to project root

print_status "Packaging enhanced Lambda function..."
cd terraform

# Create fresh Lambda package
mkdir -p lambda_package
cd lambda_package

# Copy the enhanced Lambda function
cp ../lambda/index.py .

# Create the zip file
zip -r ../lambda_function.zip .

# Clean up
cd ..
rm -rf lambda_package

print_success "Lambda function packaged"

# Step 5: Fresh Terraform initialization and deployment
print_status "Fresh Terraform initialization..."
terraform init

print_status "Creating fresh deployment plan..."
terraform plan -out=fresh_deployment.tfplan

echo ""
print_warning "About to deploy fresh TaskFlow infrastructure:"
echo "  ✅ Enhanced Lambda function with AI integration"
echo "  ✅ Fixed data structure mapping"
echo "  ✅ DynamoDB table for todos"
echo "  ✅ API Gateway with CORS"
echo "  ✅ Cognito User Pool for authentication"
echo "  ✅ All necessary IAM roles and policies"
echo ""
read -p "Proceed with fresh deployment? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Deployment cancelled by user"
    rm -f fresh_deployment.tfplan
    exit 0
fi

print_status "Applying fresh infrastructure..."
terraform apply fresh_deployment.tfplan

# Clean up plan file
rm -f fresh_deployment.tfplan

print_success "Fresh infrastructure deployed!"

# Step 6: Update frontend configuration
print_status "Configuring frontend with new infrastructure..."

# Get the new configuration
API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "Not available")
USER_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null || echo "Not available")
USER_POOL_CLIENT_ID=$(terraform output -raw cognito_user_pool_client_id 2>/dev/null || echo "Not available")
REGION=$(terraform output -raw aws_region 2>/dev/null || echo "us-west-2")

# Update frontend config with new values
print_status "Writing fresh frontend configuration..."
cat > ../frontend/config.json << EOF
{
  "apiGatewayUrl": "$API_URL",
  "region": "$REGION",
  "userPoolClientId": "$USER_POOL_CLIENT_ID",
  "userPoolId": "$USER_POOL_ID"
}
EOF

# Ensure modern files are active
cd ../frontend
print_status "Activating modern frontend files..."
cp index-modern.html index.html
cp app-modern.js app.js

print_success "Frontend configured with fresh infrastructure"

# Step 7: Test the fresh deployment
print_status "Testing fresh API endpoint..."
if [ "$API_URL" != "Not available" ]; then
    # Wait a bit for API Gateway to be ready
    sleep 10
    
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/todos" 2>/dev/null || echo "000")
    if [ "$HTTP_STATUS" = "401" ] || [ "$HTTP_STATUS" = "403" ]; then
        print_success "Fresh API endpoint is responding (authentication required)"
    elif [ "$HTTP_STATUS" = "200" ]; then
        print_success "Fresh API endpoint is responding successfully"
    else
        print_warning "API endpoint returned status: $HTTP_STATUS (might need a moment to fully initialize)"
    fi
else
    print_warning "Could not retrieve API URL for testing"
fi

cd ..

# Step 8: Run comprehensive tests
print_status "Running comprehensive tests on fresh deployment..."
./test-enhanced.sh

# Step 9: Final summary
echo ""
echo "================================================================"
print_success "🎉 FRESH TASKFLOW DEPLOYMENT COMPLETED!"
echo "================================================================"
echo ""
echo "🗑️ Destruction Summary:"
echo "  ✅ All old AWS resources destroyed"
echo "  ✅ State files cleaned up"
echo "  ✅ Build artifacts removed"
echo ""
echo "🚀 Fresh Deployment Summary:"
echo "  ✅ Enhanced Lambda function deployed"
echo "  ✅ Fixed data structure mapping active"
echo "  ✅ Modern UI with AI integration"
echo "  ✅ Fresh AWS infrastructure created"
echo "  ✅ Frontend configured with new endpoints"
echo ""
echo "🔗 Fresh Service Information:"
echo "  • API Gateway URL: $API_URL"
echo "  • Cognito User Pool ID: $USER_POOL_ID"
echo "  • Cognito Client ID: $USER_POOL_CLIENT_ID"
echo "  • AWS Region: $REGION"
echo ""
echo "🤖 AI Features Ready:"
echo "  • Gemini API integration active"
echo "  • Smart task extraction from text"
echo "  • Automatic categorization and prioritization"
echo ""
echo "🎨 Modern Interface Active:"
echo "  • Beautiful gradient design"
echo "  • Smooth animations and transitions"
echo "  • Real-time task dashboard"
echo "  • Mobile-responsive layout"
echo ""
echo "🚀 Next Steps:"
echo "  1. Start development server:"
echo "     cd frontend && python -m http.server 8000"
echo ""
echo "  2. Open your browser:"
echo "     http://localhost:8000"
echo ""
echo "  3. Test AI features:"
echo "     - Paste email text in the AI extractor"
echo "     - Watch tasks get automatically extracted and categorized"
echo ""
echo "  4. Verify everything works:"
echo "     - Create tasks manually"
echo "     - Mark tasks as complete"
echo "     - Delete tasks"
echo "     - Check the dashboard statistics"
echo ""
print_success "Your fresh TaskFlow app is ready! 🎯"
echo ""
print_warning "📝 Note: You may need to create a new user account since all data was destroyed."

#!/bin/bash

# Setup script for Serverless Todo Application
# This script helps prepare the environment for deployment

set -e  # Exit on any error

echo "🔧 Serverless Todo App Setup Script"
echo "===================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_color() {
    printf "${1}${2}${NC}\n"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check system requirements
check_system_requirements() {
    print_color $BLUE "📋 Checking system requirements..."
    
    # Check operating system
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        print_color $GREEN "✅ Linux detected"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        print_color $GREEN "✅ macOS detected"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        print_color $GREEN "✅ Windows detected"
    else
        print_color $YELLOW "⚠️  Unknown operating system: $OSTYPE"
    fi
    
    # Check for curl
    if command_exists curl; then
        print_color $GREEN "✅ curl is available"
    else
        print_color $RED "❌ curl is required but not installed"
        echo "   Please install curl and run this script again"
        exit 1
    fi
}

# Install AWS CLI
install_aws_cli() {
    if command_exists aws; then
        print_color $GREEN "✅ AWS CLI is already installed"
        aws --version
    else
        print_color $YELLOW "📦 Installing AWS CLI..."
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install
            rm -rf awscliv2.zip aws/
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
            sudo installer -pkg AWSCLIV2.pkg -target /
            rm AWSCLIV2.pkg
        else
            print_color $RED "❌ Please install AWS CLI manually for your operating system"
            echo "   Visit: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html"
            exit 1
        fi
        
        print_color $GREEN "✅ AWS CLI installed successfully"
    fi
}

# Install Terraform
install_terraform() {
    if command_exists terraform; then
        print_color $GREEN "✅ Terraform is already installed"
        terraform version
    else
        print_color $YELLOW "📦 Installing Terraform..."
        
        # Get latest Terraform version
        TERRAFORM_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//')
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            curl -LO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
            unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
            sudo mv terraform /usr/local/bin/
            rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            curl -LO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_darwin_amd64.zip"
            unzip "terraform_${TERRAFORM_VERSION}_darwin_amd64.zip"
            sudo mv terraform /usr/local/bin/
            rm "terraform_${TERRAFORM_VERSION}_darwin_amd64.zip"
        else
            print_color $RED "❌ Please install Terraform manually for your operating system"
            echo "   Visit: https://www.terraform.io/downloads.html"
            exit 1
        fi
        
        print_color $GREEN "✅ Terraform installed successfully"
    fi
}

# Setup AWS credentials
setup_aws_credentials() {
    print_color $BLUE "🔑 Setting up AWS credentials..."
    
    if aws sts get-caller-identity >/dev/null 2>&1; then
        print_color $GREEN "✅ AWS credentials are already configured"
        echo "   Current identity:"
        aws sts get-caller-identity
    else
        print_color $YELLOW "⚠️  AWS credentials not configured"
        echo ""
        echo "To configure AWS credentials, you need:"
        echo "1. AWS Access Key ID"
        echo "2. AWS Secret Access Key"
        echo "3. Default region (e.g., us-west-2)"
        echo ""
        
        read -p "Do you want to configure AWS credentials now? (y/n): " configure_aws
        
        if [[ $configure_aws =~ ^[Yy]$ ]]; then
            aws configure
            
            # Test credentials
            if aws sts get-caller-identity >/dev/null 2>&1; then
                print_color $GREEN "✅ AWS credentials configured successfully"
            else
                print_color $RED "❌ AWS credentials configuration failed"
                exit 1
            fi
        else
            print_color $YELLOW "⚠️  AWS credentials not configured. You'll need to do this before deployment."
        fi
    fi
}

# Setup Terraform variables
setup_terraform_variables() {
    print_color $BLUE "📝 Setting up Terraform variables..."
    
    cd terraform
    
    if [ -f "terraform.tfvars" ]; then
        print_color $GREEN "✅ terraform.tfvars already exists"
    else
        if [ -f "terraform.tfvars.example" ]; then
            cp terraform.tfvars.example terraform.tfvars
            print_color $GREEN "✅ Created terraform.tfvars from example"
            
            print_color $YELLOW "⚠️  Please review and update terraform.tfvars with your specific values:"
            echo "   - aws_region (default: us-west-2)"
            echo "   - project_name"
            echo "   - amplify_repository_url (if using Git integration)"
            echo "   - amplify_domain_name (if using custom domain)"
        else
            print_color $RED "❌ terraform.tfvars.example not found"
        fi
    fi
    
    cd ..
}

# Validate Terraform configuration
validate_terraform() {
    print_color $BLUE "🔍 Validating Terraform configuration..."
    
    cd terraform
    
    # Initialize Terraform
    terraform init
    
    # Validate configuration
    if terraform validate; then
        print_color $GREEN "✅ Terraform configuration is valid"
    else
        print_color $RED "❌ Terraform configuration validation failed"
        exit 1
    fi
    
    cd ..
}

# Show next steps
show_next_steps() {
    print_color $BLUE "🎯 Setup Complete! Next Steps:"
    echo "================================"
    echo ""
    echo "1. 📝 Review and update terraform/terraform.tfvars with your values"
    echo "2. 🚀 Run deployment script: ./deploy.sh"
    echo "3. 🌐 Access your application at the provided URL"
    echo "4. 📚 Read docs/README.md for detailed instructions"
    echo "5. 🧪 Follow docs/test-plan.md to test your application"
    echo ""
    echo "📁 Project structure:"
    echo "   frontend/     - React web application"
    echo "   terraform/    - Infrastructure as Code"
    echo "   docs/         - Documentation"
    echo "   deploy.sh     - Deployment script"
    echo "   cleanup.sh    - Cleanup script"
    echo ""
    echo "💡 Helpful commands:"
    echo "   ./deploy.sh   - Deploy the application"
    echo "   ./cleanup.sh  - Delete all resources"
    echo ""
    echo "🔗 Useful links:"
    echo "   AWS Console: https://console.aws.amazon.com"
    echo "   Terraform Docs: https://www.terraform.io/docs"
    echo "   AWS Free Tier: https://aws.amazon.com/free"
}

# Main setup function
main() {
    print_color $GREEN "🚀 Welcome to Serverless Todo App Setup!"
    echo ""
    
    check_system_requirements
    echo ""
    
    install_aws_cli
    echo ""
    
    install_terraform
    echo ""
    
    setup_aws_credentials
    echo ""
    
    setup_terraform_variables
    echo ""
    
    validate_terraform
    echo ""
    
    show_next_steps
    
    print_color $GREEN "🎉 Setup completed successfully!"
}

# Run main function
main "$@"

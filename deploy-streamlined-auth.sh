#!/bin/bash

# Deploy Streamlined Authentication System
# This script replaces the complex authentication flow with a seamless experience

set -e

echo "🚀 Deploying Streamlined Authentication System..."
echo "======================================================"

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$SCRIPT_DIR/frontend"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Backup current files
backup_current_files() {
    print_info "Creating backup of current authentication files..."
    
    BACKUP_DIR="$SCRIPT_DIR/backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup current files
    if [ -f "$FRONTEND_DIR/index.html" ]; then
        cp "$FRONTEND_DIR/index.html" "$BACKUP_DIR/index.html.backup"
        print_status "Backed up index.html"
    fi
    
    if [ -f "$FRONTEND_DIR/app.js" ]; then
        cp "$FRONTEND_DIR/app.js" "$BACKUP_DIR/app.js.backup"
        print_status "Backed up app.js"
    fi
    
    if [ -f "$FRONTEND_DIR/auth-complete.js" ]; then
        cp "$FRONTEND_DIR/auth-complete.js" "$BACKUP_DIR/auth-complete.js.backup"
        print_status "Backed up auth-complete.js"
    fi
    
    if [ -f "$FRONTEND_DIR/auth-forms.js" ]; then
        cp "$FRONTEND_DIR/auth-forms.js" "$BACKUP_DIR/auth-forms.js.backup"
        print_status "Backed up auth-forms.js"
    fi
    
    if [ -f "$FRONTEND_DIR/auth-verification.js" ]; then
        cp "$FRONTEND_DIR/auth-verification.js" "$BACKUP_DIR/auth-verification.js.backup"
        print_status "Backed up auth-verification.js"
    fi
    
    print_status "Backup created at: $BACKUP_DIR"
}

# Deploy new streamlined files
deploy_streamlined_auth() {
    print_info "Deploying streamlined authentication system..."
    
    # Replace index.html with streamlined version
    if [ -f "$FRONTEND_DIR/index-flowless.html" ]; then
        cp "$FRONTEND_DIR/index-flowless.html" "$FRONTEND_DIR/index.html"
        print_status "Deployed streamlined index.html"
    else
        print_error "index-flowless.html not found!"
        exit 1
    fi
    
    # Replace app.js with streamlined version
    if [ -f "$FRONTEND_DIR/app-flowless.js" ]; then
        cp "$FRONTEND_DIR/app-flowless.js" "$FRONTEND_DIR/app.js"
        print_status "Deployed streamlined app.js"
    else
        print_error "app-flowless.js not found!"
        exit 1
    fi
    
    print_status "Streamlined authentication files deployed successfully"
}

# Update Terraform outputs if needed
update_terraform_config() {
    print_info "Checking Terraform configuration..."
    
    TERRAFORM_DIR="$SCRIPT_DIR/terraform"
    
    if [ -d "$TERRAFORM_DIR" ]; then
        cd "$TERRAFORM_DIR"
        
        # Check if terraform is initialized
        if [ -d ".terraform" ]; then
            print_info "Getting current Terraform outputs..."
            
            # Generate config.json with current values
            terraform output -json > temp_outputs.json
            
            if [ -s temp_outputs.json ]; then
                python3 << EOF
import json
import os

# Read terraform outputs
with open('temp_outputs.json', 'r') as f:
    outputs = json.load(f)

# Extract values
config = {
    "region": outputs.get("aws_region", {}).get("value", "us-west-2"),
    "userPoolId": outputs.get("cognito_user_pool_id", {}).get("value", ""),
    "userPoolClientId": outputs.get("cognito_user_pool_client_id", {}).get("value", ""),
    "apiGatewayUrl": outputs.get("api_gateway_url", {}).get("value", "")
}

# Write to frontend config
frontend_config_path = "../frontend/config.json"
with open(frontend_config_path, 'w') as f:
    json.dump(config, f, indent=2)

print(f"✅ Updated frontend config: {frontend_config_path}")
print(f"   Region: {config['region']}")
print(f"   User Pool ID: {config['userPoolId'][:20]}..." if config['userPoolId'] else "   User Pool ID: NOT SET")
print(f"   Client ID: {config['userPoolClientId'][:20]}..." if config['userPoolClientId'] else "   Client ID: NOT SET")
print(f"   API URL: {config['apiGatewayUrl']}")
EOF
                
                rm -f temp_outputs.json
                print_status "Updated frontend configuration with Terraform outputs"
            else
                print_warning "No Terraform outputs found. Make sure Terraform is deployed."
            fi
        else
            print_warning "Terraform not initialized. Run 'terraform init' in the terraform directory."
        fi
        
        cd "$SCRIPT_DIR"
    else
        print_warning "Terraform directory not found. Skipping configuration update."
    fi
}

# Test the deployment
test_deployment() {
    print_info "Testing streamlined authentication deployment..."
    
    # Check if required files exist
    if [ ! -f "$FRONTEND_DIR/index.html" ]; then
        print_error "index.html not found after deployment!"
        return 1
    fi
    
    if [ ! -f "$FRONTEND_DIR/app.js" ]; then
        print_error "app.js not found after deployment!"
        return 1
    fi
    
    if [ ! -f "$FRONTEND_DIR/config.json" ]; then
        print_warning "config.json not found. Authentication may not work without Terraform configuration."
    fi
    
    # Check file sizes (basic validation)
    INDEX_SIZE=$(wc -c < "$FRONTEND_DIR/index.html")
    APP_SIZE=$(wc -c < "$FRONTEND_DIR/app.js")
    
    if [ "$INDEX_SIZE" -lt 1000 ]; then
        print_error "index.html seems too small ($INDEX_SIZE bytes). Deployment may have failed."
        return 1
    fi
    
    if [ "$APP_SIZE" -lt 5000 ]; then
        print_error "app.js seems too small ($APP_SIZE bytes). Deployment may have failed."
        return 1
    fi
    
    print_status "Deployment validation passed"
    print_info "index.html: ${INDEX_SIZE} bytes"
    print_info "app.js: ${APP_SIZE} bytes"
    
    return 0
}

# Start local development server
start_dev_server() {
    print_info "Starting local development server..."
    
    cd "$FRONTEND_DIR"
    
    # Check if Python is available
    if command -v python3 &> /dev/null; then
        print_info "Starting Python HTTP server on port 8080..."
        print_info "Access your app at: http://localhost:8080"
        print_info "Press Ctrl+C to stop the server"
        echo ""
        python3 -m http.server 8080
    elif command -v python &> /dev/null; then
        print_info "Starting Python HTTP server on port 8080..."
        print_info "Access your app at: http://localhost:8080"
        print_info "Press Ctrl+C to stop the server"
        echo ""
        python -m SimpleHTTPServer 8080
    else
        print_warning "Python not found. Please serve the frontend directory manually."
        print_info "You can use any web server to serve the files in: $FRONTEND_DIR"
    fi
}

# Display deployment summary
show_summary() {
    echo ""
    echo "======================================================"
    echo -e "${GREEN}🎉 Streamlined Authentication Deployment Complete!${NC}"
    echo "======================================================"
    echo ""
    echo "✨ What's New:"
    echo "  • Seamless signup and verification flow"
    echo "  • Auto sign-in after email verification"
    echo "  • Improved error handling with user-friendly messages"
    echo "  • Streamlined UI with better UX"
    echo "  • Automatic redirect between auth states"
    echo ""
    echo "🔧 Key Improvements:"
    echo "  • Reduced authentication steps"
    echo "  • Better form validation"
    echo "  • Enhanced visual feedback"
    echo "  • Mobile-responsive design"
    echo "  • Accessibility improvements"
    echo ""
    echo "📁 Files Updated:"
    echo "  • frontend/index.html (streamlined interface)"
    echo "  • frontend/app.js (enhanced authentication)"
    echo "  • frontend/config.json (Terraform integration)"
    echo ""
    echo "🚀 Next Steps:"
    echo "  1. Test the authentication flow locally"
    echo "  2. Deploy to your hosting platform (S3, Amplify, etc.)"
    echo "  3. Ensure Terraform outputs are properly configured"
    echo ""
    echo "💡 Development:"
    echo "  • Run './deploy-streamlined-auth.sh --dev' to start a local server"
    echo "  • Access at http://localhost:8080"
    echo ""
}

# Main execution
main() {
    echo "🔍 Pre-deployment checks..."
    
    # Check if we're in the right directory
    if [ ! -d "$FRONTEND_DIR" ]; then
        print_error "Frontend directory not found. Please run this script from the project root."
        exit 1
    fi
    
    # Check if streamlined files exist
    if [ ! -f "$FRONTEND_DIR/app-flowless.js" ] || [ ! -f "$FRONTEND_DIR/index-flowless.html" ]; then
        print_error "Streamlined authentication files not found. Please ensure they are created first."
        exit 1
    fi
    
    print_status "Pre-deployment checks passed"
    echo ""
    
    # Handle command line arguments
    case "${1:-}" in
        --dev)
            print_info "Development mode: Starting local server only..."
            start_dev_server
            exit 0
            ;;
        --backup-only)
            backup_current_files
            print_status "Backup completed. No deployment performed."
            exit 0
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dev         Start development server only"
            echo "  --backup-only Create backup without deploying"
            echo "  --help, -h    Show this help message"
            echo ""
            echo "Default: Full deployment with backup"
            exit 0
            ;;
    esac
    
    # Full deployment process
    backup_current_files
    echo ""
    
    deploy_streamlined_auth
    echo ""
    
    update_terraform_config
    echo ""
    
    if test_deployment; then
        echo ""
        show_summary
    else
        print_error "Deployment validation failed. Please check the errors above."
        exit 1
    fi
    
    # Ask if user wants to start dev server
    echo ""
    read -p "Would you like to start a local development server? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        start_dev_server
    else
        print_info "Deployment complete. You can manually serve the frontend directory."
    fi
}

# Run main function
main "$@"

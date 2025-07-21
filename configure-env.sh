#!/bin/bash

# Configure .env file for TaskFlow AI
# This script helps manage environment variables

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if .env exists
check_env_file() {
    if [[ -f ".env" ]]; then
        print_success ".env file found"
        
        # Show current Gemini key status
        if grep -q "GEMINI_API_KEY=AIzaSy" .env; then
            print_success "Gemini API key is configured"
        else
            print_warning "Gemini API key not configured"
        fi
        
        # Show current OpenAI key status  
        if grep -q "OPENAI_API_KEY=sk-" .env; then
            print_success "OpenAI API key is configured"
        else
            print_warning "OpenAI API key not configured (optional)"
        fi
    else
        print_warning ".env file not found"
        return 1
    fi
}

# Function to show current configuration
show_config() {
    print_header "Current Configuration"
    
    if [[ -f ".env" ]]; then
        echo -e "${CYAN}Current .env file contents:${NC}"
        echo ""
        # Show .env but mask API keys for security
        sed 's/\(API_KEY=\).*/\1***HIDDEN***/' .env
    else
        print_warning ".env file not found"
    fi
}

# Function to validate Gemini API key
validate_gemini_key() {
    local key="$1"
    
    if [[ ${#key} -lt 30 ]]; then
        echo "❌ Key seems too short"
        return 1
    fi
    
    if [[ ! $key =~ ^AIzaSy ]]; then
        echo "⚠️  Gemini keys typically start with 'AIzaSy'"
        return 1
    fi
    
    echo "✅ Key format looks valid"
    return 0
}

# Function to test API key
test_gemini_key() {
    local key="$1"
    
    print_status "Testing Gemini API key..."
    
    # Simple test API call
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$key" \
        -H "Content-Type: application/json" \
        -d '{"contents":[{"parts":[{"text":"Hello"}]}]}' || echo "000")
    
    if [[ $response == "200" ]]; then
        print_success "✅ API key is working!"
        return 0
    else
        print_warning "⚠️  API key test failed (HTTP $response)"
        return 1
    fi
}

# Function to update .env file
update_env_file() {
    print_header "Update .env Configuration"
    
    # Create .env if it doesn't exist
    if [[ ! -f ".env" ]]; then
        print_status "Creating new .env file..."
        cat > .env << 'EOF'
# TaskFlow AI Environment Configuration
# Add your API keys here - this file is ignored by git for security

# Google Gemini API Key (Primary AI provider)
GEMINI_API_KEY=your_gemini_api_key_here

# OpenAI API Key (Fallback AI provider) - Optional
OPENAI_API_KEY=your_openai_api_key_here

# AWS Configuration
AWS_REGION=us-west-2
PROJECT_NAME=taskflow-ai

# Deployment Configuration
ENVIRONMENT=production
EOF
        print_success ".env file created with template"
    fi
    
    echo -e "${CYAN}Configure API Keys:${NC}"
    echo ""
    
    # Gemini API Key
    echo -e "${YELLOW}Google Gemini API Key:${NC}"
    echo "Get your free key from: https://makersuite.google.com/app/apikey"
    echo ""
    read -p "Enter Gemini API key (or press Enter to keep current): " new_gemini_key
    
    if [[ ! -z "$new_gemini_key" ]]; then
        # Validate the key
        if validate_gemini_key "$new_gemini_key"; then
            # Test the key
            if test_gemini_key "$new_gemini_key"; then
                # Update .env file
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    # macOS
                    sed -i '' "s|GEMINI_API_KEY=.*|GEMINI_API_KEY=$new_gemini_key|" .env
                else
                    # Linux
                    sed -i "s|GEMINI_API_KEY=.*|GEMINI_API_KEY=$new_gemini_key|" .env
                fi
                print_success "Gemini API key updated and tested successfully!"
            else
                print_warning "API key test failed, but key was saved anyway"
                # Update even if test failed (might be network issue)
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    sed -i '' "s|GEMINI_API_KEY=.*|GEMINI_API_KEY=$new_gemini_key|" .env
                else
                    sed -i "s|GEMINI_API_KEY=.*|GEMINI_API_KEY=$new_gemini_key|" .env
                fi
            fi
        else
            print_warning "Key validation failed, but key was saved anyway"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s|GEMINI_API_KEY=.*|GEMINI_API_KEY=$new_gemini_key|" .env
            else
                sed -i "s|GEMINI_API_KEY=.*|GEMINI_API_KEY=$new_gemini_key|" .env
            fi
        fi
    fi
    
    echo ""
    
    # OpenAI API Key (optional)
    echo -e "${YELLOW}OpenAI API Key (optional fallback):${NC}"
    echo "Get your key from: https://platform.openai.com/api-keys"
    echo ""
    read -p "Enter OpenAI API key (or press Enter to skip): " new_openai_key
    
    if [[ ! -z "$new_openai_key" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|OPENAI_API_KEY=.*|OPENAI_API_KEY=$new_openai_key|" .env
        else
            sed -i "s|OPENAI_API_KEY=.*|OPENAI_API_KEY=$new_openai_key|" .env
        fi
        print_success "OpenAI API key updated!"
    fi
}

# Function to display next steps
display_next_steps() {
    print_header "Next Steps"
    
    echo -e "${GREEN}🎉 Configuration Complete!${NC}"
    echo ""
    echo -e "${CYAN}Your .env file is now configured with:${NC}"
    echo "✅ Gemini API key for AI task extraction"
    if grep -q "OPENAI_API_KEY=sk-" .env 2>/dev/null; then
        echo "✅ OpenAI API key for fallback processing"
    else
        echo "ℹ️  OpenAI API key (optional - can be added later)"
    fi
    echo ""
    echo -e "${YELLOW}🚀 Ready to deploy:${NC}"
    echo "1. Run: ./deploy-ai-enhanced.sh"
    echo "2. Wait for deployment to complete"
    echo "3. Open your TaskFlow AI application"
    echo "4. Try the AI task extraction feature!"
    echo ""
    echo -e "${CYAN}💡 Tips:${NC}"
    echo "• The .env file is ignored by git for security"
    echo "• You can edit .env manually anytime" 
    echo "• Redeploy after changing API keys"
}

# Main menu
main_menu() {
    while true; do
        echo ""
        print_header "TaskFlow AI - Environment Configuration"
        echo ""
        echo "1. Show current configuration"
        echo "2. Update API keys"
        echo "3. Test Gemini API key"
        echo "4. Exit"
        echo ""
        read -p "Choose an option (1-4): " choice
        
        case $choice in
            1)
                show_config
                ;;
            2)
                update_env_file
                display_next_steps
                ;;
            3)
                if [[ -f ".env" ]]; then
                    source .env
                    if [[ ! -z "$GEMINI_API_KEY" && "$GEMINI_API_KEY" != "your_gemini_api_key_here" ]]; then
                        test_gemini_key "$GEMINI_API_KEY"
                    else
                        print_warning "No Gemini API key found in .env file"
                    fi
                else
                    print_warning ".env file not found"
                fi
                ;;
            4)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                print_warning "Invalid option, please try again"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Main execution
main() {
    print_header "TaskFlow AI - Environment Setup"
    
    echo -e "${CYAN}This script helps you configure API keys for TaskFlow AI${NC}"
    echo ""
    
    # Check if .env exists and show status
    if check_env_file; then
        echo ""
        echo -e "${GREEN}✅ Your Gemini API key is already configured!${NC}"
        echo ""
        echo -e "${YELLOW}Options:${NC}"
        echo "1. Continue to deployment: ./deploy-ai-enhanced.sh"
        echo "2. Update configuration: choose option 2 below"
        echo "3. Test current key: choose option 3 below"
    else
        echo ""
        echo -e "${YELLOW}📝 Let's set up your .env configuration${NC}"
    fi
    
    main_menu
}

# Run main function
main "$@"

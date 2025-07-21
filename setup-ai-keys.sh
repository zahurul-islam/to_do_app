#!/bin/bash

# Setup script for TaskFlow AI API keys
# This script helps configure AI API keys after deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
REGION="us-west-2"
PROJECT_NAME="taskflow-ai"

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

# Function to setup Gemini API key
setup_gemini_key() {
    print_header "Setting up Google Gemini API Key"
    
    echo -e "${CYAN}Get your free API key from: ${YELLOW}https://makersuite.google.com/app/apikey${NC}"
    echo ""
    
    read -p "Do you want to configure Gemini API key? (y/n): " configure_gemini
    
    if [[ $configure_gemini == "y" || $configure_gemini == "Y" ]]; then
        read -s -p "Enter your Gemini API key: " GEMINI_KEY
        echo ""
        
        if [[ ! -z "$GEMINI_KEY" ]]; then
            print_status "Updating Gemini API key..."
            aws secretsmanager update-secret \
                --secret-id "$PROJECT_NAME-gemini-api-key" \
                --secret-string "$GEMINI_KEY" \
                --region "$REGION"
            print_success "Gemini API key updated"
        fi
    fi
}

# Function to setup OpenAI API key
setup_openai_key() {
    print_header "Setting up OpenAI API Key"
    
    echo -e "${CYAN}Get your API key from: ${YELLOW}https://platform.openai.com/api-keys${NC}"
    echo ""
    
    read -p "Do you want to configure OpenAI API key? (y/n): " configure_openai
    
    if [[ $configure_openai == "y" || $configure_openai == "Y" ]]; then
        read -s -p "Enter your OpenAI API key: " OPENAI_KEY
        echo ""
        
        if [[ ! -z "$OPENAI_KEY" ]]; then
            print_status "Updating OpenAI API key..."
            aws secretsmanager update-secret \
                --secret-id "$PROJECT_NAME-openai-api-key" \
                --secret-string "$OPENAI_KEY" \
                --region "$REGION"
            print_success "OpenAI API key updated"
        fi
    fi
}

# Main execution
main() {
    print_header "TaskFlow AI - API Keys Setup"
    
    echo -e "${CYAN}Configure AI API keys for enhanced functionality${NC}"
    echo ""
    
    setup_gemini_key
    setup_openai_key
    
    print_success "Setup completed!"
    echo ""
    echo -e "${YELLOW}Next: Open your TaskFlow AI application and try the AI extraction feature!${NC}"
}

main "$@"

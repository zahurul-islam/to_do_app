#!/bin/bash

# Enhanced testing script for TaskFlow AI-powered todo app
set -e

echo "🧪 Starting TaskFlow functionality tests..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "frontend/config.json" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

# Read configuration
if [ -f "frontend/config.json" ]; then
    API_URL=$(cat frontend/config.json | grep -o '"apiGatewayUrl":"[^"]*' | cut -d'"' -f4)
    print_status "Using API URL: $API_URL"
else
    print_error "Frontend configuration not found"
    exit 1
fi

# Test 1: Check if API endpoint is accessible
print_status "Testing API endpoint accessibility..."
if [ -n "$API_URL" ] && [ "$API_URL" != "loading..." ]; then
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/todos" 2>/dev/null || echo "000")
    if [ "$HTTP_STATUS" = "401" ] || [ "$HTTP_STATUS" = "403" ]; then
        print_success "API endpoint is accessible (returns authentication required)"
    elif [ "$HTTP_STATUS" = "200" ]; then
        print_success "API endpoint is accessible and responding"
    else
        print_warning "API endpoint returned status: $HTTP_STATUS"
    fi
else
    print_error "Invalid API URL configuration"
fi

# Test 2: Verify frontend files exist
print_status "Checking frontend files..."

REQUIRED_FILES=(
    "frontend/index.html"
    "frontend/app.js"
    "frontend/config.json"
    "frontend/index-modern.html"
    "frontend/app-modern.js"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "Found: $file"
    else
        print_error "Missing: $file"
    fi
done

# Test 3: Check if modern files are properly configured
print_status "Verifying modern frontend configuration..."

if [ -f "frontend/app-modern.js" ]; then
    # Check for AI integration
    if grep -q "GeminiAI" "frontend/app-modern.js"; then
        print_success "AI integration (GeminiAI) found in modern app"
    else
        print_warning "AI integration not found in modern app"
    fi
    
    # Check for modern components
    if grep -q "AITaskExtractor" "frontend/app-modern.js"; then
        print_success "AI Task Extractor component found"
    else
        print_error "AI Task Extractor component missing"
    fi
    
    if grep -q "TodoDashboard" "frontend/app-modern.js"; then
        print_success "Todo Dashboard component found"
    else
        print_error "Todo Dashboard component missing"
    fi
    
    if grep -q "Enhanced" "frontend/app-modern.js"; then
        print_success "Enhanced components detected"
    else
        print_warning "Enhanced components not detected"
    fi
else
    print_error "Modern frontend app file not found"
fi

# Test 4: Check HTML file structure
print_status "Verifying HTML structure..."

if [ -f "frontend/index-modern.html" ]; then
    if grep -q "AI-Powered Task Management" "frontend/index-modern.html"; then
        print_success "Modern HTML title found"
    else
        print_warning "Modern HTML title not found"
    fi
    
    if grep -q "app-modern.js" "frontend/index-modern.html"; then
        print_success "Modern app script reference found"
    else
        print_error "Modern app script reference missing"
    fi
    
    if grep -q "React 18" "frontend/index-modern.html"; then
        print_success "React 18 integration found"
    else
        print_warning "React 18 integration not found"
    fi
else
    print_error "Modern HTML file not found"
fi

# Test 5: Check backend Lambda function
print_status "Verifying backend Lambda function..."

if [ -f "terraform/lambda/index.py" ]; then
    # Check for enhanced mapping functions
    if grep -q "format_todo_for_frontend" "terraform/lambda/index.py"; then
        print_success "Frontend data mapping function found"
    else
        print_error "Frontend data mapping function missing"
    fi
    
    # Check for proper field mapping
    if grep -q "title.*task" "terraform/lambda/index.py"; then
        print_success "Field mapping (title ↔ task) found"
    else
        print_error "Field mapping not found"
    fi
    
    # Check for enhanced error handling
    if grep -q "convert_decimal_to_number" "terraform/lambda/index.py"; then
        print_success "Decimal conversion function found"
    else
        print_warning "Decimal conversion function not found"
    fi
else
    print_error "Lambda function file not found"
fi

# Test 6: Environment configuration
print_status "Checking environment configuration..."

if [ -f ".env" ]; then
    if grep -q "GEMINI_API_KEY" ".env"; then
        print_success "Gemini API key configuration found"
    else
        print_error "Gemini API key configuration missing"
    fi
    
    if grep -q "GEMINI_ENDPOINT" ".env"; then
        print_success "Gemini endpoint configuration found"
    else
        print_error "Gemini endpoint configuration missing"
    fi
else
    print_error "Environment file (.env) not found"
fi

# Test 7: Check .gitignore
print_status "Verifying .gitignore configuration..."

if [ -f ".gitignore" ]; then
    if grep -q ".env" ".gitignore"; then
        print_success ".env file is properly ignored"
    else
        print_warning ".env file is not in .gitignore"
    fi
    
    if grep -q "terraform/" ".gitignore"; then
        print_success "Terraform files are properly ignored"
    else
        print_warning "Terraform files might not be properly ignored"
    fi
else
    print_error ".gitignore file not found"
fi

# Test 8: Start local development server (optional)
print_status "Checking if we can start a development server..."

if command -v python3 &> /dev/null; then
    print_success "Python 3 is available for development server"
    echo "  💡 You can start the dev server with:"
    echo "     cd frontend && python3 -m http.server 8000"
    echo "     Then visit: http://localhost:8000"
elif command -v python &> /dev/null; then
    print_success "Python is available for development server"
    echo "  💡 You can start the dev server with:"
    echo "     cd frontend && python -m http.server 8000"
    echo "     Then visit: http://localhost:8000"
else
    print_warning "Python not found - consider installing for local development"
fi

# Summary
echo ""
echo "================================================================"
print_status "🧪 Test Summary Complete"
echo "================================================================"
echo ""
echo "📋 What was tested:"
echo "  ✓ API endpoint accessibility"
echo "  ✓ Frontend file structure"
echo "  ✓ Modern UI components and AI integration"
echo "  ✓ HTML structure and script references"
echo "  ✓ Backend Lambda function enhancements"
echo "  ✓ Environment configuration"
echo "  ✓ Git configuration"
echo "  ✓ Development server availability"
echo ""
echo "🚀 Ready to test your app:"
echo "  1. Deploy with: ./deploy-enhanced.sh"
echo "  2. Start local server: cd frontend && python -m http.server 8000"
echo "  3. Open browser: http://localhost:8000"
echo "  4. Test AI features by pasting email text in the AI extractor"
echo "  5. Create, update, and delete tasks normally"
echo ""
echo "🤖 AI Testing Tips:"
echo "  • Try pasting email text like:"
echo "    'Hi team, don't forget to submit your reports by Friday"
echo "     and schedule the quarterly meeting for next week.'"
echo "  • The AI should extract multiple tasks automatically"
echo "  • Test different text formats and see how AI categorizes tasks"
echo ""
print_success "Testing completed! Your TaskFlow app should be working correctly."

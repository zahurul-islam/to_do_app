#!/bin/bash

# Deploy Streamlined Authentication System
# This script replaces the complex auth flow with a seamless one

set -e

echo "🚀 Deploying Streamlined Authentication System"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project paths
PROJECT_ROOT="/home/zahurul/Documents/work/AWS_lab/capstone/aws_todo_app"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"

echo -e "${BLUE}📁 Working Directory: $PROJECT_ROOT${NC}"

# Function to print status
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Backup current files
echo -e "${BLUE}📋 Step 1: Creating backup of current authentication files${NC}"
BACKUP_DIR="$PROJECT_ROOT/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR/frontend"

# Backup original files
if [ -f "$FRONTEND_DIR/index.html" ]; then
    cp "$FRONTEND_DIR/index.html" "$BACKUP_DIR/frontend/index.html.backup"
    print_status "Backed up original index.html"
fi

if [ -f "$FRONTEND_DIR/app.js" ]; then
    cp "$FRONTEND_DIR/app.js" "$BACKUP_DIR/frontend/app.js.backup"
    print_status "Backed up original app.js"
fi

if [ -f "$FRONTEND_DIR/auth-complete.js" ]; then
    cp "$FRONTEND_DIR/auth-complete.js" "$BACKUP_DIR/frontend/auth-complete.js.backup"
    print_status "Backed up auth-complete.js"
fi

# Deploy new streamlined authentication
echo -e "${BLUE}📋 Step 2: Deploying streamlined authentication system${NC}"

# Replace main HTML file with streamlined version
if [ -f "$FRONTEND_DIR/index-flowless.html" ]; then
    cp "$FRONTEND_DIR/index-flowless.html" "$FRONTEND_DIR/index.html"
    print_status "Deployed streamlined index.html"
else
    print_error "index-flowless.html not found!"
    exit 1
fi

# Ensure the streamlined app.js is available
if [ -f "$FRONTEND_DIR/app-flowless.js" ]; then
    print_status "Streamlined app-flowless.js is ready"
else
    print_error "app-flowless.js not found!"
    exit 1
fi

# Verify Terraform configuration
echo -e "${BLUE}📋 Step 3: Verifying AWS infrastructure${NC}"
cd "$TERRAFORM_DIR"

if [ -f "terraform.tfstate" ]; then
    print_status "Terraform state found"
    
    # Check if resources exist
    if terraform show | grep -q "aws_cognito_user_pool.main"; then
        print_status "Cognito User Pool exists"
    else
        print_warning "Cognito User Pool may need to be created"
    fi
    
    if terraform show | grep -q "aws_api_gateway_rest_api.todos_api"; then
        print_status "API Gateway exists"
    else
        print_warning "API Gateway may need to be created"
    fi
else
    print_warning "No Terraform state found. Run terraform apply first."
fi

# Update frontend configuration
echo -e "${BLUE}📋 Step 4: Updating frontend configuration${NC}"
cd "$FRONTEND_DIR"

if [ -f "config.json" ]; then
    print_status "Frontend config.json exists"
    
    # Validate config.json structure
    if command -v jq >/dev/null 2>&1; then
        if jq empty config.json 2>/dev/null; then
            print_status "config.json is valid JSON"
            
            # Check required fields
            if jq -e '.userPoolId and .userPoolClientId and .apiGatewayUrl' config.json >/dev/null; then
                print_status "All required configuration fields present"
            else
                print_warning "Some configuration fields may be missing"
            fi
        else
            print_error "config.json is not valid JSON"
        fi
    else
        print_warning "jq not installed, skipping JSON validation"
    fi
else
    print_warning "config.json not found. Creating from Terraform outputs..."
    
    cd "$TERRAFORM_DIR"
    if [ -f "terraform.tfstate" ]; then
        cat > "$FRONTEND_DIR/config.json" << EOF
{
    "region": "$(terraform output -raw aws_region 2>/dev/null || echo 'us-west-2')",
    "userPoolId": "$(terraform output -raw cognito_user_pool_id 2>/dev/null || echo '')",
    "userPoolClientId": "$(terraform output -raw cognito_user_pool_client_id 2>/dev/null || echo '')",
    "apiGatewayUrl": "$(terraform output -raw api_gateway_url 2>/dev/null || echo '')"
}
EOF
        print_status "Created config.json from Terraform outputs"
    else
        print_error "Cannot create config.json without Terraform state"
    fi
    cd "$FRONTEND_DIR"
fi

# Test the new authentication system
echo -e "${BLUE}📋 Step 5: Testing streamlined authentication${NC}"

# Create a simple test file
cat > test-auth.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Auth Test</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 2rem; }
        .test { padding: 1rem; margin: 1rem 0; border-radius: 0.5rem; }
        .pass { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .fail { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
    </style>
</head>
<body>
    <h1>🧪 Streamlined Authentication Test</h1>
    <div id="results"></div>
    
    <script>
        async function runTests() {
            const results = document.getElementById('results');
            
            function addResult(message, type = 'info') {
                const div = document.createElement('div');
                div.className = `test ${type}`;
                div.textContent = message;
                results.appendChild(div);
            }
            
            // Test 1: Check if files exist
            try {
                const configResponse = await fetch('./config.json');
                if (configResponse.ok) {
                    addResult('✅ config.json is accessible', 'pass');
                    const config = await configResponse.json();
                    if (config.userPoolId && config.userPoolClientId) {
                        addResult('✅ Required AWS configuration found', 'pass');
                    } else {
                        addResult('❌ Missing required AWS configuration', 'fail');
                    }
                } else {
                    addResult('❌ config.json not found', 'fail');
                }
            } catch (error) {
                addResult(`❌ Error loading config: ${error.message}`, 'fail');
            }
            
            // Test 2: Check app-flowless.js
            try {
                const appResponse = await fetch('./app-flowless.js');
                if (appResponse.ok) {
                    addResult('✅ app-flowless.js is accessible', 'pass');
                } else {
                    addResult('❌ app-flowless.js not found', 'fail');
                }
            } catch (error) {
                addResult(`❌ Error loading app-flowless.js: ${error.message}`, 'fail');
            }
            
            // Test 3: Check React availability
            setTimeout(() => {
                if (typeof React !== 'undefined') {
                    addResult('✅ React is loaded', 'pass');
                } else {
                    addResult('❌ React not found', 'fail');
                }
                
                if (typeof ReactDOM !== 'undefined') {
                    addResult('✅ ReactDOM is loaded', 'pass');
                } else {
                    addResult('❌ ReactDOM not found', 'fail');
                }
            }, 2000);
        }
        
        // Load React for testing
        const script1 = document.createElement('script');
        script1.src = 'https://unpkg.com/react@18/umd/react.development.js';
        script1.onload = () => {
            const script2 = document.createElement('script');
            script2.src = 'https://unpkg.com/react-dom@18/umd/react-dom.development.js';
            script2.onload = runTests;
            document.head.appendChild(script2);
        };
        document.head.appendChild(script1);
    </script>
</body>
</html>
EOF

print_status "Created authentication test file"

# Start a simple HTTP server for testing (if Python is available)
echo -e "${BLUE}📋 Step 6: Starting local test server${NC}"

if command -v python3 >/dev/null 2>&1; then
    echo "Starting Python HTTP server on port 8080..."
    echo "Visit: http://localhost:8080/test-auth.html"
    echo "Visit: http://localhost:8080/ (main app)"
    echo ""
    echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
    echo ""
    
    # Start server in background and show URL
    python3 -m http.server 8080 &
    SERVER_PID=$!
    
    sleep 2
    echo -e "${GREEN}🌐 Test URLs:${NC}"
    echo "   Main App: http://localhost:8080/"
    echo "   Auth Test: http://localhost:8080/test-auth.html"
    echo ""
    echo -e "${BLUE}🔧 Testing Authentication Flow:${NC}"
    echo "1. Open http://localhost:8080/ in your browser"
    echo "2. Try signing up with a new email"
    echo "3. Check your email for verification code"
    echo "4. Complete the streamlined verification process"
    echo "5. Experience the seamless auto-login after verification"
    echo ""
    
    # Wait for user input
    read -p "Press Enter to stop the test server and continue..."
    kill $SERVER_PID 2>/dev/null || true
    
elif command -v python >/dev/null 2>&1; then
    echo "Starting Python 2 HTTP server on port 8080..."
    python -m SimpleHTTPServer 8080 &
    SERVER_PID=$!
    
    sleep 2
    echo -e "${GREEN}🌐 Server running at: http://localhost:8080/${NC}"
    read -p "Press Enter to stop the test server and continue..."
    kill $SERVER_PID 2>/dev/null || true
    
else
    print_warning "Python not found. Please start your own HTTP server to test."
    echo "Example: php -S localhost:8080 (if you have PHP)"
    echo "Or use any other local server"
fi

# Clean up test file
rm -f test-auth.html

# Summary
echo -e "${BLUE}📋 Step 7: Deployment Summary${NC}"
echo ""
echo -e "${GREEN}🎉 Streamlined Authentication System Deployed Successfully!${NC}"
echo ""
echo -e "${BLUE}📁 Backup Location:${NC} $BACKUP_DIR"
echo -e "${BLUE}🌐 Frontend Directory:${NC} $FRONTEND_DIR"
echo -e "${BLUE}⚙️  Terraform Directory:${NC} $TERRAFORM_DIR"
echo ""
echo -e "${GREEN}✨ Key Improvements:${NC}"
echo "   • Simplified signup process with auto-verification prompts"
echo "   • Streamlined error handling with user-friendly messages" 
echo "   • Automatic sign-in after email verification"
echo "   • Reduced authentication steps and complexity"
echo "   • Enhanced UX with better loading states and transitions"
echo ""
echo -e "${YELLOW}🔧 Next Steps:${NC}"
echo "1. Test the authentication flow in your browser"
echo "2. Verify email verification works end-to-end"  
echo "3. Test both signup and signin scenarios"
echo "4. Deploy to your hosting service when ready"
echo ""
echo -e "${BLUE}🚀 Ready to go! Your authentication is now flowless.${NC}"

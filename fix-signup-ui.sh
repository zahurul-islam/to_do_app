#!/bin/bash

# Fix Missing Signup UI in Production
# Deploy complete authentication system with signup functionality

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Fixing Missing Signup UI in Production${NC}"
echo "============================================="
echo ""

# Get current infrastructure details
echo -e "${BLUE}📋 Getting deployment configuration...${NC}"
cd terraform
BUCKET_NAME=$(terraform output -raw frontend_bucket_name)
CLOUDFRONT_ID=$(terraform output -raw cloudfront_distribution_id)
CLOUDFRONT_URL=$(terraform output -raw website_url)
cd ..

echo -e "${GREEN}✅ S3 Bucket: $BUCKET_NAME${NC}"
echo -e "${GREEN}✅ CloudFront: $CLOUDFRONT_ID${NC}"
echo -e "${GREEN}✅ Website: $CLOUDFRONT_URL${NC}"
echo ""

# The problem: index.html is loading app-fixed.js instead of app-enhanced.js
echo -e "${YELLOW}🐛 Problem Identified:${NC}"
echo "   Current index.html loads 'app-fixed.js' (login only)"
echo "   Need to load 'app-enhanced.js' (complete auth with signup)"
echo ""

# Create fixed index.html that loads app-enhanced.js
echo -e "${BLUE}🔧 Creating index.html with complete authentication...${NC}"

cat > frontend/index-with-signup.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TaskFlow - Neufische Todo App</title>
    <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>✓</text></svg>">
    
    <!-- Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
    
    <!-- Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    
    <!-- React 18 -->
    <script crossorigin src="https://unpkg.com/react@18/umd/react.development.js"></script>
    <script crossorigin src="https://unpkg.com/react-dom@18/umd/react-dom.development.js"></script>
    
    <!-- AWS SDK and Cognito -->
    <script src="https://sdk.amazonaws.com/js/aws-sdk-2.1396.0.min.js"></script>
    <script src="https://unpkg.com/amazon-cognito-identity-js@6.3.6/dist/amazon-cognito-identity.min.js"></script>
    
    <!-- AWS Amplify Configuration Setup -->
    <script>
        window.addEventListener('load', () => {
            setTimeout(() => {
                console.log('🔍 Setting up AWS Amplify authentication...');
                
                // Create a manual Amplify-like interface using AWS SDK and Cognito
                window.aws_amplify = {
                    Amplify: {
                        configure: (config) => {
                            console.log('✅ AWS Cognito configured with:', config);
                            window.COGNITO_CONFIG = config.Auth;
                            
                            // Setup AWS region
                            window.AWS.config.region = config.Auth.region;
                            
                            // Create Cognito User Pool
                            const poolData = {
                                UserPoolId: config.Auth.userPoolId,
                                ClientId: config.Auth.userPoolWebClientId
                            };
                            window.COGNITO_USER_POOL = new window.AmazonCognitoIdentity.CognitoUserPool(poolData);
                            console.log('✅ Cognito User Pool initialized');
                        }
                    },
                    Auth: {
                        currentAuthenticatedUser: () => {
                            return new Promise((resolve, reject) => {
                                const cognitoUser = window.COGNITO_USER_POOL.getCurrentUser();
                                if (cognitoUser) {
                                    cognitoUser.getSession((err, session) => {
                                        if (err) {
                                            reject(err);
                                        } else if (session.isValid()) {
                                            resolve(cognitoUser);
                                        } else {
                                            reject(new Error('Session invalid'));
                                        }
                                    });
                                } else {
                                    reject(new Error('No current user'));
                                }
                            });
                        },
                        signUp: (signUpData) => {
                            return new Promise((resolve, reject) => {
                                const { username, password, attributes } = signUpData;
                                const attributeList = [];
                                
                                if (attributes && attributes.email) {
                                    const emailAttr = new window.AmazonCognitoIdentity.CognitoUserAttribute({
                                        Name: 'email',
                                        Value: attributes.email
                                    });
                                    attributeList.push(emailAttr);
                                }
                                
                                window.COGNITO_USER_POOL.signUp(username, password, attributeList, null, (err, result) => {
                                    if (err) {
                                        reject(err);
                                    } else {
                                        resolve(result);
                                    }
                                });
                            });
                        },
                        signIn: (username, password) => {
                            return new Promise((resolve, reject) => {
                                const authenticationData = {
                                    Username: username,
                                    Password: password
                                };
                                
                                const authenticationDetails = new window.AmazonCognitoIdentity.AuthenticationDetails(authenticationData);
                                const userData = {
                                    Username: username,
                                    Pool: window.COGNITO_USER_POOL
                                };
                                
                                const cognitoUser = new window.AmazonCognitoIdentity.CognitoUser(userData);
                                
                                cognitoUser.authenticateUser(authenticationDetails, {
                                    onSuccess: (result) => {
                                        resolve(cognitoUser);
                                    },
                                    onFailure: (err) => {
                                        reject(err);
                                    }
                                });
                            });
                        },
                        signOut: () => {
                            return new Promise((resolve) => {
                                const cognitoUser = window.COGNITO_USER_POOL.getCurrentUser();
                                if (cognitoUser) {
                                    cognitoUser.signOut();
                                }
                                resolve();
                            });
                        },
                        currentSession: () => {
                            return new Promise((resolve, reject) => {
                                const cognitoUser = window.COGNITO_USER_POOL.getCurrentUser();
                                if (cognitoUser) {
                                    cognitoUser.getSession((err, session) => {
                                        if (err) {
                                            reject(err);
                                        } else {
                                            resolve(session);
                                        }
                                    });
                                } else {
                                    reject(new Error('No current user'));
                                }
                            });
                        },
                        confirmSignUp: (username, confirmationCode) => {
                            return new Promise((resolve, reject) => {
                                console.log('🔄 Confirming signup for:', username, 'with code:', confirmationCode);
                                
                                const userData = {
                                    Username: username,
                                    Pool: window.COGNITO_USER_POOL
                                };
                                
                                const cognitoUser = new window.AmazonCognitoIdentity.CognitoUser(userData);
                                
                                cognitoUser.confirmRegistration(confirmationCode, true, (err, result) => {
                                    if (err) {
                                        console.error('❌ Confirmation failed:', err);
                                        reject(err);
                                    } else {
                                        console.log('✅ Email confirmed successfully:', result);
                                        resolve(result);
                                    }
                                });
                            });
                        },
                        resendConfirmationCode: (username) => {
                            return new Promise((resolve, reject) => {
                                console.log('🔄 Resending confirmation code for:', username);
                                
                                const userData = {
                                    Username: username,
                                    Pool: window.COGNITO_USER_POOL
                                };
                                
                                const cognitoUser = new window.AmazonCognitoIdentity.CognitoUser(userData);
                                
                                cognitoUser.resendConfirmationCode((err, result) => {
                                    if (err) {
                                        console.error('❌ Resend failed:', err);
                                        reject(err);
                                    } else {
                                        console.log('✅ Confirmation code resent:', result);
                                        resolve(result);
                                    }
                                });
                            });
                        }
                    }
                };
                console.log('✅ AWS authentication interface ready with full signup support');
            }, 100);
        });
    </script>    
    <style>
        :root {
            /* Neufische Brand Colors */
            --primary-coral: #FF6B6B;
            --primary-coral-dark: #E55A5A;
            --secondary-teal: #4ECDC4;
            
            /* Neutral Colors */
            --gray-50: #F8FAFC;
            --gray-100: #F1F5F9;
            --gray-200: #E2E8F0;
            --gray-300: #CBD5E1;
            --gray-500: #64748B;
            --gray-600: #475569;
            --gray-700: #334155;
            --gray-800: #1E293B;
            
            /* Semantic Colors */
            --success: #22C55E;
            --warning: #F59E0B;
            --error: #EF4444;
            --info: #3B82F6;
            
            /* Design System */
            --font-primary: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
            --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
            --shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
            --transition-fast: 0.15s ease-out;
            --radius-lg: 0.75rem;
            --radius-xl: 1rem;
            --radius-2xl: 1.5rem;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: var(--font-primary);
            background: linear-gradient(135deg, var(--gray-50) 0%, var(--gray-100) 100%);
            min-height: 100vh;
            color: var(--gray-800);
            line-height: 1.6;
        }
        
        .app-container {
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }
        
        /* Loading States */
        .loading-state {
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            background: var(--gray-50);
        }
        
        .loading-content {
            text-align: center;
        }
        
        .loading-spinner {
            width: 48px;
            height: 48px;
            border: 4px solid var(--gray-200);
            border-top: 4px solid var(--primary-coral);
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin: 0 auto 1rem;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        /* Button Styles */
        .btn {
            padding: 0.75rem 1.5rem;
            border: none;
            border-radius: var(--radius-lg);
            font-weight: 600;
            font-size: 0.875rem;
            cursor: pointer;
            transition: all var(--transition-fast);
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            text-decoration: none;
            font-family: var(--font-primary);
        }
        
        .btn-primary {
            background: var(--primary-coral);
            color: white;
            box-shadow: var(--shadow-md);
        }
        
        .btn-primary:hover {
            background: var(--primary-coral-dark);
            transform: translateY(-2px);
            box-shadow: var(--shadow-lg);
        }
        
        /* Form Styles */
        .form-input {
            width: 100%;
            padding: 0.875rem 1rem;
            border: 2px solid var(--gray-200);
            border-radius: var(--radius-lg);
            font-size: 0.875rem;
            transition: border-color var(--transition-fast), box-shadow var(--transition-fast);
            background: white;
            color: var(--gray-800);
            font-family: inherit;
        }
        
        .form-input:focus {
            outline: none;
            border-color: var(--primary-coral);
            box-shadow: 0 0 0 3px rgba(255, 107, 107, 0.1);
        }
        
        /* Error Styles */
        .error-message {
            background: var(--error);
            color: white;
            padding: 1rem;
            border-radius: var(--radius-lg);
            margin-bottom: 1.5rem;
            font-size: 0.875rem;
        }
    </style>
</head>
<body>
    <div id="root">
        <div class="loading-state">
            <div class="loading-content">
                <div class="loading-spinner"></div>
                <p style="color: var(--gray-600); font-family: var(--font-primary);">Loading TaskFlow...</p>
            </div>
        </div>
    </div>

    <!-- React 18 Application Mounting -->
    <script type="module">
        // Wait for all dependencies to load
        window.addEventListener('load', () => {
            setTimeout(() => {
                // Check if React 18 is available
                if (typeof React !== 'undefined' && typeof ReactDOM !== 'undefined' && ReactDOM.createRoot) {
                    console.log('✅ React 18 detected, using createRoot');
                    
                    // Load and mount the application - IMPORTANT: Load app-enhanced.js for complete authentication
                    const script = document.createElement('script');
                    script.src = './app-enhanced.js';  // This file has complete signup UI
                    script.onload = () => {
                        // Mount with React 18 createRoot API
                        const container = document.getElementById('root');
                        const root = ReactDOM.createRoot(container);
                        
                        if (window.TodoApp) {
                            root.render(React.createElement(window.TodoApp));
                            console.log('✅ TaskFlow app mounted successfully with complete authentication');
                        } else {
                            console.error('❌ TodoApp component not found');
                            container.innerHTML = `
                                <div class="loading-state">
                                    <div class="loading-content">
                                        <p style="color: var(--error);">Failed to load application. Please refresh the page.</p>
                                    </div>
                                </div>
                            `;
                        }
                    };
                    script.onerror = () => {
                        console.error('❌ Failed to load app-enhanced.js');
                        const container = document.getElementById('root');
                        container.innerHTML = `
                            <div class="loading-state">
                                <div class="loading-content">
                                    <p style="color: var(--error);">Failed to load application files. Please check your connection.</p>
                                </div>
                            </div>
                        `;
                    };
                    document.head.appendChild(script);
                } else {
                    console.error('❌ React 18 not available');
                    document.getElementById('root').innerHTML = `
                        <div class="loading-state">
                            <div class="loading-content">
                                <p style="color: var(--error);">React 18 is required but not available. Please check your connection.</p>
                            </div>
                        </div>
                    `;
                }
            }, 1000); // Give time for AWS setup
        });
    </script>
</body>
</html>
EOF

echo -e "${GREEN}✅ Created index.html with complete authentication${NC}"
echo ""

# Create the config.json file
echo -e "${BLUE}🔧 Creating configuration file...${NC}"
cd terraform
cat > ../frontend/config.json << EOF
{
  "apiGatewayUrl": "$(terraform output -raw api_gateway_url)",
  "region": "$(terraform output -raw aws_region)",
  "userPoolClientId": "$(terraform output -raw cognito_user_pool_client_id)",
  "userPoolId": "$(terraform output -raw cognito_user_pool_id)"
}
EOF
cd ..

echo -e "${GREEN}✅ Created config.json with current AWS settings${NC}"
echo ""

# Deploy all files
echo -e "${BLUE}📤 Deploying complete authentication system...${NC}"

# Deploy index.html (load app-enhanced.js)
aws s3 cp frontend/index-with-signup.html s3://$BUCKET_NAME/index.html \
    --content-type "text/html" \
    --cache-control "max-age=300"

# Deploy app-enhanced.js (complete auth system)
aws s3 cp frontend/app-enhanced.js s3://$BUCKET_NAME/app-enhanced.js \
    --content-type "application/javascript" \
    --cache-control "max-age=3600"

# Deploy config.json (AWS configuration)
aws s3 cp frontend/config.json s3://$BUCKET_NAME/config.json \
    --content-type "application/json" \
    --cache-control "max-age=300"

echo -e "${GREEN}✅ All files deployed to S3${NC}"
echo ""

# Invalidate CloudFront cache
echo -e "${BLUE}🔄 Invalidating CloudFront cache...${NC}"
INVALIDATION_ID=$(aws cloudfront create-invalidation \
    --distribution-id $CLOUDFRONT_ID \
    --paths "/*" \
    --query 'Invalidation.Id' \
    --output text)

echo -e "${GREEN}✅ CloudFront cache invalidation initiated: $INVALIDATION_ID${NC}"
echo ""

# Clean up temporary files
rm frontend/index-with-signup.html

echo -e "${GREEN}🎉 Signup UI Fix Deployed Successfully!${NC}"
echo ""
echo "📋 What's fixed:"
echo "  ✅ index.html now loads app-enhanced.js (complete auth)"
echo "  ✅ Signup UI with 'Create an account' link"
echo "  ✅ Complete email verification flow"
echo "  ✅ Configuration file with current AWS settings"
echo "  ✅ All authentication methods available"
echo ""
echo "🧪 Test the signup functionality:"
echo "  1. Go to: $CLOUDFRONT_URL"
echo "  2. Look for 'Create an account' link below login form"
echo "  3. Click to access signup form"
echo "  4. Test complete registration flow"
echo ""
echo -e "${YELLOW}⏳ Cache propagation: 5-15 minutes${NC}"
echo -e "${YELLOW}💡 If changes aren't visible immediately, wait for CloudFront cache update${NC}"
echo ""


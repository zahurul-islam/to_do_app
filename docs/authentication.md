# Authentication Implementation Guide

## Overview

This document provides a comprehensive guide to the authentication system implemented in the Serverless Todo Application. The system uses Amazon Cognito User Pools for secure user authentication and authorization, with API Gateway integration for protecting backend resources.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Amazon Cognito Configuration](#amazon-cognito-configuration)
3. [API Gateway Authorization](#api-gateway-authorization)
4. [Frontend Authentication](#frontend-authentication)
5. [Backend Token Validation](#backend-token-validation)
6. [Security Features](#security-features)
7. [Testing Authentication](#testing-authentication)
8. [Troubleshooting](#troubleshooting)

## Architecture Overview

### Authentication Flow Diagram

```
┌─────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Browser   │    │  Amazon Cognito │    │  API Gateway    │
│  (Frontend) │    │  User Pools     │    │  + Authorizer   │
└─────────────┘    └─────────────────┘    └─────────────────┘
       │                      │                      │
       │  1. Sign up/Sign in  │                      │
       ├─────────────────────►│                      │
       │                      │                      │
       │  2. JWT Tokens       │                      │
       │◄─────────────────────┤                      │
       │                      │                      │
       │  3. API Request      │                      │
       │  (with JWT token)    │                      │
       ├──────────────────────┼─────────────────────►│
       │                      │                      │
       │                      │  4. Validate Token  │
       │                      │◄─────────────────────┤
       │                      │                      │
       │                      │  5. Token Valid     │
       │                      ├─────────────────────►│
       │                      │                      │
       │  6. API Response     │                      │
       │◄─────────────────────┼──────────────────────┤
       │                      │                      │
```

### Key Components

1. **Amazon Cognito User Pool** - Manages user identities and authentication
2. **Cognito User Pool Client** - Application configuration for accessing the user pool
3. **API Gateway Authorizer** - Validates JWT tokens for API requests
4. **Frontend Authentication** - React-based authentication UI and logic
5. **Backend Token Processing** - Lambda functions extract user context from validated tokens

## Amazon Cognito Configuration

### User Pool Configuration

The Cognito User Pool is configured with the following security features:

```hcl
resource "aws_cognito_user_pool" "main" {
  name = var.cognito_user_pool_name

  # Email-based authentication
  username_attributes = ["email"]
  alias_attributes    = ["email"]

  # Strong password policy
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = false
    temporary_password_validity_days = 7
  }

  # Email verification required
  auto_verified_attributes = ["email"]
  
  # Advanced security features
  user_pool_add_ons {
    advanced_security_mode = "AUDIT"  # Use ENFORCED for production
  }
}
```

### Key Security Features

#### 1. **Strong Password Policy**
- Minimum 8 characters
- Requires uppercase and lowercase letters
- Requires numbers
- Temporary passwords expire in 7 days

#### 2. **Email Verification**
- All users must verify their email addresses
- Custom verification messages
- Automatic email verification on sign-up

#### 3. **Advanced Security Mode**
- Risk-based authentication
- Suspicious activity detection
- Compromised credentials detection

#### 4. **Account Recovery**
- Email-based password recovery
- Secure recovery mechanisms

### User Pool Client Configuration

```hcl
resource "aws_cognito_user_pool_client" "main" {
  name         = var.cognito_user_pool_client_name
  user_pool_id = aws_cognito_user_pool.main.id

  # Security configuration
  generate_secret                      = false  # For frontend apps
  prevent_user_existence_errors        = "ENABLED"
  enable_token_revocation              = true

  # Authentication flows
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",  # Username/password authentication
    "ALLOW_REFRESH_TOKEN_AUTH",  # Token refresh
    "ALLOW_USER_SRP_AUTH"        # Secure Remote Password protocol
  ]

  # Token validity
  access_token_validity  = 1   # 1 hour
  id_token_validity      = 1   # 1 hour
  refresh_token_validity = 30  # 30 days
}
```

### Token Configuration

| Token Type | Validity | Purpose |
|------------|----------|---------|
| **Access Token** | 1 hour | API authorization |
| **ID Token** | 1 hour | User identity information |
| **Refresh Token** | 30 days | Token renewal |

## API Gateway Authorization

### Cognito Authorizer Configuration

```hcl
resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name                             = "cognito-authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.todos_api.id
  type                             = "COGNITO_USER_POOLS"
  provider_arns                    = [aws_cognito_user_pool.main.arn]
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = 300  # Cache for 5 minutes
}
```

### Protected API Methods

All API methods are protected with Cognito authorization:

```hcl
resource "aws_api_gateway_method" "get_todos" {
  rest_api_id   = aws_api_gateway_rest_api.todos_api.id
  resource_id   = aws_api_gateway_resource.todos_resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}
```

### API Endpoints Protection

| Endpoint | Method | Protection | Purpose |
|----------|--------|------------|---------|
| `/todos` | GET | ✅ Cognito Auth | Retrieve user's todos |
| `/todos` | POST | ✅ Cognito Auth | Create new todo |
| `/todos/{id}` | GET | ✅ Cognito Auth | Get specific todo |
| `/todos/{id}` | PUT | ✅ Cognito Auth | Update todo |
| `/todos/{id}` | DELETE | ✅ Cognito Auth | Delete todo |
| `/todos` | OPTIONS | ❌ No Auth | CORS preflight |
| `/todos/{id}` | OPTIONS | ❌ No Auth | CORS preflight |

## Frontend Authentication

### Authentication Hook

The frontend uses a comprehensive React hook for authentication:

```javascript
const useAuth = () => {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    
    // Authentication methods
    const signUp = useCallback(async (email, password) => { /* ... */ });
    const signIn = useCallback(async (email, password) => { /* ... */ });
    const signOut = useCallback(async () => { /* ... */ });
    const confirmSignUp = useCallback(async (email, code) => { /* ... */ });
    
    return {
        user, loading, error,
        signUp, signIn, signOut, confirmSignUp,
        isAuthenticated: !!user
    };
};
```

### Key Features

#### 1. **Sign Up Process**
```javascript
const signUp = async (email, password) => {
    try {
        const result = await aws_amplify.Auth.signUp({
            username: email,
            password: password,
            attributes: { email: email }
        });
        
        return { 
            success: true, 
            requiresVerification: !result.userConfirmed 
        };
    } catch (error) {
        return { success: false, error: getErrorMessage(error) };
    }
};
```

#### 2. **Sign In Process**
```javascript
const signIn = async (email, password) => {
    try {
        const user = await aws_amplify.Auth.signIn(email, password);
        setUser(user);
        return { success: true, user: user };
    } catch (error) {
        return { success: false, error: getErrorMessage(error) };
    }
};
```

#### 3. **Token Management**
```javascript
const getCurrentSession = async () => {
    try {
        const session = await aws_amplify.Auth.currentSession();
        return {
            accessToken: session.getAccessToken().getJwtToken(),
            idToken: session.getIdToken().getJwtToken(),
            refreshToken: session.getRefreshToken().getToken()
        };
    } catch (error) {
        return { success: false, error: error.message };
    }
};
```

### API Integration

All API calls include the JWT token in the Authorization header:

```javascript
const apiCall = async (endpoint, method = 'GET', data = null) => {
    const session = await aws_amplify.Auth.currentSession();
    const token = session.getIdToken().getJwtToken();
    
    const config = {
        method: method,
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
        }
    };
    
    const response = await fetch(`${API_URL}${endpoint}`, config);
    return await response.json();
};
```

## Backend Token Validation

### Lambda Function User Context

The Lambda function extracts user information from the validated JWT token:

```python
def get_user_id_from_event(event):
    """Extract user ID from Cognito claims in the event"""
    try:
        authorizer_context = event.get('requestContext', {}).get('authorizer', {})
        claims = authorizer_context.get('claims', {})
        user_id = claims.get('sub', claims.get('cognito:username', 'anonymous'))
        return user_id
    except Exception as e:
        print(f"Error extracting user ID: {str(e)}")
        return 'anonymous'
```

### Data Isolation

Each user's data is isolated using the user ID as a partition key:

```python
def get_todos(user_id, query_parameters):
    """Get all todos for a specific user"""
    response = table.query(
        KeyConditionExpression='user_id = :user_id',
        ExpressionAttributeValues={
            ':user_id': user_id
        }
    )
    return response.get('Items', [])
```

### Security Validation

```python
def lambda_handler(event, context):
    """Main Lambda handler with user validation"""
    try:
        # Get user ID from validated token
        user_id = get_user_id_from_event(event)
        
        # Ensure user is authenticated
        if user_id == 'anonymous':
            return create_error_response(401, 'Unauthorized')
        
        # Process request with user context
        return process_request(user_id, event)
    except Exception as e:
        return create_error_response(500, 'Internal Server Error')
```

## Security Features

### 1. **Token-Based Authentication**
- JWT tokens for stateless authentication
- Short-lived access tokens (1 hour)
- Long-lived refresh tokens (30 days)
- Automatic token refresh

### 2. **Password Security**
- Strong password requirements
- Secure password hashing (handled by Cognito)
- Password complexity validation
- Account lockout protection

### 3. **Email Verification**
- Required email verification for all users
- Verification code expiration
- Resend verification capabilities

### 4. **API Protection**
- All API endpoints require authentication
- Token validation on every request
- User data isolation
- Rate limiting and throttling

### 5. **CORS Security**
- Proper CORS headers configuration
- Origin validation
- Preflight request handling

### 6. **Error Handling**
- No user enumeration vulnerabilities
- Generic error messages
- Proper error logging
- Rate limiting on authentication attempts

## Testing Authentication

### Automated Testing

Run the comprehensive authentication test suite:

```bash
./test-auth.sh
```

This script tests:
- ✅ Infrastructure deployment
- ✅ Cognito configuration
- ✅ API Gateway authorization
- ✅ Security policies
- ✅ Frontend integration
- ✅ Manual authentication flow

### Manual Testing Checklist

#### 1. **User Registration**
- [ ] Sign up with valid email and password
- [ ] Receive verification email
- [ ] Verify email with correct code
- [ ] Handle invalid verification codes
- [ ] Resend verification code functionality

#### 2. **User Sign In**
- [ ] Sign in with verified credentials
- [ ] Handle invalid credentials
- [ ] Handle unverified email
- [ ] Token refresh functionality
- [ ] Session persistence

#### 3. **API Access**
- [ ] Authenticated API calls succeed
- [ ] Unauthenticated API calls return 401
- [ ] Invalid tokens return 401
- [ ] Expired tokens trigger refresh
- [ ] User data isolation

#### 4. **User Sign Out**
- [ ] Sign out clears session
- [ ] Redirect to login page
- [ ] Token invalidation
- [ ] Unable to access protected resources

### Security Testing

#### 1. **Authentication Bypass Testing**
```bash
# Test unauthenticated access (should return 401)
curl -X GET https://your-api-url.com/todos

# Test with invalid token (should return 401)
curl -X GET https://your-api-url.com/todos \
  -H "Authorization: Bearer invalid-token"
```

#### 2. **Password Policy Testing**
- [ ] Weak passwords rejected
- [ ] Common passwords rejected
- [ ] Password complexity enforced
- [ ] Minimum length enforced

#### 3. **Token Security Testing**
- [ ] Token expiration handling
- [ ] Token refresh mechanism
- [ ] Invalid token rejection
- [ ] Token replay protection

## Troubleshooting

### Common Issues

#### 1. **"User does not exist" Error**
**Cause**: User has not completed email verification
**Solution**: Check email for verification code and complete verification

#### 2. **"Invalid verification code" Error**
**Cause**: Code expired or incorrect
**Solution**: Request new verification code

#### 3. **API Returns 401 Unauthorized**
**Possible Causes**:
- User not signed in
- Token expired
- Invalid token
- API Gateway misconfiguration

**Debugging Steps**:
```bash
# Check Cognito User Pool configuration
aws cognito-idp describe-user-pool --user-pool-id YOUR_USER_POOL_ID

# Check API Gateway authorizer
aws apigateway get-authorizers --rest-api-id YOUR_API_ID

# Test token validity
aws cognito-idp get-user --access-token YOUR_ACCESS_TOKEN
```

#### 4. **CORS Errors in Browser**
**Cause**: CORS headers not properly configured
**Solution**: Verify CORS configuration in API Gateway

#### 5. **Frontend Authentication Not Working**
**Debugging Steps**:
1. Check browser console for JavaScript errors
2. Verify AWS configuration in frontend
3. Check network tab for API calls
4. Verify Cognito User Pool and Client IDs

### Configuration Verification

#### 1. **Cognito Configuration**
```bash
# Get User Pool details
aws cognito-idp describe-user-pool --user-pool-id YOUR_USER_POOL_ID

# Get User Pool Client details
aws cognito-idp describe-user-pool-client \
  --user-pool-id YOUR_USER_POOL_ID \
  --client-id YOUR_CLIENT_ID
```

#### 2. **API Gateway Configuration**
```bash
# List authorizers
aws apigateway get-authorizers --rest-api-id YOUR_API_ID

# Get method details
aws apigateway get-method \
  --rest-api-id YOUR_API_ID \
  --resource-id YOUR_RESOURCE_ID \
  --http-method GET
```

#### 3. **Lambda Configuration**
```bash
# Check Lambda environment variables
aws lambda get-function-configuration --function-name YOUR_FUNCTION_NAME
```

## Best Practices

### 1. **Security Best Practices**
- Use strong password policies
- Enable email verification
- Implement proper error handling
- Use short-lived access tokens
- Enable advanced security features
- Monitor for suspicious activity

### 2. **Development Best Practices**
- Test authentication thoroughly
- Handle all error scenarios
- Implement proper loading states
- Use secure token storage
- Validate tokens on the backend
- Implement proper session management

### 3. **Production Considerations**
- Enable advanced security mode in Cognito
- Set up monitoring and alerting
- Implement rate limiting
- Use HTTPS everywhere
- Regular security audits
- Backup and recovery procedures

## Conclusion

The authentication system provides robust security for the Serverless Todo Application using AWS best practices. The combination of Amazon Cognito User Pools, API Gateway authorization, and proper frontend integration ensures secure user authentication and data protection.

Key achievements:
- ✅ Secure user registration and verification
- ✅ Strong password policies
- ✅ JWT token-based authentication
- ✅ Protected API endpoints
- ✅ User data isolation
- ✅ Comprehensive error handling
- ✅ CORS security
- ✅ Automated testing

The system is production-ready and follows AWS security best practices while remaining within Free Tier limits.

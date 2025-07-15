// Enhanced Authentication Module for Todo App
// This file provides comprehensive authentication functionality

// AWS Configuration - Enhanced with validation
const AWS_CONFIG = {
    region: 'us-west-2',
    userPoolId: 'us-west-2_XXXXXXXXX',
    userPoolClientId: 'XXXXXXXXXXXXXXXXXXXXXXXXXX',
    apiGatewayUrl: 'https://XXXXXXXXXX.execute-api.us-west-2.amazonaws.com/prod',
    
    // Validation function
    isValid() {
        return this.userPoolId !== 'us-west-2_XXXXXXXXX' && 
               this.userPoolClientId !== 'XXXXXXXXXXXXXXXXXXXXXXXXXX' &&
               this.apiGatewayUrl !== 'https://XXXXXXXXXX.execute-api.us-west-2.amazonaws.com/prod';
    }
};

// Initialize AWS Amplify with enhanced error handling
const initializeAmplify = () => {
    try {
        if (typeof aws_amplify !== 'undefined' && AWS_CONFIG.isValid()) {
            aws_amplify.Amplify.configure({
                Auth: {
                    region: AWS_CONFIG.region,
                    userPoolId: AWS_CONFIG.userPoolId,
                    userPoolWebClientId: AWS_CONFIG.userPoolClientId,
                    // Enhanced configuration
                    authenticationFlowType: 'USER_PASSWORD_AUTH',
                    cookieStorage: {
                        domain: window.location.hostname,
                        path: '/',
                        expires: 365,
                        secure: window.location.protocol === 'https:'
                    }
                }
            });
            console.log('✅ AWS Amplify initialized successfully');
            return true;
        } else {
            console.warn('⚠️ AWS Amplify not available or configuration incomplete');
            return false;
        }
    } catch (error) {
        console.error('❌ Failed to initialize AWS Amplify:', error);
        return false;
    }
};

// Initialize on load
const amplifyInitialized = initializeAmplify();

const { useState, useEffect, useCallback } = React;

// Enhanced Authentication Hook with comprehensive error handling
const useAuth = () => {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [isInitialized, setIsInitialized] = useState(amplifyInitialized);

    // Check current user on mount
    useEffect(() => {
        checkUser();
    }, []);

    const checkUser = useCallback(async () => {
        try {
            setLoading(true);
            setError(null);
            
            if (!isInitialized) {
                throw new Error('Authentication service not initialized');
            }

            const currentUser = await aws_amplify.Auth.currentAuthenticatedUser();
            setUser(currentUser);
            console.log('✅ User authenticated:', currentUser.username);
        } catch (error) {
            if (error.message !== 'The user is not authenticated') {
                console.log('ℹ️ No authenticated user found');
            } else {
                console.error('❌ Error checking authentication:', error);
                setError('Failed to check authentication status');
            }
            setUser(null);
        } finally {
            setLoading(false);
        }
    }, [isInitialized]);

    // Enhanced sign up function
    const signUp = useCallback(async (email, password, additionalInfo = {}) => {
        try {
            setLoading(true);
            setError(null);

            if (!isInitialized) {
                throw new Error('Authentication service not initialized');
            }

            // Validate inputs
            if (!email || !email.includes('@')) {
                throw new Error('Please enter a valid email address');
            }

            if (!password || password.length < 8) {
                throw new Error('Password must be at least 8 characters long');
            }

            const signUpData = {
                username: email,
                password: password,
                attributes: {
                    email: email,
                    ...additionalInfo
                }
            };

            const result = await aws_amplify.Auth.signUp(signUpData);
            
            console.log('✅ Sign up successful:', result);
            return { 
                success: true, 
                requiresVerification: !result.userConfirmed,
                userSub: result.userSub
            };
        } catch (error) {
            console.error('❌ Sign up failed:', error);
            const errorMessage = getErrorMessage(error);
            setError(errorMessage);
            return { success: false, error: errorMessage };
        } finally {
            setLoading(false);
        }
    }, [isInitialized]);

    // Enhanced sign in function
    const signIn = useCallback(async (email, password) => {
        try {
            setLoading(true);
            setError(null);

            if (!isInitialized) {
                throw new Error('Authentication service not initialized');
            }

            // Validate inputs
            if (!email || !password) {
                throw new Error('Email and password are required');
            }

            const user = await aws_amplify.Auth.signIn(email, password);
            
            // Handle different challenge scenarios
            if (user.challengeName) {
                console.log('⚠️ Additional authentication required:', user.challengeName);
                return { 
                    success: false, 
                    challenge: user.challengeName, 
                    error: 'Additional authentication required' 
                };
            }

            setUser(user);
            console.log('✅ Sign in successful:', user.username);
            return { success: true, user: user };
        } catch (error) {
            console.error('❌ Sign in failed:', error);
            const errorMessage = getErrorMessage(error);
            setError(errorMessage);
            return { success: false, error: errorMessage };
        } finally {
            setLoading(false);
        }
    }, [isInitialized]);

    // Enhanced sign out function
    const signOut = useCallback(async () => {
        try {
            setLoading(true);
            setError(null);

            if (!isInitialized) {
                throw new Error('Authentication service not initialized');
            }

            await aws_amplify.Auth.signOut({ global: true });
            setUser(null);
            console.log('✅ Sign out successful');
            return { success: true };
        } catch (error) {
            console.error('❌ Sign out failed:', error);
            const errorMessage = getErrorMessage(error);
            setError(errorMessage);
            return { success: false, error: errorMessage };
        } finally {
            setLoading(false);
        }
    }, [isInitialized]);

    // Confirm sign up function
    const confirmSignUp = useCallback(async (email, confirmationCode) => {
        try {
            setLoading(true);
            setError(null);

            if (!isInitialized) {
                throw new Error('Authentication service not initialized');
            }

            await aws_amplify.Auth.confirmSignUp(email, confirmationCode);
            console.log('✅ Email verification successful');
            return { success: true };
        } catch (error) {
            console.error('❌ Email verification failed:', error);
            const errorMessage = getErrorMessage(error);
            setError(errorMessage);
            return { success: false, error: errorMessage };
        } finally {
            setLoading(false);
        }
    }, [isInitialized]);

    // Resend confirmation code
    const resendConfirmationCode = useCallback(async (email) => {
        try {
            setLoading(true);
            setError(null);

            if (!isInitialized) {
                throw new Error('Authentication service not initialized');
            }

            await aws_amplify.Auth.resendSignUp(email);
            console.log('✅ Confirmation code resent');
            return { success: true };
        } catch (error) {
            console.error('❌ Failed to resend confirmation code:', error);
            const errorMessage = getErrorMessage(error);
            setError(errorMessage);
            return { success: false, error: errorMessage };
        } finally {
            setLoading(false);
        }
    }, [isInitialized]);

    // Get current session and token
    const getCurrentSession = useCallback(async () => {
        try {
            if (!isInitialized) {
                throw new Error('Authentication service not initialized');
            }

            const session = await aws_amplify.Auth.currentSession();
            return {
                success: true,
                accessToken: session.getAccessToken().getJwtToken(),
                idToken: session.getIdToken().getJwtToken(),
                refreshToken: session.getRefreshToken().getToken()
            };
        } catch (error) {
            console.error('❌ Failed to get current session:', error);
            return { success: false, error: getErrorMessage(error) };
        }
    }, [isInitialized]);

    return {
        // State
        user,
        loading,
        error,
        isInitialized,
        
        // Actions
        signUp,
        signIn,
        signOut,
        confirmSignUp,
        resendConfirmationCode,
        getCurrentSession,
        checkUser,
        
        // Computed properties
        isAuthenticated: !!user,
        userEmail: user?.attributes?.email || user?.username
    };
};

// Enhanced error message handler
const getErrorMessage = (error) => {
    if (typeof error === 'string') return error;
    
    const message = error.message || error.toString();
    
    // Map common AWS Cognito errors to user-friendly messages
    const errorMappings = {
        'User does not exist': 'No account found with this email address',
        'Incorrect username or password': 'Invalid email or password',
        'User is not confirmed': 'Please verify your email address before signing in',
        'Invalid verification code provided': 'Invalid verification code. Please try again',
        'Code mismatch': 'Invalid verification code. Please try again',
        'ExpiredCodeException': 'Verification code has expired. Please request a new one',
        'UsernameExistsException': 'An account with this email already exists',
        'InvalidPasswordException': 'Password does not meet requirements',
        'LimitExceededException': 'Too many attempts. Please try again later',
        'NotAuthorizedException': 'Invalid credentials or account not verified',
        'UserNotConfirmedException': 'Please verify your email address first',
        'PasswordResetRequiredException': 'Password reset required. Please check your email',
        'UserNotFoundException': 'No account found with this email address',
        'InvalidParameterException': 'Invalid input parameters',
        'TooManyRequestsException': 'Too many requests. Please wait and try again'
    };

    for (const [key, value] of Object.entries(errorMappings)) {
        if (message.includes(key)) {
            return value;
        }
    }

    // Return original message if no mapping found
    return message;
};

// Enhanced API call function with better error handling
const apiCall = async (endpoint, method = 'GET', data = null) => {
    try {
        if (!AWS_CONFIG.isValid()) {
            throw new Error('API configuration not properly set up');
        }

        let token = '';
        if (amplifyInitialized) {
            try {
                const session = await aws_amplify.Auth.currentSession();
                token = session.getIdToken().getJwtToken();
            } catch (authError) {
                console.warn('⚠️ No valid session found for API call');
                throw new Error('Authentication required. Please sign in again.');
            }
        }

        const config = {
            method: method,
            headers: {
                'Content-Type': 'application/json',
                'Authorization': token ? `Bearer ${token}` : ''
            }
        };

        if (data && method !== 'GET') {
            config.body = JSON.stringify(data);
        }

        const url = `${AWS_CONFIG.apiGatewayUrl}${endpoint}`;
        console.log(`🌐 API Call: ${method} ${url}`);

        const response = await fetch(url, config);
        
        if (!response.ok) {
            const errorData = await response.json().catch(() => ({ error: 'Unknown error' }));
            throw new Error(errorData.error || `HTTP ${response.status}: ${response.statusText}`);
        }

        const responseData = await response.json();
        console.log(`✅ API Response: ${method} ${url}`, responseData);
        return responseData;
    } catch (error) {
        console.error(`❌ API Error: ${method} ${endpoint}`, error);
        throw error;
    }
};

// Authentication status indicator component
const AuthStatusIndicator = ({ user, isInitialized, error }) => {
    if (!isInitialized) {
        return (
            <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
                ⚠️ Authentication service not initialized. Please check configuration.
            </div>
        );
    }

    if (error) {
        return (
            <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
                ❌ {error}
            </div>
        );
    }

    if (user) {
        return (
            <div className="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-4">
                ✅ Signed in as: {user.attributes?.email || user.username}
            </div>
        );
    }

    return null;
};

// Export for testing purposes
window.TodoAuth = {
    useAuth,
    apiCall,
    getErrorMessage,
    AWS_CONFIG
};

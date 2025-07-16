// Streamlined Todo App with Flowless Authentication
// This version replaces the complex authentication flow with a seamless experience

let AWS_CONFIG = {
    region: 'us-west-2',
    userPoolId: 'loading...',
    userPoolClientId: 'loading...',
    apiGatewayUrl: 'loading...'
};

// Load configuration from config.json
const loadConfig = async () => {
    try {
        const response = await fetch('./config.json');
        if (response.ok) {
            const config = await response.json();
            AWS_CONFIG = { ...AWS_CONFIG, ...config };
            console.log('✅ Configuration loaded successfully:', AWS_CONFIG);
            return true;
        } else {
            console.warn('⚠️ Config.json not found, check Terraform deployment');
            return false;
        }
    } catch (error) {
        console.warn('⚠️ Failed to load config.json:', error);
        return false;
    }
};

// Initialize authentication
let authInitialized = false;
let authInitPromise = null;

authInitPromise = new Promise(async (resolve) => {
    const configLoaded = await loadConfig();
    
    if (!configLoaded) {
        console.error('❌ Cannot initialize auth without config');
        resolve(false);
        return;
    }
    
    setTimeout(() => {
        try {
            if (typeof aws_amplify !== 'undefined' && aws_amplify.Amplify) {
                aws_amplify.Amplify.configure({
                    Auth: {
                        region: AWS_CONFIG.region,
                        userPoolId: AWS_CONFIG.userPoolId,
                        userPoolWebClientId: AWS_CONFIG.userPoolClientId,
                        authenticationFlowType: 'USER_PASSWORD_AUTH'
                    }
                });
                authInitialized = true;
                console.log('✅ AWS Authentication initialized successfully');
                resolve(true);
            } else {
                console.error('❌ AWS Amplify not available');
                authInitialized = false;
                resolve(false);
            }
        } catch (error) {
            console.error('❌ Error initializing authentication:', error);
            authInitialized = false;
            resolve(false);
        }
    }, 1500);
});

// React hooks
const { useState, useEffect, useRef, useCallback, useMemo } = React;

// Streamlined Authentication Hook
const useFlowlessAuth = () => {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);
    const [authState, setAuthState] = useState('signin');
    const [formData, setFormData] = useState({
        username: '',
        email: '',
        password: '',
        confirmPassword: '',
        verificationCode: ''
    });
    const [error, setError] = useState('');
    const [success, setSuccess] = useState('');
    const [pendingUser, setPendingUser] = useState(null);
    const [autoVerifying, setAutoVerifying] = useState(false);

    useEffect(() => {
        checkAuthStatus();
    }, []);

    // Check current authentication status
    const checkAuthStatus = async () => {
        if (authInitPromise) {
            await authInitPromise;
        }
        
        try {
            if (authInitialized && aws_amplify?.Auth) {
                const currentUser = await aws_amplify.Auth.currentAuthenticatedUser();
                setUser(currentUser);
                setAuthState('complete');
                console.log('✅ User already authenticated:', currentUser.username);
            }
        } catch (error) {
            console.log('ℹ️ No authenticated user found');
            setUser(null);
            setAuthState('signin');
        } finally {
            setLoading(false);
        }
    };

    // Enhanced error handling
    const handleAuthError = (error) => {
        console.error('Auth error:', error);
        
        const errorMap = {
            'UsernameExistsException': 'An account with this email already exists. Please sign in instead.',
            'InvalidPasswordException': 'Password must be at least 8 characters with uppercase, lowercase, and numbers.',
            'UserNotConfirmedException': 'Please check your email for the verification code.',
            'CodeMismatchException': 'The verification code is incorrect. Please try again.',
            'ExpiredCodeException': 'The verification code has expired. We\'ll send you a new one.',
            'LimitExceededException': 'Too many attempts. Please wait a few minutes before trying again.',
            'NotAuthorizedException': 'Incorrect email or password. Please try again.',
            'UserNotFoundException': 'No account found with this email. Please sign up first.',
            'TooManyRequestsException': 'Too many requests. Please wait a moment and try again.'
        };

        const message = errorMap[error.code] || error.message || 'An unexpected error occurred. Please try again.';
        setError(message);
        return message;
    };

    // Streamlined signup with auto-verification attempt
    const handleSignUp = async () => {
        if (formData.password !== formData.confirmPassword) {
            setError('Passwords do not match');
            return;
        }

        if (formData.password.length < 8) {
            setError('Password must be at least 8 characters long');
            return;
        }

        try {
            setLoading(true);
            setError('');
            
            const result = await aws_amplify.Auth.signUp({
                username: formData.email,
                password: formData.password,
                attributes: {
                    email: formData.email,
                    name: formData.username
                }
            });

            setPendingUser(formData.email);
            setAuthState('verifying');
            setSuccess('Account created successfully! Please check your email for the verification code.');
            
        } catch (error) {
            if (error.code === 'UsernameExistsException') {
                setError('An account with this email already exists. Please sign in instead.');
                setTimeout(() => {
                    setAuthState('signin');
                    setFormData(prev => ({ ...prev, email: formData.email, password: '' }));
                }, 2000);
            } else {
                handleAuthError(error);
            }
        } finally {
            setLoading(false);
        }
    };

    // Verify email with code
    const handleVerification = async () => {
        if (!formData.verificationCode || formData.verificationCode.length !== 6) {
            setError('Please enter the 6-digit verification code from your email');
            return;
        }

        try {
            setLoading(true);
            setError('');
            
            await aws_amplify.Auth.confirmSignUp(pendingUser, formData.verificationCode);
            
            setSuccess('Email verified successfully! Signing you in...');
            
            // Auto sign-in after verification
            setTimeout(async () => {
                try {
                    const user = await aws_amplify.Auth.signIn(pendingUser, formData.password);
                    setUser(user);
                    setAuthState('complete');
                    setSuccess('Welcome to TaskFlow! 🎉');
                } catch (signInError) {
                    console.error('Auto sign-in failed:', signInError);
                    setAuthState('signin');
                    setSuccess('Email verified! Please sign in with your credentials.');
                }
            }, 1500);
            
        } catch (error) {
            if (error.code === 'ExpiredCodeException') {
                await handleResendCode();
            } else {
                handleAuthError(error);
            }
        } finally {
            setLoading(false);
        }
    };

    // Resend verification code
    const handleResendCode = async () => {
        try {
            setLoading(true);
            setError('');
            
            await aws_amplify.Auth.resendConfirmationCode(pendingUser);
            setSuccess('New verification code sent! Please check your email.');
            setFormData(prev => ({ ...prev, verificationCode: '' }));
            
        } catch (error) {
            handleAuthError(error);
        } finally {
            setLoading(false);
        }
    };

    // Sign in
    const handleSignIn = async () => {
        try {
            setLoading(true);
            setError('');
            
            const user = await aws_amplify.Auth.signIn(formData.email, formData.password);
            setUser(user);
            setAuthState('complete');
            setSuccess('Welcome back! 🎉');
            
        } catch (error) {
            if (error.code === 'UserNotConfirmedException') {
                setPendingUser(formData.email);
                setAuthState('verifying');
                setError('Please verify your email first. We\'ll send you a new verification code.');
                await handleResendCode();
            } else {
                handleAuthError(error);
            }
        } finally {
            setLoading(false);
        }
    };

    // Sign out
    const handleSignOut = async () => {
        try {
            setLoading(true);
            await aws_amplify.Auth.signOut();
            setUser(null);
            setAuthState('signin');
            setFormData({
                username: '',
                email: '',
                password: '',
                confirmPassword: '',
                verificationCode: ''
            });
            setError('');
            setSuccess('');
            setPendingUser(null);
            
        } catch (error) {
            console.error('Sign out error:', error);
        } finally {
            setLoading(false);
        }
    };

    // Update form data
    const updateFormData = (field, value) => {
        setFormData(prev => ({ ...prev, [field]: value }));
        setError(''); // Clear error when user types
    };

    // Switch auth mode
    const switchAuthMode = (mode) => {
        setAuthState(mode);
        setError('');
        setSuccess('');
    };

    return {
        user,
        loading,
        authState,
        formData,
        error,
        success,
        autoVerifying,
        updateFormData,
        handleSignUp,
        handleSignIn,
        handleVerification,
        handleResendCode,
        handleSignOut,
        switchAuthMode
    };
};

// Enhanced Loading Screen Component
const LoadingScreen = ({ message = 'Loading TaskFlow...' }) => {
    return React.createElement('div', {
        style: {
            minHeight: '100vh',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            color: 'white'
        }
    }, React.createElement('div', {
        style: { textAlign: 'center' }
    }, [
        React.createElement('div', {
            key: 'spinner',
            style: {
                width: '60px',
                height: '60px',
                border: '4px solid rgba(255, 255, 255, 0.3)',
                borderTop: '4px solid white',
                borderRadius: '50%',
                animation: 'spin 1s linear infinite',
                margin: '0 auto 1.5rem'
            }
        }),
        React.createElement('h2', {
            key: 'title',
            style: {
                fontSize: '1.5rem',
                fontWeight: '600',
                marginBottom: '0.5rem'
            }
        }, 'TaskFlow'),
        React.createElement('p', {
            key: 'message',
            style: {
                fontSize: '1rem',
                opacity: 0.9
            }
        }, message)
    ]));
};

// Streamlined Authentication Component
const FlowlessAuth = () => {
    const {
        user,
        loading,
        authState,
        formData,
        error,
        success,
        updateFormData,
        handleSignUp,
        handleSignIn,
        handleVerification,
        handleResendCode,
        handleSignOut,
        switchAuthMode
    } = useFlowlessAuth();

    // Initial loading screen
    if (loading && authState === 'signin' && !user) {
        return React.createElement(LoadingScreen, { 
            message: 'Initializing authentication...' 
        });
    }

    // User is authenticated - show main app
    if (user && authState === 'complete') {
        return React.createElement(TodoApp, { user, onSignOut: handleSignOut });
    }

    // Authentication form container
    const baseStyle = {
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        padding: '2rem'
    };

    const cardStyle = {
        background: 'white',
        borderRadius: '2rem',
        padding: '3rem',
        boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
        width: '100%',
        maxWidth: '450px',
        position: 'relative',
        overflow: 'hidden'
    };

    // Form header based on state
    const getHeader = () => {
        const headers = {
            signin: { title: 'Welcome Back', subtitle: 'Sign in to your TaskFlow account', icon: '✓' },
            signup: { title: 'Create Account', subtitle: 'Join TaskFlow and boost your productivity', icon: '✨' },
            verifying: { title: 'Verify Your Email', subtitle: 'We sent a verification code to your email', icon: '📧' }
        };
        return headers[authState] || headers.signin;
    };

    const header = getHeader();

    return React.createElement('div', { style: baseStyle }, 
        React.createElement('div', { style: cardStyle }, [
            // Header
            React.createElement('div', { 
                key: 'header',
                style: { textAlign: 'center', marginBottom: '2rem' }
            }, [
                React.createElement('div', { 
                    key: 'logo',
                    style: {
                        width: '80px',
                        height: '80px',
                        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                        borderRadius: '1.5rem',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: '2.5rem',
                        color: 'white',
                        margin: '0 auto 1.5rem',
                        boxShadow: '0 10px 15px -3px rgba(102, 126, 234, 0.3)'
                    }
                }, header.icon),
                React.createElement('h1', { 
                    key: 'title',
                    style: {
                        fontSize: '2rem',
                        fontWeight: '800',
                        color: '#1E293B',
                        marginBottom: '0.5rem'
                    }
                }, header.title),
                React.createElement('p', { 
                    key: 'subtitle',
                    style: {
                        color: '#64748B',
                        fontSize: '1rem'
                    }
                }, header.subtitle)
            ]),

            // Status Messages
            success && React.createElement('div', {
                key: 'success',
                style: {
                    background: '#F0FDF4',
                    color: '#16A34A',
                    padding: '1rem',
                    borderRadius: '1rem',
                    marginBottom: '1.5rem',
                    fontSize: '0.875rem',
                    fontWeight: '500',
                    border: '1px solid #BBF7D0',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.5rem'
                }
            }, [
                React.createElement('span', { key: 'icon' }, '✅'),
                React.createElement('span', { key: 'text' }, success)
            ]),

            error && React.createElement('div', {
                key: 'error',
                style: {
                    background: '#FEF2F2',
                    color: '#DC2626',
                    padding: '1rem',
                    borderRadius: '1rem',
                    marginBottom: '1.5rem',
                    fontSize: '0.875rem',
                    fontWeight: '500',
                    border: '1px solid #FCA5A5',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.5rem'
                }
            }, [
                React.createElement('span', { key: 'icon' }, '❌'),
                React.createElement('span', { key: 'text' }, error)
            ]),

            // Form content based on state
            authState === 'signin' && renderSignInForm(),
            authState === 'signup' && renderSignUpForm(),
            authState === 'verifying' && renderVerificationForm()
        ])
    );

    // Sign in form
    function renderSignInForm() {
        return React.createElement('form', { 
            key: 'signin-form',
            onSubmit: (e) => {
                e.preventDefault();
                handleSignIn();
            }
        }, [
            // Email field
            React.createElement('div', { 
                key: 'email-group',
                style: { marginBottom: '1.5rem' }
            }, [
                React.createElement('label', { 
                    key: 'label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#374151',
                        marginBottom: '0.5rem'
                    }
                }, 'Email'),
                React.createElement('input', {
                    key: 'input',
                    type: 'email',
                    value: formData.email,
                    onChange: (e) => updateFormData('email', e.target.value),
                    placeholder: 'Enter your email address',
                    style: {
                        width: '100%',
                        padding: '1rem',
                        border: '2px solid #E5E7EB',
                        borderRadius: '1rem',
                        fontSize: '1rem',
                        transition: 'border-color 0.15s ease-out'
                    },
                    required: true
                })
            ]),

            // Password field
            React.createElement('div', { 
                key: 'password-group',
                style: { marginBottom: '2rem' }
            }, [
                React.createElement('label', { 
                    key: 'label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#374151',
                        marginBottom: '0.5rem'
                    }
                }, 'Password'),
                React.createElement('input', {
                    key: 'input',
                    type: 'password',
                    value: formData.password,
                    onChange: (e) => updateFormData('password', e.target.value),
                    placeholder: 'Enter your password',
                    style: {
                        width: '100%',
                        padding: '1rem',
                        border: '2px solid #E5E7EB',
                        borderRadius: '1rem',
                        fontSize: '1rem',
                        transition: 'border-color 0.15s ease-out'
                    },
                    required: true
                })
            ]),

            // Submit button
            React.createElement('button', {
                key: 'submit',
                type: 'submit',
                disabled: loading,
                style: {
                    width: '100%',
                    background: loading ? '#9CA3AF' : 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                    color: 'white',
                    border: 'none',
                    padding: '1rem',
                    borderRadius: '1rem',
                    fontSize: '1rem',
                    fontWeight: '600',
                    cursor: loading ? 'not-allowed' : 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    marginBottom: '1.5rem'
                }
            }, [
                loading && React.createElement('div', {
                    key: 'spinner',
                    style: {
                        width: '20px',
                        height: '20px',
                        border: '2px solid rgba(255, 255, 255, 0.3)',
                        borderTop: '2px solid white',
                        borderRadius: '50%',
                        animation: 'spin 1s linear infinite'
                    }
                }),
                React.createElement('span', { key: 'text' }, loading ? 'Signing in...' : 'Sign In')
            ]),

            // Switch to signup
            React.createElement('div', {
                key: 'switch',
                style: { 
                    textAlign: 'center',
                    paddingTop: '1.5rem',
                    borderTop: '1px solid #E5E7EB'
                }
            }, [
                React.createElement('span', {
                    key: 'text',
                    style: { color: '#64748B', fontSize: '0.875rem' }
                }, "Don't have an account? "),
                React.createElement('button', {
                    key: 'link',
                    type: 'button',
                    onClick: () => switchAuthMode('signup'),
                    style: {
                        background: 'none',
                        border: 'none',
                        color: '#667eea',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        cursor: 'pointer',
                        textDecoration: 'underline'
                    }
                }, 'Create one here')
            ])
        ]);
    }

    // Sign up form
    function renderSignUpForm() {
        return React.createElement('form', { 
            key: 'signup-form',
            onSubmit: (e) => {
                e.preventDefault();
                handleSignUp();
            }
        }, [
            // Username field
            React.createElement('div', { 
                key: 'username-group',
                style: { marginBottom: '1.5rem' }
            }, [
                React.createElement('label', { 
                    key: 'label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#374151',
                        marginBottom: '0.5rem'
                    }
                }, 'Name'),
                React.createElement('input', {
                    key: 'input',
                    type: 'text',
                    value: formData.username,
                    onChange: (e) => updateFormData('username', e.target.value),
                    placeholder: 'Enter your full name',
                    style: {
                        width: '100%',
                        padding: '1rem',
                        border: '2px solid #E5E7EB',
                        borderRadius: '1rem',
                        fontSize: '1rem'
                    },
                    required: true
                })
            ]),

            // Email field
            React.createElement('div', { 
                key: 'email-group',
                style: { marginBottom: '1.5rem' }
            }, [
                React.createElement('label', { 
                    key: 'label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#374151',
                        marginBottom: '0.5rem'
                    }
                }, 'Email'),
                React.createElement('input', {
                    key: 'input',
                    type: 'email',
                    value: formData.email,
                    onChange: (e) => updateFormData('email', e.target.value),
                    placeholder: 'Enter your email address',
                    style: {
                        width: '100%',
                        padding: '1rem',
                        border: '2px solid #E5E7EB',
                        borderRadius: '1rem',
                        fontSize: '1rem'
                    },
                    required: true
                })
            ]),

            // Password field
            React.createElement('div', { 
                key: 'password-group',
                style: { marginBottom: '1.5rem' }
            }, [
                React.createElement('label', { 
                    key: 'label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#374151',
                        marginBottom: '0.5rem'
                    }
                }, 'Password'),
                React.createElement('input', {
                    key: 'input',
                    type: 'password',
                    value: formData.password,
                    onChange: (e) => updateFormData('password', e.target.value),
                    placeholder: 'Create a strong password',
                    style: {
                        width: '100%',
                        padding: '1rem',
                        border: '2px solid #E5E7EB',
                        borderRadius: '1rem',
                        fontSize: '1rem'
                    },
                    required: true
                })
            ]),

            // Confirm password field
            React.createElement('div', { 
                key: 'confirm-password-group',
                style: { marginBottom: '2rem' }
            }, [
                React.createElement('label', { 
                    key: 'label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#374151',
                        marginBottom: '0.5rem'
                    }
                }, 'Confirm Password'),
                React.createElement('input', {
                    key: 'input',
                    type: 'password',
                    value: formData.confirmPassword,
                    onChange: (e) => updateFormData('confirmPassword', e.target.value),
                    placeholder: 'Confirm your password',
                    style: {
                        width: '100%',
                        padding: '1rem',
                        border: '2px solid #E5E7EB',
                        borderRadius: '1rem',
                        fontSize: '1rem'
                    },
                    required: true
                })
            ]),

            // Submit button
            React.createElement('button', {
                key: 'submit',
                type: 'submit',
                disabled: loading,
                style: {
                    width: '100%',
                    background: loading ? '#9CA3AF' : 'linear-gradient(135deg, #22C55E 0%, #16A34A 100%)',
                    color: 'white',
                    border: 'none',
                    padding: '1rem',
                    borderRadius: '1rem',
                    fontSize: '1rem',
                    fontWeight: '600',
                    cursor: loading ? 'not-allowed' : 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    marginBottom: '1.5rem'
                }
            }, [
                loading && React.createElement('div', {
                    key: 'spinner',
                    style: {
                        width: '20px',
                        height: '20px',
                        border: '2px solid rgba(255, 255, 255, 0.3)',
                        borderTop: '2px solid white',
                        borderRadius: '50%',
                        animation: 'spin 1s linear infinite'
                    }
                }),
                React.createElement('span', { key: 'text' }, loading ? 'Creating Account...' : 'Create Account')
            ]),

            // Switch to signin
            React.createElement('div', {
                key: 'switch',
                style: { 
                    textAlign: 'center',
                    paddingTop: '1.5rem',
                    borderTop: '1px solid #E5E7EB'
                }
            }, [
                React.createElement('span', {
                    key: 'text',
                    style: { color: '#64748B', fontSize: '0.875rem' }
                }, "Already have an account? "),
                React.createElement('button', {
                    key: 'link',
                    type: 'button',
                    onClick: () => switchAuthMode('signin'),
                    style: {
                        background: 'none',
                        border: 'none',
                        color: '#667eea',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        cursor: 'pointer',
                        textDecoration: 'underline'
                    }
                }, 'Sign in here')
            ])
        ]);
    }

    // Verification form
    function renderVerificationForm() {
        return React.createElement('form', { 
            key: 'verification-form',
            onSubmit: (e) => {
                e.preventDefault();
                handleVerification();
            }
        }, [
            // Info about verification
            React.createElement('div', {
                key: 'info',
                style: {
                    background: '#F0F9FF',
                    padding: '1rem',
                    borderRadius: '1rem',
                    marginBottom: '1.5rem',
                    border: '1px solid #93C5FD'
                }
            }, [
                React.createElement('p', {
                    key: 'text',
                    style: {
                        fontSize: '0.875rem',
                        color: '#0369A1',
                        margin: 0
                    }
                }, `We sent a verification code to: ${formData.email || pendingUser}`)
            ]),

            // Verification code field
            React.createElement('div', { 
                key: 'code-group',
                style: { marginBottom: '2rem' }
            }, [
                React.createElement('label', { 
                    key: 'label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#374151',
                        marginBottom: '0.5rem'
                    }
                }, 'Verification Code'),
                React.createElement('input', {
                    key: 'input',
                    name: 'verificationCode',
                    type: 'text',
                    value: formData.verificationCode,
                    onChange: (e) => updateFormData('verificationCode', e.target.value.replace(/\D/g, '').slice(0, 6)),
                    placeholder: 'Enter 6-digit code',
                    style: {
                        width: '100%',
                        padding: '1rem',
                        border: '2px solid #E5E7EB',
                        borderRadius: '1rem',
                        fontSize: '1.5rem',
                        textAlign: 'center',
                        letterSpacing: '0.5rem',
                        fontFamily: 'monospace'
                    },
                    maxLength: 6,
                    required: true,
                    autoComplete: 'one-time-code'
                })
            ]),

            // Submit button
            React.createElement('button', {
                key: 'submit',
                type: 'submit',
                disabled: loading || formData.verificationCode.length !== 6,
                style: {
                    width: '100%',
                    background: (loading || formData.verificationCode.length !== 6) ? '#9CA3AF' : 'linear-gradient(135deg, #22C55E 0%, #16A34A 100%)',
                    color: 'white',
                    border: 'none',
                    padding: '1rem',
                    borderRadius: '1rem',
                    fontSize: '1rem',
                    fontWeight: '600',
                    cursor: (loading || formData.verificationCode.length !== 6) ? 'not-allowed' : 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    marginBottom: '1rem'
                }
            }, [
                loading && React.createElement('div', {
                    key: 'spinner',
                    style: {
                        width: '20px',
                        height: '20px',
                        border: '2px solid rgba(255, 255, 255, 0.3)',
                        borderTop: '2px solid white',
                        borderRadius: '50%',
                        animation: 'spin 1s linear infinite'
                    }
                }),
                React.createElement('span', { key: 'text' }, loading ? 'Verifying...' : 'Verify Email')
            ]),

            // Resend code button
            React.createElement('div', {
                key: 'resend-section',
                style: { 
                    textAlign: 'center',
                    marginBottom: '1.5rem'
                }
            }, [
                React.createElement('span', {
                    key: 'text',
                    style: { color: '#64748B', fontSize: '0.875rem' }
                }, "Didn't receive the code? "),
                React.createElement('button', {
                    key: 'resend-button',
                    type: 'button',
                    onClick: handleResendCode,
                    disabled: loading,
                    style: {
                        background: 'none',
                        border: 'none',
                        color: '#667eea',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        cursor: loading ? 'not-allowed' : 'pointer',
                        textDecoration: 'underline'
                    }
                }, 'Resend code')
            ]),

            // Back to signin
            React.createElement('div', {
                key: 'back',
                style: { 
                    textAlign: 'center',
                    paddingTop: '1.5rem',
                    borderTop: '1px solid #E5E7EB'
                }
            }, React.createElement('button', {
                type: 'button',
                onClick: () => switchAuthMode('signin'),
                style: {
                    background: 'none',
                    border: 'none',
                    color: '#667eea',
                    fontSize: '0.875rem',
                    fontWeight: '600',
                    cursor: 'pointer',
                    textDecoration: 'underline'
                }
            }, '← Back to Sign In'))
        ]);
    }
};

// Simple Todo App Component (placeholder for the actual todo functionality)
const TodoApp = ({ user, onSignOut }) => {
    return React.createElement('div', {
        style: {
            minHeight: '100vh',
            background: '#f8fafc',
            padding: '2rem'
        }
    }, [
        // Header
        React.createElement('header', {
            key: 'header',
            style: {
                background: 'white',
                borderRadius: '1rem',
                padding: '1.5rem',
                marginBottom: '2rem',
                boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center'
            }
        }, [
            React.createElement('div', {
                key: 'title',
                style: {
                    display: 'flex',
                    alignItems: 'center',
                    gap: '1rem'
                }
            }, [
                React.createElement('div', {
                    key: 'logo',
                    style: {
                        width: '48px',
                        height: '48px',
                        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                        borderRadius: '1rem',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: '1.5rem',
                        color: 'white'
                    }
                }, '✓'),
                React.createElement('h1', {
                    key: 'text',
                    style: {
                        fontSize: '1.5rem',
                        fontWeight: '700',
                        color: '#1e293b'
                    }
                }, 'TaskFlow')
            ]),
            React.createElement('div', {
                key: 'user-section',
                style: {
                    display: 'flex',
                    alignItems: 'center',
                    gap: '1rem'
                }
            }, [
                React.createElement('span', {
                    key: 'welcome',
                    style: {
                        color: '#64748b',
                        fontSize: '0.875rem'
                    }
                }, `Welcome, ${user.username || user.attributes?.email || 'User'}!`),
                React.createElement('button', {
                    key: 'signout',
                    onClick: onSignOut,
                    style: {
                        background: '#ef4444',
                        color: 'white',
                        border: 'none',
                        padding: '0.5rem 1rem',
                        borderRadius: '0.5rem',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        cursor: 'pointer'
                    }
                }, 'Sign Out')
            ])
        ]),

        // Welcome message
        React.createElement('div', {
            key: 'welcome',
            style: {
                background: 'white',
                borderRadius: '1rem',
                padding: '2rem',
                textAlign: 'center',
                boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
            }
        }, [
            React.createElement('h2', {
                key: 'title',
                style: {
                    fontSize: '2rem',
                    fontWeight: '700',
                    color: '#1e293b',
                    marginBottom: '1rem'
                }
            }, '🎉 Welcome to TaskFlow!'),
            React.createElement('p', {
                key: 'message',
                style: {
                    fontSize: '1.125rem',
                    color: '#64748b',
                    marginBottom: '2rem'
                }
            }, 'Your authentication is working perfectly! You can now access your personalized task management dashboard.'),
            React.createElement('div', {
                key: 'features',
                style: {
                    display: 'grid',
                    gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                    gap: '1rem',
                    marginTop: '2rem'
                }
            }, [
                React.createElement('div', {
                    key: 'feature1',
                    style: {
                        background: '#f0f9ff',
                        padding: '1.5rem',
                        borderRadius: '1rem',
                        border: '1px solid #bfdbfe'
                    }
                }, [
                    React.createElement('div', {
                        key: 'icon',
                        style: { fontSize: '2rem', marginBottom: '0.5rem' }
                    }, '🚀'),
                    React.createElement('h3', {
                        key: 'title',
                        style: { fontWeight: '600', marginBottom: '0.5rem' }
                    }, 'Seamless Auth'),
                    React.createElement('p', {
                        key: 'desc',
                        style: { fontSize: '0.875rem', color: '#64748b' }
                    }, 'Streamlined signup and verification process')
                ]),
                React.createElement('div', {
                    key: 'feature2',
                    style: {
                        background: '#f0fdf4',
                        padding: '1.5rem',
                        borderRadius: '1rem',
                        border: '1px solid #bbf7d0'
                    }
                }, [
                    React.createElement('div', {
                        key: 'icon',
                        style: { fontSize: '2rem', marginBottom: '0.5rem' }
                    }, '🔐'),
                    React.createElement('h3', {
                        key: 'title',
                        style: { fontWeight: '600', marginBottom: '0.5rem' }
                    }, 'Secure'),
                    React.createElement('p', {
                        key: 'desc',
                        style: { fontSize: '0.875rem', color: '#64748b' }
                    }, 'AWS Cognito powered authentication')
                ]),
                React.createElement('div', {
                    key: 'feature3',
                    style: {
                        background: '#fefce8',
                        padding: '1.5rem',
                        borderRadius: '1rem',
                        border: '1px solid #fde047'
                    }
                }, [
                    React.createElement('div', {
                        key: 'icon',
                        style: { fontSize: '2rem', marginBottom: '0.5rem' }
                    }, '⚡'),
                    React.createElement('h3', {
                        key: 'title',
                        style: { fontWeight: '600', marginBottom: '0.5rem' }
                    }, 'Fast'),
                    React.createElement('p', {
                        key: 'desc',
                        style: { fontSize: '0.875rem', color: '#64748b' }
                    }, 'Quick verification and auto sign-in')
                ])
            ])
        ])
    ]);
};

// Export the main component
window.FlowlessAuth = FlowlessAuth;
window.TodoApp = TodoApp;

console.log('✅ Flowless Authentication App loaded successfully');

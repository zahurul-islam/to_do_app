// TaskFlow - Modern AI-Powered Todo App
// Enhanced with AI text extraction and modern UI

let AWS_CONFIG = {
    region: 'us-west-2',
    userPoolId: null,
    userPoolClientId: null,
    apiGatewayUrl: null
};

// Load configuration from config.json with better error handling
const loadConfig = async () => {
    try {
        const response = await fetch('./config.json');
        if (response.ok) {
            const contentType = response.headers.get('content-type');
            if (contentType && contentType.includes('application/json')) {
                const config = await response.json();
                
                if (config.userPoolId && config.userPoolId !== 'loading...' && 
                    config.userPoolClientId && config.userPoolClientId !== 'loading...' &&
                    config.apiGatewayUrl && config.apiGatewayUrl !== 'loading...') {
                    
                    AWS_CONFIG = { ...AWS_CONFIG, ...config };
                    console.log('✅ Configuration loaded successfully:', AWS_CONFIG);
                    return true;
                } else {
                    console.warn('⚠️ Config loaded but missing valid AWS resource IDs');
                    return false;
                }
            } else {
                console.warn('⚠️ Config.json returned HTML instead of JSON - deployment incomplete');
                return false;
            }
        } else {
            console.warn('⚠️ Config.json not found - run ./deploy.sh first');
            return false;
        }
    } catch (error) {
        console.warn('⚠️ Failed to load config.json:', error.message);
        return false;
    }
};

// Initialize AWS authentication
let authInitialized = false;
let authPromise = null;

const initializeAuth = () => {
    if (authPromise) return authPromise;
    
    authPromise = new Promise(async (resolve) => {
        const configLoaded = await loadConfig();
        
        if (!configLoaded) {
            console.error('❌ Cannot initialize auth without proper AWS configuration');
            resolve(false);
            return;
        }
        
        if (!AWS_CONFIG.userPoolId || !AWS_CONFIG.userPoolClientId) {
            console.error('❌ Missing required AWS Cognito configuration');
            resolve(false);
            return;
        }
        
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
                console.log('✅ Authentication initialized successfully');
                resolve(true);
            } else {
                console.error('❌ AWS Amplify not available');
                resolve(false);
            }
        } catch (error) {
            console.error('❌ Auth initialization failed:', error);
            resolve(false);
        }
    });
    
    return authPromise;
};

// React hooks
const { useState, useEffect, useCallback, useRef } = React;

// Utility functions
const formatDate = (date) => {
    try {
        return new Date(date).toLocaleDateString('en-US', {
            year: 'numeric', month: 'short', day: 'numeric'
        });
    } catch { return ''; }
};

const getInitials = (email) => {
    if (!email) return 'U';
    try {
        const parts = email.split('@')[0].split('.');
        return parts.map(part => part.charAt(0).toUpperCase()).join('').slice(0, 2);
    } catch { return 'U'; }
};

const generateId = () => Date.now().toString(36) + Math.random().toString(36).substr(2);

// Enhanced categories with modern icons
const CATEGORIES = [
    { id: 'work', name: 'Work', color: '#6366F1', icon: '💼', gradient: 'from-indigo-500 to-purple-600' },
    { id: 'personal', name: 'Personal', color: '#10B981', icon: '👤', gradient: 'from-emerald-500 to-teal-600' },
    { id: 'health', name: 'Health', color: '#F59E0B', icon: '🏃', gradient: 'from-amber-500 to-orange-600' },
    { id: 'learning', name: 'Learning', color: '#8B5CF6', icon: '📚', gradient: 'from-violet-500 to-purple-600' },
    { id: 'shopping', name: 'Shopping', color: '#EC4899', icon: '🛒', gradient: 'from-pink-500 to-rose-600' },
    { id: 'meeting', name: 'Meeting', color: '#3B82F6', icon: '🤝', gradient: 'from-blue-500 to-indigo-600' },
    { id: 'other', name: 'Other', color: '#6B7280', icon: '📝', gradient: 'from-gray-500 to-slate-600' }
];

const PRIORITIES = [
    { id: 'low', name: 'Low', color: '#10B981', icon: '🟢' },
    { id: 'medium', name: 'Medium', color: '#F59E0B', icon: '🟡' },
    { id: 'high', name: 'High', color: '#EF4444', icon: '🔴' },
    { id: 'urgent', name: 'Urgent', color: '#DC2626', icon: '⚡' }
];

// AI Text Extraction Service
class AITextExtractor {
    static async extractTodos(text) {
        const response = await apiCall('/ai/extract', 'POST', { text });
        return response.todos;
    }
    
    static categorizeTask(task) {
        const taskLower = task.toLowerCase();
        
        if (taskLower.includes('meet') || taskLower.includes('call') || taskLower.includes('standup') || 
            taskLower.includes('1:1') || taskLower.includes('sync')) return 'meeting';
        if (taskLower.includes('buy') || taskLower.includes('order') || taskLower.includes('purchase')) return 'shopping';
        if (taskLower.includes('exercise') || taskLower.includes('workout') || taskLower.includes('doctor') || 
            taskLower.includes('health')) return 'health';
        if (taskLower.includes('learn') || taskLower.includes('study') || taskLower.includes('course') || 
            taskLower.includes('read')) return 'learning';
        if (taskLower.includes('project') || taskLower.includes('work') || taskLower.includes('report') || 
            taskLower.includes('deadline')) return 'work';
        
        return 'other';
    }
    
    static prioritizeTask(task) {
        const taskLower = task.toLowerCase();
        
        if (taskLower.includes('urgent') || taskLower.includes('asap') || taskLower.includes('immediately')) return 'urgent';
        if (taskLower.includes('important') || taskLower.includes('critical') || taskLower.includes('deadline')) return 'high';
        if (taskLower.includes('soon') || taskLower.includes('this week')) return 'medium';
        
        return 'low';
    }
    
    static calculateConfidence(task, fullMatch) {
        // Confidence will be determined by the AI, so this can be simplified or removed
        return 1; // Assuming AI provides high confidence
    }
}

// API helper with authentication
const apiCall = async (endpoint, method = 'GET', data = null) => {
    await initializeAuth();
    
    try {
        let token = '';
        if (authInitialized && aws_amplify?.Auth) {
            const session = await aws_amplify.Auth.currentSession();
            token = session.getIdToken().getJwtToken();
        }

        const config = {
            method,
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            }
        };

        if (data && method !== 'GET') {
            config.body = JSON.stringify(data);
        }

        const response = await fetch(`${AWS_CONFIG.apiGatewayUrl}${endpoint}`, config);
        
        if (!response.ok) {
            throw new Error(`API Error: ${response.status}`);
        }

        return await response.json();
    } catch (error) {
        console.error('API call failed:', error);
        throw error;
    }
};

// Enhanced Flowless Authentication Hook
const useFlowlessAuth = () => {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);
    const [authMode, setAuthMode] = useState('signin');
    const [formData, setFormData] = useState({
        email: '',
        password: '',
        confirmPassword: '',
        verificationCode: ''
    });
    const [error, setError] = useState('');
    const [pendingUser, setPendingUser] = useState(null);
    const [configError, setConfigError] = useState(false);

    useEffect(() => {
        checkAuth();
    }, []);

    const checkAuth = async () => {
        const authReady = await initializeAuth();
        
        if (!authReady) {
            setConfigError(true);
            setLoading(false);
            setError('AWS configuration not available. Please deploy the infrastructure first.');
            return;
        }
        
        try {
            if (authInitialized && aws_amplify?.Auth) {
                const currentUser = await aws_amplify.Auth.currentAuthenticatedUser();
                setUser(currentUser);
                console.log('✅ User authenticated:', currentUser.username);
            }
        } catch (error) {
            console.log('ℹ️ No authenticated user');
            setUser(null);
        } finally {
            setLoading(false);
        }
    };

    const updateFormData = (field, value) => {
        setFormData(prev => ({ ...prev, [field]: value }));
        setError('');
    };

    const signUp = async () => {
        try {
            setLoading(true);
            setError('');
            
            const result = await aws_amplify.Auth.signUp({
                username: formData.email,
                password: formData.password,
                attributes: { 
                    email: formData.email,
                    preferred_username: formData.email.split('@')[0]
                }
            });
            
            setPendingUser(result.user);
            setAuthMode('verify');
            console.log('✅ Signup successful, verification needed');
        } catch (error) {
            console.error('❌ Signup failed:', error);
            
            if (error.code === 'UsernameExistsException') {
                setError('Account already exists. Try signing in instead.');
                setAuthMode('signin');
            } else if (error.code === 'InvalidParameterException') {
                try {
                    const generatedUsername = 'user_' + Date.now() + '_' + Math.random().toString(36).substr(2, 5);
                    const result = await aws_amplify.Auth.signUp({
                        username: generatedUsername,
                        password: formData.password,
                        attributes: { 
                            email: formData.email,
                            preferred_username: formData.email.split('@')[0]
                        }
                    });
                    
                    setPendingUser({ ...result.user, email: formData.email });
                    setAuthMode('verify');
                    console.log('✅ Signup successful with generated username');
                } catch (retryError) {
                    setError(retryError.message || 'Signup failed. Please try again.');
                }
            } else {
                setError(error.message || 'Signup failed');
            }
        } finally {
            setLoading(false);
        }
    };

    const signIn = async () => {
        try {
            setLoading(true);
            setError('');
            
            const user = await aws_amplify.Auth.signIn(formData.email, formData.password);
            setUser(user);
            console.log('✅ Sign in successful');
        } catch (error) {
            console.error('❌ Sign in failed:', error);
            
            if (error.code === 'UserNotConfirmedException') {
                setPendingUser({ username: formData.email, email: formData.email });
                setAuthMode('verify');
                setError('Please verify your email first');
            } else if (error.code === 'UserNotFoundException') {
                setError('Account not found. Please sign up first.');
            } else if (error.code === 'NotAuthorizedException') {
                setError('Invalid email or password. Please try again.');
            } else {
                setError(error.message || 'Sign in failed');
            }
        } finally {
            setLoading(false);
        }
    };

    const verifyCode = async () => {
        try {
            setLoading(true);
            setError('');
            
            const usernameToVerify = pendingUser?.username || formData.email;
            
            await aws_amplify.Auth.confirmSignUp(usernameToVerify, formData.verificationCode);
            
            const user = await aws_amplify.Auth.signIn(formData.email, formData.password);
            setUser(user);
            console.log('✅ Verification and auto sign-in successful');
        } catch (error) {
            console.error('❌ Verification failed:', error);
            
            if (error.code === 'CodeMismatchException') {
                setError('Verification code is incorrect. Please try again.');
            } else if (error.code === 'ExpiredCodeException') {
                setError('Verification code has expired. Please request a new one.');
            } else {
                setError(error.message || 'Verification failed');
            }
        } finally {
            setLoading(false);
        }
    };

    const resendCode = async () => {
        try {
            setLoading(true);
            setError('');
            
            const usernameToResend = pendingUser?.username || formData.email;
            
            await aws_amplify.Auth.resendSignUp(usernameToResend);
            console.log('✅ Verification code resent');
            
            setError('✅ New verification code sent to your email');
            setTimeout(() => setError(''), 3000);
        } catch (error) {
            console.error('❌ Resend failed:', error);
            setError(error.message || 'Failed to resend code');
        } finally {
            setLoading(false);
        }
    };

    const signOut = async () => {
        try {
            setLoading(true);
            await aws_amplify.Auth.signOut();
            setUser(null);
            setFormData({ email: '', password: '', confirmPassword: '', verificationCode: '' });
            setAuthMode('signin');
            console.log('✅ Sign out successful');
        } catch (error) {
            console.error('❌ Sign out failed:', error);
        } finally {
            setLoading(false);
        }
    };

    return {
        user, loading, authMode, formData, error, configError,
        updateFormData, signUp, signIn, verifyCode, resendCode, signOut,
        setAuthMode, setError
    };
};

// Enhanced Loading Screen Component
const LoadingScreen = ({ message = 'Loading...', error = false, showHelp = false }) => {
    return React.createElement('div', { 
        className: 'min-h-screen bg-gradient-to-br from-indigo-50 via-white to-purple-50 flex items-center justify-center p-4'
    }, React.createElement('div', { 
        className: 'text-center max-w-md',
    }, [
        !error && React.createElement('div', { 
            key: 'spinner',
            className: 'w-12 h-12 border-4 border-indigo-200 border-t-indigo-600 rounded-full animate-spin mx-auto mb-4'
        }),
        error && React.createElement('div', {
            key: 'error-icon',
            className: 'text-6xl mb-4'
        }, '⚠️'),
        React.createElement('p', { 
            key: 'text',
            className: `text-lg font-medium ${error ? 'text-red-600' : 'text-gray-600'}`
        }, message),
        showHelp && React.createElement('div', {
            key: 'help',
            className: 'mt-8 p-6 bg-white rounded-2xl shadow-lg border border-gray-100 text-left'
        }, [
            React.createElement('h3', {
                key: 'help-title',
                className: 'text-lg font-bold text-gray-900 mb-4 flex items-center'
            }, ['🚀 ', 'Quick Setup']),
            React.createElement('ol', {
                key: 'help-steps',
                className: 'space-y-2 text-sm text-gray-600'
            }, [
                React.createElement('li', { key: 'step1', className: 'flex items-start' }, [
                    React.createElement('span', { className: 'font-medium text-indigo-600 mr-2' }, '1.'),
                    'Open terminal in project directory'
                ]),
                React.createElement('li', { key: 'step2', className: 'flex items-start' }, [
                    React.createElement('span', { className: 'font-medium text-indigo-600 mr-2' }, '2.'),
                    'Run: ./deploy.sh'
                ]),
                React.createElement('li', { key: 'step3', className: 'flex items-start' }, [
                    React.createElement('span', { className: 'font-medium text-indigo-600 mr-2' }, '3.'),
                    'Wait for deployment to complete'
                ]),
                React.createElement('li', { key: 'step4', className: 'flex items-start' }, [
                    React.createElement('span', { className: 'font-medium text-indigo-600 mr-2' }, '4.'),
                    'Refresh this page'
                ])
            ])
        ])
    ]));
};

// Modern Authentication Screen
const AuthScreen = ({ auth }) => {
    const { authMode, formData, error, loading, updateFormData, signUp, signIn, verifyCode, resendCode, setAuthMode, setError } = auth;

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');

        if (authMode === 'signup') {
            if (formData.password !== formData.confirmPassword) {
                setError('Passwords do not match');
                return;
            }
            await signUp();
        } else if (authMode === 'signin') {
            await signIn();
        } else if (authMode === 'verify') {
            await verifyCode();
        }
    };

    const switchMode = (mode) => {
        setAuthMode(mode);
        setError('');
    };

    return React.createElement('div', { 
        className: 'min-h-screen bg-gradient-to-br from-indigo-900 via-purple-900 to-pink-800 flex items-center justify-center p-4'
    }, React.createElement('div', { 
        className: 'w-full max-w-md'
    }, [
        React.createElement('div', { 
            key: 'card',
            className: 'bg-white/95 backdrop-blur-xl rounded-3xl shadow-2xl p-8 border border-white/20'
        }, [
            React.createElement('div', { 
                key: 'header',
                className: 'text-center mb-8'
            }, [
                React.createElement('div', { 
                    key: 'logo',
                    className: 'w-16 h-16 bg-gradient-to-r from-indigo-600 to-purple-600 rounded-2xl flex items-center justify-center mx-auto mb-4 shadow-lg'
                }, React.createElement('span', { className: 'text-2xl font-bold text-white' }, '✓')),
                React.createElement('h1', { 
                    key: 'title',
                    className: 'text-3xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent'
                }, 'TaskFlow'),
                React.createElement('p', { 
                    key: 'subtitle',
                    className: 'text-gray-600 mt-2'
                }, authMode === 'verify' ? 'Verify your email' : 
                    authMode === 'signup' ? 'Create your account' : 'Welcome back')
            ]),

            error && React.createElement('div', {
                key: 'error',
                className: 'mb-6 p-4 bg-red-50 border border-red-200 rounded-xl text-red-700 text-sm'
            }, error),

            React.createElement('form', { 
                key: 'form',
                onSubmit: handleSubmit,
                className: 'space-y-6'
            }, [
                // Email field
                (authMode === 'signin' || authMode === 'signup') && React.createElement('div', { 
                    key: 'email-group'
                }, [
                    React.createElement('label', { 
                        key: 'email-label',
                        className: 'block text-sm font-semibold text-gray-700 mb-2'
                    }, 'Email'),
                    React.createElement('input', {
                        key: 'email-input',
                        type: 'email',
                        className: 'w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all duration-200',
                        value: formData.email,
                        onChange: (e) => updateFormData('email', e.target.value),
                        required: true,
                        placeholder: 'Enter your email'
                    })
                ]),

                // Password fields
                (authMode === 'signin' || authMode === 'signup') && React.createElement('div', { 
                    key: 'password-group'
                }, [
                    React.createElement('label', { 
                        key: 'password-label',
                        className: 'block text-sm font-semibold text-gray-700 mb-2'
                    }, 'Password'),
                    React.createElement('input', {
                        key: 'password-input',
                        type: 'password',
                        className: 'w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all duration-200',
                        value: formData.password,
                        onChange: (e) => updateFormData('password', e.target.value),
                        required: true,
                        placeholder: 'Enter your password'
                    })
                ]),

                // Confirm password
                authMode === 'signup' && React.createElement('div', { 
                    key: 'confirm-password-group'
                }, [
                    React.createElement('label', { 
                        key: 'confirm-password-label',
                        className: 'block text-sm font-semibold text-gray-700 mb-2'
                    }, 'Confirm Password'),
                    React.createElement('input', {
                        key: 'confirm-password-input',
                        type: 'password',
                        className: 'w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all duration-200',
                        value: formData.confirmPassword,
                        onChange: (e) => updateFormData('confirmPassword', e.target.value),
                        required: true,
                        placeholder: 'Confirm your password'
                    })
                ]),

                // Verification code
                authMode === 'verify' && React.createElement('div', { 
                    key: 'code-group'
                }, [
                    React.createElement('label', { 
                        key: 'code-label',
                        className: 'block text-sm font-semibold text-gray-700 mb-2'
                    }, 'Verification Code'),
                    React.createElement('input', {
                        key: 'code-input',
                        type: 'text',
                        className: 'w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all duration-200 text-center text-lg tracking-widest',
                        value: formData.verificationCode,
                        onChange: (e) => updateFormData('verificationCode', e.target.value.replace(/\D/g, '').slice(0, 6)),
                        required: true,
                        placeholder: '000000',
                        maxLength: 6
                    }),
                    React.createElement('p', { 
                        key: 'code-help',
                        className: 'text-sm text-gray-500 mt-2 text-center'
                    }, 'Check your email for the 6-digit code')
                ]),

                // Submit button
                React.createElement('button', {
                    key: 'submit',
                    type: 'submit',
                    className: 'w-full bg-gradient-to-r from-indigo-600 to-purple-600 text-white py-3 px-4 rounded-xl font-semibold hover:from-indigo-700 hover:to-purple-700 focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition-all duration-200 shadow-lg disabled:opacity-50',
                    disabled: loading
                }, loading ? 'Please wait...' : 
                    authMode === 'verify' ? 'Verify & Sign In' :
                    authMode === 'signup' ? 'Create Account' : 'Sign In')
            ]),

            // Mode switching
            React.createElement('div', { 
                key: 'actions',
                className: 'mt-6 text-center space-y-2'
            }, [
                authMode === 'signin' && React.createElement('p', { 
                    key: 'signup-link',
                    className: 'text-sm text-gray-600'
                }, [
                    'Don\'t have an account? ',
                    React.createElement('button', {
                        key: 'signup-btn',
                        type: 'button',
                        className: 'text-indigo-600 font-semibold hover:text-indigo-700 transition-colors',
                        onClick: () => switchMode('signup')
                    }, 'Sign up')
                ]),

                authMode === 'signup' && React.createElement('p', { 
                    key: 'signin-link',
                    className: 'text-sm text-gray-600'
                }, [
                    'Already have an account? ',
                    React.createElement('button', {
                        key: 'signin-btn',
                        type: 'button',
                        className: 'text-indigo-600 font-semibold hover:text-indigo-700 transition-colors',
                        onClick: () => switchMode('signin')
                    }, 'Sign in')
                ]),

                authMode === 'verify' && React.createElement('p', { 
                    key: 'resend-link',
                    className: 'text-sm text-gray-600'
                }, [
                    'Didn\'t receive the code? ',
                    React.createElement('button', {
                        key: 'resend-btn',
                        type: 'button',
                        className: 'text-indigo-600 font-semibold hover:text-indigo-700 transition-colors',
                        onClick: resendCode
                    }, 'Resend')
                ])
            ])
        ])
    ]));
};

// Modern Header Component
const Header = ({ user, onSignOut }) => {
    return React.createElement('header', { 
        className: 'bg-white/80 backdrop-blur-xl border-b border-gray-200/50 sticky top-0 z-50'
    }, React.createElement('div', { 
        className: 'max-w-7xl mx-auto px-4 sm:px-6 lg:px-8'
    }, React.createElement('div', { 
        className: 'flex justify-between items-center h-16'
    }, [
        React.createElement('div', { 
            key: 'brand',
            className: 'flex items-center space-x-3'
        }, [
            React.createElement('div', { 
                key: 'logo',
                className: 'w-10 h-10 bg-gradient-to-r from-indigo-600 to-purple-600 rounded-xl flex items-center justify-center shadow-lg'
            }, React.createElement('span', { className: 'text-xl font-bold text-white' }, '✓')),
            React.createElement('div', { key: 'brand-text' }, [
                React.createElement('h1', { 
                    key: 'title',
                    className: 'text-xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent'
                }, 'TaskFlow'),
                React.createElement('p', { 
                    key: 'subtitle',
                    className: 'text-xs text-gray-500 font-medium'
                }, 'AI-Powered Todo Management')
            ])
        ]),
        React.createElement('div', { 
            key: 'user-section',
            className: 'flex items-center space-x-4'
        }, [
            React.createElement('div', { 
                key: 'user-info',
                className: 'hidden sm:flex items-center space-x-3'
            }, [
                React.createElement('div', { 
                    key: 'avatar',
                    className: 'w-8 h-8 bg-gradient-to-r from-indigo-500 to-purple-500 rounded-full flex items-center justify-center text-white text-sm font-semibold'
                }, getInitials(user?.username || 'User')),
                React.createElement('span', { 
                    key: 'username',
                    className: 'text-sm font-medium text-gray-700'
                }, user?.username || 'User')
            ]),
            React.createElement('button', {
                key: 'signout',
                onClick: onSignOut,
                className: 'px-4 py-2 text-sm font-medium text-gray-700 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors'
            }, 'Sign Out')
        ])
    ])));
};

// AI Text Extraction Component
const AITextExtractorComponent = ({ onExtractTodos }) => {
    const [text, setText] = useState('');
    const [extractedTodos, setExtractedTodos] = useState([]);
    const [isExtracting, setIsExtracting] = useState(false);
    const [showExtracted, setShowExtracted] = useState(false);

    const handleExtract = async () => {
        if (!text.trim()) return;
        
        setIsExtracting(true);
        try {
            const todos = await AITextExtractor.extractTodos(text);
            setExtractedTodos(todos);
            setShowExtracted(true);
        } catch (error) {
            console.error('Error extracting todos:', error);
        } finally {
            setIsExtracting(false);
        }
    };

    const handleAddTodo = (todo) => {
        onExtractTodos([{
            ...todo,
            id: generateId(),
            completed: false,
            createdAt: new Date().toISOString()
        }]);
        
        // Remove from extracted list
        setExtractedTodos(prev => prev.filter(t => t.title !== todo.title));
    };

    const handleAddAllTodos = () => {
        const todosToAdd = extractedTodos.map(todo => ({
            ...todo,
            id: generateId(),
            completed: false,
            createdAt: new Date().toISOString()
        }));
        
        onExtractTodos(todosToAdd);
        setExtractedTodos([]);
        setShowExtracted(false);
        setText('');
    };

    return React.createElement('div', {
        className: 'bg-gradient-to-r from-purple-50 to-pink-50 rounded-2xl p-6 border border-purple-100'
    }, [
        React.createElement('div', {
            key: 'header',
            className: 'flex items-center justify-between mb-4'
        }, [
            React.createElement('h3', {
                key: 'title',
                className: 'text-lg font-semibold text-gray-900 flex items-center'
            }, [
                React.createElement('span', { key: 'icon', className: 'mr-2 text-xl' }, '🧠'),
                'AI Todo Extraction'
            ]),
            React.createElement('div', {
                key: 'badge',
                className: 'px-3 py-1 bg-purple-100 text-purple-700 rounded-full text-xs font-medium'
            }, 'AI Powered')
        ]),
        
        React.createElement('div', {
            key: 'content',
            className: 'space-y-4'
        }, [
            React.createElement('div', {
                key: 'input-section'
            }, [
                React.createElement('label', {
                    key: 'label',
                    className: 'block text-sm font-medium text-gray-700 mb-2'
                }, 'Paste your text (emails, meeting notes, documents)'),
                React.createElement('textarea', {
                    key: 'textarea',
                    value: text,
                    onChange: (e) => setText(e.target.value),
                    placeholder: 'Paste your email, meeting notes, or any text containing tasks...\n\nExample:\n"We need to review the quarterly reports by Friday. Don\'t forget to schedule the team meeting for next week. Also, remember to follow up with the client about their feedback."',
                    className: 'w-full h-32 px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-purple-500 focus:border-transparent resize-none',
                    rows: 4
                })
            ]),
            
            React.createElement('div', {
                key: 'actions',
                className: 'flex justify-between items-center'
            }, [
                React.createElement('p', {
                    key: 'hint',
                    className: 'text-sm text-gray-500'
                }, 'AI will automatically detect tasks, meetings, and action items'),
                React.createElement('button', {
                    key: 'extract-btn',
                    onClick: handleExtract,
                    disabled: !text.trim() || isExtracting,
                    className: 'px-6 py-2 bg-gradient-to-r from-purple-600 to-pink-600 text-white rounded-lg font-medium hover:from-purple-700 hover:to-pink-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 flex items-center space-x-2'
                }, [
                    isExtracting && React.createElement('div', {
                        key: 'spinner',
                        className: 'w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin'
                    }),
                    React.createElement('span', { key: 'text' }, isExtracting ? 'Extracting...' : 'Extract Tasks')
                ])
            ]),
            
            // Extracted todos display
            showExtracted && extractedTodos.length > 0 && React.createElement('div', {
                key: 'extracted-todos',
                className: 'mt-6 p-4 bg-white rounded-xl border border-gray-200'
            }, [
                React.createElement('div', {
                    key: 'extracted-header',
                    className: 'flex items-center justify-between mb-4'
                }, [
                    React.createElement('h4', {
                        key: 'extracted-title',
                        className: 'font-semibold text-gray-900 flex items-center'
                    }, [
                        React.createElement('span', { key: 'icon', className: 'mr-2' }, '✨'),
                        `Found ${extractedTodos.length} potential tasks`
                    ]),
                    React.createElement('button', {
                        key: 'add-all-btn',
                        onClick: handleAddAllTodos,
                        className: 'px-4 py-2 bg-green-600 text-white rounded-lg text-sm font-medium hover:bg-green-700 transition-colors'
                    }, 'Add All')
                ]),
                React.createElement('div', {
                    key: 'extracted-list',
                    className: 'space-y-3'
                }, extractedTodos.map((todo, index) => {
                    const category = CATEGORIES.find(c => c.id === todo.category);
                    const priority = PRIORITIES.find(p => p.id === todo.priority);
                    
                    return React.createElement('div', {
                        key: index,
                        className: 'flex items-center justify-between p-3 bg-gray-50 rounded-lg'
                    }, [
                        React.createElement('div', {
                            key: 'todo-info',
                            className: 'flex-1'
                        }, [
                            React.createElement('p', {
                                key: 'title',
                                className: 'font-medium text-gray-900'
                            }, todo.title),
                            React.createElement('div', {
                                key: 'meta',
                                className: 'flex items-center space-x-2 mt-1'
                            }, [
                                React.createElement('span', {
                                    key: 'category',
                                    className: 'inline-flex items-center px-2 py-1 rounded-full text-xs font-medium',
                                    style: { backgroundColor: category.color + '20', color: category.color }
                                }, [category.icon, ' ', category.name]),
                                React.createElement('span', {
                                    key: 'priority',
                                    className: 'inline-flex items-center px-2 py-1 rounded-full text-xs font-medium',
                                    style: { backgroundColor: priority.color + '20', color: priority.color }
                                }, [priority.icon, ' ', priority.name]),
                                React.createElement('span', {
                                    key: 'confidence',
                                    className: 'text-xs text-gray-500'
                                }, `${Math.round(todo.confidence * 100)}% confidence`)
                            ])
                        ]),
                        React.createElement('button', {
                            key: 'add-btn',
                            onClick: () => handleAddTodo(todo),
                            className: 'ml-4 px-3 py-1 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 transition-colors'
                        }, 'Add')
                    ]);
                }))
            ]),
            
            showExtracted && extractedTodos.length === 0 && React.createElement('div', {
                key: 'no-todos',
                className: 'mt-6 p-4 bg-gray-50 rounded-xl text-center'
            }, [
                React.createElement('p', {
                    key: 'no-todos-text',
                    className: 'text-gray-600'
                }, 'No tasks found in the provided text. Try adding more specific action items or todo keywords.')
            ])
        ])
    ]);
};

// Enhanced Quick Add Component
const QuickAdd = ({ onAddTodo }) => {
    const [newTodo, setNewTodo] = useState({
        title: '',
        category: 'other',
        priority: 'medium'
    });
    const [showAI, setShowAI] = useState(false);

    const handleSubmit = (e) => {
        e.preventDefault();
        if (newTodo.title.trim()) {
            onAddTodo({
                ...newTodo,
                id: generateId(),
                completed: false,
                createdAt: new Date().toISOString()
            });
            setNewTodo({ title: '', category: 'other', priority: 'medium' });
        }
    };

    const handleExtractedTodos = (todos) => {
        todos.forEach(todo => onAddTodo(todo));
        setShowAI(false);
    };

    return React.createElement('div', { 
        className: 'bg-white rounded-2xl shadow-lg border border-gray-100 overflow-hidden'
    }, [
        React.createElement('div', {
            key: 'header',
            className: 'bg-gradient-to-r from-indigo-500 to-purple-600 px-6 py-4'
        }, [
            React.createElement('h2', { 
                key: 'title',
                className: 'text-xl font-bold text-white flex items-center'
            }, [
                React.createElement('span', { key: 'icon', className: 'mr-3 text-2xl' }, '✅'),
                'Add New Task'
            ]),
            React.createElement('p', {
                key: 'subtitle',
                className: 'text-indigo-100 text-sm mt-1'
            }, 'Create tasks manually or extract them with AI')
        ]),
        
        React.createElement('div', {
            key: 'content',
            className: 'p-6'
        }, [
            // Tab switcher
            React.createElement('div', {
                key: 'tabs',
                className: 'flex space-x-1 bg-gray-100 rounded-xl p-1 mb-6'
            }, [
                React.createElement('button', {
                    key: 'manual-tab',
                    onClick: () => setShowAI(false),
                    className: `flex-1 py-2 px-4 rounded-lg font-medium text-sm transition-all duration-200 ${!showAI ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-600 hover:text-gray-900'}`
                }, [
                    React.createElement('span', { key: 'icon', className: 'mr-2' }, '✏️'),
                    'Manual Entry'
                ]),
                React.createElement('button', {
                    key: 'ai-tab',
                    onClick: () => setShowAI(true),
                    className: `flex-1 py-2 px-4 rounded-lg font-medium text-sm transition-all duration-200 ${showAI ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-600 hover:text-gray-900'}`
                }, [
                    React.createElement('span', { key: 'icon', className: 'mr-2' }, '🧠'),
                    'AI Extract'
                ])
            ]),
            
            // Content based on active tab
            !showAI ? React.createElement('form', { 
                key: 'manual-form',
                onSubmit: handleSubmit,
                className: 'space-y-4'
            }, [
                React.createElement('div', {
                    key: 'title-input'
                }, [
                    React.createElement('label', {
                        key: 'title-label',
                        className: 'block text-sm font-medium text-gray-700 mb-2'
                    }, 'Task Description'),
                    React.createElement('input', {
                        key: 'title-field',
                        type: 'text',
                        className: 'w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all duration-200',
                        placeholder: 'What needs to be done?',
                        value: newTodo.title,
                        onChange: (e) => setNewTodo(prev => ({ ...prev, title: e.target.value }))
                    })
                ]),
                React.createElement('div', {
                    key: 'form-row',
                    className: 'grid grid-cols-1 sm:grid-cols-2 gap-4'
                }, [
                    React.createElement('div', {
                        key: 'category-select'
                    }, [
                        React.createElement('label', {
                            key: 'category-label',
                            className: 'block text-sm font-medium text-gray-700 mb-2'
                        }, 'Category'),
                        React.createElement('select', {
                            key: 'category-field',
                            className: 'w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all duration-200',
                            value: newTodo.category,
                            onChange: (e) => setNewTodo(prev => ({ ...prev, category: e.target.value }))
                        }, CATEGORIES.map(cat => 
                            React.createElement('option', {
                                key: cat.id,
                                value: cat.id
                            }, `${cat.icon} ${cat.name}`)
                        ))
                    ]),
                    React.createElement('div', {
                        key: 'priority-select'
                    }, [
                        React.createElement('label', {
                            key: 'priority-label',
                            className: 'block text-sm font-medium text-gray-700 mb-2'
                        }, 'Priority'),
                        React.createElement('select', {
                            key: 'priority-field',
                            className: 'w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all duration-200',
                            value: newTodo.priority,
                            onChange: (e) => setNewTodo(prev => ({ ...prev, priority: e.target.value }))
                        }, PRIORITIES.map(pri => 
                            React.createElement('option', {
                                key: pri.id,
                                value: pri.id
                            }, `${pri.icon} ${pri.name}`)
                        ))
                    ])
                ]),
                React.createElement('button', {
                    key: 'submit',
                    type: 'submit',
                    className: 'w-full bg-gradient-to-r from-indigo-600 to-purple-600 text-white py-3 px-4 rounded-xl font-semibold hover:from-indigo-700 hover:to-purple-700 transition-all duration-200 shadow-lg'
                }, 'Add Task')
            ]) : React.createElement(AITextExtractorComponent, {
                key: 'ai-extractor',
                onExtractTodos: handleExtractedTodos
            })
        ])
    ]);
};

// Modern Todo List Component
const TodoList = ({ todos, loading, filter, onFilterChange, onUpdateTodo, onDeleteTodo }) => {
    const filteredTodos = todos.filter(todo => {
        if (filter === 'completed') return todo.completed;
        if (filter === 'pending') return !todo.completed;
        return true;
    });

    const todoStats = {
        total: todos.length,
        completed: todos.filter(t => t.completed).length,
        pending: todos.filter(t => !t.completed).length
    };

    const filters = [
        { id: 'all', name: 'All Tasks', icon: '📋', count: todoStats.total },
        { id: 'pending', name: 'Pending', icon: '⏳', count: todoStats.pending },
        { id: 'completed', name: 'Completed', icon: '✅', count: todoStats.completed }
    ];

    if (loading) {
        return React.createElement('div', {
            className: 'bg-white rounded-2xl shadow-lg border border-gray-100 p-8'
        }, React.createElement('div', {
            className: 'flex items-center justify-center'
        }, [
            React.createElement('div', {
                key: 'spinner',
                className: 'w-8 h-8 border-4 border-indigo-200 border-t-indigo-600 rounded-full animate-spin'
            }),
            React.createElement('span', {
                key: 'text',
                className: 'ml-3 text-gray-600'
            }, 'Loading tasks...')
        ]));
    }

    return React.createElement('div', { 
        className: 'bg-white rounded-2xl shadow-lg border border-gray-100 overflow-hidden'
    }, [
        React.createElement('div', {
            key: 'header',
            className: 'bg-gradient-to-r from-gray-50 to-gray-100 px-6 py-5 border-b border-gray-200'
        }, [
            React.createElement('div', {
                key: 'title-section',
                className: 'flex items-center justify-between mb-4'
            }, [
                React.createElement('h2', { 
                    key: 'title',
                    className: 'text-xl font-bold text-gray-900 flex items-center'
                }, [
                    React.createElement('span', { key: 'icon', className: 'mr-3 text-2xl' }, '📝'),
                    'Your Tasks'
                ]),
                React.createElement('div', {
                    key: 'stats',
                    className: 'flex items-center space-x-4 text-sm'
                }, [
                    React.createElement('span', {
                        key: 'total',
                        className: 'px-3 py-1 bg-gray-200 text-gray-700 rounded-full font-medium'
                    }, `${todoStats.total} total`),
                    React.createElement('span', {
                        key: 'pending',
                        className: 'px-3 py-1 bg-orange-100 text-orange-700 rounded-full font-medium'
                    }, `${todoStats.pending} pending`),
                    React.createElement('span', {
                        key: 'completed',
                        className: 'px-3 py-1 bg-green-100 text-green-700 rounded-full font-medium'
                    }, `${todoStats.completed} done`)
                ])
            ]),
            React.createElement('div', { 
                key: 'filters',
                className: 'flex space-x-2'
            }, filters.map(filterOption =>
                React.createElement('button', {
                    key: filterOption.id,
                    onClick: () => onFilterChange(filterOption.id),
                    className: `px-4 py-2 rounded-xl font-medium text-sm transition-all duration-200 ${
                        filter === filterOption.id 
                            ? 'bg-indigo-600 text-white shadow-lg' 
                            : 'bg-white text-gray-600 hover:bg-gray-50 border border-gray-200'
                    }`
                }, [
                    React.createElement('span', { key: 'icon', className: 'mr-2' }, filterOption.icon),
                    filterOption.name,
                    React.createElement('span', {
                        key: 'count',
                        className: `ml-2 px-2 py-0.5 rounded-full text-xs ${
                            filter === filterOption.id 
                                ? 'bg-white/20 text-white' 
                                : 'bg-gray-100 text-gray-600'
                        }`
                    }, filterOption.count)
                ])
            ))
        ]),
        
        React.createElement('div', { 
            key: 'todo-list',
            className: 'divide-y divide-gray-100'
        }, filteredTodos.length === 0 ? 
            React.createElement('div', { 
                key: 'empty',
                className: 'px-6 py-12 text-center'
            }, [
                React.createElement('div', { 
                    key: 'icon',
                    className: 'text-6xl mb-4 opacity-50'
                }, filter === 'completed' ? '🎉' : filter === 'pending' ? '⏳' : '📝'),
                React.createElement('h3', {
                    key: 'title',
                    className: 'text-lg font-medium text-gray-900 mb-2'
                }, filter === 'completed' ? 'No completed tasks yet' : 
                    filter === 'pending' ? 'No pending tasks' : 'No tasks found'),
                React.createElement('p', {
                    key: 'subtitle',
                    className: 'text-gray-500'
                }, filter === 'completed' ? 'Complete some tasks to see them here!' :
                    filter === 'pending' ? 'All caught up! 🎯' : 'Create your first task above')
            ]) :
            filteredTodos.map(todo =>
                React.createElement(TodoItem, {
                    key: todo.id,
                    todo,
                    onUpdate: onUpdateTodo,
                    onDelete: onDeleteTodo
                })
            )
        )
    ]);
};

// Enhanced Todo Item Component
const TodoItem = ({ todo, onUpdate, onDelete }) => {
    const [isHovered, setIsHovered] = useState(false);
    const category = CATEGORIES.find(c => c.id === todo.category) || CATEGORIES[6];
    const priority = PRIORITIES.find(p => p.id === todo.priority) || PRIORITIES[1];

    return React.createElement('div', { 
        className: `px-6 py-4 transition-all duration-200 ${
            todo.completed 
                ? 'bg-green-50/50 hover:bg-green-50' 
                : isHovered 
                    ? 'bg-indigo-50' 
                    : 'hover:bg-gray-50'
        }`,
        onMouseEnter: () => setIsHovered(true),
        onMouseLeave: () => setIsHovered(false)
    }, React.createElement('div', {
        className: 'flex items-center space-x-4'
    }, [
        React.createElement('button', {
            key: 'checkbox',
            onClick: () => onUpdate(todo.id, { completed: !todo.completed }),
            className: `flex-shrink-0 w-6 h-6 rounded-full border-2 transition-all duration-200 flex items-center justify-center ${
                todo.completed 
                    ? 'bg-green-500 border-green-500 text-white' 
                    : isHovered 
                        ? 'border-indigo-400 bg-indigo-50' 
                        : 'border-gray-300 hover:border-indigo-400'
            }`
        }, todo.completed && React.createElement('svg', {
            className: 'w-3 h-3',
            fill: 'currentColor',
            viewBox: '0 0 20 20'
        }, React.createElement('path', {
            fillRule: 'evenodd',
            d: 'M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z',
            clipRule: 'evenodd'
        }))),
        
        React.createElement('div', { 
            key: 'content',
            className: 'flex-1 min-w-0'
        }, [
            React.createElement('p', { 
                key: 'title',
                className: `font-medium transition-all duration-200 ${
                    todo.completed 
                        ? 'text-gray-500 line-through' 
                        : 'text-gray-900'
                }`
            }, todo.title),
            React.createElement('div', { 
                key: 'meta',
                className: 'flex items-center space-x-3 mt-2'
            }, [
                React.createElement('span', {
                    key: 'category',
                    className: 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium transition-all duration-200',
                    style: { 
                        backgroundColor: todo.completed ? '#E5E7EB' : category.color + '15', 
                        color: todo.completed ? '#6B7280' : category.color 
                    }
                }, [category.icon, ' ', category.name]),
                React.createElement('span', {
                    key: 'priority',
                    className: 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium transition-all duration-200',
                    style: { 
                        backgroundColor: todo.completed ? '#E5E7EB' : priority.color + '15', 
                        color: todo.completed ? '#6B7280' : priority.color 
                    }
                }, [priority.icon, ' ', priority.name]),
                todo.createdAt && React.createElement('span', {
                    key: 'date',
                    className: 'text-xs text-gray-400'
                }, formatDate(todo.createdAt))
            ])
        ]),
        
        React.createElement('div', {
            key: 'actions',
            className: `flex items-center space-x-2 transition-opacity duration-200 ${
                isHovered ? 'opacity-100' : 'opacity-0'
            }`
        }, [
            React.createElement('button', {
                key: 'delete',
                onClick: () => onDelete(todo.id),
                className: 'p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-lg transition-all duration-200'
            }, React.createElement('svg', {
                className: 'w-4 h-4',
                fill: 'none',
                stroke: 'currentColor',
                viewBox: '0 0 24 24'
            }, React.createElement('path', {
                strokeLinecap: 'round',
                strokeLinejoin: 'round',
                strokeWidth: 2,
                d: 'M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16'
            })))
        ])
    ]));
};

// Main Todo App Component
const TodoApp = () => {
    const auth = useFlowlessAuth();
    const [todos, setTodos] = useState([]);
    const [loading, setLoading] = useState(false);
    const [filter, setFilter] = useState('all');

    useEffect(() => {
        if (auth.user) {
            loadTodos();
        }
    }, [auth.user]);

    const loadTodos = async () => {
        try {
            setLoading(true);
            const response = await apiCall('/todos');
            setTodos(response.todos || []);
        } catch (error) {
            console.error('❌ Failed to load todos:', error);
        } finally {
            setLoading(false);
        }
    };

    const addTodo = async (todoData) => {
        try {
            const response = await apiCall('/todos', 'POST', todoData);
            setTodos(prev => [...prev, response.todo]);
        } catch (error) {
            console.error('❌ Failed to add todo:', error);
        }
    };

    const updateTodo = async (id, updates) => {
        try {
            await apiCall(`/todos/${id}`, 'PUT', updates);
            setTodos(prev => prev.map(todo => 
                todo.id === id ? { ...todo, ...updates } : todo
            ));
        } catch (error) {
            console.error('❌ Failed to update todo:', error);
        }
    };

    const deleteTodo = async (id) => {
        try {
            await apiCall(`/todos/${id}`, 'DELETE');
            setTodos(prev => prev.filter(todo => todo.id !== id));
        } catch (error) {
            console.error('❌ Failed to delete todo:', error);
        }
    };

    if (auth.loading) {
        return React.createElement(LoadingScreen, { message: 'Loading...' });
    }

    if (auth.configError) {
        return React.createElement(LoadingScreen, { 
            message: 'Configuration Required', 
            error: true, 
            showHelp: true 
        });
    }

    if (!auth.user) {
        return React.createElement(AuthScreen, { auth });
    }

    return React.createElement('div', { 
        className: 'min-h-screen bg-gradient-to-br from-indigo-50 via-white to-purple-50'
    }, [
        React.createElement(Header, { 
            key: 'header',
            user: auth.user, 
            onSignOut: auth.signOut 
        }),
        React.createElement('main', { 
            key: 'main',
            className: 'max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8'
        }, React.createElement('div', {
            className: 'space-y-8'
        }, [
            React.createElement(QuickAdd, { 
                key: 'quick-add',
                onAddTodo: addTodo 
            }),
            React.createElement(TodoList, { 
                key: 'todo-list',
                todos,
                loading,
                filter,
                onFilterChange: setFilter,
                onUpdateTodo: updateTodo,
                onDeleteTodo: deleteTodo
            })
        ]))
    ]);
};

// Export the main app to global scope
window.TodoApp = TodoApp;

console.log('✅ Modern AI-Powered TodoApp loaded successfully');

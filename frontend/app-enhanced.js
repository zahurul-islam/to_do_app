// Enhanced Todo App with Signup Support - React 18 Compatible
// Configuration loader
let AWS_CONFIG = {
    region: 'us-west-2',
    userPoolId: 'loading...',
    userPoolClientId: 'loading...',
    apiGatewayUrl: 'loading...'
};

// Load configuration from Terraform-generated config.json
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

// Utility functions
const formatDate = (date) => {
    if (!date) return '';
    try {
        return new Date(date).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    } catch (error) {
        console.error('Error formatting date:', error);
        return '';
    }
};

const getInitials = (email) => {
    if (!email || typeof email !== 'string') return 'U';
    try {
        const parts = email.split('@')[0].split('.');
        return parts.map(part => part.charAt(0).toUpperCase()).join('').slice(0, 2);
    } catch (error) {
        console.error('Error getting initials:', error);
        return 'U';
    }
};

const generateId = () => {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
};

// Categories and priorities
const CATEGORIES = [
    { id: 'work', name: 'Work', color: '#FF6B6B', icon: '💼' },
    { id: 'personal', name: 'Personal', color: '#4ECDC4', icon: '👤' },
    { id: 'health', name: 'Health', color: '#45B7D1', icon: '🏃' },
    { id: 'learning', name: 'Learning', color: '#96CEB4', icon: '📚' },
    { id: 'shopping', name: 'Shopping', color: '#FFEAA7', icon: '🛒' },
    { id: 'other', name: 'Other', color: '#DDA0DD', icon: '📝' }
];

const PRIORITIES = [
    { id: 'low', name: 'Low', color: '#3B82F6' },
    { id: 'medium', name: 'Medium', color: '#F59E0B' },
    { id: 'high', name: 'High', color: '#EF4444' }
];
// Enhanced API Helper Functions
const apiCall = async (endpoint, method = 'GET', data = null, retries = 3) => {
    if (authInitPromise) {
        await authInitPromise;
    }
    
    for (let i = 0; i < retries; i++) {
        try {
            let token = '';
            if (authInitialized && aws_amplify?.Auth) {
                try {
                    const session = await aws_amplify.Auth.currentSession();
                    token = session.getIdToken().getJwtToken();
                } catch (authError) {
                    console.warn('⚠️ No valid session, API calls might fail.');
                    throw authError;
                }
            } else {
                throw new Error('Authentication not initialized. Cannot make API calls.');
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
                const errorText = await response.text();
                throw new Error(`API Error: ${response.status} - ${errorText}`);
            }

            const responseData = await response.json();
            return responseData;
        } catch (error) {
            console.error(`API call failed (attempt ${i + 1}):`, error);
            if (i === retries - 1) throw error;
            await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
        }
    }
};

// Enhanced Authentication Hook with Signup Support
const useAuth = () => {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const checkAuth = async () => {
            if (authInitPromise) {
                await authInitPromise;
            }
            
            try {
                if (authInitialized && aws_amplify?.Auth) {
                    const currentUser = await aws_amplify.Auth.currentAuthenticatedUser();
                    setUser(currentUser);
                    console.log('✅ User authenticated:', currentUser.username);
                }
            } catch (error) {
                console.log('ℹ️ No authenticated user found');
                setUser(null);
            } finally {
                setLoading(false);
            }
        };

        checkAuth();
    }, []);

    const signUp = async (email, password) => {
        try {
            setLoading(true);
            const result = await aws_amplify.Auth.signUp({
                username: email,
                password: password,
                attributes: {
                    email: email
                }
            });
            console.log('✅ Sign up successful:', result);
            return result;
        } catch (error) {
            console.error('❌ Sign up error:', error);
            throw error;
        } finally {
            setLoading(false);
        }
    };

    const confirmSignUp = async (email, confirmationCode) => {
        try {
            setLoading(true);
            const result = await aws_amplify.Auth.confirmSignUp(email, confirmationCode);
            console.log('✅ Email confirmed successfully');
            return result;
        } catch (error) {
            console.error('❌ Confirmation error:', error);
            throw error;
        } finally {
            setLoading(false);
        }
    };

    const signIn = async (email, password) => {
        try {
            setLoading(true);
            const user = await aws_amplify.Auth.signIn(email, password);
            setUser(user);
            console.log('✅ Sign in successful');
            return user;
        } catch (error) {
            console.error('❌ Sign in error:', error);
            throw error;
        } finally {
            setLoading(false);
        }
    };

    const completeNewPassword = async (user, newPassword) => {
        try {
            setLoading(true);
            const result = await aws_amplify.Auth.completeNewPassword(user, newPassword);
            setUser(result);
            console.log('✅ Password changed successfully');
            return result;
        } catch (error) {
            console.error('❌ Password change error:', error);
            throw error;
        } finally {
            setLoading(false);
        }
    };

    const signOut = async () => {
        try {
            setLoading(true);
            await aws_amplify.Auth.signOut();
            setUser(null);
            console.log('✅ Sign out successful');
        } catch (error) {
            console.error('❌ Sign out error:', error);
        } finally {
            setLoading(false);
        }
    };

    return { 
        user, 
        loading, 
        signUp, 
        confirmSignUp, 
        signIn, 
        completeNewPassword, 
        signOut 
    };
};
// Main Todo App Component
const TodoApp = () => {
    const { 
        user, 
        loading: authLoading, 
        signUp, 
        confirmSignUp, 
        signIn, 
        completeNewPassword, 
        signOut 
    } = useAuth();
    const [todos, setTodos] = useState([]);
    const [loading, setLoading] = useState(false);
    const [filter, setFilter] = useState('all');
    
    // Load todos when user is authenticated
    useEffect(() => {
        if (user) {
            loadTodos();
        }
    }, [user]);

    const loadTodos = async () => {
        try {
            setLoading(true);
            const response = await apiCall('/todos');
            setTodos(response.todos || []);
            console.log('✅ Todos loaded:', response.todos?.length || 0);
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
            console.log('✅ Todo added');
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
            console.log('✅ Todo updated');
        } catch (error) {
            console.error('❌ Failed to update todo:', error);
        }
    };

    const deleteTodo = async (id) => {
        try {
            await apiCall(`/todos/${id}`, 'DELETE');
            setTodos(prev => prev.filter(todo => todo.id !== id));
            console.log('✅ Todo deleted');
        } catch (error) {
            console.error('❌ Failed to delete todo:', error);
        }
    };

    if (authLoading) {
        return React.createElement('div', {
            className: 'loading-state'
        }, React.createElement('div', {
            className: 'loading-content'
        }, [
            React.createElement('div', { 
                key: 'spinner',
                className: 'loading-spinner' 
            }),
            React.createElement('p', { 
                key: 'text',
                style: { marginTop: '1rem', color: '#64748B' }
            }, 'Checking authentication...')
        ]));
    }

    if (!user) {
        return React.createElement(EnhancedAuthForm, { 
            onSignUp: signUp,
            onConfirmSignUp: confirmSignUp,
            onSignIn: signIn,
            onCompleteNewPassword: completeNewPassword
        });
    }

    return React.createElement('div', { className: 'app-container' }, [
        React.createElement(Header, { 
            key: 'header',
            user, 
            onSignOut: signOut 
        }),
        React.createElement('main', { 
            key: 'main',
            style: { 
                flex: 1,
                maxWidth: '1200px',
                margin: '0 auto',
                padding: '2rem',
                width: '100%'
            }
        }, [
            React.createElement(QuickAddPanel, { 
                key: 'quick-add',
                onAddTodo: addTodo 
            }),
            React.createElement(TodoSection, { 
                key: 'todos',
                todos,
                loading,
                filter,
                onFilterChange: setFilter,
                onUpdateTodo: updateTodo,
                onDeleteTodo: deleteTodo
            })
        ])
    ]);
};
// Fixed Enhanced Authentication Form with Proper Confirmation Flow
const EnhancedAuthForm = ({ onSignUp, onConfirmSignUp, onSignIn, onCompleteNewPassword }) => {
    const [authMode, setAuthMode] = useState('login'); // 'login', 'signup', 'confirm', 'newPassword'
    const [formData, setFormData] = useState({ 
        email: '', 
        password: '', 
        confirmPassword: '', 
        confirmationCode: '' 
    });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [successMessage, setSuccessMessage] = useState('');
    const [tempUser, setTempUser] = useState(null);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        setSuccessMessage('');
        
        try {
            switch (authMode) {
                case 'signup':
                    if (formData.password !== formData.confirmPassword) {
                        throw new Error('Passwords do not match');
                    }
                    if (formData.password.length < 8) {
                        throw new Error('Password must be at least 8 characters long');
                    }
                    
                    console.log('🔄 Attempting signup for:', formData.email);
                    const signUpResult = await onSignUp(formData.email, formData.password);
                    console.log('✅ Signup result:', signUpResult);
                    
                    // Check for successful signup (different possible response structures)
                    if (signUpResult && (signUpResult.userSub || signUpResult.user || !signUpResult.userConfirmed)) {
                        setAuthMode('confirm');
                        setSuccessMessage('Account created! Please check your email for a verification code.');
                    } else {
                        throw new Error('Signup failed - unexpected response format');
                    }
                    break;
                    
                case 'confirm':
                    if (!formData.confirmationCode || formData.confirmationCode.length < 6) {
                        throw new Error('Please enter a valid confirmation code');
                    }
                    
                    console.log('🔄 Confirming email for:', formData.email);
                    await onConfirmSignUp(formData.email, formData.confirmationCode);
                    console.log('✅ Email confirmed successfully');
                    
                    setAuthMode('login');
                    setSuccessMessage('Email confirmed! You can now sign in.');
                    setFormData(prev => ({ ...prev, confirmationCode: '' }));
                    break;
                    
                case 'login':
                    if (!formData.email || !formData.password) {
                        throw new Error('Please enter both email and password');
                    }
                    
                    try {
                        console.log('🔄 Attempting login for:', formData.email);
                        await onSignIn(formData.email, formData.password);
                        console.log('✅ Login successful');
                    } catch (loginError) {
                        console.log('❌ Login error:', loginError);
                        
                        // Handle specific error cases
                        if (loginError.code === 'UserNotConfirmedException') {
                            setAuthMode('confirm');
                            setError('Please confirm your email first. Check your inbox for a verification code.');
                        } else if (loginError.code === 'NewPasswordRequired') {
                            setTempUser(loginError.user);
                            setAuthMode('newPassword');
                            setSuccessMessage('Please set a new password to continue.');
                        } else {
                            throw loginError;
                        }
                    }
                    break;
                    
                case 'newPassword':
                    if (formData.password !== formData.confirmPassword) {
                        throw new Error('Passwords do not match');
                    }
                    if (formData.password.length < 8) {
                        throw new Error('Password must be at least 8 characters long');
                    }
                    
                    console.log('🔄 Setting new password');
                    await onCompleteNewPassword(tempUser, formData.password);
                    console.log('✅ Password updated successfully');
                    break;
                    
                default:
                    throw new Error('Invalid authentication mode');
            }
        } catch (error) {
            console.error('❌ Auth error:', error);
            setError(error.message || 'Authentication failed');
        } finally {
            setLoading(false);
        }
    };

    const renderFormFields = () => {
        const fields = [];
        
        // Email field (for all modes except newPassword and when already have email)
        if (authMode !== 'newPassword' && (authMode !== 'confirm' || !formData.email)) {
            fields.push(React.createElement('div', { 
                key: 'email-group',
                style: { marginBottom: '1.5rem' }
            }, [
                React.createElement('label', { 
                    key: 'email-label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#334155',
                        marginBottom: '0.5rem'
                    }
                }, 'Email'),
                React.createElement('input', {
                    key: 'email-input',
                    type: 'email',
                    className: 'form-input',
                    value: formData.email,
                    onChange: (e) => setFormData(prev => ({
                        ...prev,
                        email: e.target.value
                    })),
                    required: true,
                    disabled: authMode === 'confirm' && formData.email,
                    placeholder: 'Enter your email address'
                })
            ]));
        }

        // Show email as read-only in confirm mode if we have it
        if (authMode === 'confirm' && formData.email) {
            fields.push(React.createElement('div', { 
                key: 'email-display',
                style: { marginBottom: '1.5rem' }
            }, [
                React.createElement('label', { 
                    key: 'email-label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#334155',
                        marginBottom: '0.5rem'
                    }
                }, 'Email'),
                React.createElement('div', {
                    key: 'email-display-value',
                    style: {
                        padding: '0.875rem 1rem',
                        border: '2px solid #E2E8F0',
                        borderRadius: '0.75rem',
                        backgroundColor: '#F8FAFC',
                        color: '#64748B',
                        fontSize: '0.875rem'
                    }
                }, formData.email)
            ]));
        }

        // Password field (for login, signup, newPassword)
        if (authMode === 'login' || authMode === 'signup' || authMode === 'newPassword') {
            fields.push(React.createElement('div', { 
                key: 'password-group',
                style: { marginBottom: '1.5rem' }
            }, [
                React.createElement('label', { 
                    key: 'password-label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#334155',
                        marginBottom: '0.5rem'
                    }
                }, authMode === 'newPassword' ? 'New Password' : 'Password'),
                React.createElement('input', {
                    key: 'password-input',
                    type: 'password',
                    className: 'form-input',
                    value: formData.password,
                    onChange: (e) => setFormData(prev => ({
                        ...prev,
                        password: e.target.value
                    })),
                    required: true,
                    minLength: authMode === 'signup' || authMode === 'newPassword' ? 8 : undefined,
                    placeholder: authMode === 'newPassword' ? 'Enter new password (min 8 characters)' : 'Enter your password'
                })
            ]));
        }

        // Confirm Password field (for signup and newPassword)
        if (authMode === 'signup' || authMode === 'newPassword') {
            fields.push(React.createElement('div', { 
                key: 'confirm-password-group',
                style: { marginBottom: '1.5rem' }
            }, [
                React.createElement('label', { 
                    key: 'confirm-password-label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#334155',
                        marginBottom: '0.5rem'
                    }
                }, 'Confirm Password'),
                React.createElement('input', {
                    key: 'confirm-password-input',
                    type: 'password',
                    className: 'form-input',
                    value: formData.confirmPassword,
                    onChange: (e) => setFormData(prev => ({
                        ...prev,
                        confirmPassword: e.target.value
                    })),
                    required: true,
                    placeholder: 'Confirm your password'
                })
            ]));
        }

        // Confirmation Code field (for confirm mode)
        if (authMode === 'confirm') {
            fields.push(React.createElement('div', { 
                key: 'code-group',
                style: { marginBottom: '1.5rem' }
            }, [
                React.createElement('label', { 
                    key: 'code-label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#334155',
                        marginBottom: '0.5rem'
                    }
                }, 'Verification Code'),
                React.createElement('input', {
                    key: 'code-input',
                    type: 'text',
                    className: 'form-input',
                    value: formData.confirmationCode,
                    onChange: (e) => setFormData(prev => ({
                        ...prev,
                        confirmationCode: e.target.value
                    })),
                    required: true,
                    placeholder: 'Enter 6-digit code from email',
                    maxLength: 6,
                    style: {
                        textAlign: 'center',
                        fontSize: '1.25rem',
                        letterSpacing: '0.5rem',
                        fontFamily: 'monospace'
                    }
                })
            ]));
        }

        return fields;
    };

    const getFormTitle = () => {
        switch (authMode) {
            case 'signup': return 'Create Account';
            case 'confirm': return 'Verify Email';
            case 'newPassword': return 'Set New Password';
            default: return 'Sign In';
        }
    };

    const getFormSubtitle = () => {
        switch (authMode) {
            case 'signup': return 'Create your TaskFlow account';
            case 'confirm': return 'Check your email for a verification code';
            case 'newPassword': return 'Choose a secure password';
            default: return 'Welcome back to TaskFlow';
        }
    };

    const getButtonText = () => {
        if (loading) return 'Processing...';
        switch (authMode) {
            case 'signup': return 'Create Account';
            case 'confirm': return 'Verify Email';
            case 'newPassword': return 'Set Password';
            default: return 'Sign In';
        }
    };

    const renderBottomLinks = () => {
        switch (authMode) {
            case 'login':
                return React.createElement('div', {
                    key: 'login-links',
                    style: { textAlign: 'center' }
                }, [
                    React.createElement('p', { 
                        key: 'text',
                        style: { marginBottom: '0.5rem', color: '#64748B', fontSize: '0.875rem' }
                    }, "Don't have an account?"),
                    React.createElement('button', {
                        key: 'signup-btn',
                        type: 'button',
                        onClick: () => {
                            setAuthMode('signup');
                            setError('');
                            setSuccessMessage('');
                        },
                        style: {
                            background: 'none',
                            border: 'none',
                            color: '#FF6B6B',
                            fontWeight: '600',
                            cursor: 'pointer',
                            textDecoration: 'underline',
                            fontSize: '0.875rem'
                        }
                    }, 'Create an account')
                ]);
                
            case 'signup':
            case 'confirm':
                return React.createElement('div', {
                    key: 'back-links',
                    style: { textAlign: 'center' }
                }, [
                    React.createElement('button', {
                        key: 'login-btn',
                        type: 'button',
                        onClick: () => {
                            setAuthMode('login');
                            setError('');
                            setSuccessMessage('');
                        },
                        style: {
                            background: 'none',
                            border: 'none',
                            color: '#FF6B6B',
                            fontWeight: '600',
                            cursor: 'pointer',
                            textDecoration: 'underline',
                            fontSize: '0.875rem'
                        }
                    }, 'Back to Sign In'),
                    authMode === 'confirm' && React.createElement('div', {
                        key: 'resend',
                        style: { marginTop: '0.5rem' }
                    }, [
                        React.createElement('button', {
                            key: 'resend-btn',
                            type: 'button',
                            onClick: () => {
                                // TODO: Implement resend confirmation code
                                setSuccessMessage('Verification code resent to your email');
                            },
                            style: {
                                background: 'none',
                                border: 'none',
                                color: '#64748B',
                                fontSize: '0.75rem',
                                cursor: 'pointer',
                                textDecoration: 'underline'
                            }
                        }, "Didn't receive the code? Resend")
                    ])
                ]);
                
            default:
                return null;
        }
    };

    return React.createElement('div', { 
        style: { 
            minHeight: '100vh',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: 'linear-gradient(135deg, #FF6B6B 0%, #4ECDC4 100%)'
        }
    }, React.createElement('div', { 
        style: {
            background: 'white',
            borderRadius: '1.5rem',
            padding: '3rem',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
            width: '100%',
            maxWidth: '400px',
            margin: '2rem'
        }
    }, [
        // Header
        React.createElement('div', { 
            key: 'header',
            style: { textAlign: 'center', marginBottom: '2rem' }
        }, [
            React.createElement('div', { 
                key: 'logo',
                style: {
                    width: '64px',
                    height: '64px',
                    background: '#FF6B6B',
                    borderRadius: '1rem',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '2rem',
                    color: 'white',
                    margin: '0 auto 1rem'
                }
            }, '✓'),
            React.createElement('h1', { 
                key: 'title',
                style: {
                    fontSize: '1.5rem',
                    fontWeight: '800',
                    color: '#1E293B',
                    marginBottom: '0.5rem'
                }
            }, getFormTitle()),
            React.createElement('p', { 
                key: 'subtitle',
                style: {
                    color: '#475569',
                    fontSize: '0.875rem'
                }
            }, getFormSubtitle())
        ]),
        
        // Form
        React.createElement('form', { 
            key: 'form',
            onSubmit: handleSubmit 
        }, [
            // Form fields
            ...renderFormFields(),
            
            // Success message
            successMessage && React.createElement('div', {
                key: 'success',
                style: {
                    background: '#22C55E',
                    color: 'white',
                    padding: '1rem',
                    borderRadius: '0.75rem',
                    marginBottom: '1.5rem',
                    fontSize: '0.875rem',
                    textAlign: 'center'
                }
            }, successMessage),
            
            // Error message
            error && React.createElement('div', {
                key: 'error',
                className: 'error-message',
                style: {
                    background: '#EF4444',
                    color: 'white',
                    padding: '1rem',
                    borderRadius: '0.75rem',
                    marginBottom: '1.5rem',
                    fontSize: '0.875rem'
                }
            }, error),
            
            // Submit button
            React.createElement('button', {
                key: 'submit',
                type: 'submit',
                className: 'btn btn-primary',
                disabled: loading,
                style: { 
                    width: '100%', 
                    marginBottom: '1.5rem',
                    backgroundColor: loading ? '#94A3B8' : '#FF6B6B',
                    cursor: loading ? 'not-allowed' : 'pointer'
                }
            }, getButtonText()),
            
            // Bottom links
            renderBottomLinks()
        ])
    ]));
};
// Header Component (same as before)
const Header = ({ user, onSignOut }) => {
    return React.createElement('header', { 
        style: {
            background: 'linear-gradient(135deg, #FF6B6B 0%, #E55A5A 100%)',
            color: 'white',
            padding: '1.5rem 0',
            boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)',
            position: 'sticky',
            top: 0,
            zIndex: 1000
        }
    }, React.createElement('div', { 
        style: {
            maxWidth: '1200px',
            margin: '0 auto',
            padding: '0 2rem',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center'
        }
    }, [
        React.createElement('div', { 
            key: 'logo-section',
            style: { display: 'flex', alignItems: 'center', gap: '1rem' }
        }, [
            React.createElement('div', { 
                key: 'logo',
                style: {
                    width: '48px',
                    height: '48px',
                    background: 'white',
                    borderRadius: '1rem',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '1.5rem',
                    color: '#FF6B6B',
                    fontWeight: '700'
                }
            }, '✓'),
            React.createElement('div', { key: 'brand-info' }, [
                React.createElement('h1', { 
                    key: 'title',
                    style: { fontSize: '1.75rem', fontWeight: '800', marginBottom: '0.25rem' }
                }, 'TaskFlow'),
                React.createElement('p', { 
                    key: 'subtitle',
                    style: { fontSize: '0.875rem', opacity: 0.9, fontWeight: '500' }
                }, 'Todo Application')
            ])
        ]),
        React.createElement('div', { 
            key: 'user-section',
            style: { display: 'flex', alignItems: 'center', gap: '1rem' }
        }, [
            React.createElement('div', { 
                key: 'avatar',
                style: {
                    width: '40px',
                    height: '40px',
                    borderRadius: '50%',
                    background: 'rgba(255, 255, 255, 0.2)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '1rem',
                    fontWeight: '600'
                }
            }, getInitials(user?.username || 'User')),
            React.createElement('button', {
                key: 'signout',
                onClick: onSignOut,
                style: {
                    background: 'rgba(255, 255, 255, 0.1)',
                    color: 'white',
                    border: '1px solid rgba(255, 255, 255, 0.2)',
                    padding: '0.75rem 1.5rem',
                    borderRadius: '0.75rem',
                    fontWeight: '600',
                    fontSize: '0.875rem',
                    cursor: 'pointer'
                }
            }, 'Sign Out')
        ])
    ]));
};

// Quick Add Panel Component (simplified version)
const QuickAddPanel = ({ onAddTodo }) => {
    const [newTodo, setNewTodo] = useState({
        title: '',
        category: 'other',
        priority: 'medium'
    });

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

    return React.createElement('div', { 
        style: {
            background: 'white',
            borderRadius: '1.5rem',
            padding: '2rem',
            boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)',
            border: '1px solid #E2E8F0',
            marginBottom: '2rem'
        }
    }, [
        React.createElement('h2', { 
            key: 'title',
            style: {
                fontSize: '1.25rem',
                fontWeight: '700',
                color: '#1E293B',
                marginBottom: '1.5rem'
            }
        }, '✓ Quick Add Task'),
        React.createElement('form', { 
            key: 'form',
            onSubmit: handleSubmit 
        }, React.createElement('div', { 
            style: { display: 'flex', gap: '0.5rem', marginBottom: '1rem' }
        }, [
            React.createElement('input', {
                key: 'title',
                type: 'text',
                className: 'form-input',
                placeholder: 'Enter your task...',
                value: newTodo.title,
                onChange: (e) => setNewTodo(prev => ({
                    ...prev,
                    title: e.target.value
                })),
                style: { flex: 1 }
            }),
            React.createElement('button', {
                key: 'submit',
                type: 'submit',
                className: 'btn btn-primary'
            }, 'Add Task')
        ]))
    ]);
};

// Simple Todo Section Component
const TodoSection = ({ todos, loading, filter, onFilterChange, onUpdateTodo, onDeleteTodo }) => {
    const filteredTodos = todos.filter(todo => {
        if (filter === 'completed') return todo.completed;
        if (filter === 'pending') return !todo.completed;
        return true; // 'all'
    });

    if (loading) {
        return React.createElement('div', { 
            style: { textAlign: 'center', padding: '2rem' }
        }, [
            React.createElement('div', { 
                key: 'spinner',
                className: 'loading-spinner' 
            }),
            React.createElement('p', { 
                key: 'text',
                style: { marginTop: '1rem', color: '#64748B' }
            }, 'Loading tasks...')
        ]);
    }

    return React.createElement('div', { 
        style: {
            background: 'white',
            borderRadius: '1.5rem',
            padding: '2rem',
            boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)',
            border: '1px solid #E2E8F0'
        }
    }, [
        React.createElement('h2', { 
            key: 'title',
            style: {
                fontSize: '1.25rem',
                fontWeight: '700',
                color: '#1E293B',
                marginBottom: '1.5rem'
            }
        }, '📝 Your Tasks'),
        React.createElement('div', { 
            key: 'todo-list',
            style: { display: 'flex', flexDirection: 'column', gap: '1rem' }
        }, filteredTodos.length === 0 ? [
            React.createElement('div', { 
                key: 'empty',
                style: { textAlign: 'center', padding: '3rem', color: '#64748B' }
            }, [
                React.createElement('div', { 
                    key: 'icon',
                    style: { fontSize: '3rem', marginBottom: '1rem' }
                }, '📝'),
                React.createElement('p', { key: 'text' }, 'No tasks yet. Add your first task above!')
            ])
        ] : filteredTodos.map(todo =>
            React.createElement(TodoItem, {
                key: todo.id,
                todo,
                onUpdate: onUpdateTodo,
                onDelete: onDeleteTodo
            })
        ))
    ]);
};

// Simple Todo Item Component
const TodoItem = ({ todo, onUpdate, onDelete }) => {
    return React.createElement('div', { 
        style: { 
            display: 'flex', 
            alignItems: 'center', 
            padding: '1rem',
            background: todo.completed ? '#22C55E20' : '#F8FAFC',
            borderRadius: '1rem',
            border: '2px solid #E2E8F0',
            marginBottom: '0.5rem'
        }
    }, [
        React.createElement('div', {
            key: 'checkbox',
            onClick: () => onUpdate(todo.id, { completed: !todo.completed }),
            style: {
                width: '24px',
                height: '24px',
                borderRadius: '6px',
                border: '2px solid #CBD5E1',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: 'pointer',
                backgroundColor: todo.completed ? '#22C55E' : 'white',
                borderColor: todo.completed ? '#22C55E' : '#CBD5E1',
                color: 'white',
                marginRight: '1rem'
            }
        }, todo.completed ? '✓' : ''),
        React.createElement('div', { 
            key: 'content',
            style: { flex: 1 }
        }, React.createElement('div', { 
            style: { 
                fontSize: '1rem', 
                fontWeight: '500',
                textDecoration: todo.completed ? 'line-through' : 'none',
                color: todo.completed ? '#64748B' : '#1E293B'
            }
        }, todo.title)),
        React.createElement('button', {
            key: 'delete',
            onClick: () => onDelete(todo.id),
            style: {
                backgroundColor: '#EF4444',
                color: 'white',
                border: 'none',
                borderRadius: '6px',
                width: '28px',
                height: '28px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: 'pointer',
                fontSize: '0.75rem'
            }
        }, '×')
    ]);
};

// Export the main app to global scope for mounting
window.TodoApp = TodoApp;

console.log('✅ Enhanced TodoApp with Signup support loaded successfully');
// Unified Todo App with Truly Flowless Authentication
// Single file, seamless experience, no complex flows

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
                
                // Validate that we have proper AWS resource IDs
                if (config.userPoolId && config.userPoolId !== 'loading...' && 
                    config.userPoolClientId && config.userPoolClientId !== 'loading...' &&
                    config.apiGatewayUrl && config.apiGatewayUrl !== 'loading...') {
                    
                    AWS_CONFIG = { ...AWS_CONFIG, ...config };
                    console.log('✅ Configuration loaded successfully:', AWS_CONFIG);
                    return true;
                } else {
                    console.warn('⚠️ Config loaded but missing valid AWS resource IDs');
                    console.warn('Config received:', config);
                    return false;
                }
            } else {
                console.warn('⚠️ Config.json returned HTML instead of JSON - deployment incomplete');
                return false;
            }
        } else {
            console.warn('⚠️ Config.json not found (HTTP ' + response.status + ') - run ./deploy.sh first');
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
            console.error('💡 Please run: ./deploy.sh to deploy the infrastructure first');
            resolve(false);
            return;
        }
        
        // Validate configuration before proceeding
        if (!AWS_CONFIG.userPoolId || !AWS_CONFIG.userPoolClientId) {
            console.error('❌ Missing required AWS Cognito configuration');
            console.error('Current config:', AWS_CONFIG);
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
                console.error('❌ AWS Amplify not available - check CDN loading');
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
const { useState, useEffect, useCallback } = React;

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

// Flowless Authentication Hook
const useFlowlessAuth = () => {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);
    const [authMode, setAuthMode] = useState('signin'); // signin, signup, verify
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
            
            // Use email as username since Cognito is configured for email login
            const result = await aws_amplify.Auth.signUp({
                username: formData.email,
                password: formData.password,
                attributes: { 
                    email: formData.email,
                    preferred_username: formData.email.split('@')[0] // Use part before @ as preferred username
                }
            });
            
            setPendingUser(result.user);
            setAuthMode('verify');
            console.log('✅ Signup successful, verification needed');
        } catch (error) {
            console.error('❌ Signup failed:', error);
            
            // Handle specific errors
            if (error.code === 'UsernameExistsException') {
                setError('Account already exists. Try signing in instead.');
                setAuthMode('signin');
            } else if (error.code === 'InvalidParameterException') {
                // Try with a generated username instead
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
                    
                    setPendingUser({ ...result.user, email: formData.email }); // Store email for later use
                    setAuthMode('verify');
                    console.log('✅ Signup successful with generated username, verification needed');
                } catch (retryError) {
                    console.error('❌ Retry signup failed:', retryError);
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
            
            // Try signing in with email as username
            const user = await aws_amplify.Auth.signIn(formData.email, formData.password);
            setUser(user);
            console.log('✅ Sign in successful');
        } catch (error) {
            console.error('❌ Sign in failed:', error);
            
            // Handle unverified users
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
            
            // Use the username from pendingUser, or fallback to email
            const usernameToVerify = pendingUser?.username || formData.email;
            
            await aws_amplify.Auth.confirmSignUp(
                usernameToVerify,
                formData.verificationCode
            );
            
            // Auto sign in after verification - use email for sign in
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
            
            // Use the username from pendingUser, or fallback to email
            const usernameToResend = pendingUser?.username || formData.email;
            
            await aws_amplify.Auth.resendSignUp(usernameToResend);
            console.log('✅ Verification code resent');
            
            // Show success message briefly
            const originalError = error;
            setError('✅ New verification code sent to your email');
            setTimeout(() => {
                setError('');
            }, 3000);
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

    return React.createElement('div', { className: 'app-container' }, [
        React.createElement(Header, { 
            key: 'header',
            user: auth.user, 
            onSignOut: auth.signOut 
        }),
        React.createElement(MainContent, { 
            key: 'main',
            todos, loading, filter,
            onFilterChange: setFilter,
            onAddTodo: addTodo,
            onUpdateTodo: updateTodo,
            onDeleteTodo: deleteTodo
        })
    ]);
};

// Enhanced Loading Screen Component
const LoadingScreen = ({ message = 'Loading...', error = false, showHelp = false }) => {
    return React.createElement('div', { 
        className: 'loading-state' 
    }, React.createElement('div', { 
        className: 'loading-content',
        style: { textAlign: 'center', maxWidth: '500px', padding: '2rem' }
    }, [
        !error && React.createElement('div', { 
            key: 'spinner',
            className: 'loading-spinner' 
        }),
        error && React.createElement('div', {
            key: 'error-icon',
            style: { fontSize: '3rem', color: '#EF4444', marginBottom: '1rem' }
        }, '⚠️'),
        React.createElement('p', { 
            key: 'text',
            style: { 
                marginTop: '1rem', 
                color: error ? '#EF4444' : '#64748B',
                fontSize: '1rem',
                fontWeight: error ? '600' : '400'
            }
        }, message),
        showHelp && React.createElement('div', {
            key: 'help',
            style: { 
                marginTop: '2rem', 
                padding: '1.5rem',
                background: '#F1F5F9',
                borderRadius: '1rem',
                textAlign: 'left',
                fontSize: '0.875rem',
                color: '#475569'
            }
        }, [
            React.createElement('h3', {
                key: 'help-title',
                style: { margin: '0 0 1rem 0', color: '#1E293B', fontSize: '1rem' }
            }, '🚀 Quick Setup'),
            React.createElement('ol', {
                key: 'help-steps',
                style: { margin: 0, paddingLeft: '1.5rem' }
            }, [
                React.createElement('li', { key: 'step1', style: { marginBottom: '0.5rem' } }, 'Open terminal in project directory'),
                React.createElement('li', { key: 'step2', style: { marginBottom: '0.5rem' } }, 'Run: ./deploy.sh'),
                React.createElement('li', { key: 'step3', style: { marginBottom: '0.5rem' } }, 'Wait for deployment to complete'),
                React.createElement('li', { key: 'step4' }, 'Refresh this page')
            ])
        ])
    ]));
};

// Unified Authentication Screen
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
        className: 'auth-container' 
    }, React.createElement('div', { 
        className: 'auth-card' 
    }, [
        React.createElement('div', { 
            key: 'header',
            className: 'auth-header' 
        }, [
            React.createElement('div', { 
                key: 'logo',
                className: 'auth-logo' 
            }, '✓'),
            React.createElement('h1', { 
                key: 'title',
                className: 'auth-title' 
            }, 'TaskFlow'),
            React.createElement('p', { 
                key: 'subtitle',
                className: 'auth-subtitle' 
            }, authMode === 'verify' ? 'Verify your email' : 
                authMode === 'signup' ? 'Create your account' : 'Welcome back')
        ]),

        // Error message
        error && React.createElement('div', {
            key: 'error',
            className: 'error-message'
        }, error),

        // Auth form
        React.createElement('form', { 
            key: 'form',
            onSubmit: handleSubmit,
            className: 'auth-form'
        }, [
            // Email field (for signin and signup)
            (authMode === 'signin' || authMode === 'signup') && React.createElement('div', { 
                key: 'email-group',
                className: 'form-group' 
            }, [
                React.createElement('label', { 
                    key: 'email-label',
                    className: 'form-label' 
                }, 'Email'),
                React.createElement('input', {
                    key: 'email-input',
                    type: 'email',
                    className: 'form-input',
                    value: formData.email,
                    onChange: (e) => updateFormData('email', e.target.value),
                    required: true,
                    placeholder: 'Enter your email'
                })
            ]),

            // Password field (for signin and signup)
            (authMode === 'signin' || authMode === 'signup') && React.createElement('div', { 
                key: 'password-group',
                className: 'form-group' 
            }, [
                React.createElement('label', { 
                    key: 'password-label',
                    className: 'form-label' 
                }, 'Password'),
                React.createElement('input', {
                    key: 'password-input',
                    type: 'password',
                    className: 'form-input',
                    value: formData.password,
                    onChange: (e) => updateFormData('password', e.target.value),
                    required: true,
                    placeholder: 'Enter your password'
                })
            ]),

            // Confirm password field (for signup only)
            authMode === 'signup' && React.createElement('div', { 
                key: 'confirm-password-group',
                className: 'form-group' 
            }, [
                React.createElement('label', { 
                    key: 'confirm-password-label',
                    className: 'form-label' 
                }, 'Confirm Password'),
                React.createElement('input', {
                    key: 'confirm-password-input',
                    type: 'password',
                    className: 'form-input',
                    value: formData.confirmPassword,
                    onChange: (e) => updateFormData('confirmPassword', e.target.value),
                    required: true,
                    placeholder: 'Confirm your password'
                })
            ]),

            // Verification code field (for verify only)
            authMode === 'verify' && React.createElement('div', { 
                key: 'code-group',
                className: 'form-group' 
            }, [
                React.createElement('label', { 
                    key: 'code-label',
                    className: 'form-label' 
                }, 'Verification Code'),
                React.createElement('input', {
                    key: 'code-input',
                    type: 'text',
                    className: 'form-input',
                    value: formData.verificationCode,
                    onChange: (e) => updateFormData('verificationCode', e.target.value),
                    required: true,
                    placeholder: 'Enter 6-digit code',
                    maxLength: 6,
                    pattern: '[0-9]{6}'
                }),
                React.createElement('p', { 
                    key: 'code-help',
                    className: 'form-help' 
                }, 'Check your email for the verification code')
            ]),

            // Submit button
            React.createElement('button', {
                key: 'submit',
                type: 'submit',
                className: 'btn btn-primary btn-full',
                disabled: loading
            }, loading ? 'Please wait...' : 
                authMode === 'verify' ? 'Verify & Sign In' :
                authMode === 'signup' ? 'Create Account' : 'Sign In')
        ]),

        // Mode switching and additional actions
        React.createElement('div', { 
            key: 'actions',
            className: 'auth-actions' 
        }, [
            // Mode switching
            authMode === 'signin' && React.createElement('p', { 
                key: 'signup-link',
                className: 'auth-link' 
            }, [
                'Don\'t have an account? ',
                React.createElement('button', {
                    key: 'signup-btn',
                    type: 'button',
                    className: 'link-button',
                    onClick: () => switchMode('signup')
                }, 'Sign up')
            ]),

            authMode === 'signup' && React.createElement('p', { 
                key: 'signin-link',
                className: 'auth-link' 
            }, [
                'Already have an account? ',
                React.createElement('button', {
                    key: 'signin-btn',
                    type: 'button',
                    className: 'link-button',
                    onClick: () => switchMode('signin')
                }, 'Sign in')
            ]),

            // Resend code for verification
            authMode === 'verify' && React.createElement('p', { 
                key: 'resend-link',
                className: 'auth-link' 
            }, [
                'Didn\'t receive the code? ',
                React.createElement('button', {
                    key: 'resend-btn',
                    type: 'button',
                    className: 'link-button',
                    onClick: resendCode
                }, 'Resend')
            ])
        ])
    ]));
};

// Header Component
const Header = ({ user, onSignOut }) => {
    return React.createElement('header', { 
        className: 'app-header' 
    }, React.createElement('div', { 
        className: 'header-content' 
    }, [
        React.createElement('div', { 
            key: 'brand',
            className: 'header-brand' 
        }, [
            React.createElement('div', { 
                key: 'logo',
                className: 'header-logo' 
            }, '✓'),
            React.createElement('div', { 
                key: 'brand-text' 
            }, [
                React.createElement('h1', { 
                    key: 'title',
                    className: 'header-title' 
                }, 'TaskFlow'),
                React.createElement('p', { 
                    key: 'subtitle',
                    className: 'header-subtitle' 
                }, 'Smart Todo Management')
            ])
        ]),
        React.createElement('div', { 
            key: 'user-section',
            className: 'header-user' 
        }, [
            React.createElement('div', { 
                key: 'avatar',
                className: 'user-avatar' 
            }, getInitials(user?.username || 'User')),
            React.createElement('span', { 
                key: 'username',
                className: 'user-name' 
            }, user?.username || 'User'),
            React.createElement('button', {
                key: 'signout',
                onClick: onSignOut,
                className: 'btn btn-outline'
            }, 'Sign Out')
        ])
    ]));
};

// Main Content Component
const MainContent = ({ todos, loading, filter, onFilterChange, onAddTodo, onUpdateTodo, onDeleteTodo }) => {
    return React.createElement('main', { 
        className: 'main-content' 
    }, [
        React.createElement(QuickAdd, { 
            key: 'quick-add',
            onAddTodo 
        }),
        React.createElement(TodoList, { 
            key: 'todo-list',
            todos, loading, filter,
            onFilterChange,
            onUpdateTodo,
            onDeleteTodo
        })
    ]);
};

// Quick Add Component
const QuickAdd = ({ onAddTodo }) => {
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
        className: 'quick-add' 
    }, [
        React.createElement('h2', { 
            key: 'title',
            className: 'section-title' 
        }, '✅ Quick Add Task'),
        React.createElement('form', { 
            key: 'form',
            onSubmit: handleSubmit,
            className: 'quick-add-form'
        }, [
            React.createElement('input', {
                key: 'title',
                type: 'text',
                className: 'form-input',
                placeholder: 'What needs to be done?',
                value: newTodo.title,
                onChange: (e) => setNewTodo(prev => ({ ...prev, title: e.target.value }))
            }),
            React.createElement('select', {
                key: 'category',
                className: 'form-select',
                value: newTodo.category,
                onChange: (e) => setNewTodo(prev => ({ ...prev, category: e.target.value }))
            }, CATEGORIES.map(cat => 
                React.createElement('option', {
                    key: cat.id,
                    value: cat.id
                }, `${cat.icon} ${cat.name}`)
            )),
            React.createElement('select', {
                key: 'priority',
                className: 'form-select',
                value: newTodo.priority,
                onChange: (e) => setNewTodo(prev => ({ ...prev, priority: e.target.value }))
            }, PRIORITIES.map(pri => 
                React.createElement('option', {
                    key: pri.id,
                    value: pri.id
                }, pri.name)
            )),
            React.createElement('button', {
                key: 'submit',
                type: 'submit',
                className: 'btn btn-primary'
            }, 'Add Task')
        ])
    ]);
};

// Todo List Component
const TodoList = ({ todos, loading, filter, onFilterChange, onUpdateTodo, onDeleteTodo }) => {
    const filteredTodos = todos.filter(todo => {
        if (filter === 'completed') return todo.completed;
        if (filter === 'pending') return !todo.completed;
        return true;
    });

    const filters = [
        { id: 'all', name: 'All Tasks', icon: '📋' },
        { id: 'pending', name: 'Pending', icon: '⏳' },
        { id: 'completed', name: 'Completed', icon: '✅' }
    ];

    if (loading) {
        return React.createElement(LoadingScreen, { message: 'Loading tasks...' });
    }

    return React.createElement('div', { 
        className: 'todo-list' 
    }, [
        React.createElement('div', { 
            key: 'header',
            className: 'todo-list-header' 
        }, [
            React.createElement('h2', { 
                key: 'title',
                className: 'section-title' 
            }, '📝 Your Tasks'),
            React.createElement('div', { 
                key: 'filters',
                className: 'todo-filters' 
            }, filters.map(filterOption =>
                React.createElement('button', {
                    key: filterOption.id,
                    onClick: () => onFilterChange(filterOption.id),
                    className: `filter-btn ${filter === filterOption.id ? 'active' : ''}`
                }, `${filterOption.icon} ${filterOption.name}`)
            ))
        ]),
        React.createElement('div', { 
            key: 'list',
            className: 'todo-items' 
        }, filteredTodos.length === 0 ? 
            React.createElement('div', { 
                key: 'empty',
                className: 'empty-state' 
            }, [
                React.createElement('div', { 
                    key: 'icon',
                    className: 'empty-icon' 
                }, '📝'),
                React.createElement('p', { 
                    key: 'text',
                    className: 'empty-text' 
                }, filter === 'completed' ? 'No completed tasks yet' : 
                    filter === 'pending' ? 'No pending tasks' : 'No tasks found')
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

// Todo Item Component
const TodoItem = ({ todo, onUpdate, onDelete }) => {
    const category = CATEGORIES.find(c => c.id === todo.category) || CATEGORIES[5];
    const priority = PRIORITIES.find(p => p.id === todo.priority) || PRIORITIES[1];

    return React.createElement('div', { 
        className: `todo-item ${todo.completed ? 'completed' : ''}` 
    }, [
        React.createElement('div', {
            key: 'checkbox',
            onClick: () => onUpdate(todo.id, { completed: !todo.completed }),
            className: `todo-checkbox ${todo.completed ? 'checked' : ''}`
        }, todo.completed ? '✓' : ''),
        
        React.createElement('div', { 
            key: 'content',
            className: 'todo-content' 
        }, [
            React.createElement('div', { 
                key: 'title',
                className: 'todo-title' 
            }, todo.title),
            React.createElement('div', { 
                key: 'meta',
                className: 'todo-meta' 
            }, [
                React.createElement('span', {
                    key: 'category',
                    className: 'todo-tag',
                    style: { backgroundColor: category.color }
                }, `${category.icon} ${category.name}`),
                React.createElement('span', {
                    key: 'priority',
                    className: 'todo-tag',
                    style: { backgroundColor: priority.color }
                }, priority.name),
                todo.createdAt && React.createElement('span', {
                    key: 'date',
                    className: 'todo-date'
                }, formatDate(todo.createdAt))
            ])
        ]),
        
        React.createElement('button', {
            key: 'delete',
            onClick: () => onDelete(todo.id),
            className: 'todo-delete'
        }, '🗑️')
    ]);
};

// Export the main app to global scope
window.TodoApp = TodoApp;

console.log('✅ Unified TodoApp loaded successfully');

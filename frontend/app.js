// Enhanced Todo App - React 18 Compatible with AWS Cognito
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
    // Wait for config to load
    const configLoaded = await loadConfig();
    
    if (!configLoaded) {
        console.error('❌ Cannot initialize auth without config');
        resolve(false);
        return;
    }
    
    // Wait a bit for AWS Amplify setup to complete
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
    }, 1500); // Give time for AWS setup
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

// Authentication Hook
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

    const signIn = async (username, password) => {
        try {
            setLoading(true);
            const user = await aws_amplify.Auth.signIn(username, password);
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

    return { user, loading, signIn, signOut };
};
// Main Todo App Component
const TodoApp = () => {
    const { user, loading: authLoading, signIn, signOut } = useAuth();
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
        return React.createElement(LoginForm, { onSignIn: signIn });
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
// Login Form Component
const LoginForm = ({ onSignIn }) => {
    const [credentials, setCredentials] = useState({ username: '', password: '' });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        
        try {
            await onSignIn(credentials.username, credentials.password);
        } catch (error) {
            setError(error.message || 'Failed to sign in');
        } finally {
            setLoading(false);
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
            }, 'TaskFlow'),
            React.createElement('p', { 
                key: 'subtitle',
                style: {
                    color: '#475569',
                    fontSize: '0.875rem'
                }
            }, 'Sign in to your account')
        ]),
        React.createElement('form', { 
            key: 'form',
            onSubmit: handleSubmit 
        }, [
            React.createElement('div', { 
                key: 'username-group',
                style: { marginBottom: '1.5rem' }
            }, [
                React.createElement('label', { 
                    key: 'username-label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#334155',
                        marginBottom: '0.5rem'
                    }
                }, 'Username'),
                React.createElement('input', {
                    key: 'username-input',
                    type: 'text',
                    className: 'form-input',
                    value: credentials.username,
                    onChange: (e) => setCredentials(prev => ({
                        ...prev,
                        username: e.target.value
                    })),
                    required: true
                })
            ]),
            React.createElement('div', { 
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
                }, 'Password'),
                React.createElement('input', {
                    key: 'password-input',
                    type: 'password',
                    className: 'form-input',
                    value: credentials.password,
                    onChange: (e) => setCredentials(prev => ({
                        ...prev,
                        password: e.target.value
                    })),
                    required: true
                })
            ]),
            error && React.createElement('div', {
                key: 'error',
                className: 'error-message'
            }, error),
            React.createElement('button', {
                key: 'submit',
                type: 'submit',
                className: 'btn btn-primary',
                disabled: loading,
                style: { width: '100%' }
            }, loading ? 'Signing in...' : 'Sign In')
        ])
    ]));
};
// Header Component
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
                }, 'Neufische Todo App')
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
                    cursor: 'pointer',
                    transition: 'all 0.15s ease-out'
                },
                onMouseEnter: (e) => {
                    e.target.style.background = 'rgba(255, 255, 255, 0.2)';
                },
                onMouseLeave: (e) => {
                    e.target.style.background = 'rgba(255, 255, 255, 0.1)';
                }
            }, 'Sign Out')
        ])
    ]));
};

// Quick Add Panel Component  
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
                marginBottom: '1.5rem',
                display: 'flex',
                alignItems: 'center',
                gap: '0.75rem'
            }
        }, [
            React.createElement('div', {
                key: 'icon',
                style: {
                    width: '32px',
                    height: '32px',
                    borderRadius: '0.75rem',
                    background: '#FF6B6B',
                    color: 'white',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '0.875rem'
                }
            }, '✓'),
            'Quick Add Task'
        ]),
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
            React.createElement('select', {
                key: 'category',
                className: 'form-input',
                value: newTodo.category,
                onChange: (e) => setNewTodo(prev => ({
                    ...prev,
                    category: e.target.value
                })),
                style: { minWidth: '120px' }
            }, CATEGORIES.map(cat => 
                React.createElement('option', {
                    key: cat.id,
                    value: cat.id
                }, `${cat.icon} ${cat.name}`)
            )),
            React.createElement('select', {
                key: 'priority',
                className: 'form-input',
                value: newTodo.priority,
                onChange: (e) => setNewTodo(prev => ({
                    ...prev,
                    priority: e.target.value
                })),
                style: { minWidth: '100px' }
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
        ]))
    ]);
};
// Todo Section Component
const TodoSection = ({ todos, loading, filter, onFilterChange, onUpdateTodo, onDeleteTodo }) => {
    const filteredTodos = todos.filter(todo => {
        if (filter === 'completed') return todo.completed;
        if (filter === 'pending') return !todo.completed;
        return true; // 'all'
    });

    const filters = [
        { id: 'all', name: 'All Tasks', icon: '📋' },
        { id: 'pending', name: 'Pending', icon: '⏳' },
        { id: 'completed', name: 'Completed', icon: '✅' }
    ];

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
                marginBottom: '1.5rem',
                display: 'flex',
                alignItems: 'center',
                gap: '0.75rem'
            }
        }, [
            React.createElement('div', {
                key: 'icon',
                style: {
                    width: '32px',
                    height: '32px',
                    borderRadius: '0.75rem',
                    background: '#FF6B6B',
                    color: 'white',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '0.875rem'
                }
            }, '📝'),
            'Your Tasks'
        ]),
        React.createElement('div', { 
            key: 'filters',
            style: { display: 'flex', gap: '1rem', marginBottom: '1.5rem' }
        }, filters.map(filterOption =>
            React.createElement('button', {
                key: filterOption.id,
                onClick: () => onFilterChange(filterOption.id),
                style: {
                    padding: '0.5rem 1rem',
                    border: `2px solid ${filter === filterOption.id ? '#FF6B6B' : '#E2E8F0'}`,
                    borderRadius: '0.75rem',
                    background: filter === filterOption.id ? '#FF6B6B' : 'white',
                    color: filter === filterOption.id ? 'white' : '#475569',
                    fontSize: '0.875rem',
                    fontWeight: '500',
                    cursor: 'pointer',
                    transition: 'all 0.15s ease-out'
                }
            }, `${filterOption.icon} ${filterOption.name}`)
        )),
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
                React.createElement('p', { key: 'text' }, 'No tasks found')
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

// Todo Item Component
const TodoItem = ({ todo, onUpdate, onDelete }) => {
    const category = CATEGORIES.find(c => c.id === todo.category) || CATEGORIES[5];
    const priority = PRIORITIES.find(p => p.id === todo.priority) || PRIORITIES[1];

    return React.createElement('div', { 
        style: { 
            display: 'flex', 
            alignItems: 'center', 
            padding: '1.5rem',
            background: todo.completed ? '#22C55E20' : '#F8FAFC',
            borderRadius: '1rem',
            border: '2px solid #E2E8F0',
            marginBottom: '1rem',
            transition: 'all 0.15s ease-out'
        },
        onMouseEnter: (e) => {
            if (!todo.completed) {
                e.currentTarget.style.background = 'white';
                e.currentTarget.style.borderColor = '#FF6B6B';
                e.currentTarget.style.transform = 'translateY(-2px)';
                e.currentTarget.style.boxShadow = '0 4px 6px -1px rgba(0, 0, 0, 0.1)';
            }
        },
        onMouseLeave: (e) => {
            if (!todo.completed) {
                e.currentTarget.style.background = '#F8FAFC';
                e.currentTarget.style.borderColor = '#E2E8F0';
                e.currentTarget.style.transform = 'translateY(0)';
                e.currentTarget.style.boxShadow = 'none';
            }
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
                marginRight: '1rem',
                transition: 'all 0.15s ease-out'
            }
        }, todo.completed ? '✓' : ''),
        React.createElement('div', { 
            key: 'content',
            style: { flex: 1 }
        }, [
            React.createElement('div', { 
                key: 'title',
                style: { 
                    fontSize: '1rem', 
                    fontWeight: '500',
                    marginBottom: '0.5rem',
                    textDecoration: todo.completed ? 'line-through' : 'none',
                    color: todo.completed ? '#64748B' : '#1E293B'
                }
            }, todo.title),
            React.createElement('div', { 
                key: 'meta',
                style: { display: 'flex', gap: '0.5rem', alignItems: 'center' }
            }, [
                React.createElement('span', {
                    key: 'category',
                    style: {
                        backgroundColor: category.color,
                        color: 'white',
                        padding: '0.25rem 0.5rem',
                        borderRadius: '12px',
                        fontSize: '0.75rem',
                        fontWeight: '500'
                    }
                }, `${category.icon} ${category.name}`),
                React.createElement('span', {
                    key: 'priority',
                    style: {
                        backgroundColor: priority.color,
                        color: 'white',
                        padding: '0.25rem 0.5rem',
                        borderRadius: '12px',
                        fontSize: '0.75rem',
                        fontWeight: '500'
                    }
                }, priority.name),
                todo.createdAt && React.createElement('span', {
                    key: 'date',
                    style: {
                        color: '#64748B',
                        fontSize: '0.75rem'
                    }
                }, formatDate(todo.createdAt))
            ])
        ]),
        React.createElement('button', {
            key: 'delete',
            onClick: () => onDelete(todo.id),
            style: {
                backgroundColor: '#EF4444',
                color: 'white',
                border: 'none',
                borderRadius: '8px',
                width: '32px',
                height: '32px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: 'pointer',
                transition: 'all 0.15s ease-out'
            },
            onMouseEnter: (e) => {
                e.target.style.transform = 'scale(1.1)';
            },
            onMouseLeave: (e) => {
                e.target.style.transform = 'scale(1)';
            }
        }, '🗑️')
    ]);
};

// Export the main app to global scope for mounting
window.TodoApp = TodoApp;

console.log('✅ TodoApp components loaded successfully');
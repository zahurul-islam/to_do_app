// Continuing the Enhanced AI-Powered Todo App - Complete Implementation
// Adding the remaining components for the modern UI

// Enhanced Loading Screen Component
const LoadingScreen = ({ message = 'Loading...', error = false, showHelp = false }) => {
    return React.createElement('div', { 
        className: 'loading-state',
        style: {
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            minHeight: '100vh',
            background: 'var(--bg-primary)'
        }
    }, React.createElement('div', { 
        className: 'loading-content',
        style: { textAlign: 'center', maxWidth: '500px', padding: '2rem' }
    }, [
        !error && React.createElement('div', { 
            key: 'spinner',
            className: 'loading-spinner',
            style: {
                width: '64px',
                height: '64px',
                border: '4px solid rgba(102, 126, 234, 0.3)',
                borderTop: '4px solid #667eea',
                borderRadius: '50%',
                animation: 'spin 1s linear infinite',
                margin: '0 auto 2rem'
            }
        }),
        error && React.createElement('div', {
            key: 'error-icon',
            style: { fontSize: '4rem', color: '#ef4444', marginBottom: '2rem' }
        }, '⚠️'),
        React.createElement('h2', { 
            key: 'text',
            style: { 
                marginBottom: '1rem', 
                color: error ? '#ef4444' : 'var(--text-primary)',
                fontSize: '1.5rem',
                fontWeight: error ? '600' : '400',
                fontFamily: 'Space Grotesk, sans-serif'
            }
        }, message),
        showHelp && React.createElement('div', {
            key: 'help',
            style: { 
                marginTop: '2rem', 
                padding: '2rem',
                background: 'var(--glass-bg)',
                backdropFilter: 'blur(10px)',
                border: '1px solid var(--glass-border)',
                borderRadius: 'var(--radius-lg)',
                textAlign: 'left',
                fontSize: '0.875rem',
                color: 'var(--text-secondary)'
            }
        }, [
            React.createElement('h3', {
                key: 'help-title',
                style: { 
                    margin: '0 0 1.5rem 0', 
                    color: 'var(--text-primary)', 
                    fontSize: '1.25rem',
                    fontFamily: 'Space Grotesk, sans-serif'
                }
            }, '🚀 Quick Setup'),
            React.createElement('ol', {
                key: 'help-steps',
                style: { margin: 0, paddingLeft: '1.5rem', lineHeight: 1.8 }
            }, [
                React.createElement('li', { key: 'step1', style: { marginBottom: '0.75rem' } }, 'Open terminal in project directory'),
                React.createElement('li', { key: 'step2', style: { marginBottom: '0.75rem' } }, 'Run: ./deploy.sh'),
                React.createElement('li', { key: 'step3', style: { marginBottom: '0.75rem' } }, 'Wait for deployment to complete'),
                React.createElement('li', { key: 'step4' }, 'Refresh this page')
            ])
        ])
    ]));
};

// Enhanced Authentication Screen
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
        className: 'auth-container',
        style: {
            minHeight: '100vh',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: 'var(--bg-primary)',
            backgroundImage: `
                radial-gradient(circle at 20% 50%, rgba(120, 119, 198, 0.3) 0%, transparent 50%),
                radial-gradient(circle at 80% 20%, rgba(255, 119, 198, 0.3) 0%, transparent 50%),
                radial-gradient(circle at 40% 80%, rgba(120, 219, 255, 0.3) 0%, transparent 50%)
            `,
            padding: '2rem'
        }
    }, React.createElement('div', { 
        className: 'auth-card',
        style: {
            background: 'var(--glass-bg)',
            backdropFilter: 'blur(20px)',
            WebkitBackdropFilter: 'blur(20px)',
            border: '1px solid var(--glass-border)',
            borderRadius: 'var(--radius-lg)',
            padding: '3rem',
            boxShadow: 'var(--glass-shadow)',
            width: '100%',
            maxWidth: '400px',
            animation: 'slideUp 0.6s ease-out'
        }
    }, [
        React.createElement('div', { 
            key: 'header',
            className: 'auth-header',
            style: { textAlign: 'center', marginBottom: '2rem' }
        }, [
            React.createElement('div', { 
                key: 'logo',
                style: {
                    width: '80px',
                    height: '80px',
                    background: 'var(--primary)',
                    borderRadius: 'var(--radius)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '2rem',
                    color: 'white',
                    margin: '0 auto 1.5rem',
                    animation: 'glow 3s ease-in-out infinite'
                }
            }, '🤖'),
            React.createElement('h1', { 
                key: 'title',
                style: {
                    fontFamily: 'Space Grotesk, sans-serif',
                    fontSize: '2rem',
                    fontWeight: '800',
                    marginBottom: '0.5rem',
                    background: 'var(--primary)',
                    WebkitBackgroundClip: 'text',
                    WebkitTextFillColor: 'transparent',
                    backgroundClip: 'text'
                }
            }, 'TaskFlow AI'),
            React.createElement('p', { 
                key: 'subtitle',
                style: {
                    color: 'var(--text-secondary)',
                    fontSize: '0.875rem'
                }
            }, authMode === 'verify' ? 'Verify your email' : 
                authMode === 'signup' ? 'Create your account' : 'Welcome back')
        ]),

        // Error message
        error && React.createElement('div', {
            key: 'error',
            style: {
                background: error.startsWith('✅') ? 'var(--success)' : 'var(--error)',
                color: 'white',
                padding: '1rem',
                borderRadius: 'var(--radius)',
                marginBottom: '1.5rem',
                fontSize: '0.875rem',
                animation: 'slideIn 0.3s ease-out'
            }
        }, error),

        // Auth form
        React.createElement('form', { 
            key: 'form',
            onSubmit: handleSubmit,
            style: { marginBottom: '1.5rem' }
        }, [
            // Email field (for signin and signup)
            (authMode === 'signin' || authMode === 'signup') && React.createElement('div', { 
                key: 'email-group',
                style: { marginBottom: '1.5rem' }
            }, [
                React.createElement('label', { 
                    key: 'email-label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: 'var(--text-primary)',
                        marginBottom: '0.5rem'
                    }
                }, 'Email'),
                React.createElement('input', {
                    key: 'email-input',
                    type: 'email',
                    className: 'form-input',
                    value: formData.email,
                    onChange: (e) => updateFormData('email', e.target.value),
                    required: true,
                    placeholder: 'Enter your email',
                    style: {
                        width: '100%',
                        padding: '12px 16px',
                        background: 'rgba(255, 255, 255, 0.1)',
                        border: '1px solid var(--glass-border)',
                        borderRadius: 'var(--radius)',
                        color: 'var(--text-primary)',
                        fontSize: '0.875rem',
                        transition: 'var(--transition)'
                    }
                })
            ]),

            // Password field (for signin and signup)
            (authMode === 'signin' || authMode === 'signup') && React.createElement('div', { 
                key: 'password-group',
                style: { marginBottom: '1.5rem' }
            }, [
                React.createElement('label', { 
                    key: 'password-label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: 'var(--text-primary)',
                        marginBottom: '0.5rem'
                    }
                }, 'Password'),
                React.createElement('input', {
                    key: 'password-input',
                    type: 'password',
                    className: 'form-input',
                    value: formData.password,
                    onChange: (e) => updateFormData('password', e.target.value),
                    required: true,
                    placeholder: 'Enter your password',
                    style: {
                        width: '100%',
                        padding: '12px 16px',
                        background: 'rgba(255, 255, 255, 0.1)',
                        border: '1px solid var(--glass-border)',
                        borderRadius: 'var(--radius)',
                        color: 'var(--text-primary)',
                        fontSize: '0.875rem',
                        transition: 'var(--transition)'
                    }
                })
            ]),

            // Confirm password field (for signup only)
            authMode === 'signup' && React.createElement('div', { 
                key: 'confirm-password-group',
                style: { marginBottom: '1.5rem' }
            }, [
                React.createElement('label', { 
                    key: 'confirm-password-label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: 'var(--text-primary)',
                        marginBottom: '0.5rem'
                    }
                }, 'Confirm Password'),
                React.createElement('input', {
                    key: 'confirm-password-input',
                    type: 'password',
                    className: 'form-input',
                    value: formData.confirmPassword,
                    onChange: (e) => updateFormData('confirmPassword', e.target.value),
                    required: true,
                    placeholder: 'Confirm your password',
                    style: {
                        width: '100%',
                        padding: '12px 16px',
                        background: 'rgba(255, 255, 255, 0.1)',
                        border: '1px solid var(--glass-border)',
                        borderRadius: 'var(--radius)',
                        color: 'var(--text-primary)',
                        fontSize: '0.875rem',
                        transition: 'var(--transition)'
                    }
                })
            ]),

            // Verification code field (for verify only)
            authMode === 'verify' && React.createElement('div', { 
                key: 'code-group',
                style: { marginBottom: '1.5rem' }
            }, [
                React.createElement('label', { 
                    key: 'code-label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: 'var(--text-primary)',
                        marginBottom: '0.5rem'
                    }
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
                    pattern: '[0-9]{6}',
                    style: {
                        width: '100%',
                        padding: '12px 16px',
                        background: 'rgba(255, 255, 255, 0.1)',
                        border: '1px solid var(--glass-border)',
                        borderRadius: 'var(--radius)',
                        color: 'var(--text-primary)',
                        fontSize: '0.875rem',
                        transition: 'var(--transition)',
                        textAlign: 'center',
                        letterSpacing: '0.1em'
                    }
                }),
                React.createElement('p', { 
                    key: 'code-help',
                    style: {
                        fontSize: '0.75rem',
                        color: 'var(--text-secondary)',
                        marginTop: '0.5rem'
                    }
                }, 'Check your email for the verification code')
            ]),

            // Submit button
            React.createElement('button', {
                key: 'submit',
                type: 'submit',
                className: 'glass-button',
                disabled: loading,
                style: {
                    width: '100%',
                    padding: '12px 24px',
                    background: loading ? 'rgba(102, 126, 234, 0.6)' : 'var(--primary)',
                    color: 'white',
                    border: 'none',
                    borderRadius: 'var(--radius)',
                    fontWeight: '600',
                    cursor: loading ? 'not-allowed' : 'pointer',
                    transition: 'var(--transition)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem'
                }
            }, [
                loading && React.createElement('div', { 
                    key: 'spinner', 
                    className: 'loading-spinner',
                    style: { width: '16px', height: '16px' }
                }),
                loading ? 'Please wait...' : 
                authMode === 'verify' ? 'Verify & Sign In' :
                authMode === 'signup' ? 'Create Account' : 'Sign In'
            ])
        ]),

        // Mode switching and additional actions
        React.createElement('div', { 
            key: 'actions',
            style: { textAlign: 'center' }
        }, [
            // Mode switching
            authMode === 'signin' && React.createElement('p', { 
                key: 'signup-link',
                style: {
                    color: 'var(--text-secondary)',
                    fontSize: '0.875rem',
                    marginBottom: '0.5rem'
                }
            }, [
                'Don\'t have an account? ',
                React.createElement('button', {
                    key: 'signup-btn',
                    type: 'button',
                    onClick: () => switchMode('signup'),
                    style: {
                        background: 'none',
                        border: 'none',
                        color: 'var(--primary-solid)',
                        fontWeight: '600',
                        cursor: 'pointer',
                        textDecoration: 'underline'
                    }
                }, 'Sign up')
            ]),

            authMode === 'signup' && React.createElement('p', { 
                key: 'signin-link',
                style: {
                    color: 'var(--text-secondary)',
                    fontSize: '0.875rem',
                    marginBottom: '0.5rem'
                }
            }, [
                'Already have an account? ',
                React.createElement('button', {
                    key: 'signin-btn',
                    type: 'button',
                    onClick: () => switchMode('signin'),
                    style: {
                        background: 'none',
                        border: 'none',
                        color: 'var(--primary-solid)',
                        fontWeight: '600',
                        cursor: 'pointer',
                        textDecoration: 'underline'
                    }
                }, 'Sign in')
            ]),

            // Resend code for verification
            authMode === 'verify' && React.createElement('p', { 
                key: 'resend-link',
                style: {
                    color: 'var(--text-secondary)',
                    fontSize: '0.875rem',
                    marginBottom: '0.5rem'
                }
            }, [
                'Didn\'t receive the code? ',
                React.createElement('button', {
                    key: 'resend-btn',
                    type: 'button',
                    onClick: resendCode,
                    style: {
                        background: 'none',
                        border: 'none',
                        color: 'var(--primary-solid)',
                        fontWeight: '600',
                        cursor: 'pointer',
                        textDecoration: 'underline'
                    }
                }, 'Resend')
            ])
        ])
    ]));
};

// Enhanced Header Component
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
            }, '🤖'),
            React.createElement('div', { 
                key: 'brand-text' 
            }, [
                React.createElement('h1', { 
                    key: 'title',
                    className: 'header-title' 
                }, 'TaskFlow AI'),
                React.createElement('p', { 
                    key: 'subtitle',
                    className: 'header-subtitle' 
                }, 'Next-Generation AI-Powered Todo Management')
            ])
        ]),
        React.createElement('div', { 
            key: 'user-section',
            style: {
                display: 'flex',
                alignItems: 'center',
                gap: '1rem'
            }
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
                    fontWeight: '600',
                    color: 'white'
                }
            }, getInitials(user?.username || 'User')),
            React.createElement('span', { 
                key: 'username',
                style: {
                    fontWeight: '500',
                    color: 'white'
                }
            }, user?.username || 'User'),
            React.createElement('button', {
                key: 'signout',
                onClick: onSignOut,
                className: 'glass-button'
            }, 'Sign Out')
        ])
    ]));
};

// Enhanced Todo List Component
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

    return React.createElement('div', { className: 'todo-list' }, [
        React.createElement('h2', { key: 'title', className: 'section-title' }, ['📝', 'Your Tasks']),
        
        React.createElement('div', { key: 'filters', className: 'todo-filters' }, 
            filters.map(filterOption =>
                React.createElement('button', {
                    key: filterOption.id,
                    onClick: () => onFilterChange(filterOption.id),
                    className: `filter-btn ${filter === filterOption.id ? 'active' : ''}`,
                    style: {
                        background: filter === filterOption.id ? 'var(--primary)' : 'var(--glass-bg)',
                        border: `1px solid ${filter === filterOption.id ? 'transparent' : 'var(--glass-border)'}`,
                        borderRadius: 'var(--radius)',
                        color: filter === filterOption.id ? 'white' : 'var(--text-secondary)',
                        padding: '8px 16px',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        cursor: 'pointer',
                        transition: 'var(--transition)'
                    }
                }, `${filterOption.icon} ${filterOption.name}`)
            )
        ),
        
        React.createElement('div', { key: 'list', className: 'todo-items' }, 
            filteredTodos.length === 0 ? 
                React.createElement('div', { key: 'empty', className: 'empty-state' }, [
                    React.createElement('div', { key: 'icon', className: 'empty-icon' }, '🎯'),
                    React.createElement('p', { key: 'text', className: 'empty-text' }, 
                        filter === 'completed' ? 'No completed tasks yet' : 
                        filter === 'pending' ? 'No pending tasks' : 'No tasks found'
                    )
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
    const category = CATEGORIES.find(c => c.id === todo.category) || CATEGORIES[7];
    const priority = PRIORITIES.find(p => p.id === todo.priority) || PRIORITIES[1];

    return React.createElement('div', { 
        className: `todo-item ${todo.completed ? 'completed' : ''}`,
        style: {
            background: 'rgba(255, 255, 255, 0.05)',
            border: '1px solid var(--glass-border)',
            borderRadius: 'var(--radius)',
            padding: '1.5rem',
            transition: 'var(--transition)',
            position: 'relative',
            overflow: 'hidden',
            marginBottom: '1rem'
        }
    }, [
        React.createElement('div', { key: 'content', className: 'todo-content' }, [
            React.createElement('div', {
                key: 'checkbox',
                onClick: () => onUpdate(todo.id, { completed: !todo.completed }),
                style: {
                    width: '24px',
                    height: '24px',
                    borderRadius: '8px',
                    border: `2px solid ${todo.completed ? 'var(--success)' : 'var(--glass-border)'}`,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    cursor: 'pointer',
                    transition: 'var(--transition)',
                    background: todo.completed ? 'var(--success)' : 'transparent',
                    color: todo.completed ? 'white' : 'transparent',
                    marginRight: '1rem',
                    flexShrink: 0
                }
            }, todo.completed ? '✓' : ''),
            
            React.createElement('div', { key: 'text', style: { flex: 1 } }, [
                React.createElement('div', { 
                    key: 'title',
                    style: {
                        fontSize: '1rem',
                        fontWeight: '500',
                        marginBottom: '0.5rem',
                        color: todo.completed ? 'var(--text-muted)' : 'var(--text-primary)',
                        textDecoration: todo.completed ? 'line-through' : 'none',
                        transition: 'var(--transition)'
                    }
                }, todo.title),
                React.createElement('div', { 
                    key: 'meta',
                    style: {
                        display: 'flex',
                        gap: '0.5rem',
                        alignItems: 'center',
                        flexWrap: 'wrap'
                    }
                }, [
                    React.createElement('span', {
                        key: 'category',
                        style: {
                            background: category.color,
                            color: 'white',
                            padding: '4px 8px',
                            borderRadius: '12px',
                            fontSize: '0.75rem',
                            fontWeight: '500',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.25rem'
                        }
                    }, `${category.icon} ${category.name}`),
                    React.createElement('span', {
                        key: 'priority',
                        style: {
                            background: priority.color,
                            color: 'white',
                            padding: '4px 8px',
                            borderRadius: '12px',
                            fontSize: '0.75rem',
                            fontWeight: '500'
                        }
                    }, priority.name),
                    todo.source && React.createElement('span', {
                        key: 'source',
                        style: {
                            background: '#8b5cf6',
                            color: 'white',
                            padding: '4px 8px',
                            borderRadius: '12px',
                            fontSize: '0.75rem',
                            fontWeight: '500'
                        }
                    }, '🤖 AI'),
                    todo.dueDate && React.createElement('span', {
                        key: 'due',
                        style: {
                            background: '#f59e0b',
                            color: 'white',
                            padding: '4px 8px',
                            borderRadius: '12px',
                            fontSize: '0.75rem',
                            fontWeight: '500'
                        }
                    }, `📅 ${formatDate(todo.dueDate)}`),
                    todo.createdAt && React.createElement('span', {
                        key: 'date',
                        style: {
                            color: 'var(--text-muted)',
                            fontSize: '0.75rem'
                        }
                    }, formatDate(todo.createdAt))
                ])
            ])
        ]),
        
        React.createElement('div', { 
            key: 'actions',
            style: {
                display: 'flex',
                gap: '0.5rem',
                opacity: 0,
                transition: 'var(--transition)',
                position: 'absolute',
                right: '1rem',
                top: '50%',
                transform: 'translateY(-50%)'
            },
            className: 'todo-actions'
        }, [
            React.createElement('button', {
                key: 'delete',
                onClick: () => onDelete(todo.id),
                style: {
                    background: 'var(--error)',
                    color: 'white',
                    border: 'none',
                    borderRadius: '8px',
                    width: '36px',
                    height: '36px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    cursor: 'pointer',
                    transition: 'var(--transition)',
                    fontSize: '1rem'
                }
            }, '🗑️')
        ])
    ]);
};

// Export components to global scope for the main app
window.LoadingScreen = LoadingScreen;
window.AuthScreen = AuthScreen;
window.Header = Header;
window.TodoList = TodoList;
window.TodoItem = TodoItem;

console.log('✅ Enhanced UI Components loaded successfully');

// Enhanced Sign In Form Component
const SignInForm = ({ onSignIn, onSwitchToSignUp, onSwitchToForgot, loading }) => {
    const [credentials, setCredentials] = useState({ username: '', password: '' });
    const [formLoading, setFormLoading] = useState(false);
    const [error, setError] = useState('');

    const handleSubmit = async (e) => {
        e.preventDefault();
        setFormLoading(true);
        setError('');
        
        try {
            await onSignIn(credentials.username, credentials.password);
        } catch (error) {
            setError(error.message || 'Failed to sign in');
        } finally {
            setFormLoading(false);
        }
    };

    return React.createElement('div', { 
        style: { 
            minHeight: '100vh',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            padding: '2rem'
        }
    }, React.createElement('div', { 
        style: {
            background: 'white',
            borderRadius: '2rem',
            padding: '3rem',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
            width: '100%',
            maxWidth: '450px',
            position: 'relative',
            overflow: 'hidden'
        }
    }, [
        React.createElement('div', { 
            key: 'header',
            style: { textAlign: 'center', marginBottom: '2.5rem' }
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
            }, '✓'),
            React.createElement('h1', { 
                key: 'title',
                style: {
                    fontSize: '2rem',
                    fontWeight: '800',
                    color: '#1E293B',
                    marginBottom: '0.5rem'
                }
            }, 'Welcome Back'),
            React.createElement('p', { 
                key: 'subtitle',
                style: {
                    color: '#64748B',
                    fontSize: '1rem'
                }
            }, 'Sign in to your TaskFlow account')
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
                        color: '#374151',
                        marginBottom: '0.5rem'
                    }
                }, 'Email or Username'),
                React.createElement('input', {
                    key: 'username-input',
                    type: 'text',
                    value: credentials.username,
                    onChange: (e) => setCredentials(prev => ({
                        ...prev,
                        username: e.target.value
                    })),
                    placeholder: 'Enter your email or username',
                    style: {
                        width: '100%',
                        padding: '1rem',
                        border: '2px solid #E5E7EB',
                        borderRadius: '1rem',
                        fontSize: '1rem',
                        transition: 'border-color 0.15s ease-out',
                        background: 'white'
                    },
                    required: true
                })
            ]),
            React.createElement('div', { 
                key: 'password-group',
                style: { marginBottom: '1rem' }
            }, [
                React.createElement('label', { 
                    key: 'password-label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#374151',
                        marginBottom: '0.5rem'
                    }
                }, 'Password'),
                React.createElement('input', {
                    key: 'password-input',
                    type: 'password',
                    value: credentials.password,
                    onChange: (e) => setCredentials(prev => ({
                        ...prev,
                        password: e.target.value
                    })),
                    placeholder: 'Enter your password',
                    style: {
                        width: '100%',
                        padding: '1rem',
                        border: '2px solid #E5E7EB',
                        borderRadius: '1rem',
                        fontSize: '1rem',
                        transition: 'border-color 0.15s ease-out',
                        background: 'white'
                    },
                    required: true
                })
            ]),
            React.createElement('div', {
                key: 'forgot-link',
                style: { textAlign: 'right', marginBottom: '2rem' }
            }, React.createElement('button', {
                type: 'button',
                onClick: onSwitchToForgot,
                style: {
                    background: 'none',
                    border: 'none',
                    color: '#667eea',
                    fontSize: '0.875rem',
                    cursor: 'pointer',
                    textDecoration: 'underline'
                }
            }, 'Forgot your password?')),
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
                    border: '1px solid #FCA5A5'
                }
            }, error),
            React.createElement('button', {
                key: 'submit',
                type: 'submit',
                disabled: formLoading || loading,
                style: {
                    width: '100%',
                    background: formLoading || loading ? '#9CA3AF' : 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                    color: 'white',
                    border: 'none',
                    padding: '1rem',
                    borderRadius: '1rem',
                    fontSize: '1rem',
                    fontWeight: '600',
                    cursor: formLoading || loading ? 'not-allowed' : 'pointer',
                    transition: 'all 0.15s ease-out',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    marginBottom: '1.5rem'
                }
            }, [
                formLoading && React.createElement('div', {
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
                React.createElement('span', {
                    key: 'text'
                }, formLoading ? 'Signing in...' : 'Sign In')
            ])
        ]),
        React.createElement('div', {
            key: 'signup-link',
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
                onClick: onSwitchToSignUp,
                style: {
                    background: 'none',
                    border: 'none',
                    color: '#667eea',
                    fontSize: '0.875rem',
                    fontWeight: '600',
                    cursor: 'pointer',
                    textDecoration: 'underline'
                }
            }, 'Sign up here')
        ])
    ]));
};

// Enhanced Sign Up Form Component
const SignUpForm = ({ onSignUp, onSwitchToSignIn, loading }) => {
    const [formData, setFormData] = useState({ 
        username: '', 
        email: '', 
        password: '', 
        confirmPassword: '' 
    });
    const [formLoading, setFormLoading] = useState(false);
    const [error, setError] = useState('');

    const handleSubmit = async (e) => {
        e.preventDefault();
        setFormLoading(true);
        setError('');

        // Validation
        if (formData.password !== formData.confirmPassword) {
            setError('Passwords do not match');
            setFormLoading(false);
            return;
        }

        if (formData.password.length < 8) {
            setError('Password must be at least 8 characters long');
            setFormLoading(false);
            return;
        }
        
        try {
            await onSignUp(formData.username, formData.password, formData.email);
        } catch (error) {
            setError(error.message || 'Failed to create account');
        } finally {
            setFormLoading(false);
        }
    };

    return React.createElement('div', { 
        style: { 
            minHeight: '100vh',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            padding: '2rem'
        }
    }, React.createElement('div', { 
        style: {
            background: 'white',
            borderRadius: '2rem',
            padding: '3rem',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
            width: '100%',
            maxWidth: '450px'
        }
    }, [
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
                    margin: '0 auto 1.5rem'
                }
            }, '✓'),
            React.createElement('h1', { 
                key: 'title',
                style: {
                    fontSize: '2rem',
                    fontWeight: '800',
                    color: '#1E293B',
                    marginBottom: '0.5rem'
                }
            }, 'Create Account'),
            React.createElement('p', { 
                key: 'subtitle',
                style: {
                    color: '#64748B',
                    fontSize: '1rem'
                }
            }, 'Join TaskFlow and boost your productivity')
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
                        color: '#374151',
                        marginBottom: '0.5rem'
                    }
                }, 'Username'),
                React.createElement('input', {
                    key: 'username-input',
                    type: 'text',
                    value: formData.username,
                    onChange: (e) => setFormData(prev => ({
                        ...prev,
                        username: e.target.value
                    })),
                    placeholder: 'Choose a username',
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
            React.createElement('div', { 
                key: 'email-group',
                style: { marginBottom: '1.5rem' }
            }, [
                React.createElement('label', { 
                    key: 'email-label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#374151',
                        marginBottom: '0.5rem'
                    }
                }, 'Email'),
                React.createElement('input', {
                    key: 'email-input',
                    type: 'email',
                    value: formData.email,
                    onChange: (e) => setFormData(prev => ({
                        ...prev,
                        email: e.target.value
                    })),
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
                        color: '#374151',
                        marginBottom: '0.5rem'
                    }
                }, 'Password'),
                React.createElement('input', {
                    key: 'password-input',
                    type: 'password',
                    value: formData.password,
                    onChange: (e) => setFormData(prev => ({
                        ...prev,
                        password: e.target.value
                    })),
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
            React.createElement('div', { 
                key: 'confirm-password-group',
                style: { marginBottom: '2rem' }
            }, [
                React.createElement('label', { 
                    key: 'confirm-password-label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#374151',
                        marginBottom: '0.5rem'
                    }
                }, 'Confirm Password'),
                React.createElement('input', {
                    key: 'confirm-password-input',
                    type: 'password',
                    value: formData.confirmPassword,
                    onChange: (e) => setFormData(prev => ({
                        ...prev,
                        confirmPassword: e.target.value
                    })),
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
            error && React.createElement('div', {
                key: 'error',
                style: {
                    background: '#FEF2F2',
                    color: '#DC2626',
                    padding: '1rem',
                    borderRadius: '1rem',
                    marginBottom: '1.5rem',
                    fontSize: '0.875rem'
                }
            }, error),
            React.createElement('button', {
                key: 'submit',
                type: 'submit',
                disabled: formLoading || loading,
                style: {
                    width: '100%',
                    background: formLoading || loading ? '#9CA3AF' : 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                    color: 'white',
                    border: 'none',
                    padding: '1rem',
                    borderRadius: '1rem',
                    fontSize: '1rem',
                    fontWeight: '600',
                    cursor: formLoading || loading ? 'not-allowed' : 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    marginBottom: '1.5rem'
                }
            }, [
                formLoading && React.createElement('div', {
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
                React.createElement('span', {
                    key: 'text'
                }, formLoading ? 'Creating Account...' : 'Create Account')
            ])
        ]),
        React.createElement('div', {
            key: 'signin-link',
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
                onClick: onSwitchToSignIn,
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
    ]));
};

// Export components
window.SignInForm = SignInForm;
window.SignUpForm = SignUpForm;

console.log('✅ Authentication forms loaded successfully');

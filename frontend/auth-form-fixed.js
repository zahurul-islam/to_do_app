// Enhanced Authentication Form with Fixed Confirmation Flow
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
    const [success, setSuccess] = useState('');
    const [tempUser, setTempUser] = useState(null);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        setSuccess('');
        
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
                    
                    if (signUpResult && !signUpResult.userConfirmed) {
                        setSuccess('Account created! Please check your email for verification code.');
                        setAuthMode('confirm');
                        console.log('📧 Switching to confirmation mode');
                    } else if (signUpResult && signUpResult.userConfirmed) {
                        setSuccess('Account created and confirmed! You can now log in.');
                        setAuthMode('login');
                    }
                    break;
                    
                case 'confirm':
                    if (!formData.confirmationCode.trim()) {
                        throw new Error('Please enter the verification code');
                    }
                    
                    console.log('🔄 Confirming email for:', formData.email);
                    await onConfirmSignUp(formData.email, formData.confirmationCode);
                    setSuccess('Email confirmed! You can now log in.');
                    setAuthMode('login');
                    setFormData(prev => ({ ...prev, confirmationCode: '' }));
                    break;
                    
                case 'login':
                    try {
                        console.log('🔄 Attempting login for:', formData.email);
                        await onSignIn(formData.email, formData.password);
                    } catch (loginError) {
                        console.log('❌ Login error:', loginError);
                        
                        if (loginError.code === 'NewPasswordRequired') {
                            setTempUser(loginError.user);
                            setAuthMode('newPassword');
                            setSuccess('Please set a new password for your account.');
                        } else if (loginError.code === 'UserNotConfirmedException') {
                            setError('Please verify your email first. Check your inbox for the verification code.');
                            setAuthMode('confirm');
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
                    
                    await onCompleteNewPassword(tempUser, formData.password);
                    setSuccess('Password updated! Welcome to TaskFlow.');
                    break;
                    
                default:
                    throw new Error('Invalid authentication mode');
            }
        } catch (error) {
            console.error('❌ Authentication error:', error);
            setError(error.message || 'Authentication failed');
        } finally {
            setLoading(false);
        }
    };

    const handleResendCode = async () => {
        try {
            setLoading(true);
            setError('');
            
            // For resending verification code, we need to use the direct Cognito API
            if (window.aws_amplify?.Auth) {
                await window.aws_amplify.Auth.resendSignUp(formData.email);
                setSuccess('Verification code resent! Check your email.');
            }
        } catch (error) {
            setError('Failed to resend code: ' + error.message);
        } finally {
            setLoading(false);
        }
    };

    const renderFormFields = () => {
        const fields = [];
        
        // Email field (shown for all modes except newPassword)
        if (authMode !== 'newPassword') {
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
                    disabled: authMode === 'confirm' // Keep email readonly during confirmation
                })
            ]));
        }

        // Password field (not shown for confirm mode)
        if (authMode !== 'confirm') {
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
                    placeholder: authMode === 'signup' || authMode === 'newPassword' ? 'Minimum 8 characters' : ''
                })
            ]));
        }

        // Confirm password field (for signup and newPassword modes)
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
                    placeholder: 'Re-enter your password'
                })
            ]));
        }

        // Confirmation code field (only for confirm mode)
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
                    placeholder: 'Enter the 6-digit code from your email',
                    maxLength: 6,
                    pattern: '[0-9]{6}',
                    autoComplete: 'one-time-code'
                }),
                React.createElement('div', {
                    key: 'resend-section',
                    style: { 
                        marginTop: '0.5rem',
                        textAlign: 'center'
                    }
                }, [
                    React.createElement('button', {
                        key: 'resend-btn',
                        type: 'button',
                        onClick: handleResendCode,
                        disabled: loading,
                        style: {
                            background: 'none',
                            border: 'none',
                            color: '#FF6B6B',
                            fontSize: '0.875rem',
                            cursor: 'pointer',
                            textDecoration: 'underline'
                        }
                    }, 'Resend verification code')
                ])
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
            case 'signup': return 'Join TaskFlow today';
            case 'confirm': return `We sent a code to ${formData.email}`;
            case 'newPassword': return 'Choose a new secure password';
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

    return React.createElement('div', { 
        style: { 
            minHeight: '100vh',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            background: 'linear-gradient(135deg, #FF6B6B 0%, #4ECDC4 100%)',
            padding: '1rem'
        }
    }, React.createElement('div', { 
        style: {
            background: 'white',
            borderRadius: '1.5rem',
            padding: '3rem',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
            width: '100%',
            maxWidth: '400px'
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
            }, getFormTitle()),
            React.createElement('p', { 
                key: 'subtitle',
                style: {
                    color: '#475569',
                    fontSize: '0.875rem'
                }
            }, getFormSubtitle())
        ]),
        React.createElement('form', { 
            key: 'form',
            onSubmit: handleSubmit 
        }, [
            ...renderFormFields(),
            success && React.createElement('div', {
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
            }, success),
            error && React.createElement('div', {
                key: 'error',
                className: 'error-message'
            }, error),
            React.createElement('button', {
                key: 'submit',
                type: 'submit',
                className: 'btn btn-primary',
                disabled: loading,
                style: { width: '100%', marginBottom: '1rem' }
            }, getButtonText())
        ]),
        // Navigation buttons
        authMode === 'login' && React.createElement('div', {
            key: 'signup-toggle',
            style: { textAlign: 'center' }
        }, [
            React.createElement('p', { 
                key: 'text',
                style: { marginBottom: '0.5rem', color: '#64748B' }
            }, "Don't have an account?"),
            React.createElement('button', {
                key: 'signup-btn',
                type: 'button',
                onClick: () => {
                    setAuthMode('signup');
                    setError('');
                    setSuccess('');
                },
                style: {
                    background: 'none',
                    border: 'none',
                    color: '#FF6B6B',
                    fontWeight: '600',
                    cursor: 'pointer',
                    textDecoration: 'underline'
                }
            }, 'Create an account')
        ]),
        (authMode === 'signup' || authMode === 'confirm') && React.createElement('div', {
            key: 'back-to-login',
            style: { textAlign: 'center' }
        }, [
            React.createElement('button', {
                key: 'login-btn',
                type: 'button',
                onClick: () => {
                    setAuthMode('login');
                    setError('');
                    setSuccess('');
                },
                style: {
                    background: 'none',
                    border: 'none',
                    color: '#FF6B6B',
                    fontWeight: '600',
                    cursor: 'pointer',
                    textDecoration: 'underline'
                }
            }, 'Back to Login')
        ])
    ]));
};
// Verification and Password Reset Forms

// Email Verification Form Component
const VerificationForm = ({ username, onConfirm, onResend, onSwitchToSignIn, loading }) => {
    const [verificationCode, setVerificationCode] = useState('');
    const [formLoading, setFormLoading] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState('');
    const [resendLoading, setResendLoading] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setFormLoading(true);
        setError('');
        setSuccess('');
        
        try {
            await onConfirm(username, verificationCode);
            setSuccess('Email verified successfully! You can now sign in.');
            setTimeout(() => {
                onSwitchToSignIn();
            }, 2000);
        } catch (error) {
            setError(error.message || 'Failed to verify email');
        } finally {
            setFormLoading(false);
        }
    };

    const handleResend = async () => {
        setResendLoading(true);
        setError('');
        setSuccess('');
        
        try {
            await onResend(username);
            setSuccess('Verification code sent! Check your email.');
        } catch (error) {
            setError(error.message || 'Failed to resend code');
        } finally {
            setResendLoading(false);
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
                    background: 'linear-gradient(135deg, #22C55E 0%, #16A34A 100%)',
                    borderRadius: '1.5rem',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '2.5rem',
                    color: 'white',
                    margin: '0 auto 1.5rem'
                }
            }, '📧'),
            React.createElement('h1', { 
                key: 'title',
                style: {
                    fontSize: '2rem',
                    fontWeight: '800',
                    color: '#1E293B',
                    marginBottom: '0.5rem'
                }
            }, 'Verify Your Email'),
            React.createElement('p', { 
                key: 'subtitle',
                style: {
                    color: '#64748B',
                    fontSize: '1rem',
                    marginBottom: '1rem'
                }
            }, `We sent a verification code to your email.`),
            React.createElement('p', { 
                key: 'username',
                style: {
                    color: '#667eea',
                    fontSize: '0.875rem',
                    fontWeight: '600'
                }
            }, `Username: ${username}`)
        ]),
        React.createElement('form', { 
            key: 'form',
            onSubmit: handleSubmit 
        }, [
            React.createElement('div', { 
                key: 'code-group',
                style: { marginBottom: '2rem' }
            }, [
                React.createElement('label', { 
                    key: 'code-label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#374151',
                        marginBottom: '0.5rem'
                    }
                }, 'Verification Code'),
                React.createElement('input', {
                    key: 'code-input',
                    type: 'text',
                    value: verificationCode,
                    onChange: (e) => setVerificationCode(e.target.value),
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
                    required: true
                })
            ]),
            success && React.createElement('div', {
                key: 'success',
                style: {
                    background: '#F0FDF4',
                    color: '#16A34A',
                    padding: '1rem',
                    borderRadius: '1rem',
                    marginBottom: '1.5rem',
                    fontSize: '0.875rem',
                    border: '1px solid #BBF7D0'
                }
            }, success),
            error && React.createElement('div', {
                key: 'error',
                style: {
                    background: '#FEF2F2',
                    color: '#DC2626',
                    padding: '1rem',
                    borderRadius: '1rem',
                    marginBottom: '1.5rem',
                    fontSize: '0.875rem',
                    border: '1px solid #FCA5A5'
                }
            }, error),
            React.createElement('button', {
                key: 'submit',
                type: 'submit',
                disabled: formLoading || loading || verificationCode.length !== 6,
                style: {
                    width: '100%',
                    background: (formLoading || loading || verificationCode.length !== 6) ? '#9CA3AF' : 'linear-gradient(135deg, #22C55E 0%, #16A34A 100%)',
                    color: 'white',
                    border: 'none',
                    padding: '1rem',
                    borderRadius: '1rem',
                    fontSize: '1rem',
                    fontWeight: '600',
                    cursor: (formLoading || loading || verificationCode.length !== 6) ? 'not-allowed' : 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    marginBottom: '1rem'
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
                }, formLoading ? 'Verifying...' : 'Verify Email')
            ])
        ]),
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
                onClick: handleResend,
                disabled: resendLoading,
                style: {
                    background: 'none',
                    border: 'none',
                    color: '#667eea',
                    fontSize: '0.875rem',
                    fontWeight: '600',
                    cursor: resendLoading ? 'not-allowed' : 'pointer',
                    textDecoration: 'underline',
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '0.25rem'
                }
            }, [
                resendLoading && React.createElement('div', {
                    key: 'spinner',
                    style: {
                        width: '12px',
                        height: '12px',
                        border: '1px solid rgba(102, 126, 234, 0.3)',
                        borderTop: '1px solid #667eea',
                        borderRadius: '50%',
                        animation: 'spin 1s linear infinite'
                    }
                }),
                React.createElement('span', {
                    key: 'text'
                }, resendLoading ? 'Sending...' : 'Resend code')
            ])
        ]),
        React.createElement('div', {
            key: 'back-link',
            style: { 
                textAlign: 'center',
                paddingTop: '1.5rem',
                borderTop: '1px solid #E5E7EB'
            }
        }, React.createElement('button', {
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
        }, '← Back to Sign In'))
    ]));
};

// Forgot Password Form Component
const ForgotPasswordForm = ({ onForgotPassword, onSwitchToSignIn, loading }) => {
    const [email, setEmail] = useState('');
    const [formLoading, setFormLoading] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState('');

    const handleSubmit = async (e) => {
        e.preventDefault();
        setFormLoading(true);
        setError('');
        setSuccess('');
        
        try {
            await onForgotPassword(email);
            setSuccess('Password reset code sent to your email!');
        } catch (error) {
            setError(error.message || 'Failed to send reset code');
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
                    background: 'linear-gradient(135deg, #F59E0B 0%, #D97706 100%)',
                    borderRadius: '1.5rem',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '2.5rem',
                    color: 'white',
                    margin: '0 auto 1.5rem'
                }
            }, '🔑'),
            React.createElement('h1', { 
                key: 'title',
                style: {
                    fontSize: '2rem',
                    fontWeight: '800',
                    color: '#1E293B',
                    marginBottom: '0.5rem'
                }
            }, 'Reset Password'),
            React.createElement('p', { 
                key: 'subtitle',
                style: {
                    color: '#64748B',
                    fontSize: '1rem'
                }
            }, 'Enter your email to receive a reset code')
        ]),
        React.createElement('form', { 
            key: 'form',
            onSubmit: handleSubmit 
        }, [
            React.createElement('div', { 
                key: 'email-group',
                style: { marginBottom: '2rem' }
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
                }, 'Email Address'),
                React.createElement('input', {
                    key: 'email-input',
                    type: 'email',
                    value: email,
                    onChange: (e) => setEmail(e.target.value),
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
            success && React.createElement('div', {
                key: 'success',
                style: {
                    background: '#F0FDF4',
                    color: '#16A34A',
                    padding: '1rem',
                    borderRadius: '1rem',
                    marginBottom: '1.5rem',
                    fontSize: '0.875rem',
                    border: '1px solid #BBF7D0'
                }
            }, success),
            error && React.createElement('div', {
                key: 'error',
                style: {
                    background: '#FEF2F2',
                    color: '#DC2626',
                    padding: '1rem',
                    borderRadius: '1rem',
                    marginBottom: '1.5rem',
                    fontSize: '0.875rem',
                    border: '1px solid #FCA5A5'
                }
            }, error),
            React.createElement('button', {
                key: 'submit',
                type: 'submit',
                disabled: formLoading || loading,
                style: {
                    width: '100%',
                    background: formLoading || loading ? '#9CA3AF' : 'linear-gradient(135deg, #F59E0B 0%, #D97706 100%)',
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
                }, formLoading ? 'Sending...' : 'Send Reset Code')
            ])
        ]),
        React.createElement('div', {
            key: 'back-link',
            style: { 
                textAlign: 'center',
                paddingTop: '1.5rem',
                borderTop: '1px solid #E5E7EB'
            }
        }, React.createElement('button', {
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
        }, '← Back to Sign In'))
    ]));
};

// Reset Password Form Component
const ResetPasswordForm = ({ username, onResetPassword, onSwitchToSignIn, loading }) => {
    const [formData, setFormData] = useState({
        verificationCode: '',
        newPassword: '',
        confirmPassword: ''
    });
    const [formLoading, setFormLoading] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState('');

    const handleSubmit = async (e) => {
        e.preventDefault();
        setFormLoading(true);
        setError('');
        setSuccess('');

        if (formData.newPassword !== formData.confirmPassword) {
            setError('Passwords do not match');
            setFormLoading(false);
            return;
        }

        if (formData.newPassword.length < 8) {
            setError('Password must be at least 8 characters long');
            setFormLoading(false);
            return;
        }
        
        try {
            await onResetPassword(username, formData.verificationCode, formData.newPassword);
            setSuccess('Password reset successfully! You can now sign in.');
            setTimeout(() => {
                onSwitchToSignIn();
            }, 2000);
        } catch (error) {
            setError(error.message || 'Failed to reset password');
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
                    background: 'linear-gradient(135deg, #DC2626 0%, #B91C1C 100%)',
                    borderRadius: '1.5rem',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '2.5rem',
                    color: 'white',
                    margin: '0 auto 1.5rem'
                }
            }, '🔒'),
            React.createElement('h1', { 
                key: 'title',
                style: {
                    fontSize: '2rem',
                    fontWeight: '800',
                    color: '#1E293B',
                    marginBottom: '0.5rem'
                }
            }, 'Set New Password'),
            React.createElement('p', { 
                key: 'subtitle',
                style: {
                    color: '#64748B',
                    fontSize: '1rem'
                }
            }, 'Enter the code and your new password')
        ]),
        React.createElement('form', { 
            key: 'form',
            onSubmit: handleSubmit 
        }, [
            React.createElement('div', { 
                key: 'code-group',
                style: { marginBottom: '1.5rem' }
            }, [
                React.createElement('label', { 
                    key: 'code-label',
                    style: {
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#374151',
                        marginBottom: '0.5rem'
                    }
                }, 'Verification Code'),
                React.createElement('input', {
                    key: 'code-input',
                    type: 'text',
                    value: formData.verificationCode,
                    onChange: (e) => setFormData(prev => ({
                        ...prev,
                        verificationCode: e.target.value
                    })),
                    placeholder: 'Enter code from email',
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
                }, 'New Password'),
                React.createElement('input', {
                    key: 'password-input',
                    type: 'password',
                    value: formData.newPassword,
                    onChange: (e) => setFormData(prev => ({
                        ...prev,
                        newPassword: e.target.value
                    })),
                    placeholder: 'Enter new password',
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
                }, 'Confirm New Password'),
                React.createElement('input', {
                    key: 'confirm-password-input',
                    type: 'password',
                    value: formData.confirmPassword,
                    onChange: (e) => setFormData(prev => ({
                        ...prev,
                        confirmPassword: e.target.value
                    })),
                    placeholder: 'Confirm new password',
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
            success && React.createElement('div', {
                key: 'success',
                style: {
                    background: '#F0FDF4',
                    color: '#16A34A',
                    padding: '1rem',
                    borderRadius: '1rem',
                    marginBottom: '1.5rem',
                    fontSize: '0.875rem',
                    border: '1px solid #BBF7D0'
                }
            }, success),
            error && React.createElement('div', {
                key: 'error',
                style: {
                    background: '#FEF2F2',
                    color: '#DC2626',
                    padding: '1rem',
                    borderRadius: '1rem',
                    marginBottom: '1.5rem',
                    fontSize: '0.875rem',
                    border: '1px solid #FCA5A5'
                }
            }, error),
            React.createElement('button', {
                key: 'submit',
                type: 'submit',
                disabled: formLoading || loading,
                style: {
                    width: '100%',
                    background: formLoading || loading ? '#9CA3AF' : 'linear-gradient(135deg, #DC2626 0%, #B91C1C 100%)',
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
                }, formLoading ? 'Resetting...' : 'Reset Password')
            ])
        ]),
        React.createElement('div', {
            key: 'back-link',
            style: { 
                textAlign: 'center',
                paddingTop: '1.5rem',
                borderTop: '1px solid #E5E7EB'
            }
        }, React.createElement('button', {
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
        }, '← Back to Sign In'))
    ]));
};

// Export verification components
window.VerificationForm = VerificationForm;
window.ForgotPasswordForm = ForgotPasswordForm;
window.ResetPasswordForm = ResetPasswordForm;

console.log('✅ Verification and password reset forms loaded successfully');

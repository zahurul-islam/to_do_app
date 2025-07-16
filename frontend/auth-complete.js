// Enhanced Authentication Components with Signup and Verification
// Authentication Helper Functions for Cognito
const CognitoAuth = {
    async signUp(username, password, email) {
        if (!authInitialized || !aws_amplify?.Auth) {
            throw new Error('Authentication not initialized');
        }
        
        try {
            console.log('Attempting signup for:', username);
            const result = await aws_amplify.Auth.signUp({
                username: username,
                password: password,
                attributes: {
                    email: email
                }
            });
            
            console.log('Signup successful:', result);
            return result;
        } catch (error) {
            console.error('Signup error:', error);
            throw error;
        }
    },

    async confirmSignUp(username, confirmationCode) {
        if (!authInitialized || !aws_amplify?.Auth) {
            throw new Error('Authentication not initialized');
        }
        
        try {
            console.log('Confirming signup for:', username);
            const result = await aws_amplify.Auth.confirmSignUp(username, confirmationCode);
            console.log('Confirmation successful:', result);
            return result;
        } catch (error) {
            console.error('Confirmation error:', error);
            throw error;
        }
    },

    async resendConfirmationCode(username) {
        if (!authInitialized || !aws_amplify?.Auth) {
            throw new Error('Authentication not initialized');
        }
        
        try {
            console.log('Resending confirmation code for:', username);
            const result = await aws_amplify.Auth.resendConfirmationCode(username);
            console.log('Resend successful:', result);
            return result;
        } catch (error) {
            console.error('Resend error:', error);
            throw error;
        }
    },

    async forgotPassword(username) {
        if (!authInitialized || !aws_amplify?.Auth) {
            throw new Error('Authentication not initialized');
        }
        
        try {
            console.log('Initiating password reset for:', username);
            const result = await aws_amplify.Auth.forgotPassword(username);
            console.log('Password reset initiated:', result);
            return result;
        } catch (error) {
            console.error('Password reset error:', error);
            throw error;
        }
    },

    async confirmPassword(username, confirmationCode, newPassword) {
        if (!authInitialized || !aws_amplify?.Auth) {
            throw new Error('Authentication not initialized');
        }
        
        try {
            console.log('Confirming password reset for:', username);
            const result = await aws_amplify.Auth.forgotPasswordSubmit(
                username, 
                confirmationCode, 
                newPassword
            );
            console.log('Password reset confirmed:', result);
            return result;
        } catch (error) {
            console.error('Password reset confirmation error:', error);
            throw error;
        }
    }
};

// Enhanced Authentication Hook with Signup/Verification support
const useAuthComplete = () => {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);
    const [authStep, setAuthStep] = useState('signin'); // signin, signup, verify, forgot
    const [pendingUsername, setPendingUsername] = useState('');

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
            setAuthStep('signin');
            console.log('✅ Sign in successful');
            return user;
        } catch (error) {
            console.error('❌ Sign in error:', error);
            if (error.code === 'UserNotConfirmedException') {
                setPendingUsername(username);
                setAuthStep('verify');
                throw new Error('Please verify your email address first');
            }
            throw error;
        } finally {
            setLoading(false);
        }
    };

    const signUp = async (username, password, email) => {
        try {
            setLoading(true);
            const result = await CognitoAuth.signUp(username, password, email);
            setPendingUsername(username);
            setAuthStep('verify');
            console.log('✅ Sign up successful, verification needed');
            return result;
        } catch (error) {
            console.error('❌ Sign up error:', error);
            throw error;
        } finally {
            setLoading(false);
        }
    };

    const confirmSignUp = async (username, confirmationCode) => {
        try {
            setLoading(true);
            await CognitoAuth.confirmSignUp(username, confirmationCode);
            setAuthStep('signin');
            setPendingUsername('');
            console.log('✅ Email verified successfully');
            return true;
        } catch (error) {
            console.error('❌ Verification error:', error);
            throw error;
        } finally {
            setLoading(false);
        }
    };

    const resendConfirmationCode = async (username) => {
        try {
            setLoading(true);
            await CognitoAuth.resendConfirmationCode(username);
            console.log('✅ Confirmation code resent');
            return true;
        } catch (error) {
            console.error('❌ Resend error:', error);
            throw error;
        } finally {
            setLoading(false);
        }
    };

    const forgotPassword = async (username) => {
        try {
            setLoading(true);
            await CognitoAuth.forgotPassword(username);
            setPendingUsername(username);
            setAuthStep('reset');
            console.log('✅ Password reset initiated');
            return true;
        } catch (error) {
            console.error('❌ Password reset error:', error);
            throw error;
        } finally {
            setLoading(false);
        }
    };

    const confirmPassword = async (username, confirmationCode, newPassword) => {
        try {
            setLoading(true);
            await CognitoAuth.confirmPassword(username, confirmationCode, newPassword);
            setAuthStep('signin');
            setPendingUsername('');
            console.log('✅ Password reset completed');
            return true;
        } catch (error) {
            console.error('❌ Password reset confirmation error:', error);
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
            setAuthStep('signin');
            setPendingUsername('');
            console.log('✅ Sign out successful');
        } catch (error) {
            console.error('❌ Sign out error:', error);
        } finally {
            setLoading(false);
        }
    };

    const switchAuthStep = (step) => {
        setAuthStep(step);
    };

    return { 
        user, 
        loading, 
        authStep,
        pendingUsername,
        signIn, 
        signUp,
        confirmSignUp,
        resendConfirmationCode,
        forgotPassword,
        confirmPassword,
        signOut,
        switchAuthStep
    };
};

// Enhanced Authentication Container Component
const AuthContainer = () => {
    const { 
        user, 
        loading, 
        authStep,
        pendingUsername,
        signIn, 
        signUp,
        confirmSignUp,
        resendConfirmationCode,
        forgotPassword,
        confirmPassword,
        signOut,
        switchAuthStep
    } = useAuthComplete();

    if (loading) {
        return React.createElement(LoadingScreen, { message: 'Initializing authentication...' });
    }

    if (user) {
        return React.createElement(TodoApp, { user, onSignOut: signOut });
    }

    // Authentication forms based on current step
    const authForms = {
        signin: React.createElement(SignInForm, { 
            onSignIn: signIn,
            onSwitchToSignUp: () => switchAuthStep('signup'),
            onSwitchToForgot: () => switchAuthStep('forgot'),
            loading
        }),
        signup: React.createElement(SignUpForm, { 
            onSignUp: signUp,
            onSwitchToSignIn: () => switchAuthStep('signin'),
            loading
        }),
        verify: React.createElement(VerificationForm, { 
            username: pendingUsername,
            onConfirm: confirmSignUp,
            onResend: resendConfirmationCode,
            onSwitchToSignIn: () => switchAuthStep('signin'),
            loading
        }),
        forgot: React.createElement(ForgotPasswordForm, { 
            onForgotPassword: forgotPassword,
            onSwitchToSignIn: () => switchAuthStep('signin'),
            loading
        }),
        reset: React.createElement(ResetPasswordForm, { 
            username: pendingUsername,
            onResetPassword: confirmPassword,
            onSwitchToSignIn: () => switchAuthStep('signin'),
            loading
        })
    };

    return authForms[authStep] || authForms.signin;
};

// Export the enhanced auth container
window.AuthContainer = AuthContainer;

console.log('✅ Enhanced Authentication components loaded successfully');

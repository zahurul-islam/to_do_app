// Enhanced Modern Todo App with AI Integration - React 18 Compatible
// Enhanced Modern Todo App with AI Integration
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

// AI Integration with Gemini API
const GeminiAI = {
    apiKey: 'AIzaSyA7i9p0S8QPgcZLAwmRRtC89RPiiJuqWNI',
    endpoint: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
    
    async extractTasks(text) {
        try {
            const prompt = `
            Analyze the following text and extract actionable tasks. For each task found, return a JSON object with these fields:
            - title: A clear, concise task title (required)
            - category: Choose from 'work', 'personal', 'health', 'learning', 'shopping', 'other'
            - priority: Choose from 'low', 'medium', 'high'
            - description: Brief description if more context is available
            
            Text to analyze: "${text}"
            
            Return ONLY a JSON array of task objects. If no tasks are found, return an empty array [].
            Do not include any other text or explanation.
            `;
            
            const response = await fetch(`${this.endpoint}?key=${this.apiKey}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    contents: [{
                        parts: [{
                            text: prompt
                        }]
                    }]
                })
            });
            
            if (!response.ok) {
                throw new Error(`AI API error: ${response.status}`);
            }
            
            const data = await response.json();
            const aiResponse = data.candidates?.[0]?.content?.parts?.[0]?.text;
            
            if (!aiResponse) {
                throw new Error('No response from AI');
            }
            
            // Parse the JSON response
            const cleanedResponse = aiResponse.replace(/```json\n?|\n?```/g, '').trim();
            const tasks = JSON.parse(cleanedResponse);
            
            return Array.isArray(tasks) ? tasks : [];
        } catch (error) {
            console.error('❌ AI extraction error:', error);
            throw new Error('Failed to extract tasks using AI. Please try manually adding tasks.');
        }
    }
};

// Utility functions
const formatDate = (date) => {
    if (!date) return '';
    try {
        return new Date(date).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
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

// Enhanced categories and priorities with better styling
const CATEGORIES = [
    { id: 'work', name: 'Work', color: '#FF6B6B', icon: '💼', bgColor: '#FFF5F5' },
    { id: 'personal', name: 'Personal', color: '#4ECDC4', icon: '👤', bgColor: '#F0FDFA' },
    { id: 'health', name: 'Health', color: '#45B7D1', icon: '🏃', bgColor: '#F0F9FF' },
    { id: 'learning', name: 'Learning', color: '#96CEB4', icon: '📚', bgColor: '#F0FDF4' },
    { id: 'shopping', name: 'Shopping', color: '#FFEAA7', icon: '🛒', bgColor: '#FFFBF0' },
    { id: 'other', name: 'Other', color: '#DDA0DD', icon: '📝', bgColor: '#FAF5FF' }
];

const PRIORITIES = [
    { id: 'low', name: 'Low', color: '#22C55E', bgColor: '#F0FDF4' },
    { id: 'medium', name: 'Medium', color: '#F59E0B', bgColor: '#FFFBF0' },
    { id: 'high', name: 'High', color: '#EF4444', bgColor: '#FEF2F2' }
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

// Enhanced Authentication Hook
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

// Main Enhanced Todo App Component
const TodoApp = () => {
    const { user, loading: authLoading, signIn, signOut } = useAuth();
    const [todos, setTodos] = useState([]);
    const [loading, setLoading] = useState(false);
    const [filter, setFilter] = useState('all');
    const [notification, setNotification] = useState(null);
    
    // Load todos when user is authenticated
    useEffect(() => {
        if (user) {
            loadTodos();
        }
    }, [user]);

    const showNotification = (message, type = 'success') => {
        setNotification({ message, type });
        setTimeout(() => setNotification(null), 4000);
    };

    const loadTodos = async () => {
        try {
            setLoading(true);
            const response = await apiCall('/todos');
            setTodos(response.todos || []);
            console.log('✅ Todos loaded:', response.todos?.length || 0);
        } catch (error) {
            console.error('❌ Failed to load todos:', error);
            showNotification('Failed to load tasks. Please try again.', 'error');
        } finally {
            setLoading(false);
        }
    };

    const addTodo = async (todoData) => {
        try {
            setLoading(true);
            const response = await apiCall('/todos', 'POST', todoData);
            setTodos(prev => [...prev, response.todo]);
            showNotification('Task added successfully! 🎉');
            console.log('✅ Todo added');
        } catch (error) {
            console.error('❌ Failed to add todo:', error);
            showNotification('Failed to add task. Please try again.', 'error');
        } finally {
            setLoading(false);
        }
    };

    const addMultipleTodos = async (todosData) => {
        try {
            setLoading(true);
            const promises = todosData.map(todoData => apiCall('/todos', 'POST', {
                ...todoData,
                id: generateId(),
                completed: false,
                createdAt: new Date().toISOString()
            }));
            
            const responses = await Promise.all(promises);
            const newTodos = responses.map(response => response.todo);
            setTodos(prev => [...prev, ...newTodos]);
            showNotification(`🤖 AI extracted ${newTodos.length} task(s) successfully!`);
            console.log('✅ Multiple todos added via AI');
        } catch (error) {
            console.error('❌ Failed to add multiple todos:', error);
            showNotification('Failed to add AI-extracted tasks. Please try again.', 'error');
        } finally {
            setLoading(false);
        }
    };

    const updateTodo = async (id, updates) => {
        try {
            await apiCall(`/todos/${id}`, 'PUT', updates);
            setTodos(prev => prev.map(todo => 
                todo.id === id ? { ...todo, ...updates } : todo
            ));
            showNotification('Task updated successfully! ✅');
            console.log('✅ Todo updated');
        } catch (error) {
            console.error('❌ Failed to update todo:', error);
            showNotification('Failed to update task. Please try again.', 'error');
        }
    };

    const deleteTodo = async (id) => {
        try {
            await apiCall(`/todos/${id}`, 'DELETE');
            setTodos(prev => prev.filter(todo => todo.id !== id));
            showNotification('Task deleted successfully! 🗑️');
            console.log('✅ Todo deleted');
        } catch (error) {
            console.error('❌ Failed to delete todo:', error);
            showNotification('Failed to delete task. Please try again.', 'error');
        }
    };

    if (authLoading) {
        return React.createElement(LoadingScreen, { message: 'Checking authentication...' });
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
        notification && React.createElement(Notification, {
            key: 'notification',
            ...notification,
            onClose: () => setNotification(null)
        }),
        React.createElement('main', { 
            key: 'main',
            style: { 
                flex: 1,
                maxWidth: '1400px',
                margin: '0 auto',
                padding: '2rem',
                width: '100%'
            }
        }, [
            React.createElement(AITaskExtractor, { 
                key: 'ai-extractor',
                onTasksExtracted: addMultipleTodos,
                loading: loading
            }),
            React.createElement(QuickAddPanel, { 
                key: 'quick-add',
                onAddTodo: addTodo,
                loading: loading
            }),
            React.createElement(TodoDashboard, { 
                key: 'dashboard',
                todos: todos
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

// Enhanced Notification Component
const Notification = ({ message, type, onClose }) => {
    const bgColor = type === 'error' ? '#FEF2F2' : '#F0FDF4';
    const textColor = type === 'error' ? '#DC2626' : '#16A34A';
    const borderColor = type === 'error' ? '#FCA5A5' : '#BBF7D0';

    return React.createElement('div', {
        style: {
            position: 'fixed',
            top: '2rem',
            right: '2rem',
            zIndex: 9999,
            background: bgColor,
            color: textColor,
            border: `1px solid ${borderColor}`,
            padding: '1rem 1.5rem',
            borderRadius: '1rem',
            boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)',
            display: 'flex',
            alignItems: 'center',
            gap: '0.75rem',
            maxWidth: '400px',
            animation: 'slideInRight 0.3s ease-out'
        }
    }, [
        React.createElement('span', {
            key: 'icon',
            style: { fontSize: '1.25rem' }
        }, type === 'error' ? '❌' : '✅'),
        React.createElement('span', {
            key: 'message',
            style: { flex: 1, fontWeight: '500' }
        }, message),
        React.createElement('button', {
            key: 'close',
            onClick: onClose,
            style: {
                background: 'none',
                border: 'none',
                color: textColor,
                cursor: 'pointer',
                fontSize: '1.25rem',
                padding: '0.25rem'
            }
        }, '×')
    ]);
};

// AI Task Extractor Component
const AITaskExtractor = ({ onTasksExtracted, loading }) => {
    const [text, setText] = useState('');
    const [aiLoading, setAiLoading] = useState(false);
    const [extractedTasks, setExtractedTasks] = useState([]);
    const [showPreview, setShowPreview] = useState(false);

    const handleExtractTasks = async () => {
        if (!text.trim()) return;
        
        try {
            setAiLoading(true);
            const tasks = await GeminiAI.extractTasks(text);
            setExtractedTasks(tasks);
            setShowPreview(true);
        } catch (error) {
            console.error('❌ AI extraction failed:', error);
            // Create a simple fallback task
            const fallbackTask = {
                title: text.slice(0, 100),
                category: 'other',
                priority: 'medium',
                description: 'Manually added from text input'
            };
            setExtractedTasks([fallbackTask]);
            setShowPreview(true);
        } finally {
            setAiLoading(false);
        }
    };

    const handleConfirmTasks = () => {
        onTasksExtracted(extractedTasks);
        setText('');
        setExtractedTasks([]);
        setShowPreview(false);
    };

    const handleCancelTasks = () => {
        setExtractedTasks([]);
        setShowPreview(false);
    };

    return React.createElement('div', {
        style: {
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            borderRadius: '2rem',
            padding: '2.5rem',
            marginBottom: '2rem',
            color: 'white',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
            position: 'relative',
            overflow: 'hidden'
        }
    }, [
        React.createElement('div', {
            key: 'background-pattern',
            style: {
                position: 'absolute',
                top: '-50%',
                right: '-50%',
                width: '200%',
                height: '200%',
                background: 'radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 70%)',
                pointerEvents: 'none'
            }
        }),
        React.createElement('div', {
            key: 'content',
            style: { position: 'relative', zIndex: 1 }
        }, [
            React.createElement('div', {
                key: 'header',
                style: {
                    display: 'flex',
                    alignItems: 'center',
                    gap: '1rem',
                    marginBottom: '1.5rem'
                }
            }, [
                React.createElement('div', {
                    key: 'icon',
                    style: {
                        width: '48px',
                        height: '48px',
                        borderRadius: '1rem',
                        background: 'rgba(255, 255, 255, 0.2)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: '1.5rem'
                    }
                }, '🤖'),
                React.createElement('div', { key: 'text' }, [
                    React.createElement('h2', {
                        key: 'title',
                        style: {
                            fontSize: '1.5rem',
                            fontWeight: '700',
                            marginBottom: '0.25rem'
                        }
                    }, 'AI Task Extractor'),
                    React.createElement('p', {
                        key: 'subtitle',
                        style: {
                            fontSize: '1rem',
                            opacity: 0.9
                        }
                    }, 'Paste emails, notes, or any text to automatically extract tasks')
                ])
            ]),
            !showPreview && React.createElement('div', {
                key: 'input-section'
            }, [
                React.createElement('textarea', {
                    key: 'textarea',
                    value: text,
                    onChange: (e) => setText(e.target.value),
                    placeholder: 'Paste your email, meeting notes, or any text here...\n\nExample: "Don\'t forget to:\n- Schedule dentist appointment\n- Buy groceries for dinner party\n- Review quarterly reports by Friday"',
                    style: {
                        width: '100%',
                        minHeight: '120px',
                        padding: '1rem',
                        borderRadius: '1rem',
                        border: '2px solid rgba(255, 255, 255, 0.2)',
                        background: 'rgba(255, 255, 255, 0.1)',
                        color: 'white',
                        fontSize: '1rem',
                        fontFamily: 'inherit',
                        resize: 'vertical',
                        marginBottom: '1rem'
                    }
                }),
                React.createElement('div', {
                    key: 'actions',
                    style: {
                        display: 'flex',
                        gap: '1rem',
                        alignItems: 'center'
                    }
                }, [
                    React.createElement('button', {
                        key: 'extract-btn',
                        onClick: handleExtractTasks,
                        disabled: !text.trim() || aiLoading || loading,
                        style: {
                            background: 'rgba(255, 255, 255, 0.2)',
                            color: 'white',
                            border: '2px solid rgba(255, 255, 255, 0.3)',
                            padding: '0.75rem 1.5rem',
                            borderRadius: '1rem',
                            fontWeight: '600',
                            fontSize: '1rem',
                            cursor: text.trim() && !aiLoading && !loading ? 'pointer' : 'not-allowed',
                            transition: 'all 0.15s ease-out',
                            opacity: text.trim() && !aiLoading && !loading ? 1 : 0.6,
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.5rem'
                        }
                    }, [
                        aiLoading && React.createElement('div', {
                            key: 'spinner',
                            style: {
                                width: '16px',
                                height: '16px',
                                border: '2px solid rgba(255, 255, 255, 0.3)',
                                borderTop: '2px solid white',
                                borderRadius: '50%',
                                animation: 'spin 1s linear infinite'
                            }
                        }),
                        React.createElement('span', {
                            key: 'text'
                        }, aiLoading ? 'Extracting Tasks...' : '🚀 Extract Tasks with AI')
                    ])
                ])
            ]),
            showPreview && React.createElement(TaskPreview, {
                key: 'preview',
                tasks: extractedTasks,
                onConfirm: handleConfirmTasks,
                onCancel: handleCancelTasks,
                loading: loading
            })
        ])
    ]);
};

// Task Preview Component
const TaskPreview = ({ tasks, onConfirm, onCancel, loading }) => {
    return React.createElement('div', {
        style: {
            background: 'rgba(255, 255, 255, 0.1)',
            borderRadius: '1rem',
            padding: '1.5rem',
            border: '1px solid rgba(255, 255, 255, 0.2)'
        }
    }, [
        React.createElement('h3', {
            key: 'title',
            style: {
                fontSize: '1.25rem',
                fontWeight: '600',
                marginBottom: '1rem',
                color: 'white'
            }
        }, `🎯 Found ${tasks.length} task(s)`),
        React.createElement('div', {
            key: 'tasks',
            style: {
                display: 'flex',
                flexDirection: 'column',
                gap: '0.75rem',
                marginBottom: '1.5rem',
                maxHeight: '300px',
                overflowY: 'auto'
            }
        }, tasks.map((task, index) => {
            const category = CATEGORIES.find(c => c.id === task.category) || CATEGORIES[5];
            const priority = PRIORITIES.find(p => p.id === task.priority) || PRIORITIES[1];
            
            return React.createElement('div', {
                key: index,
                style: {
                    background: 'rgba(255, 255, 255, 0.1)',
                    padding: '1rem',
                    borderRadius: '0.75rem',
                    border: '1px solid rgba(255, 255, 255, 0.1)'
                }
            }, [
                React.createElement('div', {
                    key: 'title',
                    style: {
                        fontSize: '1rem',
                        fontWeight: '500',
                        marginBottom: '0.5rem',
                        color: 'white'
                    }
                }, task.title),
                React.createElement('div', {
                    key: 'meta',
                    style: {
                        display: 'flex',
                        gap: '0.5rem',
                        alignItems: 'center'
                    }
                }, [
                    React.createElement('span', {
                        key: 'category',
                        style: {
                            background: category.color,
                            color: 'white',
                            padding: '0.25rem 0.75rem',
                            borderRadius: '1rem',
                            fontSize: '0.75rem',
                            fontWeight: '500'
                        }
                    }, `${category.icon} ${category.name}`),
                    React.createElement('span', {
                        key: 'priority',
                        style: {
                            background: priority.color,
                            color: 'white',
                            padding: '0.25rem 0.75rem',
                            borderRadius: '1rem',
                            fontSize: '0.75rem',
                            fontWeight: '500'
                        }
                    }, priority.name)
                ])
            ]);
        })),
        React.createElement('div', {
            key: 'actions',
            style: {
                display: 'flex',
                gap: '1rem',
                justifyContent: 'flex-end'
            }
        }, [
            React.createElement('button', {
                key: 'cancel',
                onClick: onCancel,
                disabled: loading,
                style: {
                    background: 'rgba(255, 255, 255, 0.1)',
                    color: 'white',
                    border: '2px solid rgba(255, 255, 255, 0.2)',
                    padding: '0.75rem 1.5rem',
                    borderRadius: '0.75rem',
                    fontWeight: '500',
                    cursor: loading ? 'not-allowed' : 'pointer',
                    opacity: loading ? 0.6 : 1
                }
            }, 'Cancel'),
            React.createElement('button', {
                key: 'confirm',
                onClick: onConfirm,
                disabled: loading,
                style: {
                    background: 'rgba(255, 255, 255, 0.9)',
                    color: '#667eea',
                    border: 'none',
                    padding: '0.75rem 1.5rem',
                    borderRadius: '0.75rem',
                    fontWeight: '600',
                    cursor: loading ? 'not-allowed' : 'pointer',
                    opacity: loading ? 0.6 : 1,
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.5rem'
                }
            }, [
                loading && React.createElement('div', {
                    key: 'spinner',
                    style: {
                        width: '16px',
                        height: '16px',
                        border: '2px solid #ddd',
                        borderTop: '2px solid #667eea',
                        borderRadius: '50%',
                        animation: 'spin 1s linear infinite'
                    }
                }),
                React.createElement('span', {
                    key: 'text'
                }, loading ? 'Adding Tasks...' : `✅ Add ${tasks.length} Task(s)`)
            ])
        ])
    ]);
};

// Todo Dashboard Component
const TodoDashboard = ({ todos }) => {
    const stats = useMemo(() => {
        const total = todos.length;
        const completed = todos.filter(t => t.completed).length;
        const pending = total - completed;
        const completionRate = total > 0 ? Math.round((completed / total) * 100) : 0;
        
        const categoryStats = CATEGORIES.map(category => ({
            ...category,
            count: todos.filter(t => t.category === category.id).length
        })).filter(cat => cat.count > 0);

        return { total, completed, pending, completionRate, categoryStats };
    }, [todos]);

    return React.createElement('div', {
        style: {
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))',
            gap: '1.5rem',
            marginBottom: '2rem'
        }
    }, [
        React.createElement('div', {
            key: 'total',
            style: {
                background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                color: 'white',
                padding: '1.5rem',
                borderRadius: '1.5rem',
                textAlign: 'center',
                boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
            }
        }, [
            React.createElement('div', {
                key: 'number',
                style: { fontSize: '2.5rem', fontWeight: '700', marginBottom: '0.5rem' }
            }, stats.total),
            React.createElement('div', {
                key: 'label',
                style: { fontSize: '1rem', opacity: 0.9 }
            }, 'Total Tasks')
        ]),
        React.createElement('div', {
            key: 'completed',
            style: {
                background: 'linear-gradient(135deg, #22C55E 0%, #16A34A 100%)',
                color: 'white',
                padding: '1.5rem',
                borderRadius: '1.5rem',
                textAlign: 'center',
                boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
            }
        }, [
            React.createElement('div', {
                key: 'number',
                style: { fontSize: '2.5rem', fontWeight: '700', marginBottom: '0.5rem' }
            }, stats.completed),
            React.createElement('div', {
                key: 'label',
                style: { fontSize: '1rem', opacity: 0.9 }
            }, 'Completed')
        ]),
        React.createElement('div', {
            key: 'pending',
            style: {
                background: 'linear-gradient(135deg, #F59E0B 0%, #D97706 100%)',
                color: 'white',
                padding: '1.5rem',
                borderRadius: '1.5rem',
                textAlign: 'center',
                boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
            }
        }, [
            React.createElement('div', {
                key: 'number',
                style: { fontSize: '2.5rem', fontWeight: '700', marginBottom: '0.5rem' }
            }, stats.pending),
            React.createElement('div', {
                key: 'label',
                style: { fontSize: '1rem', opacity: 0.9 }
            }, 'Pending')
        ]),
        React.createElement('div', {
            key: 'completion',
            style: {
                background: 'linear-gradient(135deg, #3B82F6 0%, #1D4ED8 100%)',
                color: 'white',
                padding: '1.5rem',
                borderRadius: '1.5rem',
                textAlign: 'center',
                boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
            }
        }, [
            React.createElement('div', {
                key: 'number',
                style: { fontSize: '2.5rem', fontWeight: '700', marginBottom: '0.5rem' }
            }, `${stats.completionRate}%`),
            React.createElement('div', {
                key: 'label',
                style: { fontSize: '1rem', opacity: 0.9 }
            }, 'Complete')
        ])
    ]);
};

// Enhanced Login Form Component
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
            key: 'background',
            style: {
                position: 'absolute',
                top: '-50%',
                right: '-50%',
                width: '200%',
                height: '200%',
                background: 'radial-gradient(circle, rgba(102, 126, 234, 0.05) 0%, transparent 70%)',
                pointerEvents: 'none'
            }
        }),
        React.createElement('div', { 
            key: 'content',
            style: { position: 'relative', zIndex: 1 }
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
                }, 'TaskFlow'),
                React.createElement('p', { 
                    key: 'subtitle',
                    style: {
                        color: '#64748B',
                        fontSize: '1rem'
                    }
                }, 'Modern task management with AI')
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
                        value: credentials.username,
                        onChange: (e) => setCredentials(prev => ({
                            ...prev,
                            username: e.target.value
                        })),
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
                    style: { marginBottom: '2rem' }
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
                        transition: 'all 0.15s ease-out',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: '0.5rem'
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
                    React.createElement('span', {
                        key: 'text'
                    }, loading ? 'Signing in...' : 'Sign In')
                ])
            ])
        ])
    ]));
};

// Enhanced Header Component
const Header = ({ user, onSignOut }) => {
    return React.createElement('header', { 
        style: {
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            color: 'white',
            padding: '1.5rem 0',
            boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)',
            position: 'sticky',
            top: 0,
            zIndex: 1000
        }
    }, React.createElement('div', { 
        style: {
            maxWidth: '1400px',
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
                    width: '56px',
                    height: '56px',
                    background: 'rgba(255, 255, 255, 0.2)',
                    borderRadius: '1rem',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '1.75rem',
                    fontWeight: '700',
                    backdropFilter: 'blur(10px)'
                }
            }, '✓'),
            React.createElement('div', { key: 'brand-info' }, [
                React.createElement('h1', { 
                    key: 'title',
                    style: { 
                        fontSize: '2rem', 
                        fontWeight: '800', 
                        marginBottom: '0.25rem',
                        background: 'linear-gradient(135deg, #ffffff 0%, #f0f0f0 100%)',
                        WebkitBackgroundClip: 'text',
                        WebkitTextFillColor: 'transparent',
                        backgroundClip: 'text'
                    }
                }, 'TaskFlow'),
                React.createElement('p', { 
                    key: 'subtitle',
                    style: { 
                        fontSize: '0.875rem', 
                        opacity: 0.9, 
                        fontWeight: '500' 
                    }
                }, 'AI-Powered Task Management')
            ])
        ]),
        React.createElement('div', { 
            key: 'user-section',
            style: { display: 'flex', alignItems: 'center', gap: '1.5rem' }
        }, [
            React.createElement('div', {
                key: 'user-info',
                style: { textAlign: 'right' }
            }, [
                React.createElement('div', {
                    key: 'welcome',
                    style: { fontSize: '0.875rem', opacity: 0.9 }
                }, 'Welcome back'),
                React.createElement('div', {
                    key: 'username',
                    style: { fontSize: '1rem', fontWeight: '600' }
                }, user?.username || 'User')
            ]),
            React.createElement('div', { 
                key: 'avatar',
                style: {
                    width: '48px',
                    height: '48px',
                    borderRadius: '1rem',
                    background: 'rgba(255, 255, 255, 0.2)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '1.25rem',
                    fontWeight: '600',
                    backdropFilter: 'blur(10px)'
                }
            }, getInitials(user?.username || 'User')),
            React.createElement('button', {
                key: 'signout',
                onClick: onSignOut,
                style: {
                    background: 'rgba(255, 255, 255, 0.1)',
                    color: 'white',
                    border: '2px solid rgba(255, 255, 255, 0.2)',
                    padding: '0.75rem 1.5rem',
                    borderRadius: '1rem',
                    fontWeight: '600',
                    fontSize: '0.875rem',
                    cursor: 'pointer',
                    transition: 'all 0.15s ease-out',
                    backdropFilter: 'blur(10px)'
                },
                onMouseEnter: (e) => {
                    e.target.style.background = 'rgba(255, 255, 255, 0.2)';
                    e.target.style.transform = 'translateY(-2px)';
                },
                onMouseLeave: (e) => {
                    e.target.style.background = 'rgba(255, 255, 255, 0.1)';
                    e.target.style.transform = 'translateY(0)';
                }
            }, '👋 Sign Out')
        ])
    ]));
};

// Enhanced Quick Add Panel Component  
const QuickAddPanel = ({ onAddTodo, loading }) => {
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
            borderRadius: '2rem',
            padding: '2rem',
            boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)',
            border: '1px solid #E2E8F0',
            marginBottom: '2rem'
        }
    }, [
        React.createElement('h2', { 
            key: 'title',
            style: {
                fontSize: '1.5rem',
                fontWeight: '700',
                color: '#1E293B',
                marginBottom: '1.5rem',
                display: 'flex',
                alignItems: 'center',
                gap: '1rem'
            }
        }, [
            React.createElement('div', {
                key: 'icon',
                style: {
                    width: '40px',
                    height: '40px',
                    borderRadius: '1rem',
                    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                    color: 'white',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: '1.25rem'
                }
            }, '➕'),
            'Quick Add Task'
        ]),
        React.createElement('form', { 
            key: 'form',
            onSubmit: handleSubmit 
        }, [
            React.createElement('div', { 
                key: 'form-row',
                style: { 
                    display: 'grid',
                    gridTemplateColumns: '1fr auto auto auto',
                    gap: '1rem',
                    alignItems: 'end'
                }
            }, [
                React.createElement('div', {
                    key: 'title-group'
                }, [
                    React.createElement('label', {
                        key: 'title-label',
                        style: {
                            display: 'block',
                            fontSize: '0.875rem',
                            fontWeight: '600',
                            color: '#374151',
                            marginBottom: '0.5rem'
                        }
                    }, 'Task Title'),
                    React.createElement('input', {
                        key: 'title-input',
                        type: 'text',
                        placeholder: 'Enter your task...',
                        value: newTodo.title,
                        onChange: (e) => setNewTodo(prev => ({
                            ...prev,
                            title: e.target.value
                        })),
                        style: {
                            width: '100%',
                            padding: '1rem',
                            border: '2px solid #E5E7EB',
                            borderRadius: '1rem',
                            fontSize: '1rem',
                            transition: 'border-color 0.15s ease-out'
                        }
                    })
                ]),
                React.createElement('div', {
                    key: 'category-group'
                }, [
                    React.createElement('label', {
                        key: 'category-label',
                        style: {
                            display: 'block',
                            fontSize: '0.875rem',
                            fontWeight: '600',
                            color: '#374151',
                            marginBottom: '0.5rem'
                        }
                    }, 'Category'),
                    React.createElement('select', {
                        key: 'category-select',
                        value: newTodo.category,
                        onChange: (e) => setNewTodo(prev => ({
                            ...prev,
                            category: e.target.value
                        })),
                        style: {
                            padding: '1rem',
                            border: '2px solid #E5E7EB',
                            borderRadius: '1rem',
                            fontSize: '1rem',
                            minWidth: '140px',
                            background: 'white'
                        }
                    }, CATEGORIES.map(cat => 
                        React.createElement('option', {
                            key: cat.id,
                            value: cat.id
                        }, `${cat.icon} ${cat.name}`)
                    ))
                ]),
                React.createElement('div', {
                    key: 'priority-group'
                }, [
                    React.createElement('label', {
                        key: 'priority-label',
                        style: {
                            display: 'block',
                            fontSize: '0.875rem',
                            fontWeight: '600',
                            color: '#374151',
                            marginBottom: '0.5rem'
                        }
                    }, 'Priority'),
                    React.createElement('select', {
                        key: 'priority-select',
                        value: newTodo.priority,
                        onChange: (e) => setNewTodo(prev => ({
                            ...prev,
                            priority: e.target.value
                        })),
                        style: {
                            padding: '1rem',
                            border: '2px solid #E5E7EB',
                            borderRadius: '1rem',
                            fontSize: '1rem',
                            minWidth: '120px',
                            background: 'white'
                        }
                    }, PRIORITIES.map(pri => 
                        React.createElement('option', {
                            key: pri.id,
                            value: pri.id
                        }, pri.name)
                    ))
                ]),
                React.createElement('button', {
                    key: 'submit',
                    type: 'submit',
                    disabled: !newTodo.title.trim() || loading,
                    style: {
                        background: !newTodo.title.trim() || loading ? '#9CA3AF' : 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                        color: 'white',
                        border: 'none',
                        padding: '1rem 1.5rem',
                        borderRadius: '1rem',
                        fontWeight: '600',
                        fontSize: '1rem',
                        cursor: !newTodo.title.trim() || loading ? 'not-allowed' : 'pointer',
                        transition: 'all 0.15s ease-out',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.5rem',
                        whiteSpace: 'nowrap'
                    }
                }, [
                    loading && React.createElement('div', {
                        key: 'spinner',
                        style: {
                            width: '16px',
                            height: '16px',
                            border: '2px solid rgba(255, 255, 255, 0.3)',
                            borderTop: '2px solid white',
                            borderRadius: '50%',
                            animation: 'spin 1s linear infinite'
                        }
                    }),
                    React.createElement('span', {
                        key: 'text'
                    }, loading ? 'Adding...' : '🚀 Add Task')
                ])
            ])
        ])
    ]);
};

// Enhanced Todo Section Component
const TodoSection = ({ todos, loading, filter, onFilterChange, onUpdateTodo, onDeleteTodo }) => {
    const filteredTodos = todos.filter(todo => {
        if (filter === 'completed') return todo.completed;
        if (filter === 'pending') return !todo.completed;
        return true; // 'all'
    });

    const filters = [
        { id: 'all', name: 'All Tasks', icon: '📋', count: todos.length },
        { id: 'pending', name: 'Pending', icon: '⏳', count: todos.filter(t => !t.completed).length },
        { id: 'completed', name: 'Completed', icon: '✅', count: todos.filter(t => t.completed).length }
    ];

    if (loading) {
        return React.createElement('div', { 
            style: { 
                textAlign: 'center', 
                padding: '4rem',
                background: 'white',
                borderRadius: '2rem',
                boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)'
            }
        }, [
            React.createElement('div', { 
                key: 'spinner',
                style: {
                    width: '60px',
                    height: '60px',
                    border: '4px solid #E5E7EB',
                    borderTop: '4px solid #667eea',
                    borderRadius: '50%',
                    animation: 'spin 1s linear infinite',
                    margin: '0 auto 1.5rem'
                }
            }),
            React.createElement('p', { 
                key: 'text',
                style: { 
                    fontSize: '1.25rem',
                    color: '#64748B',
                    fontWeight: '500'
                }
            }, 'Loading your tasks...')
        ]);
    }

    return React.createElement('div', { 
        style: {
            background: 'white',
            borderRadius: '2rem',
            padding: '2rem',
            boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)',
            border: '1px solid #E2E8F0'
        }
    }, [
        React.createElement('div', {
            key: 'header',
            style: {
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                marginBottom: '2rem'
            }
        }, [
            React.createElement('h2', { 
                key: 'title',
                style: {
                    fontSize: '1.5rem',
                    fontWeight: '700',
                    color: '#1E293B',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '1rem'
                }
            }, [
                React.createElement('div', {
                    key: 'icon',
                    style: {
                        width: '40px',
                        height: '40px',
                        borderRadius: '1rem',
                        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                        color: 'white',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        fontSize: '1.25rem'
                    }
                }, '📝'),
                'Your Tasks'
            ])
        ]),
        React.createElement('div', { 
            key: 'filters',
            style: { 
                display: 'flex', 
                gap: '1rem', 
                marginBottom: '2rem',
                flexWrap: 'wrap'
            }
        }, filters.map(filterOption =>
            React.createElement('button', {
                key: filterOption.id,
                onClick: () => onFilterChange(filterOption.id),
                style: {
                    padding: '0.75rem 1.5rem',
                    border: `2px solid ${filter === filterOption.id ? '#667eea' : '#E2E8F0'}`,
                    borderRadius: '1rem',
                    background: filter === filterOption.id ? '#667eea' : 'white',
                    color: filter === filterOption.id ? 'white' : '#475569',
                    fontSize: '0.875rem',
                    fontWeight: '600',
                    cursor: 'pointer',
                    transition: 'all 0.15s ease-out',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.5rem'
                },
                onMouseEnter: (e) => {
                    if (filter !== filterOption.id) {
                        e.target.style.borderColor = '#667eea';
                        e.target.style.background = '#F8FAFC';
                    }
                },
                onMouseLeave: (e) => {
                    if (filter !== filterOption.id) {
                        e.target.style.borderColor = '#E2E8F0';
                        e.target.style.background = 'white';
                    }
                }
            }, [
                React.createElement('span', {
                    key: 'icon'
                }, filterOption.icon),
                React.createElement('span', {
                    key: 'name'
                }, filterOption.name),
                React.createElement('span', {
                    key: 'count',
                    style: {
                        background: filter === filterOption.id ? 'rgba(255, 255, 255, 0.2)' : '#E5E7EB',
                        color: filter === filterOption.id ? 'white' : '#6B7280',
                        padding: '0.25rem 0.5rem',
                        borderRadius: '0.5rem',
                        fontSize: '0.75rem',
                        fontWeight: '600',
                        minWidth: '1.5rem',
                        textAlign: 'center'
                    }
                }, filterOption.count)
            ])
        )),
        React.createElement('div', { 
            key: 'todo-list',
            style: { 
                display: 'flex', 
                flexDirection: 'column', 
                gap: '1rem'
            }
        }, filteredTodos.length === 0 ? [
            React.createElement('div', { 
                key: 'empty',
                style: { 
                    textAlign: 'center', 
                    padding: '4rem 2rem',
                    color: '#64748B'
                }
            }, [
                React.createElement('div', { 
                    key: 'icon',
                    style: { 
                        fontSize: '4rem', 
                        marginBottom: '1.5rem',
                        opacity: 0.5
                    }
                }, filter === 'completed' ? '🎉' : filter === 'pending' ? '⏳' : '📝'),
                React.createElement('h3', {
                    key: 'title',
                    style: {
                        fontSize: '1.5rem',
                        fontWeight: '600',
                        marginBottom: '0.5rem'
                    }
                }, filter === 'completed' ? 'No completed tasks yet' : filter === 'pending' ? 'No pending tasks' : 'No tasks yet'),
                React.createElement('p', { 
                    key: 'text',
                    style: { fontSize: '1rem' }
                }, filter === 'completed' ? 'Complete some tasks to see them here!' : filter === 'pending' ? 'All tasks are completed! 🎉' : 'Add your first task to get started!')
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

// Enhanced Todo Item Component
const TodoItem = ({ todo, onUpdate, onDelete }) => {
    const category = CATEGORIES.find(c => c.id === todo.category) || CATEGORIES[5];
    const priority = PRIORITIES.find(p => p.id === todo.priority) || PRIORITIES[1];

    const [isHovered, setIsHovered] = useState(false);

    return React.createElement('div', { 
        style: { 
            display: 'flex', 
            alignItems: 'flex-start', 
            padding: '1.5rem',
            background: todo.completed ? 
                'linear-gradient(135deg, #F0FDF4 0%, #DCFCE7 100%)' : 
                isHovered ? 'linear-gradient(135deg, #F8FAFC 0%, #F1F5F9 100%)' : '#FAFAFA',
            borderRadius: '1.5rem',
            border: `2px solid ${todo.completed ? '#BBF7D0' : isHovered ? '#667eea' : '#E2E8F0'}`,
            marginBottom: '1rem',
            transition: 'all 0.2s ease-out',
            transform: isHovered && !todo.completed ? 'translateY(-2px)' : 'translateY(0)',
            boxShadow: isHovered && !todo.completed ? '0 10px 15px -3px rgba(0, 0, 0, 0.1)' : 'none'
        },
        onMouseEnter: () => setIsHovered(true),
        onMouseLeave: () => setIsHovered(false)
    }, [
        React.createElement('div', {
            key: 'checkbox',
            onClick: () => onUpdate(todo.id, { completed: !todo.completed }),
            style: {
                width: '28px',
                height: '28px',
                borderRadius: '8px',
                border: `3px solid ${todo.completed ? '#22C55E' : '#CBD5E1'}`,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: 'pointer',
                backgroundColor: todo.completed ? '#22C55E' : 'white',
                color: 'white',
                marginRight: '1.5rem',
                marginTop: '0.25rem',
                transition: 'all 0.15s ease-out',
                fontSize: '1rem',
                fontWeight: '700'
            }
        }, todo.completed ? '✓' : ''),
        React.createElement('div', { 
            key: 'content',
            style: { flex: 1, minWidth: 0 }
        }, [
            React.createElement('div', { 
                key: 'title',
                style: { 
                    fontSize: '1.125rem', 
                    fontWeight: '600',
                    marginBottom: '0.75rem',
                    textDecoration: todo.completed ? 'line-through' : 'none',
                    color: todo.completed ? '#6B7280' : '#1E293B',
                    lineHeight: '1.4'
                }
            }, todo.title),
            React.createElement('div', { 
                key: 'meta',
                style: { 
                    display: 'flex', 
                    gap: '0.75rem', 
                    alignItems: 'center',
                    flexWrap: 'wrap'
                }
            }, [
                React.createElement('span', {
                    key: 'category',
                    style: {
                        backgroundColor: category.color,
                        color: 'white',
                        padding: '0.375rem 0.75rem',
                        borderRadius: '1rem',
                        fontSize: '0.75rem',
                        fontWeight: '600',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.25rem'
                    }
                }, `${category.icon} ${category.name}`),
                React.createElement('span', {
                    key: 'priority',
                    style: {
                        backgroundColor: priority.color,
                        color: 'white',
                        padding: '0.375rem 0.75rem',
                        borderRadius: '1rem',
                        fontSize: '0.75rem',
                        fontWeight: '600'
                    }
                }, priority.name),
                todo.createdAt && React.createElement('span', {
                    key: 'date',
                    style: {
                        color: '#6B7280',
                        fontSize: '0.75rem',
                        fontWeight: '500',
                        background: '#F3F4F6',
                        padding: '0.375rem 0.75rem',
                        borderRadius: '1rem'
                    }
                }, formatDate(todo.createdAt))
            ])
        ]),
        React.createElement('button', {
            key: 'delete',
            onClick: () => onDelete(todo.id),
            style: {
                backgroundColor: '#FEF2F2',
                color: '#DC2626',
                border: '2px solid #FCA5A5',
                borderRadius: '1rem',
                width: '40px',
                height: '40px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: 'pointer',
                transition: 'all 0.15s ease-out',
                fontSize: '1.25rem',
                marginLeft: '1rem',
                marginTop: '0.25rem'
            },
            onMouseEnter: (e) => {
                e.target.style.backgroundColor = '#DC2626';
                e.target.style.color = 'white';
                e.target.style.transform = 'scale(1.05)';
            },
            onMouseLeave: (e) => {
                e.target.style.backgroundColor = '#FEF2F2';
                e.target.style.color = '#DC2626';
                e.target.style.transform = 'scale(1)';
            }
        }, '🗑️')
    ]);
};

// Export the main app to global scope for mounting
window.TodoApp = TodoApp;

console.log('✅ Enhanced Modern TodoApp with AI integration loaded successfully');

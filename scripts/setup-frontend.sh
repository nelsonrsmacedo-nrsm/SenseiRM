#!/bin/bash
# scripts/setup-frontend.sh

set -e

echo "📁 Criando estrutura completa do frontend..."

FRONTEND_DIR="/opt/senseirm/frontend"
cd $FRONTEND_DIR

# Criar diretórios
mkdir -p public src/{components,contexts,services,pages/{Login,Dashboard,Clients,Campaigns,Tasks,System,User},utils} src/components/{Layout,UI}

# 1. Criar index.html
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
  <head>
    <meta charset="utf-8" />
    <link rel="icon" href="%PUBLIC_URL%/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#000000" />
    <meta name="description" content="SenseiRM - Sistema de Gestão de Relacionamento com Clientes" />
    <title>SenseiRM - CRM</title>
  </head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
  </body>
</html>
EOF

# 2. Criar index.js
cat > src/index.js << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

# 3. Criar index.css
cat > src/index.css << 'EOF'
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  background-color: #f8fafc;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}

:root {
  --primary-color: #3b82f6;
  --primary-dark: #1e40af;
  --secondary-color: #64748b;
  --success-color: #10b981;
  --warning-color: #f59e0b;
  --error-color: #ef4444;
  --background-color: #f8fafc;
  --surface-color: #ffffff;
  --text-primary: #1f2937;
  --text-secondary: #6b7280;
  --border-color: #e5e7eb;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

.btn {
  padding: 10px 20px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 500;
  transition: all 0.2s;
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.btn-primary {
  background-color: var(--primary-color);
  color: white;
}

.btn-primary:hover {
  background-color: var(--primary-dark);
}

.btn-secondary {
  background-color: var(--secondary-color);
  color: white;
}

.form-group {
  margin-bottom: 20px;
}

.form-label {
  display: block;
  margin-bottom: 6px;
  font-weight: 500;
  color: var(--text-primary);
}

.form-input {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid var(--border-color);
  border-radius: 6px;
  font-size: 14px;
  transition: border-color 0.2s;
}

.form-input:focus {
  outline: none;
  border-color: var(--primary-color);
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.card {
  background: var(--surface-color);
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  border: 1px solid var(--border-color);
  padding: 20px;
}
EOF

# 4. Criar App.js completo
cat > src/App.js << 'EOF'
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { SystemProvider } from './contexts/SystemContext';
import Layout from './components/Layout/Layout';
import Login from './pages/Login/Login';
import Dashboard from './pages/Dashboard/Dashboard';
import ClientManagement from './pages/Clients/ClientManagement';
import CampaignManagement from './pages/Campaigns/CampaignManagement';
import TaskManagement from './pages/Tasks/TaskManagement';
import SystemSettings from './pages/System/SystemSettings';
import UserProfile from './pages/User/UserProfile';
import LoadingSpinner from './components/UI/LoadingSpinner';
import './App.css';

// Componente para rotas protegidas
const ProtectedRoute = ({ children, requireAdmin = false }) => {
  const { user, loading } = useAuth();

  if (loading) {
    return <LoadingSpinner />;
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  if (requireAdmin && user.role !== 'admin') {
    return <Navigate to="/" replace />;
  }

  return children;
};

// Componente para rotas públicas
const PublicRoute = ({ children }) => {
  const { user, loading } = useAuth();

  if (loading) {
    return <LoadingSpinner />;
  }

  if (user) {
    return <Navigate to="/" replace />;
  }

  return children;
};

function App() {
  return (
    <SystemProvider>
      <AuthProvider>
        <Router>
          <div className="App">
            <Routes>
              {/* Rotas públicas */}
              <Route 
                path="/login" 
                element={
                  <PublicRoute>
                    <Login />
                  </PublicRoute>
                } 
              />

              {/* Rotas protegidas */}
              <Route 
                path="/" 
                element={
                  <ProtectedRoute>
                    <Layout>
                      <Dashboard />
                    </Layout>
                  </ProtectedRoute>
                } 
              />

              <Route 
                path="/clients" 
                element={
                  <ProtectedRoute>
                    <Layout>
                      <ClientManagement />
                    </Layout>
                  </ProtectedRoute>
                } 
              />

              <Route 
                path="/campaigns" 
                element={
                  <ProtectedRoute>
                    <Layout>
                      <CampaignManagement />
                    </Layout>
                  </ProtectedRoute>
                } 
              />

              <Route 
                path="/tasks" 
                element={
                  <ProtectedRoute>
                    <Layout>
                      <TaskManagement />
                    </Layout>
                  </ProtectedRoute>
                } 
              />

              <Route 
                path="/profile" 
                element={
                  <ProtectedRoute>
                    <Layout>
                      <UserProfile />
                    </Layout>
                  </ProtectedRoute>
                } 
              />

              <Route 
                path="/settings" 
                element={
                  <ProtectedRoute requireAdmin>
                    <Layout>
                      <SystemSettings />
                    </Layout>
                  </ProtectedRoute>
                } 
              />

              {/* Rota 404 */}
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </div>
        </Router>
      </AuthProvider>
    </SystemProvider>
  );
}

export default App;
EOF

# 5. Criar App.css
cat > src/App.css << 'EOF'
.App {
  min-height: 100vh;
  background-color: var(--background-color);
}

.loading-container {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  flex-direction: column;
  gap: 15px;
}

.spinner {
  border: 4px solid #f3f3f3;
  border-top: 4px solid var(--primary-color);
  border-radius: 50%;
  width: 50px;
  height: 50px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.main-layout {
  display: flex;
  min-height: 100vh;
}

.sidebar {
  width: 250px;
  background: var(--surface-color);
  border-right: 1px solid var(--border-color);
  position: fixed;
  height: 100vh;
  overflow-y: auto;
}

.main-content {
  flex: 1;
  margin-left: 250px;
  padding: 20px;
  background: var(--background-color);
  min-height: 100vh;
}

.header {
  background: var(--surface-color);
  border-bottom: 1px solid var(--border-color);
  padding: 15px 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.stat-card {
  background: var(--surface-color);
  padding: 20px;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.stat-value {
  font-size: 24px;
  font-weight: bold;
  color: var(--primary-color);
  margin: 10px 0;
}

.stat-label {
  color: var(--text-secondary);
  font-size: 14px;
}

.alert {
  padding: 12px 15px;
  border-radius: 6px;
  margin-bottom: 20px;
}

.alert-error {
  background-color: #fef2f2;
  border: 1px solid #fecaca;
  color: #dc2626;
}

.alert-success {
  background-color: #f0fdf4;
  border: 1px solid #bbf7d0;
  color: #16a34a;
}

@media (max-width: 768px) {
  .sidebar {
    width: 100%;
    height: auto;
    position: relative;
  }
  
  .main-content {
    margin-left: 0;
  }
  
  .stats-grid {
    grid-template-columns: 1fr;
  }
}
EOF

# 6. Criar AuthContext
cat > src/contexts/AuthContext.js << 'EOF'
import React, { createContext, useState, useContext, useEffect } from 'react';
import { authService } from '../services/api';

const AuthContext = createContext();

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth deve ser usado dentro de AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    checkAuth();
  }, []);

  const checkAuth = async () => {
    try {
      const token = localStorage.getItem('senseirm_token');
      if (token) {
        const response = await authService.verifyToken();
        setUser(response.data.user);
      }
    } catch (error) {
      localStorage.removeItem('senseirm_token');
      console.error('Erro na verificação de autenticação:', error);
    } finally {
      setLoading(false);
    }
  };

  const login = async (email, password) => {
    try {
      setError(null);
      const response = await authService.login(email, password);
      const { user, token } = response.data;

      localStorage.setItem('senseirm_token', token);
      setUser(user);

      return { success: true };
    } catch (error) {
      const message = error.response?.data?.error || 'Erro ao fazer login';
      setError(message);
      return { success: false, error: message };
    }
  };

  const logout = () => {
    localStorage.removeItem('senseirm_token');
    setUser(null);
    setError(null);
  };

  const value = {
    user,
    loading,
    error,
    login,
    logout,
    setError
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};
EOF

# 7. Criar SystemContext
cat > src/contexts/SystemContext.js << 'EOF'
import React, { createContext, useState, useContext, useEffect } from 'react';

const SystemContext = createContext();

export const useSystem = () => {
  const context = useContext(SystemContext);
  if (!context) {
    throw new Error('useSystem deve ser usado dentro de SystemProvider');
  }
  return context;
};

export const SystemProvider = ({ children }) => {
  const [settings, setSettings] = useState({
    companyLogo: '',
    companySlogan: 'Sistema de Gestão de Relacionamento com Clientes',
    primaryColor: '#3b82f6',
    secondaryColor: '#1e40af',
    developerLogo: '',
    developerWebsite: '',
    developerEmail: '',
    developerPhone: '',
    licenseType: 'Enterprise'
  });
  const [loading, setLoading] = useState(false);

  const value = {
    settings,
    loading,
    updateSettings: async () => ({ success: true }),
    reloadSettings: () => {}
  };

  return (
    <SystemContext.Provider value={value}>
      {children}
    </SystemContext.Provider>
  );
};
EOF

# 8. Criar services/api.js
cat > src/services/api.js << 'EOF'
import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
});

api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('senseirm_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401 || error.response?.status === 403) {
      localStorage.removeItem('senseirm_token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export const authService = {
  login: (email, password) => api.post('/auth/login', { email, password }),
  verifyToken: () => api.get('/auth/verify'),
  changePassword: (currentPassword, newPassword) => 
    api.post('/auth/change-password', { currentPassword, newPassword }),
  logout: () => api.post('/auth/logout'),
};

export const userService = {
  getUsers: (params) => api.get('/users', { params }),
  getUserProfile: () => api.get('/users/profile'),
  updateProfile: (profileData) => api.put('/users/profile', profileData),
};

export const clientService = {
  getClients: (params) => api.get('/clients', { params }),
  createClient: (clientData) => api.post('/clients', clientData),
  updateClient: (id, clientData) => api.put(`/clients/${id}`, clientData),
  deleteClient: (id) => api.delete(`/clients/${id}`),
};

export const systemService = {
  getSettings: () => api.get('/system/settings'),
};

export default api;
EOF

# 9. Criar LoadingSpinner
cat > src/components/UI/LoadingSpinner.js << 'EOF'
import React from 'react';

const LoadingSpinner = ({ size = 'medium', text = 'Carregando...' }) => {
  const spinnerSize = {
    small: '20px',
    medium: '40px',
    large: '60px'
  };

  return (
    <div className="loading-container">
      <div 
        className="spinner" 
        style={{ 
          width: spinnerSize[size], 
          height: spinnerSize[size] 
        }}
      ></div>
      {text && <div className="loading-text">{text}</div>}
    </div>
  );
};

export default LoadingSpinner;
EOF

# 10. Criar Layout
cat > src/components/Layout/Layout.js << 'EOF'
import React from 'react';
import { useAuth } from '../../contexts/AuthContext';

const Layout = ({ children }) => {
  const { user, logout } = useAuth();

  return (
    <div className="main-layout">
      <aside className="sidebar">
        <div style={{ padding: '20px', borderBottom: '1px solid var(--border-color)' }}>
          <h2 style={{ color: 'var(--primary-color)', margin: 0 }}>SenseiRM</h2>
          <p style={{ color: 'var(--text-secondary)', fontSize: '12px', margin: '5px 0 0 0' }}>
            Sistema CRM
          </p>
        </div>
        <nav style={{ padding: '10px 0' }}>
          <a href="/" style={{ display: 'block', padding: '10px 20px', color: 'var(--text-primary)', textDecoration: 'none' }}>
            📊 Dashboard
          </a>
          <a href="/clients" style={{ display: 'block', padding: '10px 20px', color: 'var(--text-primary)', textDecoration: 'none' }}>
            👥 Clientes
          </a>
          <a href="/campaigns" style={{ display: 'block', padding: '10px 20px', color: 'var(--text-primary)', textDecoration: 'none' }}>
            📧 Campanhas
          </a>
          <a href="/tasks" style={{ display: 'block', padding: '10px 20px', color: 'var(--text-primary)', textDecoration: 'none' }}>
            ✅ Tarefas
          </a>
          <a href="/profile" style={{ display: 'block', padding: '10px 20px', color: 'var(--text-primary)', textDecoration: 'none' }}>
            👤 Perfil
          </a>
          {user?.role === 'admin' && (
            <a href="/settings" style={{ display: 'block', padding: '10px 20px', color: 'var(--text-primary)', textDecoration: 'none' }}>
              ⚙️ Configurações
            </a>
          )}
        </nav>
      </aside>
      
      <main className="main-content">
        <header className="header">
          <div>
            <h1 style={{ margin: 0, fontSize: '18px' }}>SenseiRM</h1>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '15px' }}>
            <span>Olá, {user?.name}</span>
            <button onClick={logout} className="btn btn-secondary" style={{ padding: '5px 10px', fontSize: '12px' }}>
              Sair
            </button>
          </div>
        </header>
        <div style={{ padding: '20px 0' }}>
          {children}
        </div>
      </main>
    </div>
  );
};

export default Layout;
EOF

# 11. Criar páginas básicas

# Login
cat > src/pages/Login/Login.js << 'EOF'
import React, { useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { useSystem } from '../../contexts/SystemContext';

const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  
  const { login, error, setError } = useAuth();
  const { settings } = useSystem();

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!email || !password) {
      setError('Email e senha são obrigatórios');
      return;
    }

    setIsLoading(true);
    const result = await login(email, password);
    setIsLoading(false);
  };

  return (
    <div style={{ 
      minHeight: '100vh', 
      display: 'flex', 
      alignItems: 'center', 
      justifyContent: 'center',
      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      padding: '20px'
    }}>
      <div style={{
        background: 'white',
        padding: '40px',
        borderRadius: '12px',
        boxShadow: '0 20px 40px rgba(0, 0, 0, 0.1)',
        width: '100%',
        maxWidth: '400px'
      }}>
        <div style={{ textAlign: 'center', marginBottom: '30px' }}>
          <h1 style={{ color: '#1f2937', fontSize: '28px', fontWeight: '700', margin: '0 0 8px 0' }}>
            SenseiRM
          </h1>
          <p style={{ color: '#6b7280', fontSize: '14px', margin: 0 }}>
            {settings.companySlogan}
          </p>
        </div>

        <form onSubmit={handleSubmit} style={{ marginBottom: '30px' }}>
          {error && (
            <div style={{
              backgroundColor: '#fef2f2',
              border: '1px solid #fecaca',
              color: '#dc2626',
              padding: '12px',
              borderRadius: '8px',
              marginBottom: '20px',
              fontSize: '14px'
            }}>
              {error}
            </div>
          )}

          <div style={{ marginBottom: '20px' }}>
            <label style={{ display: 'block', marginBottom: '6px', color: '#374151', fontWeight: '500', fontSize: '14px' }}>
              Email
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              style={{
                width: '100%',
                padding: '12px 16px',
                border: '1px solid #d1d5db',
                borderRadius: '8px',
                fontSize: '14px',
                boxSizing: 'border-box'
              }}
              placeholder="seu@email.com"
              disabled={isLoading}
              required
            />
          </div>

          <div style={{ marginBottom: '20px' }}>
            <label style={{ display: 'block', marginBottom: '6px', color: '#374151', fontWeight: '500', fontSize: '14px' }}>
              Senha
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              style={{
                width: '100%',
                padding: '12px 16px',
                border: '1px solid #d1d5db',
                borderRadius: '8px',
                fontSize: '14px',
                boxSizing: 'border-box'
              }}
              placeholder="Sua senha"
              disabled={isLoading}
              required
            />
          </div>

          <button 
            type="submit" 
            style={{
              width: '100%',
              backgroundColor: '#3b82f6',
              color: 'white',
              border: 'none',
              padding: '12px 20px',
              borderRadius: '8px',
              fontSize: '16px',
              fontWeight: '600',
              cursor: 'pointer'
            }}
            disabled={isLoading}
          >
            {isLoading ? 'Entrando...' : 'Entrar'}
          </button>
        </form>

        <div style={{ borderTop: '1px solid #e5e7eb', paddingTop: '20px', textAlign: 'center', fontSize: '12px', color: '#6b7280' }}>
          <p>SenseiRM &copy; 2024</p>
          <p>Credenciais de teste: admin@senseirm.com / admin123</p>
        </div>
      </div>
    </div>
  );
};

export default Login;
EOF

# Dashboard
cat > src/pages/Dashboard/Dashboard.js << 'EOF'
import React from 'react';

const Dashboard = () => {
  return (
    <div>
      <h1>Dashboard</h1>
      <p>Bem-vindo ao SenseiRM - Sistema de Gestão de Relacionamento com Clientes</p>
      
      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-label">Total de Clientes</div>
          <div className="stat-value">0</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">Campanhas Ativas</div>
          <div className="stat-value">0</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">Tarefas Pendentes</div>
          <div className="stat-value">0</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">Usuários Online</div>
          <div className="stat-value">1</div>
        </div>
      </div>

      <div className="card">
        <h2>Atividade Recente</h2>
        <p>Sistema inicializado com sucesso.</p>
      </div>
    </div>
  );
};

export default Dashboard;
EOF

# Páginas básicas para outras rotas
for page in Clients Campaigns Tasks System User; do
  cat > src/pages/${page}/${page}Management.js << EOF
import React from 'react';

const ${page}Management = () => {
  return (
    <div>
      <h1>Gestão de ${page}</h1>
      <div className="card">
        <p>Módulo em desenvolvimento.</p>
      </div>
    </div>
  );
};

export default ${page}Management;
EOF
done

echo "✅ Estrutura do frontend criada com sucesso!"
echo "📦 Instalando dependências..."
npm install

echo "🏗️ Executando build..."
npm run build

echo "🎉 Frontend configurado com sucesso!"
EOF

## 2. Executar o script de setup do frontend

```bash
# Torne o script executável e execute
chmod +x /opt/senseirm/scripts/setup-frontend.sh
/opt/senseirm/scripts/setup-frontend.sh
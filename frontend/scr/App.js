// frontend/src/App.js
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from 'react-query';
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

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

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
    <QueryClientProvider client={queryClient}>
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
    </QueryClientProvider>
  );
}

export default App;
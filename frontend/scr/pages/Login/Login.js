// frontend/src/pages/Login/Login.js
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { useSystem } from '../../contexts/SystemContext';
import './Login.css';

const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  
  const { login, error, setError } = useAuth();
  const { settings } = useSystem();
  const navigate = useNavigate();

  useEffect(() => {
    setError(null);
  }, [setError]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!email || !password) {
      setError('Email e senha são obrigatórios');
      return;
    }

    setIsLoading(true);
    const result = await login(email, password);
    setIsLoading(false);

    if (result.success) {
      navigate('/');
    }
  };

  return (
    <div className="login-container">
      <div className="login-card">
        {/* Logo e Slogan do Sistema */}
        <div className="login-header">
          {settings.companyLogo && (
            <img 
              src={settings.companyLogo} 
              alt="Logo" 
              className="login-logo"
            />
          )}
          <h1 className="login-title">SenseiRM</h1>
          {settings.companySlogan && (
            <p className="login-slogan">{settings.companySlogan}</p>
          )}
        </div>

        {/* Formulário de Login */}
        <form onSubmit={handleSubmit} className="login-form">
          {error && (
            <div className="error-message">
              {error}
            </div>
          )}

          <div className="form-group">
            <label htmlFor="email" className="form-label">
              Email
            </label>
            <input
              type="email"
              id="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="form-input"
              placeholder="seu@email.com"
              disabled={isLoading}
              required
            />
          </div>

          <div className="form-group">
            <label htmlFor="password" className="form-label">
              Senha
            </label>
            <input
              type="password"
              id="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="form-input"
              placeholder="Sua senha"
              disabled={isLoading}
              required
            />
          </div>

          <button 
            type="submit" 
            className="login-button"
            disabled={isLoading}
          >
            {isLoading ? 'Entrando...' : 'Entrar'}
          </button>
        </form>

        {/* Informações do Desenvolvedor */}
        <div className="developer-info">
          {settings.developerLogo && (
            <img 
              src={settings.developerLogo} 
              alt="Developer" 
              className="developer-logo"
            />
          )}
          <div className="developer-details">
            {settings.developerWebsite && (
              <a 
                href={settings.developerWebsite} 
                target="_blank" 
                rel="noopener noreferrer"
                className="developer-link"
              >
                {settings.developerWebsite}
              </a>
            )}
            {settings.developerEmail && (
              <div className="developer-contact">
                {settings.developerEmail}
              </div>
            )}
            {settings.developerPhone && (
              <div className="developer-contact">
                {settings.developerPhone}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Login;
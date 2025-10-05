#!/bin/bash
# scripts/create-frontend-structure.sh

set -e

echo "📁 Criando estrutura do frontend..."

FRONTEND_DIR="/opt/senseirm/frontend"

cd $FRONTEND_DIR

# Criar diretórios
mkdir -p public src/{components,contexts,services,pages/{Login,Dashboard,Clients,Campaigns,Tasks,System,User}} src/components/{Layout,UI}

# Criar arquivos básicos
echo "📄 Criando index.html..."
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
    <style>
        .loading-container {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            font-family: Arial, sans-serif;
        }
        .loading-spinner {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #3498db;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 2s linear infinite;
            margin-right: 15px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <noscript>Você precisa habilitar JavaScript para executar este app.</noscript>
    <div id="root">
        <div class="loading-container">
            <div class="loading-spinner"></div>
            <div>Carregando SenseiRM...</div>
        </div>
    </div>
</body>
</html>
EOF

echo "📄 Criando index.js..."
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

echo "📄 Criando index.css..."
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
  background-color: #f5f5f5;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}
EOF

echo "📄 Criando App.js básico..."
cat > src/App.js << 'EOF'
import React from 'react';
import './App.css';

function App() {
  return (
    <div className="App">
      <header style={{ padding: '20px', background: '#3b82f6', color: 'white' }}>
        <h1>SenseiRM - Sistema CRM</h1>
        <p>Instalação em andamento...</p>
      </header>
      <main style={{ padding: '20px' }}>
        <p>Frontend está sendo configurado. Execute o build novamente.</p>
      </main>
    </div>
  );
}

export default App;
EOF

echo "📄 Criando App.css básico..."
cat > src/App.css << 'EOF'
.App {
  text-align: center;
}

.App-header {
  background-color: #282c34;
  padding: 20px;
  color: white;
}

.App-main {
  padding: 20px;
}
EOF

echo "✅ Estrutura do frontend criada com sucesso!"
echo "📋 Agora execute: cd /opt/senseirm/frontend && npm run build"
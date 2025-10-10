#!/bin/bash
# scripts/deploy-senseirm.sh

set -e

echo "🚀 Iniciando deploy do SenseiRM..."

# Configurações
APP_DIR="/opt/senseirm"
BACKEND_DIR="$APP_DIR/backend"
FRONTEND_DIR="$APP_DIR/frontend"
DATABASE_DIR="$APP_DIR/database"
DB_NAME="senseirm"
DB_USER="senseirm_user"
DB_PASS="SenseiRM@123!"

# Criar diretórios necessários
echo "📁 Criando diretórios..."
mkdir -p $APP_DIR/uploads
mkdir -p $APP_DIR/logs
mkdir -p $DATABASE_DIR

# Configurar backend
echo "🔧 Configurando backend..."
cd $BACKEND_DIR

# Verificar se package.json existe, se não, criar um básico
if [ ! -f "package.json" ]; then
    echo "📦 Criando package.json básico..."
    cat > package.json << 'EOF'
{
  "name": "senseirm-backend",
  "version": "1.0.0",
  "description": "Backend do Sistema SenseiRM",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "express-rate-limit": "^6.8.1",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.1",
    "mysql2": "^3.6.0",
    "sequelize": "^6.32.1",
    "nodemailer": "^6.9.4",
    "dotenv": "^16.3.1",
    "multer": "^1.4.5",
    "winston": "^3.10.0"
  }
}
EOF
fi

# Criar arquivo .env
echo "⚙️ Criando arquivo .env..."
cat > .env << EOF
NODE_ENV=production
PORT=5000
DB_HOST=localhost
DB_PORT=3306
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASS=$DB_PASS
JWT_SECRET=$(openssl rand -base64 64)
JWT_EXPIRES_IN=24h

# Configurações de Email
SMTP_HOST=localhost
SMTP_PORT=587
SMTP_USER=
SMTP_PASS=
SMTP_FROM=SenseiRM <noreply@senseirm.com>

# Upload
UPLOAD_DIR=$APP_DIR/uploads
MAX_FILE_SIZE=10485760

# Log
LOG_LEVEL=info
EOF

# Instalar dependências do backend
echo "📦 Instalando dependências do backend..."
npm install --production

# Verificar se as dependências críticas foram instaladas
echo "🔍 Verificando dependências..."
if ! npm list sequelize mysql2 express; then
    echo "⚠️ Reinstalando dependências críticas..."
    npm install sequelize mysql2 express cors helmet bcryptjs jsonwebtoken --save
fi

# Configurar frontend
echo "🎨 Configurando frontend..."
cd $FRONTEND_DIR

# Verificar se package.json do frontend existe
if [ ! -f "package.json" ]; then
    echo "📦 Criando package.json do frontend..."
    cat > package.json << 'EOF'
{
  "name": "senseirm-frontend",
  "version": "1.0.0",
  "description": "Frontend do Sistema SenseiRM",
  "main": "index.js",
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-scripts": "5.0.1",
    "react-router-dom": "^6.15.0",
    "axios": "^1.5.0"
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  }
}
EOF
fi

# Criar arquivo .env do frontend
cat > .env << EOF
REACT_APP_API_URL=http://localhost:5000/api
REACT_APP_VERSION=1.0.0
GENERATE_SOURCEMAP=false
EOF

# Instalar dependências e build do frontend
echo "📦 Instalando dependências do frontend..."
npm install --production

echo "🏗️ Criando build de produção do frontend..."
npm run build

# Configurar Nginx
echo "🌐 Configurando Nginx..."
sudo tee /etc/nginx/conf.d/senseirm.conf > /dev/null << EOF
server {
    listen 80;
    server_name _;
    
    # Frontend
    location / {
        root $FRONTEND_DIR/build;
        index index.html index.htm;
        try_files \$uri \$uri/ /index.html;
        
        # Cache estático
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API Backend
    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Uploads
    location /uploads {
        alias $APP_DIR/uploads;
        expires 6M;
        add_header Cache-Control "public";
    }
}
EOF

# Testar configuração do Nginx
echo "🧪 Testando configuração do Nginx..."
sudo nginx -t

# Recarregar Nginx
echo "🔄 Recarregando Nginx..."
sudo systemctl reload nginx

# **CRIAR ARQUIVOS DE MIGRAÇÃO DO BANCO**
echo "🗃️ Criando arquivos de migração do banco..."

# Criar migrate.js
cat > $DATABASE_DIR/migrate.js << 'EOF'
console.log('🔧 Iniciando migrações do banco...');

// Carregar variáveis de ambiente
require('dotenv').config({ path: '../backend/.env' });

const path = require('path');

// Configurar Sequelize manualmente
const { Sequelize, DataTypes } = require('sequelize');

// Configuração do banco
const sequelize = new Sequelize(
  process.env.DB_NAME || 'senseirm',
  process.env.DB_USER || 'senseirm_user',
  process.env.DB_PASS || 'SenseiRM@123!',
  {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    dialect: 'mysql',
    logging: (msg) => console.log(msg),
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  }
);

// Definir modelos básicos
const User = sequelize.define('User', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  name: { type: DataTypes.STRING, allowNull: false },
  email: { type: DataTypes.STRING, unique: true, allowNull: false },
  password: { type: DataTypes.STRING, allowNull: false },
  role: { type: DataTypes.ENUM('admin', 'user'), defaultValue: 'user' },
  isActive: { type: DataTypes.BOOLEAN, defaultValue: true },
  lastLogin: { type: DataTypes.DATE }
}, { tableName: 'users' });

const Client = sequelize.define('Client', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  name: { type: DataTypes.STRING, allowNull: false },
  email: { type: DataTypes.STRING },
  phone: { type: DataTypes.STRING },
  company: { type: DataTypes.STRING },
  status: { type: DataTypes.ENUM('active', 'inactive', 'prospect'), defaultValue: 'prospect' },
  notes: { type: DataTypes.TEXT },
  createdBy: { type: DataTypes.INTEGER, allowNull: false }
}, { tableName: 'clients' });

const Campaign = sequelize.define('Campaign', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  name: { type: DataTypes.STRING, allowNull: false },
  type: { type: DataTypes.ENUM('email', 'whatsapp'), allowNull: false },
  subject: { type: DataTypes.STRING },
  content: { type: DataTypes.TEXT },
  status: { type: DataTypes.ENUM('draft', 'scheduled', 'sent'), defaultValue: 'draft' },
  scheduledAt: { type: DataTypes.DATE },
  sentAt: { type: DataTypes.DATE },
  createdBy: { type: DataTypes.INTEGER, allowNull: false }
}, { tableName: 'campaigns' });

const Task = sequelize.define('Task', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  title: { type: DataTypes.STRING, allowNull: false },
  description: { type: DataTypes.TEXT },
  priority: { type: DataTypes.ENUM('low', 'medium', 'high'), defaultValue: 'medium' },
  status: { type: DataTypes.ENUM('pending', 'in_progress', 'completed'), defaultValue: 'pending' },
  progress: { type: DataTypes.INTEGER, defaultValue: 0 },
  dueDate: { type: DataTypes.DATE },
  assignedTo: { type: DataTypes.INTEGER, allowNull: false },
  createdBy: { type: DataTypes.INTEGER, allowNull: false },
  isShared: { type: DataTypes.BOOLEAN, defaultValue: false }
}, { tableName: 'tasks' });

const SystemSettings = sequelize.define('SystemSettings', {
  id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
  companyLogo: { type: DataTypes.STRING },
  companySlogan: { type: DataTypes.STRING },
  primaryColor: { type: DataTypes.STRING, defaultValue: '#3B82F6' },
  secondaryColor: { type: DataTypes.STRING, defaultValue: '#1E40AF' },
  developerLogo: { type: DataTypes.STRING },
  developerWebsite: { type: DataTypes.STRING },
  developerEmail: { type: DataTypes.STRING },
  developerPhone: { type: DataTypes.STRING },
  licenseType: { type: DataTypes.STRING },
  licenseExpiry: { type: DataTypes.DATE }
}, { tableName: 'system_settings' });

async function runMigrations() {
  try {
    console.log('🔄 Iniciando migrações do banco de dados...');

    // Testar conexão
    await sequelize.authenticate();
    console.log('✅ Conexão com o banco estabelecida');

    // Sincronizar modelos (criar tabelas)
    await sequelize.sync({ force: false });
    console.log('✅ Tabelas sincronizadas');

    // Verificar se já existem dados
    const userCount = await User.count();
    
    if (userCount === 0) {
      console.log('📦 Banco vazio. Executando população inicial...');
      await populateInitialData();
    } else {
      console.log(`✅ Banco já contém ${userCount} usuários. Migração concluída.`);
    }

    console.log('🎉 Migrações concluídas com sucesso!');
    process.exit(0);

  } catch (error) {
    console.error('❌ Erro nas migrações:', error);
    process.exit(1);
  }
}

async function populateInitialData() {
  try {
    const bcrypt = require('bcryptjs');

    // Criar usuário admin
    const adminUser = await User.create({
      name: 'Administrador SenseiRM',
      email: 'admin@senseirm.com',
      password: await bcrypt.hash('admin123', 12),
      role: 'admin'
    });
    console.log('✅ Usuário admin criado: admin@senseirm.com / admin123');

    // Criar usuário regular
    const regularUser = await User.create({
      name: 'Usuário Demo',
      email: 'user@senseirm.com',
      password: await bcrypt.hash('user123', 12),
      role: 'user'
    });
    console.log('✅ Usuário regular criado: user@senseirm.com / user123');

    // Criar clientes de exemplo
    const clients = await Client.bulkCreate([
      {
        name: 'João Silva',
        email: 'joao@empresa.com',
        phone: '(11) 99999-9999',
        company: 'Tech Solutions LTDA',
        status: 'active',
        notes: 'Cliente preferencial',
        createdBy: adminUser.id
      },
      {
        name: 'Maria Santos',
        email: 'maria@empresa.com',
        phone: '(11) 88888-8888',
        company: 'Inova Corporação',
        status: 'prospect',
        notes: 'Potencial cliente',
        createdBy: adminUser.id
      }
    ]);
    console.log(`✅ ${clients.length} clientes criados`);

    // Criar configurações do sistema
    const systemSettings = await SystemSettings.create({
      companyLogo: '/uploads/logo.png',
      companySlogan: 'Sistema de Gestão de Relacionamento com Clientes',
      primaryColor: '#3B82F6',
      secondaryColor: '#1E40AF',
      developerLogo: '/uploads/dev-logo.png',
      developerWebsite: 'https://devcompany.com',
      developerEmail: 'contato@devcompany.com',
      developerPhone: '+55 (11) 99999-9999',
      licenseType: 'Enterprise',
      licenseExpiry: new Date('2024-12-31')
    });
    console.log('✅ Configurações do sistema criadas');

  } catch (error) {
    console.error('❌ Erro na população de dados:', error);
    throw error;
  }
}

// Executar se chamado diretamente
if (require.main === module) {
  runMigrations();
}

module.exports = { runMigrations, populateInitialData };
EOF

# Configurar PM2
echo "📊 Configurando PM2..."
cd $BACKEND_DIR

# Criar ecosystem file
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'senseirm-backend',
    script: './server.js',
    instances: 1,
    exec_mode: 'fork',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    error_file: '$APP_DIR/logs/err.log',
    out_file: '$APP_DIR/logs/out.log',
    log_file: '$APP_DIR/logs/combined.log',
    time: true,
    merge_logs: true,
    max_memory_restart: '1G',
    watch: false
  }]
};
EOF

# Parar instância PM2 existente
echo "🛑 Parando instância PM2 existente..."
pm2 stop senseirm-backend 2>/dev/null || true
pm2 delete senseirm-backend 2>/dev/null || true

# **EXECUTAR MIGRAÇÕES DO BANCO**
echo "🗃️ Executando migrações do banco..."

# Verificar se as dependências estão disponíveis
cd $BACKEND_DIR
if node -e "require('sequelize')" 2>/dev/null; then
    echo "✅ Sequelize disponível"
    cd $DATABASE_DIR
    node migrate.js
else
    echo "❌ Sequelize não disponível. Instalando dependências..."
    cd $BACKEND_DIR
    npm install sequelize mysql2 bcryptjs --save
    
    echo "🔄 Executando migração simplificada..."
    node -e "
        const { Sequelize, DataTypes } = require('sequelize');
        const bcrypt = require('bcryptjs');
        
        const sequelize = new Sequelize('senseirm', 'senseirm_user', 'SenseiRM@123!', {
            host: 'localhost',
            dialect: 'mysql'
        });
        
        async function setup() {
            try {
                await sequelize.authenticate();
                console.log('✅ Conectado ao MySQL');
                
                // Criar tabelas básicas
                const User = sequelize.define('User', {
                    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
                    name: { type: DataTypes.STRING, allowNull: false },
                    email: { type: DataTypes.STRING, unique: true, allowNull: false },
                    password: { type: DataTypes.STRING, allowNull: false },
                    role: { type: DataTypes.ENUM('admin', 'user'), defaultValue: 'user' },
                    isActive: { type: DataTypes.BOOLEAN, defaultValue: true }
                });
                
                await sequelize.sync({ force: false });
                console.log('✅ Tabelas criadas');
                
                // Criar usuário admin
                const adminCount = await User.count({ where: { role: 'admin' } });
                if (adminCount === 0) {
                    await User.create({
                        name: 'Administrador SenseiRM',
                        email: 'admin@senseirm.com',
                        password: await bcrypt.hash('admin123', 12),
                        role: 'admin'
                    });
                    console.log('✅ Usuário admin criado: admin@senseirm.com / admin123');
                }
                
                console.log('🎉 Configuração do banco concluída');
            } catch (error) {
                console.error('❌ Erro:', error.message);
            }
        }
        
        setup();
    "
fi

# Iniciar aplicação com PM2
echo "🟢 Iniciando aplicação com PM2..."
cd $BACKEND_DIR
pm2 start ecosystem.config.js
pm2 save

echo ""
echo "🎉 DEPLOY CONCLUÍDO COM SUCESSO!"
echo "🌐 Acesse: http://$(curl -s ifconfig.me || hostname -I | awk '{print $1}')"
echo "📊 Monitor: pm2 monit"
echo "📋 Credenciais: admin@senseirm.com / admin123"
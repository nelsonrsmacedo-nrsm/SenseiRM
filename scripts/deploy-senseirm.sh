#!/bin/bash
# scripts/deploy-senseirm.sh

set -e

echo "🚀 Iniciando deploy do SenseiRM..."

# Configurações
APP_DIR="/opt/senseirm"
BACKEND_DIR="$APP_DIR/backend"
FRONTEND_DIR="$APP_DIR/frontend"
LOG_DIR="$APP_DIR/logs"
UPLOAD_DIR="$APP_DIR/uploads"

# Carregar credenciais do banco
if [ -f "$APP_DIR/install-info.txt" ]; then
    DB_PASSWORD=$(grep "Password:" $APP_DIR/install-info.txt | head -1 | awk '{print $3}')
else
    echo "❌ Arquivo de instalação não encontrado. Execute install-prerequisites.sh primeiro."
    exit 1
fi

# Criar diretório de uploads se não existir
mkdir -p $UPLOAD_DIR

# Configurar backend
echo "🔧 Configurando backend..."
cd $BACKEND_DIR

# Criar arquivo .env
cat > .env << EOF
NODE_ENV=production
PORT=5000
DB_HOST=localhost
DB_PORT=3306
DB_NAME=senseirm
DB_USER=senseirm_user
DB_PASS=$DB_PASSWORD
JWT_SECRET=$(openssl rand -base64 64)
JWT_EXPIRES_IN=24h

# Configurações de Email (opcional)
SMTP_HOST=your-smtp-host.com
SMTP_PORT=587
SMTP_USER=your-email@company.com
SMTP_PASS=your-email-password
SMTP_FROM=SenseiRM <noreply@senseirm.com>

# Configurações WhatsApp (opcional)
WHATSAPP_API_URL=https://api.whatsapp.com
WHATSAPP_API_TOKEN=your-whatsapp-token

# Upload
UPLOAD_DIR=$UPLOAD_DIR
MAX_FILE_SIZE=10485760

# Log
LOG_LEVEL=info
EOF

# Instalar dependências do backend
echo "📦 Instalando dependências do backend..."
npm install --production

# Configurar frontend
echo "🎨 Configurando frontend..."
cd $FRONTEND_DIR

# Criar arquivo .env
cat > .env << EOF
REACT_APP_API_URL=http://localhost:5000/api
REACT_APP_VERSION=1.0.0
GENERATE_SOURCEMAP=false
EOF

# Instalar dependências e build
echo "📦 Instalando dependências do frontend..."
npm install --production

echo "🏗️ Criando build de produção..."
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
        alias $UPLOAD_DIR;
        expires 6M;
        add_header Cache-Control "public";
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
}
EOF

# Testar configuração do Nginx
echo "🧪 Testando configuração do Nginx..."
sudo nginx -t

# Recarregar Nginx
echo "🔄 Recarregando Nginx..."
sudo systemctl reload nginx

# Configurar PM2
echo "📊 Configurando PM2..."
cd $BACKEND_DIR

# Criar ecosystem file
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'senseirm-backend',
    script: './server.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    error_file: '$LOG_DIR/err.log',
    out_file: '$LOG_DIR/out.log',
    log_file: '$LOG_DIR/combined.log',
    time: true,
    merge_logs: true,
    max_memory_restart: '1G',
    watch: false,
    ignore_watch: ['node_modules', 'logs'],
    instance_var: 'INSTANCE_ID'
  }]
};
EOF

# Iniciar aplicação com PM2
echo "🟢 Iniciando aplicação..."
pm2 start ecosystem.config.js
pm2 save
pm2 startup

# Executar migrações do banco
echo "🗃️ Executando migrações do banco..."
node database/migrate.js

echo "✅ Deploy concluído com sucesso!"
echo "🌐 Acesse: http://localhost"
echo "📊 Monitor: pm2 monit"
#!/bin/bash
# scripts/install-prerequisites.sh

set -e

echo "🚀 Iniciando instalação dos pré-requisitos do SenseiRM..."

# Configurações
NODE_VERSION="18"
MYSQL_ROOT_PASSWORD="SenseiRM@123!"
SENSEIRM_DB_PASSWORD=$(openssl rand -base64 16)

# Atualizar sistema
echo "📦 Atualizando sistema..."
sudo dnf update -y

# Instalar Node.js
echo "📥 Instalando Node.js $NODE_VERSION..."
curl -fsSL https://rpm.nodesource.com/setup_$NODE_VERSION.x | sudo bash -
sudo dnf install -y nodejs

# Instalar e configurar MySQL
echo "🗄️ Instalando MySQL..."
sudo dnf install -y mysql-server mysql

echo "⚙️ Configurando MySQL..."
sudo systemctl enable mysqld
sudo systemctl start mysqld

# Configurar segurança do MySQL
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Criar banco e usuário do SenseiRM
sudo mysql -uroot -p$MYSQL_ROOT_PASSWORD << EOF
CREATE DATABASE IF NOT EXISTS senseirm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'senseirm_user'@'localhost' IDENTIFIED BY '$SENSEIRM_DB_PASSWORD';
GRANT ALL PRIVILEGES ON senseirm.* TO 'senseirm_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# Instalar Nginx
echo "🌐 Instalando Nginx..."
sudo dnf install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Instalar PM2
echo "📊 Instalando PM2..."
sudo npm install -g pm2

# Configurar firewall
echo "🔥 Configurando firewall..."
sudo dnf install -y firewalld
sudo systemctl enable firewalld
sudo systemctl start firewalld

sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-service=mysql
sudo firewall-cmd --reload

# Criar diretórios necessários
echo "📁 Criando diretórios..."
sudo mkdir -p /opt/senseirm/{backend,frontend,logs,uploads}
sudo chown -R $USER:$USER /opt/senseirm

# Salvar credenciais
echo "💾 Salvando credenciais..."
cat > /opt/senseirm/install-info.txt << EOF
SenseiRM - Informações de Instalação
=====================================

Database:
- Name: senseirm
- User: senseirm_user
- Password: $SENSEIRM_DB_PASSWORD
- Root Password: $MYSQL_ROOT_PASSWORD

Diretórios:
- Backend: /opt/senseirm/backend
- Frontend: /opt/senseirm/frontend
- Logs: /opt/senseirm/logs
- Uploads: /opt/senseirm/uploads

Serviços:
- MySQL: systemctl status mysqld
- Nginx: systemctl status nginx
- Node.js: $(node --version)
- NPM: $(npm --version)
EOF

echo "✅ Pré-requisitos instalados com sucesso!"
echo "📋 Informações salvas em: /opt/senseirm/install-info.txt"
#!/bin/bash
# scripts/install-prerequisites.sh

set -e

echo "🚀 Iniciando instalação dos pré-requisitos do SenseiRM..."

# Configurações
NODE_VERSION="18"
MYSQL_ROOT_PASSWORD="SenseiRM@123!"
SENSEIRM_DB_PASSWORD="SenseiRM@123!"

# Função para log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Atualizar sistema
log "📦 Atualizando sistema..."
sudo dnf update -y

# Instalar dependências básicas
log "📥 Instalando dependências básicas..."
sudo dnf install -y curl wget git unzip

# Instalar Node.js
log "📥 Instalando Node.js $NODE_VERSION..."
curl -fsSL https://rpm.nodesource.com/setup_$NODE_VERSION.x | sudo bash -
sudo dnf install -y nodejs
echo "✅ Node.js $(node --version) instalado"

# **INSTALAÇÃO MYSQL 8.0 - MÉTODO CORRIGIDO**
log "🗄️ Instalando MySQL Server..."

# Remover instalação existente se houver
sudo systemctl stop mysqld 2>/dev/null || true

# Instalar MySQL
sudo dnf install -y mysql-server mysql

# Iniciar MySQL
log "🔄 Iniciando MySQL..."
sudo systemctl enable mysqld
sudo systemctl start mysqld

# Aguardar inicialização
log "⏳ Aguardando inicialização do MySQL..."
for i in {1..30}; do
    if sudo systemctl is-active --quiet mysqld; then
        log "✅ MySQL está rodando"
        break
    fi
    sleep 1
done

sleep 5

# Configurar senha root
log "🔐 Configurando senha root..."

# Método 1: Tentar acesso sem senha (funciona em novas instalações)
if sudo mysql -u root -e "SELECT 1;" &>/dev/null; then
    log "✅ Conseguiu acessar sem senha"
    sudo mysql -u root << EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
    log "✅ Senha root configurada com sucesso"

# Método 2: Se não conseguiu sem senha, usar arquivo de inicialização
else
    log "⚠️ Não conseguiu acessar sem senha. Usando método de inicialização..."
    
    sudo systemctl stop mysqld
    
    # Criar arquivo de inicialização temporário
    sudo cat > /tmp/mysql-init.sql << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    # Iniciar MySQL com arquivo de inicialização
    sudo mysqld --init-file=/tmp/mysql-init.sql &
    MYSQL_INIT_PID=$!
    
    sleep 10
    
    # Parar MySQL de inicialização
    sudo kill $MYSQL_INIT_PID 2>/dev/null || true
    wait $MYSQL_INIT_PID 2>/dev/null || true
    
    # Iniciar normalmente
    sudo systemctl start mysqld
    sleep 5
fi

# Verificar configuração
log "🔍 Verificando configuração do MySQL..."
if mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SELECT 1;" &>/dev/null; then
    log "✅ MySQL configurado com sucesso"
else
    log "❌ Falha na configuração automática do MySQL"
    log "📋 Execute manualmente: sudo mysql_secure_installation"
    log "💡 Durante a configuração:"
    log "   - Senha atual: Enter (vazio)"
    log "   - Nova senha: ${MYSQL_ROOT_PASSWORD}"
    log "   - Confirmar senha: ${MYSQL_ROOT_PASSWORD}"
    log "   - Todas outras opções: Y"
    exit 1
fi

# Criar banco de dados SenseiRM
log "🗃️ Criando banco de dados SenseiRM..."
mysql -u root -p${MYSQL_ROOT_PASSWORD} << EOF
CREATE DATABASE IF NOT EXISTS senseirm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'senseirm_user'@'localhost' IDENTIFIED BY '${SENSEIRM_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON senseirm.* TO 'senseirm_user'@'localhost';
FLUSH PRIVILEGES;
EOF

log "✅ Banco de dados e usuário criados com sucesso"

# Instalar Nginx
log "🌐 Instalando Nginx..."
sudo dnf install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Instalar PM2
log "📊 Instalando PM2..."
sudo npm install -g pm2

# Configurar firewall
log "🔥 Configurando firewall..."
sudo dnf install -y firewalld
sudo systemctl enable firewalld
sudo systemctl start firewalld

sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload

# Criar estrutura de diretórios
log "📁 Criando estrutura de diretórios..."
sudo mkdir -p /opt/senseirm/{backend,frontend,logs,uploads,database,scripts}
sudo chown -R $USER:$USER /opt/senseirm
sudo chmod -R 755 /opt/senseirm

# Criar arquivo de informações
log "💾 Salvando informações de configuração..."
cat > /opt/senseirm/install-info.txt << EOF
SenseiRM - Informações de Instalação
=====================================

✅ PRÉ-REQUISITOS INSTALADOS COM SUCESSO

CREDENCIAIS DO BANCO DE DADOS:
- Host: localhost
- Database: senseirm
- Usuário: senseirm_user
- Senha: ${SENSEIRM_DB_PASSWORD}
- Root Password: ${MYSQL_ROOT_PASSWORD}

DIRETÓRIOS:
- Backend: /opt/senseirm/backend
- Frontend: /opt/senseirm/frontend  
- Logs: /opt/senseirm/logs
- Uploads: /opt/senseirm/uploads

SERVIÇOS:
- MySQL: systemctl status mysqld
- Nginx: systemctl status nginx
- Node.js: $(node --version)
- NPM: $(npm --version)

PRÓXIMOS PASSOS:
1. Copie os arquivos do projeto para /opt/senseirm/
2. Execute: cd /opt/senseirm && ./scripts/deploy-senseirm.sh
3. Execute: cd /opt/senseirm/backend && node ../database/populate.js

ACESSO:
- URL: http://$(curl -s ifconfig.me 2>/dev/null || echo "seu-ip")
- Admin: admin@senseirm.com / admin123
- Usuário: user@senseirm.com / user123

Data da Instalação: $(date)
EOF

echo ""
echo "🎉 PRÉ-REQUISITOS INSTALADOS COM SUCESSO!"
echo "📋 Informações salvas em: /opt/senseirm/install-info.txt"
echo ""
echo "🔧 PRÓXIMOS PASSOS:"
echo "1. Copie os arquivos: scp -r senseirm/* usuario@servidor:/opt/senseirm/"
echo "2. Acesse o servidor: ssh usuario@servidor"
echo "3. Execute o deploy: cd /opt/senseirm && ./scripts/deploy-senseirm.sh"
echo "4. Popule o banco: cd backend && node ../database/populate.js"
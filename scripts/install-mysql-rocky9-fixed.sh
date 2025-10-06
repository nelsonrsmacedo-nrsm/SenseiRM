#!/bin/bash
# scripts/install-mysql-rocky9-fixed.sh

set -e

echo "🔧 INSTALAÇÃO MYSQL 8.0 - ROCKY LINUX 9.5"

# Remover instalação existente
echo "🗑️ Limpando instalação anterior..."
sudo systemctl stop mysqld 2>/dev/null || true
sudo dnf remove -y mysql-server mysql 2>/dev/null || true
sudo rm -rf /var/lib/mysql
sudo rm -f /etc/my.cnf*

# Instalar MySQL
echo "📥 Instalando MySQL Server..."
sudo dnf install -y mysql-server mysql

# Iniciar MySQL
echo "🔄 Iniciando MySQL..."
sudo systemctl enable mysqld
sudo systemctl start mysqld

# Aguardar inicialização
echo "⏳ Aguardando inicialização do MySQL..."
for i in {1..30}; do
    if sudo systemctl is-active --quiet mysqld; then
        echo "✅ MySQL está rodando"
        break
    fi
    sleep 1
done

sleep 5

# Tentar configurar senha - Múltiplos métodos
echo "🔐 Configurando senha root..."

# Método 1: Acesso direto sem senha (funciona em novas instalações)
if sudo mysql -u root -e "SELECT 1;" &>/dev/null; then
    echo "✅ Conseguiu acessar sem senha"
    sudo mysql -u root << 'EOF'
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'SenseiRM@123!';
FLUSH PRIVILEGES;
EOF
    echo "✅ Senha configurada com sucesso"

# Método 2: Se não conseguiu sem senha, usar arquivo de inicialização
else
    echo "⚠️ Não conseguiu acessar sem senha. Usando método de inicialização..."
    
    sudo systemctl stop mysqld
    
    # Criar arquivo de inicialização temporário
    sudo cat > /tmp/mysql-init.sql << 'EOF'
ALTER USER 'root'@'localhost' IDENTIFIED BY 'SenseiRM@123!';
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
echo "🔍 Verificando configuração..."
if mysql -u root -pSenseiRM@123! -e "SELECT '✅ MYSQL CONFIGURADO!' AS message;" &>/dev/null; then
    echo "🎉 MYSQL CONFIGURADO COM SUCESSO!"
    
    # Criar banco SenseiRM
    echo "🗃️ Criando banco de dados..."
    mysql -u root -pSenseiRM@123! << 'EOF'
CREATE DATABASE IF NOT EXISTS senseirm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'senseirm_user'@'localhost' IDENTIFIED BY 'SenseiRM@123!';
GRANT ALL PRIVILEGES ON senseirm.* TO 'senseirm_user'@'localhost';
FLUSH PRIVILEGES;
SHOW DATABASES;
EOF
    
    echo ""
    echo "📋 CREDENCIAIS:"
    echo "   MySQL Root: SenseiRM@123!"
    echo "   Database: senseirm" 
    echo "   User: senseirm_user"
    echo "   Password: SenseiRM@123!"
else
    echo "❌ Falha na configuração automática."
    echo "📋 Execute manualmente:"
    echo "   sudo mysql_secure_installation"
    echo "   E siga as instruções interativas"
fi
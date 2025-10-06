#!/bin/bash
# scripts/fix-mysql-rocky9.sh

set -e

echo "🔧 Correção definitiva para MySQL no Rocky Linux 9.5"

# Parar MySQL
echo "⏹️ Parando MySQL..."
sudo systemctl stop mysqld

# Criar arquivo de inicialização para configurar senha
echo "📝 Criando script de inicialização..."
sudo cat > /tmp/mysql-reset-root.sql << 'EOF'
UPDATE mysql.user SET 
    authentication_string = PASSWORD('SenseiRM@123!'),
    plugin = 'mysql_native_password'
WHERE user = 'root' AND host = 'localhost';
FLUSH PRIVILEGES;
EOF

# Método 1: Inicializar com arquivo de reset
echo "🔄 Inicializando MySQL com reset de senha..."
sudo mysqld --init-file=/tmp/mysql-reset-root.sql --skip-grant-tables &
MYSQL_PID=$!
echo "⏳ Aguardando inicialização (15 segundos)..."
sleep 15

# Parar MySQL temporário
echo "⏹️ Parando MySQL temporário..."
sudo kill $MYSQL_PID 2>/dev/null || true
wait $MYSQL_PID 2>/dev/null || true

# Iniciar MySQL normalmente
echo "🔄 Iniciando MySQL normalmente..."
sudo systemctl start mysqld
sleep 5

# Verificar se funcionou
echo "🔍 Verificando configuração..."
if mysql -u root -pSenseiRM@123! -e "SELECT 1;" &>/dev/null; then
    echo "✅ MySQL configurado com sucesso!"
    
    # Criar banco de dados
    echo "🗃️ Criando banco de dados SenseiRM..."
    mysql -u root -pSenseiRM@123! << 'EOF'
CREATE DATABASE IF NOT EXISTS senseirm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'senseirm_user'@'localhost' IDENTIFIED BY 'SenseiRM@123!';
GRANT ALL PRIVILEGES ON senseirm.* TO 'senseirm_user'@'localhost';
FLUSH PRIVILEGES;
EOF
    echo "✅ Banco de dados criado!"
else
    echo "❌ Ainda não funcionou. Tentando método alternativo..."
    
    # Método alternativo: reinstalação completa
    sudo dnf reinstall -y mysql-server mysql
    sudo systemctl start mysqld
    sleep 5
    
    # Configurar senha
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'SenseiRM@123!';"
fi

echo ""
echo "🎉 CONFIGURAÇÃO DO MYSQL CONCLUÍDA!"
echo "📋 Credenciais:"
echo "   Usuário: root"
echo "   Senha: SenseiRM@123!"
echo "   Banco: senseirm"
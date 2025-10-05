#!/bin/bash
# scripts/validate-deployment.sh

echo "Validando implantação do SenseiRM..."

# Verificar se serviços estão rodando
services=("nginx" "mysqld" "pm2")
for service in "${services[@]}"; do
  if systemctl is-active --quiet $service || pgrep -x $service > /dev/null; then
    echo "✓ $service está rodando"
  else
    echo "✗ $service não está rodando"
    exit 1
  fi
done

# Testar API
API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/health)
if [ "$API_RESPONSE" == "200" ]; then
  echo "✓ API respondendo corretamente"
else
  echo "✗ API não está respondendo"
  exit 1
fi

# Testar frontend
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)
if [ "$FRONTEND_RESPONSE" == "200" ]; then
  echo "✓ Frontend respondendo corretamente"
else
  echo "✗ Frontend não está respondendo"
  exit 1
fi

# Verificar banco de dados
DB_CHECK=$(mysql -u senseirm_user -p$DB_PASS -e "USE senseirm; SELECT COUNT(*) FROM users;" 2>/dev/null)
if [ $? -eq 0 ]; then
  echo "✓ Banco de dados acessível"
else
  echo "✗ Problema com banco de dados"
  exit 1
fi

echo "Validação concluída com sucesso! Sistema SenseiRM está operacional."
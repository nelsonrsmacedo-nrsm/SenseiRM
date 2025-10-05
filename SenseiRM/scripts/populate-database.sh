#!/bin/bash
# scripts/populate-database.sh

echo "Populando banco de dados com dados iniciais..."

mysql -u root -p senseirm << EOF

-- Inserir usuário admin padrão
INSERT INTO users (name, email, password, role) VALUES (
  'Administrador',
  'admin@senseirm.com',
  '\$2a\$12\$K9e./.XLOVqkL8.Y8n7y.OG8QJ.rQ8QbY1qQ8Q8Q8Q8Q8Q8Q8Q8Q', -- senha: admin123
  'admin'
);

-- Inserir configurações padrão do sistema
INSERT INTO system_settings (
  company_logo,
  company_slogan,
  primary_color,
  secondary_color,
  developer_logo,
  developer_website,
  developer_email,
  developer_phone,
  license_type
) VALUES (
  '/assets/default-logo.png',
  'Sistema de Gestão de Relacionamento com Clientes',
  '#3B82F6',
  '#1E40AF',
  '/assets/dev-logo.png',
  'https://devcompany.com',
  'contato@devcompany.com',
  '+55 (11) 99999-9999',
  'Enterprise'
);

-- Inserir clientes de exemplo
INSERT INTO clients (name, email, phone, company, status, created_by) VALUES
('João Silva', 'joao@empresa.com', '(11) 99999-9999', 'Empresa A', 'active', 1),
('Maria Santos', 'maria@empresa.com', '(11) 88888-8888', 'Empresa B', 'prospect', 1);

-- Inserir tarefas de exemplo
INSERT INTO tasks (title, description, priority, status, progress, assigned_to, created_by) VALUES
('Reunião com cliente', 'Apresentação do novo produto', 'high', 'pending', 0, 1, 1),
('Enviar proposta', 'Enviar proposta comercial para Empresa B', 'medium', 'in_progress', 50, 1, 1);

EOF

echo "Banco de dados populado com sucesso!"
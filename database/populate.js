// database/populate.js
const { sequelize } = require('../backend/src/config/database');
const { User, Client, Campaign, Task, SystemSettings } = require('../backend/src/models');
const logger = require('../backend/src/utils/logger');

async function populateDatabase() {
  try {
    logger.info('Iniciando população do banco de dados...');

    // Sincronizar modelos
    await sequelize.sync({ force: false });
    logger.info('✅ Modelos sincronizados');

    // Verificar se já existem dados
    const adminCount = await User.count({ where: { role: 'admin' } });
    
    if (adminCount > 0) {
      logger.info('✅ Banco de dados já populado');
      return;
    }

    // Criar usuário admin
    const adminUser = await User.create({
      name: 'Administrador SenseiRM',
      email: 'admin@senseirm.com',
      password: 'admin123',
      role: 'admin'
    });
    logger.info('✅ Usuário admin criado: admin@senseirm.com / admin123');

    // Criar usuário regular
    const regularUser = await User.create({
      name: 'Usuário Demo',
      email: 'user@senseirm.com',
      password: 'user123',
      role: 'user'
    });
    logger.info('✅ Usuário regular criado: user@senseirm.com / user123');

    // Criar clientes de exemplo
    const clients = await Client.bulkCreate([
      {
        name: 'João Silva',
        email: 'joao@empresa.com',
        phone: '(11) 99999-9999',
        company: 'Tech Solutions LTDA',
        status: 'active',
        notes: 'Cliente preferencial - interessado em novos produtos',
        createdBy: adminUser.id
      },
      {
        name: 'Maria Santos',
        email: 'maria@empresa.com',
        phone: '(11) 88888-8888',
        company: 'Inova Corporação',
        status: 'prospect',
        notes: 'Potencial cliente - agendar demonstração',
        createdBy: adminUser.id
      },
      {
        name: 'Pedro Oliveira',
        email: 'pedro@startup.com',
        phone: '(11) 77777-7777',
        company: 'StartUp Tech',
        status: 'active',
        notes: 'Cliente desde 2022 - bom pagador',
        createdBy: regularUser.id
      },
      {
        name: 'Ana Costa',
        email: 'ana@consultoria.com',
        phone: '(11) 66666-6666',
        company: 'Costa Consultoria',
        status: 'inactive',
        notes: 'Cliente inativo - mudou para concorrente',
        createdBy: adminUser.id
      }
    ]);
    logger.info(`✅ ${clients.length} clientes criados`);

    // Criar campanhas de exemplo
    const campaigns = await Campaign.bulkCreate([
      {
        name: 'Campanha de Boas Vindas',
        type: 'email',
        subject: 'Bem-vindo ao SenseiRM!',
        content: `
          <h1>Olá {{name}}!</h1>
          <p>Seja bem-vindo(a) ao SenseiRM, sua plataforma de gestão de relacionamento com clientes.</p>
          <p>Estamos muito felizes em tê-lo(a) conosco.</p>
          <p>Atenciosamente,<br>Equipe SenseiRM</p>
        `,
        status: 'sent',
        sentAt: new Date(),
        recipientCount: 3,
        successCount: 3,
        createdBy: adminUser.id
      },
      {
        name: 'Promoção Especial',
        type: 'email',
        subject: 'Oferta Exclusiva para Você!',
        content: `
          <h1>Olá {{name}}!</h1>
          <p>Temos uma oferta especial para sua empresa {{company}}.</p>
          <p>Entre em contato conosco para saber mais!</p>
          <p>Atenciosamente,<br>Equipe Comercial</p>
        `,
        status: 'draft',
        createdBy: regularUser.id
      }
    ]);
    logger.info(`✅ ${campaigns.length} campanhas criadas`);

    // Criar tarefas de exemplo
    const tasks = await Task.bulkCreate([
      {
        title: 'Reunião com João Silva',
        description: 'Apresentar novos produtos e serviços',
        priority: 'high',
        status: 'pending',
        progress: 0,
        dueDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000), // 2 dias
        assignedTo: adminUser.id,
        createdBy: adminUser.id,
        isShared: true
      },
      {
        title: 'Enviar proposta comercial',
        description: 'Preparar e enviar proposta para Maria Santos',
        priority: 'medium',
        status: 'in_progress',
        progress: 50,
        dueDate: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000), // 1 dia
        assignedTo: regularUser.id,
        createdBy: adminUser.id,
        isShared: false
      },
      {
        title: 'Follow-up com Pedro Oliveira',
        description: 'Ligar para verificar satisfação com o serviço',
        priority: 'low',
        status: 'completed',
        progress: 100,
        dueDate: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000), // 1 dia atrás
        assignedTo: adminUser.id,
        createdBy: regularUser.id,
        isShared: true
      }
    ]);
    logger.info(`✅ ${tasks.length} tarefas criadas`);

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
    logger.info('✅ Configurações do sistema criadas');

    logger.info('🎉 População do banco de dados concluída com sucesso!');

  } catch (error) {
    logger.error('❌ Erro na população do banco:', error);
    process.exit(1);
  }
}

// Executar se chamado diretamente
if (require.main === module) {
  populateDatabase()
    .then(() => {
      console.log('População concluída!');
      process.exit(0);
    })
    .catch(error => {
      console.error('Erro:', error);
      process.exit(1);
    });
}

module.exports = populateDatabase;
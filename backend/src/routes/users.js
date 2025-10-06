// backend/src/routes/users.js
const express = require('express');
const { User } = require('../models');
const { requireAdmin } = require('../middleware/auth');
const logger = require('../utils/logger');

const router = express.Router();

// Listar usuários (apenas admin)
router.get('/', requireAdmin, async (req, res) => {
  try {
    const { page = 1, limit = 10, search } = req.query;
    
    const where = {};
    if (search) {
      where[Op.or] = [
        { name: { [Op.like]: `%${search}%` } },
        { email: { [Op.like]: `%${search}%` } }
      ];
    }

    const users = await User.findAndCountAll({
      where,
      attributes: { exclude: ['password'] },
      limit: parseInt(limit),
      offset: (page - 1) * limit,
      order: [['createdAt', 'DESC']]
    });

    res.json({
      users: users.rows,
      totalPages: Math.ceil(users.count / limit),
      currentPage: parseInt(page),
      totalUsers: users.count
    });

  } catch (error) {
    logger.error('Erro ao listar usuários:', error);
    res.status(500).json({ 
      error: 'Erro interno do servidor' 
    });
  }
});

// Criar usuário (apenas admin)
router.post('/', requireAdmin, async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ 
        error: 'Nome, email e senha são obrigatórios' 
      });
    }

    // Verificar se email já existe
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ 
        error: 'Email já está em uso' 
      });
    }

    const user = await User.create({
      name,
      email,
      password,
      role: role || 'user'
    });

    logger.info(`Admin ${req.user.email} criou usuário ${email}`);

    res.status(201).json(user.toSafeObject());

  } catch (error) {
    logger.error('Erro ao criar usuário:', error);
    res.status(500).json({ 
      error: 'Erro interno do servidor' 
    });
  }
});

// Atualizar usuário
router.put('/:id', requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, email, role, isActive } = req.body;

    const user = await User.findByPk(id);
    if (!user) {
      return res.status(404).json({ 
        error: 'Usuário não encontrado' 
      });
    }

    // Verificar se email já existe (outro usuário)
    if (email && email !== user.email) {
      const existingUser = await User.findOne({ where: { email } });
      if (existingUser) {
        return res.status(400).json({ 
          error: 'Email já está em uso' 
        });
      }
    }

    await user.update({
      name: name || user.name,
      email: email || user.email,
      role: role || user.role,
      isActive: isActive !== undefined ? isActive : user.isActive
    });

    logger.info(`Admin ${req.user.email} atualizou usuário ${user.email}`);

    res.json(user.toSafeObject());

  } catch (error) {
    logger.error('Erro ao atualizar usuário:', error);
    res.status(500).json({ 
      error: 'Erro interno do servidor' 
    });
  }
});

// Deletar usuário (apenas admin)
router.delete('/:id', requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    // Impedir auto-exclusão
    if (parseInt(id) === req.user.id) {
      return res.status(400).json({ 
        error: 'Não é possível excluir seu próprio usuário' 
      });
    }

    const user = await User.findByPk(id);
    if (!user) {
      return res.status(404).json({ 
        error: 'Usuário não encontrado' 
      });
    }

    await user.destroy();

    logger.info(`Admin ${req.user.email} deletou usuário ${user.email}`);

    res.json({ 
      message: 'Usuário excluído com sucesso' 
    });

  } catch (error) {
    logger.error('Erro ao deletar usuário:', error);
    res.status(500).json({ 
      error: 'Erro interno do servidor' 
    });
  }
});

// Obter perfil do usuário logado
router.get('/profile', async (req, res) => {
  try {
    const user = await User.findByPk(req.user.id, {
      attributes: { exclude: ['password'] }
    });
    
    res.json(user);

  } catch (error) {
    logger.error('Erro ao obter perfil:', error);
    res.status(500).json({ 
      error: 'Erro interno do servidor' 
    });
  }
});

// Atualizar perfil do usuário logado
router.put('/profile', async (req, res) => {
  try {
    const { name, email } = req.body;

    const user = await User.findByPk(req.user.id);
    
    // Verificar se email já existe (outro usuário)
    if (email && email !== user.email) {
      const existingUser = await User.findOne({ where: { email } });
      if (existingUser) {
        return res.status(400).json({ 
          error: 'Email já está em uso' 
        });
      }
    }

    await user.update({
      name: name || user.name,
      email: email || user.email
    });

    logger.info(`Usuário ${user.email} atualizou seu perfil`);

    res.json(user.toSafeObject());

  } catch (error) {
    logger.error('Erro ao atualizar perfil:', error);
    res.status(500).json({ 
      error: 'Erro interno do servidor' 
    });
  }
});

module.exports = router;
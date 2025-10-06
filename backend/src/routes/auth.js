// backend/src/routes/auth.js
const express = require('express');
const jwt = require('jsonwebtoken');
const { User } = require('../models');
const { authenticateToken } = require('../middleware/auth');
const logger = require('../utils/logger');

const router = express.Router();

// Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ 
        error: 'Email e senha são obrigatórios' 
      });
    }

    // Buscar usuário
    const user = await User.findOne({ 
      where: { email } 
    });

    if (!user || !user.isActive) {
      return res.status(401).json({ 
        error: 'Credenciais inválidas' 
      });
    }

    // Validar senha
    const isValidPassword = await user.validatePassword(password);
    if (!isValidPassword) {
      return res.status(401).json({ 
        error: 'Credenciais inválidas' 
      });
    }

    // Atualizar último login
    await user.update({ lastLogin: new Date() });

    // Gerar token JWT
    const token = jwt.sign(
      { 
        userId: user.id,
        email: user.email,
        role: user.role
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
    );

    // Retornar dados do usuário (sem senha) e token
    const userData = user.toSafeObject();
    
    logger.info(`Usuário ${user.email} fez login`);

    res.json({
      user: userData,
      token,
      expiresIn: process.env.JWT_EXPIRES_IN || '24h'
    });

  } catch (error) {
    logger.error('Erro no login:', error);
    res.status(500).json({ 
      error: 'Erro interno do servidor' 
    });
  }
});

// Alterar senha
router.post('/change-password', authenticateToken, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ 
        error: 'Senha atual e nova senha são obrigatórias' 
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ 
        error: 'A nova senha deve ter pelo menos 6 caracteres' 
      });
    }

    // Buscar usuário com senha
    const user = await User.findByPk(req.user.id);
    
    // Validar senha atual
    const isValidPassword = await user.validatePassword(currentPassword);
    if (!isValidPassword) {
      return res.status(401).json({ 
        error: 'Senha atual incorreta' 
      });
    }

    // Atualizar senha
    await user.update({ password: newPassword });

    logger.info(`Usuário ${user.email} alterou a senha`);

    res.json({ 
      message: 'Senha alterada com sucesso' 
    });

  } catch (error) {
    logger.error('Erro ao alterar senha:', error);
    res.status(500).json({ 
      error: 'Erro interno do servidor' 
    });
  }
});

// Verificar token
router.get('/verify', authenticateToken, (req, res) => {
  res.json({ 
    user: req.user,
    valid: true 
  });
});

// Logout (client-side - apenas invalidar token localmente)
router.post('/logout', authenticateToken, (req, res) => {
  logger.info(`Usuário ${req.user.email} fez logout`);
  res.json({ 
    message: 'Logout realizado com sucesso' 
  });
});

module.exports = router;
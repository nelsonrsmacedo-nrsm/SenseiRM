// backend/src/utils/emailService.js
const nodemailer = require('nodemailer');
const logger = require('./logger');

class EmailService {
  constructor() {
    this.transporter = null;
    this.initializeTransporter();
  }

  initializeTransporter() {
    if (process.env.SMTP_HOST && process.env.SMTP_USER && process.env.SMTP_PASS) {
      this.transporter = nodemailer.createTransporter({
        host: process.env.SMTP_HOST,
        port: process.env.SMTP_PORT || 587,
        secure: process.env.SMTP_SECURE === 'true',
        auth: {
          user: process.env.SMTP_USER,
          pass: process.env.SMTP_PASS
        }
      });

      // Verificar configuração
      this.transporter.verify()
        .then(() => logger.info('✅ Serviço de email configurado com sucesso'))
        .catch(error => logger.warn('⚠️ Serviço de email não disponível:', error.message));
    } else {
      logger.warn('⚠️ Configuração de email não encontrada. Serviço de email desativado.');
    }
  }

  async sendEmail(to, subject, html, text = null) {
    if (!this.transporter) {
      throw new Error('Serviço de email não configurado');
    }

    try {
      const info = await this.transporter.sendMail({
        from: process.env.SMTP_FROM || `"SenseiRM" <${process.env.SMTP_USER}>`,
        to,
        subject,
        text: text || this.htmlToText(html),
        html
      });

      logger.info(`Email enviado para ${to}: ${info.messageId}`);
      return info;
    } catch (error) {
      logger.error('Erro ao enviar email:', error);
      throw error;
    }
  }

  htmlToText(html) {
    return html
      .replace(/<[^>]*>/g, '')
      .replace(/\n{3,}/g, '\n\n')
      .trim();
  }

  async sendCampaign(campaign, clients) {
    if (!this.transporter) {
      throw new Error('Serviço de email não configurado');
    }

    const results = [];
    
    for (const client of clients) {
      try {
        const personalizedContent = this.personalizeContent(campaign.content, client);
        const personalizedSubject = this.personalizeContent(campaign.subject, client);
        
        await this.sendEmail(
          client.email,
          personalizedSubject,
          personalizedContent
        );

        results.push({
          clientId: client.id,
          status: 'sent',
          email: client.email
        });

        logger.info(`Campanha "${campaign.name}" enviada para ${client.email}`);

      } catch (error) {
        results.push({
          clientId: client.id,
          status: 'failed',
          email: client.email,
          error: error.message
        });

        logger.error(`Falha ao enviar campanha para ${client.email}:`, error.message);
      }
    }

    return results;
  }

  personalizeContent(content, client) {
    if (!content) return content;
    
    return content
      .replace(/{{name}}/g, client.name || 'Cliente')
      .replace(/{{company}}/g, client.company || '')
      .replace(/{{email}}/g, client.email || '')
      .replace(/{{phone}}/g, client.phone || '');
  }
}

module.exports = new EmailService();
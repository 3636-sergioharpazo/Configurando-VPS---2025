# 🧠 Smart VPS Manager PRO

**Criado por Antonio Oliveira | Smart Software**  

Smart VPS Manager PRO é um instalador **Full Stack para VPS**, que permite instalar, configurar e gerenciar os sistemas mais utilizados do mercado atual de forma automatizada, incluindo Docker, Portainer, Chatwoot, Typebot, n8n, Waha, Evolucion CRM, scaffolds de jogos/bet e mais de 20 sistemas adicionais.  

O script fornece **configuração automática de banco de dados, SMTP, URLs, envio de e-mail de teste e monitoramento do status de cada serviço**.  

## 🚀 Sistemas incluídos

- **Docker & Docker Compose**
- **Portainer** – Gestão de containers
- **n8n** – Automação de fluxos
- **Waha** – Gestão de conteúdo
- **Chatwoot** (2 instâncias) – CRM e suporte
- **Typebot** – Chatbot interativo
- **Evolucion CRM**
- **Scaffold de jogos/bet Node.js + Nginx**
- **Bancos de dados**: PostgreSQL, MySQL, MongoDB, Redis
- **20 sistemas adicionais populares**:  
  Metabase, Grafana, Prometheus, Rocket.Chat, Nextcloud, Taiga, Redmine, Odoo, ERPNext, Ghost, Strapi, WordPress, Jitsi, Zabbix, Node-RED, Elasticsearch, Kibana, RabbitMQ, MinIO, Superset, Mattermost  

## 📝 Funcionalidades

- Instalação completa e automática de todos os sistemas
- Configuração de bancos de dados e variáveis de ambiente
- Configuração de SMTP e envio de e-mail de teste
- Scaffold para desenvolvimento de jogos e apostas
- Systemd unit para iniciar todos os serviços automaticamente no boot
- Acompanhamento de cada etapa da instalação com logs coloridos ✅/❌
- Configuração interativa de URLs e senhas para Typebot e Chatwoot  

## 💻 Pré-requisitos

- VPS Linux (Debian/Ubuntu recomendado)
- Acesso root ou sudo
- Porta aberta para cada serviço desejado (ver tabela de serviços abaixo)

| Serviço            | Porta padrão  |
|-------------------|---------------|
| Portainer         | 9443          |
| n8n               | 5678          |
| Waha              | 3000          |
| Chatwoot          | 3001          |
| Chatwoot Nestor   | 3002          |
| Typebot           | 8081          |
| Games Scaffold    | 4000          |
| Metabase          | 3003          |
| Grafana           | 3004          |
| Prometheus        | 3005          |
| Rocket.Chat       | 3006          |
| Nextcloud         | 3007          |

> Outras portas podem ser definidas durante a configuração do script.  

---

## ⚙️ Instalação

1. Clone o repositório:

```bash
git clone https://github.com/3636-sergioharpazo/Configurando-VPS---2025.git
cd Configurando-VPS---2025

# Smart VPS Manager PRO

🚀 **Smart VPS Manager PRO**  
Criado por **Antonio Oliveira | Smart Software**

---

## Descrição

O **Smart VPS Manager PRO** é um instalador completo para servidores VPS (Ubuntu/Debian), que permite instalar e configurar automaticamente uma **stack completa de aplicações modernas**, incluindo:

- **Docker e Docker Compose**
- **Portainer** (gerenciamento de containers)
- **n8n** (automação de workflows)
- **Waha**
- **Chatwoot** (duas instâncias: Principal e Nestor)
- **Typebot** (com banco de dados dedicado e configuração de SMTP)
- **Evolucion CRM** (placeholder)
- **PostgreSQL, MySQL, MongoDB, Redis**
- **Scaffold de plataforma de jogos / bet** (Node.js + Nginx)
- Envio de **e-mail de teste** após configuração SMTP
- **Logs de instalação e status** de cada serviço
- Configuração automática via **systemd** para iniciar a stack no boot

---

## Pré-requisitos

- VPS com **Ubuntu 20.04 / 22.04** ou **Debian 11/12**
- Acesso root (`sudo`)
- Firewall liberando portas usadas:
  - 80, 443 → Games / Nginx
  - 9443 → Portainer
  - 3000 → Waha
  - 3001 → Chatwoot Principal
  - 3002 → Chatwoot Nestor
  - 5678 → n8n
  - 8081 → Typebot

---

## Instalação

1. Baixe o script:

```bash
wget https://github.com/seuusuario/smart-vps-manager-pro/raw/main/smart-vps-pro-full.sh

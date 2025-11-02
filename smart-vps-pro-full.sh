#!/usr/bin/env bash
# =========================================================
# 🧠 SMART VPS MANAGER PRO - FULL
# 🚀 Criado por Antonio Oliveira | Smart Software
# =========================================================
# Instalador Full Stack:
# Docker, Portainer, n8n, Waha, Chatwoot (2 instâncias), Typebot, Evolucion CRM, bancos de dados
# Plataforma de jogos/bet (scaffold Node + Nginx)
# SMTP Typebot + envio de e-mail de teste
# =========================================================

set -euo pipefail
IFS=$'\n\t'

# ------------------ CONFIG DEFAULTS ------------------
APP_DIR="${APP_DIR:-/opt/smart-vps-manager}"
CREDITO="Criado por Antonio Oliveira | Smart Software"
POSTGRES_TYPEBOT_PASS="${POSTGRES_TYPEBOT_PASS:-change_me_typebot}"
POSTGRES_MAIN_PASS="${POSTGRES_MAIN_PASS:-change_me_chatwoot}"
POSTGRES_NESTOR_PASS="${POSTGRES_NESTOR_PASS:-change_me_chatwoot_nestor}"
MYSQL_ROOT_PASS="${MYSQL_ROOT_PASS:-change_me_mysql}"
MONGO_ROOT_PASS="${MONGO_ROOT_PASS:-change_me_mongo}"
# ------------------------------------------------------

# ------------------ UTILITIES ------------------------
msg(){ echo -e "\e[1;34m[INFO]\e[0m $*"; }
ok(){ echo -e "\e[1;32m[OK]\e[0m $*"; }
warn(){ echo -e "\e[1;33m[WARN]\e[0m $*"; }
err(){ echo -e "\e[1;31m[ERR]\e[0m $*"; }
step_passed(){ echo -e "\e[1;32m✅ $*\e[0m"; }
step_failed(){ echo -e "\e[1;31m❌ $*\e[0m"; }

ensure_root() {
  if [[ $EUID -ne 0 ]]; then
    err "Execute como root (use sudo)."
    exit 1
  fi
}

pause_short(){ sleep 1; }

# ------------------ PREREQUISITOS --------------------
install_prereqs() {
  msg "Atualizando repositórios e instalando pacotes básicos..."
  apt update -y && apt upgrade -y
  apt install -y ca-certificates curl gnupg lsb-release wget git apt-transport-https software-properties-common unzip openssl mailutils msmtp >/dev/null
  step_passed "Pacotes básicos instalados"
}

# ------------------ DOCKER ---------------------------
install_docker() {
  if command -v docker >/dev/null 2>&1; then
    ok "Docker já instalado (`docker --version`)"
    return 0
  fi
  msg "Instalando Docker..."
  mkdir -p /etc/apt/keyrings
  DIST_ID=$(. /etc/os-release; echo "$ID")
  curl -fsSL "https://download.docker.com/linux/${DIST_ID}/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DIST_ID} $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt update -y
  apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null
  systemctl enable docker && systemctl start docker
  step_passed "Docker instalado com sucesso"
}

# ------------------ DIRETÓRIOS E COMPOSE ------------
create_app_dir() {
  msg "Criando diretório de trabalho em $APP_DIR..."
  mkdir -p "$APP_DIR"
  chown -R root:root "$APP_DIR"
  step_passed "Diretório $APP_DIR pronto"
}

generate_compose_and_configs() {
  msg "Gerando docker-compose.yml e arquivos .env..."

  # docker-compose.yml
  cat > "$APP_DIR/docker-compose.yml" <<'YAML'
version: '3.8'
services:
  postgres_typebot:
    image: postgres:15
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_TYPEBOT_PASS}
      POSTGRES_DB: typebot
    volumes:
      - pgdata_typebot:/var/lib/postgresql/data
    networks:
      - smartnet

  postgres_main:
    image: postgres:15
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_MAIN_PASS}
      POSTGRES_DB: chatwoot_db
    volumes:
      - pgdata_main:/var/lib/postgresql/data
    networks:
      - smartnet

  postgres_nestor:
    image: postgres:15
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_NESTOR_PASS}
      POSTGRES_DB: chatwoot_nestor_db
    volumes:
      - pgdata_nestor:/var/lib/postgresql/data
    networks:
      - smartnet

  redis:
    image: redis:7
    restart: unless-stopped
    command: ["redis-server", "--save", "60", "1", "--appendonly", "yes"]
    volumes:
      - redisdata:/data
    networks:
      - smartnet

  portainer:
    image: portainer/portainer-ce:latest
    restart: unless-stopped
    ports:
      - "9443:9443"
      - "8000:8000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    networks:
      - smartnet

  n8n:
    image: n8nio/n8n:latest
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres_typebot
      DB_POSTGRESDB_DATABASE: n8n
      DB_POSTGRESDB_USER: postgres
      DB_POSTGRESDB_PASSWORD: ${POSTGRES_TYPEBOT_PASS}
    volumes:
      - n8ndata:/home/node/.n8n
    depends_on:
      - postgres_typebot
    networks:
      - smartnet

  waha:
    image: ghcr.io/devlikeapro/waha:latest
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - waha_data:/app/data
    networks:
      - smartnet

  chatwoot:
    image: chatwoot/chatwoot:latest
    restart: unless-stopped
    env_file:
      - ./chatwoot.env
    ports:
      - "3001:3000"
    depends_on:
      - postgres_main
      - redis
    networks:
      - smartnet

  chatwoot_nestor:
    image: chatwoot/chatwoot:latest
    restart: unless-stopped
    env_file:
      - ./chatwoot_nestor.env
    ports:
      - "3002:3000"
    depends_on:
      - postgres_nestor
      - redis
    networks:
      - smartnet

  evolucion_crm:
    image: evolucion/crm:latest
    restart: unless-stopped
    environment:
      - DB_HOST=postgres_typebot
      - DB_PASSWORD=${POSTGRES_TYPEBOT_PASS}
    volumes:
      - evolucion_data:/var/lib/evolucion
    networks:
      - smartnet

  typebot:
    image: typebot/typebot:latest
    restart: unless-stopped
    env_file:
      - ./typebot.env
    ports:
      - "8081:3000"
    depends_on:
      - postgres_typebot
    networks:
      - smartnet

volumes:
  pgdata_typebot:
  pgdata_main:
  pgdata_nestor:
  redisdata:
  portainer_data:
  n8ndata:
  waha_data:
  evolucion_data:

networks:
  smartnet:
    driver: bridge
YAML

  # .env Typebot placeholder
  cat > "$APP_DIR/typebot.env" <<EOF
POSTGRES_HOST=postgres_typebot
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=${POSTGRES_TYPEBOT_PASS}
POSTGRES_DB=typebot
EOF

  # Chatwoot .env
  cat > "$APP_DIR/chatwoot.env" <<EOF
RAILS_ENV=production
SECRET_KEY_BASE=$(openssl rand -hex 32)
DB_HOST=postgres_main
DB_USERNAME=postgres
DB_PASSWORD=${POSTGRES_MAIN_PASS}
REDIS_URL=redis://redis:6379/0
EOF

  cat > "$APP_DIR/chatwoot_nestor.env" <<EOF
RAILS_ENV=production
SECRET_KEY_BASE=$(openssl rand -hex 32)
DB_HOST=postgres_nestor
DB_USERNAME=postgres
DB_PASSWORD=${POSTGRES_NESTOR_PASS}
REDIS_URL=redis://redis:6379/0
EOF

  ok "docker-compose.yml e arquivos .env criados"
}

download_games_skeleton() {
  msg "Criando scaffold básico para jogos/bet..."
  mkdir -p "$APP_DIR/games-skeleton"
  cat > "$APP_DIR/games-skeleton/package.json" <<'JSON'
{
  "name": "games-skeleton",
  "version": "1.0.0",
  "scripts": { "start:prod": "node server.js" },
  "dependencies": { "express": "^4.18.2" }
}
JSON
  cat > "$APP_DIR/games-skeleton/server.js" <<'JS'
const express = require('express');
const app = express();
app.get('/', (req,res) => res.send('Games platform scaffold - by Antonio Oliveira'));
const port = process.env.PORT || 4000;
app.listen(port, ()=> console.log('Running on', port));
JS
  ok "Scaffold criado em $APP_DIR/games-skeleton"
}

# ------------------ START SERVICES -------------------
start_compose() {
  msg "Subindo stack Docker..."
  cd "$APP_DIR"
  docker compose up -d --remove-orphans
  step_passed "Stack iniciada"
}

# ------------------ CHECK DATABASES ------------------
check_postgres_db() {
  DB_NAME=$1
  DB_USER=$2
  DB_PASS=$3
  DB_HOST=$4
  export PGPASSWORD=$DB_PASS
  if psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c '\q' >/dev/null 2>&1; then
    step_passed "Banco $DB_NAME ($DB_HOST) acessível ✅"
  else
    step_failed "Falha ao conectar no banco $DB_NAME ($DB_HOST) ❌"
  fi
  unset PGPASSWORD
}

# ------------------ TYPEBOT + SMTP -------------------
install_typebot() {
  msg "=========== INSTALAÇÃO TYPEBOT ==========="
  read -p "URL/DOMÍNIO do Typebot: " TYPEBOT_URL
  read -p "E-mail admin: " TYPEBOT_ADMIN_EMAIL
  read -s -p "Senha admin: " TYPEBOT_ADMIN_PASS
  echo ""
  msg "Configuração SMTP"
  read -p "SMTP host: " SMTP_HOST
  read -p "SMTP porta (465/587): " SMTP_PORT
  while [[ "$SMTP_PORT" != "465" && "$SMTP_PORT" != "587" ]]; do
    err "Porta inválida"
    read -p "SMTP porta (465/587): " SMTP_PORT
  done
  read -p "SMTP user: " SMTP_USER
  read -s -p "SMTP pass: " SMTP_PASS
  echo ""
  read -p "E-mail para teste (enter para usar o mesmo): " SMTP_TEST_TO
  [[ -z "$SMTP_TEST_TO" ]] && SMTP_TEST_TO="$SMTP_USER"

  cat > "$APP_DIR/typebot.env" <<EOF
POSTGRES_HOST=postgres_typebot
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_PASSWORD=${POSTGRES_TYPEBOT_PASS}
POSTGRES_DB=typebot
APP_URL=${TYPEBOT_URL}
NEXTAUTH_URL=${TYPEBOT_URL}
NEXTAUTH_SECRET=$(openssl rand -base64 32)
ADMIN_EMAIL=${TYPEBOT_ADMIN_EMAIL}
ADMIN_PASSWORD=${TYPEBOT_ADMIN_PASS}

SMTP_HOST=${SMTP_HOST}
SMTP_PORT=${SMTP_PORT}
SMTP_USER=${SMTP_USER}
SMTP_PASS=${SMTP_PASS}
EOF

  step_passed "Arquivo typebot.env criado"

  msg "Iniciando container Typebot..."
  docker run -d --rm --name typebot \
    --env-file "$APP_DIR/typebot.env" \
    -p 8081:3000 \
    typebot/typebot:latest >/dev/null 2>&1 || true
  sleep 3
  docker ps --format '{{.Names}}' | grep -q '^typebot$' && step_passed "Typebot iniciado ✅" || step_failed "Typebot não iniciou ❌"

  msg "Enviando e-mail de teste..."
  MSmtpConf="/root/.msmtprc"
  cat > "$MSmtpConf" <<MSMTP
defaults
auth on
tls on
tls_starttls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
account default
host ${SMTP_HOST}
port ${SMTP_PORT}
user ${SMTP_USER}
password ${SMTP_PASS}
from ${SMTP_USER}
MSMTP
  chmod 600 "$MSmtpConf"

  echo -e "Assunto: Teste SMTP\n\nEste é um teste do Smart VPS Manager PRO.\nServiço Typebot." \
    | msmtp --debug --verbose --from=default "$SMTP_TEST_TO" 2> /tmp/smtp_test.log || true

  if tail -n 200 /tmp/smtp_test.log | grep -qi "error\|failed"; then
    step_failed "E-mail de teste falhou. Verifique /tmp/smtp_test.log"
  else
    step_passed "E-mail de teste enviado para $SMTP_TEST_TO ✅"
  fi
}

# ------------------ SYSTEMD UNIT ---------------------
create_systemd_unit() {
  msg "Criando unit systemd..."
  cat > /etc/systemd/system/smart-vps-manager.service <<SERVICE
[Unit]
Description=Smart VPS Manager - docker compose up
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${APP_DIR}
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
SERVICE

  systemctl daemon-reload
  systemctl enable smart-vps-manager.service
  step_passed "Systemd unit criada"
}

# ------------------ SUMMARY -------------------------
print_summary() {
  msg "================ RESUMO ================="
  step_passed "Diretório: ${APP_DIR}"
  echo "Arquivos importantes:"
  echo " - docker-compose.yml"
  echo " - typebot.env"
  echo " - chatwoot.env / chatwoot_nestor.env"
  echo
  echo "Serviços expostos (default):"
  echo " - Portainer: https://SEU_IP:9443"
  echo " - n8n: http://SEU_IP:5678"
  echo " - Waha: http://SEU_IP:3000"
  echo " - Chatwoot: http://SEU_IP:3001"
  echo " - Chatwoot Nestor: http://SEU_IP:3002"
  echo " - Typebot: http://SEU_IP:8081"
  echo " - Games scaffold: http://SEU_IP:80"
  echo
  msg "${CREDITO}"
  msg "Fim da execução."
}

# ------------------ MAIN ----------------------------
main() {
  ensure_root
  install_prereqs
  install_docker
  create_app_dir
  generate_compose_and_configs
  download_games_skeleton
  start_compose
  step_passed "Checando bancos de dados..."
  check_postgres_db "typebot" "postgres" "$POSTGRES_TYPEBOT_PASS" "postgres_typebot"
  check_postgres_db "chatwoot_db" "postgres" "$POSTGRES_MAIN_PASS" "postgres_main"
  check_postgres_db "chatwoot_nestor_db" "postgres" "$POSTGRES_NESTOR_PASS" "postgres_nestor"
  create_systemd_unit
  install_typebot
  print_summary
}

main "$@"

#!/bin/bash

# ==========================================
# СКРИПТ ИСПРАВЛЕНИЯ КОНФИГУРАЦИИ NGINX
# ==========================================
# Версия: 1.0.0
# Дата: 01.05.2025
# Автор: ATOM-GAME Team
# ==========================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Переменные настройки
DOMAIN="atomgameblk.ru"
SERVER_IP="193.109.78.85"
APP_PORT=5000  # Порт на котором работает приложение

# Функции для вывода
log() {
  echo -e "${BLUE}[ИНФО]${NC} $1"
}

success() {
  echo -e "${GREEN}[УСПЕХ]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[ВНИМАНИЕ]${NC} $1"
}

error() {
  echo -e "${RED}[ОШИБКА]${NC} $1"
}

# Проверка запуска от root
if [ "$(id -u)" != "0" ]; then
   error "Этот скрипт должен быть запущен от имени root"
   error "Пожалуйста, используйте: sudo ./fix-nginx.sh"
   exit 1
fi

# Получение реального порта приложения из текущего процесса
log "Определение реального порта приложения..."
if pm2 list | grep -q "atom-game"; then
  # Получение реальных переменных окружения приложения из экосистемы PM2
  if [ -f "/var/www/atomgameblk/ecosystem.config.cjs" ]; then
    # Используем grep и sed для извлечения порта из файла конфигурации PM2
    APP_PORT=$(grep -E "PORT.+[0-9]+" /var/www/atomgameblk/ecosystem.config.cjs | grep -o "[0-9]\+" | head -1)
    log "Найден порт приложения в ecosystem.config.cjs: $APP_PORT"
  fi
else
  warn "Приложение не запущено через PM2. Используется порт по умолчанию: $APP_PORT"
fi

# Исправление конфигурации Nginx
log "Настройка Nginx..."
cat > /etc/nginx/sites-available/$DOMAIN << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN $SERVER_IP;

    location / {
        proxy_pass http://localhost:$APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
    }

    # Логи
    access_log /var/log/nginx/$DOMAIN-access.log;
    error_log /var/log/nginx/$DOMAIN-error.log;
}
EOF

# Удаление дефолтной конфигурации
log "Удаление дефолтной конфигурации Nginx..."
rm -f /etc/nginx/sites-enabled/default

# Создание символической ссылки
log "Создание символической ссылки..."
ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/

# Проверка конфигурации Nginx
log "Проверка конфигурации Nginx..."
nginx -t
success "Конфигурация Nginx корректна"

# Перезапуск Nginx
log "Перезапуск Nginx..."
systemctl restart nginx
success "Nginx перезапущен"

# Открываем порты в брандмауэре (если есть)
log "Настройка брандмауэра..."
if command -v ufw &> /dev/null; then
  ufw allow 80/tcp
  ufw allow 443/tcp
  success "Брандмауэр настроен для HTTP и HTTPS через ufw"
elif command -v firewall-cmd &> /dev/null; then
  firewall-cmd --permanent --add-service=http
  firewall-cmd --permanent --add-service=https
  firewall-cmd --reload
  success "Брандмауэр настроен для HTTP и HTTPS через firewalld"
fi

# Проверка работы приложения
log "Проверка доступности приложения..."
if curl -s http://localhost:$APP_PORT > /dev/null; then
  success "Приложение доступно локально на порту $APP_PORT"
else
  warn "Приложение не отвечает на порту $APP_PORT. Проверьте, запущено ли оно."
  warn "Проверьте логи приложения: pm2 logs atom-game"
fi

echo "=================================================================="
echo "        ИСПРАВЛЕНИЕ NGINX ЗАВЕРШЕНО УСПЕШНО!"
echo "=================================================================="
echo ""
echo "Ваш сайт должен быть доступен по следующим адресам:"
echo "- http://$DOMAIN"
echo "- http://www.$DOMAIN"
echo "- http://$SERVER_IP"
echo ""
echo "Для просмотра логов Nginx:"
echo "- Ошибки: sudo tail -f /var/log/nginx/$DOMAIN-error.log"
echo "- Доступ: sudo tail -f /var/log/nginx/$DOMAIN-access.log"
echo ""
echo "Если сайт все еще не доступен, проверьте логи приложения:"
echo "pm2 logs atom-game"
echo "=================================================================="
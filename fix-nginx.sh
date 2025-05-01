#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${GREEN}=========================================================${NC}"
echo -e "${BOLD}${GREEN}       Настройка Nginx для работы по IP                  ${NC}"
echo -e "${BOLD}${GREEN}=========================================================${NC}"

# Конфигурационные параметры
DOMAIN="atomgameblk.ru"
IP="193.109.78.85"
PORT="5001"

# Проверка root прав
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Скрипт должен быть запущен с правами root${NC}"
  echo -e "${YELLOW}Выполните: sudo bash $0${NC}"
  exit 1
fi

# Создаем резервную копию конфигурации
echo -e "\n${YELLOW}Создание резервной копии конфигурации Nginx...${NC}"
cp -f /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-available/${DOMAIN}.bak

# Создаем новую конфигурацию, включающую IP-адрес
echo -e "\n${YELLOW}Создание новой конфигурации Nginx...${NC}"
cat > /etc/nginx/sites-available/${DOMAIN} << EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} www.${DOMAIN} ${IP};
    
    location / {
        proxy_pass http://localhost:${PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Кэширование статических файлов
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        proxy_pass http://localhost:${PORT};
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }
    
    # Увеличиваем лимит размера загружаемых файлов
    client_max_body_size 10M;
}

# Конфигурация для SSL (добавляется автоматически certbot-ом)
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name ${DOMAIN} www.${DOMAIN};
    
    # SSL-конфигурация автоматически добавляется certbot-ом
    
    location / {
        proxy_pass http://localhost:${PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Кэширование статических файлов
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        proxy_pass http://localhost:${PORT};
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }
    
    # Увеличиваем лимит размера загружаемых файлов
    client_max_body_size 10M;
    
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

# Дополнительный сервер для IP-адреса (без SSL)
server {
    listen 80;
    listen [::]:80;
    server_name ${IP};
    
    location / {
        proxy_pass http://localhost:${PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Кэширование статических файлов
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        proxy_pass http://localhost:${PORT};
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }
    
    # Увеличиваем лимит размера загружаемых файлов
    client_max_body_size 10M;
}
EOF

# Проверяем конфигурацию и перезапускаем Nginx
echo -e "\n${YELLOW}Проверка конфигурации Nginx...${NC}"
nginx -t
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Конфигурация Nginx корректна, перезапускаем...${NC}"
  systemctl restart nginx
  echo -e "${GREEN}Nginx успешно перезапущен${NC}"
else
  echo -e "${RED}Ошибка в конфигурации Nginx${NC}"
  echo -e "${YELLOW}Восстанавливаем исходную конфигурацию...${NC}"
  cp -f /etc/nginx/sites-available/${DOMAIN}.bak /etc/nginx/sites-available/${DOMAIN}
  systemctl restart nginx
  exit 1
fi

echo -e "\n${BOLD}${GREEN}=========================================================${NC}"
echo -e "${BOLD}${GREEN}       Nginx настроен для работы по IP-адресу!           ${NC}"
echo -e "${BOLD}${GREEN}=========================================================${NC}"
echo -e "${GREEN}Сайт теперь должен быть доступен по следующим адресам:${NC}"
echo -e "${GREEN}- https://${DOMAIN} (с SSL)${NC}"
echo -e "${GREEN}- http://${IP} (без SSL)${NC}"
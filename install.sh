#!/bin/bash

# ==========================================
# СКРИПТ ПОЛНОЙ УСТАНОВКИ ATOM-GAME
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
   error "Пожалуйста, используйте: sudo ./install.sh"
   exit 1
fi

# Переменные настройки
INSTALL_DIR="/var/www/atomgameblk"
APP_PORT=5000
DB_NAME="atomgame"
DB_USER="atomgame"
DB_PASSWORD="Atom&Game#2025!"
ESCAPED_PASSWORD=$(echo $DB_PASSWORD | sed 's/&/%26/g; s/#/%23/g')
SESSION_SECRET=$(openssl rand -hex 32)

# Шаг 1: Установка необходимых пакетов
log "Установка необходимых пакетов..."
apt update
apt install -y nginx postgresql postgresql-contrib nodejs npm curl git

# Установка PM2 глобально
log "Установка PM2..."
npm install -g pm2
success "PM2 установлен"

# Шаг 2: Создание директории проекта
log "Создание директории проекта..."
mkdir -p $INSTALL_DIR
success "Директория проекта создана"

# Шаг 3: Создание и настройка базы данных PostgreSQL
log "Настройка базы данных PostgreSQL..."
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" || true
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" || true
sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;" || true
success "База данных создана"

# Шаг 4: Клонирование репозитория
log "Клонирование репозитория из GitHub..."
cd $INSTALL_DIR
git clone https://github.com/Edivin2000/TeamRatingTracker.git . || git pull
success "Репозиторий клонирован"

# Шаг 5: Установка зависимостей NPM
log "Установка зависимостей NPM..."
npm install
success "Зависимости установлены"

# Шаг 6: Исправление файла для подключения к базе данных
log "Исправление файла подключения к базе данных..."
cat > $INSTALL_DIR/server/db.ts << EOF
import { Pool } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-serverless';
import * as schema from "@shared/schema";

// Получение строки подключения из переменных окружения
const DATABASE_URL = process.env.DATABASE_URL || 'postgresql://$DB_USER:$ESCAPED_PASSWORD@localhost:5432/$DB_NAME';
console.log('Connecting to database using URL:', DATABASE_URL);

// Создание пула соединений
const pool = new Pool({ 
  connectionString: DATABASE_URL,
  ssl: false
});

// Создание экземпляра Drizzle ORM
const db = drizzle({ client: pool, schema });
console.log('Database connection pool created successfully');

export { pool, db };
EOF
success "Файл подключения к базе данных исправлен"

# Шаг 7: Сборка приложения
log "Сборка приложения..."
npm run build
success "Приложение собрано"

# Шаг 8: Создание и применение миграций Drizzle
log "Применение миграций базы данных..."
npm run db:push
success "Миграции применены"

# Шаг 9: Настройка PM2 для запуска приложения
log "Настройка PM2..."
cat > $INSTALL_DIR/ecosystem.config.cjs << EOF
module.exports = {
  apps: [
    {
      name: 'atom-game',
      script: 'dist/index.js',
      cwd: '$INSTALL_DIR',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: '$APP_PORT',
        PGUSER: '$DB_USER',
        PGPASSWORD: '$DB_PASSWORD',
        PGDATABASE: '$DB_NAME',
        PGHOST: 'localhost',
        PGPORT: '5432',
        DATABASE_URL: 'postgresql://$DB_USER:$ESCAPED_PASSWORD@localhost:5432/$DB_NAME',
        SESSION_SECRET: '$SESSION_SECRET'
      },
      watch: false,
      max_memory_restart: '500M'
    }
  ]
};
EOF
success "Конфигурация PM2 создана"

# Шаг 10: Настройка Nginx
log "Настройка Nginx..."
cat > /etc/nginx/sites-available/atomgameblk.ru << EOF
server {
    listen 80;
    server_name atomgameblk.ru www.atomgameblk.ru 193.109.78.85;

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

    access_log /var/log/nginx/atomgameblk.ru-access.log;
    error_log /var/log/nginx/atomgameblk.ru-error.log;
}
EOF

# Удаление дефолтного конфига и создание символической ссылки
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/atomgameblk.ru /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx
success "Nginx настроен"

# Шаг 11: Настройка прав доступа
log "Настройка прав доступа..."
chown -R www-data:www-data $INSTALL_DIR
chmod -R 755 $INSTALL_DIR
success "Права доступа настроены"

# Шаг 12: Запуск приложения через PM2
log "Запуск приложения через PM2..."
cd $INSTALL_DIR
pm2 delete all || true
pm2 start ecosystem.config.cjs
pm2 save
pm2 startup
success "Приложение запущено через PM2"

# Шаг 13: Создание скрипта обновления
log "Создание скрипта обновления..."
cat > $INSTALL_DIR/update.sh << EOF
#!/bin/bash
cd $INSTALL_DIR
git pull
npm install
npm run build
pm2 restart atom-game
echo "Обновление успешно завершено!"
EOF
chmod +x $INSTALL_DIR/update.sh
success "Скрипт обновления создан"

# Шаг 14: Создание скрипта резервного копирования
log "Создание скрипта резервного копирования..."
cat > $INSTALL_DIR/backup.sh << EOF
#!/bin/bash
BACKUP_DIR="$INSTALL_DIR/backups"
TIMESTAMP=\$(date +"%Y%m%d%H%M%S")
mkdir -p \$BACKUP_DIR
pg_dump -U $DB_USER -d $DB_NAME > \$BACKUP_DIR/backup_\$TIMESTAMP.sql
echo "Резервное копирование создано: \$BACKUP_DIR/backup_\$TIMESTAMP.sql"
EOF
chmod +x $INSTALL_DIR/backup.sh
success "Скрипт резервного копирования создан"

# Шаг 15: Проверка статуса приложения
log "Проверка статуса приложения..."
sleep 5
if pm2 list | grep -q "atom-game" && pm2 list | grep -q "online"; then
  success "Приложение успешно запущено и находится в статусе online"
else
  warn "Приложение может быть не запущено. Проверьте логи: pm2 logs atom-game"
fi

echo "=================================================================="
echo "        УСТАНОВКА ATOM-GAME ЗАВЕРШЕНА!"
echo "=================================================================="
echo ""
echo "Проверьте доступность сайта по адресам:"
echo "  http://atomgameblk.ru"
echo "  http://193.109.78.85"
echo ""
echo "Учетные данные администратора:"
echo "  Логин: admin"
echo "  Пароль: Atom&Game#2025!"
echo ""
echo "Полезные команды:"
echo "  - Просмотр логов: pm2 logs atom-game"
echo "  - Перезапуск приложения: pm2 restart atom-game"
echo "  - Обновление из GitHub: $INSTALL_DIR/update.sh"
echo "  - Резервное копирование БД: $INSTALL_DIR/backup.sh"
echo "=================================================================="
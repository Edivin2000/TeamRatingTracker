#!/bin/bash

# ==========================================
# СКРИПТ ИСПРАВЛЕНИЯ БАЗЫ ДАННЫХ ATOM-GAME
# ==========================================
# Версия: 1.0.0
# Дата: 01.05.2025
# ==========================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Переменные настройки
DB_NAME="atomgame"
DB_USER="atomgame"
DB_PASSWORD="Atom&Game#2025!"
PROJECT_DIR="/var/www/atomgameblk"
ESCAPED_PASSWORD=$(echo $DB_PASSWORD | sed 's/&/%26/g; s/#/%23/g')
DATABASE_URL="postgresql://$DB_USER:$ESCAPED_PASSWORD@localhost:5432/$DB_NAME"

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
   error "Пожалуйста, используйте: sudo ./fix-database.sh"
   exit 1
fi

# Шаг 1: Остановка PM2 процессов
log "Остановка всех PM2 процессов..."
pm2 delete all 2>/dev/null || true
success "PM2 процессы остановлены."

# Шаг 2: Проверка базы данных PostgreSQL
log "Проверка статуса базы данных PostgreSQL..."
if systemctl is-active --quiet postgresql; then
  success "PostgreSQL уже запущен."
else
  warn "PostgreSQL не запущен. Запускаем..."
  systemctl start postgresql
  success "PostgreSQL запущен."
fi

# Шаг 3: Резервное копирование существующей базы данных (если есть)
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
  log "Создание резервной копии базы данных $DB_NAME..."
  BACKUP_FILE="/tmp/$DB_NAME-backup-$(date +%Y%m%d%H%M%S).sql"
  sudo -u postgres pg_dump $DB_NAME > $BACKUP_FILE
  success "Резервная копия создана: $BACKUP_FILE"
fi

# Шаг 4: Пересоздание базы данных
log "Пересоздание базы данных $DB_NAME..."
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
  log "Удаление существующей базы данных $DB_NAME..."
  sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;"
  success "База данных $DB_NAME удалена."
fi

# Создание пользователя, если не существует
if ! sudo -u postgres psql -c "\du" | grep -qw $DB_USER; then
  log "Создание пользователя $DB_USER..."
  sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';"
else
  log "Пользователь $DB_USER уже существует. Обновление пароля..."
  sudo -u postgres psql -c "ALTER USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';"
fi

# Создание базы данных
log "Создание новой базы данных $DB_NAME..."
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
success "База данных $DB_NAME успешно создана."

# Шаг 5: Переход в директорию проекта
log "Переход в директорию проекта $PROJECT_DIR..."
if [ -d "$PROJECT_DIR" ]; then
  cd $PROJECT_DIR
  success "Перешли в директорию проекта."
else
  error "Директория проекта $PROJECT_DIR не существует!"
  exit 1
fi

# Шаг 6: Применение миграций к базе данных
log "Применение миграций к базе данных..."
export DATABASE_URL=$DATABASE_URL

# Если есть директория 'migrations', используем drizzle-kit для применения миграций
if [ -d "migrations" ]; then
  npx drizzle-kit push:pg
  success "Миграции применены успешно."
else
  # Если нет директории миграций, создаем схему из shared/schema.ts
  log "Директория миграций не найдена, создаем миграции из схемы..."
  npx drizzle-kit generate:pg --schema=./shared/schema.ts --out=./migrations
  npx drizzle-kit push:pg
  success "Схема базы данных создана и применена успешно."
fi

# Шаг 7: Запуск скрипта для загрузки начальных данных
log "Запуск скрипта для загрузки начальных данных..."
cat > /tmp/init-db.js << 'EOF'
import { db } from './server/db.js';
import { users, teams, partners, ads, timers, siteSettings } from './shared/schema.js';

async function initDatabase() {
  try {
    console.log('Инициализация базы данных...');
    
    // Создание админа
    await db.insert(users).values({
      username: 'admin',
      password: '$2b$12$mQH5VJSvzV4Y8kyaVj9rS.HvCwFHU/DHUbyAwhqJ/B8O3NM3fFgLWnFP9vHT8tE76',
      isAdmin: 1
    }).onConflictDoNothing();
    
    // Примеры команд
    const sampleTeams = [
      { name: "Phoenix Force", logoUrl: "https://placehold.co/100x100/orange/white?text=PF", score: 89, excluded: false },
      { name: "Thunderbolts", logoUrl: "https://placehold.co/100x100/blue/white?text=TB", score: 72, excluded: false },
      { name: "Storm Riders", logoUrl: "https://placehold.co/100x100/purple/white?text=SR", score: 68, excluded: false },
      { name: "Arctic Wolves", logoUrl: "https://placehold.co/100x100/teal/white?text=AW", score: 55, excluded: true },
      { name: "Shadow Tigers", logoUrl: "https://placehold.co/100x100/gray/white?text=ST", score: 42, excluded: false },
    ];
    
    for (const team of sampleTeams) {
      await db.insert(teams).values(team).onConflictDoNothing();
    }
    
    // Примеры партнеров
    const samplePartners = [
      { name: "Росэнергоатом", logoUrl: "https://placehold.co/200x100/blue/white?text=Росэнергоатом", website: "https://www.rosenergoatom.ru/", order: 1 },
      { name: "Фонд АТР АЭС", logoUrl: "https://placehold.co/200x100/green/white?text=Фонд+АТР+АЭС", website: "https://atompsy.ru/", order: 2 },
      { name: "ATOM﮳GAME", logoUrl: "https://placehold.co/200x100/orange/white?text=ATOM﮳GAME", website: "https://atomgame.ru/", order: 3 },
    ];
    
    for (const partner of samplePartners) {
      await db.insert(partners).values(partner).onConflictDoNothing();
    }
    
    // Примеры баннеров
    const sampleAds = [
      { 
        title: "Технологический конкурс ATOM﮳GAME", 
        description: "Примите участие в технологическом конкурсе и выиграйте ценные призы", 
        logoUrl: "https://placehold.co/120x80/white/black?text=ATOM﮳GAME", 
        bgImage: "",
        bgColor: "from-blue-600 to-indigo-700",
        buttonText: "Подробнее",
        buttonLink: "https://atomgame.ru/",
        active: true,
        order: 1
      },
      { 
        title: "Росэнергоатом приглашает", 
        description: "Карьера в атомной энергетике для молодых специалистов", 
        logoUrl: "https://placehold.co/120x80/white/blue?text=Росэнергоатом", 
        bgImage: "",
        bgColor: "from-teal-600 to-teal-800",
        buttonText: "Узнать больше",
        buttonLink: "https://www.rosenergoatom.ru/",
        active: true,
        order: 2
      },
    ];
    
    for (const ad of sampleAds) {
      await db.insert(ads).values(ad).onConflictDoNothing();
    }
    
    // Настройки сайта
    await db.insert(siteSettings).values({
      primaryColor: "#000000",
      secondaryColor: "#1e293b",
      accentColor: "#3b82f6",
      headerBgColor: "#0f172a",
      fontPrimary: "Inter",
      borderRadius: "0.5rem",
      buttonStyle: "default",
      tableBgColor: "#1e293b",
      cardBgColor: "#1e293b",
      podiumStyle: "default",
      bgPattern: "none",
      logoPosition: "center",
      updated: new Date().toISOString()
    }).onConflictDoNothing();
    
    console.log('Инициализация базы данных завершена успешно.');
    process.exit(0);
  } catch (error) {
    console.error('Ошибка при инициализации базы данных:', error);
    process.exit(1);
  }
}

initDatabase();
EOF

# Запуск скрипта инициализации через node
npx tsx /tmp/init-db.js
success "Начальные данные успешно загружены в базу данных."

# Шаг 8: Установка правильных разрешений
log "Установка правильных разрешений для файлов проекта..."
chown -R www-data:www-data $PROJECT_DIR
chmod -R 755 $PROJECT_DIR
success "Разрешения установлены."

# Шаг 9: Запуск сервера с помощью PM2
log "Запуск сервера через PM2..."
cd $PROJECT_DIR
export DATABASE_URL=$DATABASE_URL
pm2 start ecosystem.config.js
success "Сервер успешно запущен через PM2."

# Шаг 10: Сохранение конфигурации PM2
log "Сохранение конфигурации PM2..."
pm2 save
success "Конфигурация PM2 сохранена."

# Завершение
success "Восстановление базы данных завершено успешно!"
log "Сервер запущен и должен работать корректно."
log "Для просмотра логов используйте: pm2 logs"
log "Для проверки статуса: pm2 status"
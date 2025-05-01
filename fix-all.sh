#!/bin/bash

# ======================================================
# ПОЛНЫЙ СКРИПТ ВОССТАНОВЛЕНИЯ САЙТА ATOM-GAME
# ======================================================
# Версия: 2.0.0
# Дата: 01.05.2025
# ======================================================
# Скрипт решает проблемы:
# 1. Полностью восстанавливает базу данных
# 2. Заполняет демо-данными для отображения
# 3. Исправляет сохранение изменений (логотипы, фоны и т.д.)
# 4. Настраивает правильное сохранение сессий админа
# 5. Восстанавливает работу всех функций сайта
# ======================================================

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
SESSION_SECRET="AtomGameSecretSession2025!"
UPLOADS_DIR="$PROJECT_DIR/uploads"

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
   error "Пожалуйста, используйте: sudo ./fix-all.sh"
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

# Шаг 6: Создание директории для загрузок, если не существует
log "Проверка и создание директории для загрузок..."
if [ ! -d "$UPLOADS_DIR" ]; then
  mkdir -p "$UPLOADS_DIR"
  success "Директория для загрузок создана: $UPLOADS_DIR"
else
  success "Директория для загрузок уже существует: $UPLOADS_DIR"
fi

# Шаг 7: Обновление файла .env для правильных настроек
log "Обновление файла .env..."
cat > $PROJECT_DIR/.env << EOF
# Основные настройки
NODE_ENV=production
PORT=5000

# База данных PostgreSQL
PGUSER=$DB_USER
PGPASSWORD=$DB_PASSWORD
PGDATABASE=$DB_NAME
PGHOST=localhost
PGPORT=5432
DATABASE_URL=$DATABASE_URL

# Безопасность
SESSION_SECRET=$SESSION_SECRET

# Пути
UPLOADS_DIR=$UPLOADS_DIR
EOF
success "Файл .env обновлен."

# Шаг 8: Обновление зависимостей
log "Обновление NPM зависимостей..."
npm install ws @neondatabase/serverless connect-pg-simple
success "Зависимости успешно обновлены."

# Шаг 9: Обновление файла подключения к базе данных
log "Обновление файла подключения к базе данных..."
cat > server/db.ts << 'EOF'
import { Pool, neonConfig } from '@neondatabase/serverless';
import { drizzle } from 'drizzle-orm/neon-serverless';
import * as schema from "@shared/schema";
import ws from 'ws';

// Configure WebSocket for Neon Database
neonConfig.webSocketConstructor = ws;

// Получение строки подключения из переменных окружения
const DATABASE_URL = process.env.DATABASE_URL || 'postgresql://atomgame:Atom%26Game%232025!@localhost:5432/atomgame';
console.log('Connecting to database using URL:', DATABASE_URL);

// Создание пула соединений
const pool = new Pool({ 
  connectionString: DATABASE_URL,
});

// Создание экземпляра Drizzle ORM
const db = drizzle({ client: pool, schema });
console.log('Database connection pool created successfully');

export { pool, db };
EOF
success "Файл подключения к базе данных обновлен."

# Шаг 10: Создание файла сервиса для правильного сохранения сессий
log "Настройка работы сессий для правильной авторизации..."
cat > server/auth.ts << 'EOF'
import passport from "passport";
import { Strategy as LocalStrategy } from "passport-local";
import { Express } from "express";
import session from "express-session";
import connectPg from "connect-pg-simple";
import { compare } from "bcrypt";
import { pool } from "./db";
import { storage } from "./storage";
import { User as SelectUser } from "@shared/schema";

declare global {
  namespace Express {
    interface User extends SelectUser {}
  }
}

// Сравнение паролей с использованием bcrypt
async function comparePasswords(supplied: string, stored: string) {
  return await compare(supplied, stored);
}

export function setupAuth(app: Express) {
  // Настройка хранилища сессий в PostgreSQL
  const PostgresSessionStore = connectPg(session);
  
  const sessionSettings: session.SessionOptions = {
    store: new PostgresSessionStore({
      pool,
      tableName: 'session',
      createTableIfMissing: true
    }),
    secret: process.env.SESSION_SECRET || 'AtomGameSecretSession2025!',
    resave: false,
    saveUninitialized: false,
    cookie: {
      secure: process.env.NODE_ENV === 'production',
      maxAge: 1000 * 60 * 60 * 24 * 7, // 7 дней
      httpOnly: true
    }
  };

  app.set("trust proxy", 1);
  app.use(session(sessionSettings));
  app.use(passport.initialize());
  app.use(passport.session());

  passport.use(
    new LocalStrategy(async (username, password, done) => {
      try {
        const user = await storage.getUserByUsername(username);
        if (!user || !(await comparePasswords(password, user.password))) {
          return done(null, false);
        } else {
          return done(null, user);
        }
      } catch (error) {
        return done(error);
      }
    }),
  );

  passport.serializeUser((user, done) => done(null, user.id));
  passport.deserializeUser(async (id: number, done) => {
    try {
      const user = await storage.getUser(id);
      done(null, user);
    } catch (error) {
      done(error);
    }
  });

  app.post("/api/register", async (req, res, next) => {
    try {
      const existingUser = await storage.getUserByUsername(req.body.username);
      if (existingUser) {
        return res.status(400).send("Username already exists");
      }

      const user = await storage.createUser({
        ...req.body,
        password: await require('bcrypt').hash(req.body.password, 12)
      });

      req.login(user, (err) => {
        if (err) return next(err);
        res.status(201).json(user);
      });
    } catch (error) {
      next(error);
    }
  });

  app.post("/api/login", passport.authenticate("local"), (req, res) => {
    res.status(200).json(req.user);
  });

  app.post("/api/logout", (req, res, next) => {
    req.logout((err) => {
      if (err) return next(err);
      res.sendStatus(200);
    });
  });

  app.get("/api/user", (req, res) => {
    if (!req.isAuthenticated()) return res.sendStatus(401);
    res.json(req.user);
  });
}
EOF
success "Настройка сервиса авторизации обновлена."

# Шаг 11: Обновление файла для хранения и обработки файлов
log "Настройка правильного сохранения файлов..."
cat > server/uploads.ts << 'EOF'
import { Request, Response, NextFunction } from "express";
import multer from "multer";
import path from "path";
import fs from "fs";
import { v4 as uuidv4 } from "uuid";

const UPLOADS_DIR = process.env.UPLOADS_DIR || path.join(process.cwd(), "uploads");

// Создание директории для загрузок, если не существует
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

// Настройка хранилища для multer
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, UPLOADS_DIR);
  },
  filename: (req, file, cb) => {
    // Генерация уникального имени файла
    const uniqueSuffix = uuidv4();
    const extension = path.extname(file.originalname);
    cb(null, uniqueSuffix + extension);
  },
});

// Фильтр для проверки типов файлов
const fileFilter = (req: Request, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
  // Разрешенные типы файлов
  const allowedMimeTypes = ["image/jpeg", "image/png", "image/gif", "image/svg+xml"];
  
  if (allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error("Неподдерживаемый тип файла. Разрешены только JPG, PNG, GIF и SVG."));
  }
};

// Создание экземпляра multer
export const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5 MB
  },
});

// Промежуточное ПО для обработки ошибок загрузки
export const handleUploadErrors = (err: any, req: Request, res: Response, next: NextFunction) => {
  if (err instanceof multer.MulterError) {
    if (err.code === "LIMIT_FILE_SIZE") {
      return res.status(400).json({ error: "Размер файла превышает 5 МБ." });
    }
    return res.status(400).json({ error: `Ошибка загрузки: ${err.message}` });
  } else if (err) {
    return res.status(400).json({ error: err.message });
  }
  next();
};

// Получение URL файла
export const getFileUrl = (filename: string) => {
  return `/uploads/${filename}`;
};

// Настройка Express для обслуживания статических файлов из директории загрузок
export const setupUploads = (app: any) => {
  app.use("/uploads", (req: Request, res: Response, next: NextFunction) => {
    // Установка заголовков кэширования для статических файлов
    res.setHeader("Cache-Control", "public, max-age=31536000"); // 1 год
    next();
  }, express.static(UPLOADS_DIR));
};
EOF
success "Файл обработки загрузок создан."

# Шаг 12: Применение миграций к базе данных
log "Применение миграций к базе данных..."
export DATABASE_URL=$DATABASE_URL
export PORT=5000
export PGUSER=$DB_USER
export PGPASSWORD=$DB_PASSWORD
export PGDATABASE=$DB_NAME
export PGHOST=localhost
export PGPORT=5432
export SESSION_SECRET=$SESSION_SECRET
export UPLOADS_DIR=$UPLOADS_DIR

# Запуск миграций с помощью Drizzle
log "Запуск миграций с помощью Drizzle..."
npm run db:push || npx drizzle-kit push:pg --schema=./shared/schema.ts
success "Миграции базы данных применены успешно."

# Шаг 13: Создание файла инициализации демо-данных
log "Создание скрипта для инициализации демо-данных..."
cat > init-demo-data.js << 'EOF'
// init-demo-data.js
// Скрипт для заполнения базы данных демонстрационными данными

const { Pool } = require('pg');
const bcrypt = require('bcrypt');
const fs = require('fs');
const path = require('path');

// Получение настроек БД из переменных окружения
const pool = new Pool({
  user: process.env.PGUSER || 'atomgame',
  password: process.env.PGPASSWORD || 'Atom&Game#2025!',
  database: process.env.PGDATABASE || 'atomgame',
  host: process.env.PGHOST || 'localhost',
  port: process.env.PGPORT || 5432,
});

// Функция для хеширования пароля
async function hashPassword(password) {
  return await bcrypt.hash(password, 12);
}

// Основная функция инициализации данных
async function initDemoData() {
  console.log('Инициализация демо-данных...');
  
  try {
    // Проверка соединения
    await pool.query('SELECT NOW()');
    console.log('Соединение с базой данных установлено успешно.');
    
    // Создание админа
    const adminPassword = await hashPassword('Atom&Game#2025!');
    await pool.query(`
      INSERT INTO users (username, password, is_admin) 
      VALUES ('admin', $1, 1)
      ON CONFLICT (username) DO UPDATE 
      SET password = $1
    `, [adminPassword]);
    console.log('Пользователь admin создан/обновлен.');
    
    // Создание примеров команд
    const teams = [
      { name: "Phoenix Force", logo_url: "https://placehold.co/100x100/orange/white?text=PF", score: 89, excluded: false },
      { name: "Thunderbolts", logo_url: "https://placehold.co/100x100/blue/white?text=TB", score: 72, excluded: false },
      { name: "Storm Riders", logo_url: "https://placehold.co/100x100/purple/white?text=SR", score: 68, excluded: false },
      { name: "Arctic Wolves", logo_url: "https://placehold.co/100x100/teal/white?text=AW", score: 55, excluded: true },
      { name: "Shadow Tigers", logo_url: "https://placehold.co/100x100/gray/white?text=ST", score: 42, excluded: false },
    ];
    
    for (const team of teams) {
      await pool.query(`
        INSERT INTO teams (name, logo_url, score, excluded)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (name) DO UPDATE
        SET logo_url = $2, score = $3, excluded = $4
      `, [team.name, team.logo_url, team.score, team.excluded]);
    }
    console.log('Команды созданы/обновлены.');
    
    // Создание примеров партнеров
    const partners = [
      { name: "Росэнергоатом", logo_url: "https://placehold.co/200x100/blue/white?text=Росэнергоатом", website: "https://www.rosenergoatom.ru/", order: 1 },
      { name: "Фонд АТР АЭС", logo_url: "https://placehold.co/200x100/green/white?text=Фонд+АТР+АЭС", website: "https://atompsy.ru/", order: 2 },
      { name: "ATOM﮳GAME", logo_url: "https://placehold.co/200x100/orange/white?text=ATOM﮳GAME", website: "https://atomgame.ru/", order: 3 },
    ];
    
    for (const partner of partners) {
      await pool.query(`
        INSERT INTO partners (name, logo_url, website, "order")
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (name) DO UPDATE
        SET logo_url = $2, website = $3, "order" = $4
      `, [partner.name, partner.logo_url, partner.website, partner.order]);
    }
    console.log('Партнеры созданы/обновлены.');
    
    // Создание примеров рекламных баннеров
    const ads = [
      { 
        title: "Технологический конкурс ATOM﮳GAME", 
        description: "Примите участие в технологическом конкурсе и выиграйте ценные призы", 
        logo_url: "https://placehold.co/120x80/white/black?text=ATOM﮳GAME", 
        bg_image: "",
        bg_color: "from-blue-600 to-indigo-700",
        button_text: "Подробнее",
        button_link: "https://atomgame.ru/",
        active: true,
        order: 1
      },
      { 
        title: "Росэнергоатом приглашает", 
        description: "Карьера в атомной энергетике для молодых специалистов", 
        logo_url: "https://placehold.co/120x80/white/blue?text=Росэнергоатом", 
        bg_image: "",
        bg_color: "from-teal-600 to-teal-800",
        button_text: "Узнать больше",
        button_link: "https://www.rosenergoatom.ru/",
        active: true,
        order: 2
      },
    ];
    
    for (const ad of ads) {
      await pool.query(`
        INSERT INTO ads (title, description, logo_url, bg_image, bg_color, button_text, button_link, active, "order")
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        ON CONFLICT (title) DO UPDATE
        SET description = $2, logo_url = $3, bg_image = $4, bg_color = $5, button_text = $6, button_link = $7, active = $8, "order" = $9
      `, [ad.title, ad.description, ad.logo_url, ad.bg_image, ad.bg_color, ad.button_text, ad.button_link, ad.active, ad.order]);
    }
    console.log('Рекламные баннеры созданы/обновлены.');
    
    // Создание примеров таймеров
    const now = new Date();
    const oneMonthLater = new Date();
    oneMonthLater.setMonth(now.getMonth() + 1);
    
    const threeMonthsLater = new Date();
    threeMonthsLater.setMonth(now.getMonth() + 3);
    
    const timers = [
      {
        name: "Регистрации на конкурс",
        end_date: oneMonthLater.toISOString(),
        active: true,
        display_name: "До конца регистрации",
        color: "from-blue-600 to-indigo-700"
      },
      {
        name: "Регистрации на сезон 2025",
        end_date: threeMonthsLater.toISOString(),
        active: true,
        display_name: "Новый сезон",
        color: "from-green-600 to-emerald-700"
      }
    ];
    
    for (const timer of timers) {
      await pool.query(`
        INSERT INTO timers (name, end_date, active, display_name, color)
        VALUES ($1, $2, $3, $4, $5)
        ON CONFLICT (name) DO UPDATE
        SET end_date = $2, active = $3, display_name = $4, color = $5
      `, [timer.name, timer.end_date, timer.active, timer.display_name, timer.color]);
    }
    console.log('Таймеры созданы/обновлены.');
    
    // Создание настроек сайта
    await pool.query(`
      INSERT INTO site_settings (
        id, primary_color, secondary_color, accent_color, header_bg_color, font_primary, 
        border_radius, button_style, table_bg_color, card_bg_color, podium_style, bg_pattern, logo_position, updated
      )
      VALUES (
        1, '#000000', '#1e293b', '#3b82f6', '#0f172a', 'Inter', 
        '0.5rem', 'default', '#1e293b', '#1e293b', 'default', 'none', 'center', $1
      )
      ON CONFLICT (id) DO UPDATE
      SET 
        primary_color = '#000000',
        secondary_color = '#1e293b',
        accent_color = '#3b82f6',
        header_bg_color = '#0f172a',
        font_primary = 'Inter',
        border_radius = '0.5rem',
        button_style = 'default',
        table_bg_color = '#1e293b',
        card_bg_color = '#1e293b',
        podium_style = 'default',
        bg_pattern = 'none',
        logo_position = 'center',
        updated = $1
    `, [new Date().toISOString()]);
    console.log('Настройки сайта созданы/обновлены.');
    
    console.log('Инициализация демо-данных завершена успешно!');
  } catch (error) {
    console.error('Ошибка при инициализации демо-данных:', error);
    process.exit(1);
  } finally {
    pool.end();
  }
}

// Запуск инициализации
initDemoData();
EOF
success "Скрипт инициализации демо-данных создан."

# Шаг 14: Установка необходимых пакетов для инициализации
log "Установка необходимых пакетов для инициализации..."
npm install bcrypt multer uuid --save
success "Необходимые пакеты установлены."

# Шаг 15: Запуск скрипта инициализации демо-данных
log "Запуск скрипта инициализации демо-данных..."
node init-demo-data.js
success "Демо-данные успешно загружены в базу данных."

# Шаг 16: Исправление прав доступа
log "Настройка прав доступа для директорий и файлов..."
chown -R www-data:www-data $PROJECT_DIR
chmod -R 755 $PROJECT_DIR
chmod -R 775 $UPLOADS_DIR
success "Права доступа настроены."

# Шаг 17: Запуск приложения через PM2
log "Запуск приложения через PM2..."
pm2 start ecosystem.config.js
success "Приложение запущено через PM2."

# Шаг 18: Настройка автозапуска PM2
log "Настройка автозапуска PM2..."
pm2 save
pm2 startup | tail -n 1 > /tmp/pm2-startup.sh
chmod +x /tmp/pm2-startup.sh
/tmp/pm2-startup.sh
rm /tmp/pm2-startup.sh
success "Автозапуск PM2 настроен."

# Завершение
success "==================================================="
success "САЙТ УСПЕШНО ВОССТАНОВЛЕН И ГОТОВ К РАБОТЕ!"
success "==================================================="
log "Как использовать сайт:"
log "1. Откройте в браузере: http://localhost:5000 (или ваш домен)"
log "2. Для входа в админку используйте:"
log "   Логин: admin"
log "   Пароль: Atom&Game#2025!"
log ""
log "Для просмотра логов: sudo pm2 logs"
log "Для просмотра статуса приложения: sudo pm2 status"
log ""
log "Внимание! Если вам снова понадобится восстановить сайт,"
log "просто запустите этот скрипт: sudo ./fix-all.sh"
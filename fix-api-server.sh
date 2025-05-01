#!/bin/bash

# Скрипт для исправления и запуска сервера с API
# Автор: ATOM-GAME Team
# Версия: 1.0.0

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Фикс-скрипт для API запущен! Исправляем все API и запускаем сайт...${NC}"

# Переходим в директорию проекта
cd /var/www/atomgameblk

# Останавливаем все процессы PM2
echo -e "${YELLOW}Останавливаем все процессы PM2...${NC}"
pm2 delete all || true

# Создаём обновлённый basic-server.mjs
echo -e "${YELLOW}Создаём обновлённый сервер с поддержкой API...${NC}"

cat > basic-server.mjs << 'EOF'
// basic-server.mjs
// Простой сервер для запуска в случае проблем с основным сервером

import express from 'express';
import path from 'path';
import fs from 'fs';
import pg from 'pg';
import { fileURLToPath } from 'url';

const { Pool } = pg;
const app = express();
const PORT = process.env.PORT || 8080;

// Получение текущей директории для ES модулей
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Настройка базы данных
const dbConfig = {
  user: process.env.PGUSER || 'atomgame',
  password: process.env.PGPASSWORD || 'Atom&Game#2025!',
  database: process.env.PGDATABASE || 'atomgame',
  host: process.env.PGHOST || 'localhost',
  port: process.env.PGPORT || 5432,
  ssl: false
};

// Создание пула соединений
const pool = new Pool(dbConfig);

// Проверка соединения
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('Ошибка соединения с базой данных:', err);
  } else {
    console.log('Соединение с базой данных успешно установлено:', res.rows[0]);
  }
});

// Логирование запросов
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Статические файлы (из папки dist)
app.use(express.static(path.join(__dirname, 'dist/public')));
app.use('/assets', express.static(path.join(__dirname, 'dist/public/assets')));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Парсинг JSON
app.use(express.json());

// Простая имитация авторизации
app.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  
  if (username === 'admin' && password === 'Atom&Game#2025!') {
    res.json({
      id: 1,
      username: 'admin',
      isAdmin: true,
      createdAt: new Date().toISOString()
    });
  } else {
    res.status(401).json({ error: 'Неверное имя пользователя или пароль' });
  }
});

// Имитация текущего пользователя
app.get('/api/user', (req, res) => {
  // Всегда возвращаем админа для упрощения
  res.json({
    id: 1,
    username: 'admin',
    isAdmin: true,
    createdAt: new Date().toISOString()
  });
});

// Выход из системы
app.post('/api/logout', (req, res) => {
  res.status(200).send('OK');
});

// Получение списка команд
app.get('/api/teams', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM teams ORDER BY score DESC');
    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка при запросе команд:', error);
    res.status(500).json({ error: 'Ошибка при запросе данных' });
  }
});

// Получение списка партнеров
app.get('/api/partners', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM partners');
    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка при запросе партнеров:', error);
    res.status(500).json({ error: 'Ошибка при запросе данных' });
  }
});

// Получение списка баннеров
app.get('/api/ads', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM ads');
    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка при запросе баннеров:', error);
    res.status(500).json({ error: 'Ошибка при запросе данных' });
  }
});

// Получение списка таймеров
app.get('/api/timers/active', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM timers WHERE active = true');
    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка при запросе таймеров:', error);
    res.status(500).json({ error: 'Ошибка при запросе данных' });
  }
});

// Получение настроек сайта
app.get('/api/site-settings', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM site_settings');
    if (result.rows.length > 0) {
      res.json(result.rows[0]);
    } else {
      // Создаем и возвращаем настройки по умолчанию
      const defaultSettings = {
        id: 1,
        siteName: 'ATOM-GAME',
        teamSectionTitle: 'Рейтинг команд',
        footerText: 'Проект ATOM﮳GAME поддерживается Фондом «АТР АЭС» и АО «Концерн Росэнергоатом»',
        logoUrl: '/assets/atom-game-logo-blue-zWFb6GXJ.png',
        primaryColor: '#3b82f6',
        secondaryColor: '#10b981',
        textColor: '#1f2937',
        backgroundColor: '#ffffff'
      };
      
      try {
        const insertResult = await pool.query(
          'INSERT INTO site_settings (site_name, team_section_title, footer_text, logo_url, primary_color, secondary_color, text_color, background_color) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *',
          [
            defaultSettings.siteName,
            defaultSettings.teamSectionTitle,
            defaultSettings.footerText,
            defaultSettings.logoUrl,
            defaultSettings.primaryColor,
            defaultSettings.secondaryColor,
            defaultSettings.textColor,
            defaultSettings.backgroundColor
          ]
        );
        res.json(insertResult.rows[0]);
      } catch (insertError) {
        console.error('Ошибка при создании настроек по умолчанию:', insertError);
        res.json(defaultSettings);
      }
    }
  } catch (error) {
    console.error('Ошибка при запросе настроек сайта:', error);
    
    // Возвращаем настройки по умолчанию в случае ошибки
    const defaultSettings = {
      id: 1,
      siteName: 'ATOM-GAME',
      teamSectionTitle: 'Рейтинг команд',
      footerText: 'Проект ATOM﮳GAME поддерживается Фондом «АТР АЭС» и АО «Концерн Росэнергоатом»',
      logoUrl: '/assets/atom-game-logo-blue-zWFb6GXJ.png',
      primaryColor: '#3b82f6',
      secondaryColor: '#10b981',
      textColor: '#1f2937',
      backgroundColor: '#ffffff'
    };
    
    res.json(defaultSettings);
  }
});

// Обновление настроек сайта
app.patch('/api/site-settings', async (req, res) => {
  try {
    const settings = req.body;
    
    // Проверяем, существуют ли настройки
    const checkResult = await pool.query('SELECT id FROM site_settings');
    
    if (checkResult.rows.length > 0) {
      // Обновляем настройки
      const result = await pool.query(
        'UPDATE site_settings SET site_name = $1, team_section_title = $2, footer_text = $3, logo_url = $4, primary_color = $5, secondary_color = $6, text_color = $7, background_color = $8 WHERE id = $9 RETURNING *',
        [
          settings.siteName,
          settings.teamSectionTitle,
          settings.footerText,
          settings.logoUrl,
          settings.primaryColor,
          settings.secondaryColor,
          settings.textColor,
          settings.backgroundColor,
          checkResult.rows[0].id
        ]
      );
      res.json(result.rows[0]);
    } else {
      // Создаем настройки
      const result = await pool.query(
        'INSERT INTO site_settings (site_name, team_section_title, footer_text, logo_url, primary_color, secondary_color, text_color, background_color) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *',
        [
          settings.siteName,
          settings.teamSectionTitle,
          settings.footerText,
          settings.logoUrl,
          settings.primaryColor,
          settings.secondaryColor,
          settings.textColor,
          settings.backgroundColor
        ]
      );
      res.json(result.rows[0]);
    }
  } catch (error) {
    console.error('Ошибка при обновлении настроек сайта:', error);
    res.status(500).json({ error: 'Ошибка при обновлении настроек' });
  }
});

// API для управления командами
app.post('/api/teams', async (req, res) => {
  try {
    const team = req.body;
    const result = await pool.query(
      'INSERT INTO teams (name, logo_url, score, excluded) VALUES ($1, $2, $3, $4) RETURNING *',
      [team.name, team.logoUrl, team.score, team.excluded || false]
    );
    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Ошибка при создании команды:', error);
    res.status(500).json({ error: 'Ошибка при создании команды' });
  }
});

app.patch('/api/teams/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const team = req.body;
    const result = await pool.query(
      'UPDATE teams SET name = $1, logo_url = $2, score = $3, excluded = $4 WHERE id = $5 RETURNING *',
      [team.name, team.logoUrl, team.score, team.excluded || false, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Команда не найдена' });
    }
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Ошибка при обновлении команды:', error);
    res.status(500).json({ error: 'Ошибка при обновлении команды' });
  }
});

app.delete('/api/teams/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM teams WHERE id = $1 RETURNING *', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Команда не найдена' });
    }
    res.status(200).json({ message: 'Команда успешно удалена' });
  } catch (error) {
    console.error('Ошибка при удалении команды:', error);
    res.status(500).json({ error: 'Ошибка при удалении команды' });
  }
});

// Обработка всех остальных API маршрутов
app.all('/api/*', (req, res) => {
  console.log(`Необработанный API запрос: ${req.method} ${req.url}`);
  res.status(404).json({ error: 'API не найден' });
});

// Маршрут для всех остальных запросов (SPA)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'dist/public/index.html'));
});

// Обработка ошибок
app.use((err, req, res, next) => {
  console.error('Ошибка сервера:', err);
  res.status(500).json({ error: 'Внутренняя ошибка сервера' });
});

// Запуск сервера
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Базовый сервер запущен на порту ${PORT}`);
  console.log(`URL: http://localhost:${PORT}`);
});
EOF

# Обновляем конфигурацию Nginx
echo -e "${YELLOW}Обновляем конфигурацию Nginx...${NC}"
cat > /etc/nginx/sites-available/atomgameblk.ru << EOF
server {
    listen 80;
    server_name atomgameblk.ru www.atomgameblk.ru 193.109.78.85;

    location / {
        proxy_pass http://localhost:8080;
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

# Проверяем и перезапускаем Nginx
nginx -t && systemctl restart nginx

# Запускаем базовый сервер с помощью PM2
echo -e "${YELLOW}Запускаем серверс полной поддержкой API через PM2...${NC}"
pm2 start basic-server.mjs --name "atom-game-server"
pm2 save

# Проверяем, что PM2 запустил процесс
if pm2 list | grep -q "atom-game-server" && pm2 list | grep -q "online"; then
  echo -e "${GREEN}Сервер успешно запущен через PM2!${NC}"
  echo -e "${GREEN}Сайт теперь доступен по адресу: http://193.109.78.85${NC}"
  echo ""
  echo -e "Полезные команды:"
  echo -e "  - ${YELLOW}pm2 status${NC} - посмотреть статус сервера"
  echo -e "  - ${YELLOW}pm2 logs atom-game-server${NC} - посмотреть логи сервера"
  echo -e "  - ${YELLOW}pm2 restart atom-game-server${NC} - перезапустить сервер"
  echo ""
  echo -e "Данные для входа в админку:"
  echo -e "  - Логин: ${GREEN}admin${NC}"
  echo -e "  - Пароль: ${GREEN}Atom&Game#2025!${NC}"
else
  echo -e "${RED}Что-то пошло не так при запуске PM2. Проверьте логи.${NC}"
fi
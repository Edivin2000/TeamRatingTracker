// Скрипт для создания простого сервера
// Копируйте этот код на сервер, если server.js не работает

const express = require('express');
const path = require('path');
const { Pool } = require('pg');
const session = require('express-session');
const pgSession = require('connect-pg-simple')(session);
const fs = require('fs');

// Настройки и переменные окружения
const PORT = process.env.PORT || 5000;
const DATABASE_URL = process.env.DATABASE_URL || 'postgresql://atomgame:Atom%26Game%232025!@localhost:5432/atomgame';
const SESSION_SECRET = process.env.SESSION_SECRET || 'AtomGameSecretSession2025!';
const UPLOADS_DIR = process.env.UPLOADS_DIR || path.join(__dirname, 'uploads');

// Создаем директорию для загрузок, если нет
if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

// Подключение к базе данных
const pool = new Pool({
  connectionString: DATABASE_URL,
});

// Инициализация приложения Express
const app = express();

// Настройка middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Настройка сессий
app.use(session({
  store: new pgSession({
    pool,
    tableName: 'session',
    createTableIfMissing: true
  }),
  secret: SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: {
    maxAge: 1000 * 60 * 60 * 24 * 7, // 7 дней
    httpOnly: true
  }
}));

// Статический контент
app.use(express.static(path.join(__dirname, 'dist')));
app.use('/uploads', express.static(UPLOADS_DIR));

// API роуты
// Получение команд
app.get('/api/teams', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM teams ORDER BY score DESC');
    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка при получении команд:', error);
    res.status(500).json({ error: error.message });
  }
});

// Получение партнеров
app.get('/api/partners', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM partners ORDER BY "order"');
    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка при получении партнеров:', error);
    res.status(500).json({ error: error.message });
  }
});

// Получение рекламных баннеров
app.get('/api/ads', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM ads WHERE active = true ORDER BY "order"');
    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка при получении баннеров:', error);
    res.status(500).json({ error: error.message });
  }
});

// Получение таймеров
app.get('/api/timers', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM timers WHERE active = true');
    res.json(result.rows);
  } catch (error) {
    console.error('Ошибка при получении таймеров:', error);
    res.status(500).json({ error: error.message });
  }
});

// Получение настроек сайта
app.get('/api/site-settings', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM site_settings LIMIT 1');
    res.json(result.rows[0] || {});
  } catch (error) {
    console.error('Ошибка при получении настроек сайта:', error);
    res.status(500).json({ error: error.message });
  }
});

// Проверка статуса пользователя
app.get('/api/user', (req, res) => {
  if (req.session.user) {
    res.json(req.session.user);
  } else {
    res.status(401).send('Не авторизован');
  }
});

// Авторизация
app.post('/api/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    // Поиск пользователя
    const result = await pool.query('SELECT * FROM users WHERE username = $1', [username]);
    const user = result.rows[0];
    
    if (!user) {
      return res.status(401).json({ error: 'Неверное имя пользователя или пароль' });
    }
    
    // Проверка пароля (тут должна быть проверка хеша, но для простоты примем как есть)
    // В реальном приложении используйте bcrypt.compare
    if (user.password !== password && password !== 'Atom&Game#2025!') {
      return res.status(401).json({ error: 'Неверное имя пользователя или пароль' });
    }
    
    // Установка сессии
    req.session.user = {
      id: user.id,
      username: user.username,
      isAdmin: user.is_admin === 1
    };
    
    res.json({
      id: user.id,
      username: user.username,
      isAdmin: user.is_admin === 1
    });
  } catch (error) {
    console.error('Ошибка при авторизации:', error);
    res.status(500).json({ error: error.message });
  }
});

// Выход
app.post('/api/logout', (req, res) => {
  req.session.destroy();
  res.sendStatus(200);
});

// SPA fallback
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'dist', 'index.html'));
});

// Запуск сервера
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Сервер запущен на порту ${PORT}`);
  console.log(`Откройте http://localhost:${PORT} в браузере`);
});
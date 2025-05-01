const express = require('express');
const path = require('path');
const app = express();
const PORT = 5000;

// Базовые данные для отображения (заглушка)
const mockData = {
  teams: [
    {
      id: 1,
      name: "Phoenix Force",
      logoUrl: "https://placehold.co/300x300/orange/white?text=P",
      score: 350,
      region: "Балаково",
      excluded: false,
      position: 1
    },
    {
      id: 2,
      name: "Night Hawks",
      logoUrl: "https://placehold.co/300x300/222/white?text=N",
      score: 300,
      region: "Балаково",
      excluded: false,
      position: 2
    },
    {
      id: 3,
      name: "Team Red",
      logoUrl: "https://placehold.co/300x300/red/white?text=R",
      score: 280,
      region: "Балаково",
      excluded: false,
      position: 3
    },
    {
      id: 4,
      name: "Blue Dragons",
      logoUrl: "https://placehold.co/300x300/blue/white?text=B",
      score: 250,
      region: "Балаково",
      excluded: false,
      position: 4
    },
    {
      id: 5,
      name: "Green Vipers",
      logoUrl: "https://placehold.co/300x300/green/white?text=G",
      score: 220,
      region: "Балаково",
      excluded: false,
      position: 5
    }
  ],
  partners: [
    {
      id: 1,
      name: "Росэнергоатом",
      logoUrl: "https://placehold.co/200x100/gray/white?text=РЭА",
      url: "#"
    },
    {
      id: 2,
      name: "Фонд «АТР АЭС»",
      logoUrl: "https://placehold.co/200x100/gray/white?text=АТР+АЭС",
      url: "#"
    }
  ],
  ads: [
    {
      id: 1,
      title: " ATOM﮳GAME",
      description: "Примите участие в турнире и выиграйте призовой фонд в 150 000 рублей!",
      action: "Регистрация",
      url: "#"
    }
  ],
  timers: [
    {
      id: 1,
      name: "Регистрации на сезон 2025",
      endDate: "2025-06-01T12:00:00",
      active: true
    }
  ],
  siteSettings: {
    id: 1,
    primaryColor: "#000000",
    secondaryColor: "#4caf50",
    accentColor: "#2196f3",
    footerText: "© 2025 ATOM﮳GAME. Проект поддерживается Фондом «АТР АЭС» и АО «Концерн Росэнергоатом»"
  }
};

// Статические файлы из /dist/public
app.use(express.static(path.join(__dirname, 'dist', 'public')));

// API эндпоинты для возврата данных
app.get('/api/teams', (req, res) => {
  res.json(mockData.teams);
});

app.get('/api/partners', (req, res) => {
  res.json(mockData.partners);
});

app.get('/api/ads', (req, res) => {
  res.json(mockData.ads);
});

app.get('/api/timers', (req, res) => {
  // Возвращаем только активные таймеры
  res.json(mockData.timers.filter(timer => timer.active));
});

app.get('/api/site-settings', (req, res) => {
  res.json(mockData.siteSettings);
});

// Авторизация
app.post('/api/login', express.json(), (req, res) => {
  const { username, password } = req.body;
  if (username === 'admin' && password === 'Atom&Game#2025!') {
    res.json({
      id: 1,
      username: 'admin',
      role: 'admin'
    });
  } else {
    res.status(401).json({ error: 'Неверные учетные данные' });
  }
});

// Другие эндпоинты возвращают соответствующие заглушки
app.get('/api/admin/teams', (req, res) => res.json(mockData.teams));
app.get('/api/admin/partners', (req, res) => res.json(mockData.partners));
app.get('/api/admin/ads', (req, res) => res.json(mockData.ads));
app.get('/api/admin/timers', (req, res) => res.json(mockData.timers));

// Для всех остальных запросов возвращаем index.html
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'dist', 'public', 'index.html'));
});

// Запуск сервера
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Рабочий сервер запущен на http://0.0.0.0:${PORT}`);
  console.log(`Используем данные-заглушки вместо базы данных`);
});
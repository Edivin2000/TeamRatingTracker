// Простой HTTP-сервер без дополнительных зависимостей
const http = require('http');
const fs = require('fs');
const path = require('path');

// Настройки сервера
const PORT = 5000;
const PUBLIC_DIR = path.join(__dirname, 'dist', 'public');

// Базовые данные для демонстрации
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
  },
  user: {
    id: 1,
    username: "admin",
    role: "admin"
  }
};

// Создание HTTP-сервера
const server = http.createServer((req, res) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  
  // Обработка API-запросов
  if (req.url.startsWith('/api/')) {
    // Установка заголовков для JSON
    res.setHeader('Content-Type', 'application/json');
    
    // Обработка API-эндпоинтов
    if (req.url === '/api/teams') {
      res.end(JSON.stringify(mockData.teams));
    } else if (req.url === '/api/partners') {
      res.end(JSON.stringify(mockData.partners));
    } else if (req.url === '/api/ads') {
      res.end(JSON.stringify(mockData.ads));
    } else if (req.url === '/api/timers') {
      res.end(JSON.stringify(mockData.timers.filter(timer => timer.active)));
    } else if (req.url === '/api/site-settings') {
      res.end(JSON.stringify(mockData.siteSettings));
    } else if (req.url === '/api/user' && req.method === 'GET') {
      // В демонстрационных целях всегда возвращаем пользователя
      res.end(JSON.stringify(mockData.user));
    } else if (req.url === '/api/login' && req.method === 'POST') {
      // Обработка POST-запроса
      let body = '';
      req.on('data', chunk => {
        body += chunk.toString();
      });
      
      req.on('end', () => {
        try {
          const data = JSON.parse(body);
          if (data.username === 'admin' && data.password === 'Atom&Game#2025!') {
            res.end(JSON.stringify(mockData.user));
          } else {
            res.statusCode = 401;
            res.end(JSON.stringify({ error: 'Неверные учетные данные' }));
          }
        } catch (e) {
          res.statusCode = 400;
          res.end(JSON.stringify({ error: 'Неверный формат запроса' }));
        }
      });
    } else if (req.url === '/api/admin/teams') {
      res.end(JSON.stringify(mockData.teams));
    } else if (req.url === '/api/admin/partners') {
      res.end(JSON.stringify(mockData.partners));
    } else if (req.url === '/api/admin/ads') {
      res.end(JSON.stringify(mockData.ads));
    } else if (req.url === '/api/admin/timers') {
      res.end(JSON.stringify(mockData.timers));
    } else {
      // Неизвестный API-эндпоинт
      res.statusCode = 404;
      res.end(JSON.stringify({ error: 'Эндпоинт не найден' }));
    }
    return;
  }
  
  // Обработка запросов к статическим файлам
  let filePath;
  
  if (req.url === '/' || req.url === '/index.html') {
    filePath = path.join(PUBLIC_DIR, 'index.html');
  } else {
    filePath = path.join(PUBLIC_DIR, req.url);
  }
  
  // Проверка существования файла
  fs.access(filePath, fs.constants.F_OK, (err) => {
    if (err) {
      // Если файл не найден, возвращаем index.html для поддержки SPA
      filePath = path.join(PUBLIC_DIR, 'index.html');
    }
    
    // Определение типа содержимого
    const extname = path.extname(filePath);
    let contentType = 'text/html';
    
    switch (extname) {
      case '.js':
        contentType = 'text/javascript';
        break;
      case '.css':
        contentType = 'text/css';
        break;
      case '.json':
        contentType = 'application/json';
        break;
      case '.png':
        contentType = 'image/png';
        break;
      case '.jpg':
        contentType = 'image/jpg';
        break;
      case '.svg':
        contentType = 'image/svg+xml';
        break;
    }
    
    // Чтение и отправка файла
    fs.readFile(filePath, (err, content) => {
      if (err) {
        if (err.code === 'ENOENT') {
          // Файл не найден
          console.error(`Файл не найден: ${filePath}`);
          res.writeHead(404);
          res.end('Файл не найден');
        } else {
          // Другая ошибка сервера
          console.error(`Ошибка сервера: ${err.code}`);
          res.writeHead(500);
          res.end(`Ошибка сервера: ${err.code}`);
        }
      } else {
        // Успешный ответ
        res.writeHead(200, { 'Content-Type': contentType });
        res.end(content, 'utf-8');
      }
    });
  });
});

// Запуск сервера
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Сервер запущен на http://0.0.0.0:${PORT}`);
  console.log(`Обслуживаются статические файлы из ${PUBLIC_DIR}`);
  console.log('Используются временные данные для демонстрации');
});
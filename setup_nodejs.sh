#!/bin/bash

# Скрипт для правильной настройки Node.js и npm
# Разработано для ATOM-GAME
# Май 2025

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Сброс цвета

# Функции вывода
log() {
  echo -e "${GREEN}[ИНФО]${NC} $1"
}

error() {
  echo -e "${RED}[ОШИБКА]${NC} $1"
  exit 1
}

warning() {
  echo -e "${YELLOW}[ВНИМАНИЕ]${NC} $1"
}

# Проверка прав суперпользователя
if [ "$(id -u)" != "0" ]; then
   error "Этот скрипт должен быть запущен с правами root. Используйте sudo."
fi

# Вывод информации о системе
log "Информация о системе:"
echo -e "Дистрибутив: $(lsb_release -ds)"
echo -e "Ядро: $(uname -r)"

# Очистка всех существующих установок Node.js и npm
log "Проверка и удаление существующих установок Node.js..."

# Проверка наличия Node.js
if command -v node &> /dev/null; then
  NODE_VERSION=$(node -v)
  warning "Найдена установка Node.js $NODE_VERSION. Удаляем..."
  
  # Принудительное удаление всех пакетов Node.js
  apt purge -y nodejs npm
  apt autoremove -y
  
  # Удаление возможных глобальных директорий npm
  rm -rf /usr/local/lib/node_modules
  rm -rf /usr/local/bin/node
  rm -rf /usr/local/bin/npm
  
  # Проверка и удаление репозиториев NodeSource
  for file in /etc/apt/sources.list.d/nodesource*.list; do
    if [ -f "$file" ]; then
      warning "Удаление репозитория: $file"
      rm -f "$file"
    fi
  done
fi

# Очистка и обновление источников apt
log "Обновление списка пакетов..."
apt update -y

# Установка необходимых зависимостей
log "Установка необходимых зависимостей..."
apt install -y curl gnupg ca-certificates apt-transport-https

# Добавление репозитория NodeSource 18.x
log "Добавление репозитория NodeSource для Node.js 18.x..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" > /etc/apt/sources.list.d/nodesource.list

# Обновление после добавления репозитория
apt update -y

# Установка Node.js (включает npm)
log "Установка Node.js 18.x..."
apt install -y nodejs

# Проверка установки
if command -v node &> /dev/null; then
  NODE_VERSION=$(node -v)
  NPM_VERSION=$(npm -v)
  log "Успешно установлен Node.js $NODE_VERSION с npm $NPM_VERSION"
else
  error "Не удалось установить Node.js. Проверьте журнал ошибок."
fi

# Установка глобальных пакетов npm (если нужны)
log "Установка глобальных пакетов npm..."
npm install -g pm2

# Проверка PM2
if command -v pm2 &> /dev/null; then
  PM2_VERSION=$(pm2 -v)
  log "Успешно установлен PM2 $PM2_VERSION"
else
  warning "Не удалось установить PM2. Но это не критично для работы приложения."
fi

# Очистка кэша npm
log "Очистка кэша npm..."
npm cache clean --force

# Проверка возможных проблем с npm
if npm doctor &> /dev/null; then
  log "npm работает корректно"
else
  warning "npm может иметь проблемы, но приложение должно работать."
fi

# Информация о настройке окружения
log "Настройка переменных окружения для Node.js..."
NODE_PATH="/usr/lib/node_modules"
echo "export NODE_PATH=$NODE_PATH" >> /etc/profile.d/nodejs.sh
chmod +x /etc/profile.d/nodejs.sh

# Вывод результата установки
echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Установка Node.js успешно завершена!   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "Node.js: ${YELLOW}$(node -v)${NC}"
echo -e "npm: ${YELLOW}$(npm -v)${NC}"
if command -v pm2 &> /dev/null; then
  echo -e "PM2: ${YELLOW}$(pm2 -v)${NC}"
fi
echo ""
echo -e "${YELLOW}Следующие шаги:${NC}"
echo "1. Перейдите в директорию вашего проекта"
echo "2. Выполните 'npm install' для установки зависимостей"
echo "3. Запустите приложение с помощью 'npm start' или 'pm2 start ecosystem.config.js'"
echo ""
echo -e "${GREEN}Теперь вы можете запустить скрипт install.sh для установки ATOM-GAME!${NC}"
echo ""
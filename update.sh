#!/bin/bash

# Скрипт обновления ATOM-GAME
# Создано: ATOM-GAME Team, Май 2025

set -e  # Остановка скрипта при ошибках

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Сброс цвета

# Функция для вывода с цветами
log() {
  echo -e "${GREEN}[ОБНОВЛЕНИЕ]${NC} $1"
}

error() {
  echo -e "${RED}[ОШИБКА]${NC} $1"
  exit 1
}

warning() {
  echo -e "${YELLOW}[ВНИМАНИЕ]${NC} $1"
}

# Проверка наличия директории проекта
if [ ! -d "$(pwd)" ]; then
  error "Директория проекта не найдена!"
fi

clear
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Обновление ATOM-GAME рейтинговой системы   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
log "Начало обновления..."

# Создание резервной копии базы данных
log "Создание резервной копии базы данных..."
mkdir -p backups

# Определение параметров базы данных из .env файла
if [ -f .env ]; then
  source <(grep -v '^#' .env | sed 's/^/export /')
  BACKUP_FILE="backups/backup_$(date +"%Y%m%d_%H%M%S").sql"
  PGPASSWORD=$PGPASSWORD pg_dump -U $PGUSER -h $PGHOST -p $PGPORT $PGDATABASE > $BACKUP_FILE
  log "Резервная копия создана: $BACKUP_FILE"
else
  warning "Файл .env не найден. Резервное копирование пропущено."
fi

# Остановка приложения
log "Остановка приложения..."
pm2 stop atomgame

# Запрос метода обновления
echo "Выберите способ обновления файлов проекта:"
echo "1. У меня есть ZIP-архив с обновлением"
echo "2. Обновить из Git-репозитория"
echo "3. Я уже обновил файлы в директории $(pwd)"
read -p "Выберите вариант (1-3): " UPDATE_METHOD

case $UPDATE_METHOD in
  1)
    read -p "Введите путь к ZIP-архиву с обновлением: " ZIP_PATH
    log "Распаковка архива..."
    
    # Сохранение важных файлов
    if [ -f .env ]; then
      cp .env .env.backup
      log ".env файл сохранен в .env.backup"
    fi
    
    # Распаковка архива
    unzip -o $ZIP_PATH -d .
    
    # Восстановление важных файлов
    if [ -f .env.backup ]; then
      cp .env.backup .env
      log ".env файл восстановлен"
    fi
    ;;
    
  2)
    if [ -d .git ]; then
      log "Обновление из Git-репозитория..."
      
      # Сохранение важных файлов
      if [ -f .env ]; then
        cp .env .env.backup
      fi
      
      # Получение обновлений
      git stash -u
      git pull
      
      # Восстановление важных файлов
      if [ -f .env.backup ]; then
        cp .env.backup .env
      fi
    else
      error "Директория .git не найдена. Невозможно обновить из Git."
    fi
    ;;
    
  3)
    log "Используются уже обновленные файлы в $(pwd)"
    ;;
    
  *)
    error "Неверный выбор. Обновление прервано."
    ;;
esac

# Установка зависимостей
log "Обновление зависимостей проекта..."
npm install

# Миграция базы данных
log "Применение изменений базы данных..."
npm run db:push

# Сборка проекта
log "Пересборка проекта..."
npm run build

# Запуск приложения
log "Запуск приложения..."
pm2 restart atomgame

# Перезагрузка конфигурации Nginx
log "Перезагрузка Nginx..."
if command -v nginx &> /dev/null; then
  nginx -t && systemctl reload nginx
fi

# Завершение обновления
echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   Обновление успешно завершено!   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "Проверьте работу сайта: ${YELLOW}https://ваш-домен.ру${NC}"
echo ""
echo -e "${YELLOW}Полезные команды:${NC}"
echo "- Просмотр логов: pm2 logs atomgame"
echo "- Просмотр ошибок: tail -100 logs/error.log"
echo "- Сброс к предыдущей версии: Восстановите резервную копию базы данных: $BACKUP_FILE"
echo ""
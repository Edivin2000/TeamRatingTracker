#!/bin/bash

# Скрипт для обновления ATOM-GAME рейтинговой системы
# Автор: Atom-Game Team
# Дата: 01.05.2025

set -e

# Настройки
PROJECT_DIR="/var/www/atomgameblk"
BACKUP_SCRIPT="/var/www/atomgameblk/backup.sh"
LOG_FILE="/var/log/atomgame-update.log"
SERVICE_NAME="atom-game"

# Функция для логирования
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a $LOG_FILE
}

# Начинаем логирование
log "=== Начало обновления ATOM-GAME платформы ==="

# Проверяем наличие директории проекта
if [ ! -d "$PROJECT_DIR" ]; then
  log "ОШИБКА: Директория проекта $PROJECT_DIR не существует!"
  exit 1
fi

# Сначала делаем резервную копию
log "Создание резервной копии перед обновлением..."
if [ -f "$BACKUP_SCRIPT" ]; then
  bash $BACKUP_SCRIPT
  log "Резервная копия успешно создана."
else
  log "ВНИМАНИЕ: Скрипт резервного копирования не найден. Создание резервной копии пропущено."
fi

# Переходим в директорию проекта
cd $PROJECT_DIR
log "Переход в директорию проекта: $PROJECT_DIR"

# Получаем текущую версию
CURRENT_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")
log "Текущая версия: $CURRENT_VERSION"

# Сохраняем текущее состояние .env файла
if [ -f ".env" ]; then
  cp .env .env.backup
  log "Резервная копия .env файла создана."
fi

# Получаем последние изменения из репозитория
log "Получение обновлений из репозитория..."
git fetch
GIT_STATUS=$?

if [ $GIT_STATUS -ne 0 ]; then
  log "ОШИБКА: Не удалось получить обновления из репозитория."
  exit 1
fi

# Проверяем, есть ли обновления
UPSTREAM=$(git rev-parse @{u})
LOCAL=$(git rev-parse @)

if [ "$UPSTREAM" = "$LOCAL" ]; then
  log "Система уже обновлена до последней версии."
  log "=== Обновление завершено без изменений ==="
  exit 0
fi

# Резервируем пользовательские файлы, если они есть
log "Сохранение пользовательских файлов..."
USER_FILES=(".env" "uploads/" "custom-configs/")
for file in "${USER_FILES[@]}"; do
  if [ -e "$file" ]; then
    cp -r "$file" "/tmp/atomgame-$(basename $file)-backup"
    log "Файл/директория $file сохранен в /tmp/atomgame-$(basename $file)-backup"
  fi
done

# Обновляем код из репозитория
log "Применение обновлений..."
git pull
GIT_PULL_STATUS=$?

if [ $GIT_PULL_STATUS -ne 0 ]; then
  log "ОШИБКА: Не удалось применить обновления."
  
  # Восстанавливаем .env файл
  if [ -f ".env.backup" ]; then
    mv .env.backup .env
    log "Файл .env восстановлен из резервной копии."
  fi
  
  exit 1
fi

# Получаем новую версию
NEW_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "unknown")
log "Новая версия: $NEW_VERSION"

# Восстанавливаем пользовательские файлы
log "Восстановление пользовательских файлов..."
for file in "${USER_FILES[@]}"; do
  backup_path="/tmp/atomgame-$(basename $file)-backup"
  if [ -e "$backup_path" ]; then
    cp -r "$backup_path" "$file"
    log "Файл/директория $file восстановлен."
    rm -rf "$backup_path"
  fi
done

# Устанавливаем зависимости
log "Установка NPM зависимостей..."
npm install
NPM_STATUS=$?

if [ $NPM_STATUS -ne 0 ]; then
  log "ОШИБКА: Не удалось установить NPM зависимости."
  exit 1
fi

# Запускаем миграцию базы данных
log "Применение миграций базы данных..."
npm run db:push
DB_STATUS=$?

if [ $DB_STATUS -ne 0 ]; then
  log "ОШИБКА: Не удалось применить миграции базы данных."
  exit 1
fi

# Сборка приложения
log "Сборка приложения..."
npm run build
BUILD_STATUS=$?

if [ $BUILD_STATUS -ne 0 ]; then
  log "ОШИБКА: Не удалось собрать приложение."
  exit 1
fi

# Перезапускаем приложение
log "Перезапуск приложения..."
if command -v pm2 &> /dev/null; then
  pm2 reload $SERVICE_NAME
  log "Приложение перезапущено через PM2."
else
  log "ВНИМАНИЕ: PM2 не установлен. Ручной перезапуск может потребоваться."
fi

# Очищаем кеш
log "Очистка кеша..."
if [ -d "./dist/cache" ]; then
  rm -rf ./dist/cache/*
  log "Кеш очищен."
fi

# Обновление завершено
log "=== Обновление успешно завершено ==="
log "Обновлено с версии $CURRENT_VERSION до $NEW_VERSION"
log "Дата и время: $(date)"

# Выводим сообщение об успешном обновлении
echo ""
echo "====================================================="
echo "        ATOM-GAME обновлен до версии $NEW_VERSION"
echo "====================================================="
echo ""
echo "Для проверки работоспособности откройте сайт:"
echo "https://atomgameblk.ru"
echo ""
echo "При обнаружении проблем восстановите из резервной копии:"
echo "- Используйте файлы, созданные в процессе обновления"
echo "  или запустите скрипт восстановления из бэкапа"
echo "====================================================="
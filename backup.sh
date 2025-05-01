#!/bin/bash

# Скрипт резервного копирования ATOM-GAME
# Создано: ATOM-GAME Team, Май 2025

set -e  # Остановка скрипта при ошибках

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Сброс цвета

# Функция для вывода с цветами
log() {
  echo -e "${GREEN}[РЕЗЕРВНОЕ КОПИРОВАНИЕ]${NC} $1"
}

error() {
  echo -e "${RED}[ОШИБКА]${NC} $1"
  exit 1
}

warning() {
  echo -e "${YELLOW}[ВНИМАНИЕ]${NC} $1"
}

# Параметры
BACKUP_DIR="$(pwd)/backups"
MAX_BACKUPS=10  # Максимальное количество хранимых резервных копий
BACKUP_PREFIX="backup_"

# Проверка наличия директории проекта
if [ ! -d "$(pwd)" ]; then
  error "Директория проекта не найдена!"
fi

# Создание директории для резервных копий
if [ ! -d "$BACKUP_DIR" ]; then
  mkdir -p "$BACKUP_DIR"
  log "Создана директория для резервных копий: $BACKUP_DIR"
fi

# Определение параметров базы данных из .env файла
if [ ! -f .env ]; then
  error "Файл .env не найден! Невозможно определить параметры базы данных."
fi

source <(grep -v '^#' .env | sed 's/^/export /')

if [ -z "$PGUSER" ] || [ -z "$PGPASSWORD" ] || [ -z "$PGDATABASE" ]; then
  error "Отсутствуют необходимые параметры базы данных в файле .env"
fi

# Формирование имени файла резервной копии
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/${BACKUP_PREFIX}${TIMESTAMP}.sql"

# Выполнение резервного копирования
log "Начало создания резервной копии базы данных..."
PGPASSWORD=$PGPASSWORD pg_dump -U $PGUSER -h ${PGHOST:-localhost} -p ${PGPORT:-5432} $PGDATABASE > "$BACKUP_FILE"

# Проверка результата
if [ $? -eq 0 ] && [ -f "$BACKUP_FILE" ]; then
  # Сжатие резервной копии
  gzip "$BACKUP_FILE"
  BACKUP_FILE="${BACKUP_FILE}.gz"
  
  log "Резервная копия успешно создана: $BACKUP_FILE"
  log "Размер файла: $(du -h $BACKUP_FILE | cut -f1)"
else
  error "Ошибка при создании резервной копии!"
fi

# Удаление старых резервных копий (оставляем только MAX_BACKUPS последних копий)
BACKUP_COUNT=$(ls -1 $BACKUP_DIR/${BACKUP_PREFIX}*.gz 2>/dev/null | wc -l)
if [ $BACKUP_COUNT -gt $MAX_BACKUPS ]; then
  log "Удаление старых резервных копий (сохраняем только $MAX_BACKUPS последних)..."
  ls -tr $BACKUP_DIR/${BACKUP_PREFIX}*.gz | head -n $(($BACKUP_COUNT - $MAX_BACKUPS)) | xargs rm -f
  log "Старые резервные копии удалены."
fi

# Вывод списка текущих резервных копий
echo ""
echo "Текущие резервные копии:"
ls -lht $BACKUP_DIR/${BACKUP_PREFIX}*.gz | awk '{print $9, "("$5")"}' | column -t

echo ""
echo -e "${GREEN}Резервное копирование успешно завершено!${NC}"
echo -e "Для восстановления базы данных используйте команду:"
echo -e "${YELLOW}gunzip -c $BACKUP_FILE | PGPASSWORD=$PGPASSWORD psql -U $PGUSER -h ${PGHOST:-localhost} -p ${PGPORT:-5432} $PGDATABASE${NC}"
echo ""

# Если скрипт запущен с параметром --cron, не выводим дополнительную информацию
if [ "$1" != "--cron" ]; then
  # Настройка автоматического резервного копирования
  echo -e "${YELLOW}Хотите настроить автоматическое ежедневное резервное копирование?${NC} (y/n)"
  read -p "> " SETUP_CRON
  
  if [ "$SETUP_CRON" = "y" ] || [ "$SETUP_CRON" = "Y" ]; then
    # Добавление задания в crontab
    CRON_JOB="0 3 * * * $(pwd)/backup.sh --cron >/dev/null 2>&1"
    
    # Проверка наличия задания в crontab
    if crontab -l 2>/dev/null | grep -q "$(pwd)/backup.sh"; then
      warning "Задание уже существует в crontab. Пропускаем..."
    else
      (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
      log "Автоматическое резервное копирование настроено на 3:00 ежедневно."
    fi
  fi
fi
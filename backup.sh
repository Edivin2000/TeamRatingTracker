#!/bin/bash

# Скрипт для создания резервных копий ATOM-GAME рейтинговой системы
# Автор: Atom-Game Team
# Дата: 01.05.2025

# Настройки
BACKUP_DIR="/var/backups/atomgame"
PROJECT_DIR="/var/www/atomgameblk"
PGUSER="atomgame"
PGPASSWORD="Atom&Game#2025!"
PGDATABASE="atomgame"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$BACKUP_DIR/backup_$TIMESTAMP.log"

# Создаем директорию для резервных копий, если она не существует
mkdir -p $BACKUP_DIR

# Начинаем логирование
echo "=== Начало резервного копирования: $(date) ===" | tee -a $LOG_FILE

# Функция для логирования
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a $LOG_FILE
}

# Создаем резервную копию базы данных
log "Создание резервной копии базы данных..."
export PGPASSWORD=$PGPASSWORD
pg_dump -U $PGUSER $PGDATABASE -F c -f "$BACKUP_DIR/db_$TIMESTAMP.dump"
if [ $? -eq 0 ]; then
  log "Резервная копия базы данных успешно создана: db_$TIMESTAMP.dump"
else
  log "ОШИБКА: Не удалось создать резервную копию базы данных!"
  exit 1
fi

# Создаем резервную копию всего проекта
log "Создание резервной копии файлов проекта..."
if [ -d "$PROJECT_DIR" ]; then
  tar -czf "$BACKUP_DIR/files_$TIMESTAMP.tar.gz" -C $(dirname $PROJECT_DIR) $(basename $PROJECT_DIR)
  if [ $? -eq 0 ]; then
    log "Резервная копия файлов проекта успешно создана: files_$TIMESTAMP.tar.gz"
  else
    log "ОШИБКА: Не удалось создать резервную копию файлов проекта!"
  fi
else
  log "ОШИБКА: Директория проекта $PROJECT_DIR не существует!"
fi

# Удаляем старые резервные копии (оставляем только последние 7 дней)
log "Удаление устаревших резервных копий..."
find $BACKUP_DIR -name "db_*.dump" -type f -mtime +7 -delete
find $BACKUP_DIR -name "files_*.tar.gz" -type f -mtime +7 -delete
log "Устаревшие резервные копии удалены."

# Показываем информацию о созданных резервных копиях
DB_SIZE=$(du -h "$BACKUP_DIR/db_$TIMESTAMP.dump" | cut -f1)
FILES_SIZE=$(du -h "$BACKUP_DIR/files_$TIMESTAMP.tar.gz" | cut -f1)
TOTAL_BACKUPS=$(find $BACKUP_DIR -name "db_*.dump" | wc -l)

echo "=== Резервное копирование завершено: $(date) ===" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "Сводка резервного копирования:" | tee -a $LOG_FILE
echo "- Дата создания: $(date)" | tee -a $LOG_FILE
echo "- Размер копии БД: $DB_SIZE" | tee -a $LOG_FILE
echo "- Размер копии файлов: $FILES_SIZE" | tee -a $LOG_FILE
echo "- Всего резервных копий: $TOTAL_BACKUPS" | tee -a $LOG_FILE
echo "- Хранение: $BACKUP_DIR" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "Для восстановления из резервной копии используйте команды:" | tee -a $LOG_FILE
echo "- БД: pg_restore -U $PGUSER -d $PGDATABASE $BACKUP_DIR/db_$TIMESTAMP.dump" | tee -a $LOG_FILE
echo "- Файлы: tar -xzf $BACKUP_DIR/files_$TIMESTAMP.tar.gz -C /" | tee -a $LOG_FILE
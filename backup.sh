#!/bin/bash

# Скрипт для создания резервной копии базы данных ATOM-GAME Балаково
# Использование: ./backup.sh [backup|restore] [путь_к_файлу_для_восстановления]

DB_NAME=${PGDATABASE:-atomgame}
BACKUP_DIR="./backups"
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/atomgame_backup_$DATE.sql"

# Создаем директорию для бэкапов, если она не существует
mkdir -p "$BACKUP_DIR"

# Функция для создания резервной копии
create_backup() {
  echo "Создание резервной копии базы данных $DB_NAME..."
  
  if [[ -z "$PGPASSWORD" ]]; then
    # Если пароль не задан в переменных окружения, запрашиваем его
    read -sp "Введите пароль для базы данных PostgreSQL: " PGPASSWORD
    echo ""
    export PGPASSWORD
  fi
  
  pg_dump -U ${PGUSER:-postgres} -h ${PGHOST:-localhost} -p ${PGPORT:-5432} "$DB_NAME" > "$BACKUP_FILE"
  
  if [ $? -eq 0 ]; then
    echo "Резервная копия успешно создана: $BACKUP_FILE"
    echo "Размер файла: $(du -h "$BACKUP_FILE" | cut -f1)"
  else
    echo "Ошибка при создании резервной копии!"
    exit 1
  fi
}

# Функция для восстановления из резервной копии
restore_backup() {
  if [ -z "$1" ]; then
    echo "Ошибка: необходимо указать файл для восстановления!"
    echo "Использование: $0 restore путь_к_файлу_резервной_копии"
    exit 1
  fi
  
  RESTORE_FILE="$1"
  
  if [ ! -f "$RESTORE_FILE" ]; then
    echo "Ошибка: файл $RESTORE_FILE не существует!"
    exit 1
  fi
  
  echo "ВНИМАНИЕ: Это действие перезапишет текущую базу данных!"
  echo "Вы собираетесь восстановить базу данных из файла: $RESTORE_FILE"
  read -p "Продолжить? (y/n): " CONFIRM
  
  if [ "$CONFIRM" != "y" ]; then
    echo "Восстановление отменено."
    exit 0
  fi
  
  if [[ -z "$PGPASSWORD" ]]; then
    # Если пароль не задан в переменных окружения, запрашиваем его
    read -sp "Введите пароль для базы данных PostgreSQL: " PGPASSWORD
    echo ""
    export PGPASSWORD
  fi
  
  echo "Восстановление базы данных $DB_NAME из файла $RESTORE_FILE..."
  
  # Очищаем существующую базу данных
  psql -U ${PGUSER:-postgres} -h ${PGHOST:-localhost} -p ${PGPORT:-5432} -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" "$DB_NAME"
  
  # Восстанавливаем из файла резервной копии
  psql -U ${PGUSER:-postgres} -h ${PGHOST:-localhost} -p ${PGPORT:-5432} "$DB_NAME" < "$RESTORE_FILE"
  
  if [ $? -eq 0 ]; then
    echo "База данных успешно восстановлена из файла: $RESTORE_FILE"
  else
    echo "Ошибка при восстановлении базы данных!"
    exit 1
  fi
}

# Основная логика скрипта
case "$1" in
  "backup")
    create_backup
    ;;
  "restore")
    restore_backup "$2"
    ;;
  *)
    echo "ATOM-GAME Балаково - Управление резервными копиями"
    echo "Использование:"
    echo "  $0 backup    - Создать резервную копию базы данных"
    echo "  $0 restore файл - Восстановить базу данных из файла"
    
    # По умолчанию создаем резервную копию
    read -p "Создать резервную копию базы данных сейчас? (y/n): " CREATE_BACKUP
    if [ "$CREATE_BACKUP" = "y" ]; then
      create_backup
    fi
    ;;
esac

exit 0
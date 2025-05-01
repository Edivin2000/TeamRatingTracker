#!/bin/bash

# Скрипт для инициализации Git и отправки проекта на GitHub
# Автор: Atom-Game Team
# Дата: 01.05.2025

set -e

# Переменные (замените на ваши)
GIT_USERNAME="your-username"
GIT_EMAIL="your-email@example.com"
REPO_NAME="atom-game-rating"
GITHUB_USER="your-github-username"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода
log() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Начало
log "Начинаем процесс инициализации Git и отправки на GitHub..."

# Проверка наличия Git
if ! command -v git &> /dev/null; then
  error "Git не установлен! Пожалуйста, установите Git и повторите попытку."
  exit 1
fi

# Вывод информации о Git
log "Используется Git версии: $(git --version)"

# Проверка существующего Git репозитория
if [ -d ".git" ]; then
  warn "Git репозиторий уже инициализирован."
  read -p "Хотите продолжить с текущим репозиторием? (y/n): " CONTINUE
  if [[ $CONTINUE != "y" && $CONTINUE != "Y" ]]; then
    error "Операция прервана пользователем."
    exit 1
  fi
else
  # Инициализация Git
  log "Инициализация Git репозитория..."
  git init
  success "Git репозиторий инициализирован."

  # Настройка имени пользователя и адреса электронной почты
  log "Настройка Git пользователя..."
  read -p "Введите имя пользователя Git [$GIT_USERNAME]: " USERNAME
  USERNAME=${USERNAME:-$GIT_USERNAME}
  
  read -p "Введите адрес электронной почты Git [$GIT_EMAIL]: " EMAIL
  EMAIL=${EMAIL:-$GIT_EMAIL}
  
  git config user.name "$USERNAME"
  git config user.email "$EMAIL"
  success "Git пользователь настроен: $USERNAME <$EMAIL>"
fi

# Проверка удаленных репозиториев
if git remote | grep -q "origin"; then
  warn "Удаленный репозиторий 'origin' уже существует."
  git remote -v
  read -p "Хотите заменить существующий репозиторий? (y/n): " REPLACE_REMOTE
  if [[ $REPLACE_REMOTE == "y" || $REPLACE_REMOTE == "Y" ]]; then
    git remote remove origin
    log "Удаленный репозиторий 'origin' удален."
  else
    warn "Сохраняем существующий удаленный репозиторий."
  fi
fi

# Добавление удаленного репозитория, если необходимо
if ! git remote | grep -q "origin"; then
  read -p "Введите имя GitHub пользователя [$GITHUB_USER]: " GITHUB_USERNAME
  GITHUB_USERNAME=${GITHUB_USERNAME:-$GITHUB_USER}
  
  read -p "Введите название репозитория [$REPO_NAME]: " REPOSITORY
  REPOSITORY=${REPOSITORY:-$REPO_NAME}
  
  log "Добавление удаленного репозитория: https://github.com/$GITHUB_USERNAME/$REPOSITORY.git"
  git remote add origin "https://github.com/$GITHUB_USERNAME/$REPOSITORY.git"
  success "Удаленный репозиторий добавлен."
fi

# Добавление файлов в индекс
log "Добавление всех файлов в индекс..."
git add .

# Создание коммита
log "Создание коммита..."
read -p "Введите сообщение коммита [Первоначальная загрузка ATOM-GAME]: " COMMIT_MSG
COMMIT_MSG=${COMMIT_MSG:-"Первоначальная загрузка ATOM-GAME рейтинговой системы"}
git commit -m "$COMMIT_MSG"
success "Коммит создан: $COMMIT_MSG"

# Установка имени ветки
log "Установка имени ветки на 'main'..."
git branch -M main
success "Ветка переименована в 'main'."

# Отправка в удаленный репозиторий
log "Отправка в удаленный репозиторий..."
log "Это может занять некоторое время в зависимости от размера проекта и скорости интернета."
git push -u origin main
success "Проект успешно отправлен в GitHub!"

# Вывод завершения
echo ""
echo "=============================================================="
echo "       ATOM-GAME успешно загружен на GitHub!                 "
echo "=============================================================="
echo ""
echo "Теперь вы можете получить доступ к вашему репозиторию по адресу:"
echo "https://github.com/$GITHUB_USERNAME/$REPOSITORY"
echo ""
echo "Для настройки GitHub Actions и автоматического деплоя:"
echo "1. Перейдите в 'Settings' > 'Secrets and variables' > 'Actions'"
echo "2. Добавьте следующие секреты для деплоя:"
echo "   - DEPLOY_HOST: Хост вашего сервера"
echo "   - DEPLOY_USER: Имя пользователя SSH"
echo "   - DEPLOY_KEY: Приватный SSH ключ"
echo "   - DEPLOY_PORT: Порт SSH (обычно 22)"
echo "=============================================================="
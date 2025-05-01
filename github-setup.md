# Перенос ATOM-GAME на GitHub

## Шаги по настройке репозитория

1. Создайте новый репозиторий на GitHub:
   - Перейдите на [GitHub](https://github.com)
   - Нажмите "New repository"
   - Укажите имя: `atom-game-rating`
   - Описание: "Рейтинговая система ATOM-GAME для сезона 2025 | Балаково"
   - Выберите "Public" или "Private" в зависимости от желаемого уровня доступа
   - Не инициализируйте репозиторий с README
   - Нажмите "Create repository"

2. Инициализируйте Git в локальном проекте и отправьте на GitHub:
   ```bash
   cd /путь/к/вашему/проекту
   git init
   git add .
   git commit -m "Первоначальная загрузка ATOM-GAME рейтинговой системы"
   git branch -M main
   git remote add origin https://github.com/ваш-аккаунт/atom-game-rating.git
   git push -u origin main
   ```

3. Настройка GitHub Pages (опционально):
   - В репозитории перейдите в "Settings" > "Pages"
   - В разделе "Source" выберите ветку "main"
   - Сохраните настройки

4. Настройте GitHub Actions для автоматического деплоя:
   - Файл `.github/workflows/deploy.yml` уже создан в репозитории
   - Он будет автоматически развертывать приложение при каждом push в main ветку

## Файлы для GitHub

В репозитории уже подготовлены следующие файлы:
- `.gitignore` - настроен для игнорирования временных файлов, node_modules и т.д.
- `README.md` - описание проекта
- `LICENSE` - лицензия MIT
- `.github/workflows/deploy.yml` - GitHub Action для автоматического деплоя

## Инструкции по локальной разработке

1. Клонируйте репозиторий:
   ```bash
   git clone https://github.com/ваш-аккаунт/atom-game-rating.git
   cd atom-game-rating
   ```

2. Установите зависимости:
   ```bash
   npm install
   ```

3. Настройте переменные окружения:
   - Создайте файл `.env` в корне проекта
   - Добавьте необходимые переменные окружения (см. `.env.example`)

4. Запустите приложение:
   ```bash
   npm run dev
   ```

## Инструкции по деплою

Для ручного деплоя на сервер с GitHub:

1. Клонируйте репозиторий на сервер:
   ```bash
   git clone https://github.com/ваш-аккаунт/atom-game-rating.git /var/www/atomgameblk
   cd /var/www/atomgameblk
   ```

2. Запустите скрипт деплоя:
   ```bash
   chmod +x deploy.sh
   sudo ./deploy.sh
   ```

Или используйте автоматический деплой через GitHub Actions (настройте secrets в репозитории).
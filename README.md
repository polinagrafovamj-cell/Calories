# CalorieCounter

Простой счётчик калорий в двух версиях:
- **iOS** — нативное приложение на SwiftUI (iOS 17+, Xcode 15+), папка `CalorieCounter/`;
- **Веб (PWA)** — для Windows, Android и любого браузера, папка `web/`
  (см. раздел [«Веб-версия»](#веб-версия-pwa-для-windows)).

## Возможности
- **Дневная сводка**: кольцо прогресса к дневной цели, остаток/превышение, Б/Ж/У за день.
- Навигация по дням (стрелки ← →), записи сгруппированы по приёмам пищи.
- Удаление записи свайпом.
- **Поиск по базе Open Food Facts**: результаты появляются по мере ввода, выбранный продукт
  сам заполняет КБЖУ (нужен интернет).
- **Экран ввода продукта**: название, приём пищи, вес порции, КБЖУ на 100 г,
  быстрый выбор популярных продуктов, предпросмотр итога за порцию.
- Настройка дневной цели (кнопка с мишенью).
- Данные сохраняются локально в `Documents/food_entries.json`.

## Структура
```
CalorieCounter/
├── CalorieCounterApp.swift      — точка входа
├── Models/FoodEntry.swift       — модель записи, приёмы пищи, суммы за день
├── Store/FoodStore.swift        — хранилище (@Observable) + сохранение в JSON
├── Services/OpenFoodFactsClient.swift — запросы к API Open Food Facts
└── Views/
    ├── DailySummaryView.swift   — главный экран со сводкой
    ├── AddFoodView.swift        — экран ввода продукта
    ├── ProductSearchView.swift  — поиск продукта в базе
    └── FoodRowView.swift        — строка продукта
```

## Запуск
**Вариант 1 — XcodeGen:**
```bash
brew install xcodegen
cd CalorieCounter
xcodegen generate
open CalorieCounter.xcodeproj
```

**Вариант 2 — вручную:** в Xcode создайте новый проект *iOS → App* (Interface: SwiftUI,
имя `CalorieCounter`), удалите сгенерированные `ContentView.swift` и `CalorieCounterApp.swift`
и перетащите папку `CalorieCounter/` с исходниками в проект.

## Сборка через GitHub Actions
Workflow `.github/workflows/build-ios.yml` собирает приложение на macOS-машине GitHub
при каждом пуше в `main` (можно запустить и вручную: **Actions → Build iOS → Run workflow**).

- Результат — **неподписанный** `CalorieCounter-unsigned.ipa`, он лежит в разделе
  **Artifacts** на странице запуска (скачивается zip-архив, внутри — `.ipa`).
- Если запушить тег вида `v1.0` (`git tag v1.0 && git push origin v1.0`), `.ipa`
  дополнительно прикрепится к GitHub Release.

### Установка на iPhone
Неподписанный `.ipa` нужно подписать своим Apple ID — проще всего через
[Sideloadly](https://sideloadly.io) (Windows/macOS):
1. Подключите iPhone к компьютеру кабелем.
2. Перетащите `.ipa` в Sideloadly, введите Apple ID и нажмите **Start**.
3. На iPhone: **Настройки → Основные → VPN и управление устройством** → доверьте профилю;
   на iOS 16+ также включите **Режим разработчика**.

С бесплатным Apple ID приложение работает 7 дней, затем его нужно переустановить.

## Веб-версия (PWA) для Windows
Папка `web/` — то же приложение на HTML/CSS/JS без сборщиков и зависимостей:
дневная сводка, ввод продукта, быстрый выбор, поиск по Open Food Facts, цель, тёмная тема.
Данные хранятся в браузере (localStorage), после первого открытия приложение работает без интернета
(кроме поиска по базе).

### Публикация на GitHub Pages
Workflow `.github/workflows/deploy-pwa.yml` публикует папку `web/` при каждом пуше в `main`.
Один раз включите Pages: **Settings → Pages → Build and deployment → Source: GitHub Actions**.
Адрес будет `https://<ваш_логин>.github.io/<репозиторий>/`.

### Установка на Windows
1. Откройте адрес в **Microsoft Edge** или **Chrome**.
2. Нажмите значок установки в адресной строке (монитор со стрелкой)
   или меню **⋯ → Приложения → Установить это приложение**.
3. «Калории» появятся в меню «Пуск» и откроются в отдельном окне, как обычная программа.

На Android — «Добавить на главный экран» в Chrome, на iPhone — «Поделиться → На экран „Домой“» в Safari.

### Локальный запуск
```bash
python3 -m http.server 8000 -d web
# открыть http://localhost:8000
```
При изменении файлов увеличьте `CACHE` в `web/sw.js`, чтобы установленное приложение обновилось.

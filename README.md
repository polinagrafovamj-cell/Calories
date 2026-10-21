# CalorieCounter

Простое iOS-приложение на SwiftUI для подсчёта калорий (iOS 17+, Xcode 15+).

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

# Healthy Heroes iOS — отчёт по архитектуре, производительности и дизайну

Дата: 21 июля 2026

## Scope

Проверены структура приложения, слой хранения, критический сценарий Food Log, SwiftUI data flow, загрузка графики, состав app bundle и основные игровые экраны. Accessibility намеренно не включена в текущий приоритет по решению владельца продукта.

Аудит производительности является code-backed: Debug и Release собраны, размеры bundle измерены, runtime-тесты выполнены, а время синхронного bootstrap измерено в Debug на Simulator. Полноценный device trace остаётся release gate: ETTrace не установился из-за устаревших Command Line Tools, а запуск `xctrace` через Xcode beta повредил сессию CoreSimulator.

## Итог

Главный релизный риск — раздельная запись профиля и Food Log в JSON — устранён. Приложение теперь использует Core Data поверх SQLite, а профиль, запись журнала, XP, квесты, награды, гардероб и позиция на карте сохраняются одной транзакцией.

Архитектурная граница теперь выглядит так:

```text
SwiftUI / ViewModel
        ↓
Domain Use Cases
        ↓
Repository protocols
        ↓
CoreDataGameRepository + mapper-функции
        ↓
private NSManagedObjectContext
        ↓
NSPersistentContainer / SQLite
```

`NSManagedObject` остаётся внутри Data/Persistence; Domain и UI работают с обычными Swift-структурами.

## Что реализовано

### Хранение и целостность

- Добавлена версионируемая `HealthyHeroes.xcdatamodeld`, текущая версия — `HealthyHeroesV1`.
- Добавлены сущности `ChildProfileEntity`, `FoodLogEntryEntity`, `QuestProgressEntity`, `RewardUnlockEntity`, `WardrobeStateEntity` и служебная `LegacyImportEntity`.
- Для `profileID`, `entryID`, `questID`, `rewardID`, `itemID` и `migrationID` заданы uniqueness constraints.
- Используется один private-queue writer context; runtime API выполняет операции асинхронно через `await context.perform`, изменения откатываются через `rollback()` при любой ошибке. `performAndWait` остался только в одноразовом legacy-import во время bootstrap и его тестовых helpers.
- SQLite store защищён `completeUntilFirstUserAuthentication`.
- Автоматическое удаление store при ошибке загрузки или миграции отсутствует.
- Логи миграции содержат только тип ошибки, без данных профиля.

### Атомарный Food Log

Use case больше не сохраняет дневник и профиль через два независимых repository. Метод `commitFoodLog` объединяет изменение агрегата и вставку `FoodLogEntryEntity` в один `context.save()`.

Failure-path test подтверждает: попытка вставить duplicate `entryID` откатывает уже подготовленное изменение XP, оставляя профиль и журнал в исходном состоянии.

Открытие награды также получило атомарную границу `commitRewardOpened`: флаг открытия и onboarding-профиль сохраняются вместе.

### Переход с JSON

- Старый формат зафиксирован fixtures `legacy-v1`; добавлен fixture более старого `legacy-v0` с преобразованием старых классов персонажа.
- При первом запуске JSON читается на очереди writer context, импортируется одной транзакцией и проверяется по ID, XP, позиции карты и набору Food Log ID.
- После успешной проверки создаётся marker `legacy-v1`.
- Исходные JSON-файлы не удаляются и остаются резервной копией на один релиз.
- При ошибке marker не создаётся, поэтому импорт будет повторён на следующем запуске.

### Производительность

- Repository и use-case API переведены на `async throws`; SwiftUI запускает I/O в `Task`, поэтому MainActor больше не блокируется ожиданием private Core Data queue.
- Начальное чтение профиля перенесено из `RootFlowView.init` в асинхронную `.task`; на время чтения используется явное состояние `loading`.
- После доменных событий UI применяет уже вычисленный профиль локально и не делает лишнее повторное чтение SQLite.
- Большие PNG уже загружаются через ImageIO с downsampling и кэшируются с лимитом 64 MiB; декодирование не выполняется внутри SwiftUI `body`.
- Каталоги JSON из bundle теперь декодируются один раз и кэшируются thread-safe loader-ом.
- Удалён runtime-путь записи через `JSONFileStore`, исключив повторное синхронное чтение/перезапись всего журнала.
- Из app target исключены четыре неиспользуемых начертания M PLUS Rounded 1c. Остались только реально используемые Regular, Bold и Black.

| Метрика | До | После | Комментарий |
| --- | ---: | ---: | --- |
| Simulator `.app` | около 36 MiB | 25.0 MiB Debug | code + resource build |
| Simulator `.app` Release | — | 23.4 MiB | unsigned Release build |
| Font payload | 7 начертаний | 3 начертания | экономия около 12.8 MiB исходных TTF |

Debug-замеры bootstrap на iPhone 17 Pro Max Simulator:

| Метрика | Первый запуск после install | Последующие cold-process запуски |
| --- | ---: | ---: |
| `loadPersistentStores` + Core Data setup | 16.46 ms | 5.28–6.94 ms |
| Проверка legacy migration | 1.35 ms | 0.39–0.85 ms |
| Весь dependency bootstrap | 18.66 ms | 5.97–7.65 ms |

Это существенно ниже внутреннего ориентира 400 ms для pre-main + synchronous startup work, поэтому отдельная asynchronous persistence state machine сейчас не оправдана. Замеры оставлены в Debug-only логах; перед релизом вывод подтверждается на физическом устройстве App Launch/Time Profiler.

В SwiftUI-коде не обнаружены высокорисковые паттерны: коллекции используют стабильные domain ID, большие сетки — lazy-контейнеры, тяжёлой сортировки или форматтеров в `body` нет. Фильтрация Food Log и Quests выполняется в computed properties, но объём каталогов мал и сейчас не создаёт практического риска.

### Дизайн и UX

Сильная сторона приложения — последовательная игровая иллюстративная стилистика, единая округлая типографика и понятный six-action hub. Компоненты экранов уже разделены достаточно мелко и соответствуют локальному SwiftUI-подходу для iOS 16 (`@StateObject` у владельца, `@ObservedObject` при инъекции).

Исправлена ложная affordance: декоративная шестерёнка Food Log выглядела как кнопка, но не имела действия. Она удалена, геометрия центрированного заголовка сохранена прозрачным spacer.

Карточка `Other` теперь открывает компактный modal input, требует непустое название и сохраняет trimmed `customTitle`; при ошибке sheet остаётся открыт и показывает сообщение. Поведение покрыто unit-тестом, включая отказ для строки из пробелов.

Для динамической карты дополнена и переведена в `Todo` задача [HEA-22](https://linear.app/healthyheroes/issue/HEA-22/design-adaptive-ios-map-asset-pack-route-anchors-and-app-store-sizes). Дизайнеру явно перечислены отсутствующие материалы: чистый фон и маршрут, отдельные transparent hero/reward assets, 20 normalized anchors, scale/anchor/state specs и safe-area examples. До поставки этих материалов корректно перемещать героя по текущему flattened PNG нельзя.

## Оставшиеся риски и следующий приоритет

1. Simulator-замер не заменяет App Launch/Time Profiler на реальном устройстве. Device trace нужен как release gate, но текущие цифры не обосновывают усложнение startup state machine.
2. Это первая Core Data schema version. JSON fixtures покрывают два legacy-формата, а V1 schema guard проверяет uniqueness constraints. Реальные N−1/N−2 SQLite fixtures появятся вместе с `HealthyHeroesV2`; правила и обязательные проверки зафиксированы в `docs/core-data-migration-policy.md`.
3. Карта остаётся визуально статичной до поставки ассетов из HEA-22. Это следующий дизайн-приоритет, потому что напрямую влияет на основной игровой feedback loop.
4. Перед релизом остаётся ручная проверка first-session loop, именованного `Other` и сохранения после полного завершения и повторного запуска приложения.

## Верификация

- Debug app build: успешно.
- Release app build: успешно.
- Runtime tests после async-refactor и custom input: 28 успешно, 0 ошибок, 0 пропусков; 37,1 секунды.
- После добавления V1 schema guard требуется финальный повторный прогон (ожидается 29 тестов); текущая сессия заблокирована упавшим `CoreSimulatorService`, а не ошибкой приложения.
- `git diff --check`: успешно.

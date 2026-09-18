# space-crawler

**Starvein: Frontier Protocol** — мобильная sci-fi головоломка на Godot 4.

Космические корабли добывают минералы в многослойных астероидах. Механика в духе color-sort puzzle: ограниченные доки, скрытые жилы, прогрессивное открытие цветов.

## Запуск

1. Открыть папку `app/` в Godot 4.x
2. Запустить проект (F5) — откроется главное меню
3. Viewport: 1080×1920 portrait

## Структура

- `app/scenes/app/Main.tscn` — главное меню
- `app/scenes/gameplay/Level.tscn` — игровой уровень
- `app/scripts/` — GDScript логика
- `project.md` — полный журнал проекта

## Управление

- Тап по ◆ клетке → назначить на свободный док
- WARP → ускорение ×2 (5 мин бесплатно, потом 300 CR)
- Цель: добыть квоту каждого минерала

## Android

APK собирается из CLI (Godot 4.7 + Android SDK):

```bash
./scripts/build-android.sh
```

Готовый файл: `build/space-crawler.apk` (~27 MB, arm64-v8a, debug keystore).

Установка на телефон (USB debugging):

```bash
adb install -r build/space-crawler.apk
```

Или скопируйте APK на устройство и установите вручную.

# Редактор уровней Space Crawler

Веб-инструмент: PNG → JSON + превью для `app/data/levels/`.

## Запуск

**Docker (рекомендуется):**

```bash
./scripts/run-level-editor.sh
```

Или вручную:

```bash
docker build -t space-crawler-level-editor tools/level-editor
docker run --rm -p 8080:8080 space-crawler-level-editor
```

Откройте http://localhost:8080

**Без Docker:**

```bash
cd tools/level-editor
python3 -m http.server 8080
```

## Workflow

1. Загрузите pixel-art PNG (прозрачный фон = пустой космос)
2. Укажите ID (например `25` → `level_025.json`)
3. Нажмите «Конвертировать» — смотрите превью сетки
4. **Правка вручную:** кликайте или проводите по клеткам превью. Выберите цвет в палитре или в списке «Все минералы». Ластик / ПКМ — очистить клетку.
5. «Скачать ZIP» → скопируйте `level_XXX.json` и `level_XXX.png` в `app/data/levels/`

Игра подхватит уровень через `AuthoredLevelPack.gd` при следующем запуске.

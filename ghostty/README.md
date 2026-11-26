# Ghostty — терминал

Конфиг: [`config.ghostty`](config.ghostty), тема: [`themes/astronaut`](themes/astronaut).
Открыть: `gconf` (fish). Применить изменения: **`Cmd+Shift+,`** в Ghostty
(или перезапуск).

## Как выглядит

- **astronaut-light / Smoked Paper** — тёплый дымчатый greige-фон, графитовый текст,
  сдержанные petrol- и tobacco-акценты. Прозрачность 90% и blur дают глубину,
  но не мешают читать текст.
- **Шрифт** SF Mono Medium 14, жирный текст — Semibold. Nerd-иконки Ghostty берёт
  из встроенного набора, отдельный Nerd-шрифт не нужен.
- Без заголовка окна и кнопок, без полосы прокрутки (`scrollbar = never`), отступы 14 px.

При переходе в Ghostty раскладка сама переключается на английскую — это
делает AeroSpace, см. [aerospace](../aerospace/#английская-раскладка-в-ghostty).

## Клавиши

| Клавиши | Действие |
|---|---|
| `Cmd+T` / `Cmd+W` | Новая вкладка / закрыть |
| `Cmd+D` / `Cmd+Shift+D` | Разделить окно вправо / вниз (но для этого есть [tmux](../tmux/)) |
| `Cmd+Shift+,` | Перечитать конфиг |
| `Cmd+=` / `Cmd+-` / `Cmd+0` | Крупнее / мельче / сбросить шрифт |
| `Option` | Работает как `Alt` — нужно для хоткеев fish и tmux |

## Как поменять

- Шрифт: `font-family`, `font-size`, `font-style` (`regular`/`medium`/`semibold`/`bold`/`heavy`).
  Доступные начертания: `ghostty +list-fonts --family="SF Mono"`.
- Цвета: файл `themes/astronaut` (фон, текст, курсор, 16 ANSI-цветов).
  Вернуть стандартную тему: `theme = Gruvbox Dark`. Все встроенные темы:
  `ghostty +list-themes`.
- Эффекты курсора: в `shaders/` лежат шейдеры (светящийся след, рябь, «взрыв»).
  Включить: раскомментировать строку `custom-shader = shaders/cursor_tail.glsl`.
- Проверить конфиг на ошибки: `ghostty +validate-config`.

### November 2026 glass update

`facade` uses the dark code-block colours from MainStorage, SF Mono Bold 14.5, opacity 0.69 and blur radius 42. Restarting Ghostty applies any window properties that the live reload leaves pending.

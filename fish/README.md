# fish — основная оболочка

Конфиг: [`config.fish`](config.fish). Открыть: `fishconf`, перечитать: `asrc`.
Промпт — свой, в рамке ([`conf.d/prompt.fish`](conf.d/prompt.fish)):

```
╭─  ~/D/c-practice/stage-1   main ● ─────────────── 3.2s · 23:46
╰─› make clean
```

Сверху — папка (родитель бледно, текущая navy), git-ветка (`●` — есть
несохранённые изменения), справа длительность прошлой команды (если ≥ 1 с) и
время. `›` — режим ввода (красный после ошибки), `‹` — обычный режим vi. После
Enter рамка сворачивается в `● команда`; упавшая или долгая (≥ 3 с) команда
оставляет под выводом строку `✗ exit 1 · 4.2s` / `✓ 4.2s`. Рамка — голубая
(glow), цвета — палитра astronaut-light.

Вернуться к [Tide](https://github.com/IlanCosman/tide) (он установлен, настройки в
[`tide.config.fish`](tide.config.fish)): удалить `conf.d/prompt.fish` и открыть
новое окно. Плагины ставит
[fisher](https://github.com/jorgebucaran/fisher) по списку [`fish_plugins`](fish_plugins).

> **abbr** — это сокращения: набираешь `gs` + пробел, и оно разворачивается в
> полную команду, которую видно и можно поправить перед Enter.

## Основное

| Что | Как |
|---|---|
| История с поиском | `Ctrl-R` (atuin, Enter сразу выполняет — см. [atuin](../atuin/)) |
| Прыгнуть в папку | `cd proj` — **zoxide**: ищет среди часто посещаемых папок по куску имени |
| Выбрать папку из списка | `cdi` — **zoxide + fzf**: интерактивный выбор из посещённых папок |
| Дополнение по Tab | **fifc** (плагин): fzf-окно с иконками и превью папки (`Enter` вставляет выбранную папку, повторный `Tab` открывает список внутри неё) |
| Список файлов | `ls` = `lsd -lah` (иконки, скрытые, папки первыми) |
| Удаление | `rm` **кладёт в Корзину**; `-r/-f` можно писать. Насовсем — `command rm` |
| vi-режим ввода | `Esc` → normal, `v` → выделение, `y` → копирует в буфер macOS |
| Очистить экран | `Ctrl-\` (прокрутка сохраняется) или `c` |
| Шпаргалка по команде | `cheat tar` (cheat.sh) |
| Внешний IP | `ip` |

## Сокращения

| Группа | Команды |
|---|---|
| Редактор, утилиты | `n` nvim · `lg` lazygit · `yz` yazi · `ff` fastfetch · `md файл.md` — прочитать Markdown (glow) |
| tmux | `tn` новый · `ta` вернуться в последнюю сессию ([tmux](../tmux/)) |
| git | `gs` status · `ga` add · `gc` commit · `gcm` commit -m · `gp` push · `gpl` pull · `gb` branch · `gco` checkout · `gsw` switch · `gl` граф · `glo` oneline · `gd` diff · `grv` remotes · `gcl` clone |
| docker | `dops` ps · `doco` compose · `doe` exec |
| Этот репо | `dots` — перейти в `~/.config` и показать git status |
| Конфиги | `fishconf` `asconf` (AeroSpace) `skconf` (SketchyBar) `skcheck` `bordersconf` `gconf` (Ghostty) `tmuxconf` `nvimconf` `karaconf` `atuinconf` `ffconf` `zshconf` `ssconf` (Starship) |

## School 21 — Docker-контейнер

| Команда | Что делает |
|---|---|
| `dohelp21` | Справка |
| `buildcont21` | Собрать образ `s21_env` из Dockerfile в текущей папке |
| `docreate21` | Первый запуск: контейнер `school-container`, `~/Projects/School` → `/home/school` |
| `doon21` / `dooff21` | Запустить / остановить |
| `do21` | Войти внутрь (zsh) |

## Окружение

- **Homebrew первым в PATH** — `git`, `python3`, `pip3` берутся из brew.
- `EDITOR` / `VISUAL` = nvim.
- Приветствие «Welcome to fish» отключено (`set -g fish_greeting`).
- Python-библиотеки — в brew-Python, список в [`../python/`](../python/).

## Плагины

```fish
fisher list          # что установлено
fisher update        # обновить всё по fish_plugins
tide configure       # мастер настройки промпта
```
Файлы плагинов (`functions/`, `conf.d/`, `completions/`) и `fish_variables` в
git не попадают — fisher восстанавливает их из `fish_plugins`.

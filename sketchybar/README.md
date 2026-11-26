# SketchyBar

Активная тема Facade находится в `facade.lua`. Точка входа — `sketchybarrc`.
Часы льняные, Bluetooth песочный, Wi‑Fi и батарея голубые. Персиковый акцент активного стола взят из темы Astronaut в MainStorage. Подписи на английском, шрифт SF Mono Heavy 14 pt.

- MacBook — часы и батарея справа от чёлки. Слева от чёлки по направлению к краю экрана идут Wi‑Fi, аудио и рабочий стол.
- Dell — рабочий стол и аудио слева, часы по центру, Wi‑Fi и батарея справа.
- Замок на Wi‑Fi означает подключённый VPN. Значок Bluetooth меняется на
  AirPods или наушники, когда macOS направляет звук на соответствующее устройство.

При переключении панель получает имя стола из события AeroSpace. При смене
дисплеев или пропуске события она сверяет их одним запросом и перестраивает
виджеты без перезапуска. Состояние батареи и
подключений считывается один раз на оба экрана и обновляет виджеты при изменении.

```sh
sketchybar --reload
brew services restart sketchybar
```

Исходник проверки аудиовыхода — `helpers/facade-audio.swift`. Команды для
пересборки помощника и для обновления локальных иконок:

```sh
swiftc -O ~/.config/sketchybar/helpers/facade-audio.swift -o ~/.local/bin/sketchybar-facade-audio
swift ~/.config/sketchybar/helpers/draw-facade-icons.swift ~/.config/sketchybar/assets
sketchybar --reload
```

Прежняя конфигурация и резервная копия AeroSpace лежат в
`~/.config/backups/desktop-20261126-134014`.

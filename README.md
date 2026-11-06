# Horizon Friends Pack

Сборка Horizon для Windows 10/11 x64: **Orbital Laser, Astral Cruiser, Spider-Man, Physics и Montarc**.

**[Скачать готовый установочный ZIP](https://github.com/timafejburdastyh-ai/horizon-friends-pack/releases/latest)** → распаковать в обычную папку → открыть **INSTALL.cmd**.

В установочном ZIP уже лежат официальный portable Horizon Launcher **0.2.47** и пакеты модов. Сам движок Horizon скачивается официальным лаунчером при установке. Если скачать **Code → Download ZIP**, установщик также скачает лаунчер и моды. Каждая загрузка проверяется по закреплённым SHA-256 и размеру из [pack.json](pack.json).

## Установка и запуск

1. Распакуй ZIP, закрой Horizon Launcher, если он уже открыт, и запусти **INSTALL.cmd**. Нужен интернет для установки самого Horizon; права администратора не требуются.
2. Открой **START-LAUNCHER.cmd** и войди в **свой Microsoft-аккаунт с Minecraft: Java Edition**. Лаунчер подготовит ресурсы из твоего Minecraft; если потребуется, укажи его папку в настройках лаунчера. Сам Horizon бесплатный и открытый, но использует твою копию Minecraft.
3. Закрой окно лаунчера и запусти **BUILD-MOD.cmd**. Выбери мод цифрой **1–4**. Первая сборка выбранного мода занимает примерно **20–30 минут или дольше**, скачивает portable Rust и занимает несколько ГБ. Дождись успешного завершения. Код native-модов выполняется с правами твоей учётной записи; кнопка запускает сборку закреплённого пакета автора.
4. Запусти **PLAY.cmd**, выбери тот же мод. Создай новый творческий мир для проверки. При следующих запусках повторно собирать мод не нужно.

Также можно пользоваться обычным окном лаунчера: группа **Friends Pack** → нужный профиль → **Build**, затем **Play**. Montarc выбирается отдельно в настройках шейдеров игры.

Моды расположены в **четырёх отдельных профилях**: их авторы закрепили разные версии движка. Это не единая игра со всеми native-модами одновременно. Сборка одного профиля не добавляет моды в другой.

## Что добавлено и как управлять

| Профиль | Версия | Начало игры |
|---|---|---|
| Friends - Orbital Laser | 0.5.9 | `/orbital give` выдаёт пульт; **R** — колесо, удержание **ПКМ** — использование |
| Friends - Astral Cruiser | 0.1.0 | `/astral spawn`, затем `/astral board`; **N** — панель, **WASD** — полёт, **пробел/Shift** — вверх/вниз, **V** — выйти из кресла, **F5** — камера |
| Friends - Spider-Man | 0.2.0 | Зажми **R** и прыгни возле высоких поверхностей; отпусти R — отпустить паутину; **Z** — подтягивание к прицелу; `/swingmode on` включает способности |
| Friends - Physics | 0.18.0 | Отдельный профиль с физикой; параметры находятся в настройках мода |

Во всех четырёх профилях есть шейдер **Montarc 1.1.1**, его включают вручную. Для Orbital содержимое предмета также устанавливается в `horizon-mods/orbital`, чтобы пульт существовал в инвентаре.

Orbital: `/orbital terrain off` отключает разрушения, `/orbital terrain on` включает. Перед разрушительными эффектами сделай копию мира. Astral: `/astral tutorial` — встроенное обучение.

## Папки и повторная установка

- Лаунчер: `%LOCALAPPDATA%\HorizonFriendsPack`.
- Профили и миры: `%APPDATA%\horizon\instances\friends-*`.
- Настройки лаунчера: `%APPDATA%\horizon-launcher`.
- Загруженные пакеты: `.cache` рядом с установщиком.

Повторная установка сохраняет миры, настройки игры и выбранные native-версии профилей. Установщик не заменяет чужие профили с совпавшими именами и останавливается, если установленный файл отличается от ожидаемого. Не меняет антивирус, Smart App Control и системную политику PowerShell. Политика запуска из CMD задаётся только для текущего процесса установщика.

Скрипт позволяет проверить размещение без загрузки движка: `powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1 -SkipGameInstall`. `-Offline` требует, чтобы все шесть файлов уже были в `.cache`; игровые ресурсы готовит сам Horizon Launcher.

## Авторы и источники

- [Horizon](https://github.com/horizon-rust/horizon) — Rust-клиент и лаунчер, MIT, [уведомление авторов](licenses/HORIZON-MIT.txt).
- [Orbital Laser — Stink-O](https://github.com/Stink-O/orbital-laser/releases/tag/v0.5.9).
- [Astral Cruiser](https://github.com/horizon-rust/horizon-mods/releases/tag/astral_cruiser-0.1.0), [Spider-Man](https://github.com/horizon-rust/horizon-mods/releases/tag/spider_man-0.2.0), [Physics](https://github.com/horizon-rust/horizon-mods/releases/tag/horizon_physics-0.18.0), [Montarc](https://github.com/horizon-rust/horizon-mods/releases/tag/montarc-1.1.1) — опубликованные пакеты авторов из каталога Horizon.

Файлы модов загружаются из официальных выпусков авторов без изменений; их лицензии и авторство сохраняются. Исходники установщика доступны здесь по MIT. Эта сборка не является официальным выпуском Minecraft, Mojang, Microsoft или Horizon. Миры, аккаунты и игровые ресурсы Minecraft в репозиторий и установочный ZIP не включены.

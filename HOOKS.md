# Вмешательства в ванильные классы

## Таск 2

| Файл мода | Ванильный класс и файл | Аннотация и поле | Назначение | Риск |
| --- | --- | --- | --- | --- |
| `modKrovnayaVrazhda/content/scripts/local/krov_enemy_data.ws` | `W3PlayerWitcher`, `content/content0/scripts/game/player/playerWitcher.ws` | `@addField`, `krov_enemies` | Сохранение массива до 256 записей вместе с Геральтом | Переименование поля или изменение типа после выпуска может сбросить данные. Удаление мода из тестового сейва требует отдельной проверки. |
| `modKrovnayaVrazhda/content/scripts/local/krov_enemy_data.ws` | `W3PlayerWitcher`, `content/content0/scripts/game/player/playerWitcher.ws` | `@addField`, `krov_lastEnemyId` | Сохранение последнего выданного ID, используемого также как seed тестового генератора | Переименование поля или изменение типа может сбросить счётчик. |

Ванильные методы не обёрнуты и не заменены. Записи меняются только по команде `krov_enemy_gen`.

## Таск 3

Все вмешательства этого таска находятся в `modKrovnayaVrazhda/content/scripts/local/krov_encounter.ws`.

| Ванильный класс и файл | Аннотация и член класса | Назначение | Риск |
| --- | --- | --- | --- |
| `CNewNPC`, `game/npc/npc.ws` | `@wrapMethod OnCombatModeSet` | Выбор именного противника при входе в бой. Сначала отрабатывает ванильный метод. | Другая обёртка может менять момент входа в бой или уровень NPC. |
| `CNewNPC`, `game/npc/npc.ws` | `@addMethod krov_tryEncounterPromotion` | Фильтрует кандидатов, создаёт запись, назначает уровень и показывает уведомление. | Срабатывание зависит от родительского энкаунтера, враждебности и дистанции в момент входа в бой. |
| `CNewNPC`, `game/npc/npc.ws` | `@addField krov_encounterEnemyId`, `krov_encounterRolled`, `krov_encounterLabel` | Хранит привязку, результат броска и подпись NPC в сейве. | Сохранность зависит от того, сохраняет ли игра саму сущность. Если игра создаст NPC заново, он может получить новую запись. |
| `W3PlayerWitcher`, `game/player/playerWitcher.ws` | `@addField krov_forceEncounterRoll` | Временный переключатель броска для проверки. | Действует до смены сеанса или команды выключения. |
| `CR4HudModuleEnemyFocus`, `game/gui/hud/modules/hudModuleEnemyFocus.ws` | `@wrapMethod UpdateName` | Подставляет имя и ранг выбранного NPC в штатный HUD. | Моды, которые меняют выбор цели или отображение имени, могут перехватить подпись. |

Теги взяты из трёх слоёв `world_novigrad_startup.bundle`:

- `nml_cp37_bandits_enc` — `living_world/crow_perch/cp37_campfire/encounter.w2l`.
- `enc_lw_sb12_road_ambush` — `living_world/spitfire_bluff/sb12_road_ambush/encounter.w2l`.
- `lw_sb20_treasure_chest_encounter` — `living_world/spitfire_bluff/sb20_treasure_chest/encounter.w2l`.

## Таск 4

| Файл мода | Ванильный класс и файл | Аннотация и член класса | Назначение и риск |
| --- | --- | --- | --- |
| `krov_encounter.ws` | `CNewNPC`, `game/npc/npc.ws` | Расширение существующих `@wrapMethod OnCombatModeSet`, `@addMethod krov_tryEncounterPromotion` и новый `@addMethod krov_bindEnemy` | Запускает наблюдение за боем, обрабатывает выход, привязывает вернувшуюся запись к подходящему NPC исходной встречи. Если подходящих NPC больше нет, запись ждёт. |
| `krov_enemy_memory.ws` | `CNewNPC`, `game/npc/npc.ws` | `@addField krov_enemyIncarnation`, `krov_fightObserved`, `krov_fightEnemyStart`, `krov_fightPlayerStart`, `krov_fightDamage` | Номер воплощения сохраняется, текущие наблюдения о бое живут до выхода из боя или загрузки. |
| `krov_enemy_memory.ws` | `CNewNPC`, `game/npc/npc.ws` | `@addMethod krov_beginFight`, `krov_trackFight`, `krov_rememberHit`, `krov_recordFightOutcome`, `krov_finishDisengagement` | Собирает виды урона, записывает исход. Побег распознаётся эвристикой расстояний, поэтому неясные разрывы контакта пропускаются. |
| `krov_enemy_memory.ws` | `W3DamageManagerProcessor`, `game/gameplay/damage/damageManagerProcessor.ws` | `@wrapMethod ProcessAction` | Сравнивает здоровье до и после ванильной обработки. Результат зависит от прохождения урона через общую цепочку, включая порядок обёрток других модов. Урон и Game Over не перехватываются. |

К записи именного врага добавлены поля `encounterTag`, `returnDay`, `incarnation`. Тег отсутствующей записи таска 3 заполняется при новом бою или регистрации исхода связанного NPC. При возвращении берётся существующая сущность из того же ванильного энкаунтера. Визуальная модель NPC остаётся ванильной, шрам хранится в записи и отражается в прозвище. Команды проверки находятся в `krov_enemy_history_console.ws`.
## Таск 5. Карта мира

| Файл мода | Ванильная точка входа | Что делает и где возможен конфликт |
| --- | --- | --- |
| `krov_ui.ws` | `game/gui/menus/mapMenu.ws`, `@wrapMethod(CR4MapMenu) UpdateEntityPins(out flashArray)` | Сначала вызывает предыдущую реализацию. При включённом примере добавляет одну запись в массив отображаемой карты текущей области. Булавки игрока и игровые объекты не редактирует. Установленные All Quest Markers On Map Remaster и Gwent Players Map оборачивают этот же метод. Фильтры карты и настройки скрытия областей могут повлиять на видимость. |

Счётчик, окно чтения, уведомления и конфиг используют прямые вызовы. Дополнительных аннотаций для них нет.


# RESEARCH.md — таск 1

Источник: ванильный дамп `Kitbein/The-witcher-3-nemesis`, коммит `a0934f1`, каталог `skripts/`.
Пути ниже относительно `skripts/`. Номера строк — этого коммита.

Аннотации `@wrapMethod`, `@addMethod`, `@replaceMethod`, `@addField` **в дампе не встречаются**. В ванильных файлах их и не должно быть: это директивы компилятора модов (патч от 6 июня 2024), а не код игры. Синтаксис аннотаций с этой копии скриптов подтвердить нельзя. Ниже написано, *какую функцию* есть смысл обернуть. Сам текст аннотации в мод не подставлялся.

`import final function` скриптом не переопределяется. Это указано отдельно, где такая функция стоит на пути.

Глобали `theGame` и `thePlayer` в дампе не объявлены, но ими пользуется весь ванильный код, включая `exec`-функции. Объявленная обёртка игрока есть: `function GetWitcherPlayer() : W3PlayerWitcher` в `game/player/playerWitcher.ws`, строка 12968. Hello world вызывает её, а не голый `thePlayer`.

Уже стоящий мод **Nemesis — Enemy Grudge System** почти наверняка сидит на бое и смерти. Любой будущий хук в `ProcessAction` или `OnDeath` с ним придётся склеивать Script Merger'ом. Таск 1 этих функций не трогает.

---

## 1. Появление врагов и «заметность»

**Вердикт: можно.**

Точки входа, все скриптовые, не `final`:

- `statemachine import class CNewNPC extends CActor` — `game/npc/npc.ws`, строка 20.
- `event OnSpawned(spawnData : SEntitySpawnData)` — тот же файл, строка 406. Сюда попадает и обычный энкаунтер, и существо, созданное модом. Поле `spawnData.restored` отличает свежий спавн от загрузки сейва (проверка на строке 439).
- `import class CEncounter extends CGameplayEntity` — `game/gameplay/encounter/encounter.ws`, строка 6.
  - `event OnAreaEnter(area : CTriggerAreaComponent, activator : CComponent)`, строка 29. Срабатывает, когда в зону входит `thePlayer`.
  - `import final function IsPlayerInEncounterArea() : bool`
  - `import final function EnableEncounter(enable : bool)`
  - `import final function EnableMember(memberName : CName, enable : bool)`
  - `import final function SetSpawnPhase(phaseName : name) : bool`
  - `function GetEncounterDataManager() : CEncounterDataManager`, строка 75.
- Отдельного NPC мод может создать сам:
  - `import function LoadResource(resource : string, optional isDepotPath : bool) : CResource` — `core/resource.ws`, строка 6.
  - `import final function CreateEntity(entityTemplate : CEntityTemplate, pos : Vector, optional rot : EulerAngles, ...) : CEntity` — `engine/game.ws`, строка 129. Вызов через `theGame.CreateEntity(...)`.

Кто годится в именные, а кого не трогать:

- `public function GetNPCType() : ENPCGroupType` — `game/npc/npc.ws`, строка 270. Возвращает `npcGroupType`.
- В коде встречаются значения `ENGT_Enemy`, `ENGT_Commoner`, `ENGT_Guard`, `ENGT_Quest`. Самого `enum ENPCGroupType` в дампе нет, это импорт движка. Полный список значений из скриптов не восстановить.
- Квестовых отсекать по `GetNPCType() == ENGT_Quest`. Стража (`ENGT_Guard`) в городах тоже лучше не брать: отдельного «это город» в просмотренных файлах нет.
- Катсцена: `import final function IsCurrentlyPlayingNonGameplayScene() : bool` — `engine/game.ws`, строка 175.
- Лошадь: `public function IsHorse() : bool` — `game/npc/npc.ws`, строка 855.
- Бой уже идёт: `import final function IsInCombat() : bool` — `game/actor.ws`, строка 561.
- Уровень: `public final function GetLevel() : int` — `game/npc/npc.ws`, строка 2085. У игрока свой `public function GetLevel() : int` — `game/player/r4Player.ws`, строка 466.

Чего в скриптах нет: готового события «этот бандит стал заметным» (убежал, тяжело ранил, пережил бой). Это придётся собирать самим из урона, смерти и флага `IsInCombat()`. Побег человека отдельной функции `Flee()` у `CNewNPC` не нашёл. `Flee` есть у роя и у `locomotionAPI` (`import final function Flee(pos : Vector) : Vector` в `game/movement/locomotionAPI.ws`, строка 48) — это движение, не «сюжетный побег». Обход для заметности: низкое здоровье плюс выход из боя, либо `WillBeUnconscious()` на `CNewNPC` (editable-поле, строка 27 того же файла).

Рядом с игроком лимит «не больше N живых» тоже выполним: мод сам решает, кого оставить записью, а кого `CreateEntity`. Готовых шаблонов бандитов в дампе скриптов нет, пути `.w2ent` надо будет брать из ресурсов игры. Пока пути не проверены, спавн в RESEARCH не считаю закрытым до конца: **создать сущность можно, конкретный шаблон ещё не подтверждён.**

## 2. Урон и смерть

**Вердикт: можно. Перехват Game Over — можно, но это самый опасный хук. Запасной порог здоровья тоже можно.**

Весь удар проходит через скрипт:

- `class W3DamageManagerProcessor` — `game/gameplay/damage/damageManagerProcessor.ws`, строка 6.
- `public function ProcessAction(act : W3DamageAction)` — строка 22.
- В начале запоминается `wasAlive = act.victim.IsAlive()` (строка 38).
- Смерть именно здесь: `if (wasAlive && !action.victim.IsAlive())` — строка 103. Рядом различается смерть и потеря сознания через `npc.WillBeUnconscious()`.

Данные удара:

- `class W3DamageAction` — `game/gameplay/actions/baseAction.ws`, строка 37.
- `import var attacker : CGameplayEntity` и `import var victim : CGameplayEntity` — строки 26–27, класс `CDamageData`.
- `public function DealsAnyDamage() : bool` — строка 504.
- `public function IsDoTDamage() : bool` — строка 448.
- `public final function IsActionMelee() : bool` — строка 624.
- Поле `dealtFireDamage` есть (строка 57), поле знака `signSkill : ESkill` есть (строка 53). Оба не публичные. Читать их снаружи класса нельзя. Для «чем били» надёжнее наследник:
- `class W3Action_Attack extends W3DamageAction` — `game/gameplay/actions/attackAction.ws`, строка 6.
- `public function GetAttackTypeName() : name` — строка 239. В `npc.ws` (около строки 2009) ваниль уже приводит удар к `W3Action_Attack` и смотрит это имя.

Смерть актёра:

- `event OnDeath(damageAction : W3DamageAction)` у `CActor` — `game/actor.ws`, строка 3330.
- Тот же event у игрока, `CPlayer` / файл `game/player/player.ws`, строка 1064. Он вызывает `super.OnDeath`, затем либо бессознательное состояние, либо смерть.
- Смерть игрока: `SetAlive(false)`, таймер, и через `CR4ScriptedHud.StartDeathTimer` (`game/gui/hud/hud.ws`, строка 208) вызывается `theGame.RequestMenu('DeathScreenMenu')` — строка 237.
- `public function Kill(source : name, optional ignoreImmortalityMode : bool, optional attacker : CGameplayEntity)` — объявлена в `game/npc/npc.ws`, строка 2054, внутри ходит в `theGame.damageMgr.ProcessAction`.

Как делать «поражение вместо Game Over» позже:

- Обернуть `OnDeath` игрока **до** `RequestMenu('DeathScreenMenu')` и не дать ванили дойти до экрана смерти, только если убийца — именной враг и это не сюжет. Функция скриптовая, не `final`.
- Запасной путь, если перехват смерти окажется дырявым: в `ProcessAction` смотреть `victim == thePlayer` и `GetHealthPercents()` ниже порога. `public function GetHealthPercents() : float` — `game/actor.ws`, строка 2377. `public final function GetHealth() : float` — строка 2390. Это ровно запасной вариант из концепции.
- Не уверен, что обёртка `OnDeath` успевает отменить уже выставленный `SetAlive(false)` и вызов меню, если ваниль внутри event это делает до возврата. Это надо проверять в игре на таске про поражение, не сейчас. Вердикт поэтому не «нельзя», а **можно, с проверкой порядка**. Ломать сюжетные смерти нельзя: в хуке обязателен выход в ваниль, если сцена или квест.

`SetImmortalityMode(mode : EActorImmortalityMode, channel : EActorImmortalityChannel, optional lockMode : bool)` — `game/actor.ws`, строка 415. Годится, чтобы именной враг не добивал Геральта в том же кадре, но это уже геймплей, не таск 1.

## 3. Имя врага в HUD

**Вердикт: можно, через HUD, не через имя сущности.**

Имя на прицеле берётся так:

- `class CR4HudModuleEnemyFocus` — `game/gui/hud/modules/hudModuleEnemyFocus.ws`, строка 17.
- В `event OnTick` (строка 194) цель: `thePlayer.GetDisplayTarget()`, приведение к `CNewNPC`.
- Раз в 0.25 с вызывается `UpdateName(l_target.GetDisplayName())` — строка 352.
- `public function UpdateName(enemyName : string)` — строка 556. Кладёт строку во Flash-функцию `setEnemyName`.
- `GetDisplayName` — `import final function GetDisplayName(optional fallBack : bool) : string` на `CGameplayEntity`, `game/gameplayEntity.ws`, строка 81. **Подменить её нельзя.** `SetDisplayName` в дампе нет.

Обход: обернуть `UpdateName`. К моменту вызова приватное поле `m_lastTarget` уже указывает на текущую цель (его пишут строкой выше, строка 299, когда цель сменилась). Обёртка выполняется внутри класса, приватное поле ей видно. Если цель — наш именной враг, в `UpdateName` уходит наше имя, иначе оригинал.

Риск: другой мод на тот же `UpdateName` потребует Script Merger. На скриншоте явного мода «имена в бою» нет, но это не гарантия.

Имя из шаблона NPC (локализация сущности) так не меняется. Журнал, труп и осмотр будут показывать ванильное имя, пока для них нет отдельного текста. Для MVP достаточно имени в прицеле и строки на HUD.

## 4. Текст и реплики

**Вердикт: можно. Новая озвучка не нужна и из скриптов всё равно не делается.**

Короткая строка на HUD, как в официальном примере REDkit:

- `public function DisplayHudMessage(value : string)` — `game/player/r4Player.ws`, строка 11241. Кладёт строку в очередь.
- Очередь показывает `DisplayPendingMessage()` в `game/gui/hud/modules/hudModuleMessage.ws.ws`, строка 58. Сначала пробует `GetLocStringByKey(str)` (`import function` в `game/localizedContent.ws`, строка 8). Если ключа нет, на экран идёт сырой текст. Hello world на этом и стоит.

Всплывающее уведомление:

- `public function ShowNotification(messageText : string, optional duration : float, optional queue : bool)` — `game/gui/r4guimanager.ws`, строка 1389. Вызов: `theGame.GetGuiManager().ShowNotification(...)`.

Боевой клич без новой озвучки:

- `import final function PlayVoiceset(priority : int, voiceset : string, optional breakCurrentSpeach : bool) : bool` — `game/actor.ws`, строка 912.
- `import final function PlayLineByStringKey(stringKey : string, subtitle : bool)` — строка 1353.

`PlayLineByStringKey` требует ключ, который уже есть в `w3strings` игры. Произвольную русскую фразу туда не положить без своего строкового файла. Для MVP субтитры именных врагов — это `DisplayHudMessage` / `ShowNotification` сырой строкой, плюс ванильный `PlayVoiceset` как звук, без новых слов. Так концепция и просит: субтитры и ванильные кличи.

Кириллица внутри `.ws`: не проверено, компилятор иногда отвергает файл не в своей кодировке. В таске 1 строки только латиницей. Русский текст для следующих тасков держать отдельным файлом и подставлять уже проверенным способом. Какой способ переживёт компилятор 5.01, этим таском не доказан.

Лог, не для игрока:

- `import function LogChannel(channel : name, text : string)` — `core/misc.ws`, строка 9.
- Пишется в `Documents\The Witcher 3\scriptlog.txt` при запуске с `-debugscripts`. В открытую консоль эта строка не печатается.

## 5. Окно выбора (пощада)

**Вердикт: два варианта — можно. Три кнопки одним окном — нельзя, обход есть.**

Готовое окно:

- `enum EUserDialogButtons` — `game/gui/r4guimanager.ws`, строки 67–73: `UDB_Ok`, `UDB_OkCancel`, `UDB_YesNo`, `UDB_None`. Третьей кнопки нет.
- `public function ShowUserDialog(messageId : int, title : string, message : string, type : EUserDialogButtons)` — строка 1221.
- Ответ приходит в `public function UserDialogCallback(messageId : int, actionId : EUserMessageAction)` — строка 1313.
- Действия: `enum EUserMessageAction` в `game/gui/popups/messagePopup.ws`, строки 6–12: `UMA_Ok`, `UMA_Cancel`, `UMA_Yes`, `UMA_No`.
- Дальше ваниль зовёт `import final function OnUserDialogCallback(message, action : int)` на игре (`game/r4Game.ws`, строка 297). Этот `final` не обернуть. Оборачивать нужно `UserDialogCallback` — он скриптовый.

Обход для «убить / отпустить / отпустить за плату»: два окна «да/нет» подряд. Сначала «убить?». Если нет — «взять плату?». Свой `messageId` взять заведомо свободным: занятые номера перечислены в `enum EUniqueMessageIDs` (тот же файл, строки 75–94), крупнейшие около 129039 и 218793. Чужой мод может занять тот же номер. Это риск, его надо будет зашить в HOOKS, когда дойдём до пощады.

Новую кнопку взаимодействия с нуля скрипт не создаёт. `CInteractionComponent` (`engine/components.ws`, строка 89) умеет `SetActionName` у уже существующей кнопки, не добавить третью. Поэтому обход — именно два диалога, а не новая иконка «пощадить».

## 6. Доски объявлений

**Вердикт: можно добавить карточку на уже стоящую доску. Свой текст на карточке — только если есть ключ локализации. Для MVP это обход, не прямая дорога.**

- `statemachine class W3NoticeBoard extends CR4MapPinEntity` — `game/gameplay/board.ws`, строка 27.
- `function AddErrand(newErrand : ErrandDetailsList, optional forceActivate : bool)` — строка 311. Пишет в сохранённый массив `addedNotes`.
- Структура `ErrandDetailsList` — строки 6–19. Поле текста: `errandStringKey : string`. Это ключ, не готовая фраза.
- Доска ищется так же, как в `game/quests/quest_function.ws` около строки 6070: `theGame.GetEntitiesByTag` и приведение к `W3NoticeBoard`.
- Меню доски: `theGame.RequestMenu('NoticeBoardMenu', this)` — `board.ws`, строка 783. `import final function RequestMenu(menuName : name, optional initData : IScriptable)` — `game/commonGame.ws`, строка 246.

Чего нет: функции «поставь на доску произвольный русский абзац». Карточка без ключа в `w3strings` будет пустой или покажет сам ключ. Обход для MVP: не рисовать бумажку, а сообщать заказ через `DisplayHudMessage` и запись в наших фактах. Настоящая карточка — отдельный строковый файл, его в этом дампе нет, схему `w3strings` я не выдумываю.

## 7. Медитация

**Вердикт: можно повеситься на вход в медитацию. Отдельного события «медитация закончилась, прошло N часов» одной функцией нет.**

- `public function Meditate() : bool` — `game/player/playerWitcher.ws`, строка 10185. Если Геральт не в медитации, делает `GotoState('Meditation')`.
- `public function CanMeditate() : bool` — строка 10093. Отказывает в бою по цепочке `CanMeditateHere()` → `IsThreatened()` (строка 10149).
- Состояние: `state Meditation in W3PlayerWitcher` — `game/player/states/meditation/meditation.ws`, строка 6. Вход: `event OnEnterState(prevStateName : name)`, строка 27.
- Выход из панели: `event OnMeditationAbort` — `game/player/playerInput.ws`, строка 3558.
- Восстановление после ожидания: `public final function MeditationRestoring(simulatedTime : float)` — `playerWitcher.ws`, строка 10249. Сюда приходит, сколько времени «промотали». Для ночного налёта это полезнее, чем сам факт входа: налёт логично вешать здесь, если медитация в глуши. Функция `final` внутри скрипта: обернуть её аннотацией, скорее всего, нельзя (как и другие `final`). Это **не проверено на компиляторе 5.01**. Запасной хук, который точно скриптовый и не `final`: `OnEnterState` состояния `Meditation` и `Meditate()`.

Рядом с игроком стычки мира концепция велит откладывать. Проверка «игрок рядом» — расстояние до `thePlayer.GetWorldPosition()` и `IsInCombat()`. Отдельного API «поставь мир на паузу в радиусе» нет, его и не нужно: мод просто не разыгрывает заочную стычку, пока точка близко.

## 8. Метки на карте

**Вердикт: можно показать уже известный тип метки на сущности с тегом. Нарисовать новый значок — нельзя.**

- `import final function EnableDynamicMappin(tag : name, enable : bool, type : name, optional useAgents : bool, optional showAlways : bool)` — `game/commonMapManager.ws`, строка 140. Менеджер: `theGame.GetCommonMapManager()`.
- Скриптовая обёртка `quest function EnableDynamicMappin(...)` — `game/quests/quest_function.ws`, строка 6088. Она переводит enum в конкретные имена типов. Среди них есть `'MonsterNest'`, `'QuestAvailable'`, `'Blacksmith'`. Своего типа «именной враг» в этом `switch` нет, ветка `default` ничего не делает.
- Метку можно включить только у сущности, у которой уже есть `tag`. Тег добавляется скриптом: `public function AddTag(tag : name)` — `game/gameplayEntity.ws`, строка 230 (и база в `engine/node.ws`, строка 56). `import final function HasTag(tag : name) : bool` — `engine/node.ws`, строка 45.
- Ручная метка игрока, не наша: `ToggleUserMapPin(...)` — `commonMapManager.ws`, строка 142. Это пользовательские булавки, лимит у них свой. Для врагов лучше `EnableDynamicMappin`, чтобы не съедать булавки игрока.

Обход: вешать на именного врага уникальный тег `krov_pin_<id>` и включать существующий тип, например `'MonsterNest'` или `'QuestAvailable'`. Иконка будет чужая. Новую иконку без ресурсов Scaleform не сделать, и концепция MVP это запрещает.

`quest function SetMapPinStatus(...)` (`quest_function.ws`, строка 335) меняет статус уже существующей статической метки по тегу. Для врага, которого игра сама на карту не ставила, её мало.

## 9. Хранение в сейвах

**Вердикт: можно. Для этого мода брать Facts DB, не новые поля классов.**

Факты движка, едут вместе с сейвом:

- `import function FactsAdd(ID : string, optional value : int, optional validFor : int, optional telemetryEvent : bool, optional storyScenePlayer : CStoryScenePlayer)` — `game/facts.ws`, строка 14.
- `import function FactsQuerySum(ID : string) : int` — строка 17.
- `import function FactsDoesExist(ID : string) : bool` — строка 27.
- `import function FactsRemove(ID : string) : bool` — строка 30.
- `function FactsSet(ID : string, val : int, optional validFor : int)` — строка 32. Удаляет факт и пишет новое значение. Значение только `int`. Строку факт не хранит.

Второй карман, тоже в сейве, на объекте игры:

- `private saved var gameplayFacts : array<SGameplayFact>` — `game/r4Game.ws`, строка 60.
- `public function GameplayFactsSet(factName : string, value : int)` — строка 1757.
- `public function GameplayFactsAdd(...)` — строка 1724.
- Снаружи: `function GameplayFactsSet` / `GameplayFactsAdd` / `GameplayFactsQuerySum` — `game/facts.ws`, строки 72–87.

Почему факты, а не `@addField`:

- Факт не является полем класса. Удалил мод — в сейве остаётся никому не нужное число. Загрузка из‑за этого не падает. Это самое близкое к требованию «мод не ломает сейвы при удалении».
- `@addField ... saved var` на `CR4Game` или `CActor` в этом дампе подтвердить нельзя: аннотаций в исходниках нет. Даже если компилятор их принимает, снятие мода с сохранённым полем — отдельный риск, его лучше не брать, пока факты тянут.
- Имена, шрамы и журнал в факт не влезают как текст. В сейв пишутся числа: id имени, id характера, id события. Сами русские строки живут в таблицах мода и восстанавливаются из id. Так состояние остаётся компактным, как просит концепция.

Не смешивать наши id с ванильными фактами квестов. Префикс имени факта: `krov_`. Иначе можно случайно закрыть или открыть квест.

Проверка фактов в сейве в таск 1 не входит: hello world ничего не записывает. Иначе удаление мода оставляло бы мусор уже на пробном запуске.

## 10. Меню настроек

**Вердикт: из одних этих скриптов новое меню добавить нельзя. Обход для MVP — консольные команды и факты.**

Что есть:

- `import class CInGameConfigWrapper` — `game/inGameConfigWrapper.ws`, строка 6.
- `import final function GetVarValue(groupCName : name, varCName : name) : string` — строка 20.
- `import final function SetVarValue(groupName : name, varName : name, varValue : string)` — строка 22.
- Обёртка: `theGame.GetInGameConfigWrapper()`.
- Язык текста игра уже читает так: `GetVarValue('Localization', 'Virtual_Localization_text')` — строки 81–89 того же файла. Для RU/EN это пригодится.

Чего нет: функции «создай группу настроек». Класс только читает и пишет группы, которые уже лежат в конфиге игры. XML такого конфига в дампе `skripts/` нет, поэтому имя файла и схему я не придумываю.

Обход, которого хватает концепции («переключатель поражения», «мягкий режим»):

- `krov_hello` уже показывает, что `exec function` жива.
- Позже такие же команды будут писать `FactsSet("krov_defeat_mode", 0 или 1)`. Факт в сейве, меню не нужно.
- Настоящий пункт в меню игры — отдельный конфиг, не этот таск. Пока его нет в репозитории скриптов, вердикт честный: **нельзя из скрипта, можно обойти командой.**

На скриншоте стоит Settings Updater. Он как раз про конфиги. Свой XML рядом с ним без проверки лучше не класть.

---

## Сводка

| Пункт | Вердикт |
|---|---|
| Появление и заметность | можно |
| Урон и смерть | можно; экран смерти — можно, проверить порядок |
| Имя в HUD | можно, через `UpdateName`, не через `GetDisplayName` |
| Текст и реплики | можно; своя озвучка не нужна |
| Окно выбора | два варианта можно; три кнопки — обход двумя окнами |
| Доски объявлений | можно добавить запись; свой текст на карточке без строкового файла нельзя |
| Медитация | можно |
| Метки на карте | можно чужой иконкой по тегу; свой значок нельзя |
| Сейвы | можно, Facts DB, только числа |
| Меню настроек | из скрипта нельзя; обход — exec и факты |

Открытые дыры, без которых дальше лучше не кодить вслепую:

1. Точный синтаксис `@wrapMethod` на версии 5.01 этим дампом не подтверждён.
2. Путь к ванильному шаблону бандита (`.w2ent`) в скриптах не лежит.
3. Переживёт ли компилятор кириллицу в `.ws`, не проверялось. Таск 1 её не использует.
4. Конфликт с модом Nemesis начнётся на первом хуке урона или смерти, не раньше.

Hello world эти дыры не закрывает и не должен: он только проверяет, что новый файл компилируется и команда пишет строку.
## Дополнение по версии 2.1, таски 2–5

Таски 1–4 приняты по игровым проверкам автора. Уточнения к исходной разведке по текущей реализации:

- Таск 2. Для записей врагов фактически выбран массив сохраняемых структур `W3PlayerWitcher.krov_enemies` и сохраняемый счётчик `krov_lastEnemyId` в `krov_enemy_data.ws`. Это отличается от исходной рекомендации раздела 9 про Facts DB. Формат действующих записей сохраняем.
- Таск 3. В трёх выбранных энкаунтерах Велена мод даёт имя уже существующему противнику. Для этой реализации создавать NPC из отдельного шаблона не требуется. Пользователь наблюдал результат в лагере по второй булавке. Идентификаторы энкаунтеров и аннотации перечислены в `HOOKS.md`.
- Таск 4. История встреч хранится в записи врага. Команда `krov_enemy_show(id)` выводит состояние, шрамы, прозвища и события. Сценарии `krov_enemy_outcome_test` проверяют запись исхода. Принятая проверка этих сценариев не подтверждает перехват настоящего Game Over.

Таск 5 уточнил два открытых вопроса. Игра принимает русский динамический текст из файла WitcherScript в UTF-8. На Steam 5.01c при установленном Settings Updater отдельная XML-группа в `user_config_matrix/pc` читается через `CInGameConfigWrapper`. Вывод таска 1 о невозможности построить группу одними скриптами сохраняется. Собственную запись журнала заданий можно обновлять при наличии подготовленного ресурса записи и цели. Для прототипа выбран счётчик в Facts DB и штатное окно с русским текстом. Источники, примеры и результаты запуска приведены в `RESEARCH_UI.md`.


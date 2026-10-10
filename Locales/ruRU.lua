local L = LibStub("AceLocale-3.0"):NewLocale("InFlight", "ruRU")
if not L then return end

-- Mouseover on the bar itself
L["TooltipOption1"] = "[Shift + ЛКМ] - переместить иконку миникарты"
L["TooltipOption2"] = "[ПКМ] - открыть настройки"
L["TooltipOption3"] = "[Ctrl + ЛКМ] - принудительно закрыть окно"
L["Duration"] = "Продолжительность полета: "

-- Settings menu: what a change applies to
L["PerCharOptions"] = "Параметры, специфичные для персонажа"

-- Settings menu: Bar Settings
L["BarOptions"] = "Опции полосы"
L["Height"] = "Высота"
L["Width"] = "Ширина"
L["Texture"] = "Текстура"
L["Border"] = "Граница"
L["BarColor"] = "Цвет полосы"
L["UnknownColor"] = "Неизвестный цвет"
L["BackgroundColor"] = "Цвет фона"
L["BorderColor"] = "Цвет границы"
L["CountUp"] = "Посчитать"
L["FillUp"] = "Заполнять"
L["ShowSpark"] = "Показать искру"

-- Settings menu: Text Settings
L["TextOptions"] = "Опции текста"
L["Font"] = "Шрифт"
L["FontColor"] = "Цвет шрифта"
L["OutlineInfo"] = "Контур информации"
L["OutlineTime"] = "Контур времени"
L["CompactMode"] = "Компактный режим"
L["TwoLines"] = "Отображать в две строки"
L["ToText"] = "\"в\" Текст"
L["Enter your 'to' text."] = "Введите текст 'до'."

-- Settings menu: Other
L["ShowChat"] = "Сообщения чата"
L["ConfirmFlight"] = "Подтвердить полет"
L["ConfirmPopup"] = "Лететь в %s?"
L["ResetFlightTimes"] = "Сброс времени полета"
L["ExportFlightTimes"] = "Экспортировать время полетов"

-- Chat messages
L["FlightTimeAdded"] = "добавлено время полета:"
L["FlightTimeUpdated"] = "Время полета обновлено:"
L["FlightTimeContribute"] = "%s раз полета доступны для вклада. Введите \"/inflight export\", чтобы поделиться."

-- Export window
L["ExportMessage"] = "Спасибо, что поделились вашими новыми обнаруженными маршрутами полета!\nПожалуйста, скопируйте текст ниже в буфер обмена (CTRL-C) и разместите его на одном из следующих веб-сайтов:"
L["Select All"] = "Выбрать все"
L["Dismiss"] = "Закрыть"

-- Parsing
L["DestParse"] = ", .+"

-- Flight points and gossip options, looked up by name while in flight
L["Amber Ledge"] = "Янтарная гряда"
L["AmberLedgeGossip"] = "Мне хотелось бы отправиться за Маскировочный щит"
L["Argent Tournament Grounds"] = "Ристалище Серебряного турнира"
L["ArgentTournamentGossip"] = "Забраться на гиппогрифа и приготовиться к бою"
L["Blackwind Landing"] = "Лагерь Черного Ветра"
L["BlackwindLandingGossip"] = "Отправьте меня на заставу Стражи Небес"
L["Caverns of Time"] = "Пещеры Времени"
L["CavernsOfTimeGossip"] = "Прошу, отведи меня в убежище хозяина"
L["Durnholde Keep"] = "Крепость Дарнхольд"
L["Expedition Point"] = "Лагерь экспедиции"
L["ExpeditionPointGossip"] = "Отправь меня к Парящей заставе"
L["Explorers' League Outpost"] = "Лагерь Лиги исследователей"
L["Hellfire Peninsula"] = "Полуостров Адского Пламени"
L["HellfirePeninsulaGossip"] = "Отправь меня на Парящую заставу"
L["Honor Point"] = "Пик Чести"
L["Nighthaven"] = "Ночная Гавань"
L["NighthavenGossipA"] = "Я бы хотел отправиться в деревню Рут'теран"
L["NighthavenGossipH"] = "Мне хотелось бы слетать в Громовой Утес"
L["Nozdormu's Lair"] = "Логово Ноздорму"
L["Old Hillsbrad Foothills"] = "Старые предгорья Хилсбрада"
L["OldHillsbradGossip"] = "Я готов отправиться в крепость Дарнхольд"
L["Reaver's Fall"] = "Останки Сквернобота"
L["Reaver'sFallGossip"] = "Одолжи мне Ветрокрыла. Я иду на Заставу Хребтолома"
L["Return"] = "Возвращение"
L["Rut'theran Village"] = "Деревня Рут'теран"
L["Shatter Point"] = "Парящая застава"
L["Shattered Sun Staging Area"] = "Подготовительный плацдарм Расколотого Солнца"
L["ShatterPointGossip"] = "Отправь меня к Пику Чести"
L["Skyguard Outpost"] = "Застава Стражи Небес"
L["SkyguardOutpostGossip"] = "Да, я бы с радостью доехал до лагеря Черного Ветра"
L["SSSAGossip"] = "Говоря о действиях... мне приказали предпринять атаку с воздуха"
L["SSSAGossip2"] = "Нужно не пропустить подкрепление Клинка Рассвета"
L["Stormwind City"] = "Штормград"
L["StormwindCityGossip"] = "Я хочу полетать над портом Штормграда"
L["Sun's Reach Harbor"] = "Гавань Солнечного Края"
L["The Sin'loren"] = "Син'лорен"
L["TheSin'lorenGossip"] = "Улететь на дракондоре в Солнечный Край"
L["Thunder Bluff"] = "Громовой Утес"
L["Transitus Shield (Scenic Route)"] = "Маскировочный щит (Живописный маршрут)"
L["Valgarde"] = "Валгард"
L["ValgardeGossip"] = "Меня послали с официальным поручением в лагерь Лиги исследователей"
-- The Shadowlands
L["Ring of Transference"] = "Кольцо Перенаправления"
L["ToBastionGossip1"] = "Я готов. Отправьте меня в Бастион"
L["ToBastionGossip2"] = "Мне нужно вернуться в Бастион"
L["Oribos"] = "Орибос"
L["Bastion"] = "Бастион"

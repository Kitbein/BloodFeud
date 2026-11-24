// Task 5. All dynamic UI copy is selected by the game's text language.
function krov_uiText(key : name) : string
{
	var ru : bool;
	ru = GetCurrentTextLocCode() == "RU";
	switch (key)
	{
		case 'title':
			if (ru) return "Журнал охоты";
			return "Hunt journal";
		case 'clues':
			if (ru) return "Свергнуть зло — собрать сведения: ";
			return "Overthrow evil — gather clues: ";
		case 'ready':
			if (ru) return "Свергнуть зло — открыть цель. Сведения: ";
			return "Overthrow evil — reveal the target. Clues: ";
		case 'demo':
			if (ru) return "Проверка интерфейса";
			return "Interface test";
		case 'area':
			if (ru) return "Область поиска";
			return "Search area";
		case 'radius':
			if (ru) return "Искать в радиусе 60 м от этой точки.";
			return "Search within 60 m of this point.";
		case 'mapOn':
			if (ru) return "Откройте карту и найдите область поиска к востоку от Геральта.";
			return "Open the map and find the search area east of Geralt.";
		case 'mapOff':
			if (ru) return "Проверочная метка скрыта.";
			return "Test map marker hidden.";
		case 'config':
			if (ru) return "Тестовые уведомления: ";
			return "Test notifications: ";
		case 'missing':
			if (ru) return "настройка не зарегистрирована";
			return "setting not registered";
	}
	return "";
}

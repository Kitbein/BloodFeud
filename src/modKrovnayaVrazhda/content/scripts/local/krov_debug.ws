// Кровная вражда, таск 1.
// Новый файл, ванильные скрипты не подменяются.
// Префикс krov_ — чтобы не пересечься с другими модами, в том числе с Nemesis.

exec function krov_hello()
{
	var witcher : W3PlayerWitcher;

	// Канал 'Krov' пишется в Documents\The Witcher 3\scriptlog.txt,
	// если игра запущена с -debugscripts. В саму консоль LogChannel не выводится.
	LogChannel('Krov', "krov_hello: mod is loaded");

	witcher = GetWitcherPlayer();
	if (witcher)
	{
		// Сырая строка, не ключ локализации.
		// Если ключа нет, HUD показывает текст как есть (hudModuleMessage.ws).
		// Кириллицу в .ws не кладём: компилятор на не-ASCII иногда падает.
		witcher.DisplayHudMessage("Krovnaya vrazhda: mod ustanovlen.");
	}
	else
	{
		LogChannel('Krov', "krov_hello: no player, open a save and run the command again");
	}
}

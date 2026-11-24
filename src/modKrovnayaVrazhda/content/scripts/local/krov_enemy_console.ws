// Task 2. Full diagnostic output goes to scriptslog.txt on channel Krov.
exec function krov_enemy_gen(count : int)
{
	var witcher : W3PlayerWitcher;
	var enemy : krov_enemy_record;
	var index : int;

	witcher = GetWitcherPlayer();
	if (!witcher)
	{
		LogChannel('Krov', "Open a Geralt save first.");
		return;
	}
	if (count < 1 || count > 256)
	{
		witcher.DisplayHudMessage("krov_enemy_gen: enter 1 to 256.");
		return;
	}
	if (witcher.krov_lastEnemyId > 2147483647 - count)
	{
		witcher.DisplayHudMessage("krov_enemy_gen: ID limit reached.");
		return;
	}

	for (index = 0; index < count; index += 1)
	{
		witcher.krov_lastEnemyId += 1;
		enemy = krov_makeEnemy(witcher.krov_lastEnemyId);
		enemy.id = witcher.krov_lastEnemyId;
		// Task 2 creates test records. Discard the oldest at capacity.
		if (witcher.krov_enemies.Size() >= 256)
			witcher.krov_enemies.Erase(0);
		witcher.krov_enemies.PushBack(enemy);
	}
	witcher.DisplayHudMessage("Krov: added " + IntToString(count) + ", total " +
		IntToString(witcher.krov_enemies.Size()) + ".");
}

// Default output is Russian transliteration. Pass true for English trait labels.
exec function krov_enemy_list(optional english : bool)
{
	var witcher : W3PlayerWitcher;
	var enemy : krov_enemy_record;
	var index : int;
	var count : int;
	var row : string;

	witcher = GetWitcherPlayer();
	if (!witcher)
	{
		LogChannel('Krov', "Open a Geralt save first.");
		return;
	}

	count = witcher.krov_enemies.Size();
	LogChannel('Krov', "krov_enemy_list: count=" + IntToString(count) +
		" lastId=" + IntToString(witcher.krov_lastEnemyId));
	for (index = 0; index < count; index += 1)
	{
		enemy = witcher.krov_enemies[index];
		row = "id=" + IntToString(enemy.id) + " seed=" + IntToString(enemy.seed) +
			" name=" + enemy.givenName + " culture=" + krov_cultureLabel(enemy.culture, english) +
			" character=" + krov_characterLabel(enemy.characterPrimary, english) + "/" +
			krov_characterLabel(enemy.characterSecondary, english) +
			" strength=" + krov_strengthLabel(enemy.strengthPrimary, english) + "/" +
			krov_strengthLabel(enemy.strengthSecondary, english) +
			" weakness=" + krov_weaknessLabel(enemy.weaknessPrimary, english) + "/" +
			krov_weaknessLabel(enemy.weaknessSecondary, english);
		row = row + " template=" + enemy.templatePath +
			" type=" + NameToString(enemy.enemyType) + " faction=" + NameToString(enemy.faction) +
			" rank=" + NameToString(enemy.rank) + " state=" + NameToString(enemy.lifeState) +
			" offset=" + IntToString(enemy.levelOffset) + " grudge=" + IntToString(enemy.grudge) +
			" superior=" + IntToString(enemy.superiorId) + " group=" + IntToString(enemy.groupId) +
			" spot=" + IntToString(enemy.spotId) + " scars=" + IntToString(enemy.scars.Size()) +
			" nicknames=" + IntToString(enemy.nicknames.Size()) + " events=" + IntToString(enemy.events.Size()) +
			" rivals=" + IntToString(enemy.rivals.Size());
		LogChannel('Krov', row);
	}
	witcher.DisplayHudMessage("Krov: " + IntToString(count) + " records. See scriptslog.txt.");
}

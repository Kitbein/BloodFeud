// Task 4. Read a saved history or simulate an outcome for a nearby named NPC.
exec function krov_enemy_show(enemyId : int)
{
	var witcher : W3PlayerWitcher;
	var enemy : krov_enemy_record;
	var meeting : krov_enemy_event;
	var index, i, j : int;
	var row : string;

	witcher = GetWitcherPlayer();
	if (!witcher || witcher != thePlayer)
		return;
	index = krov_findEnemy(witcher, enemyId);
	if (index < 0)
	{
		witcher.DisplayHudMessage("Krov: unknown enemy ID.");
		return;
	}
	enemy = witcher.krov_enemies[index];
	LogChannel('Krov', "krov_enemy_show: id=" + IntToString(enemy.id) + " " +
		krov_encounterTitle(enemy) + " state=" + NameToString(enemy.lifeState) +
		" grudge=" + IntToString(enemy.grudge) + " returnDay=" + IntToString(enemy.returnDay) +
		" encounter=" + NameToString(enemy.encounterTag));
	for (i = 0; i < enemy.scars.Size(); i += 1)
		LogChannel('Krov', "scar=" + NameToString(enemy.scars[i]));
	for (i = 0; i < enemy.nicknames.Size(); i += 1)
		LogChannel('Krov', "nickname=" + enemy.nicknames[i]);
	for (i = 0; i < enemy.events.Size(); i += 1)
	{
		meeting = enemy.events[i];
		row = "day=" + IntToString(meeting.gameDay) + " outcome=" + NameToString(meeting.outcome) +
			" region=" + NameToString(meeting.region) + " position=" + FloatToStringPrec(meeting.location.X, 1) +
			"," + FloatToStringPrec(meeting.location.Y, 1) + "," + FloatToStringPrec(meeting.location.Z, 1) +
			" damage=";
		for (j = 0; j < meeting.playerDamageTypes.Size(); j += 1)
			row += " " + NameToString(meeting.playerDamageTypes[j]);
		LogChannel('Krov', row);
	}
	witcher.DisplayHudMessage(krov_encounterTitle(enemy) + ": " + NameToString(enemy.lifeState) +
		", events " + IntToString(enemy.events.Size()) + ". See scriptslog.txt.");
}

// 1: enemy fled, 2: Geralt defeated, 3: Geralt fled, 4: spared.
// The command only changes the record. It does not move or kill an actor.
exec function krov_enemy_outcome_test(enemyId : int, scenario : int)
{
	var witcher : W3PlayerWitcher;
	var npc : CNewNPC;
	var entities : array<CGameplayEntity>;
	var outcome : name;
	var index : int;

	witcher = GetWitcherPlayer();
	if (!witcher || witcher != thePlayer || theGame.IsDialogOrCutscenePlaying())
		return;
	switch (scenario)
	{
		case 1: outcome = 'enemy_fled'; break;
		case 2: outcome = 'player_defeated'; break;
		case 3: outcome = 'player_fled'; break;
		case 4: outcome = 'spared'; break;
		default:
			witcher.DisplayHudMessage("Krov: scenario must be 1 to 4.");
			return;
	}
	FindGameplayEntitiesInSphere(entities, witcher.GetWorldPosition(), 30.0, 1000, , FLAG_OnlyAliveActors);
	for (index = 0; index < entities.Size(); index += 1)
	{
		npc = (CNewNPC)entities[index];
		if (npc && npc.krov_encounterEnemyId == enemyId && npc.krov_encounterLabel != "" &&
			npc.krov_recordFightOutcome(outcome, true))
		{
			witcher.DisplayHudMessage("Krov test: " + NameToString(outcome));
			return;
		}
	}
	witcher.DisplayHudMessage("Krov: no active named enemy with that ID within 30 m.");
}

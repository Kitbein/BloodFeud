// Task 4. Keep combat observations on actors and completed encounters in the save.
@addField(CNewNPC)
public saved var krov_enemyIncarnation : int;

@addField(CNewNPC)
private var krov_fightObserved : bool;

@addField(CNewNPC)
private var krov_fightEnemyStart : Vector;

@addField(CNewNPC)
private var krov_fightPlayerStart : Vector;

@addField(CNewNPC)
private var krov_fightDamage : array<name>;

function krov_findEnemy(witcher : W3PlayerWitcher, enemyId : int) : int
{
	var index : int;

	for (index = witcher.krov_enemies.Size() - 1; index >= 0; index -= 1)
	{
		if (witcher.krov_enemies[index].id == enemyId)
			return index;
	}
	return -1;
}

// -2 means a return is pending and reserves this encounter for the survivor.
function krov_findReturn(witcher : W3PlayerWitcher, encounterTag : name, boundId : int) : int
{
	var index, day : int;
	var enemy : krov_enemy_record;

	day = GameTimeDays(theGame.GetGameTime());
	for (index = 0; index < witcher.krov_enemies.Size(); index += 1)
	{
		enemy = witcher.krov_enemies[index];
		if (enemy.lifeState == 'wounded' && enemy.encounterTag == encounterTag &&
			(boundId == 0 || enemy.id == boundId))
		{
			if (day >= enemy.returnDay)
				return index;
			return -2;
		}
	}
	return -1;
}

function krov_addGrudge(out enemy : krov_enemy_record, amount : int)
{
	enemy.grudge += amount;
	if (enemy.grudge > 100)
		enemy.grudge = 100;
}

function krov_promoteVeteran(out enemy : krov_enemy_record)
{
	enemy.rank = 'veteran';
	enemy.levelOffset = 2;
}

function krov_storeOutcome(witcher : W3PlayerWitcher, index : int, outcome : name,
	position : Vector, damageTypes : array<name>) : bool
{
	var enemy : krov_enemy_record;
	var meeting : krov_enemy_event;
	var chance : int;

	enemy = witcher.krov_enemies[index];
	if (enemy.lifeState != 'alive' && !(enemy.lifeState == 'wounded' && outcome == 'killed'))
		return false;

	meeting.outcome = outcome;
	meeting.location = position;
	meeting.region = theGame.GetCommonMapManager().GetAreaFromWorldPath(theGame.GetWorld().GetDepotPath(), true);
	meeting.gameDay = GameTimeDays(theGame.GetGameTime());
	meeting.playerDamageTypes = damageTypes;
	if (enemy.events.Size() >= 10)
		enemy.events.Erase(0);
	enemy.events.PushBack(meeting);

	switch (outcome)
	{
		case 'killed':
			enemy.lifeState = 'dead';
			enemy.returnDay = 0;
			break;
		case 'enemy_fled':
			krov_addGrudge(enemy, 20);
			enemy.lifeState = 'wounded';
			enemy.returnDay = meeting.gameDay + 1;
			if (damageTypes.Contains('igni'))
			{
				ArrayOfNamesPushBackUnique(enemy.scars, 'burn');
				krov_addMemoryNickname(enemy, 'burn');
			}
			else
			{
				ArrayOfNamesPushBackUnique(enemy.scars, 'battle_scar');
				krov_addMemoryNickname(enemy, 'battle_scar');
			}
			chance = 20 + enemy.grudge / 2;
			if (enemy.characterPrimary == 0 || enemy.characterPrimary == 5)
				chance += 15;
			else if (enemy.characterPrimary == 1)
				chance -= 10;
			if (RandRange(100) < chance)
				krov_promoteVeteran(enemy);
			break;
		case 'player_defeated':
			krov_addGrudge(enemy, 10);
			krov_promoteVeteran(enemy);
			krov_addMemoryNickname(enemy, 'witcher_slayer');
			break;
		case 'player_fled':
			krov_addGrudge(enemy, 5);
			break;
		case 'spared':
			krov_addGrudge(enemy, 5);
			break;
		default:
			return false;
	}

	witcher.krov_enemies[index] = enemy;
	LogChannel('Krov', "krov_outcome: id=" + IntToString(enemy.id) + " outcome=" +
		NameToString(outcome) + " day=" + IntToString(meeting.gameDay));
	return true;
}

@addMethod(CNewNPC)
public function krov_beginFight()
{
	var witcher : W3PlayerWitcher;
	var index : int;
	var enemy : krov_enemy_record;

	if (krov_encounterEnemyId <= 0 || krov_encounterLabel == "" || theGame.IsDialogOrCutscenePlaying())
		return;
	witcher = GetWitcherPlayer();
	if (!witcher || witcher != thePlayer || !witcher.IsAlive() ||
		GetAttitude(witcher) != AIA_Hostile || VecDistance(witcher.GetWorldPosition(), GetWorldPosition()) > 30.0)
		return;
	index = krov_findEnemy(witcher, krov_encounterEnemyId);
	if (index < 0)
	{
		krov_encounterLabel = "";
		return;
	}
	enemy = witcher.krov_enemies[index];
	if (enemy.lifeState != 'alive' || enemy.incarnation != krov_enemyIncarnation)
	{
		krov_encounterLabel = "";
		return;
	}
	// Task 3 records already linked to a vanilla NPC have no saved tag yet.
	if (enemy.encounterTag == '')
	{
		enemy.encounterTag = krov_velenEncounterTag(GetParentEncounter());
		witcher.krov_enemies[index] = enemy;
	}
	krov_fightObserved = false;
	krov_fightDamage.Clear();
}

@addMethod(CNewNPC)
public function krov_trackFight(witcher : W3PlayerWitcher)
{
	if (!krov_fightObserved)
	{
		krov_fightObserved = true;
		krov_fightEnemyStart = GetWorldPosition();
		krov_fightPlayerStart = witcher.GetWorldPosition();
	}
}

@addMethod(CNewNPC)
public function krov_rememberHit(witcher : W3PlayerWitcher, hit : W3DamageAction)
{
	var damage : array<SRawDamage>;
	var index : int;

	krov_trackFight(witcher);
	hit.GetDTs(damage);
	for (index = 0; index < damage.Size() && krov_fightDamage.Size() < 12; index += 1)
	{
		if (damage[index].dmgVal > 0)
		{
			ArrayOfNamesPushBackUnique(krov_fightDamage, damage[index].dmgType);
			if (hit.IsActionWitcherSign() && damage[index].dmgType == theGame.params.DAMAGE_NAME_FIRE &&
				krov_fightDamage.Size() < 12)
				ArrayOfNamesPushBackUnique(krov_fightDamage, 'igni');
		}
	}
}

@addMethod(CNewNPC)
public function krov_recordFightOutcome(outcome : name, optional simulated : bool) : bool
{
	var witcher : W3PlayerWitcher;
	var index : int;
	var enemy : krov_enemy_record;

	witcher = GetWitcherPlayer();
	if (!witcher || witcher != thePlayer || krov_encounterEnemyId <= 0)
		return false;
	index = krov_findEnemy(witcher, krov_encounterEnemyId);
	if (index < 0 || witcher.krov_enemies[index].incarnation != krov_enemyIncarnation)
		return false;
	enemy = witcher.krov_enemies[index];
	if (enemy.encounterTag == '')
	{
		enemy.encounterTag = krov_velenEncounterTag(GetParentEncounter());
		if (enemy.encounterTag == '')
			return false;
		witcher.krov_enemies[index] = enemy;
	}
	if (!krov_storeOutcome(witcher, index, outcome, GetWorldPosition(), krov_fightDamage))
		return false;
	krov_fightObserved = false;
	krov_fightDamage.Clear();
	enemy = witcher.krov_enemies[index];
	if (enemy.lifeState == 'wounded' || enemy.lifeState == 'dead')
		krov_encounterLabel = "";
	else
		krov_encounterLabel = krov_encounterTitle(enemy);
	if (simulated)
		LogChannel('Krov', "krov_enemy_test: simulated id=" + IntToString(enemy.id));
	return true;
}

@addMethod(CNewNPC)
public function krov_finishDisengagement()
{
	var witcher : W3PlayerWitcher;
	var enemyMoved, playerMoved : float;

	if (!krov_fightObserved || !IsAlive() || krov_encounterLabel == "")
		return;
	krov_fightObserved = false;
	witcher = GetWitcherPlayer();
	if (!witcher || witcher != thePlayer || !witcher.IsAlive() || theGame.IsDialogOrCutscenePlaying())
		return;
	if (VecDistance(witcher.GetWorldPosition(), GetWorldPosition()) >= 25.0)
	{
		enemyMoved = VecDistance(krov_fightEnemyStart, GetWorldPosition());
		playerMoved = VecDistance(krov_fightPlayerStart, witcher.GetWorldPosition());
		if (enemyMoved >= 18.0 && playerMoved <= 9.0 && GetCanFlee())
			krov_recordFightOutcome('enemy_fled');
		else if (playerMoved >= 18.0 && enemyMoved <= 9.0)
			krov_recordFightOutcome('player_fled');
	}
	krov_fightDamage.Clear();
}

@wrapMethod(W3DamageManagerProcessor)
function ProcessAction(act : W3DamageAction)
{
	var witcher : W3PlayerWitcher;
	var victim, attacker : CActor;
	var namedVictim, namedAttacker : CNewNPC;
	var wasAlive : bool;
	var healthBefore : float;

	if (act && act.victim && !act.GetSimulateOnly())
	{
		victim = (CActor)act.victim;
		attacker = (CActor)act.attacker;
		namedVictim = (CNewNPC)victim;
		namedAttacker = (CNewNPC)attacker;
		if ((namedVictim && namedVictim.krov_encounterEnemyId > 0) ||
			(namedAttacker && namedAttacker.krov_encounterLabel != ""))
		{
			witcher = GetWitcherPlayer();
			if (witcher && witcher == thePlayer && victim && !theGame.IsDialogOrCutscenePlaying())
			{
				wasAlive = victim.IsAlive();
				healthBefore = victim.GetHealthPercents();
			}
		}
	}

	wrappedMethod(act);
	if (!wasAlive)
		return;

	if (namedVictim && namedVictim.krov_encounterEnemyId > 0)
	{
		if (namedVictim.krov_encounterLabel != "" && attacker == witcher &&
			(!victim.IsAlive() || victim.GetHealthPercents() < healthBefore))
			namedVictim.krov_rememberHit(witcher, act);
		if (!victim.IsAlive())
			namedVictim.krov_recordFightOutcome('killed');
	}
	else if (victim == witcher && namedAttacker && namedAttacker.krov_encounterLabel != "")
	{
		if (!witcher.IsAlive())
			namedAttacker.krov_recordFightOutcome('player_defeated');
		else if (witcher.GetHealthPercents() < healthBefore)
			namedAttacker.krov_trackFight(witcher);
	}
}

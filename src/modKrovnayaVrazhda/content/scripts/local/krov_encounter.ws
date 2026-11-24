// Task 3. Promote existing actors from an explicit list of rural Velen encounters.
@addField(CNewNPC)
public saved var krov_encounterEnemyId : int;

@addField(CNewNPC)
public saved var krov_encounterRolled : bool;

@addField(CNewNPC)
public saved var krov_encounterLabel : string;

@addField(W3PlayerWitcher)
public var krov_forceEncounterRoll : bool;

function krov_velenEncounterTag(encounter : CEncounter) : name
{
	if (!encounter)
		return '';

	// Exact CEncounter tags from the corresponding vanilla world layers.
	if (encounter.HasTag('enc_lw_sb12_road_ambush'))
		return 'enc_lw_sb12_road_ambush';
	if (encounter.HasTag('nml_cp37_bandits_enc'))
		return 'nml_cp37_bandits_enc';
	if (encounter.HasTag('lw_sb20_treasure_chest_encounter'))
		return 'lw_sb20_treasure_chest_encounter';

	return '';
}

// Run only for eligible combat entries. Keep at most one named NPC from this
// encounter and at most two live named NPCs in the local search radius.
function krov_hasEncounterCapacity(witcher : W3PlayerWitcher, encounter : CEncounter, candidate : CNewNPC) : bool
{
	var entities : array<CGameplayEntity>;
	var npc : CNewNPC;
	var index, nearby : int;

	FindGameplayEntitiesInSphere(entities, witcher.GetWorldPosition(), 60.0, 1000, , FLAG_OnlyAliveActors);
	for (index = 0; index < entities.Size(); index += 1)
	{
		npc = (CNewNPC)entities[index];
		if (npc && npc != candidate && npc.krov_encounterEnemyId > 0 && npc.krov_encounterLabel != "")
		{
			nearby += 1;
			if (nearby >= 2 || npc.GetParentEncounter() == encounter)
				return false;
		}
	}
	return true;
}

@wrapMethod(CNewNPC)
function OnCombatModeSet(toggle : bool)
{
	wrappedMethod(toggle);
	if (toggle)
	{
		krov_tryEncounterPromotion();
		krov_beginFight();
	}
	else
		krov_finishDisengagement();
}

@addMethod(CNewNPC)
private function krov_tryEncounterPromotion()
{
	var witcher : W3PlayerWitcher;
	var encounter : CEncounter;
	var faction : name;
	var encounterTag : name;
	var distance : float;
	var enemy : krov_enemy_record;
	var returnIndex : int;

	if (!IsAlive() || !IsHuman() || GetNPCType() != ENGT_Enemy || IsVIP())
		return;
	if (theGame.IsDialogOrCutscenePlaying())
		return;
	witcher = GetWitcherPlayer();
	if (!witcher || witcher != thePlayer || GetAttitude(witcher) != AIA_Hostile)
		return;
	if (witcher.IsFistFightMinigameEnabled())
		return;
	if (theGame.GetWorld().GetDepotPath() != "levels\novigrad\novigrad.w2w")
		return;

	encounter = GetParentEncounter();
	encounterTag = krov_velenEncounterTag(encounter);
	if (encounterTag == '')
		return;
	faction = 'bandits';
	if (encounterTag == 'enc_lw_sb12_road_ambush')
		faction = 'deserters';

	// A nearby hostile who has engaged Geralt is noticeable. At very close
	// range the combat-mode event can precede the assignment of the AI target.
	distance = VecDistance(witcher.GetWorldPosition(), GetWorldPosition());
	if (distance > 25.0 || (distance > 10.0 && GetTarget() != witcher))
		return;

	if (krov_encounterEnemyId > 0 && krov_encounterLabel != "")
		return;
	if (!krov_hasEncounterCapacity(witcher, encounter, this))
		return;

	returnIndex = krov_findReturn(witcher, encounterTag, krov_encounterEnemyId);
	if (returnIndex == -2)
		return;
	if (returnIndex >= 0)
	{
		enemy = witcher.krov_enemies[returnIndex];
		enemy.lifeState = 'alive';
		enemy.returnDay = 0;
		enemy.incarnation += 1;
		witcher.krov_enemies[returnIndex] = enemy;
		krov_bindEnemy(witcher, enemy);
		witcher.DisplayHudMessage(krov_returnNotice(enemy));
		LogChannel('Krov', "krov_return: id=" + IntToString(enemy.id) + " rank=" + NameToString(enemy.rank));
		return;
	}
	if (krov_encounterRolled || witcher.krov_enemies.Size() >= 256 || witcher.krov_lastEnemyId >= 2147483647)
		return;

	krov_encounterRolled = true;
	if (!witcher.krov_forceEncounterRoll && RandRange(100) >= 30)
		return;

	witcher.krov_lastEnemyId += 1;
	if (faction == 'deserters')
		enemy = krov_makeEnemy(witcher.krov_lastEnemyId, 'temeria');
	else
		enemy = krov_makeEnemy(witcher.krov_lastEnemyId, 'redania');
	enemy.id = witcher.krov_lastEnemyId;
	enemy.faction = faction;
	enemy.levelOffset = 1;
	enemy.encounterTag = encounterTag;
	witcher.krov_enemies.PushBack(enemy);
	krov_bindEnemy(witcher, enemy);
	witcher.DisplayHudMessage(krov_encounterNotice(enemy));

	LogChannel('Krov', "krov_encounter: id=" + IntToString(enemy.id) +
		" encounter=" + encounter.GetTagsString() + " level=" + IntToString(GetLevelFromLocalVar()) +
		" name=" + enemy.givenName + " character=" + krov_characterLabel(enemy.characterPrimary, false) +
		" strength=" + krov_strengthLabel(enemy.strengthPrimary, false) +
		" weakness=" + krov_weaknessLabel(enemy.weaknessPrimary, false));
}

@addMethod(CNewNPC)
private function krov_bindEnemy(witcher : W3PlayerWitcher, enemy : krov_enemy_record)
{
	var targetLevel : int;

	krov_encounterRolled = true;
	krov_encounterEnemyId = enemy.id;
	krov_enemyIncarnation = enemy.incarnation;
	krov_encounterLabel = krov_encounterTitle(enemy);
	targetLevel = witcher.GetLevel() + enemy.levelOffset;
	if (targetLevel > 100)
		targetLevel = 100;
	// Use the same level recalculation as vanilla spawn initializers.
	if (GetLevelFromLocalVar() != targetLevel)
		SetLevel(targetLevel);
}

@wrapMethod(CR4HudModuleEnemyFocus)
function UpdateName(enemyName : string)
{
	var npc : CNewNPC;

	// Vanilla has already selected this target. Only change its HUD label.
	npc = (CNewNPC)m_lastTarget;
	if (npc && npc.krov_encounterEnemyId > 0 && !theGame.IsDialogOrCutscenePlaying())
		enemyName = npc.krov_encounterLabel;
	wrappedMethod(enemyName);
}

// Session-only test switch. All eligibility checks and caps still apply.
exec function krov_encounter_test(enabled : bool)
{
	var witcher : W3PlayerWitcher;

	witcher = GetWitcherPlayer();
	if (!witcher)
		return;
	witcher.krov_forceEncounterRoll = enabled;
	witcher.DisplayHudMessage(krov_encounterTestNotice(enabled));
}

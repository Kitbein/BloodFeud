// Task 2. Save data only. The records hold no references to actors or world objects.
struct krov_enemy_event
{
	saved var outcome : name;
	saved var playerDamageTypes : array<name>;
	saved var location : Vector;
	saved var region : name;
	saved var gameDay : int;
}

struct krov_enemy_record
{
	saved var id : int;
	saved var seed : int;
	saved var culture : int;
	saved var givenName : string;
	saved var templatePath : string;
	saved var enemyType : name;
	saved var faction : name;
	saved var rank : name;
	saved var levelOffset : int;
	saved var characterPrimary : int;
	saved var characterSecondary : int;
	saved var strengthPrimary : int;
	saved var strengthSecondary : int;
	saved var weaknessPrimary : int;
	saved var weaknessSecondary : int;
	saved var scars : array<name>;
	saved var nicknames : array<string>;
	saved var events : array<krov_enemy_event>;
	saved var grudge : int;
	saved var lifeState : name;
	saved var superiorId : int;
	saved var rivals : array<int>;
	saved var groupId : int;
	saved var spotId : int;
	saved var encounterTag : name;
	saved var returnDay : int;
	saved var incarnation : int;
}

@addField(W3PlayerWitcher)
public saved var krov_enemies : array<krov_enemy_record>;

@addField(W3PlayerWitcher)
public saved var krov_lastEnemyId : int;

// Use a private random sequence. Multiplication fits into a signed 32-bit int.
function krov_enemyRoll(out randomState : int, count : int) : int
{
	randomState = (randomState * 16807) % 65521;
	return randomState % count;
}

// A secondary trait is optional and always different from the first.
function krov_enemySecondTrait(out randomState : int, first : int) : int
{
	if (krov_enemyRoll(randomState, 2) == 0)
		return -1;
	return (first + 1 + krov_enemyRoll(randomState, 5)) % 6;
}

function krov_enemyTemplate(culture : int, variant : int) : string
{
	var templates : array<string>;

	// Depot paths verified in vanilla content0/bundles/blob.bundle.
	switch (culture)
	{
		case 0:
			templates.PushBack("nml_deserters_axe_normal");
			templates.PushBack("nml_deserters_bow");
			templates.PushBack("nml_deserters_sword_easy");
			break;
		case 1:
			templates.PushBack("novigrad_bandit_1haxe");
			templates.PushBack("novigrad_bandit_1hblunt");
			templates.PushBack("novigrad_bandit_sword");
			break;
		case 2:
			templates.PushBack("nilfgaardian_deserter_bow");
			templates.PushBack("nilfgaardian_deserter_shield");
			templates.PushBack("nilfgaardian_deserter_sword_hard");
			break;
		case 3:
			templates.PushBack("skellige_bandit_axe1h_normal");
			templates.PushBack("skellige_bandit_blunt_normal");
			templates.PushBack("skellige_bandit_sword_normal");
			break;
	}
	return "living_world\\enemy_templates\\" + templates[variant] + ".w2ent";
}

// Accept a positive seed. Store generated values to keep existing records stable.
function krov_makeEnemy(seed : int, optional northernCulture : name) : krov_enemy_record
{
	var enemy : krov_enemy_record;
	var names : array<string>;
	var randomState : int;
	var variant : int;

	randomState = ((seed - 1) % 65520) + 1;
	enemy.seed = seed;
	enemy.culture = krov_enemyRoll(randomState, 4);
	if (northernCulture == 'temeria')
		enemy.culture = 0;
	else if (northernCulture == 'redania')
		enemy.culture = 1;
	krov_loadNames(enemy.culture, names);
	variant = krov_enemyRoll(randomState, names.Size());
	enemy.givenName = names[variant];
	variant = krov_enemyRoll(randomState, 3);
	enemy.templatePath = krov_enemyTemplate(enemy.culture, variant);
	enemy.enemyType = 'human';
	enemy.faction = 'deserters';
	if (enemy.culture == 1 || enemy.culture == 3)
		enemy.faction = 'bandits';
	enemy.rank = 'fighter';
	enemy.lifeState = 'alive';
	enemy.characterPrimary = krov_enemyRoll(randomState, 6);
	enemy.characterSecondary = krov_enemySecondTrait(randomState, enemy.characterPrimary);
	enemy.strengthPrimary = krov_enemyRoll(randomState, 6);
	enemy.strengthSecondary = krov_enemySecondTrait(randomState, enemy.strengthPrimary);
	enemy.weaknessPrimary = krov_enemyRoll(randomState, 6);
	enemy.weaknessSecondary = krov_enemySecondTrait(randomState, enemy.weaknessPrimary);
	// Zero IDs mean no links. New records start with empty history and zero grudge.
	return enemy;
}

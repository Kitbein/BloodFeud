// Task 2. Russian debug labels are transliterated to keep scripts ASCII.
// Task 3-4. Fights and nicknames use the same HUD title.
function krov_encounterTitle(enemy : krov_enemy_record) : string
{
	var title : string;

	title = enemy.givenName;
	if (enemy.nicknames.Size() > 0)
		title += " " + enemy.nicknames[enemy.nicknames.Size() - 1];
	if (enemy.rank == 'veteran')
		return title + " (Veteran)";
	return title + " (Boets)";
}

function krov_addMemoryNickname(out enemy : krov_enemy_record, story : name)
{
	var nickname : string;

	switch (story)
	{
		case 'burn':
			nickname = "Obozhzhennyi";
			break;
		case 'battle_scar':
			nickname = "Mechenyi";
			break;
		case 'witcher_slayer':
			nickname = "Ubiitsa vedmakov";
			break;
	}
	if (nickname != "" && !enemy.nicknames.Contains(nickname))
		enemy.nicknames.PushBack(nickname);
}

function krov_returnNotice(enemy : krov_enemy_record) : string
{
	return "Vernulsya: " + krov_encounterTitle(enemy);
}

function krov_encounterNotice(enemy : krov_enemy_record) : string
{
	return krov_encounterTitle(enemy) + ": " +
		krov_characterLabel(enemy.characterPrimary, false) + ", " +
		krov_strengthLabel(enemy.strengthPrimary, false) + ".";
}

function krov_encounterTestNotice(enabled : bool) : string
{
	if (enabled)
		return "Krov: encounter test chance 100%.";
	return "Krov: encounter test chance 30%.";
}

function krov_loadNames(culture : int, out names : array<string>)
{
	switch (culture)
	{
		case 0:
			names.PushBack("Aldert");
			names.PushBack("Alwin");
			names.PushBack("Ansel");
			names.PushBack("Arlen");
			names.PushBack("Artur");
			names.PushBack("Berent");
			names.PushBack("Bodek");
			names.PushBack("Borin");
			names.PushBack("Brand");
			names.PushBack("Cedric");
			names.PushBack("Cenek");
			names.PushBack("Dalen");
			names.PushBack("Davor");
			names.PushBack("Edric");
			names.PushBack("Erwin");
			names.PushBack("Faron");
			names.PushBack("Folt");
			names.PushBack("Gavren");
			names.PushBack("Goran");
			names.PushBack("Havel");
			names.PushBack("Ivor");
			names.PushBack("Jarom");
			names.PushBack("Jarek");
			names.PushBack("Jost");
			names.PushBack("Karel");
			names.PushBack("Konrad");
			names.PushBack("Leof");
			names.PushBack("Marcin");
			names.PushBack("Marek");
			names.PushBack("Miro");
			names.PushBack("Olek");
			names.PushBack("Oskar");
			names.PushBack("Radek");
			names.PushBack("Radan");
			names.PushBack("Rurik");
			names.PushBack("Tadej");
			names.PushBack("Velenor");
			names.PushBack("Vidar");
			names.PushBack("Witek");
			names.PushBack("Zoren");
			break;
		case 1:
			names.PushBack("Adalbert");
			names.PushBack("Albrecht");
			names.PushBack("Alric");
			names.PushBack("Ansholt");
			names.PushBack("Bastian");
			names.PushBack("Bertold");
			names.PushBack("Brun");
			names.PushBack("Caspar");
			names.PushBack("Cuno");
			names.PushBack("Degen");
			names.PushBack("Dieter");
			names.PushBack("Eckart");
			names.PushBack("Eike");
			names.PushBack("Eldric");
			names.PushBack("Falk");
			names.PushBack("Franz");
			names.PushBack("Gerwin");
			names.PushBack("Gisel");
			names.PushBack("Gunter");
			names.PushBack("Hagen");
			names.PushBack("Hartwin");
			names.PushBack("Heiko");
			names.PushBack("Henric");
			names.PushBack("Holm");
			names.PushBack("Ingo");
			names.PushBack("Isebrand");
			names.PushBack("Janek");
			names.PushBack("Jochen");
			names.PushBack("Karl");
			names.PushBack("Klaus");
			names.PushBack("Lothar");
			names.PushBack("Ludek");
			names.PushBack("Manfred");
			names.PushBack("Norbert");
			names.PushBack("Otto");
			names.PushBack("Reimar");
			names.PushBack("Rolf");
			names.PushBack("Siegfried");
			names.PushBack("Ulrich");
			names.PushBack("Wenzel");
			break;
		case 2:
			names.PushBack("Aedran");
			names.PushBack("Albaro");
			names.PushBack("Alvaro");
			names.PushBack("Amadis");
			names.PushBack("Ardal");
			names.PushBack("Arno");
			names.PushBack("Balian");
			names.PushBack("Berengar");
			names.PushBack("Brano");
			names.PushBack("Cassian");
			names.PushBack("Ceallach");
			names.PushBack("Cahir");
			names.PushBack("Caron");
			names.PushBack("Cedran");
			names.PushBack("Corvyn");
			names.PushBack("Darien");
			names.PushBack("Dario");
			names.PushBack("Dervan");
			names.PushBack("Eamon");
			names.PushBack("Egan");
			names.PushBack("Emric");
			names.PushBack("Esteban");
			names.PushBack("Farlan");
			names.PushBack("Ferran");
			names.PushBack("Gaelan");
			names.PushBack("Galvar");
			names.PushBack("Gervan");
			names.PushBack("Ilar");
			names.PushBack("Ivar");
			names.PushBack("Joren");
			names.PushBack("Lorcan");
			names.PushBack("Lucan");
			names.PushBack("Marvan");
			names.PushBack("Morvyn");
			names.PushBack("Niall");
			names.PushBack("Odran");
			names.PushBack("Orsino");
			names.PushBack("Renvar");
			names.PushBack("Severin");
			names.PushBack("Tervan");
			break;
		case 3:
			names.PushBack("Agnar");
			names.PushBack("Arnbjorn");
			names.PushBack("Arvid");
			names.PushBack("Asgeir");
			names.PushBack("Audun");
			names.PushBack("Bard");
			names.PushBack("Bjarke");
			names.PushBack("Bjorn");
			names.PushBack("Bragi");
			names.PushBack("Dag");
			names.PushBack("Einar");
			names.PushBack("Eirik");
			names.PushBack("Eldgrim");
			names.PushBack("Erland");
			names.PushBack("Finn");
			names.PushBack("Frode");
			names.PushBack("Geir");
			names.PushBack("Gorm");
			names.PushBack("Grim");
			names.PushBack("Gudmund");
			names.PushBack("Gunnar");
			names.PushBack("Halfdan");
			names.PushBack("Hakon");
			names.PushBack("Halvard");
			names.PushBack("Harald");
			names.PushBack("Hjalmar");
			names.PushBack("Holger");
			names.PushBack("Ingvar");
			names.PushBack("Ketil");
			names.PushBack("Knut");
			names.PushBack("Leif");
			names.PushBack("Njal");
			names.PushBack("Odd");
			names.PushBack("Orm");
			names.PushBack("Ragnar");
			names.PushBack("Ragnvald");
			names.PushBack("Sigurd");
			names.PushBack("Sten");
			names.PushBack("Torvald");
			names.PushBack("Ulf");
			break;
	}
}

function krov_cultureLabel(index : int, english : bool) : string
{
	switch (index)
	{
		case 0:
			if (english)
				return "Temeria";
			return "Temeriya";
		case 1:
			if (english)
				return "Redania";
			return "Redaniya";
		case 2:
			if (english)
				return "Nilfgaard";
			return "Nilfgaard";
		case 3:
			if (english)
				return "Skellige";
			return "Skellige";
	}
	return "-";
}

function krov_characterLabel(index : int, english : bool) : string
{
	switch (index)
	{
		case 0:
			if (english)
				return "proud";
			return "gordets";
		case 1:
			if (english)
				return "cowardly";
			return "trus";
		case 2:
			if (english)
				return "greedy";
			return "zhadina";
		case 3:
			if (english)
				return "fanatical";
			return "fanatik";
		case 4:
			if (english)
				return "sadistic";
			return "sadist";
		case 5:
			if (english)
				return "honorable";
			return "chestnyi boets";
	}
	return "-";
}

function krov_strengthLabel(index : int, english : bool) : string
{
	switch (index)
	{
		case 0:
			if (english)
				return "heavy armor";
			return "tyazhelaya bronya";
		case 1:
			if (english)
				return "Axii resistance";
			return "ustoichivost k Aksiyu";
		case 2:
			if (english)
				return "poison resistance";
			return "ustoichivost k yadu";
		case 3:
			if (english)
				return "strong guard";
			return "krepkii blok";
		case 4:
			if (english)
				return "quick recovery";
			return "bystroe vosstanovlenie";
		case 5:
			if (english)
				return "fire resistance";
			return "ustoichivost k ognyu";
	}
	return "-";
}

function krov_weaknessLabel(index : int, english : bool) : string
{
	switch (index)
	{
		case 0:
			if (english)
				return "bleeding";
			return "krovotechenie";
		case 1:
			if (english)
				return "frost";
			return "kholod";
		case 2:
			if (english)
				return "bomb shock";
			return "oglushenie bombami";
		case 3:
			if (english)
				return "crossbow bolts";
			return "arbaletnye bolty";
		case 4:
			if (english)
				return "Yrden";
			return "Irden";
		case 5:
			if (english)
				return "stamina pressure";
			return "poterya vynoslivosti";
	}
	return "-";
}

// Task 5. Two clues advance a demonstration stage. No combat or quest state is altered.
function krov_uiProgress() : string
{
	var count : int;
	count = FactsQuerySum("krov_ui_demo_clues");
	if (count >= 2)
		return krov_uiText('ready') + IntToString(count) + "/2";
	return krov_uiText('clues') + IntToString(count) + "/2";
}

exec function krov_ui_step(count : int)
{
	if (!GetWitcherPlayer()) return;
	if (count < 0 || count > 2) return;
	if (count == 0)
		FactsRemove("krov_ui_demo_clues");
	else
		FactsSet("krov_ui_demo_clues", count);
	GetWitcherPlayer().DisplayHudMessage(krov_uiProgress());
	LogChannel('Krov', "krov_ui_step " + krov_uiProgress());
}

exec function krov_ui_journal()
{
	if (!GetWitcherPlayer()) return;
	// Dynamic strings are already localized; the popup must not look them up as keys.
	theGame.GetGuiManager().ShowUserDialogAdv(0, krov_uiText('title'), krov_uiProgress(), false, UDB_Ok);
	LogChannel('Krov', "krov_ui_journal " + krov_uiProgress());
}

// The menu saves TOGGLE values as true/false. Older defaults were numeric.
function krov_uiNotifyValue() : string
{
	var config : CInGameConfigWrapper;
	var value : string;

	config = theGame.GetInGameConfigWrapper();
	if (config.GetVarsNumByGroupName('krov_ui') == 0)
		return "";

	value = config.GetVarValue('krov_ui', 'krov_ui_notify');
	if (value == "true" || value == "1")
		return "1";
	if (value == "false" || value == "0")
		return "0";
	return value;
}

exec function krov_ui_config()
{
	var value : string;
	if (!GetWitcherPlayer()) return;
	value = krov_uiNotifyValue();
	if (value == "") value = krov_uiText('missing');
	GetWitcherPlayer().DisplayHudMessage(krov_uiText('config') + value);
	LogChannel('Krov', "krov_ui_config " + value);
}

exec function krov_ui_notify()
{
	var value : string;
	if (!GetWitcherPlayer()) return;
	value = krov_uiNotifyValue();
	if (value == "1")
		GetWitcherPlayer().DisplayHudMessage(krov_uiText('demo'));
	LogChannel('Krov', "krov_ui_notify setting=" + value);
}

// Only the demo flag is saved. Each opening positions the sample near the current player.
exec function krov_ui_map(enabled : int)
{
	if (!GetWitcherPlayer()) return;
	if (enabled == 1)
	{
		FactsSet("krov_ui_demo_map", 1);
		GetWitcherPlayer().DisplayHudMessage(krov_uiText('mapOn'));
	}
	else if (enabled == 0)
	{
		FactsRemove("krov_ui_demo_map");
		GetWitcherPlayer().DisplayHudMessage(krov_uiText('mapOff'));
	}
}

@wrapMethod(CR4MapMenu)
function UpdateEntityPins(out flashArray : CScriptedFlashArray) : void
{
	var pin : CScriptedFlashObject;
	var center : Vector;
	var area : name;
	wrappedMethod(flashArray);
	if (!IsCurrentAreaShown() || FactsQuerySum("krov_ui_demo_map") != 1 || !GetWitcherPlayer()) return;
	area = GetShownMapType();
	center = thePlayer.GetWorldPosition();
	center.X += 120.0;
	pin = GetMenuFlashValueStorage().CreateTempFlashObject("red.game.witcher3.data.StaticMapPinData");
	pin.SetMemberFlashUInt("id", NameToFlashUInt('krov_ui_search_pin'));
	pin.SetMemberFlashUInt("areaId", NameToFlashUInt(area));
	pin.SetMemberFlashUInt("journalAreaId", NameToFlashUInt(theGame.GetCommonMapManager().GetJournalAreaByPosition(area, center)));
	pin.SetMemberFlashNumber("posX", center.X);
	pin.SetMemberFlashNumber("posY", center.Y);
	pin.SetMemberFlashString("type", "BanditCamp");
	pin.SetMemberFlashString("filteredType", "BanditCamp");
	pin.SetMemberFlashString("label", krov_uiText('area'));
	pin.SetMemberFlashString("description", krov_uiText('radius'));
	pin.SetMemberFlashNumber("radius", 60.0);
	pin.SetMemberFlashBool("isFastTravel", false);
	pin.SetMemberFlashBool("isQuest", false);
	pin.SetMemberFlashBool("isPlayer", false);
	pin.SetMemberFlashBool("isUserPin", false);
	pin.SetMemberFlashNumber("distance", VecDistanceSquared2D(thePlayer.GetWorldPosition(), center));
	flashArray.PushBackFlashObject(pin);
	LogChannel('Krov', "krov_ui_map: submitted marker, radius=60");
}

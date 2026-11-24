// Task 3 test navigation. Use the vanilla map marker instead of teleporting.
// Run the same command again to toggle the marker off.
exec function krov_encounter_pin(site : int)
{
	var witcher : W3PlayerWitcher;
	var manager : CCommonMapManager;
	var worldPath : string;
	var position : Vector;
	var idToAdd, idToRemove : int;

	witcher = GetWitcherPlayer();
	if (!witcher || witcher != thePlayer)
		return;

	worldPath = theGame.GetWorld().GetDepotPath();
	if (worldPath != "levels\novigrad\novigrad.w2w")
	{
		witcher.DisplayHudMessage("Krov: load a Velen save first.");
		return;
	}

	// XY from the transforms of the three vanilla CEncounter entities.
	switch (site)
	{
		case 1:
			position = Vector(-44.6, 258.7, 0.0);
			break;
		case 2:
			position = Vector(-540.8, 16.6, 0.0);
			break;
		case 3:
			position = Vector(-519.8, -192.8, 0.0);
			break;
		default:
			witcher.DisplayHudMessage("Krov: choose site 1, 2 or 3.");
			return;
	}

	manager = theGame.GetCommonMapManager();
	// Same request as placing a regular waypoint in the world map menu.
	if (manager.ToggleUserMapPin(manager.GetAreaFromWorldPath(worldPath, true),
		position, 0, false, true, idToAdd, idToRemove))
		witcher.DisplayHudMessage("Krov: waypoint toggled. Check the world map.");
	else
		witcher.DisplayHudMessage("Krov: waypoint could not be changed.");
}

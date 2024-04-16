//Resident Evil 2 Remake Autosplitter
//By CursedToast 1/28/2019
//Last updated 08/26/2023
//New Pointers by VideoGameRoulette & DeathHound

state("re2"){}

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
	vars.Helper.Settings.CreateFromXml("Components/RE2make.Settings.xml");
}

init
{
    // Initialize Version
    vars.inventoryPtr = IntPtr.Zero;
	
	IntPtr TimelineEventManager = vars.Helper.ScanRel(3, "48 8b 15 ?? ?? ?? ?? 48 39 78 ?? 0f 85 ?? ?? ?? ?? 48 85 d2 74 ?? 48 8b cb e8 ?? ?? ?? ?? 0f b6 c8");
	IntPtr InventoryManager = vars.Helper.ScanRel(3, "48 8b 3d ?? ?? ?? ?? 48 83 78 ?? ?? 0f 85 ?? ?? ?? ?? 48 85 ff 0f 84");
	IntPtr GameClock = vars.Helper.ScanRel(3, "48 8b 05 ?? ?? ?? ?? 48 85 c0 75 ?? 45 33 c0 8d 50 ?? 48 8b cd e8 ?? ?? ?? ?? eb");
	IntPtr EnvironmentStandbyManager = vars.Helper.ScanRel(3, "48 8b 15 ?? ?? ?? ?? 48 8b cb 48 85 d2 0f 84 ?? ?? ?? ?? 41 b1 ?? c6 44 24");
	IntPtr MainFlowManager = vars.Helper.ScanRel(3, "48 8b 15 ?? ?? ?? ?? 48 8b cf 8b b3");
	IntPtr SurvivorManager = vars.Helper.ScanRel(3, "48 8b 2d ?? ?? ?? ?? 48 85 ed 75 ?? 45 33 c0 8d 55 ?? 48 8b cf");
	
	vars.Helper["EventID"] = vars.Helper.MakeString(TimelineEventManager, 0xA8, 0x20, 0x14);
	vars.Helper["EventID"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	vars.Helper["isGame"] = vars.Helper.Make<bool>(GameClock, 0x50);
	vars.Helper["GameElapsedTime"] = vars.Helper.Make<long>(GameClock, 0x60, 0x18);
	vars.Helper["DemoSpendingTime"] = vars.Helper.Make<long>(GameClock, 0x60, 0x20);
	vars.Helper["PauseSpendingTime"] = vars.Helper.Make<long>(GameClock, 0x60, 0x30);
	vars.Helper["MapID"] = vars.Helper.Make<short>(EnvironmentStandbyManager, 0xA8, 0x10);
	vars.Helper["SurvivorType"] = vars.Helper.Make<byte>(SurvivorManager, 0x50, 0x54);
	
	vars.Inv = InventoryManager;
	
	vars.completedSplits = new HashSet<string>();
	
	current.item = new int[20].Select((_, i)
		=> new DeepPointer(vars.Inv, 0x50, 0x98, 0x10, 0x20 + (i * 8), 0x18, 0x10, 0x10).Deref<int>(game))
		.ToArray();
		
	current.weapon = new int[20].Select((_, i)
		=> new DeepPointer(vars.Inv, 0x50, 0x98, 0x10, 0x20 + (i * 8), 0x18, 0x10, 0x14).Deref<int>(game))
		.ToArray();

}

update
{
	vars.Helper.Update();
	vars.Helper.MapPointers();
	
	current.item = new int[20].Select((_, i)
		=> new DeepPointer(vars.Inv, 0x50, 0x98, 0x10, 0x20 + (i * 8), 0x18, 0x10, 0x10).Deref<int>(game))
		.ToArray();
		
	current.weapon = new int[20].Select((_, i)
		=> new DeepPointer(vars.Inv, 0x50, 0x98, 0x10, 0x20 + (i * 8), 0x18, 0x10, 0x14).Deref<int>(game))
		.ToArray();

	if(!string.IsNullOrEmpty(current.EventID)){
        current.Event = current.EventID.Substring(2,3);
    }
	
	if(string.IsNullOrEmpty(current.EventID)){
        current.Event = "";
    }
	
	print(current.SurvivorType.ToString());
}

onStart
{
	vars.completedSplits.Clear();
}

start
{
	return current.Event != old.Event && old.Event == "001" || current.Event != old.Event && old.Event == "910";
}

split
{
	string setting = "";
	
	int[] currentItem = (current.item as int[]);
	int[] oldItem = (old.item as int[]);

	int[] currentWeapon = (current.weapon as int[]);
	int[] oldWeapon = (old.weapon as int[]);
	
	if(!currentItem.SequenceEqual(oldItem)){
		int[] delta = (currentItem as int[]).Where((v, i) => v != oldItem[i]).ToArray();

		foreach (int item in delta){
			if(item != 0 && current.SurvivorType != 2){
				setting = "Item_" + item;
			}
		}
	}
	
	if(!currentWeapon.SequenceEqual(oldWeapon)){
		int[] delta = (currentWeapon as int[]).Where((v, i) => v != oldWeapon[i]).ToArray();

		foreach (int weapon in delta){
			if(weapon != 0 && weapon != -1){
				setting = "Weapon_" + weapon;
			}
		}
	}

	if(current.MapID != old.MapID){
		setting = "Map_" + current.MapID;
	}
	
	if(current.EventID != old.EventID && !string.IsNullOrEmpty(current.EventID)){
		setting = "Event_" + current.Event;
	}
	
	// Debug. Comment out before release.
    //if (!string.IsNullOrEmpty(setting))
    //vars.Log(setting);

	if (settings.ContainsKey(setting) && settings[setting] && vars.completedSplits.Add(setting)){
		return true;
	}
}

gameTime
{
	return TimeSpan.FromSeconds((current.GameElapsedTime - current.DemoSpendingTime - current.PauseSpendingTime) / 1000000.0);
}

isLoading
{
    return true;
}

reset
{
	return current.Event != old.Event && current.Event == "011" || current.Event != old.Event && current.Event == "910";
}

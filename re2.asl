//Resident Evil 2 Remake Autosplitter
//By CursedToast 1/28/2019
//By VideoGameRoulette & DeathHound 08/26/2023
//Sigscans/Rework by TheDementedSalad 
//Last updated 01 May 2024

state("re2"){}

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
	vars.Helper.Settings.CreateFromXml("Components/RE2make.Settings.xml");
	//vars.Helper.StartFileLogger("RE2R_Log.txt");
	
	vars.PendingSplits = 0;
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
	IntPtr FadeManager = vars.Helper.ScanRel(3, "48 8b 15 ?? ?? ?? ?? 45 33 c0 48 8b cb 48 85 d2 74 ?? f3 0f 10 1d");
	IntPtr MovieManager = vars.Helper.ScanRel(3, "48 8b 15 ?? ?? ?? ?? 0f b6 45");
	
	vars.Helper["EventID"] = vars.Helper.MakeString(TimelineEventManager, 0xA8, 0x20, 0x14);
	vars.Helper["EventID"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	vars.Helper["isGame"] = vars.Helper.Make<bool>(GameClock, 0x50);
	vars.Helper["isDemo"] = vars.Helper.Make<bool>(GameClock, 0x51);
	vars.Helper["isInv"] = vars.Helper.Make<bool>(GameClock, 0x52);
	vars.Helper["isPause"] = vars.Helper.Make<bool>(GameClock, 0x53);
	vars.Helper["GameElapsedTime"] = vars.Helper.Make<long>(GameClock, 0x60, 0x18);
	vars.Helper["DemoSpendingTime"] = vars.Helper.Make<long>(GameClock, 0x60, 0x20);
	vars.Helper["PauseSpendingTime"] = vars.Helper.Make<long>(GameClock, 0x60, 0x30);
	vars.Helper["MapID"] = vars.Helper.Make<short>(EnvironmentStandbyManager, 0xA8, 0x10);
	vars.Helper["SurvivorType"] = vars.Helper.Make<byte>(SurvivorManager, 0x50, 0x54);
	vars.Helper["SoundStateValue"] = vars.Helper.Make<byte>(MainFlowManager, 0x68);
	vars.Helper["GmeStartValue"] = vars.Helper.Make<byte>(MainFlowManager, 0x54);
	vars.Helper["Scenario"] = vars.Helper.Make<byte>(MainFlowManager, 0x198, 0x1C);
	vars.Helper["Results"] = vars.Helper.Make<byte>(MainFlowManager, 0x120, 0x10);
	vars.Helper["ResultsExtra"] = vars.Helper.Make<byte>(MainFlowManager, 0x128, 0x10);
	
	vars.Helper["DLCEventID"] = vars.Helper.MakeString(MovieManager, 0x58, 0x10, 0x20, 0xB8, 0x18, 0x10, 0x28, 0x0);
	vars.Helper["DLCEventID"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	
	vars.Helper["Fade6"] = vars.Helper.Make<bool>(FadeManager, 0x50, 0x48, 0x18, 0x68);
	
	vars.Inv = InventoryManager;
	vars.Clock = GameClock;
	
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
	
	if(!string.IsNullOrEmpty(current.DLCEventID)){
        current.DLCEvent = current.DLCEventID.Substring(2,3);
    }
	
	if(string.IsNullOrEmpty(current.DLCEventID)){
        current.DLCEvent = "";
    }

	if (!settings["3Dig"]){
		vars.Helper.Texts.RemoveAll();
	}
	
	if (settings["3Dig"]){
		vars.TotalTimeInSeconds = current.GameElapsedTime - current.DemoSpendingTime - current.PauseSpendingTime;
		vars.Helper.Texts["Total Time"].Right = TimeSpan.FromSeconds(vars.TotalTimeInSeconds / 1000000.0).ToString(@"hh\:mm\:ss\.fff");
	}
	
	if (settings["3Dig"]){
		if(current.Results == 1 && old.Results != 1){
			game.WriteValue<byte>(game.ReadPointer((IntPtr)vars.Clock) + 0x50, 0);
		}
	}
}

onStart
{
	vars.completedSplits.Clear();
	vars.PendingSplits = 0;

	if(settings["3Dig"]){
		vars.Helper.Texts["Total Time"].Left = "Time:";
		vars.Helper.Texts["Total Time"].Right = "00:00:00.0000";
	}
}

start
{
	return (old.Event == "001" || old.Event == "910" || old.Event == "930") && current.Event != old.Event || old.DLCEvent == "990" && current.DLCEvent != old.DLCEvent;
}

split
{
	string Itemsetting = "";
	string Weaponsetting = "";
	string Mapsetting = "";
	string Eventsetting = "";
	string DLCEventsetting = "";
	string Resultsetting = "";
	string ExtraResultsetting = "";
	
	int[] currentItem = (current.item as int[]);
	int[] oldItem = (old.item as int[]);

	int[] currentWeapon = (current.weapon as int[]);
	int[] oldWeapon = (old.weapon as int[]);
	
	if(!currentItem.SequenceEqual(oldItem)){
		int[] delta = (currentItem as int[]).Where((v, i) => v != oldItem[i]).ToArray();

		foreach (int item in delta){
			if(item != 0 && current.SurvivorType != 2 || current.SurvivorType != 20){
				Itemsetting = "Item_" + item;
			}
			if((current.Scenario == 2 || current.Scenario == 3) && item == 241){
				Itemsetting = "Item_" + item + "_B";
			}
			if(current.SurvivorType == 20 && item == 286){
				return true;
			}
		}
		
		if(!vars.completedSplits.Contains(Itemsetting)){
			if (settings.ContainsKey(Itemsetting) && settings[Itemsetting]){
				vars.PendingSplits++;
			}
		}
		
		// Debug. Comment out before release.
		if (!string.IsNullOrEmpty(Itemsetting))
		vars.Log(Itemsetting);
	}
	
	if(!currentWeapon.SequenceEqual(oldWeapon)){
		int[] delta = (currentWeapon as int[]).Where((v, i) => v != oldWeapon[i]).ToArray();

		foreach (int item in delta){
			Weaponsetting = "Weapon_" + item;
		}
		
		if(!vars.completedSplits.Contains(Weaponsetting)){
			if (settings.ContainsKey(Weaponsetting) && settings[Weaponsetting]){
				vars.PendingSplits++;
			}
		}
		
		// Debug. Comment out before release.
		if (!string.IsNullOrEmpty(Weaponsetting))
		vars.Log(Weaponsetting);
	}
	
	if(current.MapID != old.MapID){
		if(current.SurvivorType == 4 || current.SurvivorType == 5){
			Mapsetting = "Hunk_" + current.MapID + "_" + old.MapID;
		}
		else if(current.SurvivorType == 6){
			Mapsetting = "Kendo_" + current.MapID + "_" + old.MapID;
		}
		else if(current.SurvivorType == 20){
			Mapsetting = "Kath_" + current.MapID + "_" + old.MapID;
		}
		else if(current.SurvivorType == 12){
			Mapsetting = "Soldier_" + current.MapID + "_" + old.MapID;
		}
		else if((current.MapID == 112 || current.MapID == 261) && (current.SurvivorType == 0 || current.SurvivorType == 1)){
			Mapsetting = "Map_RPD";
		}
		else Mapsetting = "Map_" + current.MapID;
		
		if(!vars.completedSplits.Contains(Mapsetting)){
			if (settings.ContainsKey(Mapsetting) && settings[Mapsetting]){
				vars.PendingSplits++;
			}
		}
		
		// Debug. Comment out before release.
		if (!string.IsNullOrEmpty(Mapsetting))
		vars.Log(Mapsetting);
	}
	
	if(current.EventID != old.EventID && !string.IsNullOrEmpty(current.EventID)){
		Eventsetting = "Event_" + current.Event;
		
		if(!vars.completedSplits.Contains(Eventsetting)){
			if (settings.ContainsKey(Eventsetting) && settings[Eventsetting]){
				vars.PendingSplits++;
			}
		}
		
		// ebug. Comment out before release.
		if (!string.IsNullOrEmpty(Eventsetting))
		vars.Log(Eventsetting);
	}
	
	if(current.DLCEventID != old.DLCEventID && !string.IsNullOrEmpty(current.DLCEventID)){
		DLCEventsetting = "Event_" + current.DLCEvent;
		
		if(!vars.completedSplits.Contains(DLCEventsetting)){
			if (settings.ContainsKey(DLCEventsetting) && settings[DLCEventsetting]){
				vars.PendingSplits++;
			}
		}
	}

	if(current.Results == 1 && old.Results != 1){
		Resultsetting = "Results";
		
		if(!vars.completedSplits.Contains(Resultsetting)){
			if (settings.ContainsKey(Resultsetting) && settings[Resultsetting]){
				vars.PendingSplits++;
			}
		}
	}
	
	if(current.ResultsExtra == 100 && old.Results != 100){
		ExtraResultsetting = "Results_Extra";
		
		if(!vars.completedSplits.Contains(ExtraResultsetting)){
			if (settings.ContainsKey(ExtraResultsetting) && settings[ExtraResultsetting]){
				vars.PendingSplits++;
			}
		}
	}
	
	if (vars.PendingSplits > 0)
	{
		vars.PendingSplits--;
		vars.completedSplits.Add(Itemsetting);
		vars.completedSplits.Add(Weaponsetting);
		vars.completedSplits.Add(Mapsetting);
		vars.completedSplits.Add(Eventsetting);
		vars.completedSplits.Add(DLCEventsetting);
		vars.completedSplits.Add(Resultsetting);
		vars.completedSplits.Add(ExtraResultsetting);
		return true;
	}
	
	else return false;
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
	//return (current.Event == "011" || current.Event == "910" || current.Event == "930") && current.Event != old.Event || current.DLCEvent == "990" && current.DLCEvent != old.DLCEvent;
}

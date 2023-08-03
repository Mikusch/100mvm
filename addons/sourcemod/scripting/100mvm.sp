#include <sourcemod>
#include <sourcescramble>
#include <tf2utils>
#include <tf_econ_data>

#pragma newdecls required
#pragma semicolon 1

enum
{
	LOADOUT_POSITION_INVALID = -1,
	
	// Weapons & Equipment
	LOADOUT_POSITION_PRIMARY = 0,
	LOADOUT_POSITION_SECONDARY,
	LOADOUT_POSITION_MELEE,
	LOADOUT_POSITION_UTILITY,
	LOADOUT_POSITION_BUILDING,
	LOADOUT_POSITION_PDA,
	LOADOUT_POSITION_PDA2,
	
	// Wearables. If you add new wearable slots, make sure you add them to IsWearableSlot() below this.
	LOADOUT_POSITION_HEAD,
	LOADOUT_POSITION_MISC,
	
	// other
	LOADOUT_POSITION_ACTION,
	
	// More wearables, yay!
	LOADOUT_POSITION_MISC2,
	
	// taunts
	LOADOUT_POSITION_TAUNT,
	LOADOUT_POSITION_TAUNT2,
	LOADOUT_POSITION_TAUNT3,
	LOADOUT_POSITION_TAUNT4,
	LOADOUT_POSITION_TAUNT5,
	LOADOUT_POSITION_TAUNT6,
	LOADOUT_POSITION_TAUNT7,
	LOADOUT_POSITION_TAUNT8,
	
	CLASS_LOADOUT_POSITION_COUNT,
};

ConVar sm_mvm_remove_bot_cosmetics;

public Plugin myinfo =
{
	name = "Unlimited MvM Bots",
	author = "Mikusch",
	description = "Removes the 22 bot limit in Mann vs. Machine mode.",
	version = "1.0.0",
	url = "https://github.com/Mikusch/100mvm"
};

public void OnPluginStart()
{
	GameData gameconf = new GameData("100mvm");
	if (!gameconf)
		ThrowError("Could not find gamedata file for 100mvm");
	
	CreateMemoryPatch(gameconf, "CMissionPopulator::UpdateMission::MVM_INVADERS_TEAM_SIZE");
	CreateMemoryPatch(gameconf, "CWaveSpawnPopulator::Update::MVM_INVADERS_TEAM_SIZE");
	CreateMemoryPatch(gameconf, "CPopulationManager::AllocateBots::MVM_INVADERS_TEAM_SIZE");
	CreateMemoryPatch(gameconf, "CTFBotSpawner::Spawn::MVM_INVADERS_TEAM_SIZE");
	
	delete gameconf;
	
	HookEvent("post_inventory_application", EventHook_PostInventoryApplication);
	
	sm_mvm_remove_bot_cosmetics = CreateConVar("sm_mvm_remove_bot_cosmetics", "1", "Whether to remove all bot cosmetics");
}

void CreateMemoryPatch(GameData gameconf, const char[] name)
{
	MemoryPatch patch = MemoryPatch.CreateFromConf(gameconf, name);
	if (!patch.Validate())
	{
		LogError("Failed to verify patch: %s", name);
	}
	else if (patch.Enable())
	{
		LogMessage("Enabled patch: %s", name);
	}
}

void EventHook_PostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	if (!GameRules_GetProp("m_bPlayingMannVsMachine", 1) || !sm_mvm_remove_bot_cosmetics.BoolValue)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == 0)
		return;
	
	if (TF2_GetClientTeam(client) != TFTeam_Blue)
		return;
	
	for (int i = TF2Util_GetPlayerWearableCount(client) - 1; i >= 0; --i)
	{
		int weapon = TF2Util_GetPlayerWearable(client, i);
		if (weapon == -1)
			continue;
		
		int itemDefinitionIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		int slot = TF2Econ_GetItemLoadoutSlot(itemDefinitionIndex, TF2_GetPlayerClass(client));
		
		if (slot >= LOADOUT_POSITION_HEAD || slot <= LOADOUT_POSITION_MISC2)
		{
			TF2_RemoveWearable(client, weapon);
		}
	}
}

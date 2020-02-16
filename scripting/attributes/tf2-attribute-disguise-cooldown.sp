//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "disguise cooldown"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
float g_Setting_Disguise_Cooldown[MAX_ENTITY_LIMIT];
char g_Setting_Disguise_Sound_Denied[MAX_ENTITY_LIMIT][PLATFORM_MAX_PATH];

float g_Cooldown[MAXPLAYERS + 1] = {-1.0, ...};

Handle g_Hud_Cooldown;

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Disguise Cooldown", 
	author = "Drixevel", 
	description = "Adds a cooldown on loss of disguise.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	g_Hud_Cooldown = CreateHudSynchronizer();
}

public void OnConfigsExecuted()
{
	if (TF2Weapons_AllowAttributeRegisters())
		TF2Weapons_OnRegisterAttributesPost();
}

public void TF2Weapons_OnRegisterAttributesPost()
{
	if (!TF2Weapons_RegisterAttribute(ATTRIBUTE_NAME, OnAttributeAction))
		LogError("Error while registering the '%s' attribute.", ATTRIBUTE_NAME);
}

public void OnAttributeAction(int client, int weapon, const char[] attrib, const char[] action, StringMap attributesdata)
{
	if (StrEqual(action, "apply", false))
	{
		attributesdata.GetValue("cooldown", g_Setting_Disguise_Cooldown[weapon]);
		attributesdata.GetString("denied_sound", g_Setting_Disguise_Sound_Denied[weapon], sizeof(g_Setting_Disguise_Sound_Denied[]));
	}
	else if (StrEqual(action, "remove", false))
	{
		g_Setting_Disguise_Cooldown[weapon] = 0.0;
		g_Setting_Disguise_Sound_Denied[weapon][0] = '\0';
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity < MaxClients)
		return;
	
	g_Setting_Disguise_Cooldown[entity] = 0.0;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	float time = GetGameTime();
	if (condition == TFCond_Disguising && (g_Cooldown[client] != -1.0 && g_Cooldown[client] > time))
	{
		TF2_RemoveCondition(client, condition);

		int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if (IsValidEntity(melee) && strlen(g_Setting_Disguise_Sound_Denied[melee]) > 0 && IsSoundPrecached(g_Setting_Disguise_Sound_Denied[melee]))
			EmitSoundToClient(client, g_Setting_Disguise_Sound_Denied[melee]);
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if (condition == TFCond_DisguiseRemoved)
	{
		int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

		if (IsValidEntity(melee) && g_Setting_Disguise_Cooldown[melee] > 0.0)
			g_Cooldown[client] = GetGameTime() + g_Setting_Disguise_Cooldown[melee];
	}
}

public void OnGameFrame()
{
	float time = GetGameTime();

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || IsFakeClient(i) || g_Cooldown[i] == -1.0)
			continue;
		
		if (time >= g_Cooldown[i])
		{
			ClearSyncHud(i, g_Hud_Cooldown);
			continue;
		}
		
		SetHudTextParams(0.2, 0.8, 1.5, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
		ShowSyncHudText(i, g_Hud_Cooldown, "Disguise Available In: %.2f", (g_Cooldown[i] - time));
	}
}
//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "disguise timer"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
float g_Setting_Disguise_Timer[MAX_ENTITY_LIMIT];

Handle g_DisguiseTimer[MAXPLAYERS + 1];
float g_DisguiseTime[MAXPLAYERS + 1];

Handle g_Hud_Timer;

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Disguise Timer", 
	author = "Drixevel", 
	description = "Sets a maximum timer for disguises to last.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	HookEvent("player_death", Event_OnPlayerDeath);
	g_Hud_Timer = CreateHudSynchronizer();
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
		attributesdata.GetValue("timer", g_Setting_Disguise_Timer[weapon]);
	}
	else if (StrEqual(action, "remove", false))
	{
		g_Setting_Disguise_Timer[weapon] = 0.0;
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity < MaxClients)
		return;
	
	g_Setting_Disguise_Timer[entity] = 0.0;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (condition != TFCond_Disguised)
		return;
	
	int watch = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

	if (!IsValidEntity(watch) || g_Setting_Disguise_Timer[watch] == 0.0)
		return;
	
	delete g_DisguiseTimer[client];
	g_DisguiseTime[client] = g_Setting_Disguise_Timer[watch];
	g_DisguiseTimer[client] = CreateTimer(1.0, Timer_Undisguise, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	SetHudTextParams(0.2, 0.8, 99999.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
	ShowSyncHudText(client, g_Hud_Timer, "Exposed in: %.2f", g_DisguiseTime[client]);
}

public Action Timer_Undisguise(Handle timer, any client)
{
	if (g_DisguiseTime[client] > 0.0)
	{
		g_DisguiseTime[client]--;

		SetHudTextParams(0.2, 0.8, 99999.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
		ShowSyncHudText(client, g_Hud_Timer, "Exposed in: %.2f", g_DisguiseTime[client]);

		return Plugin_Continue;
	}

	ClearSyncHud(client, g_Hud_Timer);
	TF2_RemovePlayerDisguise(client);

	g_DisguiseTimer[client] = null;
	return Plugin_Stop;
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if (condition == TFCond_DisguiseRemoved)
	{
		delete g_DisguiseTimer[client];
		ClearSyncHud(client, g_Hud_Timer);
	}
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	delete g_DisguiseTimer[client];
	ClearSyncHud(client, g_Hud_Timer);
}
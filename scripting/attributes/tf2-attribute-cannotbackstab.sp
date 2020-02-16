//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "cannot backstab"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
bool g_Setting_CannotBackstab[MAX_ENTITY_LIMIT];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Cannot Backstab", 
	author = "Drixevel", 
	description = "An attribute which blocks backstabs for knives.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			OnClientPutInServer(i);
	}

	HookEvent("player_death", Event_OnPlayerDeathPre, EventHookMode_Pre);
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
		g_Setting_CannotBackstab[weapon] = true;
	else if (StrEqual(action, "remove", false))
		g_Setting_CannotBackstab[weapon] = true;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	int active = GetActiveWeapon(attacker);

	if (damagecustom == TF_CUSTOM_BACKSTAB && g_Setting_CannotBackstab[active])
	{
		if (GetClientHealth(victim) > 5)
			damage = FloatDivider(damage, 0.8);
		
		damagetype &= ~DMG_CRIT;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public Action Event_OnPlayerDeathPre(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if (!IsPlayerIndex(attacker) || !IsClientInGame(attacker) || !IsPlayerAlive(attacker))
		return Plugin_Continue;
	
	int active = GetActiveWeapon(attacker);

	if (!g_Setting_CannotBackstab[active])
		return Plugin_Continue;

	char sKillIcon[32];
	event.GetString("weapon", sKillIcon, sizeof(sKillIcon));

	if (StrEqual(sKillIcon, "knife", false))
		event.SetInt("customkill", 0);

	return Plugin_Changed;
}
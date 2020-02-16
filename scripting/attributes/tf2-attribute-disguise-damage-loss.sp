//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "lose disguise on damage"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
float g_Setting_Disguise_Damage_Loss[MAX_ENTITY_LIMIT];

float g_DamageTaken[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Lose Disguise On Damage", 
	author = "Drixevel", 
	description = "Lose your disguise if you take a certain threshold of damage.", 
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
		attributesdata.GetValue("damage", g_Setting_Disguise_Damage_Loss[weapon]);
	}
	else if (StrEqual(action, "remove", false))
	{
		g_Setting_Disguise_Damage_Loss[weapon] = 0.0;
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity < MaxClients)
		return;
	
	g_Setting_Disguise_Damage_Loss[entity] = 0.0;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	int melee = GetPlayerWeaponSlot(victim, TFWeaponSlot_Melee);

	if (!IsValidEntity(melee) || g_Setting_Disguise_Damage_Loss[melee] == 0.0)
		return Plugin_Continue;
	
	g_DamageTaken[victim] += damage;

	if (g_DamageTaken[victim] >= g_Setting_Disguise_Damage_Loss[melee])
	{
		TF2_RemovePlayerDisguise(victim);
		g_DamageTaken[victim] = 0.0;
	}

	return Plugin_Continue;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (condition == TFCond_Disguising)
		g_DamageTaken[client] = 0.0;
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if (condition == TFCond_DisguiseRemoved)
		g_DamageTaken[client] = 0.0;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrContains(classname, "item_healthkit_", false) == 0)
		SDKHook(entity, SDKHook_StartTouch, OnTouchHealthkits);
}

public Action OnTouchHealthkits(int entity, int other)
{
	if (IsPlayerIndex(other))
		g_DamageTaken[other] = 0.0;
}
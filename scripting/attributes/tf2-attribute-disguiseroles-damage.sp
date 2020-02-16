//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "disguise roles non-crit damage bonus"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
float g_Setting_Offensive_Buff[MAX_ENTITY_LIMIT];
float g_Setting_Defensive_Buff[MAX_ENTITY_LIMIT];
float g_Setting_Support_Buff[MAX_ENTITY_LIMIT];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Disguise Roles Non-Crit Damage Bonus", 
	author = "Drixevel", 
	description = "Grants bonuses or penalties for damage based on the role of the spy disguise.", 
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
		attributesdata.GetValue("offensive_buff", g_Setting_Offensive_Buff[weapon]);
		attributesdata.GetValue("defensive_buff", g_Setting_Defensive_Buff[weapon]);
		attributesdata.GetValue("support_buff", g_Setting_Support_Buff[weapon]);
	}
	else if (StrEqual(action, "remove", false))
	{
		g_Setting_Offensive_Buff[weapon] = 0.0;
		g_Setting_Defensive_Buff[weapon] = 0.0;
		g_Setting_Support_Buff[weapon] = 0.0;
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity < MaxClients)
		return;
	
	g_Setting_Offensive_Buff[entity] = 0.0;
	g_Setting_Defensive_Buff[entity] = 0.0;
	g_Setting_Support_Buff[entity] = 0.0;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (TF2_GetPlayerClass(attacker) != TFClass_Spy || !TF2_IsPlayerInCondition(attacker, TFCond_Disguised))
		return Plugin_Continue;

	bool changed;
	int melee = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee);

	if (!IsValidEntity(melee))
		return Plugin_Continue;

	switch (TF2_GetClassRole(view_as<TFClassType>(GetEntProp(attacker, Prop_Send, "m_nDisguiseClass"))))
	{
		case TFRole_Offense:
		{
			if (g_Setting_Offensive_Buff[melee] > 0.0 && (damagetype & DMG_CRIT) != DMG_CRIT)
			{
				damage = FloatMultiplier(damage, g_Setting_Offensive_Buff[melee]);
				changed = true;
			}
		}
		case TFRole_Defense:
		{
			if (g_Setting_Defensive_Buff[melee] > 0.0 && (damagetype & DMG_CRIT) != DMG_CRIT)
			{
				damage = FloatMultiplier(damage, g_Setting_Defensive_Buff[melee]);
				changed = true;
			}
		}
		case TFRole_Support:
		{
			if (g_Setting_Support_Buff[melee] > 0.0 && (damagetype & DMG_CRIT) != DMG_CRIT)
			{
				damage = FloatMultiplier(damage, g_Setting_Support_Buff[melee]);
				changed = true;
			}
		}
	}

	return changed ? Plugin_Changed : Plugin_Continue;
}
//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "disguise roles health regeneration bonus"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
int g_Setting_Offensive_Buff[MAX_ENTITY_LIMIT];
int g_Setting_Defensive_Buff[MAX_ENTITY_LIMIT];
int g_Setting_Support_Buff[MAX_ENTITY_LIMIT];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Disguise Roles Health Regeneration Bonus", 
	author = "Drixevel", 
	description = "Grants bonuses or penalties for health regeneration based on the role of the spy disguise.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	CreateTimer(1.0, Timer_Regenerate, _, TIMER_REPEAT);
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
		g_Setting_Offensive_Buff[weapon] = 0;
		g_Setting_Defensive_Buff[weapon] = 0;
		g_Setting_Support_Buff[weapon] = 0;
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity < MaxClients)
		return;
	
	g_Setting_Offensive_Buff[entity] = 0;
	g_Setting_Defensive_Buff[entity] = 0;
	g_Setting_Support_Buff[entity] = 0;
}

public Action Timer_Regenerate(Handle timer)
{
	int weapon;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || TF2_GetPlayerClass(i) != TFClass_Spy || !TF2_IsPlayerInCondition(i, TFCond_Disguised))
			continue;

		switch (TF2_GetClassRole(view_as<TFClassType>(GetEntProp(i, Prop_Send, "m_nDisguiseClass"))))
		{
			case TFRole_Offense:
			{
				for (int x = 0; x < 3; x++)
				{
					weapon = GetPlayerWeaponSlot(i, x);

					if (IsValidEntity(weapon) && g_Setting_Offensive_Buff[weapon] > 0)
						TF2_AddPlayerHealth(i, g_Setting_Offensive_Buff[weapon], 0.0, true, true);
				}
			}
			case TFRole_Defense:
			{
				for (int x = 0; x < 3; x++)
				{
					weapon = GetPlayerWeaponSlot(i, x);

					if (IsValidEntity(weapon) && g_Setting_Defensive_Buff[weapon] > 0)
						TF2_AddPlayerHealth(i, g_Setting_Defensive_Buff[weapon], 0.0, true, true);
				}
			}
			case TFRole_Support:
			{
				for (int x = 0; x < 3; x++)
				{
					weapon = GetPlayerWeaponSlot(i, x);

					if (IsValidEntity(weapon) && g_Setting_Support_Buff[weapon] > 0)
						TF2_AddPlayerHealth(i, g_Setting_Support_Buff[weapon], 0.0, true, true);
				}
			}
		}
	}
}
//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "disguise speed bonus"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
float g_Setting_Disguise_Speed_Bonus[MAX_ENTITY_LIMIT];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Disguise Speed Bonus", 
	author = "Drixevel", 
	description = "Bonuses or Pentalizes disguise speeds for spies.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{

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
		attributesdata.GetValue("speed", g_Setting_Disguise_Speed_Bonus[weapon]);
	}
	else if (StrEqual(action, "remove", false))
	{
		g_Setting_Disguise_Speed_Bonus[weapon] = 0.0;
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity < MaxClients)
		return;
	
	g_Setting_Disguise_Speed_Bonus[entity] = 0.0;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (condition != TFCond_Disguising)
		return;
	
	int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

	if (!IsValidEntity(melee) || g_Setting_Disguise_Speed_Bonus[melee] == 0.0)
		return;
	
	CreateTimer(FloatDivider(2.0, g_Setting_Disguise_Speed_Bonus[melee]), Timer_Disguise, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Disguise(Handle timer, any client)
{
	int target = GetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex");

	if (!IsPlayerIndex(target) || !IsClientInGame(target))
		target = GetRandomClient(true, true, true);

	TFClassType class = TF2_GetPlayerClass(client);
	TF2_SetPlayerClass(client, TFClass_Spy, _, false);
	TF2_DisguisePlayer(client, view_as<TFTeam>(GetEntProp(client, Prop_Send, "m_nDisguiseTeam")), view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass")), target);
	TF2_SetPlayerClass(client, class, _, false);
}
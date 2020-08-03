//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "stun on headshot"

//Sourcemod Includes
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2-items>

//Globals
bool g_Setting_StunOnHeadshot[2048 + 1];
float g_Setting_Duration[2048 + 1];
float g_Setting_Slowdown[2048 + 1];
bool g_Setting_NoDamage[2048 + 1];
int g_Setting_Flags[2048 + 1];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: stun on headshot", 
	author = "Drixevel", 
	description = "An attribute which allows weapons to stun on headshot.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnConfigsExecuted()
{
	if (TF2Items_AllowAttributeRegisters())
		TF2Items_OnRegisterAttributesPost();
}

public void TF2Items_OnRegisterAttributesPost()
{
	if (!TF2Items_RegisterAttribute(ATTRIBUTE_NAME, OnAttributeAction))
		LogError("Error while registering the '%s' attribute.", ATTRIBUTE_NAME);
}

public void OnAttributeAction(int client, int weapon, const char[] attrib, const char[] action, StringMap attributesdata)
{
	if (StrEqual(action, "apply", false))
	{
		g_Setting_StunOnHeadshot[weapon] = true;
		attributesdata.GetValue("duration", g_Setting_Duration[weapon]);
		attributesdata.GetValue("slowdown", g_Setting_Slowdown[weapon]);
		attributesdata.GetValue("nodamage", g_Setting_NoDamage[weapon]);

		char sFlags[128];
		attributesdata.GetString("flags", sFlags, sizeof(sFlags));

		if (StrContains(sFlags, "TF_STUNFLAG_SLOWDOWN", false) != -1)
			g_Setting_Flags[weapon] |= TF_STUNFLAG_SLOWDOWN;
		else if (StrContains(sFlags, "TF_STUNFLAG_BONKSTUCK", false) != -1)
			g_Setting_Flags[weapon] |= TF_STUNFLAG_BONKSTUCK;
		if (StrContains(sFlags, "TF_STUNFLAG_LIMITMOVEMENT", false) != -1)
			g_Setting_Flags[weapon] |= TF_STUNFLAG_LIMITMOVEMENT;
		else if (StrContains(sFlags, "TF_STUNFLAG_CHEERSOUND", false) != -1)
			g_Setting_Flags[weapon] |= TF_STUNFLAG_CHEERSOUND;
		if (StrContains(sFlags, "TF_STUNFLAG_NOSOUNDOREFFECT", false) != -1)
			g_Setting_Flags[weapon] |= TF_STUNFLAG_NOSOUNDOREFFECT;
		else if (StrContains(sFlags, "TF_STUNFLAG_THIRDPERSON", false) != -1)
			g_Setting_Flags[weapon] |= TF_STUNFLAG_THIRDPERSON;
		if (StrContains(sFlags, "TF_STUNFLAG_GHOSTEFFECT", false) != -1)
			g_Setting_Flags[weapon] |= TF_STUNFLAG_GHOSTEFFECT;
		else if (StrContains(sFlags, "TF_STUNFLAG_SOUND", false) != -1)
			g_Setting_Flags[weapon] |= TF_STUNFLAG_SOUND;
		else if (StrContains(sFlags, "TF_STUNFLAGS_LOSERSTATE", false) != -1)
			g_Setting_Flags[weapon] |= TF_STUNFLAGS_LOSERSTATE;
		if (StrContains(sFlags, "TF_STUNFLAGS_GHOSTSCARE", false) != -1)
			g_Setting_Flags[weapon] |= TF_STUNFLAGS_GHOSTSCARE;
		else if (StrContains(sFlags, "TF_STUNFLAGS_SMALLBONK", false) != -1)
			g_Setting_Flags[weapon] |= TF_STUNFLAGS_SMALLBONK;
		if (StrContains(sFlags, "TF_STUNFLAGS_NORMALBONK", false) != -1)
			g_Setting_Flags[weapon] |= TF_STUNFLAGS_NORMALBONK;
		else if (StrContains(sFlags, "TF_STUNFLAGS_BIGBONK", false) != -1)
			g_Setting_Flags[weapon] |= TF_STUNFLAGS_BIGBONK;
	}
	else if (StrEqual(action, "remove", false))
		g_Setting_StunOnHeadshot[weapon] = false;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (IsValidEntity(weapon) && g_Setting_StunOnHeadshot[weapon] && damagecustom == TF_CUSTOM_HEADSHOT)
	{
		TF2_StunPlayer(victim, g_Setting_Duration[weapon], g_Setting_Slowdown[weapon], g_Setting_Flags[weapon], attacker);

		if (g_Setting_NoDamage[weapon])
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}
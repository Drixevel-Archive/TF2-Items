//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "ban on damage"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
bool g_Setting_Status[MAX_ENTITY_LIMIT];
int g_Setting_Duration[MAX_ENTITY_LIMIT];
char g_Setting_Reason[MAX_ENTITY_LIMIT][128];
char g_Setting_KickMessage[MAX_ENTITY_LIMIT][128];
char g_Setting_Command[MAX_ENTITY_LIMIT][128];
bool g_Setting_Fake[MAX_ENTITY_LIMIT];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Ban On Damage", 
	author = "Drixevel", 
	description = "An attribute which allows weapons to ban players on damage.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	HookEvent("player_hurt", Event_OnPlayerHurt);
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
		g_Setting_Status[weapon] = true;
		attributesdata.GetValue("duration", g_Setting_Duration[weapon]);
		attributesdata.GetString("reason", g_Setting_Reason[weapon], sizeof(g_Setting_Reason[]));
		attributesdata.GetString("kickmessage", g_Setting_KickMessage[weapon], sizeof(g_Setting_KickMessage[]));
		attributesdata.GetString("command", g_Setting_Command[weapon], sizeof(g_Setting_Command[]));
		attributesdata.GetValue("fake", g_Setting_Fake[weapon]);
	}
	else if (StrEqual(action, "remove", false))
	{
		g_Setting_Status[weapon] = false;
		g_Setting_Duration[weapon] = 0;
		g_Setting_Reason[weapon][0] = '\0';
		g_Setting_KickMessage[weapon][0] = '\0';
		g_Setting_Command[weapon][0] = '\0';
		g_Setting_Fake[weapon] = false;
	}
}

public void Event_OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (!IsPlayerIndex(victim) || !IsPlayerIndex(attacker) || victim == attacker || !IsClientInGame(victim) || !IsClientInGame(attacker))
		return;
	
	if (IsFakeClient(victim) || IsFakeClient(attacker))
		return;
	
	int active = GetActiveWeapon(attacker);

	if (!g_Setting_Status[active])
		return;
	
	if (!g_Setting_Fake[active])
		BanClient(victim, g_Setting_Duration[active], BANFLAG_AUTHID, g_Setting_Reason[active], g_Setting_KickMessage[active], g_Setting_Command[active], attacker);
}
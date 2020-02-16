//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "push on fire"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
bool g_CanPushOnFire[MAX_ENTITY_LIMIT];
float g_Setting_Scale[MAX_ENTITY_LIMIT + 1];
char g_Setting_Direction[MAX_ENTITY_LIMIT + 1][64];
float g_Setting_ZOffset[MAX_ENTITY_LIMIT + 1];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Push On Fire", 
	author = "Drixevel", 
	description = "An attribute that allows for push on fire.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

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
		g_CanPushOnFire[weapon] = true;
		attributesdata.GetValue("scale", g_Setting_Scale[weapon]);
		attributesdata.GetString("direction", g_Setting_Direction[weapon], sizeof(g_Setting_Direction[]));
		attributesdata.GetValue("z_offset", g_Setting_ZOffset[weapon]);

		if (g_Setting_Scale[weapon] <= 0.0)
			g_Setting_Scale[weapon] = 0.0;

		if (strlen(g_Setting_Direction[weapon]) == 0)
			strcopy(g_Setting_Direction[weapon], sizeof(g_Setting_Direction[]), "backwards");

		if (g_Setting_ZOffset[weapon] <= 0.0)
			g_Setting_ZOffset[weapon] = 0.0;
	}
	else if (StrEqual(action, "remove", false))
	{
		g_CanPushOnFire[weapon] = false;
		g_Setting_Scale[weapon] = 0.0;
		g_Setting_Direction[weapon][0] = '\0';
		g_Setting_ZOffset[weapon] = 0.0;
	}
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool& result)
{
	if (!g_CanPushOnFire[weapon])
		return Plugin_Continue;
	
	int dir = DIR_BACKWARD;

	if (StrEqual(g_Setting_Direction[weapon], "forward", false))
		dir = DIR_FORWARD;
	else if (StrEqual(g_Setting_Direction[weapon], "backwards", false))
		dir = DIR_BACKWARD;
	else if (StrEqual(g_Setting_Direction[weapon], "left", false))
		dir = DIR_LEFT;
	else if (StrEqual(g_Setting_Direction[weapon], "right", false))
		dir = DIR_RIGHT;
	else if (StrEqual(g_Setting_Direction[weapon], "up", false))
		dir = DIR_UP;
	else if (StrEqual(g_Setting_Direction[weapon], "down", false))
		dir = DIR_DOWN;

	KnockbackClient(client, g_Setting_Scale[weapon], dir, g_Setting_ZOffset[weapon]);
	return Plugin_Continue;
}
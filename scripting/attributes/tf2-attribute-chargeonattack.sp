//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "charge on alt-fire"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
bool g_CanCharge[MAX_ENTITY_LIMIT];
float g_Setting_Speed[MAX_ENTITY_LIMIT];
float g_Setting_Duration[MAX_ENTITY_LIMIT];

float g_Start[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Damage Spam Damage", 
	author = "Drixevel", 
	description = "An attribute that allows for Damage to be spammed when damaged.", 
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
		g_CanCharge[weapon] = true;
		attributesdata.GetValue("speed", g_Setting_Speed[weapon]);
		attributesdata.GetValue("duration", g_Setting_Duration[weapon]);
	}
	else if (StrEqual(action, "remove", false))
	{
		g_CanCharge[weapon] = false;
		g_Setting_Speed[weapon] = 0.0;
		g_Setting_Duration[weapon] = 0.0;
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (!IsPlayerAlive(client))
		return Plugin_Continue;
	
	int active = GetActiveWeapon(client);

	if (active == -1 || !g_CanCharge[active])
		return Plugin_Continue;

	float time = GetGameTime();

	if (buttons & IN_ATTACK2 || g_Start[client] > 0 && g_Start[client] - time > 0)
	{
		float vecAngles[3];
		GetClientEyeAngles(client, vecAngles);
		vecAngles[0] = 0.0;

		float vecVelocity[3];
		AnglesToVelocity(vecAngles, g_Setting_Speed[active], vecVelocity);

		float vecOrigin[3];
		GetClientAbsOrigin(client, vecOrigin);
		vecOrigin[2] += GetEntityFlags(client) & FL_ONGROUND ? 20.0 : 0.0;
		
		TeleportEntity(client, vecOrigin, NULL_VECTOR, vecVelocity);

		if (g_Start[client] < time)
			g_Start[client] = time + g_Setting_Duration[active];
	}

	return Plugin_Continue;
}

public void OnClientDisconnect_Post(int client)
{
	g_Start[client] = 0.0;
}
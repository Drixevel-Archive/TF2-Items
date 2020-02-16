//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "hit players"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
bool g_HitProjectiles[MAX_ENTITY_LIMIT];
float g_Setting_HitBuffer[MAX_ENTITY_LIMIT + 1];
float g_Setting_HitScale[MAX_ENTITY_LIMIT + 1];
char g_Setting_HitSound[MAX_ENTITY_LIMIT + 1][PLATFORM_MAX_PATH];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Hit Projectiles", 
	author = "Drixevel", 
	description = "An attribute that allows for hit projectiles.", 
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
		g_HitProjectiles[weapon] = true;
		attributesdata.GetValue("buffer", g_Setting_HitBuffer[weapon]);
		attributesdata.GetValue("scale", g_Setting_HitScale[weapon]);
		attributesdata.GetString("sound", g_Setting_HitSound[weapon], sizeof(g_Setting_HitSound[]));
	}
	else if (StrEqual(action, "remove", false))
	{
		g_HitProjectiles[weapon] = false;
		g_Setting_HitBuffer[weapon] = 0.0;
		g_Setting_HitScale[weapon] = 0.0;
		g_Setting_HitSound[weapon][0] = '\0';
	}
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool& result)
{
	if (!g_HitProjectiles[weapon])
		return Plugin_Continue;
	
	float vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin);

	float vecAngles[3];
	GetClientAbsAngles(client, vecAngles);

	float vecPoint[3];
	AddInFrontOf(vecOrigin, vecAngles, 3.0, vecPoint);

	float vecEyeAngles[3];
	GetClientEyeAngles(client, vecEyeAngles);

	TFTeam team = TF2_GetClientTeam(client);
	bool friendlyfire = FindConVar("mp_friendlyfire").BoolValue;

	int entity = -1; float vecProj[3];
	while ((entity = FindEntityByClassname(entity, "player")) != -1)
	{
		if (client == entity || (!friendlyfire && TF2_GetClientTeam(entity) == team))
			continue;
		
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vecProj);

		if (GetVectorDistance(vecPoint, vecProj) > g_Setting_HitBuffer[weapon])
			continue;
		
		float fDirection[3];
		GetAngleVectors(vecEyeAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
		
		ScaleVector(fDirection, g_Setting_HitScale[weapon]);
		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, fDirection);

		EmitSoundToAll(g_Setting_HitSound[weapon], client);
	}

	return Plugin_Continue;
}

void AddInFrontOf(float vecOrigin[3], float vecAngle[3], float units, float output[3]) 
{ 
    float vecAngVectors[3]; 
    vecAngVectors = vecAngle;
    GetAngleVectors(vecAngVectors, vecAngVectors, NULL_VECTOR, NULL_VECTOR); 
    for (int i; i < 3; i++) 
    	output[i] = vecOrigin[i] + (vecAngVectors[i] * units); 
}
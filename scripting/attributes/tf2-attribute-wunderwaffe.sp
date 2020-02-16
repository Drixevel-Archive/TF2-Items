//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "wunderwaffe"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
bool g_Setting_Wunderwaffe[MAX_ENTITY_LIMIT];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Wunderwaffe", 
	author = "Drixevel", 
	description = "An attribute which enables Wunderwaffe effects.", 
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
		g_Setting_Wunderwaffe[weapon] = true;
	else if (StrEqual(action, "remove", false))
		g_Setting_Wunderwaffe[weapon] = false;
}

public void OnEntityDestroyed(int entity)
{
	if (!IsValidEntity(entity))
		return;
	
	char sClassname[32];
	GetEntityClassname(entity, sClassname, sizeof(sClassname));

	if (StrEqual(sClassname, "tf_projectile_energy_ring"))
	{
		int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

		if (client < 1 || client > MaxClients)
			return;

		int weapon = GetActiveWeapon(client);

		if (g_Setting_Wunderwaffe[weapon])
		{
			float vecAngles[3];
			GetClientEyeAngles(client, vecAngles);

			float vecPosition[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vecPosition);
			
			float speed = 100.0;
			float damage = 1000.0;
			float radius = 500.0;

			RocketsGameFired(client, vecPosition, vecAngles, speed, damage, radius);
		}
	}
}

void RocketsGameFired(int client, float vPosition[3], float vAngles[3], float flSpeed = 650.0, float flDamage = 800.0, float flRadius = 200.0, bool bCritical = true)
{
	int iRocket = CreateEntityByName("tf_projectile_energy_ball");

	if (IsValidEntity(iRocket))
	{
		float vBuffer[3];
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		
		float vVelocity[3];
		vVelocity[0] = vBuffer[0] * flSpeed;
		vVelocity[1] = vBuffer[1] * flSpeed;
		vVelocity[2] = vBuffer[2] * flSpeed;

		TeleportEntity(iRocket, vPosition, vAngles, vVelocity);

		SetEntData(iRocket, FindSendPropInfo("CTFProjectile_Rocket", "m_iTeamNum"), GetClientTeam(client), true);
		SetEntData(iRocket, FindSendPropInfo("CTFProjectile_Rocket", "m_bCritical"), bCritical, true);
		SetEntPropEnt(iRocket, Prop_Send, "m_hOwnerEntity", client);

		SetEntPropFloat(iRocket, Prop_Data, "m_flRadius", flRadius);
		SetEntPropFloat(iRocket, Prop_Data, "m_flModelScale", flRadius);

		DispatchSpawn(iRocket);

		CreateParticle("critgun_weaponmodel_blu", 0.5, vPosition);

		int entity = -1;
		while ((entity = FindEntityByClassname(entity, "tf_zombie")) != -1)
		{
			float vecZombiePos[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vecZombiePos);

			if (GetVectorDistance(vPosition, vecZombiePos) <= flRadius)
				SDKHooks_TakeDamage(entity, 0, client, flDamage, DMG_BLAST, GetActiveWeapon(client), NULL_VECTOR, vPosition);
		}
	}
}
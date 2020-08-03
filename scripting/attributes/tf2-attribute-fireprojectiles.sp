//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "fire projectiles"

//Sourcemod Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2-items>
#include <misc-sm>
#include <misc-tf>

//Globals
bool g_FireProjectiles[MAX_ENTITY_LIMIT + 1];
char g_Setting_Entity[MAX_ENTITY_LIMIT + 1][32];
bool g_Setting_FriendlyFire[MAX_ENTITY_LIMIT + 1];
float g_Setting_Startup[MAX_ENTITY_LIMIT + 1];
float g_Setting_Interval[MAX_ENTITY_LIMIT + 1];
char g_Setting_Offsets[MAX_ENTITY_LIMIT + 1][64];
float g_Setting_Speed[MAX_ENTITY_LIMIT + 1];
float g_Setting_Damage[MAX_ENTITY_LIMIT + 1];
char g_Setting_SpawnParticle[MAX_ENTITY_LIMIT + 1][64];
char g_Setting_RenderMode[MAX_ENTITY_LIMIT + 1][64];
char g_Setting_RenderColor[MAX_ENTITY_LIMIT + 1][64];
float g_Setting_SelfDestruct[MAX_ENTITY_LIMIT + 1];
bool g_Setting_SetTransmit[MAX_ENTITY_LIMIT + 1];
int g_Setting_ClipUsed[MAX_ENTITY_LIMIT + 1];
int g_Setting_AmmoUsed[MAX_ENTITY_LIMIT + 1];

float g_StartupTime[MAXPLAYERS + 1];
float g_IntervalTime[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Fire Projectiles", 
	author = "Drixevel", 
	description = "An attribute that allows for projectiles to be fired.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{

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
		g_FireProjectiles[weapon] = true;
		attributesdata.GetString("entity", g_Setting_Entity[weapon], sizeof(g_Setting_Entity[]));
		attributesdata.GetValue("startup_rate", g_Setting_Startup[weapon]);
		attributesdata.GetValue("fire_rate", g_Setting_Interval[weapon]);
		attributesdata.GetString("offsets", g_Setting_Offsets[weapon], sizeof(g_Setting_Offsets[]));
		attributesdata.GetValue("speed", g_Setting_Speed[weapon]);
		attributesdata.GetValue("damage", g_Setting_Damage[weapon]);
		attributesdata.GetString("spawn_particle", g_Setting_SpawnParticle[weapon], sizeof(g_Setting_SpawnParticle[]));
		attributesdata.GetString("render_mode", g_Setting_RenderMode[weapon], sizeof(g_Setting_RenderMode[]));
		attributesdata.GetString("render_color", g_Setting_RenderColor[weapon], sizeof(g_Setting_RenderColor[]));
		attributesdata.GetValue("self_destruct", g_Setting_SelfDestruct[weapon]);
		attributesdata.GetValue("transmit", g_Setting_SetTransmit[weapon]);
		attributesdata.GetValue("clip_used", g_Setting_ClipUsed[weapon]);
		attributesdata.GetValue("ammo_used", g_Setting_AmmoUsed[weapon]);

		SDKHook(client, SDKHook_PostThink, OnPostThink);
	}
	else if (StrEqual(action, "remove", false))
	{
		g_FireProjectiles[weapon] = false;
		g_Setting_Entity[weapon][0] = '\0';
		g_Setting_FriendlyFire[weapon] = false;
		g_Setting_Startup[weapon] = 0.0;
		g_Setting_Interval[weapon] = 0.0;
		g_Setting_Offsets[weapon][0] = '\0';
		g_Setting_Speed[weapon] = 0.0;
		g_Setting_Damage[weapon] = 0.0;
		g_Setting_SpawnParticle[weapon][0] = '\0';
		g_Setting_RenderMode[weapon][0] = '\0';
		g_Setting_RenderColor[weapon][0] = '\0';
		g_Setting_SelfDestruct[weapon] = 0.0;
		g_Setting_SetTransmit[weapon] = false;
		g_Setting_ClipUsed[weapon] = 0;
		g_Setting_AmmoUsed[weapon] = 0;
		
		SDKUnhook(client, SDKHook_PostThink, OnPostThink);
	}
}

public void OnPostThink(int client)
{
	int weapon = GetActiveWeapon(client);

	if (weapon == -1 || !g_FireProjectiles[weapon])
		return;
	
	if (!(GetClientButtons(client) & IN_ATTACK))
	{
		g_StartupTime[client] = GetGameTime();
		g_IntervalTime[client] = GetGameTime();

		return;
	}
	
	if (g_Setting_ClipUsed[weapon] > 0 && GetClip(weapon) < g_Setting_ClipUsed[weapon])
		return;
		
	if (g_Setting_AmmoUsed[weapon] > 0 && GetAmmo(client, weapon) < g_Setting_AmmoUsed[weapon])
		return;
	
	g_StartupTime[client] += 0.1;

	if (g_StartupTime[client] - GetGameTime() <= g_Setting_Startup[weapon])
		return;
	
	if (g_IntervalTime[client] > 0 && GetGameTime() - g_IntervalTime[client] < g_Setting_Interval[weapon])
		return;
	
	g_IntervalTime[client] = GetGameTime();
	
	if (g_Setting_ClipUsed[weapon] > 0)
		SetClip(weapon, GetClip(weapon) - g_Setting_ClipUsed[weapon]);
	
	if (g_Setting_AmmoUsed[weapon] > 0)
		StripAmmo(client, weapon, g_Setting_AmmoUsed[weapon]);

	float vecOrigin[3];
	GetClientEyePosition(client, vecOrigin);

	float vecAngles[3];
	GetClientEyeAngles(client, vecAngles);

	float vecOffsets[3];
	StringToVector(g_Setting_Offsets[weapon], vecOffsets, view_as<float>({50.0, 0.0, 0.0}));

	VectorAddRotatedOffset(vecAngles, vecOrigin, vecOffsets);

	if (strlen(g_Setting_SpawnParticle[weapon]) > 0)
		TE_Particle(g_Setting_SpawnParticle[weapon], vecOrigin);

	int team = (g_Setting_FriendlyFire[weapon] && client > 0) ? GetClientTeam(client) : 0;

	int projectile = TF2_FireProjectile(vecOrigin, vecAngles, g_Setting_Entity[weapon], client, team, g_Setting_Speed[weapon], g_Setting_Damage[weapon], true, weapon);

	if (IsValidEntity(projectile))
	{
		if (strlen(g_Setting_RenderMode[weapon]) > 0)
			SetEntityRenderMode(projectile, GetRenderModeByName(g_Setting_RenderMode[weapon]));
		
		if (strlen(g_Setting_RenderColor[weapon]) > 0)
			SetEntityRenderColorEx(projectile, GetColorByName(g_Setting_RenderColor[weapon]));

		if (!g_Setting_SetTransmit[weapon])
			SDKHook(projectile, SDKHook_SetTransmit, OnProjectileTransmit);
		
		SetEntitySelfDestruct(projectile, g_Setting_SelfDestruct[weapon]);
	}
}

public Action OnProjectileTransmit(int entity, int client)
{
	return Plugin_Stop;
}
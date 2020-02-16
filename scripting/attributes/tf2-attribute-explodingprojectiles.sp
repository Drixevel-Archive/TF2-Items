//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "exploding projectiles"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
bool g_ExplodingProjectiles[MAX_ENTITY_LIMIT + 1];
bool g_Setting_FriendlyFire[MAX_ENTITY_LIMIT + 1];
bool g_Setting_SelfDamage[MAX_ENTITY_LIMIT + 1];
float g_Setting_Damage[MAX_ENTITY_LIMIT + 1];
float g_Setting_Radius[MAX_ENTITY_LIMIT + 1];
float g_Setting_Magnitude[MAX_ENTITY_LIMIT + 1];
char g_Setting_Particle[MAX_ENTITY_LIMIT + 1][64];
char g_Setting_Sound[MAX_ENTITY_LIMIT + 1][PLATFORM_MAX_PATH];
float g_Setting_Amplitude[MAX_ENTITY_LIMIT + 1];
float g_Setting_Frequency[MAX_ENTITY_LIMIT + 1];
float g_Setting_Duration[MAX_ENTITY_LIMIT + 1];
char g_Setting_DamageType[MAX_ENTITY_LIMIT + 1][32];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Exploding Projectiles", 
	author = "Drixevel", 
	description = "An attribute that allows for exploding projectiles.", 
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
		g_ExplodingProjectiles[weapon] = true;

		attributesdata.GetValue("friendlyfire", g_Setting_FriendlyFire[weapon]);
		attributesdata.GetValue("selfdamage", g_Setting_SelfDamage[weapon]);
		attributesdata.GetValue("damage", g_Setting_Damage[weapon]);
		attributesdata.GetValue("radius", g_Setting_Radius[weapon]);
		attributesdata.GetValue("magnitude", g_Setting_Magnitude[weapon]);
		attributesdata.GetString("particle", g_Setting_Particle[weapon], sizeof(g_Setting_Particle[]));
		attributesdata.GetString("sound", g_Setting_Sound[weapon], sizeof(g_Setting_Sound[]));
		attributesdata.GetValue("amplitude", g_Setting_Amplitude[weapon]);
		attributesdata.GetValue("frequency", g_Setting_Frequency[weapon]);
		attributesdata.GetValue("duration", g_Setting_Duration[weapon]);
		attributesdata.GetString("damagetype", g_Setting_DamageType[weapon], sizeof(g_Setting_DamageType[]));
	}
	else if (StrEqual(action, "remove", false))
	{
		g_ExplodingProjectiles[weapon] = false;
		g_Setting_FriendlyFire[weapon] = false;
		g_Setting_SelfDamage[weapon] = false;
		g_Setting_Damage[weapon] = 0.0;
		g_Setting_Radius[weapon] = 0.0;
		g_Setting_Magnitude[weapon] = 0.0;
		g_Setting_Particle[weapon][0] = '\0';
		g_Setting_Sound[weapon][0] = '\0';
		g_Setting_Amplitude[weapon] = 0.0;
		g_Setting_Frequency[weapon] = 0.0;
		g_Setting_Duration[weapon] = 0.0;
		g_Setting_DamageType[weapon][0] = '\0';
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrContains(classname, "tf_projectile") == 0)
		SDKHook(entity, SDKHook_StartTouchPost, OnProjectileTouch);
}

public void OnProjectileTouch(int entity, int other)
{
	int launcher = -1;
	if ((launcher = GetEntPropEnt(entity, Prop_Send, "m_hLauncher")) < 1 || !g_ExplodingProjectiles[launcher])
		return;

	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

	float origin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);

	int team = (g_Setting_FriendlyFire[launcher] && owner > 0) ? GetClientTeam(owner) : 0;
	int attacker = (g_Setting_SelfDamage[launcher] && owner > 0) ? owner : 0;

	CreateParticle(g_Setting_Particle[launcher], 10.0, origin);
	EmitSoundToAllSafe(g_Setting_Sound[launcher]);
	ScreenShakeAll(SHAKE_START, g_Setting_Amplitude[launcher], g_Setting_Frequency[launcher], g_Setting_Duration[launcher]);
	PushAllPlayersFromPoint(origin, g_Setting_Magnitude[launcher], g_Setting_Radius[launcher], team);
	DamageArea(origin, g_Setting_Radius[launcher], g_Setting_Damage[launcher], attacker, 0, team, GetDamageTypeByName(g_Setting_DamageType[launcher]), -1);
}
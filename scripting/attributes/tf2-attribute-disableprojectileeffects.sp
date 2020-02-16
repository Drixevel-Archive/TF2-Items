//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "disable projectile effects"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
bool g_Setting_DisableProjectileEffects[MAX_ENTITY_LIMIT];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Disable Projectile Effects", 
	author = "Drixevel", 
	description = "Disables all effects for a projectile.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	AddTempEntHook("TFParticleEffect", TempEntHook_ParticleEffect);
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
		g_Setting_DisableProjectileEffects[weapon] = true;
	else if (StrEqual(action, "remove", false))
		g_Setting_DisableProjectileEffects[weapon] = false;
}

public Action TempEntHook_ParticleEffect(const char[] te_name, int[] players, int numPlayers, float delay)
{
	//PrintToServer("[T] m_iParticleSystemIndex = %i, entindex = %i", TE_ReadNum("m_iParticleSystemIndex"), TE_ReadNum("entindex"));

	int m_iParticleSystemIndex = TE_ReadNum("m_iParticleSystemIndex");

	if (m_iParticleSystemIndex == TE_LookupParticle("peejar_impact_milk"))
		return Plugin_Stop;

	return Plugin_Continue;
}

public void OnEntityDestroyed(int entity)
{
	if (entity < MaxClients)
		return;

	char class[32];
	GetEntityClassname(entity, class, sizeof(class));

	if (StrContains(class, "projectile", false) == -1)
		return;

	int weapon = GetEntPropEnt(entity, Prop_Send, "m_hLauncher");

	if (!IsValidEntity(weapon) || g_Setting_DisableProjectileEffects[weapon])
		return;
	
	float vecOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vecOrigin);

	if (StrEqual(class, "tf_projectile_jar_milk"))
		CreateParticle("peejar_impact_milk", 3.0, vecOrigin);
}
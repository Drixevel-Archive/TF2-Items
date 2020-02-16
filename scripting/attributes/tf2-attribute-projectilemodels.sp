//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "projectile models"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
char g_Setting_Model[MAX_ENTITY_LIMIT + 1][PLATFORM_MAX_PATH];
float g_Setting_Scale[MAX_ENTITY_LIMIT + 1];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Projectile Models", 
	author = "Drixevel", 
	description = "An attribute that allows for projectile models.", 
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
		attributesdata.GetString("model", g_Setting_Model[weapon], sizeof(g_Setting_Model[]));
		attributesdata.GetValue("scale", g_Setting_Scale[weapon]);

		if (g_Setting_Scale[weapon] <= 0.0)
			g_Setting_Scale[weapon] = 1.0;
	}
	else if (StrEqual(action, "remove", false))
	{
		g_Setting_Model[weapon][0] = '\0';
		g_Setting_Scale[weapon] = 0.0;
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrContains(classname, "tf_projectile") == 0)
		SDKHook(entity, SDKHook_SpawnPost, OnProjectileSpawnPost);
}

public void OnProjectileSpawnPost(int entity)
{
	int launcher = -1;
	if ((launcher = GetEntPropEnt(entity, Prop_Send, "m_hLauncher")) < 1)
		return;
	
	if (strlen(g_Setting_Model[launcher]) == 0)
		return;
	
	char sModel[PLATFORM_MAX_PATH];
	strcopy(sModel, sizeof(sModel), g_Setting_Model[launcher]);
	
	if (StrContains(sModel, "models/", false) != 0)
		Format(sModel, sizeof(sModel), "models/%s", sModel);
	
	if (IsModelPrecached(sModel))
		SetEntityModel(entity, sModel);
	
	if (g_Setting_Scale[launcher] != 1.0)
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", g_Setting_Scale[launcher]);
}
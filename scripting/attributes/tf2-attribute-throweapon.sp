//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "throw weapon"

//Sourcemod Includes
#include <sourcemod>
#include <misc-sm>
#include <misc-tf>
#include <tf2-items>

//Globals
bool g_Setting_Enabled[4096];

bool g_IsThrowable[4096];

Handle g_hSDKGetSmoothedVelocity;

public Plugin myinfo = 
{
	name = "[TF2-Items] Attribute :: throw weapon", 
	author = "Drixevel", 
	description = "An attribute which allows you to physically throw your weapons.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetVirtual(140);
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
	
	if ((g_hSDKGetSmoothedVelocity = EndPrepSDKCall()) == null)
		LogError("Failed to create SDKCall for GetSmoothedVelocity offset!");
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
		g_Setting_Enabled[weapon] = true;
	else if (StrEqual(action, "remove", false))
		g_Setting_Enabled[weapon] = false;
}

public void TF2_OnButtonPressPost(int client, int button)
{
	if ((button & IN_ATTACK2) != IN_ATTACK2)
		return;
	
	int weapon = GetActiveWeapon(client);

	if (!IsValidEntity(weapon) || !g_Setting_Enabled[weapon])
		return;
	
	char sName[64];
	GetEntityName(weapon, sName, sizeof(sName));

	char sModel[PLATFORM_MAX_PATH];
	if (!TF2Items_GetItemKeyString(sName, "worldmodel", sModel, sizeof(sModel)))
		return;
	
	float vecOrigin[3];
	GetClientEyePosition(client, vecOrigin);

	float vecAngles[3];
	GetClientEyeAngles(client, vecAngles);

	VectorAddRotatedOffset(vecAngles, vecOrigin, view_as<float>({50.0, 0.0, 0.0}));

	float vecVelocity[3];
	AnglesToVelocity(vecAngles, 10000.0, vecVelocity);

	int entity = CreateEntityByName("prop_physics_override");

	if (IsValidEntity(entity))
	{
		DispatchKeyValue(entity, "model", "models/weapons/c_models/c_claymore/c_claymore.mdl");
		DispatchKeyValue(entity, "disableshadows", "1");
		DispatchKeyValueVector(entity, "origin", vecOrigin);
		DispatchKeyValueVector(entity, "angles", vecAngles);
		DispatchKeyValueVector(entity, "basevelocity", vecVelocity);
		DispatchKeyValueVector(entity, "velocity", vecVelocity);
		DispatchSpawn(entity);

		SetEntProp(entity, Prop_Data, "m_MoveCollide", 1);
		SetEntityName(entity, sName);

		TeleportEntity(entity, vecOrigin, vecAngles, vecVelocity);

		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 13);
		SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", client);
		SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", PrecacheModel(sModel));

		SetEntitySelfDestruct(entity, 10.0);
		SDKHook(entity, SDKHook_VPhysicsUpdatePost, OnPhysicsUpdate);
		
		EmitGameSoundToClient(client, "Cleaver.Single");
		TF2_RemoveWeaponSlot(client, GetWeaponSlot(client, weapon));
		g_IsThrowable[entity] = true;

		int kukri = -1;
		if ((kukri = TF2_GiveItem(client, "tf_weapon_club", 3)) != -1)
			EquipWeapon(client, kukri);
	}
}

public void OnPhysicsUpdate(int entity)
{
	int owner = GetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker");

	if (!IsPlayerIndex(owner) || GetEntityMoveType(entity) == MOVETYPE_NONE)
		return;
	
	float origin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", origin);

	float ground[3];
	GetEntGroundCoordinates(entity, ground);
	
	float vel[3];
	if (GetEntitySmoothedVelocity(entity, vel) && GetVectorLength(vel) < 500.0 && GetVectorDistance(origin, ground) <= 10.0)
	{
		SetEntityMoveType(entity, MOVETYPE_NONE);
		EmitGameSoundToClient(owner, "Cleaver.ImpactWorld");
	}

	float velocity[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", velocity);
	
	float angles[3];
	GetVectorAngles(velocity, angles);
	SetEntPropVector(entity, Prop_Data, "m_angRotation", angles);

	float absorigin[3]; float eyeorigin[3];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || i == owner)
			continue;

		GetClientAbsOrigin(i, absorigin);
		GetClientEyePosition(i, eyeorigin);

		if (GetVectorDistance(absorigin, origin) <= 40.0 || GetVectorDistance(eyeorigin, origin) <= 40.0)
		{
			SDKHooks_TakeDamage(i, 0, owner, 5.0, DMG_CLUB, 0);
			SetEntityMoveType(entity, MOVETYPE_NONE);
			SetParent(i, entity);
			EmitGameSoundToClient(owner, "Cleaver.ImpactFlesh");
		}
	}
}

stock void ShowOriginPoint(float origin[3], bool color = true, float life = 99999.0, float size = 1.0, int brightness = 50)
{
	TE_SetupGlowSprite(origin, PrecacheModel(color ? "sprites/redglow1.vmt" : "sprites/blueglow1.vmt"), life, size, brightness);
	TE_SendToAll();
}

public void OnGameFrame()
{
	int entity = -1; int owner;
	while ((entity = FindEntityByClassname(entity, "prop_physics")) != -1)
	{
		if (!g_IsThrowable[entity] || GetEntityMoveType(entity) != MOVETYPE_NONE)
			continue;

		owner = GetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker");

		if (owner > 0 && GetEntitiesDistance(entity, owner) <= 120.0)
		{
			char sName[64];
			GetEntityName(entity, sName, sizeof(sName));

			AcceptEntityInput(entity, "Kill");
			TF2Items_GiveItem(owner, sName, false);
		}
	}
}

bool GetEntitySmoothedVelocity(int entity, float flBuffer[3])
{
    if (!IsValidEntity(entity))
		return false;

    if (g_hSDKGetSmoothedVelocity == null)
    {
        LogError("SDKCall for GetSmoothedVelocity is invalid!");
        return false;
    }
    
    SDKCall(g_hSDKGetSmoothedVelocity, entity, flBuffer);
    return true;
}
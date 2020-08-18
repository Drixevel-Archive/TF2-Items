//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "detonate rockets"

//Sourcemod Includes
#include <sourcemod>
#include <misc-sm>
#include <misc-tf>
#include <tf2-items>
#include <tf2-api>

//Globals
bool g_Setting_DetonateRockets[4096];

ArrayList g_Detonators[MAXPLAYERS + 1];

int g_iLaserMaterial = -1;
int g_iHaloMaterial = -1;

public Plugin myinfo = 
{
	name = "[TF2-Items] Attribute :: Detonate Rockets", 
	author = "Drixevel", 
	description = "An attribute which allows soldiers to detonate their rockets.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{

}

public void OnMapStart()
{
	g_iLaserMaterial = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloMaterial = PrecacheModel("materials/sprites/halo01.vmt");

	PrecacheSound("items/cart_explode.wav");
	PrecacheSound("weapons/stickybomblauncher_det.wav");
	PrecacheSound("weapons/grappling_hook_impact_default.wav");
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
		g_Setting_DetonateRockets[weapon] = true;

		delete g_Detonators[client];
		g_Detonators[client] = new ArrayList();
	}
	else if (StrEqual(action, "remove", false))
	{
		g_Setting_DetonateRockets[weapon] = false;
		delete g_Detonators[client];
	}
}

public void TF2_OnButtonReleasePost(int client, int button)
{
	if ((button & IN_ATTACK2) == IN_ATTACK2)
	{
		int weapon = GetActiveWeapon(client);

		if (IsValidEntity(weapon) && g_Setting_DetonateRockets[weapon] && g_Detonators[client].Length > 0)
		{
			EmitSoundToClientSafe(client, "weapons/stickybomblauncher_det.wav");
			SpeakResponseConceptDelayed(client, "TLK_PLAYER_CHEERS", 0.6);

			CreateTimer(0.2, Timer_DetonateRockets, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action Timer_DetonateRockets(Handle timer, any data)
{
	int client = GetClientOfUserId(data);

	if (!IsPlayerIndex(client) || !IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	int rocket; float vecOrigin[3];
	for (int i = 0; i < g_Detonators[client].Length; i++)
	{
		rocket = EntRefToEntIndex(g_Detonators[client].Get(i));

		if (IsValidEntity(rocket))
		{
			GetEntPropVector(rocket, Prop_Send, "m_vecOrigin", vecOrigin);

			CreateParticle("cinefx_goldrush", vecOrigin, 10.0);
			EmitSoundToAllSafe("items/cart_explode.wav", rocket);
			DamageRadiusWithFalloff(vecOrigin, 1000.0, 10.0, 500.0, client, rocket, DMG_BLAST, GetEntPropEnt(rocket, Prop_Data, "m_hOwnerEntity"));
			PushPlayersFromPoint(vecOrigin, 50.0, 1000.0, GetClientTeam(client) == 2 ? 3 : 2, client);
			ScreenShakeAll(SHAKE_START, 50.0, 150.0, 1.0, 2000.0, vecOrigin);

			AcceptEntityInput(rocket, "Kill");
		}
	}

	g_Detonators[client].Clear();
	return Plugin_Stop;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "tf_projectile_rocket"))
		SDKHook(entity, SDKHook_SpawnPost, OnRocketSpawnPost);
}

public void OnRocketSpawnPost(int entity)
{
	int shooter = -1;
	if ((shooter = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity")) < 1 || !IsClientConnected(shooter) || !IsClientInGame(shooter))
		return;

	int weapon = GetEntPropEnt(entity, Prop_Send, "m_hLauncher");

	if (IsValidEntity(weapon) && g_Setting_DetonateRockets[weapon])
	{
		AcceptEntityInput(entity, "Kill");

		float vecOrigin[3];
		GetClientEyePosition(shooter, vecOrigin);

		float vecAngles[3];
		GetClientEyeAngles(shooter, vecAngles);

		VectorAddRotatedOffset(vecAngles, vecOrigin, view_as<float>({50.0, 0.0, 0.0}));

		float vecLook[3];
		GetClientLookOrigin(shooter, vecLook, true, 0.0);

		int rocket = CreateEntityByName("prop_physics_override");

		if (IsValidEntity(rocket))
		{
			DispatchKeyValue(rocket, "model", "models/weapons/w_models/w_rocket.mdl");
			DispatchKeyValueVector(rocket, "origin", vecLook);
			DispatchKeyValueVector(rocket, "angles", vecAngles);
			DispatchSpawn(rocket);

			TeleportEntity(rocket, vecLook, vecAngles, NULL_VECTOR);
			SetEntityMoveType(rocket, MOVETYPE_NONE);

			SetEntProp(rocket, Prop_Data, "m_CollisionGroup", 13);
			SetEntPropEnt(rocket, Prop_Data, "m_hPhysicsAttacker", shooter);
			SetEntPropEnt(rocket, Prop_Data, "m_hOwnerEntity", weapon);

			g_Detonators[shooter].Push(EntIndexToEntRef(rocket));

			EmitSoundToAllSafe("weapons/grappling_hook_impact_default.wav", rocket);

			AttachParticle(rocket, "mvm_emergency_light_flash");
			AttachParticle(rocket, "cart_flashinglight_glow_red ");

			TE_SetupBeamPoints(vecOrigin, vecLook, g_iLaserMaterial, g_iHaloMaterial, 30, 30, 2.0, 0.5, 0.5, 5, 1.0, view_as<int>({245, 245, 245, 225}), 5);
			TE_SendToAll();
		}
	}
}
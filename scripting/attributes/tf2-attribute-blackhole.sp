//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "blackhole"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
bool g_Setting_Blackhole[MAX_ENTITY_LIMIT];

bool bHasBlackHole[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Blackhole", 
	author = "Drixevel", 
	description = "An attribute which enables Blackhole effects.", 
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
		g_Setting_Blackhole[weapon] = true;
	else if (StrEqual(action, "remove", false))
		g_Setting_Blackhole[weapon] = false;
}

public void TF2_OnButtonPressPost(int client, int button)
{
	if ((button & IN_ATTACK) == IN_ATTACK)
		AttemptBlackHole(client);
}

void AttemptBlackHole(int client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	
	int weapon = GetActiveWeapon(client);

	if (g_Setting_Blackhole[weapon] && !bHasBlackHole[client] && TF2_IsPlayerInCondition(client, TFCond_Zoomed))
	{
		int deduct = 3 - 1;

		int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");

		if (ammotype != -1)
		{
			int current = GetEntProp(client, Prop_Data, "m_iAmmo", _, ammotype) - deduct;

			if (current <= 0)
				current = 0;

			SetEntProp(client, Prop_Data, "m_iAmmo", current, _, ammotype);
		}
		
		float duration = 10.0;
		CreateBlackHole(client, duration);
	}
}

void CreateBlackHole(int client, float duration)
{
	float vecLook[3];
	if (!GetClientCrosshairOrigin(client, vecLook))
		return;

	TFTeam team = TF2_GetClientTeam(client);

	CreateParticle("eb_tp_vortex01", duration, vecLook);
	CreateParticle(team == TFTeam_Red ? "raygun_projectile_red_crit" : "raygun_projectile_blue_crit", duration, vecLook);
	CreateParticle(team == TFTeam_Red ? "eyeboss_vortex_red" : "eyeboss_vortex_blue", duration, vecLook);

	EmitSoundToAll("undead/weapons/moonbeam_spawn.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, vecLook, NULL_VECTOR, true, 0.0);
	
	bHasBlackHole[client] = true;

	DataPack pack;
	CreateDataTimer(0.1, Timer_Pull, pack, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	pack.WriteFloat(0.0);
	pack.WriteCell(GetClientUserId(client));
	pack.WriteFloat(duration);
	pack.WriteFloat(vecLook[0]);
	pack.WriteFloat(vecLook[1]);
	pack.WriteFloat(vecLook[2]);
}

public Action Timer_Pull(Handle timer, DataPack pack)
{
	pack.Reset();

	float time = pack.ReadFloat();
	int client = GetClientOfUserId(pack.ReadCell());
	float fDuration = pack.ReadFloat();

	float pos[3];
	pos[0] =  pack.ReadFloat();
	pos[1] =  pack.ReadFloat();
	pos[2] =  pack.ReadFloat();

	if (time >= fDuration)
	{
		if (client > 0)
			bHasBlackHole[client] = false;
		
		EmitSoundToAll("undead/weapons/moonbeam_loop.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		
		return Plugin_Stop;
	}
	
	pack.Reset();
	pack.WriteFloat(time + 0.1);
	
	EmitSoundToAll("undead/weapons/moonbeam_loop.wav", SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, pos, NULL_VECTOR, true, 0.0);

	int entity = INVALID_ENT_INDEX;
	while ((entity = FindEntityByClassname(entity, "base_boss")) != INVALID_ENT_INDEX)
	{
		float cpos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", cpos);

		if (GetVectorDistance(pos, cpos) > 200.0)
			continue;

		float velocity[3];
		MakeVectorFromPoints(pos, cpos, velocity);
		NormalizeVector(velocity, velocity);
		ScaleVector(velocity, -200.0);
		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, velocity);

		float fSize = GetEntPropFloat(entity, Prop_Send, "m_flModelScale");

		if (fSize > 0.2)
		{
			SetEntPropFloat(entity, Prop_Send, "m_flModelScale", fSize - 0.1);
			SDKHooks_TakeDamage(entity, -1, client, 1.0);
			continue;
		}

		AcceptEntityInput(entity, "Kill");
	}

	return Plugin_Continue;
}
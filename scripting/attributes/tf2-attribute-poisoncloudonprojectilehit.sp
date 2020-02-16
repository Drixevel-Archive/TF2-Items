//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "poison cloud on projectile impact"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
bool g_PoisonCloudOnHit[MAX_ENTITY_LIMIT];
char g_Setting_Particle_Impact[MAX_ENTITY_LIMIT][MAX_NAME_LENGTH];
float g_Setting_Active_Timer[MAX_ENTITY_LIMIT];
float g_Setting_Damage_Per_Tick[MAX_ENTITY_LIMIT];
float g_Setting_Distance_Per_Tick[MAX_ENTITY_LIMIT];
char g_Setting_DamageType_Per_Tick[MAX_ENTITY_LIMIT][32];
char g_Setting_DamageForce_Per_Tick[MAX_ENTITY_LIMIT][128];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: poison cloud on projectile impact", 
	author = "Drixevel", 
	description = "An attribute that allows for poison clouds to be created on projectile hit.", 
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
		g_PoisonCloudOnHit[weapon] = true;
		attributesdata.GetString("particle_impact", g_Setting_Particle_Impact[weapon], sizeof(g_Setting_Particle_Impact[]));
		attributesdata.GetValue("active_timer", g_Setting_Active_Timer[weapon]);
		attributesdata.GetValue("damage_per_tick", g_Setting_Damage_Per_Tick[weapon]);
		attributesdata.GetValue("distance_per_tick", g_Setting_Distance_Per_Tick[weapon]);
		attributesdata.GetString("damagetype_per_tick", g_Setting_DamageType_Per_Tick[weapon], sizeof(g_Setting_DamageType_Per_Tick[]));
		attributesdata.GetString("damageforce_per_tick", g_Setting_DamageForce_Per_Tick[weapon], sizeof(g_Setting_DamageForce_Per_Tick[]));
	}
	else if (StrEqual(action, "remove", false))
	{
		g_PoisonCloudOnHit[weapon] = false;
		g_Setting_Particle_Impact[weapon][0] = '\0';
		g_Setting_Active_Timer[weapon] = 0.0;
		g_Setting_Damage_Per_Tick[weapon] = 0.0;
		g_Setting_Distance_Per_Tick[weapon] = 0.0;
		g_Setting_DamageType_Per_Tick[weapon][0] = '\0';
		g_Setting_DamageForce_Per_Tick[weapon][0] = '\0';
	}
}

Handle g_Timer_PoisonActive[MAX_ENTITY_LIMIT];
float g_PoisonActive[MAX_ENTITY_LIMIT];

public void OnEntityDestroyed(int entity)
{
	char class[32];
	GetEntityClassname(entity, class, sizeof(class));

	if (StrContains(class, "projectile", false) == -1)
		return;

	int weapon = GetEntPropEnt(entity, Prop_Send, "m_hLauncher");

	if (!IsValidEntity(weapon) || !g_PoisonCloudOnHit[weapon])
		return;
	
	float vecOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vecOrigin);

	if (strlen(g_Setting_Particle_Impact[weapon]) > 0)
		TE_Particle(g_Setting_Particle_Impact[weapon], vecOrigin);

	delete g_Timer_PoisonActive[weapon];

	g_PoisonActive[weapon] = g_Setting_Active_Timer[weapon];
	DataPack pack;
	g_Timer_PoisonActive[weapon] = CreateDataTimer(1.0, Timer_PoisonTick, pack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(weapon);
	pack.WriteCell(GetEntPropEnt(entity, Prop_Send, "m_hThrower"));
	WritePackVector(pack, vecOrigin);
	pack.WriteCell(g_Setting_Damage_Per_Tick[weapon]);
	pack.WriteCell(g_Setting_Distance_Per_Tick[weapon]);
	pack.WriteString(g_Setting_DamageType_Per_Tick[weapon]);
	pack.WriteString(g_Setting_DamageForce_Per_Tick[weapon]);
}

public Action Timer_PoisonTick(Handle timer, DataPack pack)
{
	pack.Reset();

	int weapon = pack.ReadCell();
	int thrower = pack.ReadCell();

	float vecOrigin[3];
	ReadPackVector(pack, vecOrigin);

	float damage_per_tick = pack.ReadCell();
	float distance_per_tick = pack.ReadCell();

	char sDamageType[32];
	pack.ReadString(sDamageType, sizeof(sDamageType));
	int damagetype = GetDamageTypeByName(sDamageType);

	char sDamageForce[128]; float vecForce[3];
	pack.ReadString(sDamageForce, sizeof(sDamageForce));
	StringToVector(sDamageForce, vecForce);

	if (g_PoisonActive[weapon] > 0.0)
	{
		g_PoisonActive[weapon]--;

		if (strlen(g_Setting_Particle_Impact[weapon]) > 0)
			TE_Particle(g_Setting_Particle_Impact[weapon], vecOrigin);

		DamageArea(vecOrigin, distance_per_tick, damage_per_tick, thrower, weapon, 0, damagetype, weapon, vecForce);

		return Plugin_Continue;
	}

	g_Timer_PoisonActive[weapon] = null;
	return Plugin_Stop;
}
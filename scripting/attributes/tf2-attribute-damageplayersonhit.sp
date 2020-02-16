//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "damage players on hit"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
float g_Setting_Damage[MAX_ENTITY_LIMIT];
char g_Setting_DamageType[MAX_ENTITY_LIMIT][32];
float g_Setting_Radius[MAX_ENTITY_LIMIT];
float g_Setting_Interval[MAX_ENTITY_LIMIT];
int g_Setting_MaxTicks[MAX_ENTITY_LIMIT];
float g_Setting_MaxTimer[MAX_ENTITY_LIMIT];
bool g_Setting_ForPlayers[MAX_ENTITY_LIMIT];
bool g_Setting_ForWorld[MAX_ENTITY_LIMIT];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Damage Players On Hit", 
	author = "Drixevel", 
	description = "An attribute which allows the weapon to damage other players on hit.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			OnClientPutInServer(i);
	}
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
	{
		attributesdata.GetValue("damage", g_Setting_Damage[weapon]);
		attributesdata.GetString("damagetype", g_Setting_DamageType[weapon], sizeof(g_Setting_DamageType[]));
		attributesdata.GetValue("radius", g_Setting_Radius[weapon]);
		attributesdata.GetValue("interval", g_Setting_Interval[weapon]);
		attributesdata.GetValue("max_ticks", g_Setting_MaxTicks[weapon]);
		attributesdata.GetValue("max_timer", g_Setting_MaxTimer[weapon]);
		if (!attributesdata.GetValue("for_world", g_Setting_ForWorld[weapon]))
			g_Setting_ForWorld[weapon] = true;
		if (!attributesdata.GetValue("for_players", g_Setting_ForPlayers[weapon]))
			g_Setting_ForPlayers[weapon] = true;
	}
	else if (StrEqual(action, "remove", false))
	{
		g_Setting_Damage[weapon] = 0.0;
		g_Setting_DamageType[weapon][0] = '\0';
		g_Setting_Radius[weapon] = 0.0;
		g_Setting_Interval[weapon] = 0.0;
		g_Setting_MaxTicks[weapon] = 0;
		g_Setting_MaxTimer[weapon] = 0.0;
		g_Setting_ForPlayers[weapon] = false;
		g_Setting_ForWorld[weapon] = false;
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity < MaxClients)
		return;
	
	g_Setting_Damage[entity] = 0.0;
	g_Setting_DamageType[entity][0] = '\0';
	g_Setting_Radius[entity] = 0.0;
	g_Setting_Interval[entity] = 0.0;
	g_Setting_MaxTicks[entity] = 0;
	g_Setting_MaxTimer[entity] = 0.0;
	g_Setting_ForPlayers[entity] = false;
	g_Setting_ForWorld[entity] = false;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	int active = GetActiveWeapon(attacker);

	if (IsValidEntity(active) && g_Setting_ForPlayers[active] && g_Setting_Interval[active] > 0.0)
	{
		DamageArea(damagePosition, g_Setting_Radius[active], g_Setting_Damage[active], attacker, inflictor, GetClientTeam(attacker), GetDamageTypeByName(g_Setting_DamageType[active]));

		DataPack pack = new DataPack();
		pack.WriteCell(0);
		pack.WriteFloat(0.0);
		pack.WriteCell(GetClientUserId(attacker));
		pack.WriteCell(EntIndexToEntRef(inflictor));
		pack.WriteFloat(g_Setting_Interval[active]);
		pack.WriteCell(g_Setting_MaxTicks[active]);
		pack.WriteFloat(g_Setting_MaxTimer[active]);
		
		pack.WriteFloat(g_Setting_Damage[active]);
		pack.WriteString(g_Setting_DamageType[active]);
		pack.WriteFloat(g_Setting_Radius[active]);

		CreateTimer(g_Setting_Interval[active], Timer_DamagePlayers, pack, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public void OnMapStart()
{
	SDKHook(0, SDKHook_TraceAttack, World_TraceAttack);
}

public Action World_TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	int active = GetActiveWeapon(attacker);

	if (IsValidEntity(active) && g_Setting_ForWorld[active] && g_Setting_Interval[active] > 0.0)
	{
		float vecOrigin[3];
		GetClientAbsOrigin(attacker, vecOrigin);

		DamageArea(vecOrigin, g_Setting_Radius[active], g_Setting_Damage[active], attacker, inflictor, GetClientTeam(attacker), GetDamageTypeByName(g_Setting_DamageType[active]));
		
		DataPack pack = new DataPack();
		pack.WriteCell(0);
		pack.WriteFloat(0.0);
		pack.WriteCell(GetClientUserId(attacker));
		pack.WriteCell(EntIndexToEntRef(inflictor));
		pack.WriteFloat(g_Setting_Interval[active]);
		pack.WriteCell(g_Setting_MaxTicks[active]);
		pack.WriteFloat(g_Setting_MaxTimer[active]);
		
		pack.WriteFloat(g_Setting_Damage[active]);
		pack.WriteString(g_Setting_DamageType[active]);
		pack.WriteFloat(g_Setting_Radius[active]);

		CreateTimer(g_Setting_Interval[active], Timer_DamagePlayers, pack, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action Timer_DamagePlayers(Handle timer, DataPack pack)
{
	pack.Reset();
	
	int ticks = pack.ReadCell();
	float time = pack.ReadFloat();
	int userid = pack.ReadCell();
	int inflictor = pack.ReadCell();
	float interval = pack.ReadFloat();
	int max_ticks = pack.ReadCell();
	float max_timer = pack.ReadFloat();

	float damage = pack.ReadFloat();

	char sDamageType[32];
	pack.ReadString(sDamageType, sizeof(sDamageType));

	float radius = pack.ReadFloat();

	bool keepgoing;

	if ((max_ticks > 0 && ticks <= max_ticks))
		keepgoing = true;
	
	if ((max_timer > 0.0 && time <= max_timer))
		keepgoing = true;
		
	if (keepgoing)
	{
		ticks++;
		time += interval;

		pack.Reset();
		pack.WriteCell(ticks);
		pack.WriteFloat(time);
		pack.WriteCell(userid);
		pack.WriteCell(inflictor);
		pack.WriteFloat(interval);
		pack.WriteCell(max_ticks);
		pack.WriteFloat(max_timer);
		
		pack.WriteFloat(damage);
		pack.WriteString(sDamageType);
		pack.WriteFloat(radius);
		
		int client = GetClientOfUserId(userid);

		if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
		{
			float vecOrigin[3];
			GetClientAbsOrigin(client, vecOrigin);

			DamageArea(vecOrigin, radius, damage, client, EntRefToEntIndex(inflictor), GetClientTeam(client), GetDamageTypeByName(sDamageType), GetActiveWeapon(client));
		}
		
		CreateTimer(interval, Timer_DamagePlayers, pack, TIMER_FLAG_NO_MAPCHANGE);

		return Plugin_Continue;
	}
	
	delete pack;
	return Plugin_Stop;
}
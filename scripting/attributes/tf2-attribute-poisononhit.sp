//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "poison on hit"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
bool g_PoisonPlayers[MAX_ENTITY_LIMIT];
float g_Setting_Time[MAX_ENTITY_LIMIT + 1];

bool g_IsPoisoned[MAXPLAYERS + 1];
Handle g_Poison[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Poison on Hit", 
	author = "Drixevel", 
	description = "An attribute that allows for poison on hit.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	HookEvent("player_hurt", Event_OnPlayerHurt);
	HookEvent("player_death", Event_OnPlayerDeath);
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
		g_PoisonPlayers[weapon] = true;
		attributesdata.GetValue("time", g_Setting_Time[weapon]);

		if (g_Setting_Time[weapon] < 0.0)
			g_Setting_Time[weapon] = 0.0;
	}
	else if (StrEqual(action, "remove", false))
	{
		g_PoisonPlayers[weapon] = false;
		g_Setting_Time[weapon] = 0.0;
	}
}

public void Event_OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	int attacker = -1;
	if ((attacker = GetClientOfUserId(event.GetInt("attacker"))) < 1)
		return;
	
	int weapon = GetActiveWeapon(attacker);

	if (!IsValidEntity(weapon) || !g_PoisonPlayers[weapon])
		return;
	
	PoisonClient(client, attacker, g_Setting_Time[weapon]);
}

void PoisonClient(int client, int attacker, float time = 0.0)
{
	if (g_IsPoisoned[client])
		return;
	
	g_IsPoisoned[client] = true;

	if (!IsFakeClient(client))
	{
		int itime = RoundFloat(time);
		ScreenFade(client, itime, itime, FFADE_STAYOUT | FFADE_PURGE, view_as<int>({128, 0, 128, 150}), true);
	}

	TF2_SetPlayerColor(client, 128, 0, 128, 255);
	
	DataPack pack;
	Handle repeat = CreateDataTimer(1.0, Timer_PoisonDamage, pack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(GetClientUserId(attacker));
	TriggerTimer(repeat);
	
	if (time > 0.0)
	{
		delete g_Poison[client];
		g_Poison[client] = CreateTimer(time, Timer_UnpoisonClient, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_PoisonDamage(Handle timer, DataPack data)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int attacker = GetClientOfUserId(data.ReadCell());

	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || !g_IsPoisoned[client])
		return Plugin_Stop;
	
	SDKHooks_TakeDamage(client, 0, attacker, 5.0, DMG_POISON);
	AttachParticle(client, "halloween_ghost_smoke", 5.0, "back_lower");
	
	char sSound[PLATFORM_MAX_PATH];
	FormatEx(sSound, sizeof(sSound), "player/drown%i.wav", GetRandomInt(1, 3));
	EmitSoundToAll(sSound, client);
	
	return Plugin_Continue;
}

public Action Timer_UnpoisonClient(Handle timer, any data)
{
	int client = data;
	g_Poison[client] = null;
	UnpoisonClient(client);
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (g_IsPoisoned[client])
		UnpoisonClient(client);
}

void UnpoisonClient(int client)
{
	if (!g_IsPoisoned[client])
		return;
	
	g_IsPoisoned[client] = false;
	delete g_Poison[client];

	if (!IsFakeClient(client))
		ScreenFade(client, 1, 1, FFADE_STAYOUT | FFADE_PURGE, view_as<int>({255, 255, 255, 0}), true);
	
	TF2_SetPlayerColor(client, 255, 255, 255, 255);
}
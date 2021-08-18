//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "shake on hit"

#define	SHAKE_START 0				// Starts the screen shake for all players within the radius.
#define	SHAKE_STOP 1				// Stops the screen shake for all players within the radius.
#define	SHAKE_AMPLITUDE 2			// Modifies the amplitude of an active screen shake for all players within the radius.
#define	SHAKE_FREQUENCY 3			// Modifies the frequency of an active screen shake for all players within the radius.
#define	SHAKE_START_RUMBLEONLY 4	// Starts a shake effect that only rumbles the controller, no screen effect.
#define	SHAKE_START_NORUMBLE 5		// Starts a shake that does NOT rumble the controller.

//Sourcemod Includes
#include <sourcemod>
#include <sdkhooks>
#include <tf2-items>

//Globals
float g_Setting_Amplitude[2048];
float g_Setting_Frequency[2048];
float g_Setting_Duration[2048];
float g_Setting_Radius[2048];
float g_Setting_Interval[2048];
int g_Setting_MaxTicks[2048];
float g_Setting_MaxTimer[2048];
bool g_Setting_ForPlayers[2048];
bool g_Setting_ForWorld[2048];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Shake On Hit", 
	author = "Drixevel", 
	description = "An attribute which allows the weapon to shake the world or players on hit.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			OnClientPutInServer(i);
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
		attributesdata.GetValue("amplitude", g_Setting_Amplitude[weapon]);
		attributesdata.GetValue("frequency", g_Setting_Frequency[weapon]);
		attributesdata.GetValue("duration", g_Setting_Duration[weapon]);
		attributesdata.GetValue("radius", g_Setting_Radius[weapon]);
		attributesdata.GetValue("interval", g_Setting_Interval[weapon]);
		attributesdata.GetValue("max_ticks", g_Setting_MaxTicks[weapon]);
		attributesdata.GetValue("max_timer", g_Setting_MaxTimer[weapon]);
		if (!attributesdata.GetValue("for_world", g_Setting_ForWorld[weapon]))
			g_Setting_ForWorld[weapon] = false;
		if (!attributesdata.GetValue("for_players", g_Setting_ForPlayers[weapon]))
			g_Setting_ForPlayers[weapon] = false;
	}
	else if (StrEqual(action, "remove", false))
	{
		g_Setting_Amplitude[weapon] = 0.0;
		g_Setting_Frequency[weapon] = 0.0;
		g_Setting_Duration[weapon] = 0.0;
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
	
	g_Setting_Amplitude[entity] = 0.0;
	g_Setting_Frequency[entity] = 0.0;
	g_Setting_Duration[entity] = 0.0;
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
	if (attacker < 1 || attacker > MaxClients)
		return Plugin_Continue;
	
	int active = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");

	if (IsValidEntity(active) && g_Setting_ForPlayers[active] && g_Setting_Interval[active] > 0.0)
	{
		ScreenShakeAll(SHAKE_START, g_Setting_Amplitude[active], g_Setting_Frequency[active], g_Setting_Duration[active], g_Setting_Radius[active], damagePosition);
		
		DataPack pack = new DataPack();
		pack.WriteCell(0);
		pack.WriteFloat(0.0);
		pack.WriteCell(GetClientUserId(attacker));
		pack.WriteFloat(g_Setting_Interval[active]);
		pack.WriteCell(g_Setting_MaxTicks[active]);
		pack.WriteFloat(g_Setting_MaxTimer[active]);
		
		pack.WriteFloat(g_Setting_Amplitude[active]);
		pack.WriteFloat(g_Setting_Frequency[active]);
		pack.WriteFloat(g_Setting_Duration[active]);
		pack.WriteFloat(g_Setting_Radius[active]);

		CreateTimer(g_Setting_Interval[active], Timer_ShakePlayers, pack, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action Timer_ShakePlayers(Handle timer, DataPack pack)
{
	pack.Reset();
	
	int ticks = pack.ReadCell();
	float time = pack.ReadFloat();
	int userid = pack.ReadCell();
	float interval = pack.ReadFloat();
	int max_ticks = pack.ReadCell();
	float max_timer = pack.ReadFloat();

	float amplitude = pack.ReadFloat();
	float frequency = pack.ReadFloat();
	float duration = pack.ReadFloat();
	
	float radius = pack.ReadFloat();

	int client;
	if ((client = GetClientOfUserId(userid)) == 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		delete pack;
		return Plugin_Stop;
	}

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
		pack.WriteFloat(interval);
		pack.WriteCell(max_ticks);
		pack.WriteFloat(max_timer);
		
		pack.WriteFloat(amplitude);
		pack.WriteFloat(frequency);
		pack.WriteFloat(duration);
		pack.WriteFloat(radius);

		float vecOrigin[3];
		GetClientAbsOrigin(client, vecOrigin);

		ScreenShakeAll(SHAKE_START, amplitude, frequency, duration, radius, vecOrigin);
		
		CreateTimer(interval, Timer_ShakePlayers, pack, TIMER_FLAG_NO_MAPCHANGE);

		return Plugin_Continue;
	}
	
	delete pack;
	return Plugin_Stop;
}

public void OnMapStart()
{
	SDKHook(0, SDKHook_TraceAttack, World_TraceAttack);
}

public Action World_TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (attacker < 1 || attacker > MaxClients)
		return Plugin_Continue;
	
	int active = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");

	if (IsValidEntity(active) && g_Setting_ForWorld[active] && g_Setting_Interval[active] > 0.0)
	{
		float vecOrigin[3];
		GetClientAbsOrigin(attacker, vecOrigin);

		ScreenShakeAll(SHAKE_START, g_Setting_Amplitude[active], g_Setting_Frequency[active], g_Setting_Duration[active], g_Setting_Radius[active], vecOrigin);
		
		DataPack pack = new DataPack();
		pack.WriteCell(0);
		pack.WriteFloat(0.0);
		pack.WriteFloat(g_Setting_Interval[active]);
		pack.WriteCell(g_Setting_MaxTicks[active]);
		pack.WriteFloat(g_Setting_MaxTimer[active]);
		
		pack.WriteFloat(g_Setting_Amplitude[active]);
		pack.WriteFloat(g_Setting_Frequency[active]);
		pack.WriteFloat(g_Setting_Duration[active]);
		pack.WriteFloat(vecOrigin[0]);
		pack.WriteFloat(vecOrigin[1]);
		pack.WriteFloat(vecOrigin[2]);
		pack.WriteFloat(g_Setting_Radius[active]);

		CreateTimer(g_Setting_Interval[active], Timer_ShakeWorld, pack, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action Timer_ShakeWorld(Handle timer, DataPack pack)
{
	pack.Reset();
	
	int ticks = pack.ReadCell();
	float time = pack.ReadFloat();
	float interval = pack.ReadFloat();
	int max_ticks = pack.ReadCell();
	float max_timer = pack.ReadFloat();

	float amplitude = pack.ReadFloat();
	float frequency = pack.ReadFloat();
	float duration = pack.ReadFloat();
	
	float vecOrigin[3];
	vecOrigin[0] = pack.ReadFloat();
	vecOrigin[1] = pack.ReadFloat();
	vecOrigin[2] = pack.ReadFloat();
	
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
		pack.WriteFloat(interval);
		pack.WriteCell(max_ticks);
		pack.WriteFloat(max_timer);
		
		pack.WriteFloat(amplitude);
		pack.WriteFloat(frequency);
		pack.WriteFloat(duration);
		pack.WriteFloat(vecOrigin[0]);
		pack.WriteFloat(vecOrigin[1]);
		pack.WriteFloat(vecOrigin[2]);
		pack.WriteFloat(radius);

		ScreenShakeAll(SHAKE_START, amplitude, frequency, duration, radius, vecOrigin);
		
		CreateTimer(interval, Timer_ShakeWorld, pack, TIMER_FLAG_NO_MAPCHANGE);

		return Plugin_Continue;
	}
	
	delete pack;
	return Plugin_Stop;
}

bool ScreenShakeAll(int command = SHAKE_START, float amplitude = 50.0, float frequency = 150.0, float duration = 3.0, float distance = 0.0, float origin[3] = NULL_VECTOR)
{
	if (command == SHAKE_STOP)
		amplitude = 0.0;
	
	bool pb = GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf;
	
	Handle userMessage; float vecOrigin[3];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		GetClientAbsOrigin(i, vecOrigin);
			
		if (distance > 0.0 && GetVectorDistance(origin, vecOrigin) > distance)
			continue;
		
		userMessage = StartMessageOne("Shake", i);

		if (pb)
		{
			PbSetInt(userMessage, "command", command);
			PbSetFloat(userMessage, "local_amplitude", amplitude);
			PbSetFloat(userMessage, "frequency", frequency);
			PbSetFloat(userMessage, "duration", duration);
		}
		else
		{
			BfWriteByte(userMessage, command);		// Shake Command
			BfWriteFloat(userMessage, amplitude);	// shake magnitude/amplitude
			BfWriteFloat(userMessage, frequency);	// shake noise frequency
			BfWriteFloat(userMessage, duration);	// shake lasts this long
		}

		EndMessage();
	}
	
	return true;
}

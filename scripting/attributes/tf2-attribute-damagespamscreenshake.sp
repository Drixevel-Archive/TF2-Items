//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "on damage spam screen shake"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
float g_Setting_Amplitude[MAX_ENTITY_LIMIT];
float g_Setting_Frequency[MAX_ENTITY_LIMIT];
float g_Setting_Duration[MAX_ENTITY_LIMIT];
float g_Setting_Interval[MAX_ENTITY_LIMIT];
int g_Setting_MaxTicks[MAX_ENTITY_LIMIT];
float g_Setting_MaxTimer[MAX_ENTITY_LIMIT];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Damage Spam Screen Shake", 
	author = "Drixevel", 
	description = "An attribute that allows for Screen Shake to be spammed when damaged.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	HookEvent("player_hurt", Event_OnPlayerHurt);
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
		attributesdata.GetValue("amplitude", g_Setting_Amplitude[weapon]);
		attributesdata.GetValue("frequency", g_Setting_Frequency[weapon]);
		attributesdata.GetValue("duration", g_Setting_Duration[weapon]);
		attributesdata.GetValue("interval", g_Setting_Interval[weapon]);
		attributesdata.GetValue("max_ticks", g_Setting_MaxTicks[weapon]);
		attributesdata.GetValue("max_timer", g_Setting_MaxTimer[weapon]);
	}
	else if (StrEqual(action, "remove", false))
	{
		g_Setting_Amplitude[weapon] = 0.0;
		g_Setting_Frequency[weapon] = 0.0;
		g_Setting_Duration[weapon] = 0.0;
		g_Setting_Interval[weapon] = 0.0;
		g_Setting_MaxTicks[weapon] = 0;
		g_Setting_MaxTimer[weapon] = 0.0;
	}
}

public void Event_OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int attackerid = event.GetInt("attacker");
	int attacker = GetClientOfUserId(attackerid);

	if (attacker == 0 || attacker > MaxClients)
		return;
	
	int active = GetActiveWeapon(attacker);

	if (active == -1)
		return;
	
	if (g_Setting_Interval[active] > 0.0)
	{
		int userid = event.GetInt("userid");
		int victim = GetClientOfUserId(userid);

		if (victim == 0)
			return;

		ScreenShake(victim, SHAKE_START, g_Setting_Amplitude[active], g_Setting_Frequency[active], g_Setting_Duration[active]);
		
		DataPack pack = new DataPack();
		pack.WriteCell(0);
		pack.WriteFloat(0.0);
		pack.WriteCell(userid);
		pack.WriteFloat(g_Setting_Interval[active]);
		pack.WriteCell(g_Setting_MaxTicks[active]);
		pack.WriteFloat(g_Setting_MaxTimer[active]);
		
		pack.WriteFloat(g_Setting_Amplitude[active]);
		pack.WriteFloat(g_Setting_Frequency[active]);
		pack.WriteFloat(g_Setting_Duration[active]);

		CreateTimer(g_Setting_Interval[active], Timer_ShakePlayer, pack, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_ShakePlayer(Handle timer, DataPack pack)
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

	if ((max_ticks > 0 && ticks <= max_ticks || (max_timer > 0.0 && time <= max_timer)))
	{
		ticks++;
		time++;

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

		int victim = GetClientOfUserId(userid);

		if (victim > 0)
			ScreenShake(victim, SHAKE_START, amplitude, frequency, duration);
		
		CreateTimer(interval, Timer_ShakePlayer, pack, TIMER_FLAG_NO_MAPCHANGE);

		return Plugin_Continue;
	}
	
	delete pack;
	return Plugin_Stop;
}
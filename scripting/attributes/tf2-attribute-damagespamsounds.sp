//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "on damage spam sound"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
char g_Setting_Sound[MAX_ENTITY_LIMIT][PLATFORM_MAX_PATH];
float g_Setting_Multiplier[MAX_ENTITY_LIMIT];
float g_Setting_Interval[MAX_ENTITY_LIMIT];
int g_Setting_MaxTicks[MAX_ENTITY_LIMIT];
float g_Setting_MaxTimer[MAX_ENTITY_LIMIT];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Damage Spam Sounds", 
	author = "Drixevel", 
	description = "An attribute that allows for sounds to be spammed when damaged.", 
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
		attributesdata.GetString("sound", g_Setting_Sound[weapon], sizeof(g_Setting_Sound[]));
		attributesdata.GetValue("multiplier", g_Setting_Multiplier[weapon]);
		attributesdata.GetValue("interval", g_Setting_Interval[weapon]);
		attributesdata.GetValue("max_ticks", g_Setting_MaxTicks[weapon]);
		attributesdata.GetValue("max_timer", g_Setting_MaxTimer[weapon]);
	}
	else if (StrEqual(action, "remove", false))
	{
		g_Setting_Sound[weapon][0] = '\0';
		g_Setting_Multiplier[weapon] = 0.0;
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

		for (int i = 0; i < g_Setting_Multiplier[active]; i++)
			EmitSoundToClient(victim, g_Setting_Sound[active]);
		
		DataPack pack = new DataPack();
		pack.WriteCell(0);
		pack.WriteFloat(0.0);
		pack.WriteCell(userid);
		pack.WriteFloat(g_Setting_Interval[active]);
		pack.WriteCell(g_Setting_MaxTicks[active]);
		pack.WriteFloat(g_Setting_MaxTimer[active]);
		
		pack.WriteString(g_Setting_Sound[active]);
		pack.WriteCell(g_Setting_Multiplier[active]);

		CreateTimer(g_Setting_Interval[active], Timer_DamagePlayer, pack, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_DamagePlayer(Handle timer, DataPack pack)
{
	pack.Reset();
	
	int ticks = pack.ReadCell();
	float time = pack.ReadFloat();
	int userid = pack.ReadCell();
	float interval = pack.ReadFloat();
	int max_ticks = pack.ReadCell();
	float max_timer = pack.ReadFloat();

	char sSound[PLATFORM_MAX_PATH];
	pack.ReadString(sSound, sizeof(sSound));

	int multiplier = pack.ReadCell();

	if ((max_ticks > 0 && ticks <= max_ticks) || (max_timer > 0.0 && time <= max_timer))
	{
		ticks++;
		time++;

		pack.Reset();
		pack.WriteCell(ticks);
		pack.WriteFloat(time);
		pack.WriteCell(userid);
		pack.WriteFloat(interval);
		pack.WriteCell(max_ticks);
		pack.WriteCell(max_timer);

		pack.WriteString(sSound);
		pack.WriteCell(multiplier);

		int victim = GetClientOfUserId(userid);

		if (victim > 0)
		{
			for (int i = 0; i < multiplier; i++)
				EmitSoundToAll(sSound, victim);
		}
		
		CreateDataTimer(interval, Timer_DamagePlayer, pack, TIMER_FLAG_NO_MAPCHANGE);

		return Plugin_Continue;
	}
	
	delete pack;
	return Plugin_Stop;
}
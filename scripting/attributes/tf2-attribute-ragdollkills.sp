//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define ATTRIBUTE_NAME "ragdoll kills"

//Sourcemod Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <tf2-weapons>

//Globals
int g_RagdollType[MAX_ENTITY_LIMIT];

public Plugin myinfo = 
{
	name = "[TF2-Weapons] Attribute :: Ragdoll Kills", 
	author = "Drixevel", 
	description = "An attribute that allows for ragdoll kills.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
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
		char sRagdollType[64];
		attributesdata.GetString("type", sRagdollType, sizeof(sRagdollType));

		if (IsStringNumeric(sRagdollType))
		{
			switch (StringToInt(sRagdollType))
			{
				case 0: g_RagdollType[weapon] = RAG_GIBBED;
				case 1: g_RagdollType[weapon] = RAG_BURNING;
				case 2: g_RagdollType[weapon] = RAG_ELECTROCUTED;
				case 3: g_RagdollType[weapon] = RAG_FEIGNDEATH;
				case 4: g_RagdollType[weapon] = RAG_WASDISGUISED;
				case 5: g_RagdollType[weapon] = RAG_BECOMEASH;
				case 6: g_RagdollType[weapon] = RAG_ONGROUND;
				case 7: g_RagdollType[weapon] = RAG_CLOAKED;
				case 8: g_RagdollType[weapon] = RAG_GOLDEN;
				case 9: g_RagdollType[weapon] = RAG_ICE;
				case 10: g_RagdollType[weapon] = RAG_CRITONHARDCRIT;
				case 11: g_RagdollType[weapon] = RAG_HIGHVELOCITY;
			}
		}
		else
		{
			if (StrContains(sRagdollType, "gibbed", false) != -1)
				g_RagdollType[weapon] = RAG_GIBBED;
			else if (StrContains(sRagdollType, "burning", false) != -1)
				g_RagdollType[weapon] = RAG_BURNING;
			else if (StrContains(sRagdollType, "electrocuted", false) != -1)
				g_RagdollType[weapon] = RAG_ELECTROCUTED;
			else if (StrContains(sRagdollType, "feigndeath", false) != -1)
				g_RagdollType[weapon] = RAG_FEIGNDEATH;
			else if (StrContains(sRagdollType, "wasdisguised", false) != -1)
				g_RagdollType[weapon] = RAG_WASDISGUISED;
			else if (StrContains(sRagdollType, "becomeash", false) != -1)
				g_RagdollType[weapon] = RAG_BECOMEASH;
			else if (StrContains(sRagdollType, "onground", false) != -1)
				g_RagdollType[weapon] = RAG_ONGROUND;
			else if (StrContains(sRagdollType, "cloaked", false) != -1)
				g_RagdollType[weapon] = RAG_CLOAKED;
			else if (StrContains(sRagdollType, "golden", false) != -1)
				g_RagdollType[weapon] = RAG_GOLDEN;
			else if (StrContains(sRagdollType, "ice", false) != -1)
				g_RagdollType[weapon] = RAG_ICE;
			else if (StrContains(sRagdollType, "critonhardcrit", false) != -1)
				g_RagdollType[weapon] = RAG_CRITONHARDCRIT;
			else if (StrContains(sRagdollType, "highvelocity", false) != -1)
				g_RagdollType[weapon] = RAG_HIGHVELOCITY;
		}
	}
	else if (StrEqual(action, "remove", false))
	{
		g_RagdollType[weapon] = 0;
	}
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	
	int client = -1;
	if ((client = GetClientOfUserId(userid)) < 1 || client < 1)
		return;
	
	int attacker = -1;
	if ((attacker = event.GetInt("attacker")) < 1)
		return;
	
	int weapon = GetActiveWeapon(attacker);
	
	if (!IsValidEntity(weapon) || g_RagdollType[weapon] == 0)
		return;
	
	DataPack pack = new DataPack();
	pack.WriteCell(userid);
	pack.WriteCell(g_RagdollType[weapon]);
	
	RequestFrame(Frame_CreateRagdoll, pack);
	RequestFrame(Frame_CreateRagdoll, pack);
}

public void Frame_CreateRagdoll(DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	int flags = pack.ReadCell();
	delete pack;

	if (client > 0)
	{
		TF2_RemoveRagdoll(client);
		TF2_CreateRagdoll(client, 5.0, flags);
	}
}
//Pragma
#pragma semicolon 1
#pragma newdecls required

//Defines
#define EF_NODRAW 32

#define ARRAY_SIZE	2
#define ARRAY_ITEM	0
#define ARRAY_FLAGS	1

//Sourcemod Includes
#include <sourcemod>

#include <misc-sm>
#include <misc-colors>
#include <misc-tf>

#include <tf2items>
#include <tf2attributes>
#include <tf2-items>

//ConVars
ConVar convar_WeaponMenuOnSpawn;
ConVar convar_DisableMenu;

//Forwards
Handle g_Forward_OnRegisterAttributes;
Handle g_Forward_OnRegisterAttributesPost;
Handle g_Forward_OnRegisterWeaponConfig;
Handle g_Forward_OnRegisterWeaponSetting;
Handle g_Forward_OnRegisterWeaponSettingStr;
Handle g_Forward_OnRegisterWeaponConfigPost;

//Globals
bool g_Late;
bool g_IsCustom[MAX_ENTITY_LIMIT + 1];

ArrayList g_WeaponsList;
StringMap g_WeaponDescription;
StringMap g_WeaponFlags;
StringMap g_WeaponSteamIDs;
StringMap g_WeaponClasses;
StringMap g_WeaponSlot;
StringMap g_WeaponEntity;
StringMap g_WeaponIndex;
StringMap g_WeaponSize;
StringMap g_WeaponSkin;
StringMap g_WeaponRenderMode;
StringMap g_WeaponRenderFx;
StringMap g_WeaponRenderColor;
StringMap g_WeaponViewmodel;
StringMap g_WeaponWorldmodel;
StringMap g_WeaponQuality;
StringMap g_WeaponLevel;
StringMap g_WeaponKillIcon;
StringMap g_WeaponLogName;
StringMap g_WeaponClip;
StringMap g_WeaponAmmo;
StringMap g_WeaponMetal;
StringMap g_WeaponParticle;
StringMap g_WeaponParticleTime;
StringMap g_WeaponAttributesData;	//Handle Hell
StringMap g_WeaponSoundsData;		//Handle Hell

//Attributes Data
ArrayList g_AttributesList;
StringMap g_Attributes_Calls;

//Wearables
Handle g_SDK_EquipWearable;

//Attributes
Handle g_hGetItemSchema;
Handle g_hGetAttributeDefinitionByName;

//Overrides
StringMap g_hPlayerInfo;
ArrayList g_hPlayerArray;
ArrayList g_hGlobalSettings;

public Plugin myinfo = 
{
	name = "[TF2] Items", 
	author = "Drixevel", 
	description = "A simple and effective TF2 items plugin which allows for weapon and cosmetic customizations.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("tf2-items");

	CreateNative("TF2Items_AllowAttributeRegisters", Native_AllowAttributeRegisters);
	CreateNative("TF2Items_RegisterAttribute", Native_RegisterAttribute);
	CreateNative("TF2Items_GiveWeapon", Native_GiveWeapon);
	CreateNative("TF2Items_IsCustom", Native_IsCustom);
	CreateNative("TF2Items_RefillMag", Native_RefillMag);
	CreateNative("TF2Items_RefillAmmo", Native_RefillAmmo);
	
	CreateNative("TF2Items_EquipWearable", Native_EquipWearable);
	CreateNative("TF2Items_EquipViewmodel", Native_EquipViewmodel);

	CreateNative("TF2Items_GetWeaponKeyInt", Native_GetWeaponKeyInt);
	CreateNative("TF2Items_GetWeaponKeyFloat", Native_GetWeaponKeyFloat);
	CreateNative("TF2Items_GetWeaponKeyString", Native_GetWeaponKeyString);

	g_Forward_OnRegisterAttributes = CreateGlobalForward("TF2Items_OnRegisterAttributes", ET_Event);
	g_Forward_OnRegisterAttributesPost = CreateGlobalForward("TF2Items_OnRegisterAttributesPost", ET_Ignore);
	g_Forward_OnRegisterWeaponConfig = CreateGlobalForward("TF2Items_OnRegisterWeaponConfig", ET_Event, Param_String, Param_String, Param_Cell);
	g_Forward_OnRegisterWeaponSetting = CreateGlobalForward("TF2Items_OnRegisterWeaponSetting", ET_Event, Param_String, Param_String, Param_Any);
	g_Forward_OnRegisterWeaponSettingStr = CreateGlobalForward("TF2Items_OnRegisterWeaponSettingStr", ET_Event, Param_String, Param_String, Param_String);
	g_Forward_OnRegisterWeaponConfigPost = CreateGlobalForward("TF2Items_OnRegisterWeaponConfigPost", ET_Ignore, Param_String, Param_String, Param_Cell);

	g_Late = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CSetPrefix("{crimson}[Weapons]");
	
	convar_WeaponMenuOnSpawn = CreateConVar("sm_tf2_items_spawnmenu", "0", "Whether to display the weapons menu on spawn for players.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_DisableMenu = CreateConVar("sm_tf2_items_disablemenu", "1", "Disables the built-in menu for non-admins.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AutoExecConfig();

	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("post_inventory_application", Event_OnResupply);
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
	AddNormalSoundHook(OnSoundPlay);

	g_WeaponsList = new ArrayList(ByteCountToCells(MAX_WEAPON_NAME_LENGTH));
	g_WeaponDescription = new StringMap();
	g_WeaponFlags = new StringMap();
	g_WeaponSteamIDs = new StringMap();
	g_WeaponClasses = new StringMap();
	g_WeaponSlot = new StringMap();
	g_WeaponEntity = new StringMap();
	g_WeaponIndex = new StringMap();
	g_WeaponSize = new StringMap();
	g_WeaponSkin = new StringMap();
	g_WeaponRenderMode = new StringMap();
	g_WeaponRenderFx = new StringMap();
	g_WeaponRenderColor = new StringMap();
	g_WeaponViewmodel = new StringMap();
	g_WeaponWorldmodel = new StringMap();
	g_WeaponQuality = new StringMap();
	g_WeaponLevel = new StringMap();
	g_WeaponKillIcon = new StringMap();
	g_WeaponLogName = new StringMap();
	g_WeaponClip = new StringMap();
	g_WeaponAmmo = new StringMap();
	g_WeaponMetal = new StringMap();
	g_WeaponParticle = new StringMap();
	g_WeaponParticleTime = new StringMap();
	g_WeaponAttributesData = new StringMap();
	g_WeaponSoundsData = new StringMap();

	g_AttributesList = new ArrayList(ByteCountToCells(MAX_ATTRIBUTE_NAME_LENGTH));
	g_Attributes_Calls = new StringMap();

	RegConsoleCmd("sm_w", Command_Weapons);
	RegConsoleCmd("sm_weapons", Command_Weapons);
	RegConsoleCmd("sm_c", Command_Weapons);
	RegConsoleCmd("sm_cws", Command_Weapons);
	RegConsoleCmd("sm_customweapons", Command_Weapons);
	RegConsoleCmd("sm_weapon", Command_Weapons);
	RegConsoleCmd("sm_customweapon", Command_Weapons);
	RegConsoleCmd("sm_giveweapon", Command_Weapons);

	RegAdminCmd("sm_reloadweapons", Command_ReloadWeapons, ADMFLAG_ROOT);
	RegAdminCmd("sm_rw", Command_ReloadWeapons, ADMFLAG_ROOT);
	RegAdminCmd("sm_reloadattributes", Command_ReloadAttributes, ADMFLAG_ROOT);
	RegAdminCmd("sm_ra", Command_ReloadAttributes, ADMFLAG_ROOT);

	RegAdminCmd("sm_createweapon", Command_CreateWeapon, ADMFLAG_ROOT);

	Handle gamedata = LoadGameConfigFile("sm-tf2.games");

	if (gamedata == null)
		SetFailState("Could not find sm-tf2.games gamedata!");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(GameConfGetOffset(gamedata, "RemoveWearable") - 1);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	if ((g_SDK_EquipWearable = EndPrepSDKCall()) == null)
		LogMessage("Failed to create call: CBasePlayer::EquipWearable");

	//GetItemSchema()
	//StartPrepSDKCall(SDKCall_Static);
	//PrepSDKCall_SetSignature(SDKLibrary_Server, "\xE8\x2A\x2A\x2A\x2A\x83\xC0\x04\xC3", 9);
	//PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);	//Returns address of CEconItemSchema
	//if ((g_hGetItemSchema = EndPrepSDKCall()) == null)
		//SetFailState("Failed to create SDKCall for GetItemSchema signature!"); 	
	
	//CEconItemSchema::GetAttributeDefinitionByName(const char* name)
	//StartPrepSDKCall(SDKCall_Raw);
	//PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x8B\xEC\x83\xEC\x18\x83\x7D\x08\x00\x53\x56\x57\x8B\xD9\x75\x2A\x33\xC0\x5F", 20);
	//PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	//PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);	//Returns address of CEconItemAttributeDefinition
	//if ((g_hGetAttributeDefinitionByName = EndPrepSDKCall()) == null)
		//SetFailState("Failed to create SDKCall for CEconItemSchema::GetAttributeDefinitionByName signature!"); 
	
	delete gamedata;

	//RegAdminCmd("sm_convert", Convert, ADMFLAG_ROOT);
}

public void OnConfigsExecuted()
{
	if (g_Late)
	{
		g_Late = false;

		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i))
				OnClientPutInServer(i);

		CallAttributeRegistrations();
	}

	ParseWeapons();
	ParseOverrides();

	//debugging weapons faster
	int drixevel = -1;
	if ((drixevel = GetDrixevel()) > 0 && IsClientInGame(drixevel))
		OpenWeaponsMenu(drixevel);
}

bool ParseWeapons()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/tf2-weapons");

	if (!DirExists(sPath))
	{
		CreateDirectory(sPath, 511);

		if (!DirExists(sPath))
			LogError("Error while generating directory: %s", sPath);
	}

	g_WeaponsList.Clear();
	g_WeaponDescription.Clear();
	g_WeaponFlags.Clear();
	g_WeaponSteamIDs.Clear();
	g_WeaponClasses.Clear();
	g_WeaponSlot.Clear();
	g_WeaponEntity.Clear();
	g_WeaponIndex.Clear();
	g_WeaponSize.Clear();
	g_WeaponSkin.Clear();
	g_WeaponRenderMode.Clear();
	g_WeaponRenderFx.Clear();
	g_WeaponRenderColor.Clear();
	g_WeaponViewmodel.Clear();
	g_WeaponWorldmodel.Clear();
	g_WeaponQuality.Clear();
	g_WeaponLevel.Clear();
	g_WeaponKillIcon.Clear();
	g_WeaponLogName.Clear();
	g_WeaponClip.Clear();
	g_WeaponAmmo.Clear();
	g_WeaponMetal.Clear();
	g_WeaponParticle.Clear();
	g_WeaponParticleTime.Clear();
	g_WeaponAttributesData.Clear();
	g_WeaponSoundsData.Clear();

	StrCat(sPath, sizeof(sPath), "/weapons");

	if (!DirExists(sPath))
	{
		CreateDirectory(sPath, 511);

		if (!DirExists(sPath))
			LogError("Error while generating directory for weapons directory: %s", sPath);
	}

	ParseWeaponsFolder(sPath);
}

bool ParseWeaponsFolder(const char[] path)
{
	if (!DirExists(path, true))
		return false;

	Handle dir = OpenDirectory(path);

	if (dir == null)
		return false;

	char sFile[PLATFORM_MAX_PATH];
	FileType dir_type;
	
	while (ReadDirEntry(dir, sFile, sizeof(sFile), dir_type))
	{
		TrimString(sFile);

		switch (dir_type)
		{
			case FileType_File:
			{
				if (StrContains(sFile, ".cfg") == -1)
					continue;
				
				Format(sFile, sizeof(sFile), "%s/%s", path, sFile);
				ParseWeaponConfig(sFile);
			}
			case FileType_Directory:
			{
				if (StrEqual(sFile, ".") || StrEqual(sFile, ".."))
					continue;
				
				Format(sFile, sizeof(sFile), "%s/%s", path, sFile);
				ParseWeaponsFolder(sFile);
			}
		}
	}

	delete dir;
	return true;
}

bool ParseWeaponConfig(const char[] file)
{
	KeyValues kv = new KeyValues("weapon");

	if (!kv.ImportFromFile(file))
	{
		delete kv;
		return false;
	}

	//Simple way to skip configs from being parsed.
	if (kv.GetNum("skip") > 0)
	{
		delete kv;
		return true;
	}

	//name
	char sName[MAX_WEAPON_NAME_LENGTH];
	kv.GetString("name", sName, sizeof(sName));

	if (strlen(sName) == 0)
	{
		delete kv;
		return false;
	}

	Call_StartForward(g_Forward_OnRegisterWeaponConfig);
	Call_PushString(sName);
	Call_PushString(file);
	Call_PushCell(kv);
	Action result = Plugin_Continue; Call_Finish(result);

	if (kv == null)
	{
		LogError("Error while accessing '%s' weapon config: API killed the Settings handle.", sName);
		return false;
	}

	if (result >= Plugin_Handled)
	{
		delete kv;
		return false;
	}
	
	g_WeaponsList.PushString(sName);

	//description
	char sDescription[MAX_DESCRIPTION_LENGTH];
	kv.GetString("description", sDescription, sizeof(sDescription));
	g_WeaponDescription.SetString(sName, sDescription);
	CallSettingsForwardStr(sName, "description", sDescription);

	//flags
	char sFlags[MAX_FLAGS_LENGTH];
	kv.GetString("flags", sFlags, sizeof(sFlags));
	g_WeaponFlags.SetString(sName, sFlags);
	CallSettingsForwardStr(sName, "flags", sFlags);

	//flags
	char sSteamIDs[2048];
	kv.GetString("steamids", sSteamIDs, sizeof(sSteamIDs));
	g_WeaponSteamIDs.SetString(sName, sSteamIDs);
	CallSettingsForwardStr(sName, "steamids", sSteamIDs);

	//classes
	char sClasses[2048];
	kv.GetString("classes", sClasses, sizeof(sClasses));
	g_WeaponClasses.SetString(sName, sClasses);
	CallSettingsForwardStr(sName, "classes", sClasses);

	//slots
	char sSlot[2048];
	kv.GetString("slot", sSlot, sizeof(sSlot));
	
	int iSlot = IsStringNumeric(sSlot) ? StringToInt(sSlot) : GetSlotIDFromName(sSlot);
	g_WeaponSlot.SetValue(sName, iSlot);
	CallSettingsForward(sName, "slot", iSlot);

	//entity
	char sEntity[MAX_ENTITY_CLASSNAME_LENGTH];
	kv.GetString("entity", sEntity, sizeof(sEntity));
	g_WeaponEntity.SetString(sName, sEntity);
	CallSettingsForwardStr(sName, "entity", sEntity);

	//index
	int iIndex = kv.GetNum("index");
	g_WeaponIndex.SetValue(sName, iIndex);
	CallSettingsForward(sName, "index", iIndex);

	//size
	float fSize = kv.GetFloat("size", 1.0);
	g_WeaponSize.SetValue(sName, fSize);
	CallSettingsForward(sName, "size", fSize);

	//skin
	int iSkin = kv.GetNum("skin");
	g_WeaponSkin.SetValue(sName, iSkin);
	CallSettingsForward(sName, "skin", iSkin);

	//rendermode
	char sRenderMode[32];
	kv.GetString("rendermode", sRenderMode, sizeof(sRenderMode));

	RenderMode mode = GetRenderModeByName(sRenderMode);
	g_WeaponRenderMode.SetValue(sName, mode);
	CallSettingsForward(sName, "rendermode", mode);

	//renderfx
	char sRenderFx[32];
	kv.GetString("renderfx", sRenderFx, sizeof(sRenderFx));
	
	RenderFx fx = GetRenderFxByName(sRenderFx);
	g_WeaponRenderFx.SetValue(sName, GetRenderFxByName(sRenderFx));
	CallSettingsForward(sName, "renderfx", fx);

	//rendercolor
	char sRenderColor[32];
	kv.GetString("rendercolor", sRenderColor, sizeof(sRenderColor));
	g_WeaponRenderColor.SetArray(sName, GetColorByName(sRenderColor), 4);

	//viewmodel
	char sViewmodel[PLATFORM_MAX_PATH];
	kv.GetString("viewmodel", sViewmodel, sizeof(sViewmodel));
	g_WeaponViewmodel.SetString(sName, sViewmodel);
	CallSettingsForwardStr(sName, "viewmodel", sViewmodel);

	//worldmodel
	char sWorldModel[PLATFORM_MAX_PATH];
	kv.GetString("worldmodel", sWorldModel, sizeof(sWorldModel));
	g_WeaponWorldmodel.SetString(sName, sWorldModel);
	CallSettingsForwardStr(sName, "worldmodel", sWorldModel);

	//quality
	char sQuality[QUALITY_NAME_LENGTH];
	kv.GetString("quality", sQuality, sizeof(sQuality));
	g_WeaponQuality.SetString(sName, sQuality);
	CallSettingsForwardStr(sName, "quality", sQuality);

	//level
	int iLevel = kv.GetNum("level");
	g_WeaponLevel.SetValue(sName, iLevel);
	CallSettingsForward(sName, "level", iLevel);

	//killicon
	char sKillIcon[64];
	kv.GetString("killicon", sKillIcon, sizeof(sKillIcon));
	g_WeaponKillIcon.SetString(sName, sKillIcon);
	CallSettingsForwardStr(sName, "killicon", sKillIcon);

	//logname
	char sLogName[64];
	kv.GetString("logname", sLogName, sizeof(sLogName));
	g_WeaponLogName.SetString(sName, sLogName);
	CallSettingsForwardStr(sName, "logname", sLogName);

	//clip
	int iClip = kv.GetNum("clip", -1);
	g_WeaponClip.SetValue(sName, iClip);
	CallSettingsForward(sName, "clip", iClip);

	//ammo
	int iAmmo = kv.GetNum("ammo", -1);
	g_WeaponAmmo.SetValue(sName, iAmmo);
	CallSettingsForward(sName, "ammo", iAmmo);

	//metal
	int iMetal = kv.GetNum("metal");
	g_WeaponMetal.SetValue(sName, iMetal);
	CallSettingsForward(sName, "metal", iMetal);

	//particle
	char sParticle[MAX_PARTICLE_NAME_LENGTH];
	kv.GetString("particle", sParticle, sizeof(sParticle));
	g_WeaponParticle.SetString(sName, sParticle);
	CallSettingsForwardStr(sName, "particle", sParticle);

	//particle_time
	float fParticleTime = kv.GetFloat("particle_time");
	g_WeaponParticleTime.SetValue(sName, fParticleTime);
	CallSettingsForward(sName, "particle_time", fParticleTime);

	//attributes
	if (kv.JumpToKey("attributes") && kv.GotoFirstSubKey())
	{
		StringMap attributesdata = new StringMap();
		ArrayList attributeslist = new ArrayList(ByteCountToCells(MAX_ATTRIBUTE_NAME_LENGTH));
		char sAttributeName[MAX_ATTRIBUTE_NAME_LENGTH];

		do
		{
			kv.GetSectionName(sAttributeName, sizeof(sAttributeName));

			if (kv.GotoFirstSubKey(false))
			{
				StringMap attributedata = new StringMap();

				char sAttributeKey[64];
				int iAttributeValue;
				float fAttributeValue;
				char sAttributeValue[64];
				
				do
				{
					kv.GetSectionName(sAttributeKey, sizeof(sAttributeKey));

					switch (kv.GetDataType(NULL_STRING))
					{
						case KvData_Int:
						{
							iAttributeValue = kv.GetNum(NULL_STRING);
							attributedata.SetValue(sAttributeKey, iAttributeValue);
						}
						case KvData_Float:
						{
							fAttributeValue = kv.GetFloat(NULL_STRING);
							attributedata.SetValue(sAttributeKey, fAttributeValue);
						}
						case KvData_String:
						{
							kv.GetString(NULL_STRING, sAttributeValue, sizeof(sAttributeValue));
							attributedata.SetString(sAttributeKey, sAttributeValue);
						}
					}
				}
				while (kv.GotoNextKey(false));

				attributesdata.SetValue(sAttributeName, attributedata);
				attributeslist.PushString(sAttributeName);

				kv.GoBack();
			}
		}
		while (kv.GotoNextKey());

		g_WeaponAttributesData.SetValue(sName, attributesdata);

		char sAttributesList[MAX_WEAPON_NAME_LENGTH + 12];
		FormatEx(sAttributesList, sizeof(sAttributesList), "%s_list", sName);
		g_WeaponAttributesData.SetValue(sAttributesList, attributeslist);

		kv.Rewind();
	}

	//sounds
	if (kv.JumpToKey("sounds") && kv.GotoFirstSubKey())
	{
		StringMap soundsdata = new StringMap();
		ArrayList soundslist = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
		char sSoundName[PLATFORM_MAX_PATH];

		do
		{
			kv.GetSectionName(sSoundName, sizeof(sSoundName));

			if (strlen(sSoundName) == 0)
				continue;
			
			if (StrContains(sSoundName, "sound/") == 0)
				StripCharactersPre(sSoundName, sizeof(sSoundName), 6);

			if (kv.GotoFirstSubKey(false))
			{
				StringMap sounddata = new StringMap();

				char sSoundKey[64];
				int iSoundValue;
				float fSoundValue;
				char sSoundValue[64];
				
				do
				{
					kv.GetSectionName(sSoundKey, sizeof(sSoundKey));

					if (strlen(sSoundKey) == 0)
						continue;

					switch (kv.GetDataType(NULL_STRING))
					{
						case KvData_Int:
						{
							iSoundValue = kv.GetNum(NULL_STRING);
							sounddata.SetValue(sSoundKey, iSoundValue);
						}
						case KvData_Float:
						{
							fSoundValue = kv.GetFloat(NULL_STRING);
							sounddata.SetValue(sSoundKey, fSoundValue);
						}
						case KvData_String:
						{
							kv.GetString(NULL_STRING, sSoundValue, sizeof(sSoundValue));

							if (strlen(sSoundValue) > 0)
							{
								sounddata.SetString(sSoundKey, sSoundValue);

								if (StrContains(sSoundValue, ".wav", false) != -1 || StrContains(sSoundValue, ".mp3", false))
									PrecacheSound(sSoundValue);
							}
						}
					}
				}
				while (kv.GotoNextKey(false));

				soundsdata.SetValue(sSoundName, sounddata);
				soundslist.PushString(sSoundName);

				kv.GoBack();
			}
		}
		while (kv.GotoNextKey());

		g_WeaponSoundsData.SetValue(sName, soundsdata);

		char sSoundsList[MAX_WEAPON_NAME_LENGTH + 12];
		FormatEx(sSoundsList, sizeof(sSoundsList), "%s_list", sName);
		g_WeaponSoundsData.SetValue(sSoundsList, soundslist);

		kv.Rewind();
	}

	//precache
	if (kv.JumpToKey("precache") && kv.GotoFirstSubKey(false))
	{
		char sType[64]; char sFile[PLATFORM_MAX_PATH];
		do
		{
			kv.GetSectionName(sType, sizeof(sType));
			kv.GetString(NULL_STRING, sFile, sizeof(sFile));

			if (strlen(sType) == 0 || strlen(sFile) == 0)
				continue;

			if (StrContains(sType, "decal", false) != -1)
				PrecacheDecal(sFile);
			else if (StrContains(sType, "generic", false) != -1)
				PrecacheGeneric(sFile);
			else if (StrContains(sType, "model", false) != -1)
				PrecacheModel(sFile);
			else if (StrContains(sType, "sentencefile", false) != -1)
				PrecacheSentenceFile(sFile);
			else if (StrContains(sType, "sound", false) != -1)
				PrecacheSound(sFile);
		}
		while (kv.GotoNextKey(false));

		kv.Rewind();
	}

	//downloads
	if (kv.JumpToKey("downloads") && kv.GotoFirstSubKey(false))
	{
		char sType[64]; char sFile[PLATFORM_MAX_PATH];
		do
		{
			kv.GetSectionName(sType, sizeof(sType));
			kv.GetString(NULL_STRING, sFile, sizeof(sFile));

			if (strlen(sFile) == 0)
				continue;

			if (StrContains(sType, "material", false) != -1)
			{
				if (StrContains(sFile, "materials/") != 0)
					Format(sFile, sizeof(sFile), "materials/%s", sFile);
			}
			else if (StrContains(sType, "model", false) != -1)
			{
				if (StrContains(sFile, "models/") != 0)
					Format(sFile, sizeof(sFile), "models/%s", sFile);
			}
			else if (StrContains(sType, "sound", false) != -1)
			{
				if (StrContains(sFile, "sound/") != 0)
					Format(sFile, sizeof(sFile), "sound/%s", sFile);
			}

			AddFileToDownloadsTable(sFile);
		}
		while (kv.GotoNextKey(false));

		kv.Rewind();
	}

	Call_StartForward(g_Forward_OnRegisterWeaponConfigPost);
	Call_PushString(sName);
	Call_PushString(file);
	Call_PushCell(kv);
	Call_Finish();

	delete kv;
	LogMessage("Available Weapon: %s", file);

	return true;
}

void CallSettingsForward(const char[] name, const char[] setting, any value)
{
	Call_StartForward(g_Forward_OnRegisterWeaponSetting);
	Call_PushString(name);
	Call_PushString(setting);
	Call_PushCell(value);
	Call_Finish();
}

void CallSettingsForwardStr(const char[] name, const char[] setting, const char[] value)
{
	Call_StartForward(g_Forward_OnRegisterWeaponSettingStr);
	Call_PushString(name);
	Call_PushString(setting);
	Call_PushString(value);
	Call_Finish();
}

void ParseOverrides()
{
	DestroyItems();
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/tf2-weapons/overrides.cfg");
	
	KeyValues kv = new KeyValues("overrides");

	if (!kv.ImportFromFile(sPath))
	{
		delete kv;
		return;
	}
	
	kv.GetSectionName(sPath, sizeof(sPath));
	
	if (!StrEqual(sPath, "overrides", false))
	{
		delete kv;
		return;
	}
	
	g_hPlayerArray = new ArrayList();
	g_hPlayerInfo = new StringMap();
	
	if (kv.GotoFirstSubKey())
	{
		char strSplit[16][64];
		do
		{
			kv.GetSectionName(sPath, sizeof(sPath));
			int iNumAuths = ExplodeString(sPath, ";", strSplit, 16, 64);
			
			ArrayList hEntry = new ArrayList(2);
			g_hPlayerArray.Push(hEntry);
			
			for (int iAuth = 0; iAuth < iNumAuths; iAuth++)
			{
				TrimString(strSplit[iAuth]);
				g_hPlayerInfo.SetValue(strSplit[iAuth], hEntry);
			}
			
			ParseItemsEntry(kv, hEntry);
		}
		while (kv.GotoNextKey());
		
		kv.GoBack();
	}
	
	delete kv;
	
	g_hPlayerInfo.GetValue("*", g_hGlobalSettings);
}

void ParseItemsEntry(KeyValues kv, ArrayList hEntry)
{
	char strBuffer[64];
	char strBuffer2[64];
	char strSplit[2][64];
	
	if (kv.GotoFirstSubKey())
	{
		do
		{
			Handle hItem = TF2Items_CreateItem(OVERRIDE_ALL);
			int iItemFlags = 0;
			
			kv.GetSectionName(strBuffer, sizeof(strBuffer));
			
			if (strBuffer[0] == '*')
				TF2Items_SetItemIndex(hItem, -1);
			else
				TF2Items_SetItemIndex(hItem, StringToInt(strBuffer));
			
			int iLevel = kv.GetNum("level", -1);
			if (iLevel != -1)
			{
				TF2Items_SetLevel(hItem, iLevel);
				iItemFlags |= OVERRIDE_ITEM_LEVEL;
			}
			
			int iQuality = kv.GetNum("quality", -1);
			if (iQuality != -1)
			{
				TF2Items_SetQuality(hItem, iQuality);
				iItemFlags |= OVERRIDE_ITEM_QUALITY;
			}
			
			int iPreserve = kv.GetNum("preserve-attributes", -1);
			if (iPreserve == 1)
				iItemFlags |= PRESERVE_ATTRIBUTES;
			else
			{
				iPreserve = kv.GetNum("preserve_attributes", -1);
				
				if (iPreserve == 1)
					iItemFlags |= PRESERVE_ATTRIBUTES;
			}
			
			int iAttributeCount = 0;
			for (;;)
			{
				Format(strBuffer, sizeof(strBuffer), "%i", iAttributeCount+1);
				
				kv.GetString(strBuffer, strBuffer2, sizeof(strBuffer2));
				
				if (strBuffer2[0] == '\0')
					break;
				
				ExplodeString(strBuffer2, ";", strSplit, 2, 64);
				int iAttributeIndex = StringToInt(strSplit[0]);

				if (iAttributeIndex > 0)
				{
					float fAttributeValue = StringToFloat(strSplit[1]);
					TF2Items_SetAttribute(hItem, iAttributeCount, iAttributeIndex, fAttributeValue);
				}
				
				iAttributeCount++;
			}
			
			if (iAttributeCount != 0)
			{
				TF2Items_SetNumAttributes(hItem, iAttributeCount);
				iItemFlags |= OVERRIDE_ATTRIBUTES;
			}
			
			kv.GetString("admin-flags", strBuffer, sizeof(strBuffer), "");
			int iFlags = ReadFlagString(strBuffer);
			
			TF2Items_SetFlags(hItem, iItemFlags);
			
			hEntry.Push(0);
			hEntry.Set(hEntry.Length - 1, hItem, ARRAY_ITEM);
			hEntry.Set(hEntry.Length - 1, iFlags, ARRAY_FLAGS);
		}
		while (kv.GotoNextKey());
		
		kv.GoBack();
	}
}

void DestroyItems()
{
	if (g_hPlayerArray != null)
	{
		for (int iEntry = 0; iEntry < g_hPlayerArray.Length; iEntry++)
		{
			ArrayList hItemArray = g_hPlayerArray.Get(iEntry);
			
			if (hItemArray == null)
				continue;
			
			for (int iItem = 0; iItem < hItemArray.Length; iItem++)
			{
				Handle hItem = hItemArray.Get(iItem);
				delete hItem;
			}
		}
		
		delete g_hPlayerArray;
	}
	
	delete g_hPlayerInfo;
	
	g_hPlayerInfo = null;
	g_hPlayerArray = null;
	g_hGlobalSettings = null;
}

public void OnAllPluginsLoaded()
{
	CallAttributeRegistrations();
}

void CallAttributeRegistrations()
{
	g_AttributesList.Clear();
	g_Attributes_Calls.Clear();

	Call_StartForward(g_Forward_OnRegisterAttributes);
	Action result = Plugin_Continue; Call_Finish(result);

	if (result > Plugin_Changed)
		return;

	Call_StartForward(g_Forward_OnRegisterAttributesPost);
	Call_Finish();
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client == 0)
		return;
	
	if (convar_WeaponMenuOnSpawn.BoolValue)
		OpenWeaponsMenu(client);
}

public void Event_OnResupply(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client == 0)
		return;
	
	int entity = -1; char sName[MAX_WEAPON_NAME_LENGTH];
	while ((entity = FindEntityByClassname(entity, "tf_weapon_*")) != -1)
	{
		if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", sName, sizeof(sName));
			ExecuteWeaponAction(client, entity, sName, "remove");
		}
	}
}

public Action Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client == 0 || event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER)
		return Plugin_Continue;

	if (event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER)
		return Plugin_Continue;
	
	int weapon = event.GetInt("inflictor_entindex");

	char sName[MAX_WEAPON_NAME_LENGTH];
	GetEntPropString(weapon, Prop_Data, "m_iName", sName, sizeof(sName));

	if (strlen(sName) == 0)
		return Plugin_Continue;
	
	bool changed;

	char sKillIcon[64];
	if (g_WeaponKillIcon.GetString(sName, sKillIcon, sizeof(sKillIcon)) && strlen(sKillIcon) > 0)
	{
		event.SetString("weapon", sKillIcon);
		changed = true;
	}

	char sLogName[64];
	if (g_WeaponLogName.GetString(sName, sLogName, sizeof(sLogName)) && strlen(sLogName) > 0)
	{
		event.SetString("weapon_logclassname", sLogName);
		changed = true;
	}
	
	if (changed)
		event.SetInt("customkill", 0);
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "tf_weapon_*")) != -1)
	{
		if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", sName, sizeof(sName));
			ExecuteWeaponAction(client, entity, sName, "remove");
		}
	}

	return changed ? Plugin_Changed : Plugin_Continue;
}

public void OnClientPutInServer(int client)
{

}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "tf_dropped_weapon", false))
		AcceptEntityInput(entity, "Kill");
}

public void OnEntityDestroyed(int entity)
{
	if (entity < 1 || entity > MAX_ENTITY_LIMIT)
		return;
	
	g_IsCustom[entity] = false;
}

public Action Command_Weapons(int client, int args)
{
	if (IsClientServer(client))
	{
		CReplyToCommand(client, "You must be in-game to use this command.");
		return Plugin_Handled;
	}

	if (convar_DisableMenu.BoolValue && !CheckCommandAccess(client, "", ADMFLAG_GENERIC, true))
	{
		CReplyToCommand(client, "This command is disabled.");
		return Plugin_Handled;
	}

	if (args == 0)
	{
		OpenWeaponsMenu(client);
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(client))
	{
		CPrintToChat(client, "You must be alive to give yourself a weapon.");
		return Plugin_Handled;
	}

	char sName[MAX_WEAPON_NAME_LENGTH];
	GetCmdArgString(sName, sizeof(sName));

	if (g_WeaponsList.FindString(sName) == -1)
	{
		char sBuffer[MAX_WEAPON_NAME_LENGTH];
		for (int i = 0; i < g_WeaponsList.Length; i++)
		{
			g_WeaponsList.GetString(i, sBuffer, sizeof(sBuffer));

			if (StrContains(sBuffer, sName) != -1)
			{
				strcopy(sName, sizeof(sName), sBuffer);
				break;
			}
		}

		if (g_WeaponsList.FindString(sName) == -1)
		{
			CPrintToChat(client, "You have specified a weapon that wasn't found.");
			return Plugin_Handled;
		}
	}

	char sCurrentClass[64];
	TF2_GetClientClassName(client, sCurrentClass, sizeof(sCurrentClass));

	char sClass[2048];
	g_WeaponClasses.GetString(sName, sClass, sizeof(sClass));
	if (strlen(sClass) > 0 && StrContains(sClass, sCurrentClass, false) == -1)
	{
		CPrintToChat(client, "You must be a %s to equip this weapon.", sClass);
		return Plugin_Handled;
	}

	char sFlags[MAX_FLAGS_LENGTH];
	g_WeaponFlags.GetString(sName, sFlags, sizeof(sFlags));
	if (strlen(sFlags) > 0 && !CheckCommandAccess(client, "", ReadFlagString(sFlags), true))
	{
		CPrintToChat(client, "You don't have the required flags to equip this weapon.");
		return Plugin_Handled;
	}

	char sSteamID[64];
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));
	
	char sSteamIDs[2048];
	g_WeaponSteamIDs.GetString(sName, sSteamIDs, sizeof(sSteamIDs));
	if (!IsDrixevel(client) && strlen(sSteamIDs) > 0 && StrContains(sSteamIDs, sSteamID, false) == -1)
	{
		CPrintToChat(client, "You don't have access to equipping this weapon.");
		return Plugin_Handled;
	}

	GiveItem(client, sName, true);
	return Plugin_Handled;
}

void OpenWeaponsMenu(int client)
{
	char sCurrentClass[64];
	TF2_GetClientClassName(client, sCurrentClass, sizeof(sCurrentClass));

	char sSteamID[64];
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));

	Menu menu = new Menu(MenuHandler_Weapons);
	menu.SetTitle("Pick a weapon to equip:");

	char sName[MAX_WEAPON_NAME_LENGTH]; char sClass[2048]; char sFlags[MAX_FLAGS_LENGTH]; char sSteamIDs[2048]; 
	for (int i = 0; i < g_WeaponsList.Length; i++)
	{
		g_WeaponsList.GetString(i, sName, sizeof(sName));
		
		g_WeaponClasses.GetString(sName, sClass, sizeof(sClass));
		if (strlen(sClass) > 0 && StrContains(sClass, "all", false) == -1 && StrContains(sClass, sCurrentClass, false) == -1)
			continue;

		g_WeaponFlags.GetString(sName, sFlags, sizeof(sFlags));
		if (strlen(sFlags) > 0 && !CheckCommandAccess(client, "", ReadFlagString(sFlags), true))
			continue;
		
		g_WeaponSteamIDs.GetString(sName, sSteamIDs, sizeof(sSteamIDs));
		if (!IsDrixevel(client) && strlen(sSteamIDs) > 0 && StrContains(sSteamIDs, sSteamID, false) == -1)
			continue;

		menu.AddItem(sName, sName);
	}

	if (menu.ItemCount == 0)
		menu.AddItem("", " -- No Weapons Available --", ITEMDRAW_DISABLED);

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Weapons(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sName[MAX_WEAPON_NAME_LENGTH];
			menu.GetItem(param2, sName, sizeof(sName));

			OpenWeaponMenu(param1, sName);
		}
		case MenuAction_End:
			delete menu;
	}
}

void OpenWeaponMenu(int client, const char[] name)
{
	char sDescription[MAX_DESCRIPTION_LENGTH];
	g_WeaponDescription.GetString(name, sDescription, sizeof(sDescription));

	if (strlen(sDescription) > 0)
		Format(sDescription, sizeof(sDescription), "\nDescription: %s\n \n", sDescription);
	
	Menu menu = new Menu(MenuHandler_Weapon);
	menu.SetTitle("Information for weapon: %s%s", name, strlen(sDescription) > 0 ? sDescription : "\n ");

	menu.AddItem("equip", "Equip Weapon");
	menu.AddItem("spawn", "Spawn with Weapon");

	PushMenuString(menu, "name", name);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Weapon(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sAction[64];
			menu.GetItem(param2, sAction, sizeof(sAction));

			char sName[MAX_WEAPON_NAME_LENGTH];
			GetMenuString(menu, "name", sName, sizeof(sName));

			if (StrEqual(sAction, "equip"))
			{
				if (!IsPlayerAlive(param1))
				{
					CPrintToChat(param1, "You must be alive to give yourself a weapon.");
					OpenWeaponMenu(param1, sName);
					return;
				}

				GiveItem(param1, sName, true);
			}
			else if (StrEqual(sAction, "spawn"))
			{
				OpenSpawnWeaponClassMenu(param1, sName);
			}
		}
		case MenuAction_End:
			delete menu;
	}
}

public Action Command_ReloadWeapons(int client, int args)
{
	ParseWeapons();
	ReplyToCommand(client, "All weapon configs have been reloaded.");
	return Plugin_Handled;
}

public Action Command_ReloadAttributes(int client, int args)
{
	CallAttributeRegistrations();
	ReplyToCommand(client, "All attributes have been reloaded.");
	return Plugin_Handled;
}

int GiveItem(int client, const char[] name, bool message = false)
{
	if (client < 1 || client > MaxClients || strlen(name) == 0)
		return -1;
	
	char sEntity[MAX_ENTITY_CLASSNAME_LENGTH];
	g_WeaponEntity.GetString(name, sEntity, sizeof(sEntity));

	if (strlen(sEntity) == 0)
		return -1;
	
	int slot;
	g_WeaponSlot.GetValue(name, slot);
	TF2_RemoveWeaponSlot(client, slot);

	if (StrContains(sEntity, "tf_weapon_", false) != 0)
		Format(sEntity, sizeof(sEntity), "tf_weapon_%s", sEntity);

	Handle hItem = TF2Items_CreateItem(OVERRIDE_ALL|PRESERVE_ATTRIBUTES|FORCE_GENERATION);

	TFClassType class = TF2_GetPlayerClass(client);
	
	if (StrContains(sEntity, "saxxy", false) != -1)
	{
		switch (class)
		{
			case TFClass_Scout: strcopy(sEntity, sizeof(sEntity), "tf_weapon_bat");
			case TFClass_Sniper: strcopy(sEntity, sizeof(sEntity), "tf_weapon_club");
			case TFClass_Soldier: strcopy(sEntity, sizeof(sEntity), "tf_weapon_shovel");
			case TFClass_DemoMan: strcopy(sEntity, sizeof(sEntity), "tf_weapon_bottle");
			case TFClass_Engineer: strcopy(sEntity, sizeof(sEntity), "tf_weapon_wrench");
			case TFClass_Pyro: strcopy(sEntity, sizeof(sEntity), "tf_weapon_fireaxe");
			case TFClass_Heavy: strcopy(sEntity, sizeof(sEntity), "tf_weapon_fists");
			case TFClass_Spy: strcopy(sEntity, sizeof(sEntity), "tf_weapon_knife");
			case TFClass_Medic: strcopy(sEntity, sizeof(sEntity), "tf_weapon_bonesaw");
		}
	}
	else if (StrContains(sEntity, "shotgun", false) != -1)
	{
		switch (class)
		{
			case TFClass_Soldier: strcopy(sEntity, sizeof(sEntity), "tf_weapon_shotgun_soldier");
			case TFClass_Pyro: strcopy(sEntity, sizeof(sEntity), "tf_weapon_shotgun_pyro");
			case TFClass_Heavy: strcopy(sEntity, sizeof(sEntity), "tf_weapon_shotgun_hwg");
			case TFClass_Engineer: strcopy(sEntity, sizeof(sEntity), "tf_weapon_shotgun_primary");
		}
	}

	TF2Items_SetClassname(hItem, sEntity);

	int index;
	g_WeaponIndex.GetValue(name, index);
	TF2Items_SetItemIndex(hItem, index);

	int level;
	g_WeaponLevel.GetValue(name, level);
	TF2Items_SetLevel(hItem, level);

	char sQuality[32]; int quality;
	g_WeaponQuality.GetString(name, sQuality, sizeof(sQuality));
	quality = IsStringNumeric(sQuality) ? StringToInt(sQuality) : view_as<int>(TF2_GetQualityFromName(sQuality));
	TF2Items_SetQuality(hItem, quality);

	int entity = TF2Items_GiveNamedItem(client, hItem);
	delete hItem;

	if (!IsValidEntity(entity))
		return entity;
	
	DispatchKeyValue(entity, "targetname", name);	//Used for sounds.
	SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", 1);

	float size;
	g_WeaponSize.GetValue(name, size);
	SetEntPropFloat(entity, Prop_Send, "m_flModelScale", size);

	int skin;
	g_WeaponSkin.GetValue(name, skin);
	SetEntProp(entity, Prop_Send, "m_nSkin", skin);

	RenderMode rendermode;
	g_WeaponRenderMode.GetValue(name, rendermode);
	SetEntityRenderMode(entity, rendermode);

	RenderFx renderfx;
	g_WeaponRenderFx.GetValue(name, renderfx);
	SetEntityRenderFx(entity, renderfx);

	int color[4];
	g_WeaponRenderColor.GetArray(name, color, sizeof(color));
	SetEntityRenderColorEx(entity, color);

	char sViewmodel[PLATFORM_MAX_PATH];
	g_WeaponViewmodel.GetString(name, sViewmodel, sizeof(sViewmodel));

	AttachViewmodel(client, class, entity, sViewmodel, index);

	char sWorldModel[PLATFORM_MAX_PATH];
	g_WeaponWorldmodel.GetString(name, sWorldModel, sizeof(sWorldModel));
	SetWorldModel(entity, sWorldModel);

	int clip;
	g_WeaponClip.GetValue(name, clip);

	if (clip != -1)
		SetClip(entity, clip);

	int ammo;
	g_WeaponAmmo.GetValue(name, ammo);

	if (ammo != -1)
		SetAmmo(client, entity, ammo);

	if (class == TFClass_Engineer)
	{
		int metal;
		g_WeaponMetal.GetValue(name, metal);
		TF2_SetMetal(client, metal);
	}

	char sParticle[MAX_PARTICLE_NAME_LENGTH];
	g_WeaponParticle.GetString(name, sParticle, sizeof(sParticle));

	if (strlen(sParticle) > 0)
	{
		float particletime;
		g_WeaponParticleTime.GetValue(name, particletime);

		if (particletime < 0.0)
			particletime = 0.0;
		
		AttachParticle(entity, sParticle, particletime);
	}

	ExecuteWeaponAction(client, entity, name, "apply");

	EquipPlayerWeapon(client, entity);
	
	if (StrContains(sEntity, "tf_weapon", false) == 0)
		EquipWeaponSlot(client, slot);

	if (message)
		CPrintToChat(client, "Weapon Equipped: %s", name);
	
	g_IsCustom[entity] = true;

	return entity;
}

stock void AttachViewmodel(int client, TFClassType class, int weapon, char[] viewmodel, int index)
{
	if (strlen(viewmodel) == 0)
		return;
	
	if (StrContains(viewmodel, "models/", false) != 0)
		Format(viewmodel, PLATFORM_MAX_PATH, "models/%s", viewmodel);
	
	if (StrContains(viewmodel, ".mdl", false) == -1)
		Format(viewmodel, PLATFORM_MAX_PATH, "%s.mdl", viewmodel);

	if (!FileExists(viewmodel, true))
		return;
	
	if (StrContains(viewmodel, "v_model", false) != -1)
	{
		int v_model = TF2_GiveViewmodel(client, PrecacheModel(viewmodel));

		if (IsValidEntity(v_model))
			Call_EquipWearable(client, v_model);
		
		return;
	}
	
	int iViewModel = CreateEntityByName("tf_wearable_vm");
	if (IsValidEntity(iViewModel))
	{
		char sArms[PLATFORM_MAX_PATH];
		switch (class)
		{
			case TFClass_Scout: Format(sArms, sizeof(sArms), "models/weapons/c_models/c_scout_arms.mdl");
			case TFClass_Soldier: Format(sArms, sizeof(sArms), "models/weapons/c_models/c_soldier_arms.mdl");
			case TFClass_Pyro: Format(sArms, sizeof(sArms), "models/weapons/c_models/c_pyro_arms.mdl");
			case TFClass_DemoMan: Format(sArms, sizeof(sArms), "models/weapons/c_models/c_demo_arms.mdl");
			case TFClass_Heavy: Format(sArms, sizeof(sArms), "models/weapons/c_models/c_heavy_arms.mdl");
			case TFClass_Engineer: Format(sArms, sizeof(sArms), "models/weapons/c_models/c_engineer_arms.mdl");
			case TFClass_Medic: Format(sArms, sizeof(sArms), "models/weapons/c_models/c_medic_arms.mdl");
			case TFClass_Sniper: Format(sArms, sizeof(sArms), "models/weapons/c_models/c_sniper_arms.mdl");
			case TFClass_Spy: Format(sArms, sizeof(sArms), "models/weapons/c_models/c_spy_arms.mdl");
		}

		SetEntProp(iViewModel, Prop_Send, "m_nModelIndex", PrecacheModel(sArms));
		SetEntProp(iViewModel, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_BONEMERGE_FASTCULL);
		SetEntProp(iViewModel, Prop_Send, "m_iTeamNum", GetClientTeam(client));
		SetEntProp(iViewModel, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID);
		SetEntProp(iViewModel, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_WEAPON);

		DispatchSpawn(iViewModel);

		SetVariantString("!activator");
		ActivateEntity(iViewModel);

		Call_EquipWearable(client, iViewModel);
			
		SetEntPropEnt(iViewModel, Prop_Send, "m_hEffectEntity", weapon);
		SDKHook(iViewModel, SDKHook_SetTransmit, Hook_VMTransmit);
	}
	
	int iWeaponModel = CreateEntityByName("tf_wearable_vm");
	if (IsValidEntity(iWeaponModel))
	{
		SetEntProp(iWeaponModel, Prop_Send, "m_nModelIndex", PrecacheModel(viewmodel));
		SetEntProp(iWeaponModel, Prop_Send, "m_iItemDefinitionIndex", index);
		SetEntProp(iWeaponModel, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_BONEMERGE_FASTCULL);
		SetEntProp(iWeaponModel, Prop_Send, "m_iTeamNum", GetClientTeam(client));
		SetEntProp(iWeaponModel, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID);
		SetEntProp(iWeaponModel, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_WEAPON);
		
		DispatchSpawn(iWeaponModel);

		SetVariantString("!activator");
		ActivateEntity(iWeaponModel);

		Call_EquipWearable(client, iWeaponModel);

		SetEntPropEnt(iWeaponModel, Prop_Send, "m_hEffectEntity", weapon);
		SDKHook(iWeaponModel, SDKHook_SetTransmit, Hook_VMTransmit);
	}
}

public Action Hook_VMTransmit(int iEnt, int iOther)
{
	if (iEnt == -1) 
		return Plugin_Continue;
	
	int iOwner = GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity");
	
	if (0 < iOwner <= MaxClients)
	{
		if (iOwner != iOther) return Plugin_Continue;
		
		int iActiveWep = GetEntPropEnt(iOwner, Prop_Send, "m_hActiveWeapon");
		int iAttachedWep = GetEntPropEnt(iEnt, Prop_Send, "m_hEffectEntity");
		
		if (iAttachedWep > MaxClients && GetEntProp(iAttachedWep, Prop_Send, "m_bBeingRepurposedForTaunt"))
			SetEntProp(iAttachedWep, Prop_Send, "m_nModelIndexOverrides", 0);
		else if (iAttachedWep > -1)
			SetEntProp(iAttachedWep, Prop_Send, "m_nModelIndexOverrides", GetEntProp(iAttachedWep, Prop_Send, "m_iWorldModelIndex"));
		
		if (iActiveWep == iAttachedWep)
		{
			int effects = GetEntProp(iEnt, Prop_Send, "m_fEffects");
			
			if ((effects & EF_NODRAW))
				SetEntProp(iEnt, Prop_Send, "m_fEffects", GetEntProp(iEnt, Prop_Send, "m_fEffects") &~ EF_NODRAW);
			
			int iRealViewModels = MaxClients + 1;
			while ((iRealViewModels = FindEntityByClassname(iRealViewModels, "tf_viewmodel")) > MaxClients)
			{
				int iViewOwner = GetEntPropEnt(iRealViewModels, Prop_Send, "m_hOwner");
				
				if (iViewOwner == iOwner)
					SetEntProp(iRealViewModels, Prop_Send, "m_fEffects", GetEntProp(iRealViewModels, Prop_Send, "m_fEffects")|EF_NODRAW);
			}
		}
		else
		{
			int effects = GetEntProp(iEnt, Prop_Send, "m_fEffects");
			
			if (!(effects & EF_NODRAW))
			{
				SetEntProp(iEnt, Prop_Send, "m_fEffects", effects|EF_NODRAW);
				
				int iRealViewModels = MaxClients + 1;
				while ((iRealViewModels = FindEntityByClassname(iRealViewModels, "tf_viewmodel")) > MaxClients)
				{
					int iViewOwner = GetEntPropEnt(iRealViewModels, Prop_Send, "m_hOwner");
					
					if (iViewOwner == iOwner)
						SetEntProp(iRealViewModels, Prop_Send, "m_fEffects", GetEntProp(iRealViewModels, Prop_Send, "m_fEffects") &~ EF_NODRAW);
				}
			}
		}

		return Plugin_Continue;
	}

	AcceptEntityInput(iEnt, "Kill");
	return Plugin_Continue;
}

void SetWorldModel(int weapon, char[] worldmodel)
{
	if (strlen(worldmodel) == 0)
		return;
	
	if (StrContains(worldmodel, "models/", false) != 0)
		Format(worldmodel, PLATFORM_MAX_PATH, "models/%s", worldmodel);

	if (StrContains(worldmodel, ".mdl", false) == -1)
		Format(worldmodel, PLATFORM_MAX_PATH, "%s.mdl", worldmodel);

	if (FileExists(worldmodel, true))
	{
		int model = PrecacheModel(worldmodel, true);
		SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", model);
		SetEntProp(weapon, Prop_Send, "m_nModelIndexOverrides", model);
	}
}

void OpenSpawnWeaponClassMenu(int client, const char[] name)
{
	Menu menu = new Menu(MenuHandler_OpenSpawnWeaponClassMenu);
	menu.SetTitle("Pick a class tp spawn '%s' with:", name);

	char sClass[2048];
	g_WeaponClasses.GetString(name, sClass, sizeof(sClass));

	if (strlen(sClass) == 0 || StrContains(sClass, "all", false) != -1 || StrContains(sClass, "scout", false) != -1)
		menu.AddItem("scout", "Scout");
	if (strlen(sClass) == 0 || StrContains(sClass, "all", false) != -1 || StrContains(sClass, "soldier", false) != -1)
		menu.AddItem("soldier", "Soldier");
	if (strlen(sClass) == 0 || StrContains(sClass, "all", false) != -1 || StrContains(sClass, "pyro", false) != -1)
		menu.AddItem("pyro", "Pyro");
	if (strlen(sClass) == 0 || StrContains(sClass, "all", false) != -1 || StrContains(sClass, "demoman", false) != -1)
		menu.AddItem("demoman", "Demoman");
	if (strlen(sClass) == 0 || StrContains(sClass, "all", false) != -1 || StrContains(sClass, "heavy", false) != -1)
		menu.AddItem("heavy", "Heavy");
	if (strlen(sClass) == 0 || StrContains(sClass, "all", false) != -1 || StrContains(sClass, "engineer", false) != -1)
		menu.AddItem("engineer", "Engineer");
	if (strlen(sClass) == 0 || StrContains(sClass, "all", false) != -1 || StrContains(sClass, "medic", false) != -1)
		menu.AddItem("medic", "Medic");
	if (strlen(sClass) == 0 || StrContains(sClass, "all", false) != -1 || StrContains(sClass, "sniper", false) != -1)
		menu.AddItem("sniper", "Sniper");
	if (strlen(sClass) == 0 || StrContains(sClass, "all", false) != -1 || StrContains(sClass, "spy", false) != -1)
		menu.AddItem("spy", "Spy");
	
	PushMenuString(menu, "name", name);

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_OpenSpawnWeaponClassMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sClass[32];
			menu.GetItem(param2, sClass, sizeof(sClass));

			char sName[MAX_WEAPON_NAME_LENGTH];
			GetMenuString(menu, "name", sName, sizeof(sName));

			int iSlot;
			g_WeaponSlot.SetValue(sName, iSlot);

			SetSpawnWeapon(param1, sClass, iSlot, sName);
		}
		case MenuAction_End:
			delete menu;
	}
}

void SetSpawnWeapon(int client, const char[] class, int slot, const char[] name)
{
	CPrintToChat(client, "%s has been equipped for the %s class and the %i slot.", name, class, slot);
}

public int Native_AllowAttributeRegisters(Handle plugin, int numParams)
{
	return g_AttributesList != null;
}

bool ExecuteWeaponAction(int client, int weapon, const char[] name, const char[] action)
{
	StringMap attributesdata;
	if (!g_WeaponAttributesData.GetValue(name, attributesdata) || attributesdata == null)
		return false;
	
	char sAttributesList[MAX_ATTRIBUTE_NAME_LENGTH + 12];
	FormatEx(sAttributesList, sizeof(sAttributesList), "%s_list", name);

	ArrayList attributeslist;
	if (!g_WeaponAttributesData.GetValue(sAttributesList, attributeslist) || attributeslist == null)
		return false;
	
	char sSteamID[64];
	GetClientAuthId(client, AuthId_Engine, sSteamID, sizeof(sSteamID));
	
	char sAttribute[MAX_ATTRIBUTE_NAME_LENGTH]; StringMap attributedata; bool status = true; char sFlags[MAX_FLAGS_LENGTH]; char sSteamIDs[2048];
	for (int i = 0; i < attributeslist.Length; i++)
	{
		attributeslist.GetString(i, sAttribute, sizeof(sAttribute));
		
		if (!attributesdata.GetValue(sAttribute, attributedata) || attributedata == null)
			continue;
		
		if (attributedata.GetValue("status", status) && !status)
			continue;
		
		if (attributedata.GetString("flags", sFlags, sizeof(sFlags)) && strlen(sFlags) > 0 && !CheckCommandAccess(client, "", ReadFlagString(sFlags), true))
			continue;

		if (attributedata.GetString("steamids", sSteamIDs, sizeof(sSteamIDs)) && strlen(sSteamIDs) > 0 && StrContains(sSteamIDs, sSteamID, false) == -1)
			continue;
		
		ExecuteAttributeAction(client, weapon, sAttribute, action, attributedata);
	}

	return true;
}

bool ExecuteAttributeAction(int client, int weapon, char[] attrib, const char[] action, StringMap attributesdata)
{
	float value;
	if (attributesdata.GetValue("default", value))
		TF2Attrib_SetByName(weapon, attrib, value);

	Handle action_call;
	if (!g_Attributes_Calls.GetValue(attrib, action_call) || action_call == null)
		return false;

	if (action_call != null && GetForwardFunctionCount(action_call) > 0)
	{
		Call_StartForward(action_call);
		Call_PushCell(client);
		Call_PushCell(weapon);
		Call_PushString(attrib);
		Call_PushString(action);
		Call_PushCell(attributesdata);
		Call_Finish();

		return true;
	}

	return false;
}

public Action OnSoundPlay(int clients[64], int& numClients, char sound[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags)
{
	if (entity > 0 && entity <= MaxClients && IsClientInGame(entity))
	{
		int weapon = GetEntPropEnt(entity, Prop_Send, "m_hActiveWeapon");

		if (!IsValidEntity(weapon))
			return Plugin_Continue;
		
		char sName[MAX_WEAPON_NAME_LENGTH];
		GetEntPropString(weapon, Prop_Data, "m_iName", sName, sizeof(sName));

		StringMap soundsdata;
		if (!g_WeaponSoundsData.GetValue(sName, soundsdata) || soundsdata == null)
			return Plugin_Continue;
		
		char sSound[PLATFORM_MAX_PATH];
		strcopy(sSound, sizeof(sSound), sound);
		ReplaceString(sSound, sizeof(sSound), "\\", "/");
		
		StringMap sounddata;
		if (!soundsdata.GetValue(sSound, sounddata) || sounddata == null)
			return Plugin_Continue;
		
		bool changed;
	
		char sReplace[PLATFORM_MAX_PATH];
		if (sounddata.GetString("replace", sReplace, sizeof(sReplace)) && strlen(sReplace) > 0)
		{
			PrecacheSound(sReplace);
			Format(sound, sizeof(sound), sReplace);
			changed = true;
		}

		int iBuffer;
		float fBuffer;

		if (sounddata.GetValue("entity", iBuffer))
		{
			entity = iBuffer;
			changed = true;
		}

		if (sounddata.GetValue("channel", iBuffer))
		{
			channel = iBuffer;
			changed = true;
		}
		
		if (sounddata.GetValue("volume", fBuffer))
		{
			volume = fBuffer;
			changed = true;
		}
		
		if (sounddata.GetValue("level", iBuffer))
		{
			level = iBuffer;
			changed = true;
		}
		
		if (sounddata.GetValue("pitch", iBuffer))
		{
			pitch = iBuffer;
			changed = true;
		}
		
		if (sounddata.GetValue("flags", iBuffer))
		{
			flags = iBuffer;
			changed = true;
		}

		char sEmit[PLATFORM_MAX_PATH];
		if (sounddata.GetString("emit", sEmit, sizeof(sEmit)) && strlen(sEmit) > 0)
		{
			PrecacheSound(sEmit);
			EmitSoundToAll(sEmit, entity, channel, level, flags, volume, pitch);
		}
		
		return changed ? Plugin_Changed : Plugin_Stop;
	}

	return Plugin_Continue;
}

bool RegisterAttribute(Handle plugin, const char[] attrib, Function onaction = INVALID_FUNCTION)
{
	if (plugin == null || strlen(attrib) == 0 || onaction == INVALID_FUNCTION)
		return false;
	
	int index;
	if ((index = g_AttributesList.FindString(attrib)) != -1)
		g_AttributesList.Erase(index);
	
	g_AttributesList.PushString(attrib);
	SortADTArray(g_AttributesList, Sort_Descending, Sort_String);

	Handle action_call;
	if (g_Attributes_Calls.GetValue(attrib, action_call) && action_call != null)
		delete action_call;
	
	action_call = CreateForward(ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_String, Param_Cell);
	AddToForward(action_call, plugin, onaction);
	g_Attributes_Calls.SetValue(attrib, action_call);

	return true;
}

public int Native_RegisterAttribute(Handle plugin, int numParams)
{
	int size;

	GetNativeStringLength(1, size); size++;
	char[] attrib = new char[size];
	GetNativeString(1, attrib, size);

	Function onaction = GetNativeFunction(2);

	return RegisterAttribute(plugin, attrib, onaction);
}

stock bool TF2_IsValidAttribute(const char[] attribute)
{
	if (strlen(attribute) > 0)
		return true;
	
	Address CEconItemSchema = SDKCall(g_hGetItemSchema);
	if (CEconItemSchema == Address_Null)
		return false;
	
	Address CEconItemAttributeDefinition = SDKCall(g_hGetAttributeDefinitionByName, CEconItemSchema, attribute);
	if (CEconItemAttributeDefinition == Address_Null)
		return false;
	
	return true;
}

public Action Command_CreateWeapon(int client, int args)
{
	if (args == 0)
	{
		if (IsClientServer(client))
		{
			CReplyToCommand(client, "You must be in-game to use this command.");
			return Plugin_Handled;
		}

		OpenCreateWeaponMenu(client);
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	GetCmdArgString(sPath, sizeof(sPath));

	if (StrContains(sPath, "configs/tf2-weapons/weapons", false) != 0)
		Format(sPath, sizeof(sPath), "configs/tf2-weapons/weapons/%s", sPath);
	
	if (StrContains(sPath, ".cfg", false) != strlen(sPath) - 4)
		Format(sPath, sizeof(sPath), "%s.cfg", sPath);

	char sFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFile, sizeof(sFile), sPath);

	bool created = CreateWeaponConfig(sFile);
	CReplyToCommand(client, "Weapon template created %ssuccessfully at '%s'.", created ? "" : "un", sPath);

	return Plugin_Handled;
}



bool OpenCreateWeaponMenu(int client)
{
	Menu menu = new Menu(MenuHandler_CreateWeapon);
	menu.SetTitle("Create a new weapon:");

	menu.AddItem("name", "Name: (not set)");
	menu.AddItem("description", "Description: (not set)");
	menu.AddItem("flags", "Flags: (not set)");
	menu.AddItem("steamids", "SteamIDs: (not set)");
	menu.AddItem("classes", "Classes: (not set)");
	menu.AddItem("slot", "Slot: (not set)");
	menu.AddItem("entity", "Entity: (not set)");
	menu.AddItem("index", "Index: (not set)");
	menu.AddItem("viewmodel", "Viewmodel: (not set)");
	menu.AddItem("worldmodel", "Worldmodel: (not set)");
	menu.AddItem("attachment", "Attachment: (not set)");
	menu.AddItem("attachment_pos", "Attachment Pos: (not set)");
	menu.AddItem("attachment_ang", "Attachment Ang: (not set)");
	menu.AddItem("attachment_scale", "Attachment Scale: (not set)");
	menu.AddItem("quality", "Quality: (not set)");
	menu.AddItem("level", "Level: (not set)");
	menu.AddItem("clip", "Clip: (not set)");
	menu.AddItem("ammo", "Ammo: (not set)");
	menu.AddItem("metal", "Metal: (not set)");
	menu.AddItem("particle", "Particle: (not set)");
	menu.AddItem("particle_time", "Particle_time: (not set)");

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_CreateWeapon(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{

		}
		case MenuAction_End:
			delete menu;
	}
}

bool CreateWeaponConfig(const char[] file, const char[] name = " ", const char[] description = " ", const char[] flags = " ", const char[] steamids = " ", const char[] classes = " ", const char[] slot = " ", const char[] entity = " ", int index = 0, const char[] viewmodel = " ", const char[] worldmodel = " ", int attachment = 0, float attachment_pos[3] = NULL_VECTOR, float attachment_ang[3] = NULL_VECTOR, float attachment_scale = 1.0, const char[] quality = " ", int level = 0, int clip = 0, int ammo = 0, int metal = 0, const char[] particle = " ", float particle_time = 1.0)
{
	KeyValues kv = new KeyValues("weapon");

	//name
	kv.SetString("name", name);

	//description
	kv.SetString("description", description);

	//flags
	kv.SetString("flags", flags);

	//flags
	kv.SetString("steamids", steamids);

	//classes
	kv.SetString("classes", classes);

	//slots
	kv.SetString("slot", slot);

	//entity
	kv.SetString("entity", entity);

	//index
	kv.SetNum("index", index);

	//viewmodel
	kv.SetString("viewmodel", viewmodel);

	//worldmodel
	kv.SetString("worldmodel", worldmodel);

	//attachment
	kv.GetNum("attachment", attachment);

	//attachment_pos
	kv.SetVector("attachment_pos", attachment_pos);

	//attachment_ang
	kv.SetVector("attachment_ang", attachment_ang);

	//attachment_scale
	kv.SetFloat("attachment_scale", attachment_scale);

	//quality
	kv.SetString("quality", quality);

	//level
	kv.SetNum("level", level);

	//clip
	kv.SetNum("clip", clip);

	//ammo
	kv.SetNum("ammo", ammo);

	//metal
	kv.SetNum("metal", metal);

	//particle
	kv.SetString("particle", particle);

	//particle_time
	kv.SetFloat("particle_time", particle_time);
	
	bool found = kv.ExportToFile(file);
	delete kv;

	return found;
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle& hItem)
{
	if (hItem != null)
		return Plugin_Continue;
	
	Handle hOverrides = ApplyItemOverrides(client, iItemDefinitionIndex);
	
	if (hOverrides == null)
		return Plugin_Continue;
	
	hItem = hOverrides;
	return Plugin_Changed;
}

Handle ApplyItemOverrides(int client, int iItemDefinitionIndex)
{
	char sSteamID[64];
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));
	
	if (g_hPlayerInfo == null)
		return null;
	
	ArrayList hItemArray; 
	g_hPlayerInfo.GetValue(sSteamID, hItemArray);
	
	Handle hOutput = FindItemOnArray(client, hItemArray, iItemDefinitionIndex);
	
	if (hOutput == null)
		hOutput = FindItemOnArray(client, g_hGlobalSettings, iItemDefinitionIndex);
	
	return hOutput;
}

Handle FindItemOnArray(int client, ArrayList hArray, int iItemDefinitionIndex)
{
	if (hArray == null)
		return null;
		
	Handle hWildcardItem;
	
	for (int iItem = 0; iItem < hArray.Length; iItem++)
	{
		Handle hItem = hArray.Get(iItem, ARRAY_ITEM);
		int iItemFlags = hArray.Get(iItem, ARRAY_FLAGS);
		
		if (hItem == null)
			continue;
		
		if (TF2Items_GetItemIndex(hItem) == -1 && hWildcardItem == null && CheckItemUsage(client, iItemFlags))
			hWildcardItem = hItem;
		
		if (TF2Items_GetItemIndex(hItem) == iItemDefinitionIndex && CheckItemUsage(client, iItemFlags))
			return hItem;
	}
	
	return hWildcardItem;
}

bool CheckItemUsage(int client, int flags)
{
	if (flags == 0)
		return true;
	
	int clientflags = GetUserFlagBits(client);
	
	if ((clientflags & ADMFLAG_ROOT) == ADMFLAG_ROOT)
		return true;
	
	return (clientflags & flags) != 0;
}

enum struct WeaponsData
{
	int mag;
	int ammo;
}

WeaponsData g_WeaponsData[MAX_ENTITY_LIMIT + 1];

public void TF2Items_OnGiveNamedItem_Post(int client, char[] classname, int itemDefinitionIndex, int itemLevel, int itemQuality, int entityIndex)
{
	DataPack pack;
	CreateDataTimer(0.5, Timer_CacheData, pack, TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(EntIndexToEntRef(entityIndex));
}

public Action Timer_CacheData(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	int entityIndex = EntRefToEntIndex(pack.ReadCell());
	
	if (client > 0 && IsValidEntity(entityIndex))
	{
		g_WeaponsData[entityIndex].mag = GetClip(entityIndex);
		g_WeaponsData[entityIndex].ammo = GetAmmo(client, entityIndex);
	}
}

public int Native_GiveWeapon(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	char sName[MAX_WEAPON_NAME_LENGTH];
	GetNativeString(2, sName, sizeof(sName));

	bool message = GetNativeCell(3);

	return GiveItem(client, sName, message);
}

public int Native_IsCustom(Handle plugin, int numParams)
{
	return g_IsCustom[GetNativeCell(1)];
}

public int Native_GetWeaponKeyInt(Handle plugin, int numParams)
{
	int size;
	GetNativeStringLength(1, size); size++;

	char[] sWeapon = new char[size];
	GetNativeString(1, sWeapon, size);

	if (g_WeaponsList.FindString(sWeapon) == -1)
		return -1;
	
	GetNativeStringLength(2, size); size++;

	char[] sKey = new char[size];
	GetNativeString(2, sKey, size);

	int value = -1;

	if (StrEqual(sKey, "slot", false))
		g_WeaponSlot.GetValue(sWeapon, value);

	return value;
}

public int Native_GetWeaponKeyFloat(Handle plugin, int numParams)
{
	int size;
	GetNativeStringLength(1, size); size++;

	char[] sWeapon = new char[size];
	GetNativeString(1, sWeapon, size);

	if (g_WeaponsList.FindString(sWeapon) == -1)
		return -1;
	
	GetNativeStringLength(2, size); size++;

	char[] sKey = new char[size];
	GetNativeString(2, sKey, size);

	float value = -1.0;
	
	if (StrEqual(sKey, "size", false))
		g_WeaponSize.GetValue(sWeapon, value);

	return view_as<any>(value);
}

public int Native_GetWeaponKeyString(Handle plugin, int numParams)
{
	int size;
	GetNativeStringLength(1, size); size++;

	char[] sWeapon = new char[size];
	GetNativeString(1, sWeapon, size);

	if (g_WeaponsList.FindString(sWeapon) == -1)
		return false;
	
	GetNativeStringLength(2, size); size++;

	char[] sKey = new char[size];
	GetNativeString(2, sKey, size);

	if (StrEqual(sKey, "worldmodel", false))
	{
		char sWorldmodel[PLATFORM_MAX_PATH];
		if (!g_WeaponWorldmodel.GetString(sWeapon, sWorldmodel, sizeof(sWorldmodel)))
			return false;

		SetNativeString(3, sWorldmodel, GetNativeCell(4));
		return true;
	}
	else if (StrEqual(sKey, "classes", false))
	{
		char sClasses[2048];
		if (!g_WeaponClasses.GetString(sWeapon, sClasses, sizeof(sClasses)))
			return false;
		
		SetNativeString(3, sClasses, GetNativeCell(4));
		return true;
	}

	return false;
}

public Action Convert(int client, int args)
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/tf2-weapons/weapons/");

	Handle dir = OpenDirectory(sPath);

	if (dir == null)
	{
		CPrintToChat(client, "failed 1");
		return Plugin_Handled;
	}

	char sBuffer[PLATFORM_MAX_PATH];
	FileType type = FileType_Unknown;

	while (ReadDirEntry(dir, sBuffer, sizeof(sBuffer), type))
	{
		if (type != FileType_File || StrContains(sBuffer, ".txt", false) == -1)
			continue;
		
		Format(sBuffer, sizeof(sBuffer), "%s%s", sPath, sBuffer);
		ConvertCW3ToTF2W(client, sBuffer);
	}

	delete dir;
	CPrintToChat(client, "completed");

	return Plugin_Handled;
}

void ConvertCW3ToTF2W(int client, const char[] config)
{
	if (client)
	{

	}

	char sPath[PLATFORM_MAX_PATH];
	strcopy(sPath, sizeof(sPath), config);

	//original
	KeyValues kv_orig = new KeyValues("test");
	kv_orig.ImportFromFile(sPath);

	char sWeapon[256];
	kv_orig.GetSectionName(sWeapon, sizeof(sWeapon));
	TrimString(sWeapon);

	char sClasses[256]; int slot = -1;
	if (kv_orig.JumpToKey("classes"))
	{
		int scout = kv_orig.GetNum("scout", -1);
		int soldier = kv_orig.GetNum("soldier", -1);
		int pyro = kv_orig.GetNum("pyro", -1);
		int demoman = kv_orig.GetNum("demoman", -1);
		int heavy = kv_orig.GetNum("heavy", -1);
		int engineer = kv_orig.GetNum("engineer", -1);
		int medic = kv_orig.GetNum("medic", -1);
		int sniper = kv_orig.GetNum("sniper", -1);
		int spy = kv_orig.GetNum("spy", -1);

		if (scout != -1)
		{
			slot = scout;
			FormatEx(sClasses, sizeof(sClasses), "scout");
		}
		
		if (soldier != -1)
		{
			slot = soldier;
			FormatEx(sClasses, sizeof(sClasses), "%ssoldier", sClasses);
		}
		
		if (pyro != -1)
		{
			slot = pyro;
			FormatEx(sClasses, sizeof(sClasses), "%spyro", sClasses);
		}
		
		if (demoman != -1)
		{
			slot = demoman;
			FormatEx(sClasses, sizeof(sClasses), "%sdemoman", sClasses);
		}
		
		if (heavy != -1)
		{
			slot = heavy;
			FormatEx(sClasses, sizeof(sClasses), "%sheavy", sClasses);
		}
		
		if (engineer != -1)
		{
			slot = engineer;
			FormatEx(sClasses, sizeof(sClasses), "%sengineer", sClasses);
		}
		
		if (medic != -1)
		{
			slot = medic;
			FormatEx(sClasses, sizeof(sClasses), "%smedic", sClasses);
		}
		
		if (sniper != -1)
		{
			slot = sniper;
			FormatEx(sClasses, sizeof(sClasses), "%s sniper", sClasses);
		}
		
		if (spy != -1)
		{
			slot = spy;
			FormatEx(sClasses, sizeof(sClasses), "%s spy", sClasses);
		}

		kv_orig.Rewind();
	}
	TrimString(sClasses);

	char sEntity[64];
	kv_orig.GetString("baseclass", sEntity, sizeof(sEntity));
	TrimString(sEntity);

	if (strlen(sEntity) > 0 && StrContains(sEntity, "tf_weapon_", false) != 0)
		Format(sEntity, sizeof(sEntity), "tf_weapon_%s", sEntity);

	int index = kv_orig.GetNum("baseindex", -1);

	char sViewmodel[PLATFORM_MAX_PATH];
	if (kv_orig.JumpToKey("viewmodel"))
	{
		kv_orig.GetString("modelname", sViewmodel, sizeof(sViewmodel));
		kv_orig.Rewind();
	}
	TrimString(sViewmodel);

	char sWorldmodel[PLATFORM_MAX_PATH];
	if (kv_orig.JumpToKey("worldmodel"))
	{
		kv_orig.GetString("modelname", sWorldmodel, sizeof(sWorldmodel));
		kv_orig.Rewind();
	}
	TrimString(sWorldmodel);

	int clip = kv_orig.GetNum("clip", -1);
	
	if (clip == -1)
		clip = kv_orig.GetNum("mag", -1);
	
	int ammo = kv_orig.GetNum("ammo", -1);

	ArrayList attributes = new ArrayList(ByteCountToCells(256));
	StringMap values = new StringMap();

	char sAttribute[256]; char sValue[1024];
	if (kv_orig.JumpToKey("attributes") && kv_orig.GotoFirstSubKey())
	{
		do
		{
			kv_orig.GetSectionName(sAttribute, sizeof(sAttribute));
			TrimString(sAttribute);
			kv_orig.GetString("value", sValue, sizeof(sValue));
			TrimString(sValue);

			attributes.PushString(sAttribute);
			values.SetString(sAttribute, sValue);
		}
		while (kv_orig.GotoNextKey());

		kv_orig.Rewind();
	}

	ArrayList sounds = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	StringMap replacements = new StringMap();
	StringMap pitches = new StringMap();

	char sSound[PLATFORM_MAX_PATH]; char sReplace[PLATFORM_MAX_PATH]; char sPitch[32];
	if (kv_orig.JumpToKey("sound") && kv_orig.GotoFirstSubKey())
	{
		do
		{
			kv_orig.GetString("find", sSound, sizeof(sSound));
			TrimString(sSound);
			sounds.PushString(sSound);

			kv_orig.GetString("replace", sReplace, sizeof(sReplace));
			TrimString(sReplace);
			replacements.SetString(sSound, sReplace);
			
			kv_orig.GetString("pitch", sPitch, sizeof(sPitch));
			TrimString(sPitch);
			pitches.SetString(sSound, sPitch);
		}
		while (kv_orig.GotoNextKey());
	}

	delete kv_orig;

	//new
	KeyValues kv = new KeyValues("weapon");

	if (strlen(sWeapon) > 0)
		kv.SetString("name", sWeapon);

	if (strlen(sClasses) > 0)
		kv.SetString("classes", sClasses);

	if (slot != -1)
		kv.SetNum("slot", slot);

	if (strlen(sEntity) > 0)
		kv.SetString("entity", sEntity);

	if (index != -1)
		kv.SetNum("index", index);

	if (strlen(sViewmodel) > 0)
		kv.SetString("viewmodel", sViewmodel);

	if (strlen(sWorldmodel) > 0)
		kv.SetString("worldmodel", sWorldmodel);

	if (clip != -1)
		kv.SetNum("clip", clip);
	
	if (ammo != -1)
		kv.SetNum("ammo", ammo);
	
	kv.JumpToKey("attributes", true);

	for (int i = 0; i < attributes.Length; i++)
	{
		attributes.GetString(i, sAttribute, sizeof(sAttribute));
		values.GetString(sAttribute, sValue, sizeof(sValue));
		
		kv.JumpToKey(sAttribute, true);
		kv.SetString("default", sValue);
		kv.GoBack();
	}

	delete attributes;
	delete values;

	kv.Rewind();

	kv.JumpToKey("sounds", true);

	for (int i = 0; i < sounds.Length; i++)
	{
		sounds.GetString(i, sSound, sizeof(sSound));
		replacements.GetString(sSound, sReplace, sizeof(sReplace));
		pitches.GetString(sSound, sPitch, sizeof(sPitch));
		
		ReplaceString(sSound, sizeof(sSound), "/", "\\");
		kv.JumpToKey(sSound, true);

		kv.SetString("replace", sReplace);
		kv.SetString("pitch", sPitch);
		kv.GoBack();
	}

	delete sounds;
	delete replacements;
	delete pitches;

	kv.Rewind();
	ReplaceString(sPath, sizeof(sPath), ".txt", ".cfg");
	kv.ExportToFile(sPath);

	/*char sBuffer[4096];
	kv.ExportToString(sBuffer, sizeof(sBuffer));
	PrintToConsole(client, sBuffer);*/

	delete kv;
}

public int Native_RefillMag(Handle plugin, int numParams)
{
	int weapon = GetNativeCell(1);
	SetClip(weapon, g_WeaponsData[weapon].mag);
}

public int Native_RefillAmmo(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int weapon = GetNativeCell(2);
	SetAmmo(client, weapon, g_WeaponsData[weapon].ammo);
}

public int Native_EquipWearable(Handle plugin, int numParams)
{
	int size;
	GetNativeStringLength(2, size); size++;
	
	char[] sEntity = new char[size];
	GetNativeString(2, sEntity, size);
	
	return EquipWearable(GetNativeCell(1), sEntity, GetNativeCell(3), GetNativeCell(4), GetNativeCell(5));
}

int EquipWearable(int client, char[] classname, int index, int level = 50, int quality = 9)
{
	Handle hWearable = TF2Items_CreateItem(OVERRIDE_ALL);

	if (hWearable == null)
		return -1;

	TF2Items_SetClassname(hWearable, classname);
	TF2Items_SetItemIndex(hWearable, index);
	TF2Items_SetLevel(hWearable, level);
	TF2Items_SetQuality(hWearable, quality);

	int iWearable = TF2Items_GiveNamedItem(client, hWearable);
	delete hWearable;

	if (IsValidEntity(iWearable))
	{
		SetEntProp(iWearable, Prop_Send, "m_bValidatedAttachedEntity", true);
		Call_EquipWearable(client, iWearable);
	}

	return iWearable;
}

public int Native_EquipViewmodel(Handle plugin, int numParams)
{
	int size;
	GetNativeStringLength(2, size);

	char[] sModel = new char[size + 1];
	GetNativeString(2, sModel, size + 1);
	
	return EquipViewmodel(GetNativeCell(1), sModel);
}

int EquipViewmodel(int client, const char[] model)
{
	if (client == 0 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client) || strlen(model) == 0)
		return -1;
	
	int iWearable = CreateEntityByName("tf_wearable_vm");

	if (IsValidEntity(iWearable))
	{
		SetEntProp(iWearable, Prop_Send, "m_nModelIndex", PrecacheModel(model));
		SetEntProp(iWearable, Prop_Send, "m_fEffects", EF_BONEMERGE | EF_BONEMERGE_FASTCULL);
		SetEntProp(iWearable, Prop_Send, "m_iTeamNum", GetClientTeam(client));
		SetEntProp(iWearable, Prop_Send, "m_usSolidFlags", 4);
		SetEntProp(iWearable, Prop_Send, "m_CollisionGroup", 11);
		
		SetEntProp(iWearable, Prop_Send, "m_bValidatedAttachedEntity", true);
		Call_EquipWearable(client, iWearable);
	}

	return iWearable;
}

void Call_EquipWearable(int client, int wearable)
{
	if (g_SDK_EquipWearable != null)
		SDKCall(g_SDK_EquipWearable, client, wearable);
}
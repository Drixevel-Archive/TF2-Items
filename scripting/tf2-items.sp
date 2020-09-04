/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Items"
#define PLUGIN_DESCRIPTION "A simple and effective TF2 items plugin which allows for items, weapons and cosmetic customizations."
#define PLUGIN_VERSION "1.1.0"

#define EF_NODRAW 0x020

#define ARRAY_SIZE	2
#define ARRAY_ITEM	0
#define ARRAY_FLAGS	1

/*****************************/
//Includes
#include <sourcemod>

#include <misc-sm>
#include <misc-colors>
#include <misc-tf>

#include <tf2items>
#include <tf2attributes>
#include <tf2-items>

/*****************************/
//ConVars
ConVar convar_SpawnMenu;
ConVar convar_DisableMenu;

/*****************************/
//Forwards
Handle g_Forward_OnRegisterAttributes;
Handle g_Forward_OnRegisterAttributesPost;
Handle g_Forward_OnRegisterItemConfig;
Handle g_Forward_OnRegisterItemSetting;
Handle g_Forward_OnRegisterItemSettingStr;
Handle g_Forward_OnRegisterItemConfigPost;

/*****************************/
//Globals
bool g_Late;
bool g_IsCustom[MAX_ENTITY_LIMIT + 1];

ArrayList g_ItemsList;
StringMap g_ItemDescription;
StringMap g_ItemAuthors;	//Handle Hell
StringMap g_ItemItemFlags;
StringMap g_ItemFlags;
StringMap g_ItemSteamIDs;
StringMap g_ItemClasses;
StringMap g_ItemSlot;
StringMap g_ItemEntity;
StringMap g_ItemIndex;
StringMap g_ItemSize;
StringMap g_ItemSkin;
StringMap g_ItemRenderMode;
StringMap g_ItemRenderFx;
StringMap g_ItemRenderColor;
StringMap g_ItemViewmodel;
StringMap g_ItemWorldmodel;
StringMap g_ItemQuality;
StringMap g_ItemLevel;
StringMap g_ItemKillIcon;
StringMap g_ItemLogName;
StringMap g_ItemClip;
StringMap g_ItemAmmo;
StringMap g_ItemMetal;
StringMap g_ItemParticle;
StringMap g_ItemParticleTime;
StringMap g_ItemPreAttributesData;	//Handle Hell
StringMap g_ItemAttributesData;	//Handle Hell
StringMap g_ItemSoundsData;		//Handle Hell

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

/*****************************/
//Plugin Info
public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = "Drixevel", 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "https://drixevel.dev/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("tf2-items");

	CreateNative("TF2Items_AllowAttributeRegisters", Native_AllowAttributeRegisters);
	CreateNative("TF2Items_RegisterAttribute", Native_RegisterAttribute);
	
	CreateNative("TF2Items_GiveItem", Native_GiveItem);
	CreateNative("TF2Items_IsItemCustom", Native_IsItemCustom);
	
	CreateNative("TF2Items_RefillMag", Native_RefillMag);
	CreateNative("TF2Items_RefillAmmo", Native_RefillAmmo);
	
	CreateNative("TF2Items_EquipWearable", Native_EquipWearable);
	CreateNative("TF2Items_EquipViewmodel", Native_EquipViewmodel);

	CreateNative("TF2Items_GetItemKeyInt", Native_GetItemKeyInt);
	CreateNative("TF2Items_GetItemKeyFloat", Native_GetItemKeyFloat);
	CreateNative("TF2Items_GetItemKeyString", Native_GetItemKeyString);

	CreateNative("TF2Items_OpenInfoPanel", Native_OpenInfoPanel);

	g_Forward_OnRegisterAttributes = CreateGlobalForward("TF2Items_OnRegisterAttributes", ET_Event);
	g_Forward_OnRegisterAttributesPost = CreateGlobalForward("TF2Items_OnRegisterAttributesPost", ET_Ignore);
	
	g_Forward_OnRegisterItemConfig = CreateGlobalForward("TF2Items_OnRegisterItemConfig", ET_Event, Param_String, Param_String, Param_Cell);
	g_Forward_OnRegisterItemConfigPost = CreateGlobalForward("TF2Items_OnRegisterItemConfigPost", ET_Ignore, Param_String, Param_String, Param_Cell);
	
	g_Forward_OnRegisterItemSetting = CreateGlobalForward("TF2Items_OnRegisterItemSetting", ET_Event, Param_String, Param_String, Param_Any);
	g_Forward_OnRegisterItemSettingStr = CreateGlobalForward("TF2Items_OnRegisterItemSettingStr", ET_Event, Param_String, Param_String, Param_String);

	g_Late = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("tf2-items.phrases");
	
	CSetPrefix("{crimson}[Items]");
	
	convar_SpawnMenu = CreateConVar("sm_tf2_items_spawnmenu", "0", "Whether to display the items menu on spawn for players.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_DisableMenu = CreateConVar("sm_tf2_items_disablemenu", "1", "Disables the built-in items menu for non-admins.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AutoExecConfig();

	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("post_inventory_application", Event_OnResupply);
	HookEvent("player_death", Event_OnPlayerDeath, EventHookMode_Pre);
	AddNormalSoundHook(OnSoundPlay);

	g_ItemsList = new ArrayList(ByteCountToCells(MAX_ITEM_NAME_LENGTH));
	g_ItemDescription = new StringMap();
	g_ItemAuthors = new StringMap();
	g_ItemItemFlags = new StringMap();
	g_ItemFlags = new StringMap();
	g_ItemSteamIDs = new StringMap();
	g_ItemClasses = new StringMap();
	g_ItemSlot = new StringMap();
	g_ItemEntity = new StringMap();
	g_ItemIndex = new StringMap();
	g_ItemSize = new StringMap();
	g_ItemSkin = new StringMap();
	g_ItemRenderMode = new StringMap();
	g_ItemRenderFx = new StringMap();
	g_ItemRenderColor = new StringMap();
	g_ItemViewmodel = new StringMap();
	g_ItemWorldmodel = new StringMap();
	g_ItemQuality = new StringMap();
	g_ItemLevel = new StringMap();
	g_ItemKillIcon = new StringMap();
	g_ItemLogName = new StringMap();
	g_ItemClip = new StringMap();
	g_ItemAmmo = new StringMap();
	g_ItemMetal = new StringMap();
	g_ItemParticle = new StringMap();
	g_ItemParticleTime = new StringMap();
	g_ItemPreAttributesData = new StringMap();
	g_ItemAttributesData = new StringMap();
	g_ItemSoundsData = new StringMap();

	g_AttributesList = new ArrayList(ByteCountToCells(MAX_ATTRIBUTE_NAME_LENGTH));
	g_Attributes_Calls = new StringMap();

	RegConsoleCmd("sm_i", Command_Items);
	RegConsoleCmd("sm_items", Command_Items);
	RegConsoleCmd("sm_w", Command_Items);
	RegConsoleCmd("sm_weapons", Command_Items);
	RegConsoleCmd("sm_c", Command_Items);
	RegConsoleCmd("sm_cws", Command_Items);
	RegConsoleCmd("sm_customweapons", Command_Items);
	RegConsoleCmd("sm_weapon", Command_Items);
	RegConsoleCmd("sm_customweapon", Command_Items);
	RegConsoleCmd("sm_giveweapon", Command_Items);
	
	RegAdminCmd("sm_rw", Command_ReloadItems, ADMFLAG_ROOT);
	RegAdminCmd("sm_reloaditems", Command_ReloadItems, ADMFLAG_ROOT);
	
	RegAdminCmd("sm_ra", Command_ReloadAttributes, ADMFLAG_ROOT);
	RegAdminCmd("sm_reloadattributes", Command_ReloadAttributes, ADMFLAG_ROOT);

	RegAdminCmd("sm_create", Command_CreateItem, ADMFLAG_ROOT);
	RegAdminCmd("sm_createitem", Command_CreateItem, ADMFLAG_ROOT);
	RegAdminCmd("sm_createweapon", Command_CreateItem, ADMFLAG_ROOT);

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

	ParseItems();
	ParseOverrides();

	int drixevel = -1;
	if ((drixevel = GetDrixevel()) > 0 && IsClientInGame(drixevel))
		OpenItemsMenu(drixevel);
}

bool ParseItems()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/tf2-items");

	if (!DirExists(sPath))
	{
		CreateDirectory(sPath, 511);

		if (!DirExists(sPath))
			LogError("Error while generating directory: %s", sPath);
	}

	g_ItemsList.Clear();
	g_ItemDescription.Clear();
	g_ItemAuthors.Clear();
	g_ItemItemFlags.Clear();
	g_ItemFlags.Clear();
	g_ItemSteamIDs.Clear();
	g_ItemClasses.Clear();
	g_ItemSlot.Clear();
	g_ItemEntity.Clear();
	g_ItemIndex.Clear();
	g_ItemSize.Clear();
	g_ItemSkin.Clear();
	g_ItemRenderMode.Clear();
	g_ItemRenderFx.Clear();
	g_ItemRenderColor.Clear();
	g_ItemViewmodel.Clear();
	g_ItemWorldmodel.Clear();
	g_ItemQuality.Clear();
	g_ItemLevel.Clear();
	g_ItemKillIcon.Clear();
	g_ItemLogName.Clear();
	g_ItemClip.Clear();
	g_ItemAmmo.Clear();
	g_ItemMetal.Clear();
	g_ItemParticle.Clear();
	g_ItemParticleTime.Clear();
	g_ItemPreAttributesData.Clear();
	g_ItemAttributesData.Clear();
	g_ItemSoundsData.Clear();

	StrCat(sPath, sizeof(sPath), "/items");

	if (!DirExists(sPath))
	{
		CreateDirectory(sPath, 511);

		if (!DirExists(sPath))
			LogError("Error while generating directory for items directory: %s", sPath);
	}

	ParseItemsFolder(sPath);
}

bool ParseItemsFolder(const char[] path)
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
				ParseItemConfig(sFile);
			}
			case FileType_Directory:
			{
				if (StrEqual(sFile, ".") || StrEqual(sFile, ".."))
					continue;
				
				Format(sFile, sizeof(sFile), "%s/%s", path, sFile);
				ParseItemsFolder(sFile);
			}
		}
	}

	delete dir;
	return true;
}

bool ParseItemConfig(const char[] file)
{
	KeyValues kv = new KeyValues("item");

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
	char sName[MAX_ITEM_NAME_LENGTH];
	kv.GetString("name", sName, sizeof(sName));

	if (strlen(sName) == 0)
	{
		delete kv;
		return false;
	}

	Call_StartForward(g_Forward_OnRegisterItemConfig);
	Call_PushString(sName);
	Call_PushString(file);
	Call_PushCell(kv);
	Action result = Plugin_Continue; Call_Finish(result);

	if (kv == null)
	{
		LogError("Error while accessing '%s' item config: API killed the Settings handle.", sName);
		return false;
	}

	if (result >= Plugin_Handled)
	{
		delete kv;
		return false;
	}
	
	g_ItemsList.PushString(sName);

	//description
	char sDescription[MAX_DESCRIPTION_LENGTH];
	kv.GetString("description", sDescription, sizeof(sDescription));
	g_ItemDescription.SetString(sName, sDescription);
	CallSettingsForwardStr(sName, "description", sDescription);

	//authors
	if (kv.JumpToKey("authors") && kv.GotoFirstSubKey(false))
	{
		ArrayList authors = new ArrayList(ByteCountToCells(MAX_NAME_LENGTH));
		StringMap authorsdata = new StringMap();
		
		char sAuthor[MAX_NAME_LENGTH];
		char sAuthorsData[64];
		
		do
		{
			kv.GetSectionName(sAuthor, sizeof(sAuthor));
			kv.GetString(NULL_STRING, sAuthorsData, sizeof(sAuthorsData));

			authors.PushString(sAuthor);
			authorsdata.SetString(sAuthor, sAuthorsData);
		}
		while (kv.GotoNextKey(false));

		g_ItemAuthors.SetValue(sName, authors);

		char sAuthorsData2[MAX_ITEM_NAME_LENGTH + 12];
		FormatEx(sAuthorsData2, sizeof(sAuthorsData2), "%s_data", sName);
		g_ItemAuthors.SetValue(sAuthorsData2, authorsdata);

		kv.Rewind();
	}

	//entity flags
	char sItemFlags[256];
	kv.GetString("itemflags", sItemFlags, sizeof(sItemFlags), "PRESERVE_ATTRIBUTES");
	g_ItemItemFlags.SetString(sName, sItemFlags);
	CallSettingsForwardStr(sName, "itemflags", sItemFlags);
	
	//flags
	char sFlags[MAX_FLAGS_LENGTH];
	kv.GetString("flags", sFlags, sizeof(sFlags));
	g_ItemFlags.SetString(sName, sFlags);
	CallSettingsForwardStr(sName, "flags", sFlags);

	//steamids
	char sSteamIDs[2048];
	kv.GetString("steamids", sSteamIDs, sizeof(sSteamIDs));
	g_ItemSteamIDs.SetString(sName, sSteamIDs);
	CallSettingsForwardStr(sName, "steamids", sSteamIDs);

	//classes
	char sClasses[2048];
	kv.GetString("classes", sClasses, sizeof(sClasses));
	g_ItemClasses.SetString(sName, sClasses);
	CallSettingsForwardStr(sName, "classes", sClasses);

	//slots
	char sSlot[2048];
	kv.GetString("slot", sSlot, sizeof(sSlot));
	
	int iSlot = IsStringNumeric(sSlot) ? StringToInt(sSlot) : GetSlotIDFromName(sSlot);
	g_ItemSlot.SetValue(sName, iSlot);
	CallSettingsForward(sName, "slot", iSlot);

	//entity
	char sEntity[MAX_ENTITY_CLASSNAME_LENGTH];
	kv.GetString("entity", sEntity, sizeof(sEntity));
	g_ItemEntity.SetString(sName, sEntity);
	CallSettingsForwardStr(sName, "entity", sEntity);

	//index
	int iIndex = kv.GetNum("index");
	g_ItemIndex.SetValue(sName, iIndex);
	CallSettingsForward(sName, "index", iIndex);

	//size
	float fSize = kv.GetFloat("size", 1.0);
	g_ItemSize.SetValue(sName, fSize);
	CallSettingsForward(sName, "size", fSize);

	//skin
	int iSkin = kv.GetNum("skin");
	g_ItemSkin.SetValue(sName, iSkin);
	CallSettingsForward(sName, "skin", iSkin);

	//rendermode
	char sRenderMode[32];
	kv.GetString("rendermode", sRenderMode, sizeof(sRenderMode));

	RenderMode mode = GetRenderModeByName(sRenderMode);
	g_ItemRenderMode.SetValue(sName, mode);
	CallSettingsForward(sName, "rendermode", mode);

	//renderfx
	char sRenderFx[32];
	kv.GetString("renderfx", sRenderFx, sizeof(sRenderFx));
	
	RenderFx fx = GetRenderFxByName(sRenderFx);
	g_ItemRenderFx.SetValue(sName, GetRenderFxByName(sRenderFx));
	CallSettingsForward(sName, "renderfx", fx);

	//rendercolor
	char sRenderColor[32];
	kv.GetString("rendercolor", sRenderColor, sizeof(sRenderColor));
	g_ItemRenderColor.SetArray(sName, GetColorByName(sRenderColor), 4);

	//viewmodel
	char sViewmodel[PLATFORM_MAX_PATH];
	kv.GetString("viewmodel", sViewmodel, sizeof(sViewmodel));
	g_ItemViewmodel.SetString(sName, sViewmodel);
	CallSettingsForwardStr(sName, "viewmodel", sViewmodel);

	//worldmodel
	char sWorldModel[PLATFORM_MAX_PATH];
	kv.GetString("worldmodel", sWorldModel, sizeof(sWorldModel));
	g_ItemWorldmodel.SetString(sName, sWorldModel);
	CallSettingsForwardStr(sName, "worldmodel", sWorldModel);

	//quality
	char sQuality[QUALITY_NAME_LENGTH];
	kv.GetString("quality", sQuality, sizeof(sQuality));
	g_ItemQuality.SetString(sName, sQuality);
	CallSettingsForwardStr(sName, "quality", sQuality);

	//level
	int iLevel = kv.GetNum("level");
	g_ItemLevel.SetValue(sName, iLevel);
	CallSettingsForward(sName, "level", iLevel);

	//killicon
	char sKillIcon[64];
	kv.GetString("killicon", sKillIcon, sizeof(sKillIcon));
	g_ItemKillIcon.SetString(sName, sKillIcon);
	CallSettingsForwardStr(sName, "killicon", sKillIcon);

	//logname
	char sLogName[64];
	kv.GetString("logname", sLogName, sizeof(sLogName));
	g_ItemLogName.SetString(sName, sLogName);
	CallSettingsForwardStr(sName, "logname", sLogName);

	//clip
	int iClip = kv.GetNum("clip", -1);
	g_ItemClip.SetValue(sName, iClip);
	CallSettingsForward(sName, "clip", iClip);

	//ammo
	int iAmmo = kv.GetNum("ammo", -1);
	g_ItemAmmo.SetValue(sName, iAmmo);
	CallSettingsForward(sName, "ammo", iAmmo);

	//metal
	int iMetal = kv.GetNum("metal");
	g_ItemMetal.SetValue(sName, iMetal);
	CallSettingsForward(sName, "metal", iMetal);

	//particle
	char sParticle[MAX_PARTICLE_NAME_LENGTH];
	kv.GetString("particle", sParticle, sizeof(sParticle));
	g_ItemParticle.SetString(sName, sParticle);
	CallSettingsForwardStr(sName, "particle", sParticle);

	//particle_time
	float fParticleTime = kv.GetFloat("particle_time");
	g_ItemParticleTime.SetValue(sName, fParticleTime);
	CallSettingsForward(sName, "particle_time", fParticleTime);

	//pre-attributes
	if (kv.JumpToKey("pre-attributes") && kv.GotoFirstSubKey(false))
	{
		ArrayList attributes = new ArrayList(ByteCountToCells(MAX_ATTRIBUTE_NAME_LENGTH));
		StringMap attributesvalues = new StringMap();
		
		char sAttributeName[MAX_ATTRIBUTE_NAME_LENGTH];
		float fAttributeValue;

		do
		{
			kv.GetSectionName(sAttributeName, sizeof(sAttributeName));
			fAttributeValue = kv.GetFloat(NULL_STRING, 0.0);

			attributes.PushString(sAttributeName);
			attributesvalues.SetValue(sAttributeName, fAttributeValue);
		}
		while (kv.GotoNextKey(false));

		g_ItemPreAttributesData.SetValue(sName, attributes);

		char sAttributesValues[MAX_ITEM_NAME_LENGTH + 12];
		FormatEx(sAttributesValues, sizeof(sAttributesValues), "%s_values", sName);
		g_ItemPreAttributesData.SetValue(sAttributesValues, attributesvalues);

		kv.Rewind();
	}
	
	//attributes
	if (kv.JumpToKey("attributes") && kv.GotoFirstSubKey())
	{
		StringMap attributesdata = new StringMap();
		ArrayList attributeslist = new ArrayList(ByteCountToCells(MAX_ATTRIBUTE_NAME_LENGTH));
		char sAttributeName[MAX_ATTRIBUTE_NAME_LENGTH];

		do
		{
			kv.GetSectionName(sAttributeName, sizeof(sAttributeName));
			sAttributeName[0] = CharToLower(sAttributeName[0]);
			
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

		g_ItemAttributesData.SetValue(sName, attributesdata);

		char sAttributesList[MAX_ITEM_NAME_LENGTH + 12];
		FormatEx(sAttributesList, sizeof(sAttributesList), "%s_list", sName);
		g_ItemAttributesData.SetValue(sAttributesList, attributeslist);

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

		g_ItemSoundsData.SetValue(sName, soundsdata);

		char sSoundsList[MAX_ITEM_NAME_LENGTH + 12];
		FormatEx(sSoundsList, sizeof(sSoundsList), "%s_list", sName);
		g_ItemSoundsData.SetValue(sSoundsList, soundslist);

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

	Call_StartForward(g_Forward_OnRegisterItemConfigPost);
	Call_PushString(sName);
	Call_PushString(file);
	Call_PushCell(kv);
	Call_Finish();

	delete kv;
	LogMessage("Item Config Parsed: %s", file);

	return true;
}

void CallSettingsForward(const char[] name, const char[] setting, any value)
{
	Call_StartForward(g_Forward_OnRegisterItemSetting);
	Call_PushString(name);
	Call_PushString(setting);
	Call_PushCell(value);
	Call_Finish();
}

void CallSettingsForwardStr(const char[] name, const char[] setting, const char[] value)
{
	Call_StartForward(g_Forward_OnRegisterItemSettingStr);
	Call_PushString(name);
	Call_PushString(setting);
	Call_PushString(value);
	Call_Finish();
}

void ParseOverrides()
{
	DestroyItems();
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/tf2-items/item-overrides.cfg");
	
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
	
	if (convar_SpawnMenu.BoolValue)
		OpenItemsMenu(client);
}

public void Event_OnResupply(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client == 0)
		return;
	
	int entity = -1; char sName[MAX_ITEM_NAME_LENGTH];
	while ((entity = FindEntityByClassname(entity, "tf_weapon_*")) != -1)
	{
		if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", sName, sizeof(sName));
			ExecuteItemAction(client, entity, sName, "remove");
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

	char sName[MAX_ITEM_NAME_LENGTH];
	GetEntPropString(weapon, Prop_Data, "m_iName", sName, sizeof(sName));

	if (strlen(sName) == 0)
		return Plugin_Continue;
	
	bool changed;

	char sKillIcon[64];
	if (g_ItemKillIcon.GetString(sName, sKillIcon, sizeof(sKillIcon)) && strlen(sKillIcon) > 0)
	{
		event.SetString("weapon", sKillIcon);
		changed = true;
	}

	char sLogName[64];
	if (g_ItemLogName.GetString(sName, sLogName, sizeof(sLogName)) && strlen(sLogName) > 0)
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
			ExecuteItemAction(client, entity, sName, "remove");
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

public Action Command_Items(int client, int args)
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
		OpenItemsMenu(client);
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(client))
	{
		CPrintToChat(client, "You must be alive to give yourself an item.");
		return Plugin_Handled;
	}

	char sName[MAX_ITEM_NAME_LENGTH];
	GetCmdArgString(sName, sizeof(sName));

	if (g_ItemsList.FindString(sName) == -1)
	{
		char sBuffer[MAX_ITEM_NAME_LENGTH];
		for (int i = 0; i < g_ItemsList.Length; i++)
		{
			g_ItemsList.GetString(i, sBuffer, sizeof(sBuffer));

			if (StrContains(sBuffer, sName) != -1)
			{
				strcopy(sName, sizeof(sName), sBuffer);
				break;
			}
		}

		if (g_ItemsList.FindString(sName) == -1)
		{
			CPrintToChat(client, "You have specified an item that isn't available.");
			return Plugin_Handled;
		}
	}

	char sCurrentClass[64];
	TF2_GetClientClassName(client, sCurrentClass, sizeof(sCurrentClass));

	char sClass[2048];
	g_ItemClasses.GetString(sName, sClass, sizeof(sClass));
	if (strlen(sClass) > 0 && StrContains(sClass, sCurrentClass, false) == -1)
	{
		CPrintToChat(client, "You must be a {crimson}%s {default}to equip this item.", sClass);
		return Plugin_Handled;
	}

	char sFlags[MAX_FLAGS_LENGTH];
	g_ItemFlags.GetString(sName, sFlags, sizeof(sFlags));
	if (strlen(sFlags) > 0 && !CheckCommandAccess(client, "", ReadFlagString(sFlags), true))
	{
		CPrintToChat(client, "You don't have the required flags to equip this item.");
		return Plugin_Handled;
	}

	char sSteamID[64];
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));
	
	char sSteamIDs[2048];
	g_ItemSteamIDs.GetString(sName, sSteamIDs, sizeof(sSteamIDs));
	if (!IsDrixevel(client) && strlen(sSteamIDs) > 0 && StrContains(sSteamIDs, sSteamID, false) == -1)
	{
		CPrintToChat(client, "You don't have access to equipping this item.");
		return Plugin_Handled;
	}

	GiveItem(client, sName, true, true);
	return Plugin_Handled;
}

void OpenItemsMenu(int client)
{
	char sCurrentClass[64];
	TF2_GetClientClassName(client, sCurrentClass, sizeof(sCurrentClass));

	char sSteamID[64];
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));

	Menu menu = new Menu(MenuHandler_Items);
	menu.SetTitle("Pick an item to equip:");

	char sName[MAX_ITEM_NAME_LENGTH]; char sClass[2048]; char sFlags[MAX_FLAGS_LENGTH]; char sSteamIDs[2048]; 
	for (int i = 0; i < g_ItemsList.Length; i++)
	{
		g_ItemsList.GetString(i, sName, sizeof(sName));
		
		g_ItemClasses.GetString(sName, sClass, sizeof(sClass));
		if (strlen(sClass) > 0 && StrContains(sClass, "all", false) == -1 && StrContains(sClass, sCurrentClass, false) == -1)
			continue;

		g_ItemFlags.GetString(sName, sFlags, sizeof(sFlags));
		if (strlen(sFlags) > 0 && !CheckCommandAccess(client, "", ReadFlagString(sFlags), true))
			continue;
		
		g_ItemSteamIDs.GetString(sName, sSteamIDs, sizeof(sSteamIDs));
		if (!IsDrixevel(client) && strlen(sSteamIDs) > 0 && StrContains(sSteamIDs, sSteamID, false) == -1)
			continue;

		menu.AddItem(sName, sName);
	}

	if (menu.ItemCount == 0)
		menu.AddItem("", " -- No Items Available --", ITEMDRAW_DISABLED);

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Items(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sName[MAX_ITEM_NAME_LENGTH];
			menu.GetItem(param2, sName, sizeof(sName));

			OpenItemMenu(param1, sName);
		}
		case MenuAction_End:
			delete menu;
	}
}

void OpenItemMenu(int client, const char[] name)
{
	char sDescription[MAX_DESCRIPTION_LENGTH];
	g_ItemDescription.GetString(name, sDescription, sizeof(sDescription));

	if (strlen(sDescription) > 0)
		Format(sDescription, sizeof(sDescription), "\nDescription: %s\n \n", sDescription);
	
	Menu menu = new Menu(MenuHandler_Item);
	menu.SetTitle("Information for item: %s%s", name, strlen(sDescription) > 0 ? sDescription : "\n ");

	menu.AddItem("equip", "Equip Item");
	menu.AddItem("info", "Item Information");
	menu.AddItem("spawn", "Spawn with Item");

	ArrayList authors;
	g_ItemAuthors.GetValue(name, authors);

	if (authors != null)
		menu.AddItem("authors", "View Authors");

	PushMenuString(menu, "name", name);
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Item(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sAction[64];
			menu.GetItem(param2, sAction, sizeof(sAction));

			char sName[MAX_ITEM_NAME_LENGTH];
			GetMenuString(menu, "name", sName, sizeof(sName));

			if (StrEqual(sAction, "equip"))
			{
				if (!IsPlayerAlive(param1))
				{
					CPrintToChat(param1, "You must be alive to give yourself an item.");
					OpenItemMenu(param1, sName);
					return;
				}

				GiveItem(param1, sName, true, true);
			}
			else if (StrEqual(sAction, "info"))
				OpenInfoPanel(param1, sName);
			else if (StrEqual(sAction, "spawn"))
				OpenSpawnItemClassMenu(param1, sName);
			else if (StrEqual(sAction, "authors"))
				ShowAuthors(param1, sName);
		}
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack)
				OpenItemsMenu(param1);
		case MenuAction_End:
			delete menu;
	}
}

public Action Command_ReloadItems(int client, int args)
{
	ParseItems();
	ReplyToCommand(client, "All item configs have been reloaded.");
	return Plugin_Handled;
}

public Action Command_ReloadAttributes(int client, int args)
{
	CallAttributeRegistrations();
	ReplyToCommand(client, "All attributes have been reloaded.");
	return Plugin_Handled;
}

int GiveItem(int client, const char[] name, bool message = false, bool inspect = false)
{
	if (client < 1 || client > MaxClients || strlen(name) == 0)
		return -1;
	
	char sEntity[MAX_ENTITY_CLASSNAME_LENGTH];
	g_ItemEntity.GetString(name, sEntity, sizeof(sEntity));

	if (strlen(sEntity) == 0)
		return -1;
	
	int slot;
	g_ItemSlot.GetValue(name, slot);
	TF2_RemoveWeaponSlot(client, slot);

	if (StrContains(sEntity, "tf_weapon_", false) != 0)
		Format(sEntity, sizeof(sEntity), "tf_weapon_%s", sEntity);

	char sItemFlags[256];
	g_ItemItemFlags.GetString(name, sItemFlags, sizeof(sItemFlags));

	int flags;

	if (StrContains(sItemFlags, "OVERRIDE_CLASSNAME", false) != -1)
		flags |= OVERRIDE_CLASSNAME;
	if (StrContains(sItemFlags, "OVERRIDE_ITEM_DEF", false) != -1)
		flags |= OVERRIDE_ITEM_DEF;
	if (StrContains(sItemFlags, "OVERRIDE_ITEM_LEVEL", false) != -1)
		flags |= OVERRIDE_ITEM_LEVEL;
	if (StrContains(sItemFlags, "OVERRIDE_ITEM_QUALITY", false) != -1)
		flags |= OVERRIDE_ITEM_QUALITY;
	if (StrContains(sItemFlags, "OVERRIDE_ATTRIBUTES", false) != -1)
		flags |= OVERRIDE_ATTRIBUTES;
	if (StrContains(sItemFlags, "OVERRIDE_ALL", false) != -1)
		flags |= OVERRIDE_ALL;
	if (StrContains(sItemFlags, "PRESERVE_ATTRIBUTES", false) != -1)
		flags |= PRESERVE_ATTRIBUTES;
	if (StrContains(sItemFlags, "FORCE_GENERATION", false) != -1)
		flags |= FORCE_GENERATION;

	Handle hItem = TF2Items_CreateItem(flags);

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
	g_ItemIndex.GetValue(name, index);
	TF2Items_SetItemIndex(hItem, index);

	int level;
	g_ItemLevel.GetValue(name, level);
	TF2Items_SetLevel(hItem, level);

	char sQuality[32]; int quality;
	g_ItemQuality.GetString(name, sQuality, sizeof(sQuality));
	quality = IsStringNumeric(sQuality) ? StringToInt(sQuality) : view_as<int>(TF2_GetQualityFromName(sQuality));
	TF2Items_SetQuality(hItem, quality);

	ArrayList attributes;
	if (g_ItemPreAttributesData.GetValue(name, attributes) && attributes != null)
	{
		char sAttributesValues[MAX_ITEM_NAME_LENGTH + 12];
		FormatEx(sAttributesValues, sizeof(sAttributesValues), "%s_values", name);

		StringMap attributesvalues;
		g_ItemPreAttributesData.GetValue(sAttributesValues, attributesvalues);
		
		char sAttribute[MAX_ATTRIBUTE_NAME_LENGTH];
		float fAttributeValue;

		TF2Items_SetNumAttributes(hItem, attributes.Length);
		for (int i = 0; i < attributes.Length; i++)
		{
			attributes.GetString(i, sAttribute, sizeof(sAttribute));
			attributesvalues.GetValue(sAttribute, fAttributeValue);
			TF2Items_SetAttribute(hItem, i, StringToInt(sAttribute), fAttributeValue);
		}
	}

	int entity = TF2Items_GiveNamedItem(client, hItem);
	delete hItem;

	if (!IsValidEntity(entity))
		return entity;
	
	DispatchKeyValue(entity, "targetname", name);	//Used for sounds.
	SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", 1);

	float size;
	g_ItemSize.GetValue(name, size);
	SetEntPropFloat(entity, Prop_Send, "m_flModelScale", size);

	int skin;
	g_ItemSkin.GetValue(name, skin);
	SetEntProp(entity, Prop_Send, "m_nSkin", skin);

	RenderMode rendermode;
	g_ItemRenderMode.GetValue(name, rendermode);
	SetEntityRenderMode(entity, rendermode);

	RenderFx renderfx;
	g_ItemRenderFx.GetValue(name, renderfx);
	SetEntityRenderFx(entity, renderfx);

	int color[4];
	g_ItemRenderColor.GetArray(name, color, sizeof(color));
	SetEntityRenderColorEx(entity, color);

	char sViewmodel[PLATFORM_MAX_PATH];
	g_ItemViewmodel.GetString(name, sViewmodel, sizeof(sViewmodel));

	AttachViewmodel(client, class, entity, sViewmodel, index);

	char sWorldModel[PLATFORM_MAX_PATH];
	g_ItemWorldmodel.GetString(name, sWorldModel, sizeof(sWorldModel));
	SetWorldModel(entity, sWorldModel);

	int clip;
	g_ItemClip.GetValue(name, clip);

	if (clip != -1)
		SetWeaponClip(entity, clip);

	int ammo;
	g_ItemAmmo.GetValue(name, ammo);

	if (ammo != -1)
		SetWeaponAmmo(client, entity, ammo);

	if (class == TFClass_Engineer)
	{
		int metal;
		g_ItemMetal.GetValue(name, metal);
		TF2_SetMetal(client, metal);
	}

	char sParticle[MAX_PARTICLE_NAME_LENGTH];
	g_ItemParticle.GetString(name, sParticle, sizeof(sParticle));

	if (strlen(sParticle) > 0)
	{
		float particletime;
		g_ItemParticleTime.GetValue(name, particletime);

		if (particletime < 0.0)
			particletime = 0.0;
		
		AttachParticle(entity, sParticle, particletime);
	}

	ExecuteItemAction(client, entity, name, "apply");
	EquipPlayerWeapon(client, entity);
	
	if (StrContains(sEntity, "tf_weapon", false) == 0)
		EquipWeaponSlot(client, slot);

	if (message)
		CPrintToChat(client, "Item Equipped: {crimson}%s", name);
	
	g_IsCustom[entity] = true;
	
	if (inspect)
	{
		KeyValues kv = new KeyValues("inspect_weapon");
		kv.SetSectionName("+inspect_server");
		FakeClientCommandKeyValues(client, kv);
		
		CreateTimer(0.2, Timer_EndInspectAnim, GetClientUserId(client));
	}

	return entity;
}

public Action Timer_EndInspectAnim(Handle timer, any data)
{
	int client;

	if ((client = GetClientOfUserId(data)) == 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	KeyValues kv = new KeyValues("inspect_weapon");
	kv.SetSectionName("-inspect_server");
	FakeClientCommandKeyValues(client, kv);

	return Plugin_Continue;
}

void AttachViewmodel(int client, TFClassType class, int item, char[] viewmodel, int index)
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
	
	int viewmodel1 = CreateEntityByName("tf_wearable_vm");
	if (IsValidEntity(viewmodel1))
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

		SetEntProp(viewmodel1, Prop_Send, "m_nModelIndex", PrecacheModel(sArms));
		SetEntProp(viewmodel1, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_BONEMERGE_FASTCULL);
		SetEntProp(viewmodel1, Prop_Send, "m_iTeamNum", GetClientTeam(client));
		SetEntProp(viewmodel1, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID);
		SetEntProp(viewmodel1, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_WEAPON);

		DispatchSpawn(viewmodel1);

		SetVariantString("!activator");
		ActivateEntity(viewmodel1);

		Call_EquipWearable(client, viewmodel1);
			
		SetEntPropEnt(viewmodel1, Prop_Send, "m_hEffectEntity", item);
		SDKHook(viewmodel1, SDKHook_SetTransmit, OnWeaponTransmit);
	}
	
	int viewmodel2 = CreateEntityByName("tf_wearable_vm");
	if (IsValidEntity(viewmodel2))
	{
		SetEntProp(viewmodel2, Prop_Send, "m_nModelIndex", PrecacheModel(viewmodel));
		SetEntProp(viewmodel2, Prop_Send, "m_iItemDefinitionIndex", index);
		SetEntProp(viewmodel2, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_BONEMERGE_FASTCULL);
		SetEntProp(viewmodel2, Prop_Send, "m_iTeamNum", GetClientTeam(client));
		SetEntProp(viewmodel2, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID);
		SetEntProp(viewmodel2, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_WEAPON);
		
		DispatchSpawn(viewmodel2);

		SetVariantString("!activator");
		ActivateEntity(viewmodel2);

		Call_EquipWearable(client, viewmodel2);

		SetEntPropEnt(viewmodel2, Prop_Send, "m_hEffectEntity", item);
		SDKHook(viewmodel2, SDKHook_SetTransmit, OnWeaponTransmit);
	}
}

public Action OnWeaponTransmit(int entity, int other)
{
	if (entity == -1) 
		return Plugin_Continue;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if (0 < owner <= MaxClients)
	{
		if (owner != other)
			return Plugin_Continue;
		
		int active = GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon");
		int attached = GetEntPropEnt(entity, Prop_Send, "m_hEffectEntity");
		
		if (attached > MaxClients && GetEntProp(attached, Prop_Send, "m_bBeingRepurposedForTaunt"))
			SetEntProp(attached, Prop_Send, "m_nModelIndexOverrides", 0);
		else if (attached > -1)
			SetEntProp(attached, Prop_Send, "m_nModelIndexOverrides", GetEntProp(attached, Prop_Send, "m_iWorldModelIndex"));
		
		if (active == attached)
		{
			int effects = GetEntProp(entity, Prop_Send, "m_fEffects");
			
			if ((effects & EF_NODRAW))
				SetEntProp(entity, Prop_Send, "m_fEffects", GetEntProp(entity, Prop_Send, "m_fEffects") &~ EF_NODRAW);
			
			int viewmodel = MaxClients + 1;
			while ((viewmodel = FindEntityByClassname(viewmodel, "tf_viewmodel")) > MaxClients)
			{
				int iViewOwner = GetEntPropEnt(viewmodel, Prop_Send, "m_hOwner");
				
				if (iViewOwner == owner)
					SetEntProp(viewmodel, Prop_Send, "m_fEffects", GetEntProp(viewmodel, Prop_Send, "m_fEffects") | EF_NODRAW);
			}
		}
		else
		{
			int effects = GetEntProp(entity, Prop_Send, "m_fEffects");
			
			if (!(effects & EF_NODRAW))
			{
				SetEntProp(entity, Prop_Send, "m_fEffects", effects|EF_NODRAW);
				
				int viewmodel = MaxClients + 1;
				while ((viewmodel = FindEntityByClassname(viewmodel, "tf_viewmodel")) > MaxClients)
				{
					int iViewOwner = GetEntPropEnt(viewmodel, Prop_Send, "m_hOwner");
					
					if (iViewOwner == owner)
						SetEntProp(viewmodel, Prop_Send, "m_fEffects", GetEntProp(viewmodel, Prop_Send, "m_fEffects") &~ EF_NODRAW);
				}
			}
		}

		return Plugin_Continue;
	}

	AcceptEntityInput(entity, "Kill");
	return Plugin_Continue;
}

void SetWorldModel(int item, char[] worldmodel)
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
		SetEntProp(item, Prop_Send, "m_iWorldModelIndex", model);
		SetEntProp(item, Prop_Send, "m_nModelIndexOverrides", model);
	}
}

void OpenSpawnItemClassMenu(int client, const char[] name)
{
	Menu menu = new Menu(MenuHandler_OpenSpawnItemClassMenu);
	menu.SetTitle("Pick a class to spawn '%s' with:", name);

	char sClass[2048];
	g_ItemClasses.GetString(name, sClass, sizeof(sClass));

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

public int MenuHandler_OpenSpawnItemClassMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sClass[32];
			menu.GetItem(param2, sClass, sizeof(sClass));

			char sName[MAX_ITEM_NAME_LENGTH];
			GetMenuString(menu, "name", sName, sizeof(sName));

			int iSlot;
			g_ItemSlot.SetValue(sName, iSlot);

			SetSpawnItem(param1, sClass, iSlot, sName);
		}
		case MenuAction_End:
			delete menu;
	}
}

void SetSpawnItem(int client, const char[] class, int slot, const char[] name)
{
	CPrintToChat(client, "{crimson}%s {default}has been equipped for the {crimson}%s {default}class and the {crimson}%i {default}slot.", name, class, slot);
}

public int Native_AllowAttributeRegisters(Handle plugin, int numParams)
{
	return g_AttributesList != null;
}

bool ExecuteItemAction(int client, int item, const char[] name, const char[] action)
{
	StringMap attributesdata;
	if (!g_ItemAttributesData.GetValue(name, attributesdata) || attributesdata == null)
		return false;
	
	char sAttributesList[MAX_ATTRIBUTE_NAME_LENGTH + 12];
	FormatEx(sAttributesList, sizeof(sAttributesList), "%s_list", name);

	ArrayList attributeslist;
	if (!g_ItemAttributesData.GetValue(sAttributesList, attributeslist) || attributeslist == null)
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
		
		ExecuteAttributeAction(client, item, sAttribute, action, attributedata);
	}

	return true;
}

bool ExecuteAttributeAction(int client, int item, char[] attrib, const char[] action, StringMap attributesdata)
{
	float value;
	if (attributesdata.GetValue("default", value))
		TF2Attrib_SetByName(item, attrib, value);

	Handle action_call;
	if (!g_Attributes_Calls.GetValue(attrib, action_call) || action_call == null)
		return false;

	if (action_call != null && GetForwardFunctionCount(action_call) > 0)
	{
		Call_StartForward(action_call);
		Call_PushCell(client);
		Call_PushCell(item);
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
		int item = GetEntPropEnt(entity, Prop_Send, "m_hActiveWeapon");

		if (!IsValidEntity(item))
			return Plugin_Continue;
		
		char sName[MAX_ITEM_NAME_LENGTH];
		GetEntPropString(item, Prop_Data, "m_iName", sName, sizeof(sName));

		StringMap soundsdata;
		if (!g_ItemSoundsData.GetValue(sName, soundsdata) || soundsdata == null)
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

public Action Command_CreateItem(int client, int args)
{
	if (args == 0)
	{
		if (IsClientServer(client))
		{
			CReplyToCommand(client, "You must be in-game to use this command.");
			return Plugin_Handled;
		}

		OpenCreateItemMenu(client);
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	GetCmdArgString(sPath, sizeof(sPath));

	if (StrContains(sPath, "configs/tf2-items/items", false) != 0)
		Format(sPath, sizeof(sPath), "configs/tf2-items/items/%s", sPath);
	
	if (StrContains(sPath, ".cfg", false) != strlen(sPath) - 4)
		Format(sPath, sizeof(sPath), "%s.cfg", sPath);

	char sFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFile, sizeof(sFile), sPath);

	bool created = CreateItemConfig(sFile);
	CReplyToCommand(client, "Item template created %ssuccessfully at '%s'.", created ? "" : "un", sPath);

	return Plugin_Handled;
}

bool OpenCreateItemMenu(int client)
{
	Menu menu = new Menu(MenuHandler_CreateItem);
	menu.SetTitle("Create a new item:");

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

public int MenuHandler_CreateItem(Menu menu, MenuAction action, int param1, int param2)
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

bool CreateItemConfig(const char[] file, const char[] name = " ", const char[] description = " ", const char[] flags = " ", const char[] steamids = " ", const char[] classes = " ", const char[] slot = " ", const char[] entity = " ", int index = 0, const char[] viewmodel = " ", const char[] worldmodel = " ", int attachment = 0, float attachment_pos[3] = NULL_VECTOR, float attachment_ang[3] = NULL_VECTOR, float attachment_scale = 1.0, const char[] quality = " ", int level = 0, int clip = 0, int ammo = 0, int metal = 0, const char[] particle = " ", float particle_time = 1.0)
{
	KeyValues kv = new KeyValues("item");

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

stock Handle ApplyItemOverrides(int client, int iItemDefinitionIndex)
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

enum struct ItemsData
{
	int mag;
	int ammo;
}

ItemsData g_ItemsData[MAX_ENTITY_LIMIT + 1];

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
		g_ItemsData[entityIndex].mag = GetWeaponClip(entityIndex);
		g_ItemsData[entityIndex].ammo = GetWeaponAmmo(client, entityIndex);
	}
}

public int Native_GiveItem(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	char sName[MAX_ITEM_NAME_LENGTH];
	GetNativeString(2, sName, sizeof(sName));

	bool message = GetNativeCell(3);
	bool inspect = GetNativeCell(4);

	return GiveItem(client, sName, message, inspect);
}

public int Native_IsItemCustom(Handle plugin, int numParams)
{
	return g_IsCustom[GetNativeCell(1)];
}

public int Native_GetItemKeyInt(Handle plugin, int numParams)
{
	int size;
	GetNativeStringLength(1, size); size++;

	char[] sItem = new char[size];
	GetNativeString(1, sItem, size);

	if (g_ItemsList.FindString(sItem) == -1)
		return -1;
	
	GetNativeStringLength(2, size); size++;

	char[] sKey = new char[size];
	GetNativeString(2, sKey, size);

	int value = -1;

	if (StrEqual(sKey, "slot", false))
		g_ItemSlot.GetValue(sItem, value);

	return value;
}

public int Native_GetItemKeyFloat(Handle plugin, int numParams)
{
	int size;
	GetNativeStringLength(1, size); size++;

	char[] sItem = new char[size];
	GetNativeString(1, sItem, size);

	if (g_ItemsList.FindString(sItem) == -1)
		return -1;
	
	GetNativeStringLength(2, size); size++;

	char[] sKey = new char[size];
	GetNativeString(2, sKey, size);

	float value = -1.0;
	
	if (StrEqual(sKey, "size", false))
		g_ItemSize.GetValue(sItem, value);

	return view_as<any>(value);
}

public int Native_GetItemKeyString(Handle plugin, int numParams)
{
	int size;
	GetNativeStringLength(1, size); size++;

	char[] sItem = new char[size];
	GetNativeString(1, sItem, size);

	if (g_ItemsList.FindString(sItem) == -1)
		return false;
	
	GetNativeStringLength(2, size); size++;

	char[] sKey = new char[size];
	GetNativeString(2, sKey, size);

	if (StrEqual(sKey, "worldmodel", false))
	{
		char sWorldmodel[PLATFORM_MAX_PATH];
		if (!g_ItemWorldmodel.GetString(sItem, sWorldmodel, sizeof(sWorldmodel)))
			return false;

		SetNativeString(3, sWorldmodel, GetNativeCell(4));
		return true;
	}
	else if (StrEqual(sKey, "classes", false))
	{
		char sClasses[2048];
		if (!g_ItemClasses.GetString(sItem, sClasses, sizeof(sClasses)))
			return false;
		
		SetNativeString(3, sClasses, GetNativeCell(4));
		return true;
	}

	return false;
}

public Action Convert(int client, int args)
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/tf2-items/items/");

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

	char sItem[256];
	kv_orig.GetSectionName(sItem, sizeof(sItem));
	TrimString(sItem);

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

	if (strlen(sItem) > 0)
		kv.SetString("name", sItem);

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
	SetEntProp(weapon, Prop_Data, "m_iClip1", g_ItemsData[weapon].mag);
}

public int Native_RefillAmmo(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int weapon = GetNativeCell(2);

	int iAmmoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	
	if (iAmmoType != -1)
		SetEntProp(client, Prop_Data, "m_iAmmo", g_ItemsData[weapon].ammo, _, iAmmoType);
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
char g_BackItem[MAXPLAYERS + 1][256];
void ShowAuthors(int client, const char[] item)
{
	Panel panel = new Panel();
	panel.SetTitle("Authors");

	ArrayList authors;
	g_ItemAuthors.GetValue(item, authors);

	char sData[512];
	FormatEx(sData, sizeof(sData), "%s_data", item);

	StringMap authorsdata;
	g_ItemAuthors.GetValue(sData, authorsdata);
	
	char sAuthor[64]; char sAuthorsData[64];
	for (int i = 0; i < authors.Length; i++)
	{
		authors.GetString(i, sAuthor, sizeof(sAuthor));
		authorsdata.GetString(sAuthor, sAuthorsData, sizeof(sAuthorsData));
		panel.DrawText(sAuthor);
		panel.DrawText(sAuthorsData);
	}

	panel.DrawItem("Back");
	strcopy(g_BackItem[client], 256, item); //hacky fix

	panel.Send(client, MenuAction_Authors, MENU_TIME_FOREVER);
}

public int MenuAction_Authors(Menu menu, MenuAction action, int param1, int param2)
{
	OpenItemMenu(param1, g_BackItem[param1]);
}

public int Native_OpenInfoPanel(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	int size;
	GetNativeStringLength(2, size); size++;

	char[] name = new char[size];
	GetNativeString(2, name, size);
	
	bool back = GetNativeCell(3);

	OpenInfoPanel(client, name, back);
}
bool g_CanBack[MAXPLAYERS + 1];
char g_WeaponInfo[MAXPLAYERS + 1][MAX_NAME_LENGTH];
void OpenInfoPanel(int client, const char[] name, bool back = true)
{
	Panel panel = new Panel();

	char title[256];
	FormatEx(title, sizeof(title), "%s Item Information", name);
	panel.SetTitle(title);

	StringMap attributesdata;
	g_ItemAttributesData.GetValue(name, attributesdata);
	
	char sAttributesList[MAX_ATTRIBUTE_NAME_LENGTH + 12];
	FormatEx(sAttributesList, sizeof(sAttributesList), "%s_list", name);

	ArrayList attributeslist;
	g_ItemAttributesData.GetValue(sAttributesList, attributeslist);
	
	char sAttribute[MAX_ATTRIBUTE_NAME_LENGTH]; StringMap attributedata; char sDisplay[128];
	for (int i = 0; i < attributeslist.Length; i++)
	{
		attributeslist.GetString(i, sAttribute, sizeof(sAttribute));
		FormatEx(sDisplay, sizeof(sDisplay), " - %s", sAttribute);
		panel.DrawText(sDisplay);
		
		attributesdata.GetValue(sAttribute, attributedata);
		
		StringMapSnapshot snap = attributedata.Snapshot();

		for (int x = 0; x < snap.Length; x++)
		{
			int size = snap.KeyBufferSize(x);

			char[] sKey = new char[size];
			snap.GetKey(x, sKey, size);

			float value;
			attributedata.GetValue(sKey, value);

			FormatEx(sDisplay, sizeof(sDisplay), " - %s: %.2f", sKey, value);
			panel.DrawText(sDisplay);
		}

		delete snap;
	}
	
	g_CanBack[client] = back;
	strcopy(g_WeaponInfo[client], MAX_NAME_LENGTH, name);
	
	if (back)
		panel.DrawItem("Back");
	
	panel.DrawItem("Exit");

	panel.Send(client, MenuAction_Info, MENU_TIME_FOREVER);
	delete panel;
}

public int MenuAction_Info(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select && param2 == (g_CanBack[param1] ? 1 : 2))
		OpenItemMenu(param1, g_WeaponInfo[param1]);
}
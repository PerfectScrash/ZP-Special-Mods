/* 
	[ZPSp] Special Class: Xiter 
	
	* Description:
		This Special Class have a f***ing Speed Hack and great damage and use against zombies

	* Cvars:
		- zp_xiter_minplayers 2 		// Min players for start a Xiter gamemode
		- zp_xiter_damage_multi 2.0 	// Damage multi for Xiter's every weapon
		- zp_xiter_weapon_rate 0.05		// Speed of Shoots
*/


#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <cstrike>
#include <zombie_plague_special>
#include <amx_settings_api>

#if ZPS_INC_VERSION < 45
	#assert Zombie Plague Special 4.5 Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

/*-------------------------------------
--> Class Configs
--------------------------------------*/
#define Make_Acess ADMIN_IMMUNITY 	// Flag Acess make
new const sp_name[] = "Xiter"
new const sp_model[] = "vip"
new const sp_hp = 10000
new const sp_speed = 800
new const Float:sp_gravity = 0.2
new const sp_aura_size = 25
new const sp_clip_type = 2 // Unlimited Ammo (0 - Disable | 1 - Unlimited Semi Clip | 2 - Unlimited Clip)
new const sp_allow_glow = 1
new const sp_color_rgb[3] = { 255, 0, 255 }

// Weapon enums
enum _wpn_hand { wpn_index, IniLoad[32], wpn_give[32], Default_V_model[64], Default_P_model[64] }

// Default Xiter Weapons
#define MAX_WEAPONS 4
new const xiter_weapons[MAX_WEAPONS][_wpn_hand] = {
	// Weapon Id |	Wpn Ini load	| Weapon Give item 	|    V Model			| 	P_Model
	{ CSW_XM1014, 	"XM1014",		"weapon_xm1014", 	"models/v_xm1014.mdl", 	"models/p_xm1014.mdl" },
	{ CSW_M3, 		"M3",			"weapon_m3", 		"models/v_m3.mdl", 		"models/p_m3.mdl" },
	{ CSW_SCOUT, 	"SCOUT",		"weapon_scout", 	"models/v_scout.mdl",	"models/p_scout.mdl" },
	{ CSW_DEAGLE, 	"DEAGLE",		"weapon_deagle", 	"models/v_deagle.mdl",	"models/p_deagle.mdl" }
}

/*-------------------------------------
--> Ambience/Round Sound Config
--------------------------------------*/
// Ambience enums
enum _handler { AmbiencePrecache[64], Float:AmbienceDuration }

// Enable Ambience?
const ambience_enable = 1

// Ambience sounds
new const gamemode_ambiences[][_handler] = {	
	// Sounds					// Duration
	{ "sound/zombie_plague/xiter_ambience.mp3", 243.0 }
}

// Round start sounds
new const gamemode_round_start_snd[][] = { 
	"zombie_plague/survivor1.wav" 
}

/*-------------------------------------
--> Gamemode Config
--------------------------------------*/
new const g_chance = 90						// Gamemode chance
#define Start_Mode_Acess ADMIN_IMMUNITY

/*-------------------------------------
--> Variables/Defines
--------------------------------------*/
new g_gameid, g_msg_sync, cvar_minplayers, g_special_id, cvar_damage, cvar_pattack_rate, v_xiter_model[MAX_WEAPONS][64], p_xiter_model[MAX_WEAPONS][64]

// Weapons Offsets
#define NO_RECOIL_WEAPONS_BITSUM (1<<CSW_HEGRENADE|1<<CSW_FLASHBANG|1<<CSW_SMOKEGRENADE|1<<CSW_C4)

// Offsets
const m_pPlayer = 41
const m_flNextPrimaryAttack = 46
const m_flNextSecondaryAttack = 47
const m_flTimeWeaponIdle = 48

#define GetUserXiter(%1) (zp_get_human_special_class(%1) == g_special_id)
#define IsXiterRound() (zp_get_current_mode() == g_gameid)

/*-------------------------------------
--> Plugin registeration.
--------------------------------------*/
public plugin_init() {
	register_plugin("[ZPSp] Special Class: Xiter", "1.1", "[P]erfec[T] [S]cr[@]s[H]")
	
	cvar_minplayers = register_cvar("zp_xiter_minplayers", "2")
	cvar_damage = register_cvar("zp_xiter_damage_multi", "2.0") 
	cvar_pattack_rate = register_cvar("zp_xiter_weapon_rate", "0.05")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")

	// Thanks MasI
	static weapon_name[24], i
	for (i = 1; i <= 30; i++) {
		if (!(NO_RECOIL_WEAPONS_BITSUM & 1 << i) && get_weaponname(i, weapon_name, charsmax(weapon_name))) {
			RegisterHam(Ham_Weapon_PrimaryAttack, weapon_name, "fw_PrimaryAttack_Pre")
			RegisterHam(Ham_Weapon_PrimaryAttack, weapon_name, "fw_PrimaryAttack_Post", 1)
		}
	}
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_PrimaryAttack_Post", 1)

	g_msg_sync = CreateHudSyncObj()
}

/*-------------------------------------
--> Plugin Precache
--------------------------------------*/
public plugin_precache() {
	// Register our game mode
	g_gameid = zpsp_register_gamemode(sp_name, Start_Mode_Acess, g_chance, 0, ZP_DM_NONE)
	g_special_id = zp_register_human_special(sp_name, sp_model, sp_hp, sp_speed, sp_gravity, Make_Acess, sp_clip_type, sp_aura_size, sp_allow_glow, sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2])

	static i
	for(i = 0; i < MAX_WEAPONS; i++) {
		if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", fmt("V_%s XITER", xiter_weapons[i][IniLoad]), v_xiter_model[i], charsmax(v_xiter_model[]))) {
			amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", fmt("V_%s XITER", xiter_weapons[i][IniLoad]), xiter_weapons[i][Default_V_model])
			formatex(v_xiter_model[i], charsmax(v_xiter_model[]), xiter_weapons[i][Default_V_model])
		}
		precache_model(v_xiter_model[i])
		
		if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", fmt("P_%s XITER", xiter_weapons[i][IniLoad]), p_xiter_model[i], charsmax(p_xiter_model[]))) {
			amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", fmt("P_%s XITER", xiter_weapons[i][IniLoad]), xiter_weapons[i][Default_P_model])
			formatex(p_xiter_model[i], charsmax(p_xiter_model[]), xiter_weapons[i][Default_P_model])
		}
		precache_model(p_xiter_model[i])
	}

	
	// Register round start sound
	for(i = 0; i < sizeof gamemode_round_start_snd; i++)
		zp_register_start_gamemode_snd(g_gameid, gamemode_round_start_snd[i])

	// Register ambience sounds
	for (i = 0; i < sizeof gamemode_ambiences; i++)
		zp_register_gamemode_ambience(g_gameid, gamemode_ambiences[i][AmbiencePrecache], gamemode_ambiences[i][AmbienceDuration], ambience_enable)
	
}

/*-------------------------------------
--> Natives
--------------------------------------*/
public plugin_natives() {
	register_native("zp_get_user_xiter", "native_get_user_xiter")
	register_native("zp_make_user_xiter", "native_make_user_xiter")
	register_native("zp_get_xiter_count", "native_get_xiter_count")
	register_native("zp_is_xiter_round", "native_is_xiter_round")
}
public native_get_user_xiter(plugin_id, num_params)
	return GetUserXiter(get_param(1));
	
public native_make_user_xiter(plugin_id, num_params)
	return zp_make_user_special(get_param(1), g_special_id, GET_HUMAN);
	
public native_get_xiter_count(plugin_id, num_params)
	return zp_get_special_count(GET_HUMAN, g_special_id);
	
public native_is_xiter_round(plugin_id, num_params)
	return (IsXiterRound());


/*-------------------------------------
--> Class Functions
--------------------------------------*/
// Xiter Weapon Model
public zp_fw_deploy_weapon(id, wpnid) {
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;

	if(!GetUserXiter(id))
		return PLUGIN_HANDLED;

	static i;
	for(i = 0; i < MAX_WEAPONS; i++) {
		if(wpnid == xiter_weapons[i][wpn_index]) {
			set_pev(id, pev_viewmodel2, v_xiter_model[i])
			set_pev(id, pev_weaponmodel2, p_xiter_model[i])
			break;
		}
	}
	return PLUGIN_HANDLED
}


// XM1014 Damage
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if(!is_user_alive(attacker))
		return HAM_IGNORED

	if(GetUserXiter(attacker))
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_damage))

	return HAM_IGNORED
}


public zp_user_humanized_post(id) {
	if(!GetUserXiter(id)) 
		return;
	
	if(!zp_has_round_started())
		zp_set_custom_game_mod(g_gameid)	// Force Start Xiter Round
	
	static i;
	for(i = 0; i < MAX_WEAPONS; i++)
		zp_give_item(id, xiter_weapons[i][wpn_give], 1);
}
public fw_PrimaryAttack_Pre(ent) {
	static id;
	id = pev(ent,pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED

	if(!GetUserXiter(id))
		return HAM_IGNORED

	// Get new fire rate
	static Float:flRate
	flRate = get_pcvar_float(cvar_pattack_rate)

	// Set new rates
	set_pdata_float(id, m_flNextPrimaryAttack, flRate, 4)
	set_pdata_float(id, m_flNextSecondaryAttack, flRate, 4)
	set_pdata_float(id, m_flTimeWeaponIdle, flRate, 4)

	pev(id, pev_punchangle, Float:{0.0, 0.0, 0.0})

	return HAM_IGNORED
}   
public fw_PrimaryAttack_Post(wpn) {
	static id
	id = get_pdata_cbase(wpn, m_pPlayer, 4)

	if(!is_user_alive(id))
		return HAM_IGNORED

	if(!GetUserXiter(id))
		return HAM_IGNORED
	
	// Get new fire rate
	static Float:flRate
	flRate = get_pcvar_float(cvar_pattack_rate)

	// Set new rates
	set_pdata_float(wpn, m_flNextPrimaryAttack, flRate, 4)
	set_pdata_float(wpn, m_flNextSecondaryAttack, flRate, 4)
	set_pdata_float(wpn, m_flTimeWeaponIdle, flRate, 4)

	set_pev(id, pev_punchangle, Float:{0.0, 0.0, 0.0})

	return HAM_IGNORED
}

/*-------------------------------------
--> Gamemode Functions
--------------------------------------*/
// Player spawn post
public zp_player_spawn_post(id) {
	// Check for current mode
	if(IsXiterRound())
		zp_infect_user(id, 0, 1, 0)
}

public zp_round_started_pre(game) {
	// Check if it is our game mode
	if(game != g_gameid)
		return PLUGIN_CONTINUE
	
	// Check for min players
	if(zp_get_alive_players() < get_pcvar_num(cvar_minplayers))
		return ZP_PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public zp_round_started(game, id) {
	if(game == g_gameid)
		start_xiter_mode()
}

// This function contains the whole code behind this game mode
start_xiter_mode() {
	static id, i, has_xiter
	has_xiter = false
	for (i = 1; i <= MaxClients; i++) {
		if(!is_user_alive(i))
			continue

		if(!GetUserXiter(i)) 
			continue;

		id = i
		has_xiter = true
		break;		
	}

	if(!has_xiter) {
		id = zp_get_random_player()
		zp_make_user_special(id, g_special_id, GET_HUMAN)
	}
	
	static name[32]; get_user_name(id, name, charsmax(name));
	set_hudmessage(sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2], -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync, "%s is a %s", name, sp_name)
		
	// Turn the remaining players into zombies
	for (id = 1; id <= MaxClients; id++) {
		if(!is_user_alive(id))
			continue;
		
		if(GetUserXiter(id) || zp_get_user_zombie(id))
			continue;
		
		zp_infect_user(id, 0, 1, 0) // Turn into a zombie
	}
}
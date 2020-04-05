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

#if ZPS_INC_VERSION < 44
	#assert Zombie Plague Special 4.4 (Beta) Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

new const ZP_CUSTOMIZATION_FILE[] = "zombie_plague_special.ini"

new Array:g_sound_xiter, g_ambience_sounds, Array:g_sound_amb_xiter_dur, Array: g_sound_ambience_xiter

// Default Sounds
new const sound_xiter[][] = { "zombie_plague/survivor1.wav" }
new const ambience_xiter_sound[][] = { "sound/zombie_plague/xiter_ambience.mp3" } 
new const ambience_xiter_dur[][] = { "243" }

new const sp_name[] = "Xiter"
new const sp_model[] = "vip"
new const sp_hp = 10000
new const sp_speed = 800
new const Float:sp_gravity = 0.2
new const sp_aura_size = 25
new const sp_clip_type = 2 // Unlimited Ammo (0 - Disable | 1 - Unlimited Semi Clip | 2 - Unlimited Clip)
new const sp_allow_glow = 1
new const sp_color_r = 255
new const sp_color_g = 0
new const sp_color_b = 255
new acess_flags[2]

// Default XM1014 Models
new const default_v_xm1014[] = "models/v_xm1014.mdl"
new const default_p_xm1014[] = "models/p_xm1014.mdl"

// Variables
new g_gameid, g_msg_sync, cvar_minplayers, g_speciald, cvar_damage, g_maxplayers, cvar_pattack_rate
new v_xm1014_model[64], p_xm1014_model[64]
new const g_chance = 90

// Enable Ambience?
#define AMBIENCE_ENABLE 1

// Ambience sounds task
#define TASK_AMB 3256

// Weapons Offsets
#define NO_RECOIL_WEAPONS_BITSUM (1<<CSW_HEGRENADE|1<<CSW_FLASHBANG|1<<CSW_SMOKEGRENADE|1<<CSW_C4)

// Offsets
const m_pPlayer = 41
const m_flNextPrimaryAttack = 46
const m_flNextSecondaryAttack = 47
const m_flTimeWeaponIdle = 48

public plugin_init()
{
	// Plugin registeration.
	register_plugin("[ZP] Special Class: Xiter","1.0", "[P]erfec[T] [S]cr[@]s[H]")
	
	cvar_minplayers = register_cvar("zp_xiter_minplayers", "2")
	cvar_damage = register_cvar("zp_xiter_damage_multi", "2.0") 
	cvar_pattack_rate = register_cvar("zp_xiter_weapon_rate", "0.05")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_event("CurWeapon","checkModel","be","1=1")

	// Thanks MasI
	new weapon_name[24]
	for (new i = 1; i <= 30; i++) {
		if (!(NO_RECOIL_WEAPONS_BITSUM & 1 << i) && get_weaponname(i, weapon_name, charsmax(weapon_name))) {
			RegisterHam(Ham_Weapon_PrimaryAttack, weapon_name, "fw_PrimaryAttack_Pre")
			RegisterHam(Ham_Weapon_PrimaryAttack, weapon_name, "fw_PrimaryAttack_Post", 1)
		}
	}
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_PrimaryAttack_Post", 1)

	g_msg_sync = CreateHudSyncObj()
	g_maxplayers = get_maxplayers()
}

// Game modes MUST be registered in plugin precache ONLY
public plugin_precache()
{
	// Read the access flag
	new user_access[40], i, buffer[250]
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE XITER", user_access, charsmax(user_access))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE XITER", "a")
		formatex(user_access, charsmax(user_access), "a")
	}
	acess_flags[0] = read_flags(user_access)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "MAKE XITER", user_access, charsmax(user_access))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "MAKE XITER", "a")
		formatex(user_access, charsmax(user_access), "a")
	}
	acess_flags[1] = read_flags(user_access)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_XM1014 XITER", v_xm1014_model, charsmax(v_xm1014_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_XM1014 XITER", default_v_xm1014)
		formatex(v_xm1014_model, charsmax(v_xm1014_model), default_v_xm1014)
	}
	precache_model(v_xm1014_model)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_XM1014 XITER", p_xm1014_model, charsmax(p_xm1014_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_XM1014 XITER", default_p_xm1014)
		formatex(p_xm1014_model, charsmax(p_xm1014_model), default_p_xm1014)
	}
	precache_model(p_xm1014_model)
	
	g_sound_xiter = ArrayCreate(64, 1)
	g_sound_ambience_xiter = ArrayCreate(64, 1)
	g_sound_amb_xiter_dur = ArrayCreate(64, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND XITER", g_sound_xiter)
	
	// Precache the play sounds
	if (ArraySize(g_sound_xiter) == 0) {
		for (i = 0; i < sizeof sound_xiter; i++)
			ArrayPushString(g_sound_xiter, sound_xiter[i])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND XITER", g_sound_xiter)
	}
	
	// Precache sounds
	for (i = 0; i < ArraySize(g_sound_xiter); i++) {
		ArrayGetString(g_sound_xiter, i, buffer, charsmax(buffer))
		precache_ambience(buffer)
	}
	
	// Ambience Sounds
	g_ambience_sounds = AMBIENCE_ENABLE
	if(!amx_load_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "XITER ENABLE", g_ambience_sounds))
		amx_save_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "XITER ENABLE", g_ambience_sounds)
	
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "XITER SOUNDS", g_sound_ambience_xiter)
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "XITER DURATIONS", g_sound_amb_xiter_dur)
	
	
	// Save to external file
	if (ArraySize(g_sound_ambience_xiter) == 0) {
		for (i = 0; i < sizeof ambience_xiter_sound; i++)
			ArrayPushString(g_sound_ambience_xiter, ambience_xiter_sound[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "XITER SOUNDS", g_sound_ambience_xiter)
	}
	
	if (ArraySize(g_sound_amb_xiter_dur) == 0) {
		for (i = 0; i < sizeof ambience_xiter_dur; i++)
			ArrayPushString(g_sound_amb_xiter_dur, ambience_xiter_dur[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "XITER DURATIONS", g_sound_amb_xiter_dur)
	}
	
	// Ambience Sounds
	if (g_ambience_sounds) {
		for (i = 0; i < ArraySize(g_sound_ambience_xiter); i++) {
			ArrayGetString(g_sound_ambience_xiter, i, buffer, charsmax(buffer))
			precache_ambience(buffer)
		}
	}
	
	// Register our game mode
	g_gameid = zpsp_register_gamemode(sp_name, acess_flags[0], g_chance, 0, 0)
	g_speciald = zp_register_human_special(sp_name, sp_model, sp_hp, sp_speed, sp_gravity, acess_flags[1], sp_clip_type, sp_aura_size, sp_allow_glow, sp_color_r, sp_color_g, sp_color_b)
}

public plugin_natives() {
	register_native("zp_get_user_xiter", "native_get_user_xiter", 1)
	register_native("zp_make_user_xiter", "native_make_user_xiter", 1)
	register_native("zp_get_xiter_count", "native_get_xiter_count", 1)
	register_native("zp_is_xiter_round", "native_is_xiter_round", 1)
}

// XM1014 Model
public checkModel(id) {
	if (!is_user_alive(id))
		return PLUGIN_HANDLED;
	
	if (!zp_get_user_zombie(id) && get_user_weapon(id) == CSW_XM1014 && zp_get_human_special_class(id) == g_speciald) {
		set_pev(id, pev_viewmodel2, v_xm1014_model)
		set_pev(id, pev_weaponmodel2, p_xm1014_model)
	}
	return PLUGIN_HANDLED
}

// XM1014 Damage
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if(!is_user_alive(attacker))
		return HAM_IGNORED

	if(zp_get_human_special_class(attacker) == g_speciald)
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_damage))

	return HAM_IGNORED
}

// Player spawn post
public zp_player_spawn_post(id) {
	// Check for current mode
	if(zp_get_current_mode() == g_gameid)
		zp_infect_user(id)
}

public zp_round_started_pre(game) {
	// Check if it is our game mode
	if(game == g_gameid)
	{
		// Check for min players
		if(zp_get_alive_players() < get_pcvar_num(cvar_minplayers))
			return ZP_PLUGIN_HANDLED

		// Start our new mode
		start_xiter_mode()
	}
	return PLUGIN_CONTINUE
}

public zp_round_started(game, id) {
	// Check if it is our game mode
	if(game == g_gameid) {
		// Play the starting sound
		static sound[100]
		ArrayGetString(g_sound_xiter, random_num(0, ArraySize(g_sound_xiter) - 1), sound, charsmax(sound))
		zp_play_sound(0, sound)
		
		// Remove ambience task affects
		remove_task(TASK_AMB)
		
		// Set task to start ambience sounds
		set_task(2.0, "start_ambience_sounds", TASK_AMB)
	}
}

public zp_game_mode_selected(gameid, id) {
	// Check if our game mode was called
	if(gameid == g_gameid)
		start_xiter_mode()
	
	// Make the compiler happy again =)
	return PLUGIN_CONTINUE
}

// This function contains the whole code behind this game mode
start_xiter_mode() {
	new id, i, has_xiter
	has_xiter = false
	for (i = 1; i <= g_maxplayers; i++) {
		if(!is_user_connected(i))
			continue;

		if(zp_get_human_special_class(i) == g_speciald) {
			id = i
			has_xiter = true
		}
	}

	if(!has_xiter) {
		id = zp_get_random_player()
		zp_make_user_special(id, g_speciald, GET_HUMAN)
	}
	
	static name[32]; get_user_name(id, name, 31);
	set_hudmessage(sp_color_r, sp_color_g, sp_color_b, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync, "%s is a %s", name, sp_name)
		
	// Turn the remaining players into zombies
	for (id = 1; id <= g_maxplayers; id++) {
		// Not alive
		if(!is_user_alive(id))
			continue;
			
		// Survivor or already a zombie
		if(zp_get_human_special_class(id) == g_speciald || zp_get_user_zombie(id))
			continue;
			
		// Turn into a zombie
		zp_infect_user(id)
	}
}

public start_ambience_sounds()
{
	if (!g_ambience_sounds)
		return;
	
	// Variables
	static amb_sound[64], sound,  str_dur[20]
	
	// Select our ambience sound
	sound = random_num(0, ArraySize(g_sound_ambience_xiter)-1)

	ArrayGetString(g_sound_ambience_xiter, sound, amb_sound, charsmax(amb_sound))
	ArrayGetString(g_sound_amb_xiter_dur, sound, str_dur, charsmax(str_dur))
	
	zp_play_sound(0, amb_sound)
	
	// Start the ambience sounds
	set_task(str_to_float(str_dur), "start_ambience_sounds", TASK_AMB)
}
public zp_round_ended() {
	remove_task(TASK_AMB)
}

public zp_user_humanized_post(id)
{
	if(zp_get_human_special_class(id) == g_speciald) {
		if(!zp_has_round_started())
			zp_set_custom_game_mod(g_gameid)	// Force Start Xiter Round
		
		fm_give_item(id, "weapon_xm1014")
		fm_give_item(id, "weapon_m3")
		fm_give_item(id, "weapon_scout")
		cs_set_user_bpammo(id, CSW_XM1014, 90)
		cs_set_user_bpammo(id, CSW_M3, 90)
		cs_set_user_bpammo(id, CSW_SCOUT, 90)
	}
}

public native_get_user_xiter(id)
	return (zp_get_human_special_class(id) == g_speciald)
	
public native_make_user_xiter(id)
	return zp_make_user_special(id, g_speciald, 0)
	
public native_get_xiter_count()
	return zp_get_special_count(0, g_speciald)
	
public native_is_xiter_round()
	return (zp_get_current_mode() == g_gameid)
	
// Give an item to a player (from fakemeta_util)
stock fm_give_item(id, const item[])
{
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item))
	if(!pev_valid(ent)) return;
	
	static Float:originF[3]
	pev(id, pev_origin, originF)
	set_pev(ent, pev_origin, originF)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)
	
	static save
	save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, id)
	if(pev(ent, pev_solid) != save)
		return;
	
	engfunc(EngFunc_RemoveEntity, ent)
}

precache_ambience(sound[])
{
	static buffer[150]
	if(equal(sound[strlen(sound)-4], ".mp3")) {
		if(!equal(sound, "sound/", 6) && !file_exists(sound) && !equal(sound, "media/", 6))
			format(buffer, charsmax(buffer), "sound/%s", sound)
		else
			format(buffer, charsmax(buffer), "%s", sound)
		
		precache_generic(buffer)
	}
	else  {
		if(equal(sound, "sound/", 6))
			format(buffer, charsmax(buffer), "%s", sound[6])
		else
			format(buffer, charsmax(buffer), "%s", sound)
		
		
		precache_sound(buffer)
	}
}
public fw_PrimaryAttack_Pre(ent)
{
	new id = pev(ent,pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED

	if(zp_get_human_special_class(id) == g_speciald) {
		// Get new fire rate
		static Float:flRate
		flRate = get_pcvar_float(cvar_pattack_rate)

		// Set new rates
		set_pdata_float(id, m_flNextPrimaryAttack, flRate, 4)
		set_pdata_float(id, m_flNextSecondaryAttack, flRate, 4)
		set_pdata_float(id, m_flTimeWeaponIdle, flRate, 4)

		pev(id, pev_punchangle, Float:{0.0, 0.0, 0.0})
	}

	return HAM_IGNORED
}   
public fw_PrimaryAttack_Post(wpn) {
	static id
	id = get_pdata_cbase(wpn, m_pPlayer, 4)

	if(!is_user_alive(id))
		return HAM_IGNORED

	if(zp_get_human_special_class(id) == g_speciald) {
		// Get new fire rate
		static Float:flRate
		flRate = get_pcvar_float(cvar_pattack_rate)

		// Set new rates
		set_pdata_float(wpn, m_flNextPrimaryAttack, flRate, 4)
		set_pdata_float(wpn, m_flNextSecondaryAttack, flRate, 4)
		set_pdata_float(wpn, m_flTimeWeaponIdle, flRate, 4)

		set_pev(id, pev_punchangle, Float:{0.0, 0.0, 0.0})
	}

	return HAM_IGNORED
}

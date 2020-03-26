/*				
				[ZPSp] Special Class: Chuck Norris

				- Description:
					Nothing is able to stop the invincible Chuck Norris

				- Cvars:
					zp_chuck_norris_minplayers "2" ; Minimun of players for start a Chuck Norris Mod

				- Change log:

					* 1.0: 
						- First Release

					* 1.1:
						- Fixed Ambience Bug
						- Fixed Frozen Bug (Not Frozing in some times)
						- Added More messages
*/

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta_util>
#include <zombie_plague_special>
#include <amx_settings_api>

#if ZPS_INC_VERSION < 43
	#assert Zombie Plague Special 4.3 Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

new const ZP_CUSTOMIZATION_FILE[] = "zombie_plague_special.ini"

new Array:g_sound_chuck_norris, g_ambience_sounds, Array:g_sound_amb_chuck_norris_dur, Array: g_sound_ambience_chuck_norris

// Chuck Norris Vars
new countdown_timer, message_id
#define MAX_CHUCK_MSG 18
new const msg_langs[MAX_CHUCK_MSG][] = { "CHUCK_MSG1", "CHUCK_MSG2", "CHUCK_MSG3", "CHUCK_MSG4", "CHUCK_MSG5", "CHUCK_MSG6", "CHUCK_MSG7", "CHUCK_MSG8",
"CHUCK_MSG9", "CHUCK_MSG10", "CHUCK_MSG11", "CHUCK_MSG12", "CHUCK_MSG13", "CHUCK_MSG14", "CHUCK_MSG15", "CHUCK_MSG16", "CHUCK_MSG17", "CHUCK_MSG18" }

// Default Sounds
new const sound_chuck_norris[][] = { "zombie_plague/survivor1.wav" }
new const ambience_chuck_norris_sound[][] = { "zombie_plague/ambience.wav" } 
new const ambience_chuck_norris_dur[][] = { "17" }

new const sp_name[] = "Chuck Norris"
new const sp_model[] = "vip"
new const sp_hp = 10000
new const sp_speed = 999
new const Float:sp_gravity = 0.2
new const sp_aura_size = 10
new const sp_clip_type = 2 // Unlimited Ammo (0 - Disable | 1 - Unlimited Semi Clip | 2 - Unlimited Clip)
new const sp_allow_glow = 0
new const sp_color_r = 255
new const sp_color_g = 255
new const sp_color_b = 255
new acess_flags[2]

// Default KNIFE Models
new const default_v_knife[] = "models/v_knife.mdl"
new const default_p_knife[] = "models/p_knife.mdl"

// Variables
new g_gameid, g_msg_sync[3], cvar_minplayers, g_speciald, cvar_frost
new v_knife_model[64], p_knife_model[64], g_maxplayers
new const g_chance = 90

// Ambience sounds task
#define TASK_AMB 3256
#define TASK_COUNTDOWN 01313213
#define TASK_PARTICLES 65781
#define TASK_MSG 3123182

public plugin_init()
{
	// Plugin registeration.
	register_plugin("[ZP] Class Chuck Norris","1.1", "[P]erfec[T] [S]cr[@]s[H]")
	register_dictionary("zpsp_class_chucknoris.txt")
	
	cvar_minplayers = register_cvar("zp_chuck_norris_minplayers", "2")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	register_event("CurWeapon","checkModel","be","1=1")
	
	g_msg_sync[0] = CreateHudSyncObj()
	g_msg_sync[1] = CreateHudSyncObj()
	g_msg_sync[2] = CreateHudSyncObj()

	g_maxplayers = get_maxplayers()
	cvar_frost = get_cvar_pointer("zp_frost_dur")
}

// Game modes MUST be registered in plugin precache ONLY
public plugin_precache()
{
	// Read the access flag
	new user_access[40]
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE CHUCK NORRIS", user_access, charsmax(user_access))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE CHUCK NORRIS", "a")
		formatex(user_access, charsmax(user_access), "a")
	}
	acess_flags[0] = read_flags(user_access)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "MAKE CHUCK NORRIS", user_access, charsmax(user_access))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "MAKE CHUCK NORRIS", "a")
		formatex(user_access, charsmax(user_access), "a")
	}
	acess_flags[1] = read_flags(user_access)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_KNIFE CHUCK NORRIS", v_knife_model, charsmax(v_knife_model)))
	{
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_KNIFE CHUCK NORRIS", default_v_knife)
		formatex(v_knife_model, charsmax(v_knife_model), default_v_knife)
	}
	precache_model(v_knife_model)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_KNIFE CHUCK NORRIS", p_knife_model, charsmax(p_knife_model)))
	{
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_KNIFE CHUCK NORRIS", default_p_knife)
		formatex(p_knife_model, charsmax(p_knife_model), default_p_knife)
	}
	precache_model(p_knife_model)
	
	new i
	
	g_sound_chuck_norris = ArrayCreate(64, 1)
	g_sound_ambience_chuck_norris = ArrayCreate(64, 1)
	g_sound_amb_chuck_norris_dur = ArrayCreate(64, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND CHUCK NORRIS", g_sound_chuck_norris)
	
	// Precache the play sounds
	if (ArraySize(g_sound_chuck_norris) == 0) {
		for (i = 0; i < sizeof sound_chuck_norris; i++)
			ArrayPushString(g_sound_chuck_norris, sound_chuck_norris[i])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND CHUCK NORRIS", g_sound_chuck_norris)
	}
	
	// Precache sounds
	new sound[100]
	for (i = 0; i < ArraySize(g_sound_chuck_norris); i++) {
		ArrayGetString(g_sound_chuck_norris, i, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else precache_sound(sound)
	}
	
	// Ambience Sounds
	g_ambience_sounds = 0
	if(!amx_load_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "CHUCK NORRIS ENABLE", g_ambience_sounds))
		amx_save_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "CHUCK NORRIS ENABLE", g_ambience_sounds)
	
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "CHUCK NORRIS SOUNDS", g_sound_ambience_chuck_norris)
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "CHUCK NORRIS DURATIONS", g_sound_amb_chuck_norris_dur)
	
	
	// Save to external file
	if (ArraySize(g_sound_ambience_chuck_norris) == 0) {
		for (i = 0; i < sizeof ambience_chuck_norris_sound; i++)
			ArrayPushString(g_sound_ambience_chuck_norris, ambience_chuck_norris_sound[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "CHUCK NORRIS SOUNDS", g_sound_ambience_chuck_norris)
	}
	
	if (ArraySize(g_sound_amb_chuck_norris_dur) == 0) {
		for (i = 0; i < sizeof ambience_chuck_norris_dur; i++)
			ArrayPushString(g_sound_amb_chuck_norris_dur, ambience_chuck_norris_dur[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "CHUCK NORRIS DURATIONS", g_sound_amb_chuck_norris_dur)
	}
	
	// Ambience Sounds
	static buffer[250]
	if (g_ambience_sounds) {
		for (i = 0; i < ArraySize(g_sound_ambience_chuck_norris); i++) {
			ArrayGetString(g_sound_ambience_chuck_norris, i, buffer, charsmax(buffer))
			
			if (equal(buffer[strlen(buffer)-4], ".mp3")) {
				format(buffer, charsmax(buffer), "sound/%s", buffer)
				precache_generic(buffer)
			}
			else precache_sound(buffer)
		}
	}
	
	// Register our game mode
	#if ZPS_INC_VERSION < 44
	g_gameid = zp_register_game_mode(sp_name, acess_flags[0], g_chance, 0, 0)
	#else
	g_gameid = zpsp_register_gamemode(sp_name, acess_flags[0], g_chance, 0, 0)
	#endif


	g_speciald = zp_register_human_special(sp_name, sp_model, sp_hp, sp_speed, sp_gravity, acess_flags[1], sp_clip_type, sp_aura_size, sp_allow_glow, sp_color_r, sp_color_g, sp_color_b)
}



public plugin_natives() {
	register_native("zp_get_user_chuck_norris", "native_get_user_chuck_norris", 1)
	register_native("zp_make_user_chuck_norris", "native_make_user_chuck_norris", 1)
	register_native("zp_get_chuck_norris_count", "native_get_chuck_norris_count", 1)
	register_native("zp_is_chuck_norris_round", "native_is_chuck_norris_round", 1)
}

public zp_extra_item_selected_pre(id, itemid) {
	if(zp_get_human_special_class(id) == g_speciald)
		return ZP_PLUGIN_SUPERCEDE
	
	return PLUGIN_CONTINUE
}

// Knife Model
public checkModel(id) {
	if (!is_user_alive(id) || zp_get_user_zombie(id))
		return PLUGIN_HANDLED;
	
	if (get_user_weapon(id) == CSW_KNIFE && zp_get_human_special_class(id) == g_speciald)
	{
		set_pev(id, pev_viewmodel2, v_knife_model)
		set_pev(id, pev_weaponmodel2, p_knife_model)
	}
	return PLUGIN_HANDLED
}

// Block damage in Chuck Norris countdown
public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type) {
	if(countdown_timer > 0 && zp_get_current_mode() == g_gameid)
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

// Chuck Norris Damage
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(countdown_timer > 0 && zp_get_current_mode() == g_gameid)
		return HAM_SUPERCEDE;
	
	if(is_user_alive(attacker) && zp_get_human_special_class(attacker) == g_speciald && get_user_weapon(attacker) == CSW_KNIFE)
		ExecuteHamB(Ham_Killed, victim, attacker, 0)
		
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
		start_chuck_norris_mode()
	}
	return PLUGIN_CONTINUE
}

public zp_round_started(game, id)
{
	// Check if it is our game mode
	if(game == g_gameid)
	{
		// Play the starting sound
		static sound[100]
		ArrayGetString(g_sound_chuck_norris, random_num(0, ArraySize(g_sound_chuck_norris) - 1), sound, charsmax(sound))
		#if ZPS_INC_VERSION < 44
		PlaySoundToClients(sound)
		#else
		zp_play_sound(0, sound)
		#endif
		
		// Remove ambience task affects
		remove_task(TASK_AMB)
		
		// Set task to start ambience sounds
		set_task(2.0, "start_ambience_sounds", TASK_AMB)
	}
}

#if ZPS_INC_VERSION < 44
// Plays a sound on clients
PlaySoundToClients(const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(0, "spk ^"%s^"", sound)
}
#endif
public zp_game_mode_selected(gameid, id)
{
	// Check if our game mode was called
	if(gameid == g_gameid)
		start_chuck_norris_mode()

	return PLUGIN_CONTINUE
}

// This function contains the whole code behind this game mode
start_chuck_norris_mode()
{
	new id, i,  has_chuck_norris
	static Float:default_value; 
	default_value = get_pcvar_float(cvar_frost)
	set_pcvar_float(cvar_frost, 999.0)
	has_chuck_norris = false
	for (i = 1; i <= g_maxplayers; i++) {
		if(zp_get_human_special_class(i) == g_speciald) {
			id = i
			has_chuck_norris = true
		}
	}

	set_task(1.0, "countdown", TASK_COUNTDOWN);
	countdown_timer = 20
	message_id = 0

	if(!has_chuck_norris) {
		//id = fnGetRandomAlive(random_num(1, zp_get_alive_players()))
		id = zp_get_random_player()
		zp_make_user_special(id, g_speciald, GET_HUMAN)
	}

	if(countdown_timer) {
		zp_set_user_frozen(id, SET_WITHOUT_IMMUNIT)

		if(!fm_get_user_godmode(id))
			fm_set_user_godmode(id, 1) 
	}
	
	static name[32]; get_user_name(id, name, 31);
	set_hudmessage(sp_color_r, sp_color_g, sp_color_b, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync[0], "%L", LANG_PLAYER, "NOTICE_CHUCK_NORRIS", name)
	
	set_pcvar_float(cvar_frost, default_value)
	
	// Turn the remaining players into zombies
	for (id = 1; id <= g_maxplayers; id++)
	{
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
	sound = random_num(0, ArraySize(g_sound_ambience_chuck_norris)-1)

	ArrayGetString(g_sound_ambience_chuck_norris, sound, amb_sound, charsmax(amb_sound))
	ArrayGetString(g_sound_amb_chuck_norris_dur, sound, str_dur, charsmax(str_dur))
	
	#if ZPS_INC_VERSION < 44
	PlaySoundToClients(amb_sound)
	#else
	zp_play_sound(0, amb_sound)
	#endif
	
	// Start the ambience sounds
	set_task(str_to_float(str_dur), "start_ambience_sounds", TASK_AMB)
}
public zp_round_ended() {
	remove_task(TASK_AMB)
}

public zp_user_humanized_post(id)
{
	if(zp_get_human_special_class(id) == g_speciald) 
	{
		static Float:default_value; 
		default_value = get_pcvar_float(cvar_frost)
		set_pcvar_float(cvar_frost, 999.0)

		if(!zp_has_round_started())
			zp_set_custom_game_mod(g_gameid)

		if(countdown_timer && !zp_get_user_frozen(id)) {
			zp_set_user_frozen(id, SET_WITHOUT_IMMUNIT)

			if(!fm_get_user_godmode(id))
				fm_set_user_godmode(id, 1)
		}
			
		set_task(0.1, "fn_Effect_Particles", id+TASK_PARTICLES, _, _, "b");
		set_pcvar_float(cvar_frost, default_value)
	}
}
public native_get_user_chuck_norris(id)
	return (zp_get_human_special_class(id) == g_speciald)
	
public native_make_user_chuck_norris(id)
	return zp_make_user_special(id, g_speciald, 0)
	
public native_get_chuck_norris_count()
	return zp_get_special_count(0, g_speciald)
	
public native_is_chuck_norris_round()
	return (zp_get_current_mode() == g_gameid)

// -------------------------------------------------------------[Chuck Norris Skills]----------------------------------------------------------
public fn_Effect_Particles(id)
{
	id -= TASK_PARTICLES
	if(!is_user_alive(id) || zp_get_human_special_class(id) != g_speciald) {
		remove_task(id+TASK_PARTICLES)
		return
	}
	
	static Origin[3];
	get_user_origin(id, Origin);
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, Origin);
	write_byte(TE_IMPLOSION);
	write_coord(Origin[0]);
	write_coord(Origin[1]);
	write_coord(Origin[2]);
	write_byte(128);
	write_byte(20);
	write_byte(3);
	message_end()
}

public countdown()
{
	if(zp_get_current_mode() == g_gameid && !zp_has_round_ended()) {
		--countdown_timer;
		
		if(countdown_timer > 0)  {
			set_task(1.0, "countdown", TASK_COUNTDOWN);
			set_hudmessage(179, 0, 0, -1.0, 0.28, 2, 0.02, 1.0, 0.01, 0.1, 10);	
			ShowSyncHudMsg(0, g_msg_sync[1], "%L", LANG_PLAYER, "CHUCK_COUNTDOWN", countdown_timer); //the new way
		}
		else {
			set_task(0.1, "chuck_norris_msg", TASK_MSG)
			remove_task(TASK_COUNTDOWN)

			for(new i = 0; i <= g_maxplayers; i++) {
				if(!is_user_alive(i))
					continue;

				if(zp_get_user_zombie(i))
					continue;

				if(zp_get_human_special_class(i) != g_speciald) 
					continue;

				if(zp_get_user_frozen(i)) 
					zp_set_user_frozen(i, UNSET)

				if(fm_get_user_godmode(i)) 
					fm_set_user_godmode(i, 0)
			}
		}
	}
	else remove_task(TASK_COUNTDOWN)
}

public chuck_norris_msg()
{
	if(zp_get_current_mode() == g_gameid && !zp_has_round_ended())
	{
		set_hudmessage(255, 69, 0, -1.0, 0.6, 1, 6.0, 12.0, 1.0, 1.0)
		ShowSyncHudMsg(0, g_msg_sync[2], "%L", LANG_PLAYER, msg_langs[message_id])
		
		message_id++
		if(message_id >= MAX_CHUCK_MSG) message_id = 0

		set_task(15.0, "chuck_norris_msg", TASK_MSG);
	}
	else remove_task(TASK_MSG)
}

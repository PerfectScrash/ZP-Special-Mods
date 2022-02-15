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

				* 1.2:
					- Fixed Zombie health (Some times zombies have same health as first zombie)
					- Fixed Bug that player sometimes don't turn into plasma when round starts

				* 1.3:
					- Support for ZPSp 4.5
*/

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta_util>
#include <zombie_plague_special>
#include <amx_settings_api>

#if ZPS_INC_VERSION < 45
	#assert Zombie Plague Special 4.5 Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

/*-------------------------------------
--> Class Configs
--------------------------------------*/
#define Make_Acess ADMIN_IMMUNITY 	// Flag Acess make
new const sp_name[] = "Chuck Norris"
new const sp_model[] = "vip"
new const sp_hp = 10000
new const sp_speed = 999
new const Float:sp_gravity = 0.2
new const sp_aura_size = 10
new const sp_clip_type = 2 // Unlimited Ammo (0 - Disable | 1 - Unlimited Semi Clip | 2 - Unlimited Clip)
new const sp_allow_glow = 0
new sp_color_rgb[3] = { 255, 255, 255 }

// Default KNIFE Models
new const default_v_knife[] = "models/v_knife.mdl"
new const default_p_knife[] = "models/p_knife.mdl"

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
	{ "zombie_plague/ambience.wav", 17.0 }
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
new g_gameid, g_msg_sync[3], cvar_minplayers, g_special_id, v_knife_model[64], p_knife_model[64], countdown_timer, message_id

// Message Lang
#define MAX_CHUCK_MSG 18
new const msg_langs[MAX_CHUCK_MSG][] = { "CHUCK_MSG1", "CHUCK_MSG2", "CHUCK_MSG3", "CHUCK_MSG4", "CHUCK_MSG5", "CHUCK_MSG6", "CHUCK_MSG7", "CHUCK_MSG8",
"CHUCK_MSG9", "CHUCK_MSG10", "CHUCK_MSG11", "CHUCK_MSG12", "CHUCK_MSG13", "CHUCK_MSG14", "CHUCK_MSG15", "CHUCK_MSG16", "CHUCK_MSG17", "CHUCK_MSG18" }

// Task defines
#define TASK_COUNTDOWN 01313213
#define TASK_PARTICLES 65781
#define TASK_MSG 3123182

// Class Defines
#define GetUserChuck(%1) (zp_get_human_special_class(%1) == g_special_id)
#define IsChuckRound() (zp_get_current_mode() == g_gameid)

public plugin_init() {
	// Plugin registeration.
	register_plugin("[ZPSp] Special Class: Chuck Norris", "1.3", "[P]erfec[T] [S]cr[@]s[H]")
	register_dictionary("zpsp_class_chucknoris.txt")
	
	cvar_minplayers = register_cvar("zp_chuck_norris_minplayers", "2")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	register_event("CurWeapon","checkModel","be","1=1")
	
	g_msg_sync[0] = CreateHudSyncObj()
	g_msg_sync[1] = CreateHudSyncObj()
	g_msg_sync[2] = CreateHudSyncObj()
}

// Game modes MUST be registered in plugin precache ONLY
public plugin_precache() {	
	g_gameid = zpsp_register_gamemode(sp_name, Start_Mode_Acess, g_chance, 0, 0, .uselang=1, .langkey="CHUCK_NORRIS_NAME")
	g_special_id = zp_register_human_special(sp_name, sp_model, sp_hp, sp_speed, sp_gravity, Make_Acess, sp_clip_type, sp_aura_size, sp_allow_glow, sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2])
	amx_save_setting_int(ZP_SPECIAL_CLASSES_FILE, fmt("H:%s", sp_name), "NAME BY LANG", 1)
	amx_save_setting_string(ZP_SPECIAL_CLASSES_FILE, fmt("H:%s", sp_name), "LANG KEY", "CHUCK_NORRIS_NAME")

	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_KNIFE CHUCK NORRIS", v_knife_model, charsmax(v_knife_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_KNIFE CHUCK NORRIS", default_v_knife)
		formatex(v_knife_model, charsmax(v_knife_model), default_v_knife)
	}
	precache_model(v_knife_model)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_KNIFE CHUCK NORRIS", p_knife_model, charsmax(p_knife_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_KNIFE CHUCK NORRIS", default_p_knife)
		formatex(p_knife_model, charsmax(p_knife_model), default_p_knife)
	}
	precache_model(p_knife_model)
	
	static i
	// Register round start sound
	for(i = 0; i < sizeof gamemode_round_start_snd; i++)
		zp_register_start_gamemode_snd(g_gameid, gamemode_round_start_snd[i])

	// Register ambience sounds
	for (i = 0; i < sizeof gamemode_ambiences; i++)
		zp_register_gamemode_ambience(g_gameid, gamemode_ambiences[i][AmbiencePrecache], gamemode_ambiences[i][AmbienceDuration], ambience_enable)
}



public plugin_natives() {
	register_native("zp_get_user_chuck_norris", "native_get_user_chuck_norris")
	register_native("zp_make_user_chuck_norris", "native_make_user_chuck_norris")
	register_native("zp_get_chuck_norris_count", "native_get_chuck_norris_count")
	register_native("zp_is_chuck_norris_round", "native_is_chuck_norris_round")
}

public native_get_user_chuck_norris(plugin_id, num_params)
	return GetUserChuck(get_param(1));
	
public native_make_user_chuck_norris(plugin_id, num_params)
	return zp_make_user_special(get_param(1), g_special_id, GET_HUMAN);
	
public native_get_chuck_norris_count(plugin_id, num_params)
	return zp_get_special_count(GET_HUMAN, g_special_id);
	
public native_is_chuck_norris_round(plugin_id, num_params)
	return (IsChuckRound());


/*-------------------------------------
--> Gamemode functions
--------------------------------------*/
public zp_player_spawn_post(id) {
	if(IsChuckRound())
		zp_infect_user(id)
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
	// Check if it is our game mode
	if(game == g_gameid)
		start_chuck_norris_mode()
}

// This function contains the whole code behind this game mode
start_chuck_norris_mode() {
	static id, i, has_chuck_norris
	has_chuck_norris = false
	id = 0
	for (i = 1; i <= MaxClients; i++) {
		if(!is_user_alive(i))
			continue;

		if(GetUserChuck(i)) {
			id = i
			has_chuck_norris = true
		}
	}

	set_task(1.0, "countdown", TASK_COUNTDOWN);
	countdown_timer = 20
	message_id = 0

	if(!has_chuck_norris) {
		id = zp_get_random_player()
		zp_make_user_special(id, g_special_id, GET_HUMAN)
	}

	if(countdown_timer) {
		zp_set_user_frozen(id, SET_WITHOUT_IMMUNIT, float(countdown_timer))

		if(!fm_get_user_godmode(id))
			fm_set_user_godmode(id, 1) 
	}
	
	static name[32]; get_user_name(id, name, charsmax(name));
	set_hudmessage(sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2], -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync[0], "%L", LANG_PLAYER, "NOTICE_CHUCK_NORRIS", name)
	
	// Turn the remaining players into zombies
	for (id = 1; id <= MaxClients; id++) {
		// Not alive
		if(!is_user_alive(id))
			continue;
			
		if(GetUserChuck(id) || zp_get_user_zombie(id))
			continue;
			
		zp_infect_user(id, 0, 1, 0)
	}
}

/*-------------------------------------
--> Class Functions
--------------------------------------*/
public zp_extra_item_selected_pre(id, itemid) {
	if(GetUserChuck(id))
		return ZP_PLUGIN_SUPERCEDE
	
	return PLUGIN_CONTINUE
}

// Knife Model
public checkModel(id) {
	if (!is_user_alive(id))
		return PLUGIN_HANDLED
	
	if(zp_get_user_zombie(id) || !GetUserChuck(id))
		return PLUGIN_HANDLED;
	
	if(get_user_weapon(id) == CSW_KNIFE) {
		set_pev(id, pev_viewmodel2, v_knife_model)
		set_pev(id, pev_weaponmodel2, p_knife_model)
	}
	return PLUGIN_HANDLED
}

// Block damage in Chuck Norris countdown
public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type) {
	if(countdown_timer > 0 && IsChuckRound())
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

// Chuck Norris Damage
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if(!is_user_alive(attacker))
		return HAM_IGNORED

	if(countdown_timer > 0 && IsChuckRound())
		return HAM_SUPERCEDE;
	
	if(GetUserChuck(attacker) && get_user_weapon(attacker) == CSW_KNIFE)
		ExecuteHamB(Ham_Killed, victim, attacker, 0)
		
	return HAM_IGNORED
}

public zp_user_humanized_post(id) {
	if(!GetUserChuck(id)) 
		return;
	
	if(!zp_has_round_started())
		zp_set_custom_game_mod(g_gameid)

	if(countdown_timer && !zp_get_user_frozen(id)) {
		zp_set_user_frozen(id, SET_WITHOUT_IMMUNIT, float(countdown_timer))

		if(!fm_get_user_godmode(id))
			fm_set_user_godmode(id, 1)
	}
		
	set_task(0.1, "fn_Effect_Particles", id+TASK_PARTICLES, _, _, "b");
}


public fn_Effect_Particles(id) {
	id -= TASK_PARTICLES
	if(!is_user_alive(id) || !GetUserChuck(id)) {
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

public countdown() {
	if(IsChuckRound() && !zp_has_round_ended()) {
		--countdown_timer;
		
		if(countdown_timer > 0)  {
			set_task(1.0, "countdown", TASK_COUNTDOWN);
			set_hudmessage(179, 0, 0, -1.0, 0.28, 2, 0.02, 1.0, 0.01, 0.1, 10);	
			ShowSyncHudMsg(0, g_msg_sync[1], "%L", LANG_PLAYER, "CHUCK_COUNTDOWN", countdown_timer); //the new way
		}
		else {
			set_task(0.1, "chuck_norris_msg", TASK_MSG)
			remove_task(TASK_COUNTDOWN)
			
			static i;
			for(i = 0; i <= MaxClients; i++) {
				if(!is_user_alive(i))
					continue;

				if(zp_get_user_zombie(i) || !GetUserChuck(i))
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

public chuck_norris_msg() {
	if(!IsChuckRound() || zp_has_round_ended()) {
		remove_task(TASK_MSG)
		return;
	}

	set_hudmessage(255, 69, 0, -1.0, 0.6, 1, 6.0, 12.0, 1.0, 1.0)
	ShowSyncHudMsg(0, g_msg_sync[2], "%L", LANG_PLAYER, msg_langs[message_id])
	
	message_id++
	if(message_id >= MAX_CHUCK_MSG) message_id = 0

	set_task(15.0, "chuck_norris_msg", TASK_MSG);
}

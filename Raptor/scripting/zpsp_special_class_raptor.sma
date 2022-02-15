/*
		[ZPSp] Special Class: Raptor

		* Description:
			Can run very faster for a few seconds

		* Cvars:
			zp_raptor_minplayers "2" - Min Players for start a mod
			zp_raptor_damage "500"	- Knife Damage
			zp_raptor_speed_skill "1500.0"	- Raptor Skill Speed
			zp_raptor_skill_cooldown "10.0" - Raptor Skill Cooldown
			zp_raptor_skill_time "6.0"	- Raptor Skill Time
		
		* Change log:
			* 1.0: 
				- First Release

			* 1.1:
				- Fixed Ambience
				- Otimized Code
*/
#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_plague_special>
#include <amx_settings_api>


#if ZPS_INC_VERSION < 45
	#assert Zombie Plague Special 4.5 Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

/*-------------------------------------
--> Class Configs
--------------------------------------*/
#define Make_Acess ADMIN_IMMUNITY 	// Flag Acess make

new const sp_name[] = "Raptor"
new const sp_model[] = "zombie_source"
new const sp_knifemodel[] = "models/zombie_plague/v_knife_zombie.mdl"
new const sp_painsound[] = "zombie_plague/nemesis_pain1.wav"
new const sp_hp = 30000
new const sp_speed = 350
new const Float:sp_gravity = 0.5
new const sp_aura_size = 20
new const Float:sp_knockback = 0.25
new const sp_allow_glow = 1
new sp_color_rgb[3] = { 0, 100, 255 }

new const sp_death_sounds[][] = {
	"zombie_plague/zombie_die1.wav", 
	"zombie_plague/zombie_die2.wav", 
	"zombie_plague/zombie_die3.wav", 
	"zombie_plague/zombie_die4.wav", 
	"zombie_plague/zombie_die5.wav"
}
new const def_sound_raptor_sprint[] = "zombie_plague/raptor_sprint.wav" //sprint sound

/*-------------------------------------
--> Gamemode Config
--------------------------------------*/
new const g_chance = 90						// Gamemode chance
#define Start_Mode_Acess ADMIN_IMMUNITY

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
	"zombie_plague/nemesis1.wav"
}

/*-------------------------------------
--> Variables/Defines
--------------------------------------*/
new g_gameid, g_msg_sync[2], cvar_minplayers, cvar_raptor_damage, g_special_id, raptor_cooldown_time[33], g_abil_one_used[33]
new gRaptorTrail, cvar_raptor_power[3], sound_raptor_sprint[64]

#define TASK_ENABLE_SKILL 1231231
#define TASK_SKILL_COUNTDOWN 312312
#define TASK_REMOVE_SKILL 154332

#define GetUserRaptor(%1) (zp_get_zombie_special_class(%1) == g_special_id) 
#define IsRaptorMode() (zp_get_current_mode() == g_gameid)

/*-------------------------------------
--> Plugin registeration
--------------------------------------*/
public plugin_init() {
	register_plugin("[ZPSp] Special Class: Raptor", "1.1", "[P]erfec[T] [S]cr[@]s[H]")
	register_dictionary("zpsp_raptor.txt")
	
	cvar_minplayers = register_cvar("zp_raptor_minplayers", "2")
	cvar_raptor_damage = register_cvar("zp_raptor_damage", "500")
	cvar_raptor_power[0] = register_cvar("zp_raptor_speed_skill", "1500.0")
	cvar_raptor_power[1] = register_cvar("zp_raptor_skill_cooldown", "10.0")
	cvar_raptor_power[2] = register_cvar("zp_raptor_skill_time", "6.0")

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_forward(FM_EmitSound, "fw_EmitSound")
	g_msg_sync[0] = CreateHudSyncObj()
	g_msg_sync[1] = CreateHudSyncObj()
}

/*-------------------------------------
--> Plugin Precache
--------------------------------------*/
public plugin_precache() {
	g_gameid = zpsp_register_gamemode(sp_name, Start_Mode_Acess, g_chance, 0, ZP_DM_NONE, .uselang=1, .langkey="RAPTOR_CLASSNAME")
	g_special_id = zp_register_zombie_special(sp_name, sp_model, sp_knifemodel, sp_painsound, sp_hp, sp_speed, sp_gravity, Make_Acess, sp_knockback, sp_aura_size, sp_allow_glow, sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2])
	
	// Set lang configuration
	amx_save_setting_int(ZP_SPECIAL_CLASSES_FILE, fmt("Z:%s", sp_name), "NAME BY LANG", 1)
	amx_save_setting_string(ZP_SPECIAL_CLASSES_FILE, fmt("Z:%s", sp_name), "LANG KEY", "RAPTOR_CLASSNAME")

	if(!amx_load_setting_string(ZP_SPECIAL_CLASSES_FILE, fmt("Z:%s", sp_name), "RAPTOR SPRINT SOUND", sound_raptor_sprint, charsmax(sound_raptor_sprint))) {
		amx_save_setting_string(ZP_SPECIAL_CLASSES_FILE, fmt("Z:%s", sp_name), "RAPTOR SPRINT SOUND", def_sound_raptor_sprint)
		formatex(sound_raptor_sprint, charsmax(sound_raptor_sprint), def_sound_raptor_sprint)
	}
	precache_model(sound_raptor_sprint)
	gRaptorTrail = precache_model("sprites/smoke.spr")

	static i
	// Register round start sound
	for(i = 0; i < sizeof gamemode_round_start_snd; i++)
		zp_register_start_gamemode_snd(g_gameid, gamemode_round_start_snd[i])

	// Register ambience sounds
	for (i = 0; i < sizeof gamemode_ambiences; i++)
		zp_register_gamemode_ambience(g_gameid, gamemode_ambiences[i][AmbiencePrecache], gamemode_ambiences[i][AmbienceDuration], ambience_enable)

	// Register Class Death sound
	for (i = 0; i < sizeof sp_death_sounds; i++)
		zp_register_zmspecial_deathsnd(g_special_id, sp_death_sounds[i])
}

/*-------------------------------------
--> Natives
--------------------------------------*/
public plugin_natives() {
	register_native("zp_get_user_raptor", "native_get_user_raptor")
	register_native("zp_make_user_raptor", "native_make_user_raptor")
	register_native("zp_get_raptor_count", "native_get_raptor_count")
	register_native("zp_is_raptor_round", "native_is_raptor_round")
}

// Native: zp_get_user_raptor(id)
public native_get_user_raptor(plugin_id, num_params) 
	return GetUserRaptor(get_param(1));

// Native: zp_make_user_raptor(id)
public native_make_user_raptor(plugin_id, num_params) 
	return (zp_make_user_special(get_param(1), g_special_id, GET_ZOMBIE));

// Native: zp_get_raptor_count()
public native_get_raptor_count(plugin_id, num_params)
	return zp_get_special_count(GET_ZOMBIE, g_special_id);

// Native: zp_is_raptor_round()
public native_is_raptor_round(plugin_id, num_params)
	return IsRaptorMode();

/*-------------------------------------
--> Gamemode Functions
--------------------------------------*/
// Player spawn post
public zp_player_spawn_post(id) {
	
	reset_raptor_vars(id)

	if(IsRaptorMode() && zp_get_user_zombie(id)) // Check for current mode
		zp_disinfect_user(id)
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

public zp_round_started(gameid) {
	if(gameid == g_gameid) // Check if it is our game mode
		start_raptor_mode()
}

// This function contains the whole code behind this game mode
start_raptor_mode() {
	static id, i, has_raptor
	has_raptor = false
	for (i = 1; i <= MaxClients; i++) {
		if(!is_user_alive(i))
			continue
	
		if(!GetUserRaptor(i))
			continue
		
		id = i	// Get Raptor Index
		has_raptor = true
		break;
	}

	if(!has_raptor) {
		id = zp_get_random_player()
		zp_make_user_special(id, g_special_id, GET_ZOMBIE)
	}
	
	static name[32]; get_user_name(id, name, charsmax(name));
	set_hudmessage(sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2], -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync[0], "%L", LANG_PLAYER, "ARE_RAPTOR", name, sp_name)
	ScreenFade(0, 5, sp_color_rgb, 255)
}


/*-------------------------------------
--> Class Functions
--------------------------------------*/
// Attack Damage
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if(!is_user_connected(victim) || !is_user_connected(attacker))
		return HAM_IGNORED
	
	if(inflictor == attacker && GetUserRaptor(attacker))
		SetHamParamFloat(4, get_pcvar_float(cvar_raptor_damage))
		
	return HAM_IGNORED
}

public zp_user_infected_post(id) {
	if(!GetUserRaptor(id))
		return;

	reset_raptor_vars(id);

	if(!zp_has_round_started())
		zp_set_custom_game_mod(g_gameid)
	
	client_print_color(id, print_team_default, "%L %L", id, "CLASS_RAPTOR_PREFIX", id, "CLASS_RAPTOR_INFO");
		
	if(is_user_bot(id)) {
		remove_task(id)
		set_task(random_float(5.0, 15.0), "use_cmd", id, _, _, "b") // Raptor Skills Bot Suport
	}
}

public zp_user_humanized_post(id) reset_raptor_vars(id);
public client_disconnected(id) reset_raptor_vars(id);

public reset_raptor_vars(id) {
	remove_task(id+TASK_ENABLE_SKILL)
	remove_task(id+TASK_REMOVE_SKILL)
	g_abil_one_used[id] = false	
	raptor_cooldown_time[id] = get_pcvar_num(cvar_raptor_power[1])
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)  // Emit Sound Forward
{
	if(!is_user_alive(id))
		return FMRES_IGNORED;

	if(equal(sample, "common/wpn_denyselect.wav") && (pev(id, pev_button) & IN_USE) && GetUserRaptor(id))
		use_cmd(id)

	return FMRES_IGNORED;
}

public use_cmd(id) {
	if(!is_user_alive(id))
		return;

	if(!GetUserRaptor(id) || g_abil_one_used[id])
		return;

	client_cmd(id, "cl_forwardspeed 9999")
	client_cmd(id, "cl_backspeed 9999")
	client_cmd(id, "cl_sidespeed 9999")
	server_cmd("sv_maxspeed 9999")
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(id)
	write_short(gRaptorTrail)
	write_byte(2)
	write_byte(10)
	write_byte(sp_color_rgb[0])
	write_byte(sp_color_rgb[1])
	write_byte(sp_color_rgb[2])
	write_byte(220)
	message_end()
	
	g_abil_one_used[id] = true
	zp_set_user_maxspeed(id, get_pcvar_float(cvar_raptor_power[0]))
	emit_sound(id, CHAN_STREAM, sound_raptor_sprint, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	remove_task(id+TASK_REMOVE_SKILL)
	set_task(get_pcvar_float(cvar_raptor_power[2]),"set_normal_speed",id+TASK_REMOVE_SKILL)
	
	raptor_cooldown_time[id] = get_pcvar_num(cvar_raptor_power[1])
	set_task(1.0, "raptor_countdown", id+TASK_SKILL_COUNTDOWN, _, _, "a",raptor_cooldown_time[id])
}

public set_normal_speed(id) {
	id -= TASK_REMOVE_SKILL
	
	if(!is_user_alive(id))
		return;

	if(GetUserRaptor(id)) {
		zp_reset_user_maxspeed(id)
		remove_task(id+TASK_ENABLE_SKILL)
		set_task(get_pcvar_float(cvar_raptor_power[1]), "allow_power_again", id+TASK_ENABLE_SKILL)
	}
}

public raptor_countdown(id) {
	id -= TASK_SKILL_COUNTDOWN

	if(!is_user_alive(id)) {
		remove_task(id+TASK_SKILL_COUNTDOWN)
		return;
	}

	if(zp_has_round_ended() || !GetUserRaptor(id)) {
		remove_task(id+TASK_SKILL_COUNTDOWN)
		return;
	}

	raptor_cooldown_time[id]--
	set_hudmessage(0, 100, 255, -1.0, 0.6, 0, 1.0, 1.1, 0.0, 0.0, -1)
	ShowSyncHudMsg(id, g_msg_sync[1], "%L", id, "SKILL_RAPTOR_COOLDOWN", raptor_cooldown_time[id])
}

public allow_power_again(id) {
	id -= TASK_ENABLE_SKILL
	if(GetUserRaptor(id)) {
		g_abil_one_used[id] = false
		client_print_color(id, print_team_default, "%L %L", id, "CLASS_RAPTOR_PREFIX", id, "CLASS_RAPTOR_SKILL_READY");
	}
}

/*-------------------------------------
--> Stocks
--------------------------------------*/
stock ScreenFade(id, Timer, Colors[3], Alpha) {
	if(!is_user_connected(id) && id)
		return;

	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, get_user_msgid("ScreenFade"), _, id);
	write_short((1<<12) * Timer)
	write_short(1<<12)
	write_short(0)
	write_byte(Colors[0])
	write_byte(Colors[1])
	write_byte(Colors[2])
	write_byte(Alpha)
	message_end()
} 


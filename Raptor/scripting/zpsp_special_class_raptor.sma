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

#if ZPS_INC_VERSION < 43
	#assert Zombie Plague Special 4.3 Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

new const ZP_CUSTOMIZATION_FILE[] = "zombie_plague_special.ini"

new Array:g_sound_raptor, g_ambience_sounds, Array:g_sound_amb_raptor_dur, Array: g_sound_ambience_raptor

// Default Sounds
new const sound_raptor[][] = { "zombie_plague/nemesis1.wav" }
new const ambience_raptor_sound[][] = { "zombie_plague/ambience.wav" } 
new const ambience_raptor_dur[][] = { "17" }

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
new const sp_color_r =  0
new const sp_color_g = 100
new const sp_color_b = 255
new acess_flags[2]

// Variables
new g_gameid, g_msg_sync[2], cvar_minplayers, cvar_raptor_damage, g_speciald
new const g_chance = 50

// Raptor Power Vars
new raptor_cooldown_time[33], g_abil_one_used[33], gRaptorTrail, cvar_raptor_power[3], g_maxplayers
new const sound_raptor_sprint[] = "zombie_plague/raptor_sprint.wav" //sprint sound

// Ambience sounds task
#define TASK_AMB 3256
#define TASK_ENABLE_SKILL 1231231
#define TASK_SKILL_COUNTDOWN 312312
#define TASK_REMOVE_SKILL 154332

// Enable Ambience?
#define AMBIENCE_ENABLE 0

public plugin_init()
{
	// Plugin registeration.
	register_plugin("[ZP] Class Raptor","1.1", "[P]erfec[T] [S]cr[@]s[H]")
	
	cvar_minplayers = register_cvar("zp_raptor_minplayers", "2")
	cvar_raptor_damage = register_cvar("zp_raptor_damage", "500")
	cvar_raptor_power[0] = register_cvar("zp_raptor_speed_skill", "1500.0")
	cvar_raptor_power[1] = register_cvar("zp_raptor_skill_cooldown", "10.0")
	cvar_raptor_power[2] = register_cvar("zp_raptor_skill_time", "6.0")

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_forward(FM_EmitSound, "fw_EmitSound")
	g_msg_sync[0] = CreateHudSyncObj()
	g_msg_sync[1] = CreateHudSyncObj()
	g_maxplayers = get_maxplayers()
}


// Game modes MUST be registered in plugin precache ONLY
public plugin_precache()
{
	// Read the access flag
	static user_access[40], i
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE RAPTOR", user_access, charsmax(user_access))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE RAPTOR", "a")
		formatex(user_access, charsmax(user_access), "a")
	}
	acess_flags[0] = read_flags(user_access)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "MAKE RAPTOR", user_access, charsmax(user_access))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "MAKE RAPTOR", "a")
		formatex(user_access, charsmax(user_access), "a")
	}	
	acess_flags[1] = read_flags(user_access)

	g_sound_raptor = ArrayCreate(64, 1)
	g_sound_ambience_raptor = ArrayCreate(64, 1)
	g_sound_amb_raptor_dur = ArrayCreate(64, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND RAPTOR", g_sound_raptor)
	
	// Precache the play sounds
	if (ArraySize(g_sound_raptor) == 0) {
		for (i = 0; i < sizeof sound_raptor; i++)
			ArrayPushString(g_sound_raptor, sound_raptor[i])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND RAPTOR", g_sound_raptor)
	}
	
	// Precache sounds
	static sound[100]
	for (i = 0; i < ArraySize(g_sound_raptor); i++) {
		ArrayGetString(g_sound_raptor, i, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else precache_sound(sound)
	}
	
	// Ambience Sounds
	g_ambience_sounds = AMBIENCE_ENABLE
	if(!amx_load_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "RAPTOR ENABLE", g_ambience_sounds))
		amx_save_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "RAPTOR ENABLE", g_ambience_sounds)
	
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "RAPTOR SOUNDS", g_sound_ambience_raptor)
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "RAPTOR DURATIONS", g_sound_amb_raptor_dur)
	
	
	// Save to external file
	if (ArraySize(g_sound_ambience_raptor) == 0) {
		for (i = 0; i < sizeof ambience_raptor_sound; i++)
			ArrayPushString(g_sound_ambience_raptor, ambience_raptor_sound[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "RAPTOR SOUNDS", g_sound_ambience_raptor)
	}
	
	if (ArraySize(g_sound_amb_raptor_dur) == 0) {
		for (i = 0; i < sizeof ambience_raptor_dur; i++)
			ArrayPushString(g_sound_amb_raptor_dur, ambience_raptor_dur[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "RAPTOR DURATIONS", g_sound_amb_raptor_dur)
	}
	
	// Ambience Sounds
	static buffer[250]
	if (g_ambience_sounds) {
		for (i = 0; i < ArraySize(g_sound_ambience_raptor); i++) {
			ArrayGetString(g_sound_ambience_raptor, i, buffer, charsmax(buffer))
			
			if (equal(buffer[strlen(buffer)-4], ".mp3")) {
				format(buffer, charsmax(buffer), "sound/%s", buffer)
				precache_generic(buffer)
			}
			else precache_sound(buffer)
		}
	}
	
	precache_sound(sound_raptor_sprint)
	gRaptorTrail = precache_model("sprites/smoke.spr")
	
	// Register our game mode
	#if ZPS_INC_VERSION < 44
	g_gameid = zp_register_game_mode(sp_name, acess_flags[0], g_chance, 0, 0)
	#else
	g_gameid = zpsp_register_gamemode(sp_name, acess_flags[0], g_chance, 0, 0)
	#endif
	g_speciald = zp_register_zombie_special(sp_name, sp_model, sp_knifemodel, sp_painsound, sp_hp, sp_speed, sp_gravity, acess_flags[1], sp_knockback, sp_aura_size, sp_allow_glow, sp_color_r, sp_color_g, sp_color_b)
}

public plugin_natives()
{
	register_native("zp_get_user_raptor", "native_get_user_raptor", 1)
	register_native("zp_make_user_raptor", "native_make_user_raptor", 1)
	register_native("zp_get_raptor_count", "native_get_raptor_count", 1)
	register_native("zp_is_raptor_round", "native_is_raptor_round", 1)
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(!is_user_alive(victim) || !is_user_alive(attacker))
		return HAM_IGNORED

	if(zp_get_zombie_special_class(attacker) == g_speciald)
		SetHamParamFloat(4, get_pcvar_float(cvar_raptor_damage))

	return HAM_IGNORED
}

// Player spawn post
public zp_player_spawn_post(id)
{
	// Check for current mode
	if(zp_get_current_mode() == g_gameid)
		zp_disinfect_user(id)
}

public zp_round_started_pre(game)
{
	// Check if it is our game mode
	if(game == g_gameid)
	{
		// Check for min players
		if(zp_get_alive_players() < get_pcvar_num(cvar_minplayers))
			return ZP_PLUGIN_HANDLED

		// Start our new mode
		start_raptor_mode()
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
		ArrayGetString(g_sound_raptor, random_num(0, ArraySize(g_sound_raptor) - 1), sound, charsmax(sound))

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
		start_raptor_mode()
	
	// Make the compiler happy again =)
	return PLUGIN_CONTINUE
}

// This function contains the whole code behind this game mode
start_raptor_mode()
{
	new id, i,  has_raptor
	has_raptor = false
	for (i = 1; i <= g_maxplayers; i++) {
		if(!is_user_alive(i))
			continue;

		if(zp_get_zombie_special_class(i) == g_speciald) {
			id = i
			has_raptor = true
		}
	}

	if(!has_raptor) {
		id = zp_get_random_player()
		zp_make_user_special(id, g_speciald, GET_ZOMBIE)
	}
	
	static name[32]; get_user_name(id, name, charsmax(name));
	set_hudmessage(sp_color_r, sp_color_g, sp_color_b, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync[0], "%s is an %s", name, sp_name)
		
	// Turn the remaining players into zombies
	for (id = 1; id <= g_maxplayers; id++)
	{
		// Not alive
		if(!is_user_alive(id))
			continue;
			
		ScreenFade(id, 5, sp_color_r, sp_color_g, sp_color_b, 255)
	}
}

public start_ambience_sounds()
{
	if (!g_ambience_sounds)
		return;
	
	// Variables
	static amb_sound[64], sound,  str_dur[20]
	
	// Select our ambience sound
	sound = random_num(0, ArraySize(g_sound_ambience_raptor)-1)

	ArrayGetString(g_sound_ambience_raptor, sound, amb_sound, charsmax(amb_sound))
	ArrayGetString(g_sound_amb_raptor_dur, sound, str_dur, charsmax(str_dur))
	
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

public zp_user_infected_post(id)
{
	remove_task(id+TASK_REMOVE_SKILL)
	remove_task(id+TASK_ENABLE_SKILL)
	g_abil_one_used[id] = false	
	raptor_cooldown_time[id] = get_pcvar_num(cvar_raptor_power[1])
	
	if(zp_get_zombie_special_class(id) == g_speciald) 
	{
		if(!zp_has_round_started())
			zp_set_custom_game_mod(g_gameid)
		
		#if ZPS_INC_VERSION < 44
		zp_colored_print(id, "!g[ZP]!t You are a Raptor !y||!t Press !g[E]!t To Use Sprint !y(When available)")
		#else
		zp_colored_print(id, 0, "!g[ZP]!t You are a Raptor !y||!t Press !g[E]!t To Use Sprint !y(When available)")
		#endif
			
		if(is_user_bot(id)) {
			remove_task(id)
			set_task(random_float(5.0, 15.0), "use_cmd", id, _, _, "b") // Raptor Skills Bot Suport
		}
	}
}

public zp_user_humanized_post(id) {
	remove_task(id+TASK_ENABLE_SKILL)
	remove_task(id+TASK_REMOVE_SKILL)
	g_abil_one_used[id] = false	
	raptor_cooldown_time[id] = get_pcvar_num(cvar_raptor_power[1])
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)  // Emit Sound Forward
{
	if(!is_user_alive(id))
		return FMRES_IGNORED;

	if(equal(sample, "common/wpn_denyselect.wav") && (pev(id, pev_button) & IN_USE) && zp_get_zombie_special_class(id) == g_speciald)
		use_cmd(id)

	return FMRES_IGNORED;
}

public use_cmd(id) {
	if(!is_user_alive(id))
		return;

	if(zp_get_zombie_special_class(id) == g_speciald && !g_abil_one_used[id])
	{	
		client_cmd(id,"cl_forwardspeed 9999")
		client_cmd(id,"cl_backspeed 9999")
		client_cmd(id,"cl_sidespeed 9999")
		server_cmd("sv_maxspeed 9999")
		
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW)
		write_short(id)
		write_short(gRaptorTrail)
		write_byte(2)
		write_byte(10)
		write_byte(sp_color_r)
		write_byte(sp_color_g)
		write_byte(sp_color_b)
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
}

public set_normal_speed(id)
{
	id -= TASK_REMOVE_SKILL
	
	if(!is_user_alive(id))
		return;

	if(zp_get_zombie_special_class(id) == g_speciald) {
		zp_reset_user_maxspeed(id)
		remove_task(id+TASK_ENABLE_SKILL)
		set_task(get_pcvar_float(cvar_raptor_power[1]),"allow_power_again",id+TASK_ENABLE_SKILL)
	}
}

public raptor_countdown(id)
{
	id -= TASK_SKILL_COUNTDOWN

	if(!is_user_alive(id)) {
		remove_task(id+TASK_SKILL_COUNTDOWN)
		return;
	}

	if(zp_get_zombie_special_class(id) == g_speciald && !zp_has_round_ended())
	{
		raptor_cooldown_time[id]--
		set_hudmessage(0, 100, 255, -1.0, 0.6, 0, 1.0, 1.1, 0.0, 0.0, -1)
		ShowSyncHudMsg(id, g_msg_sync[1], "Sprint Cooldown: %d", raptor_cooldown_time[id])
	}
	else {
		remove_task(id+TASK_SKILL_COUNTDOWN)
	}
}

public allow_power_again(id)
{
	id -= TASK_ENABLE_SKILL
	if(zp_get_zombie_special_class(id) == g_speciald) {
		g_abil_one_used[id] = false

		#if ZPS_INC_VERSION < 44
		zp_colored_print(id, "!g[Raptor]!t Your skill is ready.");
		#else
		zp_colored_print(id, 0, "!g[Raptor]!t Your skill is ready.");
		#endif
	}
}

#if ZPS_INC_VERSION < 44
stock zp_colored_print(const id,const input[], any:...)
{
	new msg[191], players[32], count = 1; vformat(msg,190,input,3);
	replace_all(msg,190,"!g","^4");    // green
	replace_all(msg,190,"!y","^1");    // normal
	replace_all(msg,190,"!t","^3");    // team
	
	if (id) players[0] = id; else get_players(players,count,"ch");
	
	for (new i=0;i<count;i++)
	{
		if (is_user_connected(players[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("SayText"),_,players[i]);
			write_byte(players[i]);
			write_string(msg);
			message_end();
		}
	}
} 
#endif

stock ScreenFade(id, Timer, r, g ,b, Alpha) 
{	
	if(!is_user_connected(id)) return;
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, id);
	write_short((1<<12) * Timer)
	write_short(1<<12)
	write_short(0)
	write_byte(r)
	write_byte(g)
	write_byte(b)
	write_byte(Alpha)
	message_end()
}


public native_get_user_raptor(id)
	return (zp_get_zombie_special_class(id) == g_speciald)
	
public native_make_user_raptor(id)
	return (zp_make_user_special(id, g_speciald, GET_ZOMBIE))
	
public native_get_raptor_count()
	return zp_get_special_count(GET_ZOMBIE, g_speciald)
	
public native_is_raptor_round()
	return (zp_get_current_mode() == g_gameid)

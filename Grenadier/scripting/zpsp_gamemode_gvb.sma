/*	
		[ZPSp] Game Mode: Grenadier Vs Bombardier

			* Description:
				Its a Grenade War, Just killing

			* Cvars:
				zp_gvb_minplayers "2" - Min Players for Start Mod
				zp_gvb_grenadier_hp "2000" - Health of Grenadier
				zp_gvb_bombardier_hp "1000" - Health of Bombardier
				zp_gvb_inf_ratio "0.5" - Ratio of Players (0.5 with 10 players = 5 Bombardier vs 5 Grenadier)

*/

#include <amxmodx>
#include <fun>
#include <zombie_plague_special>
#include <amx_settings_api>
#include <zpsp_class_grenadier>

#if ZPS_INC_VERSION < 43
	#assert Zombie Plague Special 4.3 Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

new const ZP_CUSTOMIZATION_FILE[] = "zombie_plague_special.ini"

new Array:g_sound_gvb, g_ambience_sounds, Array:g_sound_amb_gvb_duration, Array: g_sound_ambience_gvb

// Default Sounds
new const sound_gvb[][] = { "zombie_plague/survivor1.wav" }
new const ambience_gvb_sound[][] = { "zombie_plague/ambience.wav" } 
new const ambience_gvb_dur[][] = { "17" }

#if ZPS_INC_VERSION > 44
new const gm_respawn_limit = 3 // Respawn Limit per Player (Zombie Plague Special 4.4 Version or higher requires)
#endif

// Variables
new g_gameid, g_maxplayers, cvar_minplayers, cvar_ratio, cvar_grenadierhp, cvar_bombardierhp, g_msg_sync

new const g_chance = 85

// Ambience sounds task
#define TASK_AMB 3256

public plugin_init()
{
	// Plugin registeration.
	register_plugin("[ZP] Grenadier Vs Bombardier Mode", "1.0", "@bdul! | [P]erfec[T] [S]cr[@]s[H]")
	
	// Register some cvars
	// Edit these according to your liking
	cvar_minplayers = register_cvar("zp_gvb_minplayers", "2")
	cvar_grenadierhp = register_cvar("zp_gvb_grenadier_hp", "2000")
	cvar_bombardierhp = register_cvar("zp_gvb_bombardier_hp", "1000")
	cvar_ratio = register_cvar("zp_gvb_inf_ratio", "0.5")
	
	g_maxplayers = get_maxplayers() // Get maxplayers
	g_msg_sync = CreateHudSyncObj() // Hud stuff
}

// Game modes MUST be registered in plugin precache ONLY
public plugin_precache()
{
	// Read the access flag
	new user_access[40], access_flag, i
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE GVB", user_access, charsmax(user_access))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE GVB", "a")
		formatex(user_access, charsmax(user_access), "a")
	}
	
	access_flag  = read_flags(user_access)

	g_sound_gvb = ArrayCreate(64, 1)
	g_sound_ambience_gvb = ArrayCreate(64, 1)
	g_sound_amb_gvb_duration = ArrayCreate(64, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND GVB", g_sound_gvb)
	
	// Precache the play sounds
	if (ArraySize(g_sound_gvb) == 0)
	{
		for (i = 0; i < sizeof sound_gvb; i++)
			ArrayPushString(g_sound_gvb, sound_gvb[i])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND GVB", g_sound_gvb)
	}
	
	// Precache sounds
	static sound[100]
	for (i = 0; i < ArraySize(g_sound_gvb); i++)
	{
		ArrayGetString(g_sound_gvb, i, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			if(!file_exists(sound))
				format(sound, charsmax(sound), "sound/%s", sound)
			
			precache_generic(sound)
		}
		else precache_sound(sound)
	}
	
	// Ambience Sounds
	g_ambience_sounds = 0
	if(!amx_load_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "GVB ENABLE", g_ambience_sounds))
		amx_save_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "GVB ENABLE", g_ambience_sounds)
	
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "GVB SOUNDS", g_sound_ambience_gvb)
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "GVB DURATIONS", g_sound_amb_gvb_duration)
	
	// Save to external file
	if (ArraySize(g_sound_ambience_gvb) == 0) {
		for (i = 0; i < sizeof ambience_gvb_sound; i++)
			ArrayPushString(g_sound_ambience_gvb, ambience_gvb_sound[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "GVB SOUNDS", g_sound_ambience_gvb)
	}
	
	if (ArraySize(g_sound_amb_gvb_duration) == 0) {
		for (i = 0; i < sizeof ambience_gvb_dur; i++)
			ArrayPushString(g_sound_amb_gvb_duration, ambience_gvb_dur[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "GVB DURATIONS", g_sound_amb_gvb_duration)
	}
	
	// Ambience Sounds
	static buffer[250]
	if (g_ambience_sounds) {
		for (i = 0; i < ArraySize(g_sound_ambience_gvb); i++) {
			ArrayGetString(g_sound_ambience_gvb, i, buffer, charsmax(buffer))
			
			if (equal(buffer[strlen(buffer)-4], ".mp3")) {
				
				if(!file_exists(buffer))
					format(buffer, charsmax(buffer), "sound/%s", buffer)

				precache_generic(buffer)
			}
			else precache_sound(buffer)
		}
	}
	
	// Register our game mode
	#if ZPS_INC_VERSION < 44
	g_gameid = zp_register_game_mode("Grenadier vs Bombardier", access_flag, g_chance, 0, ZP_DM_BALANCE)
	#else
	g_gameid = zpsp_register_gamemode("Grenadier vs Bombardier", access_flag, g_chance, 0, ZP_DM_BALANCE, gm_respawn_limit)
	#endif
}

public plugin_natives() {
	register_native("zp_is_gvb_round", "native_is_gvb_round", 1)
}

// Player spawn post
public zp_player_spawn_post(id)
{
	// Check for current mode
	if(zp_get_current_mode() == g_gameid) {
		// Check if the player is a zombie
		if(zp_get_user_zombie(id)) {
			zp_make_user_bombardier(id) // Make him an bombardier instead
			set_user_health(id, get_pcvar_num(cvar_bombardierhp)) // Set his health
		}
		else {
			zp_make_user_grenadier(id) // Make him a grenadier
			set_user_health(id, get_pcvar_num(cvar_grenadierhp)) // Set his health
		}
	}
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
		start_gvb_mode()
	}
	// Make the compiler happy =)
	return PLUGIN_CONTINUE
}

public zp_round_started(game, id)
{
	// Check if it is our game mode
	if(game == g_gameid)
	{
		// Show HUD notice
		set_hudmessage(221, 156, 21, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_msg_sync, "Bombardier Vs Grenadier !!!")
		
		// Play the starting sound
		static sound[100]
		ArrayGetString(g_sound_gvb, random_num(0, ArraySize(g_sound_gvb) - 1), sound, charsmax(sound))

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
	if (equal(sound[strlen(sound)-4], ".mp3")) {
		client_cmd(0, "mp3 stop")
		client_cmd(0, "mp3 play ^"sound/%s^"", sound)
	}
	else {
		client_cmd(0, "stopsound")
		client_cmd(0, "spk ^"%s^"", sound)
	}
}
#endif
public zp_game_mode_selected(gameid, id)
{
	// Check if our game mode was called
	if(gameid == g_gameid)
		start_gvb_mode()
	
	// Make the compiler happy again =)
	return PLUGIN_CONTINUE
}

// This function contains the whole code behind this game mode
start_gvb_mode()
{
	// Create and initialize some important vars
	static i_bombardiers, i_max_bombardiers, id, i_alive
	i_alive = zp_get_alive_players()
	id = 0
	
	// Get the no of players we have to turn into assassins
	i_max_bombardiers = floatround((i_alive * get_pcvar_float(cvar_ratio)), floatround_ceil)
	i_bombardiers = 0
	
	// Randomly turn players into Assassins
	while (i_bombardiers < i_max_bombardiers)
	{
		// Keep looping through all players
		if ((++id) > g_maxplayers) id = 1
		
		// Dead
		if (!is_user_alive(id))
			continue;
		
		// Random chance
		if (random_num(1, 5) == 1)
		{
			// Make user bombardier
			zp_make_user_bombardier(id)
			set_user_health(id, get_pcvar_num(cvar_bombardierhp)) // Set his health
			i_bombardiers++ // Increase counter
		}
	}
	
	// Turn the remaining players into snipers
	for (id = 1; id <= g_maxplayers; id++)
	{
		// Only those of them who are alive and are not assassins
		if (!is_user_alive(id) || zp_get_user_bombardier(id))
			continue;
		
		zp_make_user_grenadier(id) // Turn into a grenadier		
		set_user_health(id, get_pcvar_num(cvar_grenadierhp)) // Set his health
	}
}

public start_ambience_sounds()
{
	if (!g_ambience_sounds)
		return;
	
	// Variables
	static amb_sound[64], sound,  str_dur[20]
	
	
	sound = random_num(0, ArraySize(g_sound_ambience_gvb)-1) // Select our ambience sound

	ArrayGetString(g_sound_ambience_gvb, sound, amb_sound, charsmax(amb_sound))
	ArrayGetString(g_sound_amb_gvb_duration, sound, str_dur, charsmax(str_dur))
	
	#if ZPS_INC_VERSION < 44
	PlaySoundToClients(amb_sound)
	#else
	zp_play_sound(0, amb_sound)
	#endif
	
	// Start the ambience sounds
	set_task(str_to_float(str_dur), "start_ambience_sounds", TASK_AMB)
}
public zp_round_ended() {
	remove_task(TASK_AMB) // Stop ambience sounds on round end
}

public native_is_gvb_round() {
	return (zp_get_current_mode() == g_gameid)
}

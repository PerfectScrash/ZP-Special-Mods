/*
	[ZPSp] Gamemode: Gravity Mode

	* Description:
		Its like swarm mode, but with low gravity

	* Cvars:
		zp_gravity_minplayers "2" - Min Players for start a mode
		zp_gravity_inf_ratio "0.5" - Ratio of gamemode

*/

#include <amxmodx>
#include <fun>
#include <zombie_plague_special>
#include <amx_settings_api>

#if ZPS_INC_VERSION < 43
	#assert Zombie Plague Special 4.3 Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

new const ZP_CUSTOMIZATION_FILE[] = "zombie_plague_special.ini"

new Array:g_sound_gravity, g_ambience_sounds, Array:g_sound_ambience_dur, Array: g_sound_ambience

// Default Sounds
new const sound_gravity[][] = { "ambience/the_horror2.wav" }
new const ambience_gravity_sound[][] = { "zombie_plague/ambience.wav" } 
new const ambience_gravity_dur[][] = { "17" }

// Variables
new g_gameid, g_maxplayers, cvar_minplayers, cvar_ratio, g_msg_sync

new const g_chance = 80

// Ambience sounds task
#define TASK_AMB 3256

// Enable Ambience?
#define AMBIENCE_ENABLE 0

public plugin_init()
{
	// Plugin registeration.
	register_plugin("[ZP] Gravity Mode","1.0", "@bdul! | [P]erfec[T] [S]cr[@]s[H]")
	
	// Register some cvars
	cvar_minplayers = register_cvar("zp_gravity_minplayers", "2")
	cvar_ratio = register_cvar("zp_gravity_inf_ratio", "0.5")
	
	// Get maxplayers
	g_maxplayers = get_maxplayers()
	
	// Hud stuff
	g_msg_sync = CreateHudSyncObj()
}

public plugin_natives() {
	register_native("zp_is_gravity_round", "native_is_gravity_round", 1)
}

// Game modes MUST be registered in plugin precache ONLY
public plugin_precache()
{
	// Read the access flag
	static user_access[40], i, access_flag
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE GRAVITY", user_access, charsmax(user_access)))
	{
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE GRAVITY", "a")
		formatex(user_access, charsmax(user_access), "a")
	}
	
	access_flag = read_flags(user_access)
	
	g_sound_gravity = ArrayCreate(64, 1)
	g_sound_ambience = ArrayCreate(64, 1)
	g_sound_ambience_dur = ArrayCreate(64, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND GRAVITY", g_sound_gravity)
	
	// Precache the play sounds
	if (ArraySize(g_sound_gravity) == 0) {
		for (i = 0; i < sizeof sound_gravity; i++)
			ArrayPushString(g_sound_gravity, sound_gravity[i])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND GRAVITY", g_sound_gravity)
	}
	
	// Precache sounds
	new sound[100]
	for (i = 0; i < ArraySize(g_sound_gravity); i++)
	{
		ArrayGetString(g_sound_gravity, i, sound, charsmax(sound))
		precache_ambience(sound)
	}
	
	// Ambience Sounds
	g_ambience_sounds = AMBIENCE_ENABLE
	if(!amx_load_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "GRAVITY ENABLE", g_ambience_sounds))
		amx_save_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "GRAVITY ENABLE", g_ambience_sounds)
	
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "GRAVITY SOUNDS", g_sound_ambience)
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "GRAVITY DURATIONS", g_sound_ambience_dur)
	
	// Save to external file
	if (ArraySize(g_sound_ambience) == 0) {
		for (i = 0; i < sizeof ambience_gravity_sound; i++)
			ArrayPushString(g_sound_ambience, ambience_gravity_sound[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "GRAVITY SOUNDS", g_sound_ambience)
	}
	
	if (ArraySize(g_sound_ambience_dur) == 0) {
		for (i = 0; i < sizeof ambience_gravity_dur; i++)
			ArrayPushString(g_sound_ambience_dur, ambience_gravity_dur[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "GRAVITY DURATIONS", g_sound_ambience_dur)
	}
	
	// Ambience Sounds
	static buffer[250]
	if (g_ambience_sounds) {
		for (i = 0; i < ArraySize(g_sound_ambience); i++) {
			ArrayGetString(g_sound_ambience, i, buffer, charsmax(buffer))
			precache_ambience(buffer)
		}
	}
	
	// Register our game mode
	#if ZPS_INC_VERSION < 44
	g_gameid = zp_register_game_mode("Gravity", access_flag, g_chance, 0, ZP_DM_NONE)
	#else
	g_gameid = zpsp_register_gamemode("Gravity", access_flag, g_chance, 0, ZP_DM_NONE)
	#endif
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
		start_gravity_mode()
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
		ShowSyncHudMsg(0, g_msg_sync, "Gravity Mode !!!")
		
		// Play the starting sound
		static sound[100]
		ArrayGetString(g_sound_gravity, random_num(0, ArraySize(g_sound_gravity) - 1), sound, charsmax(sound))
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

public zp_game_mode_selected(gameid, id)
{
	// Check if our game mode was called
	if(gameid == g_gameid)
		start_gravity_mode()
	
	// Make the compiler happy again =)
	return PLUGIN_CONTINUE
}

// This function contains the whole code behind this game mode
start_gravity_mode()
{
	// Create and initialize some important vars
	static i_zombies, i_max_zombies, id, i_alive
	i_alive = zp_get_alive_players()
	id = 0
	
	// Get the no of players we have to turn into zombies
	i_max_zombies = floatround((i_alive * get_pcvar_float(cvar_ratio)), floatround_ceil)
	i_zombies = 0
	
	// Randomly turn players into zombies
	while (i_zombies < i_max_zombies)
	{
		// Keep looping through all players
		if ((++id) > g_maxplayers) id = 1
		
		// Dead
		if (!is_user_alive(id))
			continue;
		
		// Random chance
		if (random_num(1, 5) == 1) {
			// Make user zombie
			zp_infect_user(id)

			if(zp_is_escape_map())
				zp_do_random_spawn(id)
			
			// Increase counter
			i_zombies++
		}
	}

	server_cmd("sv_gravity 100")
}

public start_ambience_sounds()
{
	if (!g_ambience_sounds)
		return;
	
	// Variables
	static amb_sound[64], sound,  str_dur[20]
	
	// Select our ambience sound
	sound = random_num(0, ArraySize(g_sound_ambience)-1)

	ArrayGetString(g_sound_ambience, sound, amb_sound, charsmax(amb_sound))
	ArrayGetString(g_sound_ambience_dur, sound, str_dur, charsmax(str_dur))
	
	#if ZPS_INC_VERSION < 44
	PlaySoundToClients(amb_sound)
	#else
	zp_play_sound(0, amb_sound)
	#endif
	
	// Start the ambience sounds
	set_task(str_to_float(str_dur), "start_ambience_sounds", TASK_AMB)
}
public zp_round_ended(winteam)
{
	// Stop ambience sounds on round end
	remove_task(TASK_AMB)

	// Restore Gravity
	server_cmd("sv_gravity 800")
}

public native_is_gravity_round() {
	return (zp_get_current_mode() == g_gameid)
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

#if ZPS_INC_VERSION < 44
// Plays a sound on clients
stock PlaySoundToClients(const sound[])
{
	static buffer[150]

	if(equal(sound[strlen(sound)-4], ".mp3")) {
		if(!equal(sound, "sound/", 6) && !file_exists(sound) && !equal(sound, "media/", 6))
			format(buffer, charsmax(buffer), "sound/%s", sound)
		else
			format(buffer, charsmax(buffer), "%s", sound)
	
		client_cmd(0, "mp3 play ^"%s^"", buffer)

	}
	else {
		if(equal(sound, "sound/", 6))
			format(buffer, charsmax(buffer), "%s", sound[6])
		else
			format(buffer, charsmax(buffer), "%s", sound)
			
		client_cmd(0, "spk ^"%s^"", buffer)
	}
}
#endif

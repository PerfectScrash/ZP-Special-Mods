/***************************************************************************\
		   ========================================
		    * || [ZPSp] Game Mode Shadow vs Sonic || *
		   ========================================

	-------------
	 *||CVARS||*
	-------------

	- zp_sonic_vs_shadow_minplayers 2
		- Minimum players required for this game mode to be
		  activated

	- zp_sonic_vs_shadow_sonic_hp 1.5
		- Sonic HP multiplier
	
	- zp_sonic_vs_shadow_shadow_hp 1.0
		- Shadows HP multiplier

	- zp_sonic_vs_shadow_inf_ratio 0.5
		- Infection ratio of this game mode i.e how many players
		  will turn into shadows [Total players * infection ratio]
		  	
\***************************************************************************/

#include <amxmodx>
#include <fun>
#include <zombie_plague_special>
#include <amx_settings_api>
#include <zpsp_sonic_shadow>


#if ZPS_INC_VERSION < 44
	#assert Zombie Plague Special 4.4 (Beta) Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

new const ZP_CUSTOMIZATION_FILE[] = "zombie_plague_special.ini"

new Array:g_sound_SvS, g_ambience_sounds, Array:g_sound_amb_SvS_duration, Array: g_sound_ambience_SvS

// Default Sounds
new const sound_SvS[][] = { "zpsp_sonic/round_start_sega.wav" }
new const ambience_SvS_sound[][] = { "sound/zpsp_sonic/shadow_ambience.mp3" } 
new const ambience_SvS_dur[][] = { "268" }

// Variables
new g_gameid, g_maxplayers, cvar_minplayers, cvar_ratio, cvar_sonichp, cvar_shadowhp, g_msg_sync

new const g_chance = 90

// Enable Ambience?
#define AMBIENCE_ENABLE 1

// Ambience sounds task
#define TASK_AMB 3256

public plugin_init()
{
	// Plugin registeration.
	register_plugin("[ZP] Shadow vs Sonic Mode","1.0", "@bdul! | [P]erfec[T] [S]cr[@]s[H]")
	register_dictionary("zpsp_sonic_shadow.txt")
	
	// Register some cvars
	// Edit these according to your liking
	cvar_minplayers = register_cvar("zp_sonic_vs_shadow_minplayers", "2")
	cvar_sonichp = register_cvar("zp_sonic_vs_shadow_sonic_hp", "5000")
	cvar_shadowhp = register_cvar("zp_sonic_vs_shadow_shadow_hp", "5000")
	cvar_ratio = register_cvar("zp_sonic_vs_shadow_inf_ratio", "0.5")
	
	// Get maxplayers
	g_maxplayers = get_maxplayers()
	
	// Hud stuff
	g_msg_sync = CreateHudSyncObj()
}

public plugin_natives() {
	register_native("zp_is_sonic_vs_shadow", "native_is_SvS_round", 1)
	register_native("zp_is_sonic_vs_shadow_enable", "native_is_SvS_enable", 1)
}

// Game modes MUST be registered in plugin precache ONLY
public plugin_precache()
{
	// Read the access flag
	static user_access[40], i, buffer[250], access_flag
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE SONIC VS SHADOW", user_access, charsmax(user_access))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE SONIC VS SHADOW", "a")
		formatex(user_access, charsmax(user_access), "a")
	}
	access_flag = read_flags(user_access)

	g_sound_SvS = ArrayCreate(64, 1)
	g_sound_ambience_SvS = ArrayCreate(64, 1)
	g_sound_amb_SvS_duration = ArrayCreate(64, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND SONIC VS SHADOW", g_sound_SvS)
	
	// Precache the play sounds
	if (ArraySize(g_sound_SvS) == 0)
	{
		for (i = 0; i < sizeof sound_SvS; i++)
			ArrayPushString(g_sound_SvS, sound_SvS[i])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND SONIC VS SHADOW", g_sound_SvS)
	}
	
	// Precache sounds
	for (i = 0; i < ArraySize(g_sound_SvS); i++)
	{
		ArrayGetString(g_sound_SvS, i, buffer, charsmax(buffer))
		precache_ambience(buffer)
	}
	
	// Ambience Sounds
	g_ambience_sounds = AMBIENCE_ENABLE
	if(!amx_load_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "SONIC VS SHADOW ENABLE", g_ambience_sounds))
		amx_save_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "SONIC VS SHADOW ENABLE", g_ambience_sounds)
	
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "SONIC VS SHADOW SOUNDS", g_sound_ambience_SvS)
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "SONIC VS SHADOW DURATIONS", g_sound_amb_SvS_duration)
	
	
	// Save to external file
	if (ArraySize(g_sound_ambience_SvS) == 0)
	{
		for (i = 0; i < sizeof ambience_SvS_sound; i++)
			ArrayPushString(g_sound_ambience_SvS, ambience_SvS_sound[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "SONIC VS SHADOW SOUNDS", g_sound_ambience_SvS)
	}
	
	if (ArraySize(g_sound_amb_SvS_duration) == 0)
	{
		for (i = 0; i < sizeof ambience_SvS_dur; i++)
			ArrayPushString(g_sound_amb_SvS_duration, ambience_SvS_dur[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "SONIC VS SHADOW DURATIONS", g_sound_amb_SvS_duration)
	}
	
	// Ambience Sounds
	if (g_ambience_sounds) {
		for (i = 0; i < ArraySize(g_sound_ambience_SvS); i++) {
			ArrayGetString(g_sound_ambience_SvS, i, buffer, charsmax(buffer))
			precache_ambience(buffer)
		}
	}
	
	// Register our game mode
	g_gameid = zpsp_register_gamemode("Shadow vs Sonic", access_flag, g_chance, 0, ZP_DM_BALANCE)
}

// Player spawn post
public zp_player_spawn_post(id)
{
	// Check for current mode
	if(zp_get_current_mode() == g_gameid)
	{
		// Check if the player is a zombie
		if(zp_get_user_zombie(id))
		{
			// Make him an shadow instead
			zp_make_user_shadow(id)
			
			// Set his health
			set_user_health(id, get_pcvar_num(cvar_shadowhp))
		}
		else
		{
			// Make him a sonic
			zp_make_user_sonic(id)
			
			// Set his health
			set_user_health(id, get_pcvar_num(cvar_sonichp))
		}
	}
}
public zp_game_mode_selected_pre(id, game)
{
	if(game != g_gameid)
		return PLUGIN_CONTINUE;

	if(!zp_is_shadow_enable() || !zp_is_sonic_enable())
		return ZP_PLUGIN_SUPERCEDE;

	return PLUGIN_CONTINUE;
}

public zp_round_started_pre(game)
{
	// Check if it is our game mode
	if(game == g_gameid)
	{
		// Check for min players
		if(zp_get_alive_players() < get_pcvar_num(cvar_minplayers))
			return ZP_PLUGIN_HANDLED

		if(!zp_is_shadow_enable() || !zp_is_sonic_enable())
			return ZP_PLUGIN_HANDLED;

		// Start our new mode
		start_SvS_mode()
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
		set_hudmessage(255, 69, 0, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "START_SVS")
		
		// Play the starting sound
		static sound[100]
		ArrayGetString(g_sound_SvS, random_num(0, ArraySize(g_sound_SvS) - 1), sound, charsmax(sound))
		zp_play_sound(0, sound)
		
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
		start_SvS_mode()
	
	// Make the compiler happy again =)
	return PLUGIN_CONTINUE
}

// This function contains the whole code behind this game mode
start_SvS_mode()
{
	// Create and initialize some important vars
	static i_shadows, i_max_shadows, id, i_alive
	i_alive = zp_get_alive_players()
	id = 0
	
	// Get the no of players we have to turn into shadows
	i_max_shadows = floatround((i_alive * get_pcvar_float(cvar_ratio)), floatround_ceil)
	i_shadows = 0
	
	// Randomly turn players into Shadows
	while (i_shadows < i_max_shadows)
	{
		// Keep looping through all players
		if ((++id) > g_maxplayers) id = 1
		
		// Dead
		if (!is_user_alive(id))
			continue;
		
		// Random chance
		if (random_num(1, 5) == 1)
		{
			// Make user shadow
			zp_make_user_shadow(id)
			
			// Set his health
			set_user_health(id, get_pcvar_num(cvar_shadowhp))

			// Increase counter
			i_shadows++
		}
	}
	
	// Turn the remaining players into sonics
	for (id = 1; id <= g_maxplayers; id++)
	{
		// Only those of them who are alive and are not shadows
		if (!is_user_alive(id) || zp_get_user_shadow(id))
			continue;
			
		// Turn into a sonic
		zp_make_user_sonic(id)
		
		// Set his health
		set_user_health(id, get_pcvar_num(cvar_sonichp))
	}
}

public start_ambience_sounds()
{
	if (!g_ambience_sounds)
		return;
	
	// Variables
	static amb_sound[64], sound,  str_dur[20]
	
	// Select our ambience sound
	sound = random_num(0, ArraySize(g_sound_ambience_SvS)-1)

	ArrayGetString(g_sound_ambience_SvS, sound, amb_sound, charsmax(amb_sound))
	ArrayGetString(g_sound_amb_SvS_duration, sound, str_dur, charsmax(str_dur))
	
	zp_play_sound(0, amb_sound)
	
	// Start the ambience sounds
	set_task(str_to_float(str_dur), "start_ambience_sounds", TASK_AMB)
}
public zp_round_ended(winteam)
{
	// Stop ambience sounds on round end
	remove_task(TASK_AMB)
}

public native_is_SvS_round() 
	return (zp_get_current_mode() == g_gameid)

public native_is_SvS_enable()
	return (zp_is_gamemode_enable(g_gameid))

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

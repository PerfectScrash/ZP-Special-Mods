/*
	[ZPSp] Gamemode: Deathmatch Mode

	* Description:
		Its Like swarm mode but you can respawn

	* Cvars:
		zp_deathmatch_minplayers "2" - Min Players for start a mode
		zp_deathmatch_inf_ratio "0.5" - Ratio of gamemode

*/

#include <amxmodx>
#include <fun>
#include <zombie_plague_special>
#include <amx_settings_api>

#if ZPS_INC_VERSION < 45
	#assert Zombie Plague Special 4.5 or higher Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

/*-------------[Ambience Configuration]--------------------------*/
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
	"zombie_plague/nemesis1.wav", 
	"zombie_plague/survivor1.wav" 
}

/*-------------[Gamemode Configuration]--------------------------*/
#define DEFAULT_FLAG_ACESS ADMIN_IMMUNITY 	// Flag Acess mode
new const g_chance = 90 // Chance of 1 in X to start
new const gm_respawn_limit = 3 // Respawn Limit per Player

/*------------------------[Variables]--------------------------*/
new g_gameid, cvar_minplayers, cvar_ratio, g_msg_sync

/*-------------[Plugin registeration]--------------------------*/
public plugin_init() {
	register_plugin("[ZPSp] Game Mode: Deathmatch Mode", "1.1", "@bdul! | [P]erfec[T] [S]cr[@]s[H]")
	
	// Register some cvars
	cvar_minplayers = register_cvar("zp_deathmatch_minplayers", "2")
	cvar_ratio = register_cvar("zp_deathmatch_inf_ratio", "0.5")
	
	// Hud stuff
	g_msg_sync = CreateHudSyncObj()
}

/*------------------------[Natives]--------------------------*/
public plugin_natives()
	register_native("zp_is_deathmatch_round", "native_is_deathmatch_round");

public native_is_deathmatch_round(plugin_id, num_params)
	return (zp_get_current_mode() == g_gameid);

/*------------------------[Precache]--------------------------*/
public plugin_precache() {
	g_gameid = zpsp_register_gamemode("Deathmatch", DEFAULT_FLAG_ACESS, g_chance, 0, ZP_DM_BALANCE, gm_respawn_limit, 0, 1, "DM_MODNAME")

	static i;
	// Register round start sound
	for(i = 0; i < sizeof gamemode_round_start_snd; i++)
		zp_register_start_gamemode_snd(g_gameid, gamemode_round_start_snd[i])

	// Register ambience sounds
	for (i = 0; i < sizeof gamemode_ambiences; i++)
		zp_register_gamemode_ambience(g_gameid, gamemode_ambiences[i][AmbiencePrecache], gamemode_ambiences[i][AmbienceDuration], ambience_enable)
}

public zp_round_started_pre(game) {
	if(game != g_gameid)
		return PLUGIN_CONTINUE
	
	// Check for min players
	if(zp_get_alive_players() < get_pcvar_num(cvar_minplayers))
		return ZP_PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public zp_round_started(game, id) {
	if(game != g_gameid)
		return;
	
	// Show HUD notice
	set_hudmessage(221, 156, 21, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "DM_START")

	// Create and initialize some important vars
	static i_zombies, i_max_zombies, id, i_alive
	i_alive = zp_get_alive_players()
	id = 0
	
	// Get the no of players we have to turn into zombies
	i_max_zombies = floatround((i_alive * get_pcvar_float(cvar_ratio)), floatround_ceil)
	i_zombies = 0
	
	// Randomly turn players into zombies
	while (i_zombies < i_max_zombies) {
		// Keep looping through all players
		if ((++id) > MaxClients) id = 1
		
		if (!is_user_alive(id))
			continue;
		
		if(random_num(1, 5) != 1 || zp_get_user_zombie(id))
			continue
			
		zp_infect_user(id) // Make user zombie
		if(zp_is_escape_map()) zp_do_random_spawn(id)
		i_zombies++ // Increase counter
	}
}
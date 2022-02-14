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

#if ZPS_INC_VERSION < 45
	#assert Zombie Plague Special 4.5 Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

/*-------------------------------------
--> Sound Config
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
	"zombie_plague/nemesis1.wav", 
	"zombie_plague/survivor1.wav" 
}

/*-------------------------------------
--> Gamemode Config
--------------------------------------*/
new const g_chance = 90						// Gamemode chance
#define DEFAULT_FLAG_ACESS ADMIN_IMMUNITY 	// Flag Acess mode
new const gm_respawn_limit = 3 // Respawn Limit per Player

/*-------------------------------------
--> Variables/Defines
--------------------------------------*/
new g_gameid, cvar_minplayers, cvar_ratio, cvar_grenadierhp, cvar_bombardierhp, g_msg_sync, g_grenadier_id
#define zp_make_user_grenadier(%1) zp_make_user_special(%1, g_grenadier_id, GET_HUMAN)
#define zp_get_user_grenadier(%1) (zp_get_human_special_class(%1) == g_grenadier_id)
#define IsGvbRound() (zp_get_current_mode() == g_gameid)

/*-------------------------------------
--> Plugin registeration
--------------------------------------*/
public plugin_init() {
	register_plugin("[ZPSp] Game Mode: Grenadier Vs Bombardier", "1.1", "@bdul! | [P]erfec[T] [S]cr[@]s[H]")
	
	cvar_minplayers = register_cvar("zp_gvb_minplayers", "2")
	cvar_grenadierhp = register_cvar("zp_gvb_grenadier_hp", "2000")
	cvar_bombardierhp = register_cvar("zp_gvb_bombardier_hp", "1000")
	cvar_ratio = register_cvar("zp_gvb_inf_ratio", "0.5")
	
	g_msg_sync = CreateHudSyncObj() // Hud stuff
	g_grenadier_id = zp_get_special_class_id(GET_HUMAN, "Grenadier")
}

// Game modes MUST be registered in plugin precache ONLY
public plugin_precache() {
	g_gameid = zpsp_register_gamemode("Grenadier vs Bombardier", DEFAULT_FLAG_ACESS, g_chance, 0, ZP_DM_BALANCE, gm_respawn_limit)

	static i
	// Register round start sound
	for(i = 0; i < sizeof gamemode_round_start_snd; i++)
		zp_register_start_gamemode_snd(g_gameid, gamemode_round_start_snd[i])

	// Register ambience sounds
	for (i = 0; i < sizeof gamemode_ambiences; i++)
		zp_register_gamemode_ambience(g_gameid, gamemode_ambiences[i][AmbiencePrecache], gamemode_ambiences[i][AmbienceDuration], ambience_enable)
}

public plugin_natives()
	register_native("zp_is_gvb_round", "native_is_gvb_round");

public native_is_gvb_round(plugin_id, num_params)
	return (IsGvbRound());

// Player spawn post
public zp_player_spawn_post(id) {
	// Check for current mode
	if(!IsGvbRound()) 
		return;

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
		return

	// Show HUD notice
	set_hudmessage(221, 156, 21, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync, "Bombardier Vs Grenadier !!!")

	// Create and initialize some important vars
	static i_bombardiers, i_max_bombardiers, id, i_alive
	i_alive = zp_get_alive_players()
	id = 0
	
	// Get the no of players we have to turn into assassins
	i_max_bombardiers = floatround((i_alive * get_pcvar_float(cvar_ratio)), floatround_ceil)
	i_bombardiers = 0
	
	// Randomly turn players into Assassins
	while (i_bombardiers < i_max_bombardiers) {
		// Keep looping through all players
		if((++id) > MaxClients) id = 1
		
		if(!is_user_alive(id))
			continue;

		if(random_num(1, 5) != 1 || zp_get_user_bombardier(id))
			continue;
		
		zp_make_user_bombardier(id) // Make user bombardier
		set_user_health(id, get_pcvar_num(cvar_bombardierhp)) // Set his health
		i_bombardiers++ // Increase counter
	}
	
	// Turn the remaining players into snipers
	for (id = 1; id <= MaxClients; id++) {
		if(!is_user_alive(id))
			continue;
		
		if(zp_get_user_bombardier(id) || zp_get_user_grenadier(id))
			continue;
		
		zp_make_user_grenadier(id) // Turn into a grenadier		
		set_user_health(id, get_pcvar_num(cvar_grenadierhp)) // Set his health
	}
}
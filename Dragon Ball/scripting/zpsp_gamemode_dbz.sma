/***************************************************************************\
		   ========================================
		    * || [ZPSp] Game Mode Dragon ball mod || *
		   ========================================

	-------------
	 *||CVARS||*
	-------------

	- zp_dbm_minplayers "2" 	// Minimum players required for this game mode to be activated
	- zp_dbm_goku_hp "5000" 	// Goku Health
	- zp_dbm_frieza_hp "5000" 	// Frieza Health
	- zp_dbm_inf_ratio "0.5"	// Infection ratio of this game mode i.e how many players will turn into frieza [Total players * infection ratio]
		  	
\***************************************************************************/

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
	{ "zp_dragon_ball/ambience_dbz1.wav", 145.0 },
	{ "zp_dragon_ball/ambience_dbz3.wav", 110.0 },
	{ "zp_dragon_ball/ultimate_battle.mp3", 172.0 }
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

/*-------------------------------------
--> Variables/Defines
--------------------------------------*/
new g_gameid, cvar_minplayers, cvar_ratio, cvar_gokuhp, cvar_friezahp, g_msg_sync, g_frieza_id, g_goku_id

// Make/Get User Class (Without use include)
#define zp_make_user_frieza(%1) zp_make_user_special(%1, g_frieza_id, GET_ZOMBIE)
#define zp_get_user_frieza(%1) (zp_get_zombie_special_class(%1) == g_frieza_id)
#define zp_make_user_goku(%1) zp_make_user_special(%1, g_goku_id, GET_HUMAN)
#define zp_get_user_goku(%1) (zp_get_human_special_class(%1) == g_goku_id)

/*-------------------------------------
--> Plugin Registration
--------------------------------------*/
public plugin_init()
{
	register_plugin("[ZPSp] Gamemode: Dragon Ball Mode","1.0", "@bdul! | [P]erfec[T] [S]cr[@]s[H]")
	register_dictionary("zp_dbm_classes.txt")
	
	cvar_minplayers = register_cvar("zp_dbm_minplayers", "2")
	cvar_gokuhp = register_cvar("zp_dbm_goku_hp", "5000")
	cvar_friezahp = register_cvar("zp_dbm_frieza_hp", "5000")
	cvar_ratio = register_cvar("zp_dbm_inf_ratio", "0.5")
	
	g_msg_sync = CreateHudSyncObj()
}

/*-------------------------------------
--> Plugin Precache
--------------------------------------*/
public plugin_precache()
{
	g_frieza_id = zp_get_special_class_id(GET_ZOMBIE, "Frieza")
	g_goku_id = zp_get_special_class_id(GET_HUMAN, "Goku")

	if(g_goku_id == -1 || g_frieza_id == -1) {
		set_fail_state("[ZPSp Dragon Ball] Some special class (Goku/Frieza) are disable")
		return;
	}

	// Register our game mode
	g_gameid = zpsp_register_gamemode("Dragon Ball", DEFAULT_FLAG_ACESS, g_chance, 0, ZP_DM_BALANCE, .uselang=1, .langkey="DBM_MODENANE")

	static i
	// Register round start sound
	for(i = 0; i < sizeof gamemode_round_start_snd; i++)
		zp_register_start_gamemode_snd(g_gameid, gamemode_round_start_snd[i])

	// Register ambience sounds
	for (i = 0; i < sizeof gamemode_ambiences; i++)
		zp_register_gamemode_ambience(g_gameid, gamemode_ambiences[i][AmbiencePrecache], gamemode_ambiences[i][AmbienceDuration], ambience_enable)
}

/*-------------------------------------
--> Gamemode Natives
--------------------------------------*/
public plugin_natives() {
	register_native("zp_is_dbz_round", "native_is_dbz_round")
}
public native_is_dbz_round(plugin_id, num_params)
	return (zp_get_current_mode() == g_gameid);

/*-------------------------------------
--> Gamemode functions
--------------------------------------*/
// Player spawn post
public zp_player_spawn_post(id)
{
	// Check for current mode
	if(zp_get_current_mode() != g_gameid)
		return PLUGIN_CONTINUE;

	if(!is_user_alive(id))
		return PLUGIN_CONTINUE;

	// Check if the player is a zombie
	if(zp_get_user_zombie(id)) {
		zp_make_user_frieza(id) // Make him a frieza
		set_user_health(id, get_pcvar_num(cvar_friezahp)) // Set his health
	}
	else {
		zp_make_user_goku(id) // Make him a goku
		set_user_health(id, get_pcvar_num(cvar_gokuhp)) // Set his health
	}
	return PLUGIN_CONTINUE;
}

public zp_round_started_pre(game)
{
	if(game != g_gameid)
		return PLUGIN_CONTINUE
	
	// Check for min players
	if(zp_get_alive_players() < get_pcvar_num(cvar_minplayers))
		return ZP_PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public zp_round_started(game, id) {
	// Check if it is our game mode
	if(game != g_gameid)
		return;

	// Show HUD notice
	set_hudmessage(221, 156, 21, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "START_DBM")

	// Gamemod main function
	start_dbz_mode()
}

// This function contains the whole code behind this game mode
start_dbz_mode()
{
	// Create and initialize some important vars
	static i_friezas, i_max_friezas, id, i_alive
	i_alive = zp_get_alive_players()
	id = 0
	
	// Get the no off players we have to turn into friezas
	i_max_friezas = floatround((i_alive * get_pcvar_float(cvar_ratio)), floatround_ceil)
	i_friezas = 0
	
	// Randomly turn players into frieza
	while (i_friezas <= i_max_friezas) {
		// Keep looping through all players
		if ((++id) > MaxClients) id = 1
		
		if (!is_user_alive(id))
			continue;

		if (random_num(1, 5) != 1 || zp_get_user_frieza(id)) 
			continue;

		zp_make_user_frieza(id) // Make user frieza
		set_user_health(id, get_pcvar_num(cvar_friezahp)) // Set his health
		i_friezas++ // Increase counter
	}
	
	// Turn the remaining players into goku
	for (id = 1; id <= MaxClients; id++) {
		// Only those of them who are alive and are not frieza
		if (!is_user_alive(id))
			continue;
		if(zp_get_user_frieza(id))
			continue;

		zp_make_user_goku(id) // Turn into a goku
		set_user_health(id, get_pcvar_num(cvar_gokuhp)) // Set his health
	}
}

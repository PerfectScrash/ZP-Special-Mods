/***************************************************************************\
		   ========================================
		    * || [ZPSp] Game Mode Shadow vs Sonic || *
		   ========================================

	-------------
	 *||CVARS||*
	-------------

	- zp_sonic_vs_shadow_minplayers 2 // Minimum players required for this game mode to be activated
	- zp_sonic_vs_shadow_sonic_hp 5000 // Sonic Health
	- zp_sonic_vs_shadow_shadow_hp 5000 // Shadow Health
	- zp_sonic_vs_shadow_inf_ratio 0.5 // Infection ratio of this game mode i.e how many players will turn into shadow [Total players * infection ratio]
		  	
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
	{ "sound/zpsp_sonic/shadow_ambience.mp3", 268.0 },
	{ "sound/zpsp_sonic/sonic_ambience.mp3", 223.0 }
}

// Round start sounds
new const gamemode_round_start_snd[][] = { 
	"zpsp_sonic/round_start_sega.wav"
}

/*-------------------------------------
--> Gamemode Config
--------------------------------------*/
new const g_chance = 90						// Gamemode chance
#define DEFAULT_FLAG_ACESS ADMIN_IMMUNITY 	// Flag Acess mode

/*-------------------------------------
--> Variables/Defines
--------------------------------------*/
new g_gameid, cvar_minplayers, cvar_ratio, cvar_sonichp, cvar_shadowhp, g_msg_sync, g_shadow_id, g_sonic_id

// Make/Get User Shadow/Sonic (Without use include)
#define zp_make_user_shadow(%1) zp_make_user_special(%1, g_shadow_id, GET_ZOMBIE)
#define zp_get_user_shadow(%1) (zp_get_zombie_special_class(%1) == g_shadow_id)
#define zp_make_user_sonic(%1) zp_make_user_special(%1, g_sonic_id, GET_HUMAN)
#define zp_get_user_sonic(%1) (zp_get_human_special_class(%1) == g_sonic_id)

/*-------------------------------------
--> Plugin Register
--------------------------------------*/
public plugin_init() {
	register_plugin("[ZPSp] Gamemode: Shadow vs Sonic Mode", "1.1", "@bdul! | [P]erfec[T] [S]cr[@]s[H]")
	register_dictionary("zpsp_sonic_shadow.txt")
	
	// Register some cvars
	cvar_minplayers = register_cvar("zp_sonic_vs_shadow_minplayers", "2")
	cvar_sonichp = register_cvar("zp_sonic_vs_shadow_sonic_hp", "5000")
	cvar_shadowhp = register_cvar("zp_sonic_vs_shadow_shadow_hp", "5000")
	cvar_ratio = register_cvar("zp_sonic_vs_shadow_inf_ratio", "0.5")
	
	g_msg_sync = CreateHudSyncObj() // Hud stuff
}

/*-------------------------------------
--> Plugin precache
--------------------------------------*/
public plugin_precache()
{
	g_shadow_id = zp_get_special_class_id(GET_ZOMBIE, "Shadow") // Shadow Index
	g_sonic_id = zp_get_special_class_id(GET_HUMAN, "Sonic") // Sonic Index
	if(!zp_is_special_class_enable(GET_ZOMBIE, g_shadow_id) || !zp_is_special_class_enable(GET_HUMAN, g_sonic_id)) {
		set_fail_state("[ZPSp Sonic vs Shadow] Some special class (Shadow/Sonic) are disable")
		return;
	}
	
	// Register our game mode
	g_gameid = zpsp_register_gamemode("Shadow vs Sonic", DEFAULT_FLAG_ACESS, g_chance, 0, ZP_DM_BALANCE, .uselang=1, .langkey="GM_SVS_NAME")

	static i
	// Register round start sound
	for(i = 0; i < sizeof gamemode_round_start_snd; i++)
		zp_register_start_gamemode_snd(g_gameid, gamemode_round_start_snd[i])

	// Register ambience sounds
	for (i = 0; i < sizeof gamemode_ambiences; i++)
		zp_register_gamemode_ambience(g_gameid, gamemode_ambiences[i][AmbiencePrecache], gamemode_ambiences[i][AmbienceDuration], ambience_enable)
}

/*-------------------------------------
--> Natives
--------------------------------------*/
public plugin_natives() {
	register_native("zp_is_sonic_vs_shadow", "native_is_SvS_round")
	register_native("zp_is_sonic_vs_shadow_enable", "native_is_SvS_enable")
}
public native_is_SvS_round(plugin_id, num_params)
	return (zp_get_current_mode() == g_gameid);

public native_is_SvS_enable(plugin_id, num_params)
	return (zp_is_gamemode_enable(g_gameid));

/*-------------------------------------
--> Gamemode functions
--------------------------------------*/
// Player spawn post
public zp_player_spawn_post(id) {
	// Check for current mode
	if(zp_get_current_mode() != g_gameid)
		return
	
	// Check if the player is a zombie
	if(zp_get_user_zombie(id)) {
		zp_make_user_shadow(id) // Make him an shadow instead
		set_user_health(id, get_pcvar_num(cvar_shadowhp)) // Set his health
	}
	else {
		zp_make_user_sonic(id) // Make him a sonic
		set_user_health(id, get_pcvar_num(cvar_sonichp)) // Set his health
	}
}
public zp_game_mode_selected_pre(id, game) {
	if(game != g_gameid)
		return PLUGIN_CONTINUE;

	if(!zp_is_special_class_enable(GET_ZOMBIE, g_shadow_id) || !zp_is_special_class_enable(GET_HUMAN, g_sonic_id))
		return ZP_PLUGIN_SUPERCEDE;

	return PLUGIN_CONTINUE;
}

public zp_round_started_pre(game) {
	// Check if it is our game mode
	if(game != g_gameid)
		return PLUGIN_CONTINUE;
	
	// Check for min players
	if(zp_get_alive_players() < get_pcvar_num(cvar_minplayers))
		return ZP_PLUGIN_HANDLED

	if(!zp_is_special_class_enable(GET_ZOMBIE, g_shadow_id) || !zp_is_special_class_enable(GET_HUMAN, g_sonic_id))
		return ZP_PLUGIN_HANDLED

	// Make the compiler happy =)
	return PLUGIN_CONTINUE
}

public zp_round_started(game, id) {
	if(game == g_gameid)
		start_svs_mode()
}

// This function contains the whole code behind this game mode
start_svs_mode() {
	// Create and initialize some important vars
	static i_shadows, i_max_shadows, id, i_alive
	i_alive = zp_get_alive_players()
	id = 0
	
	// Get the no of players we have to turn into Shadows
	i_max_shadows = floatround((i_alive * get_pcvar_float(cvar_ratio)), floatround_ceil)
	i_shadows = 0
	
	// Randomly turn players into Shadows
	while (i_shadows < i_max_shadows) {
		// Keep looping through all players
		if((++id) > MaxClients) id = 1

		if(!is_user_alive(id))
			continue;
		
		if(random_num(1, 5) != 1 || zp_get_user_shadow(id)) 
			continue;

		zp_make_user_shadow(id) // Make user shadow
		set_user_health(id, get_pcvar_num(cvar_shadowhp)) // Set his health
		i_shadows++ // Increase counter
	}

	// Turn the remaining players into sonic
	for (id = 1; id <= MaxClients; id++) {
		if(!is_user_alive(id))
			continue;
		
		if(zp_get_user_shadow(id) || zp_get_user_sonic(id))
			continue;

		zp_make_user_sonic(id) // Turn into a sonic
		set_user_health(id, get_pcvar_num(cvar_sonichp)) // Set his health
	}

	// Show HUD notice
	set_hudmessage(221, 156, 21, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "START_SVS")
}
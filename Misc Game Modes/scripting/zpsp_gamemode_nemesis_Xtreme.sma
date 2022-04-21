/*
	[ZPSp] Gamemode: Nemesis Xtreme

	* Description:
		- X Nemesis vs Other humans

	* Cvars:
		- zp_nemxtreme_minplayers "8" - Min Players for start a mode
		- zp_nem_xtreme_nemesis_num "3" - Nemesis Count
		- zp_nem_xtreme_nemesis_hp "25000" - Nemesis Health in Nemesis Xtreme Round

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
	"zombie_plague/nemesis1.wav"
}

/*-------------[Gamemode Configuration]--------------------------*/
#define DEFAULT_FLAG_ACESS ADMIN_IMMUNITY 	// Flag Acess mode
new const g_chance = 90 // Chance of 1 in X to start

/*-------------[Variables/Defines]--------------------------*/
new g_gameid, cvar_minplayers, cvar_nemesis_num, cvar_nemesis_health, g_msg_sync
#define IsNemXtremeRound() (zp_get_current_mode() == g_gameid) 

/*-------------[Plugin Register]--------------------------*/
public plugin_init() {
	// Plugin registeration.
	register_plugin("[ZPSp] Game mode: Nemesis Xtreme", "1.0", "@bdul! | [P]erfec[T] [S]cr[@]s[H]")
	register_dictionary("zpsp_misc_modes.txt")
	
	// Register some cvars
	cvar_minplayers = register_cvar("zp_nem_xtreme_minplayers", "8")
	cvar_nemesis_num = register_cvar("zp_nem_xtreme_nemesis_num", "3")
	cvar_nemesis_health = register_cvar("zp_nem_xtreme_nemesis_hp", "25000")
	
	// Hud stuff
	g_msg_sync = CreateHudSyncObj()
}

/*-------------[Natives]--------------------------*/
public plugin_natives() {
	register_native("zp_is_nem_xtreme_round", "native_is_nem_xtreme_round")
}
public native_is_nem_xtreme_round(plugin_id, num_params)
	return (IsNemXtremeRound());

/*-------------[Precache files]--------------------------*/
public plugin_precache() {	
	// Register our game mode
	g_gameid = zpsp_register_gamemode("Nemesis-Xtreme", DEFAULT_FLAG_ACESS, g_chance, 0, ZP_DM_HUMAN, .uselang=1, .langkey="NEM_XTREME_MODNAME")

	static i;
	// Register round start sound
	for(i = 0; i < sizeof gamemode_round_start_snd; i++)
		zp_register_start_gamemode_snd(g_gameid, gamemode_round_start_snd[i])

	// Register ambience sounds
	for (i = 0; i < sizeof gamemode_ambiences; i++)
		zp_register_gamemode_ambience(g_gameid, gamemode_ambiences[i][AmbiencePrecache], gamemode_ambiences[i][AmbienceDuration], ambience_enable)
}
/*-------------[Gamemode functions]--------------------------*/
public zp_round_started_pre(game) {
	if(game != g_gameid)
		return PLUGIN_CONTINUE
	
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
	ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "NEM_XTREME_START")

	// Create and initialize some important vars
	static i_nemesis, i_max_zombies, id, i_health
	i_health = get_pcvar_num(cvar_nemesis_health)
	id = 0
	
	// Get the no of players we have to turn into zombies
	i_max_zombies = get_pcvar_num(cvar_nemesis_num)
	i_nemesis = 0
	
	// Randomly turn players into zombies
	while (i_nemesis < i_max_zombies) {
		// Keep looping through all players
		if((++id) > MaxClients) id = 1

		if(!is_user_alive(id))
			continue;
		
		if(random_num(1, 5) != 1 || zp_get_user_nemesis(id))
			continue;
			
		zp_make_user_nemesis(id) // Make user zombie
		set_user_health(id, i_health)
		if(zp_is_escape_map()) zp_do_random_spawn(id)
		i_nemesis++ // Increase counter
	}
}
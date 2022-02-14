/***************************************************************************\
		   ========================================
			* || [ZPSp] Game Mode: Cannibal || *
		   ========================================

	-------------------
	 *||DESCRIPTION||*
	-------------------

	--- Basicaly Zombies Battle Royale with Zombies vs Zombies, 
		when one zombie kill X zombies this zombie will evolute to nemesis

	-------------------
	 *||REQUERIMENTS||*
	-------------------
	- Zombie Plague Special 4.5
	- ReGame and ReHLDS
	- Amx 1.9 or higher

	-------------
	 *||CVARS||*
	-------------

	- zp_cannibal_minplayers 2
		- Minimum players required for this game mode to begin

	- zp_cannibal_kills_for_evolute 2
		- Kills for evolute to nemesis

	- zp_cannibal_nemesis_health 300
		- Nemesis Health in cannibal mode

	- zp_cannibal_zombie_health 200
		- Zombie Health in cannibal mode

	- zp_cannibal_winner_ap_reward 50
		- Reward for Winner of cannibal mode
		  	
\***************************************************************************/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
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

//----------------[Variables/Defines]------------------------
new g_gameid, cvar_minplayers, cvar_kill_for_evolute, cvar_nemesis_health, cvar_zombie_health, cvar_ap_winner, cvar_nem_dmg, g_msg_sync
new user_kills[33], spr_blood_drop, spr_blood_spray
#define is_user_valid_connected(%1) (1 <= %1 <= MaxClients && is_user_connected(%1))       
#define TASK_AMB 3256
#define TASK_CHECK_HP 1231223
#define IsCannibalRound() (zp_get_current_mode() == g_gameid) 

//------------------[Plugin Register]---------------------
public plugin_init() {
	// Plugin registeration.
	register_plugin("[ZPSp] Gamemode: Cannibal", "1.0", "[P]erfec[T] [S]cr[@]s[H]")
	register_dictionary("zpsp_misc_modes.txt")
	
	// Cvars
	cvar_minplayers = register_cvar("zp_cannibal_minplayers", "2")
	cvar_kill_for_evolute = register_cvar("zp_cannibal_kills_for_evolute", "2")
	cvar_nemesis_health = register_cvar("zp_cannibal_nemesis_health", "300")
	cvar_zombie_health = register_cvar("zp_cannibal_zombie_health", "200")
	cvar_ap_winner = register_cvar("zp_cannibal_winner_ap_reward", "50")
	cvar_nem_dmg = get_cvar_pointer("zp_nem_damage")

	// Events
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	
	// Hud stuff
	g_msg_sync = CreateHudSyncObj()
}

//------------------[Natives]---------------------
public plugin_natives()
	register_native("zp_is_cannibal_round", "native_is_cannibal_round");

public native_is_cannibal_round(plugin_id, num_params) 
	return (IsCannibalRound());

//------------------[Load Configuration and download files]-----------------
public plugin_precache() {
	// Register Traceattack in precache for zombies can attack others zombies
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")

	// Register our game mode
	g_gameid = zpsp_register_gamemode("Cannibal", DEFAULT_FLAG_ACESS, g_chance, 0, ZP_DM_NONE, .uselang=1, .langkey="CANNIBAL_MODNAME")

	spr_blood_drop = precache_model("sprites/blood.spr") 
	spr_blood_spray = precache_model("sprites/bloodspray.spr") 

	static i;
	// Register round start sound
	for(i = 0; i < sizeof gamemode_round_start_snd; i++)
		zp_register_start_gamemode_snd(g_gameid, gamemode_round_start_snd[i])

	// Register ambience sounds
	for (i = 0; i < sizeof gamemode_ambiences; i++)
		zp_register_gamemode_ambience(g_gameid, gamemode_ambiences[i][AmbiencePrecache], gamemode_ambiences[i][AmbienceDuration], ambience_enable)
}

//--------------[Game Mode Functions]--------------------------------
// Manualy Start (On Admin menu)
public zp_game_mode_selected_pre(id, game) {
	if(game != g_gameid)
		return PLUGIN_CONTINUE;

	// Check for min players
	if(zp_get_alive_players() < get_pcvar_num(cvar_minplayers))
		return ZP_PLUGIN_HANDLED

	return PLUGIN_CONTINUE;
}

// Auto Selecting Gamemode
public zp_round_started_pre(game) {
	if(game != g_gameid)
		return PLUGIN_CONTINUE
	
	// Check for min players
	if(zp_get_alive_players() < get_pcvar_num(cvar_minplayers))
		return ZP_PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

// Round Start
public zp_round_started(game, id) {
	// Check if it is our game mode
	if(game != g_gameid)
		return;
	
	// Show HUD notice
	set_hudmessage(221, 156, 21, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "CANNIBAL_START")

	static id, iZombieHP
	iZombieHP = get_pcvar_num(cvar_zombie_health)
	// Turn every Terrorist into a zombie
	for (id = 1; id <= MaxClients; id++) {
		// Not alive
		if (!is_user_alive(id))
			continue;
		
		// Turn into a zombie
		zp_force_user_class(id, 0, 1)
		set_user_health(id, iZombieHP)
		user_kills[id] = 0
	}
	RemoveGrenade()
	server_cmd("mp_freeforall 1")
	server_cmd("mp_round_infinite bcdefg")
	Check_Alive()
	set_task(2.0, "Check_HP", TASK_CHECK_HP, _, _, "b")
}

public zp_player_spawn_post(id)  {
	user_kills[id] = 0
}

public Check_HP() {
	if(!IsCannibalRound()) {
		remove_task(TASK_CHECK_HP)
		return;
	}

	static id, iMaxHPNemesis, iMaxHPZombie, iUserHealth, bUserNemesis
	iMaxHPNemesis = get_pcvar_num(cvar_nemesis_health)
	iMaxHPZombie = get_pcvar_num(cvar_zombie_health)

	// Turn every Terrorist into a zombie
	for (id = 1; id <= MaxClients; id++) {
		if(!is_user_alive(id))
			continue

		iUserHealth = get_user_health(id) 
		bUserNemesis = zp_get_user_nemesis(id)
		if(iUserHealth > iMaxHPNemesis && bUserNemesis)
			set_user_health(id, iMaxHPNemesis)
		
		else if(iUserHealth > iMaxHPZombie && !bUserNemesis)
			set_user_health(id, iMaxHPZombie)
			
		if(!zp_get_user_zombie(id))
			zp_force_user_class(id, 0, 1)
	}		
}

// End Round
public zp_round_ended(winteam) {
	if(zp_get_last_mode() != g_gameid) 
		return;

	remove_task(TASK_CHECK_HP)
	server_cmd("mp_freeforall 0")
	server_cmd("humans_join_team any")
	server_cmd("mp_round_infinite 0")
}

public Check_Alive() {
	if(!IsCannibalRound())
		return;

	if(zp_get_alive_players() > 1) 
		set_task(2.0, "Check_Alive")
	else {
		static name[32], id, iApWinner
		iApWinner = get_pcvar_num(cvar_ap_winner)
		for (id = 1; id <= MaxClients; id++) {
			if(is_user_alive(id)) {
				get_user_name(id, name, charsmax(name))
				zp_add_user_ammopacks(id, iApWinner)
				client_print_color(0, print_team_default, "%L %L", LANG_PLAYER, "CANNIBAL_PREFIX", LANG_PLAYER, "CANNIBAL_WINNER", name, iApWinner)
				break;
			}
		}
		server_cmd("mp_freeforall 0")
		server_cmd("humans_join_team any")
		server_cmd("mp_round_infinite 0")
		server_cmd("endround")
	}
}
public fw_PlayerKilled_Post(victim, killer) {	
	if(killer == victim || !is_user_connected(victim) || !is_user_connected(killer))
		return HAM_IGNORED
	
	if(!zp_get_user_zombie(victim) || !zp_get_user_zombie(killer) || zp_get_user_nemesis(killer))
		return HAM_IGNORED
		
	static Nick[32], kill_evo
	kill_evo = get_pcvar_num(cvar_kill_for_evolute)

	if(user_kills[killer] >= kill_evo) {
		get_user_name(killer, Nick, charsmax(Nick))
		zp_force_user_class(killer, NEMESIS, 1, 0, 0)
		set_user_health(killer, get_pcvar_num(cvar_nemesis_health))
		client_print_color(0, print_team_default, "%L %L", LANG_PLAYER, "CANNIBAL_PREFIX", LANG_PLAYER, "CANNIBAL_EVOLUTION", Nick, kill_evo)
	}
	else user_kills[killer]++

	return HAM_IGNORED

}
public RemoveGrenade() {
	static iEnt; iEnt = -1
	while((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", "grenade")) != 0) {
		if(pev_valid(iEnt))	engfunc(EngFunc_RemoveEntity, iEnt);
	}
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type) {
	if(!is_user_valid_connected(attacker))
		return HAM_IGNORED
	
	if(!IsCannibalRound() || zp_has_round_ended())
		return HAM_IGNORED

	// Get damage result
	static Float:flDamageResult 
	flDamageResult = (zp_get_user_nemesis(attacker)) ? get_pcvar_float(cvar_nem_dmg) : damage

	ExecuteHam(Ham_TakeDamage, victim, 0, attacker, flDamageResult, damage_type)

	static Float: end[3] 
	get_tr2(tracehandle, TR_vecEndPos, end); 
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE) 
	engfunc(EngFunc_WriteCoord, end[0]) 
	engfunc(EngFunc_WriteCoord, end[1]) 
	engfunc(EngFunc_WriteCoord, end[2]) 
	write_short(spr_blood_spray) 
	write_short(spr_blood_drop) 
	write_byte(247)
	write_byte(random_num(5, 10))
	message_end() 
	
	// Stop here
	return HAM_SUPERCEDE;
}

public zp_extra_item_selected_pre(id, itemid) {
	if(IsCannibalRound())
		return ZP_PLUGIN_SUPERCEDE;

	return PLUGIN_CONTINUE
}

//----------------[Stocks]-----------------------------
stock set_user_health(index, health) {
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index);
	return 1;
}
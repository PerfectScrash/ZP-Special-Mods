/***************************************************************************\
		   ========================================
			* || [ZPSp] Game Mode: Hot potato || *
		   ========================================

	-------------------
	 *||DESCRIPTION||*
	-------------------

	--- X players are choosed to turn zombies and have some time to hit other humans with grenade and cure yourself before time ends,
		mode ends when remaing one human.

	-------------------
	 *||REQUERIMENTS||*
	-------------------
	- Zombie Plague Special 4.5 (Final Version)
	- ReHLDS
	- Amx 1.9 or higher

	-------------
	 *||CVARS||*
	-------------

	- zp_hotpotato_mode_minplayers 2
		- Minimum players required for this game mode to begin

	- zp_hotpotato_mode_winner_ap 50
		- Reward for winner of hotpotato mode
		  	
\***************************************************************************/

#include <amxmodx>
#include <cstrike>
#include <engine>
#include <hamsandwich>
#include <zombie_plague_special>
#include <amx_settings_api>

#if ZPS_INC_VERSION < 45
	#assert Zombie Plague Special 4.5 or higher Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

/*-------------[Basic Configuration]--------------------------*/
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


#define TENSION_SOUND_ENABLE 1
new const tension_sound[][] = { "ScrashMods/tag_tension_sound.wav" }

// Flag Acess
#define DEFAULT_FLAG_ACESS ADMIN_IMMUNITY 	// Flag Acess mode

// Chance of 1 in X to start
new const g_chance = 90

//----------------[End of Basic configuration]------------------------
// Variables
new g_gameid, cvar_minplayers, g_msg_sync, g_Countdown, exp_spr_id, ap_rwd, cvar_hotpotato_ap_winner
new Array:g_sound_tension, g_tension_enable

// Defines
#define TASK_COUNTDOWN 1231223
#define TASK_SELECT 1239120
#define IsHotpotatoRound() (zp_get_current_mode() == g_gameid) 
#define NADE_TYPE_INFECTION 1111

//------------------[Plugin Register]---------------------
public plugin_init() {
	register_plugin("[ZPSp] Game mode: Hot Potato Mode","1.0", "[P]erfec[T] [S]cr[@]s[H]")
	register_dictionary("zpsp_misc_modes.txt")
	
	// Cvars
	cvar_minplayers = register_cvar("zp_hotpotato_mode_minplayers", "2")
	cvar_hotpotato_ap_winner = register_cvar("zp_hotpotato_mode_winner_ap", "50")

	// Events
	register_touch("grenade", "*", "fw_Touch")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Pre");
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Pre");
	
	// Hud stuff
	g_msg_sync = CreateHudSyncObj()
}
//------------------[Natives]---------------------
public plugin_natives()
	register_native("zp_is_hotpotato_round", "native_is_hotpotato_round");

public native_is_hotpotato_round(plugin_id, num_params)
	return (IsHotpotatoRound());

//------------------[Load Configuration and download files]-----------------
public plugin_precache() {
	// Read the access flag
	static i, buffer[250]
	g_sound_tension = ArrayCreate(64, 1)

	// Tension Sound
	g_tension_enable = TENSION_SOUND_ENABLE
	if(!amx_load_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "HOT-POTATO TENSION SOUND ENABLE", g_tension_enable))
		amx_save_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "HOT-POTATO TENSION SOUND ENABLE", g_tension_enable)

	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "HOT-POTATO TENSION SOUNDS", g_sound_tension)
	
	// Save to external file
	if (ArraySize(g_sound_tension) == 0) {
		for (i = 0; i < sizeof tension_sound; i++)
			ArrayPushString(g_sound_tension, tension_sound[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "HOT-POTATO TENSION SOUNDS", g_sound_tension)
	}
	// Tension Sound
	if (g_tension_enable) {
		for (i = 0; i < ArraySize(g_sound_tension); i++) {
			ArrayGetString(g_sound_tension, i, buffer, charsmax(buffer))
			precache_ambience(buffer)
		}
	}
	exp_spr_id = precache_model("sprites/zerogxplode.spr") // Explosao

	// Register our game mode
	g_gameid = zpsp_register_gamemode("Hot-Potato", DEFAULT_FLAG_ACESS, g_chance, 0, ZP_DM_NONE, .uselang=1, .langkey="HOTPOTATO_MODNAME")

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
	// Check if it is our game mode
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
	ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "HOTPOTATO_START")

	set_task(0.1, "Hotpotato_Select", TASK_SELECT);
	server_cmd("mp_round_infinite abf");
	engclient_cmd(0, "weapon_knife")
}

// End Round
public zp_round_ended(winteam) {
	// Remove tasks
	remove_task(TASK_COUNTDOWN)
	remove_task(TASK_SELECT)

	if(zp_get_last_mode() == g_gameid)
		server_cmd("mp_round_infinite 0");
	
}
// Hotpotato Mode Winner
public announce_winner() {
	static winner, i;
	winner = 0;

	for(i = 1; i <= MaxClients; i++) {
		if(is_user_alive(i)) {
			winner = i;
			break;
		}
	}

	if(winner) {
		static name[32]; get_user_name(winner, name, charsmax(name))
		ap_rwd = get_pcvar_num(cvar_hotpotato_ap_winner)
		zp_add_user_ammopacks(winner, ap_rwd)
		client_print_color(0, print_team_default, "%L %L", LANG_PLAYER, "HOTPOTATO_PREFIX", LANG_PLAYER, "HOTPOTATO_WINNER", name, ap_rwd)
	}

	//rg_round_end(5.0, WINSTATUS_CTS, ROUND_NONE, "")
	server_cmd("mp_round_infinite 0");
	server_cmd("endround");
}

// Selecting Players for turn into zombie
public Hotpotato_Select() {

	if(!IsHotpotatoRound())
		return;

	static alive_count, iMaxZombies, iZombieNum, iMaxTime;
	alive_count = zp_get_alive_players();

	switch(alive_count) {
		case 1: {
			announce_winner();
			return;
		}
		case 2,3: iMaxZombies = 1, iMaxTime = 20;
		case 4: iMaxZombies = 2, iMaxTime = 16;
		case 5..11: iMaxZombies = 3, iMaxTime = 14;
		case 12..17: iMaxZombies = 4, iMaxTime = 11;
		case 18..21: iMaxZombies = 5, iMaxTime = 9;
		case 22..27: iMaxZombies = 6, iMaxTime = 6;
		case 28..32: iMaxZombies = 7, iMaxTime = 3;
		default: return;
	}

	static id
	iZombieNum = 0;
	while (iZombieNum < iMaxZombies)
	{
		// Choose random guy
		id = zp_get_random_player(GET_HUMAN)
		
		// Dead or already a zombie
		if (!is_user_alive(id) || zp_get_user_zombie(id))
			continue;
		
		// Turn into a zombie
		zp_infect_user(id);
		iZombieNum++;
	}
	g_Countdown = iMaxTime + 20;
	set_task(1.0, "Count", TASK_COUNTDOWN, _, _, "b");
	client_print_color(0, print_team_default, "%L %L", LANG_PLAYER, "HOTPOTATO_PREFIX", LANG_PLAYER, "HOTPOTATO_CHOOSED", iZombieNum, iMaxTime+20);
}

// Explode Zombies
public explode_zombies() {
	if(!IsHotpotatoRound())
		return;

	static id, Origin[3]
	for (id = 1; id <= MaxClients; id++) {
		// Only those of them who aren't zombies
		if (!is_user_alive(id))
			continue;

		if(!zp_get_user_zombie(id))
			continue;
	
		// Make him explode
		user_kill(id, 0)

		get_user_origin(id, Origin)
		message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
		write_byte(TE_EXPLOSION)
		write_coord(Origin[0])
		write_coord(Origin[1])
		write_coord(Origin[2])
		write_short(exp_spr_id)   // sprite index
		write_byte(20)   // scale in 0.1's
		write_byte(30)   // framerate
		write_byte(0)   // flags
		message_end()
	}
	set_task(5.0, "Hotpotato_Select", TASK_SELECT);
}

// Knifes/Grenades Only in Hotpotato Mode
public zp_fw_deploy_weapon(id, wpnid) {
	if (!is_user_alive(id) || !IsHotpotatoRound())
		return PLUGIN_HANDLED;
	
	if (wpnid != CSW_HEGRENADE && zp_get_user_zombie(id))
		engclient_cmd(id, "weapon_hegrenade")
	else if (wpnid != CSW_KNIFE)
		engclient_cmd(id, "weapon_knife")
	
	return PLUGIN_HANDLED
}

// Block damage
public fw_TraceAttack_Pre(victim, attacker, Float:damage, Float:direction[3], traceresult, damagebits) {
	if(IsHotpotatoRound())
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}
public fw_TakeDamage_Pre(victim, inflictor, attacker, Float:damage, damagebits) {
	if(IsHotpotatoRound())
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

// Countdown
public Count() {
	if(!IsHotpotatoRound()) {
		remove_task(TASK_COUNTDOWN)
		return;
	}

	if(g_Countdown <= 15) {
		if(g_tension_enable) {
			if(g_Countdown == 12 && ArraySize(g_sound_tension)) {
				static sound[100]
				ArrayGetString(g_sound_tension, random_num(0, ArraySize(g_sound_tension) - 1), sound, charsmax(sound))
				zp_play_sound(0, sound)
			}
		}

		static szCount[32], i;
		szCount = ""
		for(i = 0; i < g_Countdown; i++)
			strcat(szCount, "*", charsmax(szCount));

		set_hudmessage(0, 180, 255, -1.0, 0.28, 2, 0.02, 1.0, 0.01, 0.1, 10)

		if(g_Countdown <= 0) {
			remove_task(TASK_COUNTDOWN)
			explode_zombies()
			ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "HOTPOTATO_EXPLODES")
		}
		else ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "HOTPOTATO_COUNTDOWN", g_Countdown, szCount)
	}

	g_Countdown--
}

// Infected Action
public zp_user_infected_post(victim, attacker) {
	if(!IsHotpotatoRound())
		return;
	
	zp_force_user_class(attacker, 0, 0)
	zp_give_item(victim, "weapon_hegrenade");
	cs_set_user_bpammo(victim, CSW_HEGRENADE, 200)
}

public zp_infected_by_bomb_pre(victim, attacker) {
	if(!IsHotpotatoRound())
		return PLUGIN_CONTINUE;

	if(!is_user_alive(attacker) || !is_user_alive(victim) || victim == attacker)
		return ZP_PLUGIN_SUPERCEDE;

	if(!zp_get_user_zombie(victim) && zp_get_user_zombie(attacker))
		zp_force_user_class(victim, 0, 1, attacker, 0)

	return ZP_PLUGIN_SUPERCEDE;
}

// For Don't kill Last human 
public fw_Touch(grenade, victim) {
	if(!is_valid_ent(grenade) || !IsHotpotatoRound()) 
		return
	
	if(entity_get_int(grenade, EV_INT_flTimeStepSound) != NADE_TYPE_INFECTION)
		return;

	static attacker;
	attacker = entity_get_edict(grenade, EV_ENT_owner);

	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return;
	
	if (!zp_get_user_zombie(victim)) {
		zp_force_user_class(victim, 0, 1, attacker, 0)

		if(is_valid_ent(grenade)) 
			remove_entity(grenade)
	}
}
// Block extra itens
public zp_extra_item_selected_pre(id, itemid) {
	if(IsHotpotatoRound())
		return ZP_PLUGIN_SUPERCEDE;

	return PLUGIN_CONTINUE
}

//----------------[Stocks]-----------------------------
// Ambience Precache
precache_ambience(sound[]) {
	static buffer[150]
	if(equal(sound[strlen(sound)-4], ".mp3")) {
		if(!equal(sound, "sound/", 6) && !file_exists(sound) && !equal(sound, "media/", 6))
			format(buffer, charsmax(buffer), "sound/%s", sound)
		else
			format(buffer, charsmax(buffer), "%s", sound)
		
		precache_generic(buffer)
	}
	else  {
		if(equal(sound, "sound/", 6)) format(buffer, charsmax(buffer), "%s", sound[6])
		else format(buffer, charsmax(buffer), "%s", sound)
		
		precache_sound(buffer)
	}
}
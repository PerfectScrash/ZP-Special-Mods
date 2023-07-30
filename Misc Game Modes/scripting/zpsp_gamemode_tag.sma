/***************************************************************************\
		   ========================================
			* || [ZPSp] Game Mode: Tag Mode || *
		   ========================================

	-------------------
	 *||DESCRIPTION||*
	-------------------

	--- X players are choosed to turn zombies and have some time to infect other humans and cure yourself before time ends,
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

	- zp_tag_mode_minplayers 2
		- Minimum players required for this game mode to begin

	- zp_tag_mode_winner_ap 50
		- Reward for winner of tag mode
		  	
	-------------------
	 *||Change Log||*
	-------------------
	* 1.0:
		- First Releaase

	* 1.1:
		- Fix Server crashes when use "engclient_cmd" in bots

	* 1.2:
		- Fix Bug when last player in some teams are disconnected/killed

\***************************************************************************/

#include <amxmodx>
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
new g_gameid, cvar_minplayers, g_msg_sync, g_Countdown, exp_spr_id, ap_rwd, cvar_tag_ap_winner, exploding
new Array:g_sound_tension, g_tension_enable

// Defines
#define TASK_COUNTDOWN 1231223
#define TASK_SELECT 1239120
#define IsTagRound() (zp_get_current_mode() == g_gameid) 

//------------------[Plugin Register]---------------------
public plugin_init() {
	register_plugin("[ZPSp] Game mode: Tag Mode", "1.2", "[P]erfec[T] [S]cr[@]s[H]")
	register_dictionary("zpsp_misc_modes.txt")
	
	// Cvars
	cvar_minplayers = register_cvar("zp_tag_mode_minplayers", "2")
	cvar_tag_ap_winner = register_cvar("zp_tag_mode_winner_ap", "50")

	// Events
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack");
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	
	// Hud stuff
	g_msg_sync = CreateHudSyncObj()
}

//------------------[Natives]---------------------
public plugin_natives()
	register_native("zp_is_tag_round", "native_is_tag_round");

public native_is_tag_round(plugin_id, num_params)
	return (IsTagRound());

//------------------[Load Configuration and download files]-----------------
public plugin_precache() {
	// Read the access flag
	static i, buffer[250]
	g_sound_tension = ArrayCreate(64, 1)

	// Tension Sound
	g_tension_enable = TENSION_SOUND_ENABLE
	if(!amx_load_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "TAG TENSION SOUND ENABLE", g_tension_enable))
		amx_save_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "TAG TENSION SOUND ENABLE", g_tension_enable)

	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "TAG TENSION SOUNDS", g_sound_tension)
	
	// Save to external file
	if (ArraySize(g_sound_tension) == 0) {
		for (i = 0; i < sizeof tension_sound; i++)
			ArrayPushString(g_sound_tension, tension_sound[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "TAG TENSION SOUNDS", g_sound_tension)
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
	g_gameid = zpsp_register_gamemode("Tag", DEFAULT_FLAG_ACESS, g_chance, 1, ZP_DM_NONE, .uselang=1, .langkey="TAG_MODNAME")

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
public zp_round_started(game) {
	// Check if it is our game mode
	if(game != g_gameid)
		return;
	
	for(new id = 0; id <= MaxClients; id++) {
		if(!is_user_alive(id))
			continue;

		if(is_user_bot(id)) {
			zp_strip_user_weapons(id)
			zp_give_item(id, "weapon_knife")
		}
		else
			engclient_cmd(id, "weapon_knife")
	}

	// Show HUD notice
	set_hudmessage(221, 156, 21, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "TAG_START")

	set_task(0.1, "Tag_Select", TASK_SELECT);
	server_cmd("mp_round_infinite abf");
}

// End Round
public zp_round_ended(winteam) {
	// Remove tasks
	remove_task(TASK_COUNTDOWN)
	remove_task(TASK_SELECT)

	if(zp_get_last_mode() == g_gameid)
		server_cmd("mp_round_infinite 0");
	
}
// Tag Mode Winner
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
		if(zp_get_user_zombie(winner))
			zp_force_user_class(winner, 0, 0) // Disinfect Winner

		static name[32]; get_user_name(winner, name, charsmax(name))
		ap_rwd = get_pcvar_num(cvar_tag_ap_winner)
		zp_add_user_ammopacks(winner, ap_rwd)
		client_print_color(0, print_team_default, "%L %L", LANG_PLAYER, "TAG_PREFIX", LANG_PLAYER, "TAG_WINNER", name, ap_rwd)
	}

	//rg_round_end(5.0, WINSTATUS_CTS, ROUND_NONE, "")
	server_cmd("mp_round_infinite 0");
	server_cmd("endround");
}

// Fix bug when remain some player disconected
public client_disconnected(id) check_round();

// Fix bug when remain some player get slayed/killed
public fw_PlayerKilled_Post(victim, attacker) check_round();

// Check Round to fix some bugs
public check_round() {
	if(exploding) // Prevent lag when exploding zombies
		return;

	static count_h, count_z, alive_count, i;
	count_h = 0; count_z = 0; alive_count = 0
	for(i = 1; i <= MaxClients; i++) {
		if(!is_user_alive(i))
			continue;

		alive_count++

		if(zp_get_user_zombie(i)) {
			count_z++
			continue;
		}
		count_h++
	}

	if(alive_count <= 1) {
		remove_task(TASK_COUNTDOWN)
		remove_task(TASK_SELECT)
		announce_winner()
	}
	else if(count_z < 1 && count_h > 1) {
		remove_task(TASK_COUNTDOWN)
		remove_task(TASK_SELECT)
		client_print_color(0, print_team_default, "%L %L", LANG_PLAYER, "TAG_PREFIX", LANG_PLAYER, "TAG_LASTDISCONECT");
		set_task(2.0, "Tag_Select", TASK_SELECT);
	}
	else if(count_h <= 0 && count_z > 1) {
		for(i = 1; i <= MaxClients; i++) {
			if(!is_user_alive(i))
				continue;

			if(zp_get_user_zombie(i))
				zp_force_user_class(i, 0, 0)
		}
		remove_task(TASK_COUNTDOWN)
		remove_task(TASK_SELECT)
		client_print_color(0, print_team_default, "%L %L", LANG_PLAYER, "TAG_PREFIX", LANG_PLAYER, "TAG_LASTDISCONECT");
		set_task(2.0, "Tag_Select", TASK_SELECT);
	}
}

// Selecting Players for turn into zombie
public Tag_Select() {

	if(!IsTagRound())
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
	client_print_color(0, print_team_default, "%L %L", LANG_PLAYER, "TAG_PREFIX", LANG_PLAYER, "TAG_CHOOSED", iZombieNum, iMaxTime+20);
}

// Explode Zombies
public explode_zombies() {
	if(!IsTagRound())
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

	exploding = false
	set_task(5.0, "Tag_Select", TASK_SELECT);
}

// Knifes Only in Tag Mode
public zp_fw_deploy_weapon(id, wpnid) {
	if (!is_user_alive(id) || !IsTagRound())
		return PLUGIN_HANDLED;
	
	if (wpnid != CSW_KNIFE && !zp_get_user_zombie(id)) {
		if(is_user_bot(id)) {
			zp_strip_user_weapons(id)
			zp_give_item(id, "weapon_knife")
		}
		else
			engclient_cmd(id, "weapon_knife")
	}
	
	return PLUGIN_HANDLED
}

// Countdown
public Count() {
	if(!IsTagRound()) {
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
			exploding = true
			explode_zombies()
			ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "TAG_EXPLODES")
		}
		else ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "TAG_COUNTDOWN", g_Countdown, szCount)
	}

	g_Countdown--
}

// Infected Action
public zp_user_infected_post(id, attacker) {
	if(!IsTagRound() || id == attacker)
		return;
	
	if(!is_user_alive(attacker) || !is_user_alive(id))
		return;

	zp_set_user_frozen(id, SET_WITHOUT_IMMUNIT)
	zp_force_user_class(attacker, 0, 0)
}

// For Don't kill Last human 
public fw_TraceAttack(victim, attacker) {
	// Non-player damage or self damage
	if (victim == attacker || !IsTagRound() || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	if (zp_get_user_last_human(victim)) {
		zp_force_user_class(victim, 0, 1, attacker, 0)
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}
// Block extra itens
public zp_extra_item_selected_pre(id, itemid) {
	if(IsTagRound())
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
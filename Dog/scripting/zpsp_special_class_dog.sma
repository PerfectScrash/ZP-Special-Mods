/*
		[ZPSp] Special Class: Dog

		* Description:
			Dog are smaller and furious (Walk like zombie crawler), humans can kill with knife only (In Dog Rounds)

		* Cvars:
			zp_dog_minplayers "2" - Min Players for start a Dog round
			zp_dog_damage_multi "2" - Knife damage multi for Dog

		* Change Log:
			* 1.0:
				- First Release

			* 1.1:
				- Fixed Ambience Sound
				- Optimized Code

			-- 20/12 Fix: Fixed Error log on "event_round_started"

			* 1.2:
				- ZPSp 4.5 Full support


*/

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <zombie_plague_special>
#include <amx_settings_api>

#if ZPS_INC_VERSION < 45
	#assert Zombie Plague Special 4.5 Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

/*-------------------------------------
--> Class Configs
--------------------------------------*/
#define Make_Acess ADMIN_IMMUNITY 	// Flag Acess make

new const sp_name[] = "Dog"
new const sp_model[] = "zp_dog"
new const sp_knifemodel[] = "models/zombie_plague/v_knife_dog.mdl"
new const sp_painsound[] = "zombie_plague/nemesis_pain1.wav"
new const sp_hp = 5000
new const sp_speed = 975
new const Float:sp_gravity = 0.6
new const sp_aura_size = 0
new const Float:sp_knockback = 0.25
new const sp_allow_glow = 1
new sp_color_rgb[3] =  { 0, 255, 255 }

new const sp_death_sounds[][] = {
	"zombie_plague/zombie_die1.wav", 
	"zombie_plague/zombie_die2.wav", 
	"zombie_plague/zombie_die3.wav", 
	"zombie_plague/zombie_die4.wav", 
	"zombie_plague/zombie_die5.wav"
}

/*-------------------------------------
--> Gamemode Config
--------------------------------------*/
new const g_chance = 90						// Gamemode chance
#define Start_Mode_Acess ADMIN_IMMUNITY

/*-------------------------------------
--> Ambience/Round Sound Config
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
	"zombie_plague/nemesis1.wav"
}

/*-------------------------------------
--> Variables/Defines
--------------------------------------*/
new g_gameid, g_msg_sync, cvar_minplayers, cvar_dog_damage, g_special_id, crounched[33]

#define GetUserDog(%1) (zp_get_zombie_special_class(%1) == g_special_id) 
#define IsDogMode() (zp_get_current_mode() == g_gameid)

/*-------------------------------------
--> Plugin registeration.
--------------------------------------*/
public plugin_init() {
	register_plugin("[ZPSp] Special Class: Dog", "1.2", "[P]erfec[T] [S]cr[@]s[H]")
	
	cvar_minplayers = register_cvar("zp_dog_minplayers", "2")
	cvar_dog_damage = register_cvar("zp_dog_damage_multi", "2.0")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	
	g_msg_sync = CreateHudSyncObj()
}

/*-------------------------------------
--> Plugin Precache
--------------------------------------*/
public plugin_precache() {
	g_gameid = zpsp_register_gamemode(sp_name, Start_Mode_Acess, g_chance, 0, 0)
	g_special_id = zp_register_zombie_special(sp_name, sp_model, sp_knifemodel, sp_painsound, sp_hp, sp_speed, sp_gravity, Make_Acess, sp_knockback, sp_aura_size, sp_allow_glow, sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2])
	
	static i
	// Register round start sound
	for(i = 0; i < sizeof gamemode_round_start_snd; i++)
		zp_register_start_gamemode_snd(g_gameid, gamemode_round_start_snd[i])

	// Register ambience sounds
	for (i = 0; i < sizeof gamemode_ambiences; i++)
		zp_register_gamemode_ambience(g_gameid, gamemode_ambiences[i][AmbiencePrecache], gamemode_ambiences[i][AmbienceDuration], ambience_enable)

	// Register Class Death sound
	for (i = 0; i < sizeof sp_death_sounds; i++)
		zp_register_zmspecial_deathsnd(g_special_id, sp_death_sounds[i])
}


/*-------------------------------------
--> Natives
--------------------------------------*/
public plugin_natives() {
	register_native("zp_get_user_dog", "native_get_user_dog")
	register_native("zp_make_user_dog", "native_make_user_dog")
	register_native("zp_get_dog_count", "native_get_dog_count")
	register_native("zp_is_dog_round", "native_is_dog_round")
}

// Native: zp_get_user_dog(id)
public native_get_user_dog(plugin_id, num_params) 
	return GetUserDog(get_param(1));

// Native: zp_make_user_dog(id)
public native_make_user_dog(plugin_id, num_params) 
	return (zp_make_user_special(get_param(1), g_special_id, GET_ZOMBIE));

// Native: zp_get_dog_count()
public native_get_dog_count(plugin_id, num_params)
	return zp_get_special_count(GET_ZOMBIE, g_special_id);

// Native: zp_is_dog_round()
public native_is_dog_round(plugin_id, num_params)
	return IsDogMode();

/*-------------------------------------
--> Class Functions
--------------------------------------*/
// Attack Damage
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if(!is_user_connected(victim) || !is_user_connected(attacker))
		return HAM_IGNORED
	
	if(inflictor == attacker && GetUserDog(attacker))
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_dog_damage))
		
	return HAM_IGNORED
}


public zp_user_infected_post(id) {
	if(GetUserDog(id)) {
		if(!zp_has_round_started())
			zp_set_custom_game_mod(g_gameid)
		
		if(is_user_bot(id))	// Make Bots move more slow (Force crounch in bots not works yet)
			zp_set_user_maxspeed(id, 325.0)

		crounched[id] = true
	}
	else {
		if(crounched[id]) unduck_player(id) // Remove Force crounch
	}
}
	
// Forward Player PreThink
public fw_PlayerPreThink(id) {
	if(!is_user_alive(id))
		return;

	if(!zp_get_user_zombie(id) || !GetUserDog(id) || is_user_bot(id) || !crounched[id])
		return;
	
	// Forces the player crouch
	set_pev(id, pev_bInDuck, 1)
	client_cmd(id, "+duck")
}

// Ham Player Killed Forward
public fw_PlayerKilled(id)
	if(crounched[id]) unduck_player(id);

// Converted to human (normal or special)
public zp_user_humanized_post(id)
	if(crounched[id]) unduck_player(id);

// Remove force crounch
public unduck_player(id) {
	if(is_user_bot(id) || !crounched[id])
		return
	
	if(crounched[id]) {
		set_pev(id, pev_bInDuck, 0)
		client_cmd(id, "-duck")
		client_cmd(id, "-duck") // Prevent death spectator camera bug
		crounched[id] = false
	}
}

/*-------------------------------------
--> Gamemode Functions
--------------------------------------*/
public zp_extra_item_selected_pre(id, itemid) {
	if(GetUserDog(id) || IsDogMode())
		return ZP_PLUGIN_SUPERCEDE
	
	return PLUGIN_CONTINUE
}

// Knifes Only in Dog Round
public zp_fw_deploy_weapon(id, wpnid) {
	if(!is_user_alive(id) || !IsDogMode())
		return PLUGIN_HANDLED;
	
	if(wpnid != CSW_KNIFE && !zp_get_user_zombie(id))
		engclient_cmd(id, "weapon_knife")
	
	return PLUGIN_HANDLED
}

// Player spawn post
public zp_player_spawn_post(id) {
	// Check for current mode
	if(IsDogMode())
		zp_disinfect_user(id)
	
	// Remove force crounch of dog
	if(crounched[id])
		unduck_player(id)
}

public zp_round_started_pre(game) {
	// Check if it is our game mode
	if(game != g_gameid)
		return PLUGIN_CONTINUE
	
	// Check for min players
	if(zp_get_alive_players() < get_pcvar_num(cvar_minplayers))
		return ZP_PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public zp_round_started(game, id) {
	// Check if it is our game mode
	if(game == g_gameid)
		start_dog_mode()
}

// This function contains the whole code behind this game mode
start_dog_mode() {
	static id, i, has_dog
	has_dog = false
	for (i = 1; i <= MaxClients; i++) {
		if(!is_user_alive(i))
			continue
	
		if(!GetUserDog(i))
			continue
		
		id = i	// Get Dog Index
		has_dog = true
		break;
	}

	if(!has_dog) {
		id = zp_get_random_player()
		zp_make_user_special(id, g_special_id, GET_ZOMBIE)
	}
	
	static name[32]; get_user_name(id, name, charsmax(name));
	set_hudmessage(sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2], -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync, "%s is a %s", name, sp_name)

	ScreenFade(0, 5, sp_color_rgb, 255)
	engclient_cmd(0, "weapon_knife")
}

/*-------------------------------------
--> Stocks
--------------------------------------*/
stock ScreenFade(id, Timer, Colors[3], Alpha) {
	if(!is_user_connected(id) && id)
		return;

	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, get_user_msgid("ScreenFade"), _, id);
	write_short((1<<12) * Timer)
	write_short(1<<12)
	write_short(0)
	write_byte(Colors[0])
	write_byte(Colors[1])
	write_byte(Colors[2])
	write_byte(Alpha)
	message_end()
} 
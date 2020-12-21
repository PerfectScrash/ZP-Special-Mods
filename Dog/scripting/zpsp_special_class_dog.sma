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


*/

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <zombie_plague_special>
#include <amx_settings_api>

#if ZPS_INC_VERSION < 43
	#assert Zombie Plague Special 4.3 Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

new const ZP_CUSTOMIZATION_FILE[] = "zombie_plague_special.ini"

new Array:g_sound_dog, g_ambience_sounds, Array:g_sound_amb_dog_dur, Array: g_sound_ambience_dog

// Default Sounds
new const sound_dog[][] = { "zombie_plague/nemesis1.wav" }
new const ambience_dog_sound[][] = { "zombie_plague/ambience.wav" } 
new const ambience_dog_dur[][] = { "17" }

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
new const sp_color_r =  0
new const sp_color_g = 255
new const sp_color_b = 255
new acess_flags[2]

// Variables
new g_gameid, g_msg_sync, cvar_minplayers, cvar_dog_damage, g_speciald, crounched[33], g_maxplayers
new const g_chance = 90

// Ambience sounds task
#define TASK_AMB 3256

public plugin_init()
{
	// Plugin registeration.
	register_plugin("[ZP] Class Dog","1.1", "[P]erfec[T] [S]cr[@]s[H]")
	
	cvar_minplayers = register_cvar("zp_dog_minplayers", "2")
	cvar_dog_damage = register_cvar("zp_dog_damage_multi", "2")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	//register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	
	g_msg_sync = CreateHudSyncObj()
	g_maxplayers = get_maxplayers()
}


// Game modes MUST be registered in plugin precache ONLY
public plugin_precache()
{
	// Read the access flag
	new user_access[40]
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE DOG", user_access, charsmax(user_access))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE DOG", "a")
		formatex(user_access, charsmax(user_access), "a")
	}
	acess_flags[0] = read_flags(user_access)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "MAKE DOG", user_access, charsmax(user_access))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "MAKE DOG", "a")
		formatex(user_access, charsmax(user_access), "a")
	}
	acess_flags[1] = read_flags(user_access)

	new i

	g_sound_dog = ArrayCreate(64, 1)
	g_sound_ambience_dog = ArrayCreate(64, 1)
	g_sound_amb_dog_dur = ArrayCreate(64, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND DOG", g_sound_dog)
	
	// Precache the play sounds
	if (ArraySize(g_sound_dog) == 0)
	{
		for (i = 0; i < sizeof sound_dog; i++)
			ArrayPushString(g_sound_dog, sound_dog[i])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND DOG", g_sound_dog)
	}
	
	// Precache sounds
	new sound[100]
	for (i = 0; i < ArraySize(g_sound_dog); i++)
	{
		ArrayGetString(g_sound_dog, i, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else precache_sound(sound)
	}
	
	// Ambience Sounds
	g_ambience_sounds = 0
	if(!amx_load_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "DOG ENABLE", g_ambience_sounds))
		amx_save_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "DOG ENABLE", g_ambience_sounds)
	
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "DOG SOUNDS", g_sound_ambience_dog)
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "DOG DURATIONS", g_sound_amb_dog_dur)
	
	
	// Save to external file
	if (ArraySize(g_sound_ambience_dog) == 0) {
		for (i = 0; i < sizeof ambience_dog_sound; i++)
			ArrayPushString(g_sound_ambience_dog, ambience_dog_sound[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "DOG SOUNDS", g_sound_ambience_dog)
	}
	
	if (ArraySize(g_sound_amb_dog_dur) == 0) {
		for (i = 0; i < sizeof ambience_dog_dur; i++)
			ArrayPushString(g_sound_amb_dog_dur, ambience_dog_dur[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "DOG DURATIONS", g_sound_amb_dog_dur)
	}
	
	// Ambience Sounds
	static buffer[250]
	if (g_ambience_sounds) {
		for (i = 0; i < ArraySize(g_sound_ambience_dog); i++) {
			ArrayGetString(g_sound_ambience_dog, i, buffer, charsmax(buffer))
			
			if (equal(buffer[strlen(buffer)-4], ".mp3")) {
				format(buffer, charsmax(buffer), "sound/%s", buffer)
				precache_generic(buffer)
			}
			else precache_sound(buffer)
		}
	}
	
	// Register our game mode
	#if ZPS_INC_VERSION < 44
	g_gameid = zp_register_game_mode(sp_name, acess_flags[0], g_chance, 0, 0)
	#else
	g_gameid = zpsp_register_gamemode(sp_name, acess_flags[0], g_chance, 0, 0)
	#endif

	g_speciald = zp_register_zombie_special(sp_name, sp_model, sp_knifemodel, sp_painsound, sp_hp, sp_speed, sp_gravity, acess_flags[1], sp_knockback, sp_aura_size, sp_allow_glow, sp_color_r, sp_color_g, sp_color_b)
}

public plugin_natives() {
	register_native("zp_get_user_dog", "native_get_user_dog", 1)
	register_native("zp_make_user_dog", "native_make_user_dog", 1)
	register_native("zp_get_dog_count", "native_get_dog_count", 1)
	register_native("zp_is_dog_round", "native_is_dog_round", 1)
}

public zp_extra_item_selected_pre(id, itemid) {
	if(zp_get_zombie_special_class(id) == g_speciald || zp_get_current_mode() == g_gameid)
		return ZP_PLUGIN_SUPERCEDE
	
	return PLUGIN_CONTINUE
}

// Knifes Only in Dog Round
public CurrentWeapon(id) {
	if (!is_user_alive(id) || zp_get_current_mode() != g_gameid)
		return PLUGIN_HANDLED;
	
	if (get_user_weapon(id) != CSW_KNIFE && !zp_get_user_zombie(id))
		engclient_cmd(id, "weapon_knife")
	
	return PLUGIN_HANDLED
}

// Dog damage multi
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if(inflictor == attacker && zp_get_zombie_special_class(attacker) == g_speciald)
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_dog_damage))
}

// Player spawn post
public zp_player_spawn_post(id) {
	// Check for current mode
	if(zp_get_current_mode() == g_gameid)
		zp_disinfect_user(id)
	
	// Remove force crounch of dog
	if(crounched[id]) {
		unduck_player(id)
	}
}

public zp_round_started_pre(game) {
	// Check if it is our game mode
	if(game == g_gameid)
	{
		// Check for min players
		if(zp_get_alive_players() < get_pcvar_num(cvar_minplayers))
			return ZP_PLUGIN_HANDLED

		// Start our new mode
		start_dog_mode()
	}
	return PLUGIN_CONTINUE
}

public zp_round_started(game, id) {
	// Check if it is our game mode
	if(game == g_gameid)
	{
		// Play the starting sound
		static sound[100]
		ArrayGetString(g_sound_dog, random_num(0, ArraySize(g_sound_dog) - 1), sound, charsmax(sound))

		#if ZPS_INC_VERSION < 44
		PlaySoundToClients(sound)
		#else
		zp_play_sound(0, sound)
		#endif
		
		// Remove ambience task affects
		remove_task(TASK_AMB)
		
		// Set task to start ambience sounds
		set_task(2.0, "start_ambience_sounds", TASK_AMB)
	}
}
#if ZPS_INC_VERSION < 44
// Plays a sound on clients
PlaySoundToClients(const sound[]) {
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(0, "spk ^"%s^"", sound)
}
#endif

public zp_game_mode_selected(gameid, id) {
	// Check if our game mode was called
	if(gameid == g_gameid)
		start_dog_mode()
	
	// Make the compiler happy again =)
	return PLUGIN_CONTINUE
}

// This function contains the whole code behind this game mode
start_dog_mode() {
	static id, i, has_dog
	has_dog = false
	for (i = 1; i <= g_maxplayers; i++) {
		if(!is_user_alive(i)) 
			continue;

		if(zp_get_zombie_special_class(i) == g_speciald) {
			id = i
			has_dog = true
		}
	}

	if(!has_dog) {
		id = zp_get_random_player()
		zp_make_user_special(id, g_speciald, GET_ZOMBIE)
	}
	
	static name[32]; get_user_name(id, name, charsmax(name));
	set_hudmessage(sp_color_r, sp_color_g, sp_color_b, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync, "%s is a %s", name, sp_name)

	for (id = 1; id <= g_maxplayers; id++) {
		// Not alive
		if(!is_user_alive(id))
			continue;
			
		if(!zp_get_user_zombie(id))
			engclient_cmd(id, "weapon_knife")

		ScreenFade(id, 5, sp_color_r, sp_color_g, sp_color_b, 255)
	}

}

public start_ambience_sounds()
{
	if (!g_ambience_sounds)
		return;
	
	// Variables
	static amb_sound[64], sound,  str_dur[20]
	
	// Select our ambience sound
	sound = random_num(0, ArraySize(g_sound_ambience_dog)-1)

	ArrayGetString(g_sound_ambience_dog, sound, amb_sound, charsmax(amb_sound))
	ArrayGetString(g_sound_amb_dog_dur, sound, str_dur, charsmax(str_dur))
	
	#if ZPS_INC_VERSION < 44
	PlaySoundToClients(amb_sound)
	#else
	zp_play_sound(0, amb_sound)
	#endif
	
	// Start the ambience sounds
	set_task(str_to_float(str_dur), "start_ambience_sounds", TASK_AMB)
}
public zp_round_ended() {
	remove_task(TASK_AMB)
}

public zp_user_infected_post(id)
{
	if(zp_get_zombie_special_class(id) == g_speciald) 
	{
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
public fw_PlayerPreThink(id)
{
	if(!is_user_alive(id) || is_user_bot(id) || !crounched[id])
		return;

	if (!zp_get_user_zombie(id) || zp_get_zombie_special_class(id) != g_speciald)
		return;
	
	// Forces the player crouch
	set_pev(id, pev_bInDuck, 1)
	client_cmd(id, "+duck")
}

// Ham Player Killed Forward
public fw_PlayerKilled(id) {
	if(crounched[id]) unduck_player(id)
}

public zp_user_humanized_post(id) {
	if(crounched[id]) unduck_player(id)
}

// Remove force crounch
public unduck_player(id)
{
	if(is_user_bot(id) || !crounched[id])
		return
	
	if(crounched[id]) {
		set_pev(id, pev_bInDuck, 0)
		client_cmd(id, "-duck")
		client_cmd(id, "-duck") // Prevent death spectator camera bug
		crounched[id] = false
	}
}

stock ScreenFade(id, Timer, r, g ,b, Alpha) 
{	
	if(!is_user_connected(id)) return;
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, id);
	write_short((1<<12) * Timer)
	write_short(1<<12)
	write_short(0)
	write_byte(r)
	write_byte(g)
	write_byte(b)
	write_byte(Alpha)
	message_end()
}

public native_get_user_dog(id)
	return (zp_get_zombie_special_class(id) == g_speciald)
	
public native_make_user_dog(id)
	return (zp_make_user_special(id, g_speciald, GET_ZOMBIE))
	
public native_get_dog_count()
	return zp_get_special_count(GET_ZOMBIE, g_speciald)
	
public native_is_dog_round()
	return (zp_get_current_mode() == g_gameid)

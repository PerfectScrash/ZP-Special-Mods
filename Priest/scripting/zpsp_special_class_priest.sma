/*
		[ZPSp] Special Class: Priest

		* Description:
			Removes a Demon from Zombie with a Holy Grenade

		* Cvars:
			zp_priest_minplayers "2" - Min Players for start a Priest Mod
			zp_priest_damage_multi "1.5" - Knife Damage Multi

		* Change Log
			* 1.0:
				- First Release

			* 1.1:
				- Fixed Ambience
				- Added p_model
			* 1.2:
				- Fixed Zombie health (Some times zombies have same health as first zombie)
				- Fixed Bug that player sometimes don't turn into plasma when round starts
*/
#include <amxmodx>
#include <hamsandwich>
#include <fakemeta_util>
#include <zombie_plague_special>
#include <amx_settings_api>

#if ZPS_INC_VERSION < 43
	#assert Zombie Plague Special 4.3 Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

new const ZP_CUSTOMIZATION_FILE[] = "zombie_plague_special.ini"

new Array:g_sound_priest, g_ambience_sounds, Array:g_sound_amb_priest_dur, Array: g_sound_ambience_priest

// Default Sounds
new const sound_priest[][] = { "zombie_plague/survivor1.wav" }
new const ambience_priest_sound[][] = { "zombie_plague/ambience.wav" } 
new const ambience_priest_dur[][] = { "17" }

new const sp_name[] = "Priest"
new const sp_model[] = "zp_priest"
new const sp_hp = 7000
new const sp_speed = 280
new const Float:sp_gravity = 0.8
new const sp_aura_size = 15
new const sp_clip_type = 2 // Unlimited Ammo (0 - Disable | 1 - Unlimited Semi Clip | 2 - Unlimited Clip)
new const sp_allow_glow = 1
new const sp_color_r = 100
new const sp_color_g = 100
new const sp_color_b = 255
new acess_flags[2]

new const NADE_TYPE_ANTIDOTEBOMB = 10102
new const Float:RADIUS = 240.0
new const sprite_grenade_trail[] = "sprites/laserbeam.spr"
new const sprite_grenade_ring[] = "sprites/shockwave.spr"
new g_trailSpr, g_exploSpr, g_msgScoreInfo, g_msgDeathMsg, g_msgScoreAttrib

// Default Models
new const default_v_knife[] = "models/zombie_plague/v_knife_priest.mdl"
new const default_p_knife[] = "models/p_knife.mdl"
new const default_v_antidote[] = "models/zombie_plague/v_antidote_priest.mdl"


// Variables
new g_gameid, g_msg_sync, cvar_minplayers, g_speciald, cvar_damage, cvar_flaregrenades, cvar_fragsinfect, cvar_ammoinfect
new v_knife_model[64], p_knife_model[64], v_antidote_model[64], g_maxpl
new const g_chance = 50

// Ambience sounds task
#define TASK_AMB 3256

public plugin_init()
{
	// Plugin registeration.
	register_plugin("[ZP] Class Priest","1.1", "[P]erfec[T] [S]cr[@]s[H]")
	
	cvar_minplayers = register_cvar("zp_priest_minplayers", "2")
	cvar_damage = register_cvar("zp_priest_damage_multi", "1.5") 
	cvar_flaregrenades = get_cvar_pointer("zp_flare_grenades")
	cvar_fragsinfect = get_cvar_pointer("zp_zombie_frags_for_infect")
	cvar_ammoinfect = get_cvar_pointer("zp_zombie_infect_reward")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_event("CurWeapon","checkModel","be","1=1")
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	register_forward(FM_SetModel, "fw_SetModel")	
	
	g_msgScoreInfo = get_user_msgid("ScoreInfo")
	g_msgDeathMsg = get_user_msgid("DeathMsg")
	g_msgScoreAttrib = get_user_msgid("ScoreAttrib")
	g_msg_sync = CreateHudSyncObj()
	g_maxpl = get_maxplayers()
}

// Game modes MUST be registered in plugin precache ONLY
public plugin_precache()
{
	// Read the access flag
	static user_access[40], i
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE PRIEST", user_access, charsmax(user_access))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE PRIEST", "a")
		formatex(user_access, charsmax(user_access), "a")
	}
	acess_flags[0] = read_flags(user_access)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "MAKE PRIEST", user_access, charsmax(user_access))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "MAKE PRIEST", "a")
		formatex(user_access, charsmax(user_access), "a")
	}
	acess_flags[1] = read_flags(user_access)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_KNIFE PRIEST", v_knife_model, charsmax(v_knife_model)))
	{
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_KNIFE PRIEST", default_v_knife)
		formatex(v_knife_model, charsmax(v_knife_model), default_v_knife)
	}
	precache_model(v_knife_model)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_KNIFE PRIEST", p_knife_model, charsmax(p_knife_model)))
	{
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_KNIFE PRIEST", default_p_knife)
		formatex(p_knife_model, charsmax(p_knife_model), default_p_knife)
	}
	precache_model(p_knife_model)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_ANTIDOTE PRIEST", v_antidote_model, charsmax(v_antidote_model)))
	{
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_ANTIDOTE PRIEST", default_v_antidote)
		formatex(v_antidote_model, charsmax(v_antidote_model), default_v_antidote)
	}
	precache_model(v_antidote_model)
	
	
	g_trailSpr = precache_model(sprite_grenade_trail)
	g_exploSpr = precache_model(sprite_grenade_ring)

	g_sound_priest = ArrayCreate(64, 1)
	g_sound_ambience_priest = ArrayCreate(64, 1)
	g_sound_amb_priest_dur = ArrayCreate(64, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND PRIEST", g_sound_priest)
	
	// Precache the play sounds
	if (ArraySize(g_sound_priest) == 0) {
		for (i = 0; i < sizeof sound_priest; i++)
			ArrayPushString(g_sound_priest, sound_priest[i])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND PRIEST", g_sound_priest)
	}
	
	// Precache sounds
	static sound[100]
	for (i = 0; i < ArraySize(g_sound_priest); i++)
	{
		ArrayGetString(g_sound_priest, i, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else precache_sound(sound)
	}
	
	// Ambience Sounds
	g_ambience_sounds = 0
	if(!amx_load_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "PRIEST ENABLE", g_ambience_sounds))
		amx_save_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "PRIEST ENABLE", g_ambience_sounds)
	
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "PRIEST SOUNDS", g_sound_ambience_priest)
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "PRIEST DURATIONS", g_sound_amb_priest_dur)
	
	
	// Save to external file
	if (ArraySize(g_sound_ambience_priest) == 0) {
		for (i = 0; i < sizeof ambience_priest_sound; i++)
			ArrayPushString(g_sound_ambience_priest, ambience_priest_sound[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "PRIEST SOUNDS", g_sound_ambience_priest)
	}
	
	if (ArraySize(g_sound_amb_priest_dur) == 0) {
		for (i = 0; i < sizeof ambience_priest_dur; i++)
			ArrayPushString(g_sound_amb_priest_dur, ambience_priest_dur[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "PRIEST DURATIONS", g_sound_amb_priest_dur)
	}
	
	// Ambience Sounds
	static buffer[250]
	if (g_ambience_sounds) {
		for (i = 0; i < ArraySize(g_sound_ambience_priest); i++) {
			ArrayGetString(g_sound_ambience_priest, i, buffer, charsmax(buffer))
			
			if (equal(buffer[strlen(buffer)-4], ".mp3")) {
				format(buffer, charsmax(buffer), "sound/%s", buffer)
				precache_generic(buffer)
			}
			else precache_sound(buffer)
		}
	}
	
	// Register our game mode
	#if ZPS_INC_VERSION < 44
	g_gameid = zp_register_game_mode(sp_name, acess_flags[0], g_chance, 0, ZP_DM_NONE)
	#else
	g_gameid = zpsp_register_gamemode(sp_name, acess_flags[0], g_chance, 0, ZP_DM_NONE)
	#endif
	g_speciald = zp_register_human_special(sp_name, sp_model, sp_hp, sp_speed, sp_gravity, acess_flags[1], sp_clip_type, sp_aura_size, sp_allow_glow, sp_color_r, sp_color_g, sp_color_b)
}



public plugin_natives()
{
	register_native("zp_get_user_priest", "native_get_user_priest", 1)
	register_native("zp_make_user_priest", "native_make_user_priest", 1)
	register_native("zp_get_priest_count", "native_get_priest_count", 1)
	register_native("zp_is_priest_round", "native_is_priest_round", 1)
}

// Weapon Model
public checkModel(id)
{
	if (!is_user_alive(id) || zp_get_user_zombie(id))
		return PLUGIN_HANDLED;
	
	if(zp_get_human_special_class(id) == g_speciald) {
		if (get_user_weapon(id) == CSW_KNIFE) {
			set_pev(id, pev_viewmodel2, v_knife_model)
			set_pev(id, pev_weaponmodel2, p_knife_model)
		}
		if (get_user_weapon(id) == CSW_SMOKEGRENADE) {
			set_pev(id, pev_viewmodel2, v_antidote_model)
		}
	}
	return PLUGIN_HANDLED
}

// Knife Damage
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(!is_user_alive(attacker) || !is_user_alive(victim))
		return HAM_IGNORED

	if(zp_get_human_special_class(attacker) == g_speciald && get_user_weapon(attacker) == CSW_KNIFE && zp_get_user_zombie(victim)) {
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_damage))
		zp_set_user_burn(victim, SET_WITHOUT_IMMUNIT)
	}

	return HAM_IGNORED
}

// Player spawn post
public zp_player_spawn_post(id) {
	// Check for current mode
	if(zp_get_current_mode() == g_gameid)
		zp_infect_user(id, 0, 1, 0)
}

public zp_round_started_pre(game)
{
	// Check if it is our game mode
	if(game == g_gameid)
	{
		// Check for min players
		if(zp_get_alive_players() < get_pcvar_num(cvar_minplayers))
			return ZP_PLUGIN_HANDLED

		// Start our new mode
		start_priest_mode()
	}
	return PLUGIN_CONTINUE
}

public zp_round_started(game, id)
{
	// Check if it is our game mode
	if(game == g_gameid)
	{
		// Play the starting sound
		static sound[100]
		ArrayGetString(g_sound_priest, random_num(0, ArraySize(g_sound_priest) - 1), sound, charsmax(sound))

		#if ZPS_INC_VERSION < 44
		PlaySoundToClients(sound)
		#endif
		zp_play_sound(0, sound)
		
		// Remove ambience task affects
		remove_task(TASK_AMB)
		
		// Set task to start ambience sounds
		set_task(2.0, "start_ambience_sounds", TASK_AMB)
	}
}

#if ZPS_INC_VERSION < 44
// Plays a sound on clients
PlaySoundToClients(const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(0, "spk ^"%s^"", sound)
}
#endif

public zp_game_mode_selected(gameid, id)
{
	// Check if our game mode was called
	if(gameid == g_gameid)
		start_priest_mode()
	
	// Make the compiler happy again =)
	return PLUGIN_CONTINUE
}

// This function contains the whole code behind this game mode
start_priest_mode()
{
	static id, i,  has_priest
	has_priest = false
	for (i = 1; i <= g_maxpl; i++) {
		if(!is_user_alive(i))
			continue;

		if(zp_get_human_special_class(i) == g_speciald) {
			id = i
			has_priest = true
		}
	}

	if(!has_priest) {
		id = zp_get_random_player()
		zp_make_user_special(id, g_speciald, GET_HUMAN)
	}
	
	static name[32]; get_user_name(id, name, charsmax(name));
	set_hudmessage(sp_color_r, sp_color_g, sp_color_b, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	//ShowSyncHudMsg(0, g_msg_sync, "%s is a %s", name, sp_name)
	ShowSyncHudMsg(0, g_msg_sync, "%s is a %s", name, sp_name)
		
	// Turn the remaining players into zombies
	for (id = 1; id <= g_maxpl; id++)
	{
		// Not alive
		if(!is_user_alive(id))
			continue;
			
		// Survivor or already a zombie
		if(zp_get_human_special_class(id) == g_speciald || zp_get_user_zombie(id))
			continue;
			
		// Turn into a zombie
		zp_infect_user(id, 0, 1, 0)
	}

}

public start_ambience_sounds()
{
	if (!g_ambience_sounds)
		return;
	
	// Variables
	static amb_sound[64], sound,  str_dur[20]
	
	// Select our ambience sound
	sound = random_num(0, ArraySize(g_sound_ambience_priest)-1)

	ArrayGetString(g_sound_ambience_priest, sound, amb_sound, charsmax(amb_sound))
	ArrayGetString(g_sound_amb_priest_dur, sound, str_dur, charsmax(str_dur))
	
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

public zp_user_humanized_post(id)
{
	if(zp_get_human_special_class(id) == g_speciald) 
	{
		if(!zp_has_round_started())
			zp_set_custom_game_mod(g_gameid)
			
		fm_give_item(id,"weapon_smokegrenade")
		
		if(is_user_bot(id)) {
			remove_task(id)
			set_task(random_float(5.0, 15.0), "bot_support", id)
		}
	}
}

public bot_support(id) {
	if(zp_get_human_special_class(id) == g_speciald && user_has_weapon(id, CSW_SMOKEGRENADE)) {
		engclient_cmd(id, "weapon_smokegrenade");
		ExecuteHam(Ham_Weapon_PrimaryAttack, get_pdata_cbase(id, 373, 5));
	}
}

public native_get_user_priest(id)
	return (zp_get_human_special_class(id) == g_speciald)
	
public native_make_user_priest(id)
	return zp_make_user_special(id, g_speciald, GET_HUMAN)
	
public native_get_priest_count()
	return zp_get_special_count(GET_HUMAN, g_speciald)
	
public native_is_priest_round()
	return (zp_get_current_mode() == g_gameid)
	
public fw_ThinkGrenade(entity)
{
	if(!pev_valid(entity))
		return HAM_IGNORED

	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	if (dmgtime > get_gametime())
		return HAM_IGNORED	
		
	if(pev(entity, pev_flTimeStepSound) == NADE_TYPE_ANTIDOTEBOMB)
		antidote_explode(entity)
	
	return HAM_SUPERCEDE
}

new changed
public fw_SetModel(entity, const model[])
{
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	if (dmgtime == 0.0)
		return
	
	if (equal(model[7], "w_sm", 4))
	{		
		new owner = pev(entity, pev_owner)		
		
		if(zp_get_human_special_class(owner) == g_speciald) 
		{
			if(get_pcvar_num(cvar_flaregrenades) != 0) {
				changed = true
				set_pcvar_num(cvar_flaregrenades,0)	
			}
			
			fm_set_rendering(entity, kRenderFxGlowShell, sp_color_r, sp_color_g, sp_color_b, kRenderNormal, 16)
			
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_BEAMFOLLOW) // TE id
			write_short(entity) // entity
			write_short(g_trailSpr) // sprite
			write_byte(10) // life
			write_byte(10) // width
			write_byte(sp_color_r) // red
			write_byte(sp_color_g) // green
			write_byte(sp_color_b) // blue
			write_byte(200) // brightness
			message_end()
			
			set_pev(entity, pev_flTimeStepSound, NADE_TYPE_ANTIDOTEBOMB)
		}
	}
	
}

public antidote_explode(ent)
{
	if (!zp_has_round_started()) return
	
	if(changed) set_pcvar_num(cvar_flaregrenades,1)
	
	static Float:originF[3]
	pev(ent, pev_origin, originF)
	
	create_blast(originF)	
	
	static attacker
	attacker = pev(ent, pev_owner)
	
	static victim
	victim = -1
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, RADIUS)) != 0)
	{
		if (!is_user_alive(victim))
			continue;

		if(!zp_get_user_zombie(victim))
			continue;
		
		if(zp_get_user_last_zombie(victim) || zp_get_zombie_special_class(victim)) {
			zp_set_user_burn(victim, SET_WITHOUT_IMMUNIT)
			zp_set_user_frozen(victim, SET_WITHOUT_IMMUNIT)
			continue;
		}
		
		SendDeathMsg(attacker, victim)
		FixDeadAttrib(victim)
		UpdateFrags(attacker, victim, get_pcvar_num(cvar_fragsinfect), 1, 1)
		zp_disinfect_user(victim)
		zp_set_user_ammo_packs(attacker,zp_get_user_ammo_packs(attacker) + get_pcvar_num(cvar_ammoinfect))
	}
	
	engfunc(EngFunc_RemoveEntity, ent)
}

public create_blast(const Float:originF[3])
{
	new radius_shockwave, size
	radius_shockwave = floatround(RADIUS)
	while(radius_shockwave >= 60) {
		radius_shockwave -= 60
		size++
	}
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+385.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(size) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(sp_color_r) // red
	write_byte(sp_color_g) // green
	write_byte(sp_color_b) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+470.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(size) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(sp_color_r) // red
	write_byte(sp_color_g) // green
	write_byte(sp_color_b) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+555.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(size) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(sp_color_r) // red
	write_byte(sp_color_g) // green
	write_byte(sp_color_b) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
}

public UpdateFrags(attacker, victim, frags, deaths, scoreboard)
{
	set_pev(attacker, pev_frags, float(pev(attacker, pev_frags) + frags))
	
	fm_set_user_deaths(victim, fm_get_user_deaths(victim) + deaths)
	
	if (scoreboard) {	
		message_begin(MSG_BROADCAST, g_msgScoreInfo)
		write_byte(attacker) // id
		write_short(pev(attacker, pev_frags)) // frags
		write_short(fm_get_user_deaths(attacker)) // deaths
		write_short(0) // class?
		write_short(fm_get_user_team(attacker)) // team
		message_end()
		
		message_begin(MSG_BROADCAST, g_msgScoreInfo)
		write_byte(victim) // id
		write_short(pev(victim, pev_frags)) // frags
		write_short(fm_get_user_deaths(victim)) // deaths
		write_short(0) // class?
		write_short(fm_get_user_team(victim)) // team
		message_end()
	}
}

stock fm_set_user_deaths(id, value) {
	set_pdata_int(id, 444, value, 5)
}

stock fm_get_user_deaths(id) {
	return get_pdata_int(id, 444, 5)
}

stock fm_get_user_team(id) {
	return get_pdata_int(id, 114, 5)
}

public SendDeathMsg(attacker, victim) {
	message_begin(MSG_BROADCAST, g_msgDeathMsg)
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(1) // headshot flag
	write_string("grenade") // killer's weapon
	message_end()
}

public FixDeadAttrib(id) {
	message_begin(MSG_BROADCAST, g_msgScoreAttrib)
	write_byte(id) // id
	write_byte(0) // attrib
	message_end()
}

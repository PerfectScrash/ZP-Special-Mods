/*
			[ZPSp] Special Class: Grenadier

			* Description:
				Its like a Bombardier but its human.

			* Cvars:
				zp_grenadier_minplayers "2" - Min Players for Start a Grenadier Mod
				zp_grenadier_damage_multi "1.5" - Knife Damage Multi

			* Change Log:

				* 1.0:
					First Release

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

new Array:g_sound_grenadier, g_ambience_sounds, Array:g_sound_amb_grenadier_dur, Array: g_sound_ambience_grenadier

// Default Sounds
new const sound_grenadier[][] = { "zombie_plague/survivor1.wav" }
new const ambience_grenadier_sound[][] = { "zombie_plague/ambience.wav" } 
new const ambience_grenadier_dur[][] = { "17" }

new const sp_name[] = "Grenadier"
new const sp_model[] = "vip"
new const sp_hp = 5000
new const sp_speed = 250
new const Float:sp_gravity = 0.7
new const sp_aura_size = 15
new const sp_clip_type = 2 // Unlimited Ammo (0 - Disable | 1 - Unlimited Semi Clip | 2 - Unlimited Clip)
new const sp_allow_glow = 1
new const sp_color_r = 100
new const sp_color_g = 0
new const sp_color_b = 255
new acess_flags[2]

new const NADE_TYPE_KILL = 3020
new const Float:RADIUS = 240.0
new const sprite_grenade_trail[] = "sprites/laserbeam.spr"
new const sprite_grenade_ring[] = "sprites/shockwave.spr"
new g_trailSpr, g_exploSpr

// Default Models
new const default_v_knife[] = "models/v_knife.mdl"
new const default_p_knife[] = "models/p_knife.mdl"
new const default_v_kill[] = "models/v_smokegrenade.mdl"
new const default_p_kill[] = "models/p_smokegrenade.mdl"
new const default_w_kill[] = "models/w_smokegrenade.mdl"


// Variables
new g_gameid, g_msg_sync, cvar_minplayers, g_speciald, cvar_damage, cvar_flaregrenades
new v_knife_model[64], p_knife_model[64], v_kill_model[64], p_kill_model[64], w_kill_model[64], g_maxpl
new const g_chance = 50

// Ambience sounds task
#define TASK_AMB 3256
#define TASK_GIVE_GRENADE 132912

public plugin_init()
{
	// Plugin registeration.
	register_plugin("[ZPSp] Special Class: Grenadier","1.0", "[P]erfec[T] [S]cr[@]s[H]")
	
	cvar_minplayers = register_cvar("zp_grenadier_minplayers", "2")
	cvar_damage = register_cvar("zp_grenadier_damage_multi", "1.5") 
	cvar_flaregrenades = get_cvar_pointer("zp_flare_grenades")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_event("CurWeapon","checkModel","be","1=1")
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	register_forward(FM_SetModel, "fw_SetModel")	
	
	g_msg_sync = CreateHudSyncObj()
	g_maxpl = get_maxplayers()
}

// Game modes MUST be registered in plugin precache ONLY
public plugin_precache()
{
	// Read the access flag
	static user_access[40]
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE GRENADIER", user_access, charsmax(user_access))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE GRENADIER", "a")
		formatex(user_access, charsmax(user_access), "a")
	}
	acess_flags[0] = read_flags(user_access)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "MAKE GRENADIER", user_access, charsmax(user_access))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "MAKE GRENADIER", "a")
		formatex(user_access, charsmax(user_access), "a")
	}
	acess_flags[1] = read_flags(user_access)

	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_KNIFE GRENADIER", v_knife_model, charsmax(v_knife_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_KNIFE GRENADIER", default_v_knife)
		formatex(v_knife_model, charsmax(v_knife_model), default_v_knife)
	}
	precache_model(v_knife_model)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_KNIFE GRENADIER", p_knife_model, charsmax(p_knife_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_KNIFE GRENADIER", default_p_knife)
		formatex(p_knife_model, charsmax(p_knife_model), default_p_knife)
	}
	precache_model(p_knife_model)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_KILLBOMB GRENADIER", v_kill_model, charsmax(v_kill_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_KILLBOMB GRENADIER", default_v_kill)
		formatex(v_kill_model, charsmax(v_kill_model), default_v_kill)
	}
	precache_model(v_kill_model)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_KILLBOMB GRENADIER", p_kill_model, charsmax(p_kill_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_KILLBOMB GRENADIER", default_p_kill)
		formatex(p_kill_model, charsmax(p_kill_model), default_p_kill)
	}
	precache_model(p_kill_model)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "W_KILLBOMB GRENADIER", w_kill_model, charsmax(w_kill_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "W_KILLBOMB GRENADIER", default_w_kill)
		formatex(w_kill_model, charsmax(w_kill_model), default_w_kill)
	}
	precache_model(w_kill_model)
	
	g_trailSpr = precache_model(sprite_grenade_trail)
	g_exploSpr = precache_model(sprite_grenade_ring)
	
	new i
	g_sound_grenadier = ArrayCreate(64, 1)
	g_sound_ambience_grenadier = ArrayCreate(64, 1)
	g_sound_amb_grenadier_dur = ArrayCreate(64, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND GRENADIER", g_sound_grenadier)
	
	// Precache the play sounds
	if (ArraySize(g_sound_grenadier) == 0) {
		for (i = 0; i < sizeof sound_grenadier; i++)
			ArrayPushString(g_sound_grenadier, sound_grenadier[i])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND GRENADIER", g_sound_grenadier)
	}
	
	// Precache sounds
	static sound[100]
	for (i = 0; i < ArraySize(g_sound_grenadier); i++)
	{
		ArrayGetString(g_sound_grenadier, i, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			if(!file_exists(sound))
				format(sound, charsmax(sound), "sound/%s", sound)
			
			precache_generic(sound)
		}
		else precache_sound(sound)
	}
	
	// Ambience Sounds
	g_ambience_sounds = 0
	if(!amx_load_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "GRENADIER ENABLE", g_ambience_sounds))
		amx_save_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "GRENADIER ENABLE", g_ambience_sounds)
	
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "GRENADIER SOUNDS", g_sound_ambience_grenadier)
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "GRENADIER DURATIONS", g_sound_amb_grenadier_dur)
	
	
	// Save to external file
	if (ArraySize(g_sound_ambience_grenadier) == 0) {
		for (i = 0; i < sizeof ambience_grenadier_sound; i++)
			ArrayPushString(g_sound_ambience_grenadier, ambience_grenadier_sound[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "GRENADIER SOUNDS", g_sound_ambience_grenadier)
	}
	
	if (ArraySize(g_sound_amb_grenadier_dur) == 0) {
		for (i = 0; i < sizeof ambience_grenadier_dur; i++)
			ArrayPushString(g_sound_amb_grenadier_dur, ambience_grenadier_dur[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "GRENADIER DURATIONS", g_sound_amb_grenadier_dur)
	}
	
	// Ambience Sounds
	static buffer[250]
	if (g_ambience_sounds) {
		for (i = 0; i < ArraySize(g_sound_ambience_grenadier); i++) {
			ArrayGetString(g_sound_ambience_grenadier, i, buffer, charsmax(buffer))
			
			if (equal(buffer[strlen(buffer)-4], ".mp3")) {
				
				if(!file_exists(buffer))
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

	g_speciald = zp_register_human_special(sp_name, sp_model, sp_hp, sp_speed, sp_gravity, acess_flags[1], sp_clip_type, sp_aura_size, sp_allow_glow, sp_color_r, sp_color_g, sp_color_b)
}

public plugin_natives()
{
	register_native("zp_get_user_grenadier", "native_get_user_grenadier", 1)
	register_native("zp_make_user_grenadier", "native_make_user_grenadier", 1)
	register_native("zp_get_grenadier_count", "native_get_grenadier_count", 1)
	register_native("zp_is_grenadier_round", "native_is_grenadier_round", 1)
}

public zp_extra_item_selected_pre(id, itemid) {
	if(zp_get_human_special_class(id) == g_speciald)
		return ZP_PLUGIN_SUPERCEDE
	
	return PLUGIN_CONTINUE
}

// Weapon Model
public checkModel(id) {
	if (!is_user_alive(id) || zp_get_user_zombie(id))
		return PLUGIN_HANDLED;
	
	if(zp_get_human_special_class(id) == g_speciald) {
		if (get_user_weapon(id) == CSW_KNIFE) {
			set_pev(id, pev_viewmodel2, v_knife_model)
			set_pev(id, pev_weaponmodel2, p_knife_model)
		}
		if (get_user_weapon(id) == CSW_SMOKEGRENADE) {
			set_pev(id, pev_viewmodel2, v_kill_model)
			set_pev(id, pev_weaponmodel2, p_kill_model)
		}
	}
	return PLUGIN_HANDLED
}

// Knife Damage
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if(!is_user_alive(attacker) || !is_user_alive(victim))
		return HAM_IGNORED
	
	if(zp_get_human_special_class(attacker) == g_speciald && get_user_weapon(attacker) == CSW_KNIFE && zp_get_user_zombie(victim)) {
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_damage))
	}
	return HAM_IGNORED
}

// Player spawn post
public zp_player_spawn_post(id) {
	// Check for current mode
	if(zp_get_current_mode() == g_gameid)
		zp_infect_user(id)
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
		start_grenadier_mode()
	}
	return PLUGIN_CONTINUE
}

public zp_round_started(game, id)
{
	// Check if it is our game mode
	if(game == g_gameid) {
		// Play the starting sound
		static sound[100]
		ArrayGetString(g_sound_grenadier, random_num(0, ArraySize(g_sound_grenadier) - 1), sound, charsmax(sound))
		
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
		start_grenadier_mode()
	
	// Make the compiler happy again =)
	return PLUGIN_CONTINUE
}

// This function contains the whole code behind this game mode
start_grenadier_mode()
{
	static id, i, has_grenadier
	has_grenadier = false
	for (i = 0; i <= g_maxpl; i++) {
		if(!is_user_alive(i))
			continue
		
		if(zp_get_human_special_class(i) == g_speciald) {
			id = i
			has_grenadier = true
			break;
		}
	}

	if(!has_grenadier) {
		id = zp_get_random_player()
		
		if(id != -1 && is_user_alive(id))
			zp_make_user_special(id, g_speciald, GET_HUMAN)
		else
			log_error(AMX_ERR_NOTFOUND, "[ZP] No Player Alive found")
	}	
	
	static name[32]; get_user_name(id, name, charsmax(name));
	set_hudmessage(sp_color_r, sp_color_g, sp_color_b, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync, "%s is a %s", name, sp_name)
		
	// Turn the remaining players into zombies
	for (id = 0; id <= g_maxpl; id++)
	{
		// Not alive
		if(!is_user_alive(id))
			continue;
			
		// Survivor or already a zombie
		if(zp_get_human_special_class(id) == g_speciald || zp_get_user_zombie(id))
			continue;
			
		// Turn into a zombie
		zp_infect_user(id)
	}

}

// Ambience Sounds
public start_ambience_sounds()
{
	if (!g_ambience_sounds)
		return;
	
	// Variables
	static amb_sound[64], sound,  str_dur[20]
	
	// Select our ambience sound
	sound = random_num(0, ArraySize(g_sound_ambience_grenadier)-1)

	ArrayGetString(g_sound_ambience_grenadier, sound, amb_sound, charsmax(amb_sound))
	ArrayGetString(g_sound_amb_grenadier_dur, sound, str_dur, charsmax(str_dur))
	
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

// When player turn into a Grenadier
public zp_user_humanized_post(id)
{
	if(!is_user_alive(id))
		return
	
	if(zp_get_human_special_class(id) == g_speciald) 
	{
		if(!zp_has_round_started())
			zp_set_custom_game_mod(g_gameid)
			
		fm_give_item(id,"weapon_smokegrenade")
		set_task(3.0, "give_grenade", id+TASK_GIVE_GRENADE, _, _, "b")
	}
}

// Give Grenade
public give_grenade(id) {
	id -= TASK_GIVE_GRENADE
	
	if(!is_user_alive(id)) {
		remove_task(id+TASK_GIVE_GRENADE)
		return;
	}

	if(zp_get_human_special_class(id) == g_speciald) {
		if(!user_has_weapon(id, CSW_SMOKEGRENADE))
			fm_give_item(id, "weapon_smokegrenade")
	
		// Bot Support (Some bots system not suports)
		if(is_user_bot(id) && user_has_weapon(id, CSW_SMOKEGRENADE)) {
			engclient_cmd(id, "weapon_smokegrenade");
			
			if (pev_valid(id) == 2)	
				ExecuteHam(Ham_Weapon_PrimaryAttack, get_pdata_cbase(id, 373, 5));
		}
	}
	else
		remove_task(id+TASK_GIVE_GRENADE)
}

// Natives
public native_get_user_grenadier(id)
	return (zp_get_human_special_class(id) == g_speciald)
	
public native_make_user_grenadier(id)
	return zp_make_user_special(id, g_speciald, GET_HUMAN)
	
public native_get_grenadier_count()
	return zp_get_special_count(GET_HUMAN, g_speciald)
	
public native_is_grenadier_round()
	return (zp_get_current_mode() == g_gameid)

// Think Grenade
public fw_ThinkGrenade(entity)
{
	if(!pev_valid(entity))
		return HAM_IGNORED
	
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	if (dmgtime > get_gametime())
		return HAM_IGNORED	
		
	if(pev(entity, pev_flTimeStepSound) == NADE_TYPE_KILL)
		kill_explode(entity)
	
	return HAM_SUPERCEDE
}

// W_ Model Grenade Change
new changed
public fw_SetModel(entity, const model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED	
	
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	if (dmgtime == 0.0)
		return FMRES_IGNORED
	
	if (equal(model[7], "w_sm", 4))
	{		
		new owner = pev(entity, pev_owner)
		
		if(!is_user_connected(owner))
			return FMRES_IGNORED
		
		if(zp_get_human_special_class(owner) == g_speciald) 
		{
			if(get_pcvar_num(cvar_flaregrenades) != 0) {
				changed = true
				set_pcvar_num(cvar_flaregrenades,0)	
			}
			
			fm_entity_set_model(entity, w_kill_model)
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
			
			set_pev(entity, pev_flTimeStepSound, NADE_TYPE_KILL)
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

// Kill Bomb Explodes
public kill_explode(ent)
{
	if (!zp_has_round_started() || zp_has_round_ended() || !pev_valid(ent)) 
		return
	
	if(changed) set_pcvar_num(cvar_flaregrenades,1)
	
	static Float:originF[3]
	pev(ent, pev_origin, originF)
	
	create_blast(originF)	
	
	static attacker
	attacker = pev(ent, pev_owner)
	
	// Infection bomb owner disconnected?
	if (!is_user_connected(attacker))
	{
		// Get rid of the grenade
		engfunc(EngFunc_RemoveEntity, ent)
		return;
	}
	
	static victim
	victim = -1
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, RADIUS)) != 0)
	{
		if (!is_user_alive(victim))
			continue;
		
		if(!zp_get_user_zombie(victim))
			continue;
		
		ExecuteHamB(Ham_Killed, victim, attacker, 0)
		zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker) + 2)
		
	}
	
	engfunc(EngFunc_RemoveEntity, ent)
}

// Ring Effect
public create_blast(const Float:originF[3])
{
	static radius_shockwave, size
	size = 0
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

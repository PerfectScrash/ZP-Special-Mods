/*
			[ZPSp] Special Class: Plasma

		* Description:
			Give a player a one Plasma Rifle

		* Cvars:
			zp_plasma_minplayers "2" - Min Players for Start a Plasma Mode

		* Change Log:
			* 1.0:
				- First Release

			* 1.1:
				- Fixed Ambience Sound
				- Fixed v_model of Plasma Rifle
				- Added Draw Sound in v_model
				- Plasma Rifle Can give Ammo packs (Works only in Zombie Plague Special 4.4 or higher)
*/

#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <fakemeta_util>
#include <cstrike>
#include <zombie_plague_special>
#include <amx_settings_api>

#if ZPS_INC_VERSION < 43
	#assert Zombie Plague Special 4.3 Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

new const ZP_CUSTOMIZATION_FILE[] = "zombie_plague_special.ini"

new Array:g_sound_plasma, g_ambience_sounds, Array:g_sound_amb_plasma_dur, Array: g_sound_ambience_plasma

// Default Sounds
new const sound_plasma[][] = { "zombie_plague/survivor1.wav" }
new const ambience_plasma_sound[][] = { "zombie_plague/ambience.wav" } 
new const ambience_plasma_dur[][] = { "17" }

new const sp_name[] = "Plasma"
new const sp_model[] = "vip"
new const sp_hp = 5000
new const sp_speed = 280
new const Float:sp_gravity = 0.8
new const sp_aura_size = 10
new const sp_clip_type = 2 // Unlimited Ammo (0 - Disable | 1 - Unlimited Semi Clip | 2 - Unlimited Clip)
new const sp_allow_glow = 1
new const sp_color_r = 0
new const sp_color_g = 255
new const sp_color_b = 0
new acess_flags[2]

// Default FAMAS Models
new const default_v_famas[] = "models/zombie_plague/plasma/v_plasma_fix.mdl"
new const default_p_famas[] = "models/zombie_plague/plasma/p_plasma.mdl"

#define FIRERATE 0.2
#define HITSD 0.7
#define RELOADSPEED 5.0
#define DAMAGE 250.0
#define DAMAGE_MULTI 3.0

new const weapon[] = "weapon_famas"

new const spr_beam[] = "sprites/plasma/plasma_beam.spr"
new const spr_exp[] = "sprites/plasma/plasma_exp.spr"
new const spr_blood[] = "sprites/blood.spr"
new const snd_fire[] = "zombie_plague/plasma/plasma_fire.wav"
new const snd_reload[] = "zombie_plague/plasma/plasma_reload.wav"
new const snd_draw[] = "zombie_plague/plasma/plasma_draw.wav"
new const snd_hit[] =  "zombie_plague/plasma/plasma_hit.wav"

new g_iCurWpn[33], Float:g_flLastFireTime[33]
new g_sprBeam, g_sprExp, g_sprBlood, g_msgDamage, g_msgScreenFade, g_msgScreenShake

const m_pPlayer = 		41
const m_fInReload =		54
const m_pActiveItem = 		373
const m_flNextAttack = 		83
const m_flTimeWeaponIdle = 	48
const m_flNextPrimaryAttack = 	46
const m_flNextSecondaryAttack =	47

const UNIT_SECOND =		(1<<12)
const ENG_NULLENT = 		-1
const WPN_MAXCLIP =		25
const ANIM_FIRE = 		5
const ANIM_DRAW = 		10
const ANIM_RELOAD =		9

// Variables
new g_gameid, g_msg_sync, cvar_minplayers, g_speciald
new v_famas_model[64], p_famas_model[64], g_maxplayers
new const g_chance = 90

// Ambience sounds task
#define TASK_AMB 3256

public plugin_init()
{
	// Plugin registeration.
	register_plugin("[ZP] Class Plasma","1.1", "[P]erfec[T] [S]cr[@]s[H] | Sh0oT3R")
	
	cvar_minplayers = register_cvar("zp_plasma_minplayers", "2")

	register_event("CurWeapon","checkModel","be","1=1")
	
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	
	RegisterHam(Ham_Item_Deploy, weapon, "fw_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_Reload, weapon, "fw_Reload_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon, "fw_PostFrame")
	
	g_msgDamage = get_user_msgid("Damage")
	g_msgScreenFade = get_user_msgid("ScreenFade")
	g_msgScreenShake = get_user_msgid("ScreenShake")
	g_maxplayers = get_maxplayers()
	
	g_msg_sync = CreateHudSyncObj()
}

// Game modes MUST be registered in plugin precache ONLY
public plugin_precache()
{
	// Read the access flag
	static user_access[40], i
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE PLASMA", user_access, charsmax(user_access))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE PLASMA", "a")
		formatex(user_access, charsmax(user_access), "a")
	}
	acess_flags[0] = read_flags(user_access)

	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "MAKE PLASMA", user_access, charsmax(user_access))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "MAKE PLASMA", "a")
		formatex(user_access, charsmax(user_access), "a")
	}
	acess_flags[1] = read_flags(user_access)

	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_FAMAS PLASMA", v_famas_model, charsmax(v_famas_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_FAMAS PLASMA", default_v_famas)
		formatex(v_famas_model, charsmax(v_famas_model), default_v_famas)
	}
	precache_model(v_famas_model)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_FAMAS PLASMA", p_famas_model, charsmax(p_famas_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_FAMAS PLASMA", default_p_famas)
		formatex(p_famas_model, charsmax(p_famas_model), default_p_famas)
	}
	precache_model(p_famas_model)

	g_sound_plasma = ArrayCreate(64, 1)
	g_sound_ambience_plasma = ArrayCreate(64, 1)
	g_sound_amb_plasma_dur = ArrayCreate(64, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND PLASMA", g_sound_plasma)
	
	// Precache the play sounds
	if (ArraySize(g_sound_plasma) == 0) {
		for (i = 0; i < sizeof sound_plasma; i++)
			ArrayPushString(g_sound_plasma, sound_plasma[i])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND PLASMA", g_sound_plasma)
	}
	
	// Precache sounds
	new sound[100]
	for (i = 0; i < ArraySize(g_sound_plasma); i++) {
		ArrayGetString(g_sound_plasma, i, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3")) {
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else precache_sound(sound)
	}
	
	// Ambience Sounds
	g_ambience_sounds = 0
	if(!amx_load_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "PLASMA ENABLE", g_ambience_sounds))
		amx_save_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "PLASMA ENABLE", g_ambience_sounds)
	
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "PLASMA SOUNDS", g_sound_ambience_plasma)
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "PLASMA DURATIONS", g_sound_amb_plasma_dur)
	
	
	// Save to external file
	if (ArraySize(g_sound_ambience_plasma) == 0) {
		for (i = 0; i < sizeof ambience_plasma_sound; i++)
			ArrayPushString(g_sound_ambience_plasma, ambience_plasma_sound[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "PLASMA SOUNDS", g_sound_ambience_plasma)
	}
	
	if (ArraySize(g_sound_amb_plasma_dur) == 0) {
		for (i = 0; i < sizeof ambience_plasma_dur; i++)
			ArrayPushString(g_sound_amb_plasma_dur, ambience_plasma_dur[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "PLASMA DURATIONS", g_sound_amb_plasma_dur)
	}
	
	// Ambience Sounds
	static buffer[250]
	if (g_ambience_sounds) {
		for (i = 0; i < ArraySize(g_sound_ambience_plasma); i++) {
			ArrayGetString(g_sound_ambience_plasma, i, buffer, charsmax(buffer))
			
			if (equal(buffer[strlen(buffer)-4], ".mp3")) {
				format(buffer, charsmax(buffer), "sound/%s", buffer)
				precache_generic(buffer)
			}
			else precache_sound(buffer)
		}
	}
	
	g_sprBlood = precache_model(spr_blood)
	g_sprBeam = precache_model(spr_beam)
	g_sprExp = precache_model(spr_exp)
	
	precache_sound(snd_fire)
	precache_sound(snd_hit)
	precache_sound(snd_reload)	
	precache_sound(snd_draw)	
	
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
	register_native("zp_get_user_plasma", "native_get_user_plasma", 1)
	register_native("zp_make_user_plasma", "native_make_user_plasma", 1)
	register_native("zp_get_plasma_count", "native_get_plasma_count", 1)
	register_native("zp_is_plasma_round", "native_is_plasma_round", 1)
}

#if ZPS_INC_VERSION < 43
public zp_extra_item_selected_pre(id, itemid) {
	if(zp_get_human_special_class(id) == g_speciald)
		return ZP_PLUGIN_SUPERCEDE
	
	return PLUGIN_CONTINUE
}
#endif

// Weapon Model
public checkModel(id) {
	if (!is_user_alive(id) || zp_get_user_zombie(id))
		return PLUGIN_HANDLED;
	
	g_iCurWpn[id] = read_data(2)
	
	if (g_iCurWpn[id] == CSW_FAMAS && zp_get_human_special_class(id) == g_speciald) {		
		set_pev(id, pev_viewmodel2, v_famas_model)
		set_pev(id, pev_weaponmodel2, p_famas_model)
	}
	return PLUGIN_HANDLED
}

// Player spawn post
public zp_player_spawn_post(id) {
	// Check for current mode
	if(zp_get_current_mode() == g_gameid)
		zp_infect_user(id)
}

public zp_round_started_pre(game) {
	// Check if it is our game mode
	if(game == g_gameid)
	{
		// Check for min players
		if(zp_get_alive_players() < get_pcvar_num(cvar_minplayers))
			return ZP_PLUGIN_HANDLED

		// Start our new mode
		start_plasma_mode()
	}
	return PLUGIN_CONTINUE
}

public zp_round_started(game, id) {
	// Check if it is our game mode
	if(game == g_gameid)
	{
		// Play the starting sound
		static sound[100]
		ArrayGetString(g_sound_plasma, random_num(0, ArraySize(g_sound_plasma) - 1), sound, charsmax(sound))
		
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
		start_plasma_mode()
	
	// Make the compiler happy again =)
	return PLUGIN_CONTINUE
}

// This function contains the whole code behind this game mode
start_plasma_mode()
{
	new id, i,  has_plasma
	has_plasma = false
	for (i = 1; i <= g_maxplayers; i++) {
		if(zp_get_human_special_class(i) == g_speciald) {
			id = i
			has_plasma = true
		}
	}

	if(!has_plasma) {
		id = zp_get_random_player()
		zp_make_user_special(id, g_speciald, GET_HUMAN)
	}
	
	static name[32]; get_user_name(id, name, charsmax(name));
	set_hudmessage(sp_color_r, sp_color_g, sp_color_b, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync, "%s is a %s", name, sp_name)
		
	// Turn the remaining players into zombies
	for (id = 1; id <= g_maxplayers; id++)
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

public start_ambience_sounds()
{
	if (!g_ambience_sounds)
		return;
	
	// Variables
	static amb_sound[64], sound,  str_dur[20]
	
	// Select our ambience sound
	sound = random_num(0, ArraySize(g_sound_ambience_plasma)-1)

	ArrayGetString(g_sound_ambience_plasma, sound, amb_sound, charsmax(amb_sound))
	ArrayGetString(g_sound_amb_plasma_dur, sound, str_dur, charsmax(str_dur))
	
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
	if(zp_get_human_special_class(id) == g_speciald) {
		if(!zp_has_round_started())
			zp_set_custom_game_mod(g_gameid)
		
		fm_give_item(id, "weapon_famas")
		cs_set_user_bpammo(id, CSW_FAMAS, 90)
	}
}

public native_get_user_plasma(id)
	return (zp_get_human_special_class(id) == g_speciald)
	
public native_make_user_plasma(id)
	return zp_make_user_special(id, g_speciald, GET_HUMAN)
	
public native_get_plasma_count()
	return zp_get_special_count(GET_HUMAN, g_speciald)
	
public native_is_plasma_round()
	return (zp_get_current_mode() == g_gameid)
	
public fw_CmdStart(id, handle, seed)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED
	
	if(zp_get_human_special_class(id) != g_speciald || zp_get_user_zombie(id))
		return FMRES_IGNORED
	
	if(g_iCurWpn[id] != CSW_FAMAS)
		return FMRES_IGNORED
		
	static iButton
	iButton = get_uc(handle, UC_Buttons)
	
	if(iButton & IN_ATTACK)
	{
		set_uc(handle, UC_Buttons, iButton & ~IN_ATTACK)
		
		static Float:flCurTime
		flCurTime = halflife_time()
		
		if(flCurTime - g_flLastFireTime[id] < FIRERATE)
			return FMRES_IGNORED
			
		static iWpnID, iClip
		iWpnID = get_pdata_cbase(id, m_pActiveItem, 5)
		iClip = cs_get_weapon_ammo(iWpnID)
		
		if(get_pdata_int(iWpnID, m_fInReload, 4))
			return FMRES_IGNORED
		
		set_pdata_float(iWpnID, m_flNextPrimaryAttack, FIRERATE, 4)
		set_pdata_float(iWpnID, m_flNextSecondaryAttack, FIRERATE, 4)
		set_pdata_float(iWpnID, m_flTimeWeaponIdle, FIRERATE, 4)
		g_flLastFireTime[id] = flCurTime
		if(iClip <= 0)
		{
			ExecuteHamB(Ham_Weapon_PlayEmptySound, iWpnID)
			return FMRES_IGNORED
		}
		primary_attack(id)
		make_punch(id, 50)
		cs_set_weapon_ammo(iWpnID, --iClip)
		
		return FMRES_IGNORED
	}
	
	return FMRES_IGNORED
}
public fw_UpdateClientData_Post(id, sendweapons, handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED
		
	if(zp_get_human_special_class(id) != g_speciald || zp_get_user_zombie(id))
		return FMRES_IGNORED
	
	if(g_iCurWpn[id] != CSW_FAMAS)
		return FMRES_IGNORED
		
	set_cd(handle, CD_flNextAttack, halflife_time() + 0.001)
	return FMRES_HANDLED
}
public fw_Deploy_Post(wpn)
{
	static id
	id = get_pdata_cbase(wpn, m_pPlayer, 4)
	
	if(is_user_connected(id) && zp_get_human_special_class(id) == g_speciald)
		set_wpnanim(id, ANIM_DRAW)

	return HAM_IGNORED
}

public fw_PostFrame(wpn)
{
	static id
	id = get_pdata_cbase(wpn, m_pPlayer, 4)

	if(is_user_alive(id) && zp_get_human_special_class(id) == g_speciald)
	{
		static Float:flNextAttack, iBpAmmo, iClip, iInReload
		iInReload = get_pdata_int(wpn, m_fInReload, 4)
		flNextAttack = get_pdata_float(id, m_flNextAttack, 5)
		iBpAmmo = cs_get_user_bpammo(id, CSW_FAMAS)
		iClip = cs_get_weapon_ammo(wpn)
		
		if(iInReload && flNextAttack <= 0.0) {
			new iRemClip = min(WPN_MAXCLIP - iClip, iBpAmmo)
			cs_set_weapon_ammo(wpn, iClip + iRemClip)
			cs_set_user_bpammo(id, CSW_FAMAS, iBpAmmo-iRemClip)
			iInReload = 0
			set_pdata_int(wpn, m_fInReload, 0, 4)
		}
		static iButton
		iButton = get_user_button(id)

		if((iButton & IN_ATTACK2 && get_pdata_float(wpn, m_flNextSecondaryAttack, 4) <= 0.0) || (iButton & IN_ATTACK && get_pdata_float(wpn, m_flNextPrimaryAttack, 4) <= 0.0))
			return
		
		if(iButton & IN_RELOAD && !iInReload) {
			if(iClip >= WPN_MAXCLIP) {
				entity_set_int(id, EV_INT_button, iButton & ~IN_RELOAD)
				set_wpnanim(id, 0)
			}
			else if(iClip == WPN_MAXCLIP) {
				if(iBpAmmo) {
					reload(id, wpn, 1)
				}
			}
		}
	}
}
public fw_Reload_Post(wpn)
{
	static id;
	id = get_pdata_cbase(wpn, m_pPlayer, 4)
	
	if(!is_user_alive(id)) 
		return HAM_IGNORED; 
	
	if(zp_get_human_special_class(id) == g_speciald && get_pdata_int(wpn, m_fInReload, 4))
		reload(id, wpn)

	return HAM_IGNORED;
}
public primary_attack(id)
{
	set_wpnanim(id, ANIM_FIRE)
	entity_set_vector(id, EV_VEC_punchangle, Float:{ -1.5, 0.0, 0.0 })
	
	emit_sound(id, CHAN_WEAPON, snd_hit, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	static iTarget, iBody, iEndOrigin[3], iStartOrigin[3]
	get_user_origin(id, iStartOrigin, 1) 
	get_user_origin(id, iEndOrigin, 3)
	fire_effects(iStartOrigin, iEndOrigin)
	get_user_aiming(id, iTarget, iBody)
	
	new iEnt = create_entity("info_target")
	
	static Float:flOrigin[3]
	IVecFVec(iEndOrigin, flOrigin)
	entity_set_origin(iEnt, flOrigin)
	remove_entity(iEnt)
	
	if(is_user_alive(iTarget) && zp_get_user_zombie(iTarget) || is_valid_ent(iTarget) && entity_get_float(iTarget, EV_FL_takedamage) != 0.0)
	{	
		if(HITSD > 0.0)
		{
			static Float:flVelocity[3]
			fm_get_user_velocity(iTarget, flVelocity)
			xs_vec_mul_scalar(flVelocity, HITSD, flVelocity)
			fm_set_user_velocity(iTarget, flVelocity)	
		}

		new Float:iDamage, iBloodScale

		if(iBody == HIT_HEAD) {
			iDamage = DAMAGE
			iBloodScale = 10
		}
		else {
			iDamage = DAMAGE*DAMAGE_MULTI
			iBloodScale = 25
		}
			
		if(is_user_alive(iTarget) && zp_get_user_zombie(iTarget)) 
		{
			#if ZPS_INC_VERSION < 44
			zp_set_extra_damage(iTarget, id, floatround(iDamage), "Plasma Rifle")
			#else
			zp_set_user_extra_damage(iTarget, id, floatround(iDamage), "Plasma Rifle", 1)
			#endif

			make_blood(iTarget, iBloodScale)
			damage_effects(iTarget)
		}
		else ExecuteHamB(Ham_TakeDamage, iTarget, 0, id, iDamage, DMG_BULLET) // Tirar dano de Boss
			
		emit_sound(id, CHAN_WEAPON, snd_fire, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)	
	}
}
stock fire_effects(iStartOrigin[3], iEndOrigin[3])
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(0)    
	write_coord(iStartOrigin[0])
	write_coord(iStartOrigin[1])
	write_coord(iStartOrigin[2])
	write_coord(iEndOrigin[0])
	write_coord(iEndOrigin[1])
	write_coord(iEndOrigin[2])
	write_short(g_sprBeam)
	write_byte(1) 
	write_byte(5) 
	write_byte(10) 
	write_byte(25) 
	write_byte(0) 
	write_byte(0)     
	write_byte(255)      
	write_byte(0)      
	write_byte(100) 
	write_byte(0) 
	message_end()
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)
	write_coord(iEndOrigin[0])
	write_coord(iEndOrigin[1])
	write_coord(iEndOrigin[2])
	write_short(g_sprExp)
	write_byte(10)
	write_byte(15)
	write_byte(4)
	message_end()	
}
stock reload(id, wpn, force_reload = 0)
{
	set_pdata_float(id, m_flNextAttack, RELOADSPEED, 5)
	set_wpnanim(id, ANIM_RELOAD)
	emit_sound(id, CHAN_WEAPON, snd_reload, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	if(force_reload)
		set_pdata_int(wpn, m_fInReload, 1, 4)
}
stock damage_effects(id)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, _, id)
	write_byte(0)
	write_byte(0)
	write_long(DMG_NERVEGAS)
	write_coord(0) 
	write_coord(0)
	write_coord(0)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade, {0,0,0}, id)
	write_short(1<<13)
	write_short(1<<14)
	write_short(0x0000)
	write_byte(0)
	write_byte(255)
	write_byte(0)
	write_byte(100) 
	message_end()
		
	message_begin(MSG_ONE, g_msgScreenShake, {0,0,0}, id)
	write_short(0xFFFF)
	write_short(1<<13)
	write_short(0xFFFF) 
	message_end()
}
stock make_blood(id, scale)
{
	new Float:iVictimOrigin[3]
	pev(id, pev_origin, iVictimOrigin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(115)
	write_coord(floatround(iVictimOrigin[0]+random_num(-20,20))) 
	write_coord(floatround(iVictimOrigin[1]+random_num(-20,20))) 
	write_coord(floatround(iVictimOrigin[2]+random_num(-20,20))) 
	write_short(g_sprBlood)
	write_short(g_sprBlood) 
	write_byte(248) 
	write_byte(scale) 
	message_end()
}
stock set_wpnanim(id, anim)
{
	entity_set_int(id, EV_INT_weaponanim, anim)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(entity_get_int(id, EV_INT_body))
	message_end()
}
stock make_punch(id, velamount) 
{
	static Float:flNewVelocity[3], Float:flCurrentVelocity[3]
	velocity_by_aim(id, -velamount, flNewVelocity)
	get_user_velocity(id, flCurrentVelocity)
	xs_vec_add(flNewVelocity, flCurrentVelocity, flNewVelocity)
	set_user_velocity(id, flNewVelocity)	
}

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

			* 1.2:
				- Fixed Zombie health (Some times zombies have same health as first zombie)
				- Fixed Bug that player sometimes don't turn into plasma when round starts

			* 1.3:
				- ZPSp 4.5 Support
				- Engine module is not used more here
*/

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta_util>
#include <cstrike>
#include <zombie_plague_special>
#include <amx_settings_api>

#if ZPS_INC_VERSION < 45
	#assert Zombie Plague Special 4.5 Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

/*-------------------------------------
--> Class Configs
--------------------------------------*/
#define Make_Acess ADMIN_IMMUNITY 	// Flag Acess make
new const sp_name[] = "Plasma"
new const sp_model[] = "vip"
new const sp_hp = 5000
new const sp_speed = 280
new const Float:sp_gravity = 0.8
new const sp_aura_size = 10
new const sp_clip_type = 2 // Unlimited Ammo (0 - Disable | 1 - Unlimited Semi Clip | 2 - Unlimited Clip)
new const sp_allow_glow = 1
new sp_color_rgb[3] = { 0, 255, 0 }

// Default Plasma Models
new const default_v_famas[] = "models/zombie_plague/plasma/v_plasma_fix.mdl"
new const default_p_famas[] = "models/zombie_plague/plasma/p_plasma.mdl"

const Float:FireRate = 0.2;
const Float:Hit_SD = 0.7;
const Float:Reload_Speed = 5.0;
const Float:Damage = 250.0;
const Float:Damage_Multi = 3.0;

new const weapon[] = "weapon_famas"
new const spr_beam[] = "sprites/plasma/plasma_beam.spr"
new const spr_exp[] = "sprites/plasma/plasma_exp.spr"
new const spr_blood[] = "sprites/blood.spr"
new const snd_fire[] = "zombie_plague/plasma/plasma_fire.wav"
new const snd_reload[] = "zombie_plague/plasma/plasma_reload.wav"
new const snd_draw[] = "zombie_plague/plasma/plasma_draw.wav"
new const snd_hit[] =  "zombie_plague/plasma/plasma_hit.wav"

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
	"zombie_plague/survivor1.wav"
}

/*-------------------------------------
--> Gamemode Config
--------------------------------------*/
new const g_chance = 90						// Gamemode chance
#define Start_Mode_Acess ADMIN_IMMUNITY

/*-------------------------------------
--> Variables/Defines/Const
--------------------------------------*/
new g_iCurWpn[33], Float:g_flLastFireTime[33], g_sprBeam, g_sprExp, g_sprBlood, g_msgDamage, g_msgScreenFade, g_msgScreenShake
new g_gameid, g_msg_sync, cvar_minplayers, g_special_id, v_famas_model[64], p_famas_model[64]

const m_pPlayer = 41
const m_fInReload = 54
const m_pActiveItem = 373
const m_flNextAttack = 83
const m_flTimeWeaponIdle = 48
const m_flNextPrimaryAttack = 46
const m_flNextSecondaryAttack =	47

const UNIT_SECOND = (1<<12)
const ENG_NULLENT = -1
const WPN_MAXCLIP = 25
const ANIM_FIRE = 5
const ANIM_DRAW = 10
const ANIM_RELOAD = 9

#define GetUserPlasma(%1) (zp_get_human_special_class(%1) == g_special_id)
#define IsPlasmaRound() (zp_get_current_mode() == g_gameid)

/*-------------------------------------
--> Plugin registeration.
--------------------------------------*/
public plugin_init() {
	// Plugin registeration.
	register_plugin("[ZPSp] Special Class: Plasma", "1.2", "[P]erfec[T] [S]cr[@]s[H] | Sh0oT3R")
	
	cvar_minplayers = register_cvar("zp_plasma_minplayers", "2")

	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	
	RegisterHam(Ham_Item_Deploy, weapon, "fw_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_Reload, weapon, "fw_Reload_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon, "fw_PostFrame")
	
	g_msgDamage = get_user_msgid("Damage")
	g_msgScreenFade = get_user_msgid("ScreenFade")
	g_msgScreenShake = get_user_msgid("ScreenShake")
	
	g_msg_sync = CreateHudSyncObj()
}

/*-------------------------------------
--> Plugin Precache
--------------------------------------*/
public plugin_precache() {
	g_gameid = zpsp_register_gamemode(sp_name, Start_Mode_Acess, g_chance, 0, ZP_DM_NONE)
	g_special_id = zp_register_human_special(sp_name, sp_model, sp_hp, sp_speed, sp_gravity, Make_Acess, sp_clip_type, sp_aura_size, sp_allow_glow, sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2])

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

	g_sprBlood = precache_model(spr_blood)
	g_sprBeam = precache_model(spr_beam)
	g_sprExp = precache_model(spr_exp)
	
	precache_sound(snd_fire)
	precache_sound(snd_hit)
	precache_sound(snd_reload)	
	precache_sound(snd_draw)
	
	static i;
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
	register_native("zp_get_user_plasma", "native_get_user_plasma")
	register_native("zp_make_user_plasma", "native_make_user_plasma")
	register_native("zp_get_plasma_count", "native_get_plasma_count")
	register_native("zp_is_plasma_round", "native_is_plasma_round")
}
public native_get_user_plasma(plugin_id, num_params)
	return GetUserPlasma(get_param(1));
	
public native_make_user_plasma(plugin_id, num_params)
	return zp_make_user_special(get_param(1), g_special_id, GET_HUMAN);
	
public native_get_plasma_count(plugin_id, num_params)
	return zp_get_special_count(GET_HUMAN, g_special_id);
	
public native_is_plasma_round(plugin_id, num_params)
	return (IsPlasmaRound());

/*-------------------------------------
--> Gamemode Functions
--------------------------------------*/
// Player spawn post
public zp_player_spawn_post(id) {
	if(IsPlasmaRound())
		zp_infect_user(id)
}

public zp_round_started_pre(game) {
	if(game != g_gameid)
		return PLUGIN_CONTINUE

	if(zp_get_alive_players() < get_pcvar_num(cvar_minplayers))
		return ZP_PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public zp_round_started(game, id) {
	if(game == g_gameid)
		start_plasma_mode();
}

// This function contains the whole code behind this game mode
start_plasma_mode() {
	static id, i, has_plasma
	has_plasma = false
	for (i = 1; i <= MaxClients; i++) {
		if(!is_user_alive(i))
			continue

		if(GetUserPlasma(i)) {
			id = i
			has_plasma = true
			break;
		}
	}

	if(!has_plasma) {
		id = zp_get_random_player()
		zp_make_user_special(id, g_special_id, GET_HUMAN)
	}
	
	static name[32]; get_user_name(id, name, charsmax(name));
	set_hudmessage(sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2], -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync, "%s is a %s", name, sp_name)
		
	// Turn the remaining players into zombies
	for (id = 1; id <= MaxClients; id++) {
		if(!is_user_alive(id))
			continue;
			
		if(GetUserPlasma(id) || zp_get_user_zombie(id))
			continue;
		
		zp_infect_user(id, 0, 1, 0) // Turn into a zombie
	}
}

/*-------------------------------------
--> Class Functions
--------------------------------------*/
public zp_extra_item_selected_pre(id, itemid) {
	if(GetUserPlasma(id))
		return ZP_PLUGIN_SUPERCEDE
	
	return PLUGIN_CONTINUE
}

// Weapon Model
public zp_fw_deploy_weapon(id, wpnid) {
	if (!is_user_alive(id))
		return PLUGIN_HANDLED;
	
	if(!GetUserPlasma(id))
		return PLUGIN_HANDLED;

	g_iCurWpn[id] = wpnid
	if (wpnid == CSW_FAMAS) {		
		set_pev(id, pev_viewmodel2, v_famas_model)
		set_pev(id, pev_weaponmodel2, p_famas_model)
	}
	return PLUGIN_HANDLED
}

public zp_user_humanized_post(id) {
	if(!GetUserPlasma(id))
		return;
	
	if(!zp_has_round_started())
		zp_set_custom_game_mod(g_gameid)
	
	zp_give_item(id, "weapon_famas", 1)
}
	
public fw_CmdStart(id, handle, seed) {
	if(!is_user_alive(id))
		return FMRES_IGNORED
	
	if(!GetUserPlasma(id) || zp_get_user_zombie(id))
		return FMRES_IGNORED
	
	if(g_iCurWpn[id] != CSW_FAMAS)
		return FMRES_IGNORED
		
	static iButton
	iButton = get_uc(handle, UC_Buttons)
	
	if(iButton & IN_ATTACK) {
		set_uc(handle, UC_Buttons, iButton & ~IN_ATTACK)
		
		static Float:flCurTime
		flCurTime = get_gametime()
		
		if(flCurTime - g_flLastFireTime[id] < FireRate)
			return FMRES_IGNORED
			
		static iWpnID, iClip
		iWpnID = get_pdata_cbase(id, m_pActiveItem, 5)
		iClip = cs_get_weapon_ammo(iWpnID)
		
		if(get_pdata_int(iWpnID, m_fInReload, 4))
			return FMRES_IGNORED
		
		set_pdata_float(iWpnID, m_flNextPrimaryAttack, FireRate, 4)
		set_pdata_float(iWpnID, m_flNextSecondaryAttack, FireRate, 4)
		set_pdata_float(iWpnID, m_flTimeWeaponIdle, FireRate, 4)
		g_flLastFireTime[id] = flCurTime
		if(iClip <= 0) {
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
public fw_UpdateClientData_Post(id, sendweapons, handle) {
	if(!is_user_alive(id))
		return FMRES_IGNORED
		
	if(!GetUserPlasma(id) || zp_get_user_zombie(id))
		return FMRES_IGNORED
	
	if(g_iCurWpn[id] != CSW_FAMAS)
		return FMRES_IGNORED
		
	set_cd(handle, CD_flNextAttack, get_gametime() + 0.001)
	return FMRES_HANDLED
}
public fw_Deploy_Post(wpn) {
	static id
	id = get_pdata_cbase(wpn, m_pPlayer, 4)
	
	if(!is_user_alive(id))
		return HAM_IGNORED;

	if(GetUserPlasma(id))
		set_wpnanim(id, ANIM_DRAW)

	return HAM_IGNORED
}

public fw_PostFrame(wpn) {
	static id
	id = get_pdata_cbase(wpn, m_pPlayer, 4)

	if(!is_user_alive(id))
		return;
	
	if(!GetUserPlasma(id))
		return;

	static Float:flNextAttack, iBpAmmo, iClip, iInReload, iRemClip
	iInReload = get_pdata_int(wpn, m_fInReload, 4)
	flNextAttack = get_pdata_float(id, m_flNextAttack, 5)
	iBpAmmo = cs_get_user_bpammo(id, CSW_FAMAS)
	iClip = cs_get_weapon_ammo(wpn)
	
	if(iInReload && flNextAttack <= 0.0) {
		iRemClip = min(WPN_MAXCLIP - iClip, iBpAmmo)
		cs_set_weapon_ammo(wpn, iClip + iRemClip)
		cs_set_user_bpammo(id, CSW_FAMAS, iBpAmmo-iRemClip)
		iInReload = 0
		set_pdata_int(wpn, m_fInReload, 0, 4)
	}
	static iButton
	iButton = pev(id, pev_button)

	if((iButton & IN_ATTACK2 && get_pdata_float(wpn, m_flNextSecondaryAttack, 4) <= 0.0) || (iButton & IN_ATTACK && get_pdata_float(wpn, m_flNextPrimaryAttack, 4) <= 0.0))
		return
	
	if(iButton & IN_RELOAD && !iInReload) {
		if(iClip >= WPN_MAXCLIP) {
			set_pev(id, pev_button, iButton & ~IN_RELOAD)
			set_wpnanim(id, 0)
		}
		else if(iClip == WPN_MAXCLIP) {
			if(iBpAmmo)
				reload(id, wpn, 1)
		}
	}
	
}
public fw_Reload_Post(wpn) {
	static id;
	id = get_pdata_cbase(wpn, m_pPlayer, 4)
	
	if(!is_user_alive(id)) 
		return HAM_IGNORED; 
	
	if(GetUserPlasma(id) && get_pdata_int(wpn, m_fInReload, 4))
		reload(id, wpn)

	return HAM_IGNORED;
}
public primary_attack(id) {
	set_wpnanim(id, ANIM_FIRE)
	set_pev(id, pev_punchangle, Float:{ -1.5, 0.0, 0.0 })
	
	emit_sound(id, CHAN_WEAPON, snd_hit, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	static iTarget, iBody, iEndOrigin[3], iStartOrigin[3]
	get_user_origin(id, iStartOrigin, 1) 
	get_user_origin(id, iEndOrigin, 3)
	fire_effects(iStartOrigin, iEndOrigin)
	get_user_aiming(id, iTarget, iBody)
	
	new iEnt = fm_create_entity("info_target")
	
	static Float:flOrigin[3]
	IVecFVec(iEndOrigin, flOrigin)
	fm_entity_set_origin(iEnt, flOrigin)
	fm_remove_entity(iEnt)
	
	if(is_user_alive(iTarget) && zp_get_user_zombie(iTarget) || pev_valid(iTarget) && pev(iTarget, pev_takedamage) != 0.0) {	
		if(Hit_SD > 0.0) {
			static Float:flVelocity[3]
			fm_get_user_velocity(iTarget, flVelocity)
			xs_vec_mul_scalar(flVelocity, Hit_SD, flVelocity)
			fm_set_user_velocity(iTarget, flVelocity)	
		}

		static Float:iDamage, iBloodScale
		if(iBody == HIT_HEAD) {
			iDamage = Damage
			iBloodScale = 10
		}
		else {
			iDamage = Damage*Damage_Multi
			iBloodScale = 25
		}
			
		if(is_user_alive(iTarget) && zp_get_user_zombie(iTarget)) {
			zp_set_user_extra_damage(iTarget, id, floatround(iDamage), "Plasma Rifle", 1)
			make_blood(iTarget, iBloodScale)
			Damage_effects(iTarget)
		}
		else ExecuteHamB(Ham_TakeDamage, iTarget, 0, id, iDamage, DMG_BULLET) // Tirar dano de Boss
			
		emit_sound(id, CHAN_WEAPON, snd_fire, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)	
	}
}
stock fire_effects(iStartOrigin[3], iEndOrigin[3]) {
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
stock reload(id, wpn, force_reload = 0) {
	set_pdata_float(id, m_flNextAttack, Reload_Speed, 5)
	set_wpnanim(id, ANIM_RELOAD)
	emit_sound(id, CHAN_WEAPON, snd_reload, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	if(force_reload)
		set_pdata_int(wpn, m_fInReload, 1, 4)
}
stock Damage_effects(id) {
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
stock make_blood(id, scale) {
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
stock set_wpnanim(id, anim) {
	set_pev(id, pev_weaponanim, anim)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}
stock make_punch(id, velamount) 
{
	static Float:flNewVelocity[3], Float:flCurrentVelocity[3]
	velocity_by_aim(id, -velamount, flNewVelocity)
	fm_get_user_velocity(id, flCurrentVelocity)
	xs_vec_add(flNewVelocity, flCurrentVelocity, flNewVelocity)
	fm_set_user_velocity(id, flNewVelocity)	
}

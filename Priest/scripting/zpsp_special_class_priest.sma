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
				- Fixed Bug that player sometimes don't turn into priest when round starts
			* 1.3:
				- ZPSp 4.5 Support.
				- P_ Model and W_ Model Support for antidote bomb
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
new const sp_name[] = "Priest"
new const sp_model[] = "zp_priest"
new const sp_hp = 7000
new const sp_speed = 280
new const Float:sp_gravity = 0.8
new const sp_aura_size = 15
new const sp_clip_type = 2 // Unlimited Ammo (0 - Disable | 1 - Unlimited Semi Clip | 2 - Unlimited Clip)
new const sp_allow_glow = 1
new sp_color_rgb[3] = { 100, 100, 255 }

// Default Models
new const default_v_knife[] = "models/zombie_plague/v_knife_priest.mdl"
new const default_p_knife[] = "models/zombie_plague/p_knife_priest.mdl"
new const default_v_antidote[] = "models/zombie_plague/v_antidote_priest.mdl"
new const default_p_antidote[] = "models/p_smokegrenade.mdl"
new const default_w_antidote[] = "models/w_smokegrenade.mdl"
new const sprite_grenade_trail[] = "sprites/laserbeam.spr"
new const sprite_grenade_ring[] = "sprites/shockwave.spr"

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
--> Variables/Defines
--------------------------------------*/
new g_gameid, g_special_id, g_msg_sync, cvar_minplayers, cvar_damage, cvar_flaregrenades, g_trailSpr, g_exploSpr
new v_knife_model[64], p_knife_model[64], v_antidote_model[64], p_antidote_model[64], w_antidote_model[64]
new const NADE_TYPE_ANTIDOTEBOMB = 10102
new const Float:RADIUS = 240.0

#define GetUserPriest(%1) (zp_get_human_special_class(%1) == g_special_id)
#define IsPriestRound() (zp_get_current_mode() == g_gameid)

/*-------------------------------------
--> Plugin registeration.
--------------------------------------*/
public plugin_init() {
	register_plugin("[ZPSp] Special Class: Priest", "1.2", "[P]erfec[T] [S]cr[@]s[H]")
	
	cvar_minplayers = register_cvar("zp_priest_minplayers", "2")
	cvar_damage = register_cvar("zp_priest_damage_multi", "1.5") 
	cvar_flaregrenades = get_cvar_pointer("zp_flare_grenades")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_event("CurWeapon","checkModel","be","1=1")
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	register_forward(FM_SetModel, "fw_SetModel")	

	g_msg_sync = CreateHudSyncObj()
}

/*-------------------------------------
--> Plugin Precache
--------------------------------------*/
public plugin_precache() {	
	g_gameid = zpsp_register_gamemode(sp_name, Start_Mode_Acess, g_chance, 0, ZP_DM_NONE)
	g_special_id = zp_register_human_special(sp_name, sp_model, sp_hp, sp_speed, sp_gravity, Make_Acess, sp_clip_type, sp_aura_size, sp_allow_glow, sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2])

	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_KNIFE PRIEST", v_knife_model, charsmax(v_knife_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_KNIFE PRIEST", default_v_knife)
		formatex(v_knife_model, charsmax(v_knife_model), default_v_knife)
	}
	precache_model(v_knife_model)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_KNIFE PRIEST", p_knife_model, charsmax(p_knife_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_KNIFE PRIEST", default_p_knife)
		formatex(p_knife_model, charsmax(p_knife_model), default_p_knife)
	}
	precache_model(p_knife_model)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_ANTIDOTE PRIEST", v_antidote_model, charsmax(v_antidote_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_ANTIDOTE PRIEST", default_v_antidote)
		formatex(v_antidote_model, charsmax(v_antidote_model), default_v_antidote)
	}
	precache_model(v_antidote_model)

	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_ANTIDOTE PRIEST", p_antidote_model, charsmax(p_antidote_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_ANTIDOTE PRIEST", default_p_antidote)
		formatex(p_antidote_model, charsmax(p_antidote_model), default_p_antidote)
	}
	precache_model(p_antidote_model)

	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "W_ANTIDOTE PRIEST", w_antidote_model, charsmax(w_antidote_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "W_ANTIDOTE PRIEST", default_w_antidote)
		formatex(w_antidote_model, charsmax(w_antidote_model), default_w_antidote)
	}
	precache_model(w_antidote_model)
	
	g_trailSpr = precache_model(sprite_grenade_trail)
	g_exploSpr = precache_model(sprite_grenade_ring)
	
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
	register_native("zp_get_user_priest", "native_get_user_priest")
	register_native("zp_make_user_priest", "native_make_user_priest")
	register_native("zp_get_priest_count", "native_get_priest_count")
	register_native("zp_is_priest_round", "native_is_priest_round")
}
public native_get_user_priest(plugin_id, num_params)
	return GetUserPriest(get_param(1));
	
public native_make_user_priest(plugin_id, num_params)
	return zp_make_user_special(get_param(1), g_special_id, GET_HUMAN);
	
public native_get_priest_count(plugin_id, num_params)
	return zp_get_special_count(GET_HUMAN, g_special_id);
	
public native_is_priest_round(plugin_id, num_params)
	return (IsPriestRound());

/*-------------------------------------
--> Gamemode Functions
--------------------------------------*/
// Player spawn post
public zp_player_spawn_post(id) {
	// Check for current mode
	if(IsPriestRound())
		zp_infect_user(id, 0, 1, 0)
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
		start_priest_mode()
}

// This function contains the whole code behind this game mode
start_priest_mode() {
	static id, i, has_priest
	has_priest = false
	for (i = 1; i <= MaxClients; i++) {
		if(!is_user_alive(i))
			continue;

		if(GetUserPriest(i)) {
			id = i
			has_priest = true
			break;
		}
	}

	if(!has_priest) {
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
			
		if(GetUserPriest(id) || zp_get_user_zombie(id))
			continue;
		
		zp_infect_user(id, 0, 1, 0) // Turn into a zombie
	}
}

/*-------------------------------------
--> Class functions
--------------------------------------*/
public checkModel(id) {
	if (!is_user_alive(id))
		return PLUGIN_HANDLED;
	
	if(!GetUserPriest(id)) 
		return PLUGIN_HANDLED;
	
	static userWpn;
	userWpn = get_user_weapon(id)
	if (userWpn == CSW_KNIFE) {
		set_pev(id, pev_viewmodel2, v_knife_model)
		set_pev(id, pev_weaponmodel2, p_knife_model)
	}
	if (userWpn == CSW_SMOKEGRENADE) {
		set_pev(id, pev_viewmodel2, v_antidote_model)
		set_pev(id, pev_viewmodel2, p_antidote_model)
	}
	return PLUGIN_HANDLED
}

// Knife Damage
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if(!is_user_alive(attacker) || !is_user_alive(victim))
		return HAM_IGNORED

	if(!GetUserPriest(attacker) || !zp_get_user_zombie(victim))
		return HAM_IGNORED

	if(get_user_weapon(attacker) == CSW_KNIFE) {
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_damage))
		zp_set_user_burn(victim, SET_WITHOUT_IMMUNIT)
	}

	return HAM_IGNORED
}

public zp_user_humanized_post(id) {
	if(!GetUserPriest(id))
		return;
		
	if(!zp_has_round_started())
		zp_set_custom_game_mod(g_gameid)
		
	zp_give_item(id,"weapon_smokegrenade")
	
	if(is_user_bot(id)) {
		remove_task(id)
		set_task(random_float(5.0, 15.0), "bot_support", id)
	}
}

public bot_support(id) {
	if(!is_user_alive(id))
		return;

	if(GetUserPriest(id) && user_has_weapon(id, CSW_SMOKEGRENADE)) {
		engclient_cmd(id, "weapon_smokegrenade");
		ExecuteHam(Ham_Weapon_PrimaryAttack, get_pdata_cbase(id, 373, 5));
	}
}

public fw_ThinkGrenade(entity) {
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
public fw_SetModel(entity, const model[]) {
	static Float:dmgtime, owner
	pev(entity, pev_dmgtime, dmgtime)

	if (dmgtime == 0.0)
		return FMRES_IGNORED
	
	if (!equal(model[7], "w_sm", 4))
		return FMRES_IGNORED;

	owner = pev(entity, pev_owner)		
		
	if(!GetUserPriest(owner)) 
		return FMRES_IGNORED;
		
	if(get_pcvar_num(cvar_flaregrenades) != 0) {
		changed = true
		set_pcvar_num(cvar_flaregrenades,0)	
	}
	
	fm_set_rendering(entity, kRenderFxGlowShell, sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2], kRenderNormal, 16)
	engfunc(EngFunc_SetModel, entity, w_antidote_model)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // TE id
	write_short(entity) // entity
	write_short(g_trailSpr) // sprite
	write_byte(10) // life
	write_byte(10) // width
	write_byte(sp_color_rgb[0]) // red
	write_byte(sp_color_rgb[1]) // green
	write_byte(sp_color_rgb[2]) // blue
	write_byte(200) // brightness
	message_end()
	
	set_pev(entity, pev_flTimeStepSound, NADE_TYPE_ANTIDOTEBOMB)
	return FMRES_SUPERCEDE;
}

public antidote_explode(ent) {
	if(changed) set_pcvar_num(cvar_flaregrenades,1)

	if (!zp_has_round_started()) 
		return;
	
	static Float:originF[3], attacker, victim
	pev(ent, pev_origin, originF)
	
	create_blast(originF)	
	attacker = pev(ent, pev_owner)
	victim = -1

	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, RADIUS)) != 0) {
		if (!is_user_alive(victim))
			continue;

		if(!zp_get_user_zombie(victim))
			continue;
		
		if(zp_get_user_last_zombie(victim) || zp_get_zombie_special_class(victim)) {
			zp_set_user_burn(victim, SET_WITHOUT_IMMUNIT)
			zp_set_user_frozen(victim, SET_WITHOUT_IMMUNIT)
			continue;
		}
		zp_disinfect_user(victim, 0, attacker)
	}
	engfunc(EngFunc_RemoveEntity, ent)
}

public create_blast(const Float:originF[3]) {
	static radius_shockwave, size, i
	size = 0
	radius_shockwave = floatround(RADIUS)
	while(radius_shockwave >= 60) {
		radius_shockwave -= 60
		size++
	}
	for(i = 0; i < 3; i++) {
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
		write_byte(TE_BEAMCYLINDER) // TE id
		engfunc(EngFunc_WriteCoord, originF[0]) // x
		engfunc(EngFunc_WriteCoord, originF[1]) // y
		engfunc(EngFunc_WriteCoord, originF[2]) // z
		engfunc(EngFunc_WriteCoord, originF[0]) // x axis
		engfunc(EngFunc_WriteCoord, originF[1]) // y axis
		engfunc(EngFunc_WriteCoord, originF[2]+385.0 + (i * 75.0)) // z axis
		write_short(g_exploSpr) // sprite
		write_byte(0) // startframe
		write_byte(0) // framerate
		write_byte(size) // life
		write_byte(60) // width
		write_byte(0) // noise
		write_byte(sp_color_rgb[0]) // red
		write_byte(sp_color_rgb[1]) // green
		write_byte(sp_color_rgb[2]) // blue
		write_byte(200) // brightness
		write_byte(0) // speed
		message_end()
	}
}

/*-------------------------------------
--> Stocks
--------------------------------------*/
stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) {
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);

	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, RenderColor);
	set_pev(entity, pev_rendermode, render);
	set_pev(entity, pev_renderamt, float(amount));

	return 1;
}

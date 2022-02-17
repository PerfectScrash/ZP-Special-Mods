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
					
				* 1.1:
					- Fixed Zombie health (Some times zombies have same health as first zombie)
					- Fixed Bug that player sometimes don't turn into plasma when round starts

*/

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <zombie_plague_special>
#include <amx_settings_api>

#if ZPS_INC_VERSION < 45
	#assert Zombie Plague Special 4.5 or higher Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

/*-------------------------------------
--> Ambience Config
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
--> Class Configs
--------------------------------------*/
#define Make_Acess ADMIN_IMMUNITY 	// Flag Acess make
new const sp_name[] = "Grenadier"
new const sp_model[] = "vip"
new const sp_hp = 5000
new const sp_speed = 250
new const Float:sp_gravity = 0.7
new const sp_aura_size = 15
new const sp_clip_type = 2
new const sp_allow_glow = 1
new sp_color_rgb[3] = { 100, 0, 255 }

// Default Models
new const default_v_knife[] = "models/v_knife.mdl"
new const default_p_knife[] = "models/p_knife.mdl"
new const default_v_kill[] = "models/v_smokegrenade.mdl"
new const default_p_kill[] = "models/p_smokegrenade.mdl"
new const default_w_kill[] = "models/w_smokegrenade.mdl"
new const sprite_grenade_trail[] = "sprites/laserbeam.spr"
new const sprite_grenade_ring[] = "sprites/shockwave.spr"
new const Float:Grenade_Radius = 240.0

/*-------------------------------------
--> Gamemode Config
--------------------------------------*/
new const g_chance = 90						// Gamemode chance
#define Start_Mode_Acess ADMIN_IMMUNITY

/*-------------------------------------
--> Variables/Defines
--------------------------------------*/
new g_gameid, g_msg_sync, cvar_minplayers, g_special_id, cvar_damage, cvar_flaregrenades, g_trailSpr, g_exploSpr
new v_knife_model[64], p_knife_model[64], v_kill_model[64], p_kill_model[64], w_kill_model[64]
new const NADE_TYPE_KILL = 3020
#define TASK_GIVE_GRENADE 132912

#define GetUserGrenadier(%1) (zp_get_human_special_class(%1) == g_special_id)
#define IsGrenadierRound() (zp_get_current_mode() == g_gameid)

public plugin_init() {
	// Plugin registeration.
	register_plugin("[ZPSp] Special Class: Grenadier", "1.0", "[P]erfec[T] [S]cr[@]s[H]")
	
	cvar_minplayers = register_cvar("zp_grenadier_minplayers", "2")
	cvar_damage = register_cvar("zp_grenadier_damage_multi", "1.5") 
	cvar_flaregrenades = get_cvar_pointer("zp_flare_grenades")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	register_forward(FM_SetModel, "fw_SetModel")	
	
	g_msg_sync = CreateHudSyncObj()
}

/*-------------------------------------
--> Precache
--------------------------------------*/
public plugin_precache() {
	g_gameid = zpsp_register_gamemode(sp_name, Start_Mode_Acess, g_chance, 0, 0)
	g_special_id = zp_register_human_special(sp_name, sp_model, sp_hp, sp_speed, sp_gravity, Make_Acess, sp_clip_type, sp_aura_size, sp_allow_glow, sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2])

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

	static i
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
	register_native("zp_get_user_grenadier", "native_get_user_grenadier")
	register_native("zp_make_user_grenadier", "native_make_user_grenadier")
	register_native("zp_get_grenadier_count", "native_get_grenadier_count")
	register_native("zp_is_grenadier_round", "native_is_grenadier_round")
}
public native_get_user_grenadier(plugin_id, num_params)
	return GetUserGrenadier(get_param(1));
	
public native_make_user_grenadier(plugin_id, num_params)
	return zp_make_user_special(get_param(1), g_special_id, GET_HUMAN);
	
public native_get_grenadier_count(plugin_id, num_params)
	return zp_get_special_count(GET_HUMAN, g_special_id);
	
public native_is_grenadier_round(plugin_id, num_params)
	return (IsGrenadierRound());

/*-------------------------------------
--> Gamemode functions
--------------------------------------*/
public zp_player_spawn_post(id) {
	// Check for current mode
	if(IsGrenadierRound())
		zp_infect_user(id, 0, 1, 0)
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

public zp_round_started(game) {
	if(game == g_gameid)
		start_grenadier_mode()
}

// This function contains the whole code behind this game mode
start_grenadier_mode() {
	static id, i, has_grenadier
	has_grenadier = false
	for (i = 1; i <= MaxClients; i++) {
		if(!is_user_alive(i))
			continue
		
		if(GetUserGrenadier(i)) {
			id = i
			has_grenadier = true
			break;
		}
	}

	if(!has_grenadier) {
		id = zp_get_random_player()
		zp_make_user_special(id, g_special_id, GET_HUMAN)
	}	
	
	static name[32]; get_user_name(id, name, charsmax(name));
	set_hudmessage(sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2], -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync, "%s is a %s", name, sp_name)
		
	// Turn the remaining players into zombies
	for (id = 0; id <= MaxClients; id++) {
		if(!is_user_alive(id))
			continue;
			
		if(GetUserGrenadier(id) || zp_get_user_zombie(id))
			continue;
			
		zp_infect_user(id, 0, 1) // Turn into a zombie
	}
}

/*-------------------------------------
--> Class Functions
--------------------------------------*/
public zp_extra_item_selected_pre(id, itemid) {
	if(GetUserGrenadier(id))
		return ZP_PLUGIN_SUPERCEDE
	
	return PLUGIN_CONTINUE
}

// Weapon Model
public zp_fw_deploy_weapon(id, wpnid) {
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	
	if(zp_get_user_zombie(id) || !GetUserGrenadier(id))
		return PLUGIN_CONTINUE;

	if(wpnid == CSW_KNIFE) {
		set_pev(id, pev_viewmodel2, v_knife_model)
		set_pev(id, pev_weaponmodel2, p_knife_model)
	}
	if(wpnid == CSW_SMOKEGRENADE) {
		set_pev(id, pev_viewmodel2, v_kill_model)
		set_pev(id, pev_weaponmodel2, p_kill_model)
	}
	return PLUGIN_CONTINUE
}

// Knife Damage
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if(!is_user_alive(attacker) || !is_user_alive(victim))
		return HAM_IGNORED
	
	if(GetUserGrenadier(attacker) && get_user_weapon(attacker) == CSW_KNIFE && zp_get_user_zombie(victim)) {
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_damage))
	}
	return HAM_IGNORED
}

// When player turn into a Grenadier
public zp_user_humanized_post(id) {
	if(!is_user_alive(id))
		return
	
	if(!GetUserGrenadier(id)) 
		return;
	
	if(!zp_has_round_started())
		zp_set_custom_game_mod(g_gameid)
		
	zp_give_item(id, "weapon_smokegrenade")
	set_task(3.0, "give_grenade", id+TASK_GIVE_GRENADE, _, _, "b")
}

// Give Grenade
public give_grenade(id) {
	id -= TASK_GIVE_GRENADE
	
	if(!is_user_alive(id)) {
		remove_task(id+TASK_GIVE_GRENADE)
		return;
	}
	if(!GetUserGrenadier(id)) {
		remove_task(id+TASK_GIVE_GRENADE)
		return
	}
	if(!user_has_weapon(id, CSW_SMOKEGRENADE))
		zp_give_item(id, "weapon_smokegrenade")

	// Bot Support (Some bots system not suports)
	if(is_user_bot(id) && user_has_weapon(id, CSW_SMOKEGRENADE)) {
		engclient_cmd(id, "weapon_smokegrenade");
		
		if(pev_valid(id) == 2)	
			ExecuteHam(Ham_Weapon_PrimaryAttack, get_pdata_cbase(id, 373, 5));
	}
}

// Think Grenade
public fw_ThinkGrenade(entity) {
	if(!pev_valid(entity))
		return HAM_IGNORED
	
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	if(dmgtime > get_gametime())
		return HAM_IGNORED	
		
	if(pev(entity, pev_flTimeStepSound) == NADE_TYPE_KILL)
		kill_explode(entity)
	
	return HAM_SUPERCEDE
}

// W_ Model Grenade Change
new changed
public fw_SetModel(entity, const model[]) {
	if(!pev_valid(entity))
		return FMRES_IGNORED	
	
	static Float:dmgtime, owner
	pev(entity, pev_dmgtime, dmgtime)
	
	if(dmgtime == 0.0)
		return FMRES_IGNORED
	
	if(!equal(model[7], "w_sm", 4))
		return FMRES_IGNORED

	owner = pev(entity, pev_owner)
	
	if(!is_user_connected(owner))
		return FMRES_IGNORED
	
	if(!GetUserGrenadier(owner)) 
		return FMRES_IGNORED
	
	if(get_pcvar_num(cvar_flaregrenades) != 0) {
		changed = true
		set_pcvar_num(cvar_flaregrenades, 0)	
	}
	
	engfunc(EngFunc_SetModel, entity, w_kill_model)
	fm_set_rendering(entity, kRenderFxGlowShell, sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2], kRenderNormal, 16)
	
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
	
	set_pev(entity, pev_flTimeStepSound, NADE_TYPE_KILL)
	return FMRES_SUPERCEDE	
}

// Kill Bomb Explodes
public kill_explode(ent) {
	if(!zp_has_round_started() || zp_has_round_ended() || !pev_valid(ent)) 
		return
	
	if(changed) set_pcvar_num(cvar_flaregrenades, 1)
	
	static Float:originF[3], attacker, victim
	pev(ent, pev_origin, originF)
	create_blast(originF)	
	attacker = pev(ent, pev_owner)
	victim = -1

	if(!is_user_connected(attacker)) {
		engfunc(EngFunc_RemoveEntity, ent)
		return;
	}
	while((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, Grenade_Radius)) != 0) {
		if(!is_user_alive(victim))
			continue;
		
		if(!zp_get_user_zombie(victim))
			continue;
		
		ExecuteHamB(Ham_Killed, victim, attacker, 0)
		zp_add_user_ammopacks(attacker, 2)	
	}
	engfunc(EngFunc_RemoveEntity, ent)
}

// Ring Effect
public create_blast(const Float:originF[3]) {
	static radius_shockwave, size, i
	size = 0
	radius_shockwave = floatround(Grenade_Radius)
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
		engfunc(EngFunc_WriteCoord, originF[2]+385.0 + (i * 85.0))  // z axis
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
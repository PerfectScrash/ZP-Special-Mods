/* 
	[ZPSp] Special Class: Antidoter 
	
	* Description:
		Cure zombies with vaccine of T-Virus

	* Cvars:
		- zp_antidoter_minplayers "2"			// Min players for start antidoter mod
		- zp_antidoter_damage_multi "2.0"		// Vaccine M4A1 Damage multi
		- zp_antidoter_knife_damage "1000"		// Knife Damage
		- zp_antidoter_disinfect_reward "2"		// Amount of ammo pack's reward

	* Changelog:
		- 1.0: First release.
		- 1.1: Fixed error log
		- 1.2: Added ZPSp 4.5 Support
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
new const sp_name[] = "Antidoter"
new const sp_model[] = "zpsp_antidoter_br"
new const sp_hp = 7000
new const sp_speed = 265
new const Float:sp_gravity = 0.65
new const sp_aura_size = 0
new const sp_clip_type = 2 // Unlimited Ammo (0 - Disable | 1 - Unlimited Semi Clip | 2 - Unlimited Clip)
new const sp_allow_glow = 0
new sp_color_rgb[3] = { 255, 255, 255 }

// Default M4A1/Knife Models
new const default_v_knife[] = "models/zombie_plague/v_knife_antidoter_br.mdl"
new const default_v_m4a1[] = "models/zombie_plague/v_m4a1_antidoter_br.mdl"
new const default_p_m4a1[] = "models/zombie_plague/p_m4a1_antidoter_br.mdl"

new const WeaponSounds[][] = {
	"zpsp_antidoter/fire_sound_silen.wav",
	"zpsp_antidoter/fire_sound.wav"
}

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
	{ "media/Half-Life02.mp3", 104.0 }
}

// Round start sounds
new const gamemode_round_start_snd[][] = { 
	"items/smallmedkit1.wav"
}

/*-------------------------------------
--> Gamemode Config
--------------------------------------*/
new const g_chance = 90						// Gamemode chance
#define Start_Mode_Acess ADMIN_IMMUNITY

/*-------------------------------------
--> Variables/Defines
--------------------------------------*/
new g_gameid, g_msg_sync, cvar_minplayers, g_special_id, cvar_damage, cvar_damage_knife
new v_m4a1_model[64], p_m4a1_model[64], v_knife_model[64], tracer_sprite, tracer_sprite2, g_orig_event
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX_WEAPONS = 4

#define GetUserAntidoter(%1) (zp_get_human_special_class(%1) == g_special_id)
#define IsAntidoterRound() (zp_get_current_mode() == g_gameid)

/*-------------------------------------
--> Plugin Registeration
--------------------------------------*/
public plugin_init() {
	register_plugin("[ZPSp] Special Class: Antidoter", "1.2", "[P]erfec[T] [S]cr[@]s[H]")
	register_dictionary("zpsp_class_antidoter.txt")
	
	cvar_minplayers = register_cvar("zp_antidoter_minplayers", "2")
	cvar_damage = register_cvar("zp_antidoter_damage_multi", "2.0") 
	cvar_damage_knife = register_cvar("zp_antidoter_knife_damage", "1000") 

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Weapon_Reload, "weapon_m4a1", "fw_Reload_Post", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m4a1", "fw_PrimaryAttack_Post", 1);
	register_forward(FM_PlaybackEvent, "fwPlaybackEvent")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)

	g_msg_sync = CreateHudSyncObj()
}

/*-------------------------------------
--> Plugin Precache
--------------------------------------*/
public plugin_precache() {
	register_forward(FM_PrecacheEvent, "fwPrecacheEvent_Post", 1)

	// Register our game mode
	g_gameid = zpsp_register_gamemode(sp_name, Start_Mode_Acess, g_chance, 0, 0, .uselang=1, .langkey="ANTIDOTER_CLASS_NAME")
	g_special_id = zp_register_human_special(sp_name, sp_model, sp_hp, sp_speed, sp_gravity, Make_Acess, sp_clip_type, sp_aura_size, sp_allow_glow, sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2])
	
	// Set lang configuration
	amx_save_setting_int(ZP_SPECIAL_CLASSES_FILE, fmt("H:%s", sp_name), "NAME BY LANG", 1)
	amx_save_setting_string(ZP_SPECIAL_CLASSES_FILE, fmt("H:%s", sp_name), "LANG KEY", "ANTIDOTER_CLASS_NAME")
	
		
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_M4A1 ANTIDOTER", v_m4a1_model, charsmax(v_m4a1_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_M4A1 ANTIDOTER", default_v_m4a1)
		formatex(v_m4a1_model, charsmax(v_m4a1_model), default_v_m4a1)
	}
	precache_model(v_m4a1_model)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_M4A1 ANTIDOTER", p_m4a1_model, charsmax(p_m4a1_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_M4A1 ANTIDOTER", default_p_m4a1)
		formatex(p_m4a1_model, charsmax(p_m4a1_model), default_p_m4a1)
	}
	precache_model(p_m4a1_model)

	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_KNIFE ANTIDOTER", v_knife_model, charsmax(v_knife_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_KNIFE ANTIDOTER", default_v_knife)
		formatex(v_knife_model, charsmax(v_knife_model), default_v_knife)
	}
	precache_model(v_knife_model)

	tracer_sprite = precache_model("sprites/blue.spr");
	tracer_sprite2 = precache_model("sprites/blue2.spr");

	static i
	// Precache weapon sound
	for(i = 0; i < sizeof WeaponSounds; i++)
		precache_sound(WeaponSounds[i])

	// Register round start sound
	for(i = 0; i < sizeof gamemode_round_start_snd; i++)
		zp_register_start_gamemode_snd(g_gameid, gamemode_round_start_snd[i])

	// Register ambience sounds
	for (i = 0; i < sizeof gamemode_ambiences; i++)
		zp_register_gamemode_ambience(g_gameid, gamemode_ambiences[i][AmbiencePrecache], gamemode_ambiences[i][AmbienceDuration], ambience_enable)

}

public fwPrecacheEvent_Post(type, const name[]) {
	if (equal("events/m4a1.sc", name)) {
		g_orig_event = get_orig_retval()
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

/*-------------------------------------
--> Natives
--------------------------------------*/
public plugin_natives() {
	register_native("zp_get_user_antidoter", "native_get_user_antidoter")
	register_native("zp_make_user_antidoter", "native_make_user_antidoter")
	register_native("zp_get_antidoter_count", "native_get_antidoter_count")
	register_native("zp_is_antidoter_round", "native_is_antidoter_round")
}
public native_get_user_antidoter(plugin_id, num_params)
	return GetUserAntidoter(get_param(1));
	
public native_make_user_antidoter(plugin_id, num_params)
	return zp_make_user_special(get_param(1), g_special_id, GET_HUMAN);
	
public native_get_antidoter_count(plugin_id, num_params)
	return zp_get_special_count(GET_HUMAN, g_special_id);
	
public native_is_antidoter_round(plugin_id, num_params)
	return (IsAntidoterRound());

/*-------------------------------------
--> Class/Weapon Functions
--------------------------------------*/
public zp_user_humanized_post(id) {
	if(!GetUserAntidoter(id)) 
		return;

	if(!zp_has_round_started())
		zp_set_custom_game_mod(g_gameid) // Force Start Antidoter Round
	
	zp_give_item(id, "weapon_m4a1", 1)
}
public fw_UpdateClientData_Post(Player, SendWeapons, CD_Handle) {
	if(!is_user_alive(Player))
		return FMRES_IGNORED

	if(zp_get_user_zombie(Player) || (get_user_weapon(Player) != CSW_M4A1) || !GetUserAntidoter(Player))
		return FMRES_IGNORED

	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001)
	return FMRES_HANDLED
}
public fwPlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2) {
	if ((eventid != g_orig_event))
		return FMRES_IGNORED

	if (!(1 <= invoker <= MaxClients))
		return FMRES_IGNORED

	if(!is_user_alive(invoker))
		return FMRES_IGNORED

	if(!GetUserAntidoter(invoker) || zp_get_user_zombie(invoker))
		return FMRES_IGNORED;

	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	return FMRES_SUPERCEDE
}

public fw_PrimaryAttack_Post(weapon_entity) {
	if (!pev_valid(weapon_entity))
		return HAM_IGNORED;

	static id;
	id = get_pdata_cbase(weapon_entity, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
	if (!(1 <= id <= MaxClients))
		return HAM_IGNORED
	
	if(!is_user_alive(id))
		return HAM_IGNORED;

	if(!GetUserAntidoter(id) || zp_get_user_zombie(id))
		return HAM_IGNORED;

	if(get_user_weapon(id) != CSW_M4A1)
		return HAM_IGNORED
	
	static szClip, szAmmo, HasSilen
	get_user_weapon(id, szClip, szAmmo)

	if(!szClip)
		return HAM_IGNORED

	HasSilen = cs_get_weapon_silen(weapon_entity)

	if(HasSilen) {
		Set_WeaponAnim(id, random_num(1, 3))
		emit_sound(id, CHAN_WEAPON, WeaponSounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	else {
		Set_WeaponAnim(id, random_num(8, 10))
		emit_sound(id, CHAN_WEAPON, WeaponSounds[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	
	static Float:plrViewAngles[3], Float:VecEnd[3], Float:VecDir[3], Float:PlrOrigin[3], hTrace, Float:VecSrc[3], Float:VecDst[3];
	pev(id, pev_v_angle, plrViewAngles);
	
	//VecSrc = pev->origin + pev->view_ofs;
	pev(id, pev_origin, PlrOrigin)
	pev(id, pev_view_ofs, VecSrc)
	xs_vec_add(VecSrc, PlrOrigin, VecSrc)

	//VecDst = VecDir * 8192.0;
	angle_vector(plrViewAngles, ANGLEVECTOR_FORWARD, VecDir);
	xs_vec_mul_scalar(VecDir, 8192.0, VecDst);
	xs_vec_add(VecDst, VecSrc, VecDst);
	
	hTrace = create_tr2()
	engfunc(EngFunc_TraceLine, VecSrc, VecDst, 0, id, hTrace)
	get_tr2(hTrace, TR_vecEndPos, VecEnd);

	create_tracer_water(id, VecSrc, VecEnd, HasSilen)
	free_tr2(hTrace);

	return HAM_IGNORED
}

public fw_Reload_Post(weapon_entity) {
	if (!pev_valid(weapon_entity))
		return HAM_IGNORED;

	static id;
	id = get_pdata_cbase(weapon_entity, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
	if(!is_user_alive(id))
		return HAM_IGNORED;

	if(!GetUserAntidoter(id) || zp_get_user_zombie(id))
		return HAM_IGNORED;

	if(get_user_weapon(id) != CSW_M4A1)
		return HAM_IGNORED

	Set_WeaponAnim(id, cs_get_weapon_silen(id) ? 4 : 11)

	return HAM_IGNORED;
}

public zp_fw_deploy_weapon(id, user_wpn) {
	if (!is_user_alive(id))
		return HAM_IGNORED;

	if(zp_get_user_zombie(id) || !GetUserAntidoter(id))
		return HAM_IGNORED

	if(user_wpn == CSW_M4A1)  {
		set_pev(id, pev_viewmodel2, v_m4a1_model)
		set_pev(id, pev_weaponmodel2, p_m4a1_model)
	}
	else if(user_wpn == CSW_KNIFE) {
		set_pev(id, pev_viewmodel2, v_knife_model)
		set_pev(id, pev_weaponmodel2, "")
	}

	return HAM_IGNORED
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if(!is_user_alive(attacker))
		return HAM_IGNORED;

	if(!GetUserAntidoter(attacker) || zp_get_user_zombie(attacker))
		return HAM_IGNORED;
	
	static userWpn
	userWpn = get_user_weapon(attacker)
	if(userWpn == CSW_M4A1) {
		damage *= get_pcvar_float(cvar_damage)

		if(pev(victim, pev_health) <= damage) {
			if(zp_get_user_zombie(victim) && !zp_get_user_last_zombie(victim)) {
				zp_disinfect_user(victim, 1, attacker)
				return HAM_SUPERCEDE;
			}
		}
		else if(!task_exists(victim)) {
			zp_set_user_rendering(victim, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 20)
			set_task(3.0, "reset_render", victim)
		}
	}
	else if(userWpn == CSW_KNIFE)
		damage = get_pcvar_float(cvar_damage_knife)

	SetHamParamFloat(4, damage)
	return HAM_IGNORED;
}

public reset_render(id) {
	if(!is_user_alive(id))
		return;

	zp_reset_user_rendering(id)
}

/*-------------------------------------
--> Gamemode Functions
--------------------------------------*/
public zp_player_spawn_post(id) {
	if(IsAntidoterRound())
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
		start_antidoter_mode();
}

start_antidoter_mode() {
	static id, i,  has_antidoter
	has_antidoter = false
	for (i = 1; i <= MaxClients; i++) {
		if(!is_user_alive(i))
			continue

		if(GetUserAntidoter(i)) {
			id = i
			has_antidoter = true
			break;
		}
	}

	if(!has_antidoter) {
		id = zp_get_random_player()
		zp_make_user_special(id, g_special_id, GET_HUMAN)
	}
	
	static name[32]; get_user_name(id, name, charsmax(name));
	set_hudmessage(sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2], -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "START_ANTIDOTER", name, LANG_PLAYER, "ANTIDOTER_CLASS_NAME")
		
	// Turn the remaining players into zombies
	for (id = 1; id <= MaxClients; id++) {
		if(!is_user_alive(id))
			continue;
			
		if(GetUserAntidoter(id) || zp_get_user_zombie(id))
			continue;

		zp_infect_user(id)
	}
}

/*-------------------------------------
--> Stocks
--------------------------------------*/
stock create_tracer_water(id, Float:fVec1[3], Float:fVec2[3], HasSilen) {
	if(!is_user_alive(id))
		return 0

	static iVec1[3];
	FVecIVec(fVec1, iVec1);

	static Float:origin[3], Float:vSrc[3], Float:angles[3], Float:v_forward[3], Float:v_right[3], Float:v_up[3], Float:gun_position[3], Float:player_origin[3], Float:player_view_offset[3];
	pev(id, pev_v_angle, angles);
	engfunc(EngFunc_MakeVectors, angles);
	global_get(glb_v_forward, v_forward);
	global_get(glb_v_right, v_right);
	global_get(glb_v_up, v_up);

	//m_pPlayer->GetGunPosition( ) = pev->origin + pev->view_ofs
	pev(id, pev_origin, player_origin);
	pev(id, pev_view_ofs, player_view_offset);
	xs_vec_add(player_origin, player_view_offset, gun_position);

	xs_vec_mul_scalar(v_forward, 24.0, v_forward);
	xs_vec_mul_scalar(v_right, 3.0, v_right);

	if ((pev(id, pev_flags) & FL_DUCKING) == FL_DUCKING)
		xs_vec_mul_scalar(v_up, 6.0, v_up);
	else
		xs_vec_mul_scalar(v_up, -2.0, v_up);

	xs_vec_add(gun_position, v_forward, origin);
	xs_vec_add(origin, v_right, origin);
	xs_vec_add(origin, v_up, origin);

	vSrc[0] = origin[0];
	vSrc[1] = origin[1];
	vSrc[2] = origin[2];

	new Float:dist = get_distance_f(vSrc, fVec2);
	new CountDrops = floatround(dist / 50.0);
	
	if (CountDrops > 20)
		CountDrops = 20;
	
	if (CountDrops < 2)
		CountDrops = 2;

	message_begin(MSG_PAS, SVC_TEMPENTITY, iVec1);
	write_byte(TE_SPRITETRAIL);
	engfunc(EngFunc_WriteCoord, vSrc[0]);
	engfunc(EngFunc_WriteCoord, vSrc[1]);
	engfunc(EngFunc_WriteCoord, vSrc[2]);
	engfunc(EngFunc_WriteCoord, fVec2[0]);
	engfunc(EngFunc_WriteCoord, fVec2[1]);
	engfunc(EngFunc_WriteCoord, fVec2[2]);
	write_short(tracer_sprite2); 
	write_byte(CountDrops); //count
	write_byte(0); //life  
	write_byte(1); //scale
	write_byte(60); //velocity
	write_byte(10); //rand_velocity
	message_end();

	message_begin(MSG_PAS, SVC_TEMPENTITY, iVec1);
	write_byte(TE_BEAMPOINTS);
	engfunc(EngFunc_WriteCoord, fVec2[0]);
	engfunc(EngFunc_WriteCoord, fVec2[1]);
	engfunc(EngFunc_WriteCoord, fVec2[2]);
	engfunc(EngFunc_WriteCoord, vSrc[0]);
	engfunc(EngFunc_WriteCoord, vSrc[1]);
	engfunc(EngFunc_WriteCoord, vSrc[2]);
	write_short(tracer_sprite); 
	write_byte(6); //starting_frame
	write_byte(200); //framerate
	write_byte(1); //life
	write_byte(HasSilen ? 30 : 80); //line width
	write_byte(0); //noise ampl
	write_byte(0); write_byte(50); write_byte(255);  //color
	write_byte(192); //brightness
	write_byte(250); //scroll speed
	message_end();

	return 1;
}

stock Set_WeaponAnim(id, anim) {
	if(!is_user_connected(id))
		return;

	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}
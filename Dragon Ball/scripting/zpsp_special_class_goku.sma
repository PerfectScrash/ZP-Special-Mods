/*===========================================================================================================
				[ZPSp] Special Class: Goku

		[Requeriments]
	* Amxmodx 1.9 or higher
	* Zombie Plague Special 4.5 or higher

		[Button Description]
	Press [E] Button for use a Skill

		[Cvars]
	zp_goku_minplayers "2"					// Min players for start a gamemode
	zp_goku_energy_second "70"				// Give X Energy every second
	zp_goku_energy_need "250"				// Amount required for transform
	zp_goku_damage_ki_blast "500"			// Damage of Ki Blast
	zp_goku_damage_kamehameha "850"			// Damage of Kamehameha
	zp_goku_damage_10x_kamehameha "1500"	// Damage of 10x Kamehameha
	zp_goku_damage_dragon_first "1000"		// Damage of Dragon First
	zp_goku_damage_spirit_bomb "3000"		// Damage of Spirit Bomb
	zp_goku_radius_ki_blast "100"			// Damage of Ki Blast
	zp_goku_radius_kamehameha "300"			// Damage of Kamehameha
	zp_goku_radius_10x_kamehameha "500"		// Damage of 10x Kamehameha
	zp_goku_radius_dragon_first "300"		// Damage of Dragon First
	zp_goku_radius_spirit_bomb "700"		// Damage of Spirit Bomb
	zp_goku_blast_decals "0"				// Decal Mark of attacks
	zp_goku_damage "500"					// "Knife" Damage
	zp_goku_ap_for_kill "2"					// Ammo pack for kill

		[Credits]
	[P]erfec[T] [S]cr[@]s[H]: For make this Gamemod/Special Class
	|RIC|_ALBANIAN, 0 and vittu: For Original Goku Code from SH Mode

===========================================================================================================*/

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_plague_special>
#include <amx_settings_api>

#if ZPS_INC_VERSION < 45
	#assert Zombie Plague Special 4.5 Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

/*-------------------------------------
--> Sound Config
--------------------------------------*/
// Ambience enums
enum _handler { AmbiencePrecache[64], Float:AmbienceDuration }

// Enable Ambience?
const ambience_enable = 1

// Ambience sounds
new const gamemode_ambiences[][_handler] = {	
	// Sounds					// Duration
	{ "zp_dragon_ball/ambience_dbz1.wav", 145.0 },
	{ "zp_dragon_ball/ambience_dbz3.wav", 110.0 },
	{ "zp_dragon_ball/ultimate_battle.mp3", 172.0 }
}

// Round start sounds
new const gamemode_round_start_snd[][] = { 
	"zombie_plague/survivor1.wav" 
}

new const Powerup_Sounds[][] = { "zp_dragon_ball/goku_powerup1.wav",	"zp_dragon_ball/goku_powerup2.wav", "zp_dragon_ball/goku_powerup3.wav", 
"zp_dragon_ball/goku_powerup4.wav", "zp_dragon_ball/goku_powerup5.wav" }

/*-------------------------------------
--> Class Configs
--------------------------------------*/
#define Make_Acess ADMIN_IMMUNITY 	// Flag Acess make
new const sp_name[] = "Goku"
new const sp_models[][] = { "dbz_goku", "dbz_goku2", "dbz_goku2", "dbz_goku3", "dbz_goku4", "dbz_goku5" }
new const sp_hp = 3000
new const sp_speed = 300
new const Float:sp_gravity = 0.5
new const sp_aura_size = 0
new const sp_clip_type = 2
new const sp_allow_glow = 0
new sp_color_rgb[3] = { 255, 255, 0 }
new const default_v_knife[] = "models/zombie_plague/v_knife_dbz.mdl"
new const POWER_CLASSNAME[] = "vexd_goku_power"

/*-------------------------------------
--> Gamemode Config
--------------------------------------*/
new const g_chance = 90						// Gamemode chance
#define Start_Mode_Acess ADMIN_IMMUNITY

/*-------------------------------------
--> Variables/Defines
--------------------------------------*/
new g_gameid, g_msg_sync[3], cvar_minplayers, g_special_id

// Goku Power Vars
new g_isSaiyanLevel[33], g_powerNum[33], g_spr_trail[4], g_spr_exp[3], g_powerID[33], v_knife_model[64],
g_maxRadius[33], g_maxDamage[33], g_ssj_lvl_energy[5], g_energy[33], g_spriteSmoke, cvar_goku_power[14], cvar_rwd
static const g_burnDecal[3] = {28, 29, 30}
static const g_burnDecalBig[3] = {46, 47, 48}

#define TASK_LOOP 33333

#define GetUserGoku(%1) (zp_get_human_special_class(%1) == g_special_id)
#define IsGokuRound() (zp_get_current_mode() == g_gameid)

/*-------------------------------------
--> Plugin registeration.
--------------------------------------*/
public plugin_init()
{
	register_plugin("[ZPSp] Special Class: Goku", "1.0", "[P]erfec[T] [S]cr[@]s[H]")
	register_dictionary("zp_dbm_classes.txt")
	
	cvar_minplayers = register_cvar("zp_goku_minplayers", "2")
	cvar_goku_power[0] = register_cvar("zp_goku_energy_second", "70")
	cvar_goku_power[1] = register_cvar("zp_goku_energy_need", "250")
	cvar_goku_power[2] = register_cvar("zp_goku_damage_ki_blast", "500")
	cvar_goku_power[3] = register_cvar("zp_goku_damage_kamehameha", "850")
	cvar_goku_power[4] = register_cvar("zp_goku_damage_10x_kamehameha", "1500")
	cvar_goku_power[5] = register_cvar("zp_goku_damage_spirit_bomb", "3000")
	cvar_goku_power[6] = register_cvar("zp_goku_radius_ki_blast", "100")
	cvar_goku_power[7] = register_cvar("zp_goku_radius_kamehameha", "300")
	cvar_goku_power[8] = register_cvar("zp_goku_radius_10x_kamehameha", "500")
	cvar_goku_power[9] = register_cvar("zp_goku_radius_spirit_bomb", "700")
	cvar_goku_power[10] = register_cvar("zp_goku_blast_decals", "0")
	cvar_goku_power[11] = register_cvar("zp_goku_damage", "500")
	cvar_goku_power[12] = register_cvar("zp_goku_damage_dragon_first", "1000")
	cvar_goku_power[13] = register_cvar("zp_goku_radius_dragon_first", "300")
	cvar_rwd = register_cvar("zp_goku_ap_for_kill", "2")

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	register_forward(FM_EmitSound, "fw_EmitSound")
	
	register_touch(POWER_CLASSNAME, "*",  "power_touch")
	register_think(POWER_CLASSNAME, "fw_power_think")
	
	g_msg_sync[0] = CreateHudSyncObj()
	g_msg_sync[1] = CreateHudSyncObj()
	g_msg_sync[2] = CreateHudSyncObj()
}

/*-------------------------------------
--> Plugin Precache
--------------------------------------*/
public plugin_precache()
{
	// Enable Infinite leap (BHOP) by default
	static Float:loaded
	if(!amx_load_setting_float(ZP_SPECIAL_CLASSES_FILE, fmt("H:%s", sp_name), "LEAP COOLDOWN", loaded))
		amx_save_setting_float(ZP_SPECIAL_CLASSES_FILE, fmt("H:%s", sp_name), "LEAP COOLDOWN", 0.0)

	// Knife model
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_KNIFE GOKU", v_knife_model, charsmax(v_knife_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_KNIFE GOKU", default_v_knife)
		formatex(v_knife_model, charsmax(v_knife_model), default_v_knife)
	}
	precache_model(v_knife_model)
	precache_sound("zp_dragon_ball/goku_ki_blast.wav")
	precache_sound("zp_dragon_ball/goku_kamehameha.wav")
	precache_sound("zp_dragon_ball/goku_dragon_first.wav")
	precache_sound("zp_dragon_ball/goku_10x_kamehameha.wav")
	precache_sound("zp_dragon_ball/goku_spirit_bomb.wav")
	precache_sound("player/pl_pain2.wav")
	precache_model("sprites/zp_dragon_ball/esf_ki_blast.spr")
	precache_model("sprites/zp_dragon_ball/esf_kamehameha_blue.spr")
	precache_model("sprites/zp_dragon_ball/dragon_first.spr")
	precache_model("sprites/zp_dragon_ball/esf_kamehameha_red.spr")
	precache_model("sprites/zp_dragon_ball/esf_spirit_bomb.spr")
	g_spr_trail[0] = precache_model("sprites/zp_dragon_ball/esf_trail_yellow.spr")
	g_spr_trail[1] = precache_model("sprites/zp_dragon_ball/esf_trail_blue.spr")
	g_spr_trail[2] = precache_model("sprites/zp_dragon_ball/esf_trail_red.spr")
	g_spr_trail[3] = precache_model("sprites/zp_dragon_ball/dragon_first_trail.spr")
	g_spr_exp[0] = precache_model("sprites/zp_dragon_ball/esf_exp_yellow.spr")
	g_spr_exp[1] = precache_model("sprites/zp_dragon_ball/esf_exp_blue.spr")
	g_spr_exp[2] = precache_model("sprites/zp_dragon_ball/esf_exp_red.spr")
	g_spriteSmoke = precache_model("sprites/wall_puff4.spr")
	
	// Register our game mode
	g_gameid = zpsp_register_gamemode(sp_name, Start_Mode_Acess, g_chance, 0, ZP_DM_NONE, .uselang=1, .langkey="GOKU_CLASS_NAME")
	g_special_id = zp_register_human_special(sp_name, sp_models[0], sp_hp, sp_speed, sp_gravity, Make_Acess, sp_clip_type, sp_aura_size, sp_allow_glow, sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2])

	// Set lang configuration
	amx_save_setting_int(ZP_SPECIAL_CLASSES_FILE, fmt("H:%s", sp_name), "NAME BY LANG", 1)
	amx_save_setting_string(ZP_SPECIAL_CLASSES_FILE, fmt("H:%s", sp_name), "LANG KEY", "GOKU_CLASS_NAME")

	static i
	for (i = 0; i < sizeof sp_models; i++) 
		precache_player_model(sp_models[i])

	for(i = 0; i < sizeof Powerup_Sounds; i++)
		precache_sound(Powerup_Sounds[i])

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
	register_native("zp_get_user_goku", "native_get_user_goku")
	register_native("zp_make_user_goku", "native_make_user_goku")
	register_native("zp_get_goku_count", "native_get_goku_count")
	register_native("zp_is_goku_round", "native_is_goku_round")
}

public native_get_user_goku(plugin_id, num_params)
	return GetUserGoku(get_param(1));
	
public native_make_user_goku(plugin_id, num_params)
	return zp_make_user_special(get_param(1), g_special_id, GET_HUMAN);
	
public native_get_goku_count(plugin_id, num_params)
	return zp_get_special_count(GET_HUMAN, g_special_id);
	
public native_is_goku_round(plugin_id, num_params)
	return (IsGokuRound());

/*-------------------------------------
--> Cache cvars
--------------------------------------*/
public plugin_cfg() set_task(0.5, "cache_cvars");
public cache_cvars() {
	static i;
	for(i = 0; i <= 4; i++)
		g_ssj_lvl_energy[i] = get_pcvar_num(cvar_goku_power[1]) * (i+1)
}

/*-------------------------------------
--> Gamemode functions
--------------------------------------*/
// Player spawn post
public zp_player_spawn_post(id)
{
	if (!is_user_alive(id))
		return;

	if(!GetUserGoku(id)) {
		g_isSaiyanLevel[id] = 0
		g_energy[id] = 0
		if(g_powerID[id] > 0) remove_power(id, g_powerID[id]);
		remove_task(id+TASK_LOOP)
	}

	// Check for current mode
	if(IsGokuRound())
		zp_infect_user(id)
}

public zp_round_started_pre(game)
{
	if(game != g_gameid) // Check if it is our game mode
		return PLUGIN_CONTINUE
	
	if(zp_get_alive_players() < get_pcvar_num(cvar_minplayers)) // Check for min players
		return ZP_PLUGIN_HANDLED

	start_goku_mode() // Start our new mode
	return PLUGIN_CONTINUE
}

public zp_game_mode_selected(gameid, id) {
	if(gameid == g_gameid) // Check if our game mode was called
		start_goku_mode()
}

// This function contains the whole code behind this game mode
start_goku_mode() {
	static id, i
	id = 0
	for (i = 1; i <= MaxClients; i++) {
		if(!is_user_alive(i))
			continue;

		if(!GetUserGoku(i))
			continue;

		id = i
		break;
	}
	if(!id) {
		id = zp_get_random_player()
		zp_make_user_special(id, g_special_id, GET_HUMAN)
	}
	
	static name[32]; get_user_name(id, name, charsmax(name));
	set_hudmessage(sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2], -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync[0], "%L", LANG_PLAYER, "AN_A_GOKU", name)
		
	// Turn the remaining players into zombies
	for (id = 1; id <= MaxClients; id++) {
		if(!is_user_alive(id))
			continue;
			
		if(GetUserGoku(id) || zp_get_user_zombie(id))
			continue;

		zp_infect_user(id)
	}
}

/*-------------------------------------
--> Class functions
--------------------------------------*/
public fw_PlayerKilled(victim, attacker, shouldgib) {
	if(!is_user_connected(attacker) || !is_user_connected(victim))
		return HAM_IGNORED;

	if(zp_get_human_special_class(attacker) == g_special_id)
		zp_add_user_ammopacks(attacker, get_pcvar_num(cvar_rwd))

	return HAM_IGNORED
}
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if(!is_user_alive(attacker))
		return HAM_IGNORED

	if(GetUserGoku(attacker) && get_user_weapon(attacker) == CSW_KNIFE)
		SetHamParamFloat(4, get_pcvar_float(cvar_goku_power[11]))

	return HAM_IGNORED
}

public zp_fw_deploy_weapon(id, wpnid) {
	if(wpnid != CSW_KNIFE)
		return PLUGIN_HANDLED;
	
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;
	
	if(GetUserGoku(id)) {
		entity_set_string(id, EV_SZ_viewmodel, v_knife_model)
		entity_set_string(id, EV_SZ_weaponmodel, "")
	}
	return PLUGIN_HANDLED
}

public zp_round_ended() {
	static id;
	for(id = 1; id <= MaxClients; id++)
		remove_goku_skills(id)
}

public zp_user_humanized_post(id)
{
	if(!is_user_connected(id))
		return;

	remove_goku_skills(id)

	if(GetUserGoku(id)) {
		if(!zp_has_round_started())
			zp_set_custom_game_mod(g_gameid)
			
		if(is_user_bot(id)) {
			remove_task(id)
			set_task(random_float(5.0, 15.0), "use_cmd", id, _, _, "b")
		}

		g_powerID[id] = 0
		set_task(1.0, "goku_loop", id+TASK_LOOP, _, _, "b")
		client_print_color(id, print_team_default, "%L", id, "GOKU_INFO")
	}
}

public zp_user_infected_post(id) remove_goku_skills(id);
public client_disconnected(id) remove_goku_skills(id);

public remove_goku_skills(id) {
	g_energy[id] = 0
	g_isSaiyanLevel[id] = 0
	if(g_powerID[id] > 0) remove_power(id, g_powerID[id]);
	remove_task(id+TASK_LOOP)
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch) {
	if(equal(sample, "common/wpn_denyselect.wav") && (pev(id, pev_button) & IN_USE))
		use_cmd(id); // Use power with IN_USE button
}

public use_cmd(id) {
	if(!is_user_alive(id) || zp_has_round_ended())
		return

	if(!GetUserGoku(id)) 
		return
	
	if(g_energy[id] < g_ssj_lvl_energy[0]) {
		client_print_color(id, print_team_default, "%L", id, "GOKU_NO_ENERGY")
		return
	}
	
	if(g_powerID[id]) {
		client_print_color(id, print_team_default, "%L", id, "GOKU_ONCE_POWER")
		return
	}
	
	if(g_energy[id] >= g_ssj_lvl_energy[0] && g_energy[id] < g_ssj_lvl_energy[1])
		power_attack(id, "GOKU_ATK1", "zp_dragon_ball/goku_ki_blast.wav", g_ssj_lvl_energy[0], get_pcvar_num(cvar_goku_power[2]), get_pcvar_num(cvar_goku_power[6]), 1)
	else if(g_energy[id] >= g_ssj_lvl_energy[1] && g_energy[id] < g_ssj_lvl_energy[2]) 
		power_attack(id, "GOKU_ATK2", "zp_dragon_ball/goku_kamehameha.wav", g_ssj_lvl_energy[1], get_pcvar_num(cvar_goku_power[3]), get_pcvar_num(cvar_goku_power[7]), 2)
	else if(g_energy[id] >= g_ssj_lvl_energy[2] && g_energy[id] < g_ssj_lvl_energy[3]) 
		power_attack(id, "GOKU_ATK3", "zp_dragon_ball/goku_dragon_first.wav", g_ssj_lvl_energy[2], get_pcvar_num(cvar_goku_power[12]), get_pcvar_num(cvar_goku_power[13]), 3)
	else if(g_energy[id] >= g_ssj_lvl_energy[3] && g_energy[id] < g_ssj_lvl_energy[4])
		power_attack(id, "GOKU_ATK4", "zp_dragon_ball/goku_10x_kamehameha.wav", g_ssj_lvl_energy[3], get_pcvar_num(cvar_goku_power[4]), get_pcvar_num(cvar_goku_power[8]), 4)
	else if(g_energy[id] >= g_ssj_lvl_energy[4])
		power_attack(id, "GOKU_ATK5", "zp_dragon_ball/goku_spirit_bomb.wav", g_ssj_lvl_energy[4], get_pcvar_num(cvar_goku_power[5]), get_pcvar_num(cvar_goku_power[9]), 5)
	
}

stock power_attack(const id, const attack_name[], const sound[], const remove_quantity, const max_dmg, const radius, const power_id) {
	if(!is_user_alive(id) || zp_has_round_ended())
		return 0
	
	if(GetUserGoku(id)) {
		client_print_color(id, print_team_default, "%L", id, attack_name)
		emit_sound(id, CHAN_STATIC, sound, 0.8, ATTN_NORM, 0, PITCH_NORM)
		g_energy[id] -= remove_quantity
		g_maxDamage[id] = max_dmg
		g_maxRadius[id] = radius
		g_powerNum[id] = power_id
		create_power(id)
		g_isSaiyanLevel[id] = 0
		zp_reset_player_model(id)
		return 1
	}
	return 0
}

public create_power(id) {
	static Float:vOrigin[3], Float:vAngles[3], Float:vAngle[3], entModel[60]
	static Float:entScale, Float:entSpeed, trailModel, trailLength, trailWidth
	static Float:VecMins[3], Float:VecMaxs[3]

	// Seting entSpeed higher then 2000.0 will not go where you aim
	// Vec Mins/Maxes must be below +-5.0 to make a burndecal
	switch(g_powerNum[id]) {
		case 1:{ // Ki-Blast
			entModel = "sprites/zp_dragon_ball/esf_ki_blast.spr"
			entScale = 0.20; entSpeed = 2000.0; trailModel = g_spr_trail[0]
			trailLength = 1; trailWidth = 2
			VecMins = Float:{ -1.0, -1.0, -1.0 }
			VecMaxs = Float:{ 1.0, 1.0, 1.0 }
		}
		case 2:{ // Kamehameha
			entModel = "sprites/zp_dragon_ball/esf_kamehameha_blue.spr"
			entScale = 1.20; entSpeed = 1500.0; trailModel = g_spr_trail[1]
			trailLength = 100; trailWidth = 8
			VecMins = Float:{ -2.0, -2.0, -2.0 }
			VecMaxs = Float:{ 2.0, 2.0, 2.0 }
		}
		case 3:{ // Dragon First
			entModel = "sprites/zp_dragon_ball/dragon_first.spr"
			entScale = 2.00; entSpeed = 1500.0
			trailModel = g_spr_trail[3]
			trailLength = 100; trailWidth = 16
			VecMins = Float:{ -3.0, -3.0, -3.0 }
			VecMaxs = Float:{ 3.0, 3.0, 3.0 }
		}
		case 4:{ // 10x Kamehameha
			entModel = "sprites/zp_dragon_ball/esf_kamehameha_red.spr"
			entScale = 2.00; entSpeed = 1000.0; trailModel = g_spr_trail[2]
			trailLength = 100; trailWidth = 16;
			VecMins = Float:{ -3.0, -3.0, -3.0 }
			VecMaxs = Float:{ 3.0, 3.0, 3.0 }
		}
		case 5:{ // Spirit Bomb (A Famosa Genkki Dama)
			entModel = "sprites/zp_dragon_ball/esf_spirit_bomb.spr"
			entScale = 0.70; entSpeed = 800.0
			VecMins = Float:{ -4.0, -4.0, -4.0 }
			VecMaxs = Float:{ 4.0, 4.0, 4.0 }
		}
	}

	// Get users postion and angles
	entity_get_vector(id, EV_VEC_origin, vOrigin)
	entity_get_vector(id, EV_VEC_angles, vAngles)
	entity_get_vector(id, EV_VEC_v_angle, vAngle)
	
	// Change height for entity origin
	if(g_powerNum[id] == 5) vOrigin[2] += 110
	else vOrigin[2] += 6

	new newEnt = create_entity("info_target")
	if(newEnt == 0) return

	g_powerID[id] = newEnt

	entity_set_string(newEnt, EV_SZ_classname, POWER_CLASSNAME)
	entity_set_model(newEnt, entModel)

	entity_set_vector(newEnt, EV_VEC_mins, VecMins)
	entity_set_vector(newEnt, EV_VEC_maxs, VecMaxs)

	entity_set_origin(newEnt, vOrigin)
	entity_set_vector(newEnt, EV_VEC_angles, vAngles)
	entity_set_vector(newEnt, EV_VEC_v_angle, vAngle)

	entity_set_int(newEnt, EV_INT_solid, 2)
	entity_set_int(newEnt, EV_INT_movetype, 5)
	entity_set_int(newEnt, EV_INT_rendermode, 5)
	entity_set_float(newEnt, EV_FL_renderamt, 255.0)
	entity_set_float(newEnt, EV_FL_scale, entScale)
	entity_set_edict(newEnt, EV_ENT_owner, id)

	// Create a VelocityByAim() function, but instead of users
	// eyesight make it start from the entity's origin - vittu
	static Float:fl_Velocity[3], AimVec[3], velOrigin[3]
	static Float:invTime, distance

	FVecIVec(vOrigin, velOrigin)

	get_user_origin(id, AimVec, 3)

	distance = get_distance(velOrigin, AimVec)

	// Stupid Check but lets make sure you don't devide by 0
	if(!distance) distance = 1

	invTime = entSpeed / distance

	fl_Velocity[0] = (AimVec[0] - vOrigin[0]) * invTime
	fl_Velocity[1] = (AimVec[1] - vOrigin[1]) * invTime
	fl_Velocity[2] = (AimVec[2] - vOrigin[2]) * invTime

	entity_set_vector(newEnt, EV_VEC_velocity, fl_Velocity)

	// No trail on Spirit Bomb
	if(g_powerNum[id] == 5) 
		return;

	// Set Trail on entity
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(22)			// TE_BEAMFOLLOW
	write_short(newEnt)		// entity:attachment to follow
	write_short(trailModel)	// sprite index
	write_byte(trailLength)	// life in 0.1's
	write_byte(trailWidth)	// line width in 0.1's
	write_byte(255)	//colour
	write_byte(255)
	write_byte(255)
	write_byte(255)	// brightness
	message_end()

	// Guiar o Kamehameha com o mouse
	if(g_powerNum[id] == 2 || g_powerNum[id] == 3 || g_powerNum[id] == 4) {
		entity_set_float(newEnt, EV_FL_fuser4, entSpeed)
		entity_set_float(newEnt, EV_FL_nextthink, get_gametime() + 0.1)
	}
}

public fw_power_think(ent) {
	if(!is_valid_ent(ent)) 
		return FMRES_IGNORED;

	static id, speed, Float:Velocity[3], Float:NewAngle[3];
	id = entity_get_edict(ent, EV_ENT_owner)
	if(!is_user_connected(id)) {
		power_touch(ent, 0)
		return FMRES_IGNORED
	}

	speed = floatround(entity_get_float(ent, EV_FL_fuser4))

	VelocityByAim(id, speed, Velocity)
	entity_set_vector(ent, EV_VEC_velocity, Velocity)
		
	entity_get_vector(id, EV_VEC_v_angle, NewAngle)
	entity_set_vector(ent, EV_VEC_angles, NewAngle)
	
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.1)
	return FMRES_IGNORED;
}

public power_touch(pToucher, pTouched) {
	if(pToucher <= 0) return
	if(!is_valid_ent(pToucher)) return

	static szClassName[32]
	entity_get_string(pToucher, EV_SZ_classname, szClassName, charsmax(szClassName))

	if(!equal(szClassName, POWER_CLASSNAME))
		return;

	static attacker, dmgRadius, maxDamage, Float:fl_vExplodeAt[3], damageName[16], spriteExp, vExplodeAt[3]

	attacker = entity_get_edict(pToucher, EV_ENT_owner)
	dmgRadius = g_maxRadius[attacker]
	maxDamage = g_maxDamage[attacker]
	spriteExp = g_spr_exp[0]

	switch(g_powerNum[attacker]){
		case 1: damageName = "Ki Blast"
		case 2:{
			damageName = "Kamehameha"
			spriteExp = g_spr_exp[1]
		}
		case 3: damageName = "Dragon First"
		case 4:{
			damageName = "10x Kamehameha"
			spriteExp = g_spr_exp[2]
		}
		case 5: damageName = "Spirit Bomb"
	}

	entity_get_vector(pToucher, EV_VEC_origin, fl_vExplodeAt)

	vExplodeAt[0] = floatround(fl_vExplodeAt[0])
	vExplodeAt[1] = floatround(fl_vExplodeAt[1])
	vExplodeAt[2] = floatround(fl_vExplodeAt[2])

	static VicOrigin[3], Float:dRatio,  distance, damage, victim // Cause the Damage
	static Float:fl_Time, Float:fl_VicVelocity[3], blastSize
	for (victim = 1; victim <= MaxClients; victim++) {
		if(!is_user_alive(victim)) continue
		if(!zp_get_user_zombie(victim)) continue

		get_user_origin(victim, VicOrigin)
		distance = get_distance(vExplodeAt, VicOrigin)

		if(distance >= dmgRadius) 
			continue;

		dRatio = floatdiv(float(distance), float(dmgRadius))
		damage = maxDamage - floatround(maxDamage * dRatio)

		zp_set_user_extra_damage(victim, attacker, damage, damageName, 1)
		
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), _, victim)
		write_short((1<<12)*75) // amplitude
		write_short((1<<12)*7) // duration
		write_short((1<<12)*75) // frequency
		message_end()
		
		emit_sound(victim, CHAN_BODY, "player/pl_pain2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)

		fl_Time = distance / 125.0

		fl_VicVelocity[0] = (VicOrigin[0] - vExplodeAt[0]) / fl_Time
		fl_VicVelocity[1] = (VicOrigin[1] - vExplodeAt[1]) / fl_Time
		fl_VicVelocity[2] = (VicOrigin[2] - vExplodeAt[2]) / fl_Time
		entity_set_vector(victim, EV_VEC_velocity, fl_VicVelocity)
	}

	// Make some Effects
	blastSize = floatround(dmgRadius / 12.0)

	// Explosion Sprite
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(23)			//TE_GLOWSPRITE
	write_coord(vExplodeAt[0])
	write_coord(vExplodeAt[1])
	write_coord(vExplodeAt[2])
	write_short(spriteExp)	// model
	write_byte(01)			// life 0.x sec
	write_byte(blastSize)	// size
	write_byte(255)		// brightness
	message_end()

	// Explosion (smoke, sound/effects)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)			//TE_EXPLOSION
	write_coord(vExplodeAt[0])
	write_coord(vExplodeAt[1])
	write_coord(vExplodeAt[2])
	write_short(g_spriteSmoke)		// model
	write_byte(blastSize+5)	// scale in 0.1's
	write_byte(20)			// framerate
	write_byte(10)			// flags
	message_end()

	// Create Burn Decals, if they are used
	if(get_pcvar_num(cvar_goku_power[10])) {
		static decal_id; // Change burn decal according to blast size
		decal_id = (blastSize <= 18) ? g_burnDecal[random_num(0,2)] : g_burnDecalBig[random_num(0,2)]

		// Create the burn decal
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(109)		//TE_GUNSHOTDECAL
		write_coord(vExplodeAt[0])
		write_coord(vExplodeAt[1])
		write_coord(vExplodeAt[2])
		write_short(0)			//?
		write_byte(decal_id)	//decal
		message_end()
	}

	remove_entity(pToucher)
	g_powerNum[attacker] = 0
	g_powerID[attacker] = 0
}

public remove_power(id, powerID)
{
	if(!is_valid_ent(powerID)) 
		return;
	
	static szClassName[32], Float:fl_vOrigin[3]
	entity_get_string(powerID, EV_SZ_classname, szClassName, charsmax(szClassName))

	if(equal(szClassName, POWER_CLASSNAME) && id == entity_get_edict(powerID, EV_ENT_owner)) {
		entity_get_vector(powerID, EV_VEC_origin, fl_vOrigin)
			
		// Create an effect of kamehameha being removed
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(14)		//TE_IMPLOSION
		write_coord(floatround(fl_vOrigin[0]))
		write_coord(floatround(fl_vOrigin[1]))
		write_coord(floatround(fl_vOrigin[2]))
		write_byte(200)	// radius
		write_byte(40)		// count
		write_byte(45)		// life in 0.1's
		message_end()

		g_powerNum[id] = 0
		g_powerID[id] = 0

		remove_entity(powerID)
	}
}

public goku_loop(id) {
	id -= TASK_LOOP

	if(!is_user_alive(id) || zp_has_round_ended()) {
		remove_task(id+TASK_LOOP)
		remove_goku_skills(id)
		return;
	}
	
	if(!GetUserGoku(id)) {
		remove_task(id+TASK_LOOP)
		remove_goku_skills(id)
		return;
	}

	set_hudmessage(0, 100, 255, -1.0, 0.7, 0, 1.0, 1.1, 0.0, 0.0, -1)
	ShowSyncHudMsg(id, g_msg_sync[1], "%L", id, "GOKU_HUD", g_energy[id], g_isSaiyanLevel[id])
	
	if(g_energy[id] < g_ssj_lvl_energy[4]) {
		if(g_energy[id] + get_pcvar_num(cvar_goku_power[0]) > g_ssj_lvl_energy[4]) 
			g_energy[id] = g_ssj_lvl_energy[4]
		else
			g_energy[id] += get_pcvar_num(cvar_goku_power[0])
	}
	
	if(g_energy[id] < g_ssj_lvl_energy[0] && g_isSaiyanLevel[id] > 0) {
		g_isSaiyanLevel[id] = 0;
	}
	else {
		static name[32], i, rgb[3], ok; 
		for(i = 1; i <= 5; i++) {
			if(i != 5) {
				if(g_energy[id] < g_ssj_lvl_energy[i]) ok = true
				else ok = false
			}
			else ok = true

			if(g_energy[id] >= g_ssj_lvl_energy[i-1] && ok && g_isSaiyanLevel[id] < i) {
				g_isSaiyanLevel[id] = i
				switch(i) {
					case 1..3: rgb = { 255, 255, 0 }
					case 4: rgb = { 255, 0, 0 }
					case 5: rgb = { 255, 255, 255 }
				}

				set_hudmessage(rgb[0], rgb[1], rgb[2], -1.0, 0.25, 0, 0.25, 3.0, 0.0, 0.0, 84)

				if(IsGokuRound() && i == 5) {
					get_user_name(id, name, charsmax(name))
					ShowSyncHudMsg(0, g_msg_sync[2], "%L", LANG_PLAYER, "GOKU_TURN_INTO_SSJ_ALL", name, i)
				}
				else
					ShowSyncHudMsg(id, g_msg_sync[2], "%L", id, "GOKU_TURN_INTO_SSJ", i)

				emit_sound(id, CHAN_STATIC, Powerup_Sounds[i-1], 0.8, ATTN_NORM, 0, PITCH_NORM)

				zp_reset_player_model(id)

				break;
			}
		}
	}
}
public zp_user_model_change_pre(id, model[])
{
	if(!is_user_alive(id) || zp_has_round_ended())
		return PLUGIN_CONTINUE;
	
	if(!GetUserGoku(id))
		return PLUGIN_CONTINUE;

	if(!equal(model, sp_models[g_isSaiyanLevel[id]]))
		zp_set_param_string(sp_models[g_isSaiyanLevel[id]])

	return PLUGIN_CONTINUE;
}

precache_player_model(const modelname[]) {
	static longname[128] , index
	formatex(longname, charsmax(longname), "models/player/%s/%s.mdl", modelname, modelname)  	
	index = engfunc(EngFunc_PrecacheModel, longname) 
	
	copy(longname[strlen(longname)-4], charsmax(longname) - (strlen(longname)-4), "T.mdl") 
	if(file_exists(longname)) engfunc(EngFunc_PrecacheModel, longname) 
	
	return index
}
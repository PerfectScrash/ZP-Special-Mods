/* 
	[ZPSp] Special Class: Shadow the Hedgehog

	* Description:
		- Same sonic skills but in zombie team

	* Skills
		- [E] Button: Boost
		- [R] Button: Spin Dash
		- [Spacebar] Button (In Air): Homming Attack

	* Cvars:
		- zp_shadow_minplayers "2"				// Minplayers for start a Shadow Mode
		- zp_shadow_damage_multi "3.0"			// Shadow "Knife" damage multi
		- zp_shadow_damage_homming_attack "500"	// Homming Attack Damage
		- zp_shadow_damage_spindash "50"		// Spin Dash Damage
		- zp_shadow_damage_boost "30"			// Boost Damage
		- zp_shadow_boost_gauge "10"			// Boost Gauge
		- zp_shadow_boost_give "2"				// Give gauge ammount when kill a player

	* Changelog
		- 1.0: First Release

		- 1.1:
			- ZPSp 4.5 Support
			- Improved Camera and homming shoot aim

		- 1.2:
			- Fixed Homming Shoot Aim
			- Added cvars: "zp_sonic_boost_gauge" and "zp_sonic_boost_give"

	* Credits:
		- [P]erfect [S]crash: For Editing Model Animation, sound and for Create this Plugin
		- William: For Camera Code
*/


#include <amxmodx>
#include <hamsandwich>
#include <fakemeta_util>
#include <engine>
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
	{ "sound/zpsp_sonic/shadow_ambience.mp3", 268.0 }
}

// Round start sounds
new const gamemode_round_start_snd[][] = { 
	"zpsp_sonic/round_start_sega.wav"
}

/*-------------------------------------
--> Class Configs
--------------------------------------*/
#define Make_Acess ADMIN_IMMUNITY 	// Flag Acess make
new const sp_name[] = "Shadow"
new const sp_model[] = "zpsp_shadow"
new const sp_knifemodel[] = "models/v_knife.mdl"
new const sp_painsound[] = "player/pl_pain2.wav"
new const sp_hp = 10000
new const sp_speed = 350
new const Float:sp_gravity = 0.4
new const sp_aura_size = 0
new const Float:sp_knockback = 0.25
new const sp_allow_glow = 0
new sp_color_rgb[3] =  { 255, 69, 0 }

enum { SND_BOOST = 0, SND_JUMP, SND_HOMMING_AIM, SND_HOMMING_ATTACK, SND_SPIN_START, SND_SPIN_UNLEASH }
new const skill_sounds[][] = {
	"zpsp_sonic/boost.wav",
	"zpsp_sonic/jump.wav",
	"zpsp_sonic/homming_lockon.wav",
	"zpsp_sonic/homming_attack.wav",
	"zpsp_sonic/spindash_start.wav",
	"zpsp_sonic/spindash_unleash.wav"
}

/*-------------------------------------
--> Gamemode Config
--------------------------------------*/
new const g_chance = 90						// Gamemode chance
#define Start_Mode_Acess ADMIN_IMMUNITY

// Variables
new g_gameid, g_msg_sync, cvar_minplayers, cvar_shadow_damage, g_special_id
new Float:Time1, Float:fAim[3], Float:User_fVelocity[3][33], Float:Time_Bot[33], Float:Time_skill[33];

enum {
	HOMMING_ATTACK = 1,
	ATTACK_SPINDASH,
	ATTACK_BOOST
}
#define TASK_SPIN_DASH 120312
#define TASK_HUD_BOOST 213121
#define TASK_HOMMING_ATTACK 1230912

new g_spin_force[33], g_in_dash_attack[33], cvar_attack_damage[3], g_sequence_anim[33], g_boost_gauge[33], created_aim, g_sonic_id
new g_homming_target[33], used_homming[33], g_ShadowTrail, have_trail[33], cvar_camera_distance, g_pl_cam_ent[33], cvar_boost_gauge, cvar_boost_give

#define CAMERA_OWNER EV_INT_iuser4
#define CAMERA_CLASSNAME "shadow_camera"
#define CAMERA_MODEL "models/rpgrocket.mdl"
#define HOMMING_AIM_CLASSNAME "zpsp_shadow_homming_aim"
#define HOMMING_MODEL "models/zpsp_homming_aim.mdl"

#define GetUserShadow(%1) (zp_get_zombie_special_class(%1) == g_special_id) 
#define IsShadowMode() (zp_get_current_mode() == g_gameid)
#define zp_get_user_sonic(%1) (zp_get_human_special_class(%1) == g_sonic_id)

public plugin_init() {
	// Plugin registeration.
	register_plugin("[ZPSp] Special Class: Shadow", "1.2", "[P]erfec[T] [S]cr[@]s[H]")
	register_dictionary("zpsp_sonic_shadow.txt")
	
	cvar_minplayers = register_cvar("zp_shadow_minplayers", "2")
	cvar_shadow_damage = register_cvar("zp_shadow_damage_multi", "3.0")
	cvar_camera_distance = register_cvar("zp_shadow_cam_distance", "250")
	cvar_attack_damage[HOMMING_ATTACK-1] = register_cvar("zp_shadow_damage_homming_attack", "500") 
	cvar_attack_damage[ATTACK_SPINDASH-1] = register_cvar("zp_shadow_damage_spindash", "50") 
	cvar_attack_damage[ATTACK_BOOST-1] = register_cvar("zp_shadow_damage_boost", "30") 
	cvar_boost_gauge = register_cvar("zp_shadow_boost_gauge", "10")
	cvar_boost_give = register_cvar("zp_shadow_boost_give", "2") 

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage", 0, true)
	register_forward(FM_AddToFullPack, "forward_AddToFullPack", 1); 
	register_forward(FM_Touch, "fw_Touch")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1, true)
	register_forward(FM_SetView, "FakeMeta_SetView_Pre", false);
	RegisterHam(Ham_Think, "trigger_camera", "HamHook_CameraThink_Pre", false);
	
	g_msg_sync = CreateHudSyncObj()
	g_sonic_id = zp_get_special_class_id(GET_HUMAN, "Sonic")
}

// Game modes MUST be registered in plugin precache ONLY
public plugin_precache() {
	// Register Special Class and Game mod
	g_gameid = zpsp_register_gamemode(sp_name, Start_Mode_Acess, g_chance, 0, ZP_DM_NONE, .uselang=1, .langkey="SHADOW_CLASSNAME")
	g_special_id = zp_register_zombie_special(sp_name, sp_model, sp_knifemodel, sp_painsound, sp_hp, sp_speed, sp_gravity, Make_Acess, sp_knockback, sp_aura_size, sp_allow_glow, sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2])

	// Set lang configuration
	amx_save_setting_int(ZP_SPECIAL_CLASSES_FILE, fmt("Z:%s", sp_name), "NAME BY LANG", 1)
	amx_save_setting_string(ZP_SPECIAL_CLASSES_FILE, fmt("Z:%s", sp_name), "LANG KEY", "SHADOW_CLASSNAME")

	precache_model(CAMERA_MODEL)
	precache_model(HOMMING_MODEL)
	g_ShadowTrail = precache_model("sprites/laserbeam.spr")
	
	static i;
	for(i = 0; i < sizeof skill_sounds; i++)
		precache_sound(skill_sounds[i])

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
	register_native("zp_get_user_shadow", "native_get_user_shadow")
	register_native("zp_make_user_shadow", "native_make_user_shadow")
	register_native("zp_get_shadow_count", "native_get_shadow_count")
	register_native("zp_is_shadow_round", "native_is_shadow_round")
	register_native("zp_is_shadow_enable", "native_is_shadow_enable")
}

// Native: zp_get_user_shadow(id)
public native_get_user_shadow(plugin_id, num_params) 
	return GetUserShadow(get_param(1));

// Native: zp_make_user_shadow(id)
public native_make_user_shadow(plugin_id, num_params) 
	return (zp_make_user_special(get_param(1), g_special_id, GET_ZOMBIE));

// Native: zp_get_shadow_count()
public native_get_shadow_count(plugin_id, num_params)
	return zp_get_special_count(GET_ZOMBIE, g_special_id);

// Native: zp_is_shadow_round()
public native_is_shadow_round(plugin_id, num_params)
	return IsShadowMode();

// Native: zp_is_shadow_enable()
public native_is_shadow_enable(plugin_id, num_params) 
	return (zp_is_special_class_enable(GET_ZOMBIE, g_special_id));

// Attack Damage
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if(!is_user_connected(victim) || !is_user_connected(attacker))
		return HAM_IGNORED
	
	if(inflictor == attacker && GetUserShadow(attacker))
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_shadow_damage))

	// Prevent damage fall (Some times happens when use Homming Attack)
	if(damage_type & DMG_FALL && GetUserShadow(victim))
		return HAM_SUPERCEDE;
		
	return HAM_IGNORED
}

// Player spawn post
public zp_player_spawn_post(id) {
	// Check for current mode
	if(IsShadowMode())
		zp_disinfect_user(id)

	if(!GetUserShadow(id) && g_pl_cam_ent[id])
		reset_shadow_vars(id, 1);

	client_cmd(id, "-duck")
	client_cmd(id, "-duck")
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
	if(game == g_gameid)
		start_shadow_mode()
}

// This function contains the whole code behind this game mode
start_shadow_mode() {
	static id, i, has_shadow
	has_shadow = false
	for (i = 1; i <= MaxClients; i++) {
		if(!is_user_alive(i))
			continue;

		if(GetUserShadow(i)) {
			id = i						// Get Shadow Index
			has_shadow = true
			break;
		}
	}

	if(!has_shadow) {
		id = zp_get_random_player()
		zp_make_user_special(id, g_special_id, GET_ZOMBIE)
	}
	
	static name[32]; get_user_name(id, name, charsmax(name));
	set_hudmessage(sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2], -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "START_SHADOW", name)
	ScreenFade(0, 5, sp_color_rgb, 255)
}

public zp_user_infected_post(id) {
	if(GetUserShadow(id)) 
	{
		if(!zp_has_round_started())
			zp_set_custom_game_mod(g_gameid)	// Force Start Shadow Round
		
		//reset_shadow_vars(id, 0)

		g_boost_gauge[id] = get_pcvar_num(cvar_boost_gauge)

		if(is_user_bot(id)) {
			Time_Bot[id] = get_gametime()
			Time_skill[id] = random_float(5.0, 10.0)
		}
		else {
			if(!g_pl_cam_ent[id])
				set_cam_ent(id)

			if(!created_aim)
				create_homming_aim()

			set_task(1.0, "boost_gauge_hud", id+TASK_HUD_BOOST, _, _, "b")
		}

		client_print_color(id, print_team_default, "%L %L", id, "SHADOW_CHAT_PREFIX", id, "YOURE_SHADOW")
		client_print_color(id, print_team_default, "%L %L", id, "SHADOW_CHAT_PREFIX", id, "SHADOW_INFO")
	}
	else if(g_pl_cam_ent[id]) {
		reset_shadow_vars(id, g_pl_cam_ent[id] ? 1 : 0)
	}
}

public forward_AddToFullPack(es_handle, e, id, host, hostflags, player, pSet) {
	if(!is_user_connected(host))
		return FMRES_IGNORED;

	if(is_user_alive(id) && player) {
		if(GetUserShadow(id) && g_sequence_anim[id] != -1) {
			// Set players sequence
			if(get_es(es_handle, ES_Sequence) != g_sequence_anim[id]) {
				set_es(es_handle, ES_Sequence, g_sequence_anim[id]);
			}
		}
	}

	if(is_user_connected(id))
		return FMRES_IGNORED;

	if(!is_user_alive(g_homming_target[host]) || !pev_valid(id))
		return FMRES_IGNORED;

	if(!GetUserShadow(host) || zp_get_user_zombie(g_homming_target[host]) || used_homming[host])
		return FMRES_IGNORED;

	if(entity_range(host, g_homming_target[host]) > 500.0) 
		return FMRES_IGNORED;

	static szClassname[32]; 
	pev(id, pev_classname, szClassname, charsmax(szClassname))
	if(equal(szClassname, HOMMING_AIM_CLASSNAME)) {
		set_es(es_handle, ES_MoveType, MOVETYPE_FOLLOW)
		set_es(es_handle, ES_AimEnt, g_homming_target[host])
		set_es(es_handle, ES_RenderFx, kRenderFxGlowShell);
		set_es(es_handle, ES_RenderColor, { 0, 255, 0 });
		set_es(es_handle, ES_RenderMode, kRenderNormal);
		set_es(es_handle, ES_RenderAmt, 40);
	}

	return FMRES_HANDLED;
}

public zp_user_humanized_post(id) {
	if(zp_get_user_sonic(id)) {
		reset_shadow_vars(id, 0)
	}
	else reset_shadow_vars(id, 1)
}

public client_putinserver(id) reset_shadow_vars(id, g_pl_cam_ent[id] ? 1 : 0);

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


public client_PreThink(id) {
	if(!is_user_alive(id))
		return

	if(!GetUserShadow(id)) 
		return;

	static in_ground, iButton, iOldButton, Float:fVelocity[3]
	in_ground = (pev(id, pev_flags) & FL_ONGROUND) ? true : false

	if(is_user_bot(id)) {
		if(!in_ground && !g_in_dash_attack[id] && !used_homming[id]) {
			if(get_gametime() - 0.2 > Time_Bot[id]) {
				iButton |= IN_JUMP
				iOldButton &= IN_JUMP

				Time_Bot[id] = get_gametime()
				Time_skill[id] = random_float(5.0, 10.0)
			}
		}
		else if(get_gametime() - Time_skill[id] > Time_Bot[id]) {		
			if(!g_in_dash_attack[id]) {
				if(random_num(0, 4) > 2 && g_boost_gauge[id]) {
					iButton |= IN_USE	
					iOldButton &= IN_USE	
				}
				else {
					iButton |= IN_RELOAD	
					iOldButton &= IN_RELOAD	
				}

			}
			else {
				iButton &= IN_USE	
				iOldButton |= IN_USE	

				iButton &= IN_RELOAD	
				iOldButton |= IN_RELOAD	
			}

			Time_Bot[id] = get_gametime()
			Time_skill[id] = random_float(5.0, 10.0)
		}
	}
	else {
		iButton = get_user_button(id)
		iOldButton = get_user_oldbutton(id)
	}

	// Spin dash = Crounch Size
	if(g_in_dash_attack[id] == ATTACK_SPINDASH) {
		set_pev(id, pev_bInDuck, 1)
		client_cmd(id, "+duck")
	}

	if(iButton & IN_RELOAD && (g_in_dash_attack[id] == 0 || g_in_dash_attack[id] == ATTACK_SPINDASH) && !task_exists(id+TASK_SPIN_DASH)) {
		if(!(iOldButton & IN_RELOAD)) {
			Time1 = get_gametime()
			emit_sound(id, CHAN_STATIC, skill_sounds[SND_SPIN_START], 1.0, ATTN_NORM, 0, PITCH_NORM)

			if(is_user_bot(id)) {
				Time_Bot[id] = get_gametime()
				Time_skill[id] = random_float(2.0, 5.0)
				iOldButton |= IN_RELOAD
			}
			return;
		}
	
		if(get_gametime() - 0.5 > Time1 && g_spin_force[id] < 3) {
			g_spin_force[id]++
			Time1 = get_gametime()
		}

		if(!in_ground)
			set_pev(id, pev_velocity, Float:{0.0, 0.0, -200.0});
		else 
			set_pev(id, pev_velocity, Float:{1.0, 1.0, 1.0});
	
		g_sequence_anim[id] = 112
		g_in_dash_attack[id] = ATTACK_SPINDASH
	}
	if(!(iButton & IN_RELOAD) && (iOldButton & IN_RELOAD) && !task_exists(id+TASK_SPIN_DASH)) {

		if(!have_trail[id])
			set_trail(id, 15)

		static speed
		switch(g_spin_force[id]) {
			case 0: speed = 500
			case 1: speed = 700
			case 2: speed = 1000
			case 3: speed = 1500
			default: speed = 500
		}

		velocity_by_aim(id, speed, fAim)

		User_fVelocity[0][id] = fAim[0];
		User_fVelocity[1][id] = fAim[1]; 
		User_fVelocity[2][id] = -100.0

		set_task(0.1, "spin_dash_loop", id+TASK_SPIN_DASH, _, _, "b")
		set_task(2.0, "spin_dash_end", id+TASK_SPIN_DASH)

		emit_sound(id, CHAN_STATIC, skill_sounds[SND_SPIN_UNLEASH], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}

	if(iButton & IN_USE && g_boost_gauge[id] > 0 && (g_in_dash_attack[id] == 0 || g_in_dash_attack[id] == ATTACK_BOOST)) {
		if(!(iOldButton & IN_USE)) {
			Time1 = get_gametime()
			emit_sound(id, CHAN_STATIC, skill_sounds[SND_BOOST], 1.0, ATTN_NORM, 0, PITCH_NORM)

			if(is_user_bot(id)) {
				Time_Bot[id] = get_gametime()
				Time_skill[id] = random_float(5.0, 10.0)
				iOldButton |= IN_USE
			}
			return;
		}

		if(get_gametime() - 1.0 > Time1 && g_boost_gauge[id] > 0) {
			Time1 = get_gametime()
			g_boost_gauge[id]--
		}

		if(!have_trail[id])
			set_trail(id, 25)

		velocity_by_aim(id, 1000, fAim)

		fVelocity[0] = fAim[0];
		fVelocity[1] = fAim[1]; 
		fVelocity[2] = -50.0
		set_pev(id, pev_velocity, fVelocity);

		g_sequence_anim[id] = 113

		zp_set_user_rendering(id, kRenderFxGlowShell, 255, 69, 0, kRenderNormal, 150)

		g_in_dash_attack[id] = ATTACK_BOOST
	}
	if(g_in_dash_attack[id] == ATTACK_BOOST && (!(iButton & IN_USE) && (iOldButton & IN_USE) || g_boost_gauge[id] <= 0)) {
		zp_reset_user_rendering(id)
		g_sequence_anim[id] = -1
		g_in_dash_attack[id] = 0
		
		if(have_trail[id]) remove_trail(id)

		emit_sound(id, CHAN_STATIC, skill_sounds[SND_BOOST], VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)
	}

	if((iButton & IN_JUMP) && !(iOldButton & IN_JUMP) && !g_in_dash_attack[id]) {
		if(is_user_bot(id)) {
			iButton &= IN_JUMP
			iOldButton |= IN_JUMP
		}

		if(!in_ground && !task_exists(id+TASK_HOMMING_ATTACK) && !used_homming[id]) {
			if(!have_trail[id])
				set_trail(id, 15)

			g_sequence_anim[id] = 111
			g_in_dash_attack[id] = HOMMING_ATTACK
			set_task(0.1, "homming_attack_task", id+TASK_HOMMING_ATTACK, _, _, "b")
			set_task(2.0, "end_homming_attack", id+TASK_HOMMING_ATTACK)
			emit_sound(id, CHAN_STATIC, skill_sounds[SND_HOMMING_ATTACK], 1.0, ATTN_NORM, 0, PITCH_NORM)			
		}
		else if(in_ground)
			emit_sound(id, CHAN_STATIC, skill_sounds[SND_JUMP], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}

	// Search Target
	if(!task_exists(id+TASK_HOMMING_ATTACK) && !g_in_dash_attack[id]) {
		if(!in_ground && !g_homming_target[id] && !used_homming[id]) {
			g_homming_target[id] = FindClosetEnemy(id)
			
			if(g_homming_target[id]) {
				client_cmd(id, "spk %s", skill_sounds[SND_HOMMING_AIM])
			}
		}
		else if(in_ground) {
			if(g_homming_target[id]) {
				g_homming_target[id] = 0
			}

			if(used_homming[id])
				used_homming[id] = false
		}
	}
}

public homming_attack_task(id) {
	id -= TASK_HOMMING_ATTACK

	if(!zp_get_user_zombie(id) || !GetUserShadow(id)) {
		remove_task(id+TASK_HOMMING_ATTACK)
		return;
	}

	static Float:TargetOrigin[3];
	if(is_user_alive(g_homming_target[id]) && entity_range(id, g_homming_target[id]) < 500.0) {
		pev(g_homming_target[id], pev_origin, TargetOrigin)
		Aim_To(id, TargetOrigin, 2.0, 0)
		hook_ent2(id, TargetOrigin, 1000.0)
	}
	else {
		get_position(id, 200.0, 0.0, 0.0, TargetOrigin)
		Aim_To(id, TargetOrigin, 2.0, 0)
		hook_ent2(id, TargetOrigin, 1000.0)
		end_homming_attack(id+TASK_HOMMING_ATTACK)
	}
}

public end_homming_attack(id) {
	id -= TASK_HOMMING_ATTACK

	remove_task(id+TASK_HOMMING_ATTACK)
	g_homming_target[id] = 0
	g_in_dash_attack[id] = 0
	g_sequence_anim[id] = -1
	used_homming[id] = true
	if(have_trail[id]) remove_trail(id)
}

public spin_dash_loop(id) {
	id -= TASK_SPIN_DASH

	if(!is_user_alive(id)) {
		remove_task(id+TASK_SPIN_DASH)
		return
	}

	if(!GetUserShadow(id)) {
		remove_task(id+TASK_SPIN_DASH)
		return;
	}

	static Float:fVelocity[3]
	fVelocity[0] = User_fVelocity[0][id]
	fVelocity[1] = User_fVelocity[1][id]
	fVelocity[2] = User_fVelocity[2][id]

	set_pev(id, pev_velocity, fVelocity);
	g_sequence_anim[id] = 112
}
public spin_dash_end(id) {
	id -= TASK_SPIN_DASH

	remove_task(id+TASK_SPIN_DASH)
	g_spin_force[id] = 0
	g_in_dash_attack[id] = 0
	g_sequence_anim[id] = -1
	set_pev(id, pev_bInDuck, 0)
	client_cmd(id, "-duck")
	client_cmd(id, "-duck")
	if(have_trail[id]) remove_trail(id)
	//g_frame[id] = 0
}

public reset_shadow_vars(id, remove_cam) {

	if(is_user_connected(id)) {
		zp_reset_user_rendering(id)
		
		if(remove_cam) 
			remove_cam_ent(id, 1)
	}
	else {
		if(remove_cam) 
			remove_cam_ent(id, 0)
	}

	remove_task(id+TASK_SPIN_DASH)
	g_spin_force[id] = 0
	g_in_dash_attack[id] = 0
	g_sequence_anim[id] = -1
	set_pev(id, pev_bInDuck, 0)
	client_cmd(id, "-duck")
	client_cmd(id, "-duck")

	remove_task(id+TASK_HUD_BOOST)
	remove_task(id+TASK_HOMMING_ATTACK)
	g_homming_target[id] = 0
	g_in_dash_attack[id] = 0
	if(have_trail[id]) remove_trail(id)
}

public fw_Touch(attacker, victim) {
	if(!is_user_alive(attacker) || !pev_valid(victim))
		return FMRES_IGNORED

	if(GetUserShadow(attacker) && g_in_dash_attack[attacker]) 
	{
		if(is_user_alive(victim)) {
			if(!zp_get_user_zombie(victim)) {
				switch(g_in_dash_attack[attacker]) {
					case HOMMING_ATTACK: zp_set_user_extra_damage(victim, attacker, get_pcvar_num(cvar_attack_damage[HOMMING_ATTACK-1]), "Shadow Homming Attack", 1)
					case ATTACK_SPINDASH: zp_set_user_extra_damage(victim, attacker, get_pcvar_num(cvar_attack_damage[ATTACK_SPINDASH-1]), "Shadow Spin Dash", 1)
					case ATTACK_BOOST: zp_set_user_extra_damage(victim, attacker, get_pcvar_num(cvar_attack_damage[ATTACK_BOOST-1]), "Shadow Boost", 1)
				}

				static Float:Velocity[3]
				Velocity[0] = random_float(1000.0, 1500.0)
				Velocity[1] = random_float(1000.0, 1500.0)
				Velocity[2] = random_float(1000.0, 1500.0)
				set_pev(victim, pev_velocity, Velocity)
			}
		}
		else if(!is_user_connected(victim) && pev(victim, pev_takedamage) != DAMAGE_NO) {
			ExecuteHamB(Ham_TakeDamage, victim, 0, attacker, get_pcvar_float(cvar_attack_damage[g_in_dash_attack[attacker]-1]), DMG_GENERIC)
		}

		if(g_in_dash_attack[attacker] == HOMMING_ATTACK)
			end_homming_attack(attacker+TASK_HOMMING_ATTACK)
	}
	return FMRES_IGNORED
}

/*--------------------------------------------------------
	[Third Person View (Thanks William for his code)]
---------------------------------------------------------*/

/*--------------------------------------------------------
	[Third Person View (Thanks William for his code)]
---------------------------------------------------------*/
public set_cam_ent(iPlayer) {
	// new ient = create_entity("trigger_camera")
	
	//if(!is_valid_ent(ient))
	//	return

	// entity_set_model(ient, CAMERA_MODEL)
	// entity_set_int(ient, CAMERA_OWNER, id)
	// entity_set_string(ient, EV_SZ_classname, CAMERA_CLASSNAME)
	// entity_set_int(ient, EV_INT_solid, SOLID_NOT)
	// entity_set_int(ient, EV_INT_movetype, MOVETYPE_FLY)
	// entity_set_int(ient, EV_INT_rendermode, kRenderTransTexture)

	// fm_attach_view(id, ient)
	// entity_set_float(ient, EV_FL_nextthink, get_gametime() + 0.01)

	if(is_valid_ent(g_pl_cam_ent[iPlayer])) {
		attach_view(iPlayer, g_pl_cam_ent[iPlayer])
		return g_pl_cam_ent[iPlayer];
	}

	new ient = create_entity("trigger_camera");
	
	if (!is_valid_ent(ient))
	{
		return -1;
	}

	static iFlags, Float: flMaxSpeed;
	iFlags = entity_get_int(iPlayer, EV_INT_flags);
	flMaxSpeed = entity_get_float(iPlayer, EV_FL_maxspeed);
	
	set_kvd(0, KV_ClassName, "trigger_camera");
	set_kvd(0, KV_fHandled, 0);
	set_kvd(0, KV_KeyName, "wait");
	set_kvd(0, KV_Value, "999999");
	dllfunc(DLLFunc_KeyValue, ient, 0);
	
	entity_set_int(ient, EV_INT_spawnflags, SF_CAMERA_PLAYER_TARGET|SF_CAMERA_PLAYER_POSITION);
	entity_set_int(ient, EV_INT_flags, entity_get_int(ient, EV_INT_flags)|FL_ALWAYSTHINK);
	entity_set_edict(ient, EV_ENT_owner, iPlayer);
	// entity_set_int(ient, CAMERA_OWNER, id)
	entity_set_string(ient, EV_SZ_classname, CAMERA_CLASSNAME)
	DispatchSpawn(ient);
	ExecuteHam(Ham_Use, ient, iPlayer, iPlayer, USE_TOGGLE, 1.0);
	
	entity_set_int(iPlayer, EV_INT_flags, iFlags);
	engfunc(EngFunc_SetClientMaxspeed, iPlayer, flMaxSpeed); // depending on mod, you may have to send SetClientMaxspeed here.
	entity_set_float(iPlayer, EV_FL_maxspeed, flMaxSpeed);

	g_pl_cam_ent[iPlayer] = ient
	attach_view(iPlayer, ient)
	return ient;
	
	
}

public HamHook_CameraThink_Pre(iEntity)
{
	static ClassName[32];
	entity_get_string(iEntity, EV_SZ_classname, ClassName, charsmax(ClassName))
	if(!equal(ClassName, CAMERA_CLASSNAME))
		return;

	static iPlayer;
	iPlayer = entity_get_edict(iEntity, EV_ENT_owner);
	
	if (!is_user_alive(iPlayer))
		return;

	if(!GetUserShadow(iPlayer) || !g_pl_cam_ent[iPlayer])
		return;
	
	static Float: vStart[3], Float: vEnd[3], Float: vAngles[3], Float: vBack[3];
	entity_get_vector(iPlayer, EV_VEC_origin, vStart);
	entity_get_vector(iPlayer, EV_VEC_view_ofs, vAngles);

	vStart[2] += vAngles[2];
	
	entity_get_vector(iPlayer, EV_VEC_v_angle, vAngles);

	angle_vector(vAngles, ANGLEVECTOR_FORWARD, vBack);
	
	static Float:CamDistance;
	CamDistance = get_pcvar_float(cvar_camera_distance)
	vEnd[0] = vStart[0] + (-vBack[0] * CamDistance);
	vEnd[1] = vStart[1] + (-vBack[1] * CamDistance);
	vEnd[2] = vStart[2] + (-vBack[2] * CamDistance);
	
	engfunc(EngFunc_TraceLine, vStart, vEnd, IGNORE_MONSTERS, iPlayer, 0);
	
	static Float: flFraction;
	get_tr2(0, TR_flFraction, flFraction);
	
	if (flFraction != 1.0 ) {
		flFraction *= 150.0;
		
		vEnd[0] = vStart[0] + (-vBack[0] * flFraction);
		vEnd[1] = vStart[1] + (-vBack[1] * flFraction);
		vEnd[2] = vStart[2] + (-vBack[2] * flFraction);
	}
	
	entity_set_vector(iEntity, EV_VEC_origin, vEnd);
	entity_set_vector(iEntity, EV_VEC_angles, vAngles);
}

public FakeMeta_SetView_Pre(iPlayer, iEntity)
{
	if (!is_user_alive(iPlayer))
		return FMRES_IGNORED;
	
	if(!GetUserShadow(iPlayer))
		return FMRES_IGNORED;
	
	new iCamera = g_pl_cam_ent[iPlayer];
	
	if (!iCamera || iEntity == iCamera)
		return FMRES_IGNORED;

	static szClassname[32];
	entity_get_string(iEntity, EV_SZ_classname, szClassname, charsmax(szClassname));
	
	if (equal(szClassname, "trigger_camera"))
		return FMRES_IGNORED;
	
	engfunc(EngFunc_SetView, iPlayer, iCamera);
	
	return FMRES_SUPERCEDE;
}

public remove_cam_ent(id, attachview) {
	if(attachview) attach_view(id, id)

	new ient = -1

	while((ient = find_ent_by_class(ient, CAMERA_CLASSNAME))) {
		if(!is_valid_ent(ient))
			continue
		
		if(entity_get_edict(ient, EV_ENT_owner) == id) {
			g_pl_cam_ent[id] = 0
			
			entity_set_int(ient, EV_INT_flags, FL_KILLME)
			dllfunc(DLLFunc_Think, ient)
		}
	}
}

public fw_PlayerKilled_Post(victim, attacker) {
	if(!is_user_connected(victim))
		return HAM_IGNORED;

	if(GetUserShadow(victim) && g_pl_cam_ent[victim])
		reset_shadow_vars(victim, 1)

	if(!is_user_connected(attacker))
		return HAM_IGNORED;

	if(GetUserShadow(attacker)) {
		if(g_boost_gauge[attacker] + get_pcvar_num(cvar_boost_give) <= get_pcvar_num(cvar_boost_gauge)) 
			g_boost_gauge[attacker] += get_pcvar_num(cvar_boost_give)
		else
			g_boost_gauge[attacker] = get_pcvar_num(cvar_boost_gauge)
	}

	

	return HAM_IGNORED
}

public boost_gauge_hud(id) {
	id -= TASK_HUD_BOOST

	if(!is_user_alive(id)) {
		remove_task(id+TASK_HUD_BOOST)
		return;
	}

	if(!GetUserShadow(id)) {
		remove_task(id+TASK_HUD_BOOST)
		return;
	}

	static szBar[32], color[3], MaxBoostGauge
	MaxBoostGauge = get_pcvar_num(cvar_boost_gauge)

	color = { 255, 69, 0 }

	if(g_boost_gauge[id] > MaxBoostGauge * 0.9 )
		szBar = "||||||||||||||||||||"

	if(g_boost_gauge[id] <= MaxBoostGauge * 0.9)
		szBar = "||||||||||||||||||--"

	if(g_boost_gauge[id] <= MaxBoostGauge * 0.8)
		szBar = "||||||||||||||||----"

	if(g_boost_gauge[id] <= MaxBoostGauge * 0.7) {
		szBar = "||||||||||||||------"
		color = { 0, 255, 0 }
	}
	if(g_boost_gauge[id] <= MaxBoostGauge * 0.6)
		szBar = "||||||||||||--------"

	if(g_boost_gauge[id] <= MaxBoostGauge * 0.5)
		szBar = "||||||||||----------"

	if(g_boost_gauge[id] <= MaxBoostGauge * 0.4)
		szBar = "||||||||------------"

	if(g_boost_gauge[id] <= MaxBoostGauge * 0.3) {
		szBar = "||||||--------------"
		color = { 255, 255, 0 }
	}
	if(g_boost_gauge[id] <= MaxBoostGauge * 0.2)
		szBar = "||||----------------"

	if(g_boost_gauge[id] <= MaxBoostGauge * 0.1)
		szBar = "||------------------"

	if(!g_boost_gauge[id]) {
		szBar = "--------------------"
		color = { 255, 0, 0 }
	}

	set_dhudmessage(color[0], color[1], color[2], 0.05, 0.65, 1, 0.2, 1.0, 0.1, 0.1)
	show_dhudmessage(id, "%L^n%s", id, "BOOST_GAUGE", szBar)

}

public FindClosetEnemy(ent) {
	if(!is_user_alive(ent))
		return 0

	static indexid, Float:current_dis
	indexid = 0	
	current_dis = 240.0

	static Float:Origin[3], Float:EntOrigin[3]
	get_position(ent, 250.0, 0.0, 0.0, EntOrigin)

	for(new i = 1; i <= MaxClients; i++) {
		if(!is_user_alive(i))
			continue;

		if(!zp_get_user_zombie(i) && is_visible(ent,  i)) { 
			pev(i, pev_origin, Origin)

			if(get_distance_f(Origin, EntOrigin) > current_dis)
				continue;

			current_dis = get_distance_f(Origin, EntOrigin)
			indexid = i
		}
	}	
	
	return indexid
}
stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[]) {
	if(!pev_valid(ent))
		return
		
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_angles, vAngle) // if normal entity ,use pev_angles
	
	vAngle[0] = 0.0
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

public Aim_To(iEnt, Float:vTargetOrigin[3], Float:flSpeed, Style) {
	if(!pev_valid(iEnt))	
		return
		
	if(!Style) {
		static Float:Vec[3], Float:Angles[3]
		pev(iEnt, pev_origin, Vec)
		
		Vec[0] = vTargetOrigin[0] - Vec[0]
		Vec[1] = vTargetOrigin[1] - Vec[1]
		Vec[2] = vTargetOrigin[2] - Vec[2]
		engfunc(EngFunc_VecToAngles, Vec, Angles)
		//Angles[0] = Angles[2] = 0.0 
		
		set_pev(iEnt, pev_v_angle, Angles)
		set_pev(iEnt, pev_angles, Angles)
	} else {
		new Float:f1, Float:f2, Float:fAngles, Float:vOrigin[3], Float:vAim[3], Float:vAngles[3];
		pev(iEnt, pev_origin, vOrigin);
		xs_vec_sub(vTargetOrigin, vOrigin, vOrigin);
		xs_vec_normalize(vOrigin, vAim);
		vector_to_angle(vAim, vAim);
		
		if (vAim[1] > 180.0) vAim[1] -= 360.0;
		if (vAim[1] < -180.0) vAim[1] += 360.0;
		
		fAngles = vAim[1];
		pev(iEnt, pev_angles, vAngles);
		
		if (vAngles[1] > fAngles) {
			f1 = vAngles[1] - fAngles;
			f2 = 360.0 - vAngles[1] + fAngles;
			if (f1 < f2) {
				vAngles[1] -= flSpeed;
				vAngles[1] = floatmax(vAngles[1], fAngles);
			}
			else
			{
				vAngles[1] += flSpeed;
				if (vAngles[1] > 180.0) vAngles[1] -= 360.0;
			}
		}
		else
		{
			f1 = fAngles - vAngles[1];
			f2 = 360.0 - fAngles + vAngles[1];
			if (f1 < f2) {
				vAngles[1] += flSpeed;
				vAngles[1] = floatmin(vAngles[1], fAngles);
			}
			else
			{
				vAngles[1] -= flSpeed;
				if (vAngles[1] < -180.0) vAngles[1] += 360.0;
			}		
		}
	
		set_pev(iEnt, pev_v_angle, vAngles)
		set_pev(iEnt, pev_angles, vAngles)
	}
}

public hook_ent2(ent, Float:VicOrigin[3], Float:speed) {
	if(!pev_valid(ent)) return;
	
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	
	pev(ent, pev_origin, EntOrigin)
	
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	
	if (distance_f > 60.0) {
		new Float:fl_Time = distance_f / speed
		
		fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
		fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time
	} 
	else
	{
		fl_Velocity[0] = 0.0
		fl_Velocity[1] = 0.0
		fl_Velocity[2] = 0.0
	}
	entity_set_vector(ent, EV_VEC_velocity, fl_Velocity)
}

public set_trail(id, grossura) {
	if(!is_user_alive(id))
		return;

	if(!GetUserShadow(id) || have_trail[id])
		return;

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(id)
	write_short(g_ShadowTrail)
	write_byte(4)
	write_byte(grossura)
	write_byte(255)
	write_byte(69)
	write_byte(0)
	write_byte(125)
	message_end()

	have_trail[id] = true
}
remove_trail(id) {
	if(!is_user_alive(id) || !have_trail[id])
		return;

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(99)	// TE_KILLBEAM
	write_short(id)
	message_end()

	have_trail[id] = false
}

public create_homming_aim() {
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))

	set_pev(ent, pev_classname, HOMMING_AIM_CLASSNAME)
	engfunc(EngFunc_SetModel, ent, HOMMING_MODEL)
	set_pev(ent, pev_movetype, MOVETYPE_FOLLOW)
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_aiment, 0)
	//set_pev(ent, pev_rendermode, kRenderNormal)
	set_pev(ent, pev_sequence, 0)
	//set_pev(ent, pev_animtime, get_gametime())
	//set_pev(ent, pev_framerate, 1.0)

	// Invisible
	fm_set_rendering(ent, kRenderFxGlowShell, 0, 0, 0, kRenderTransAdd, 0)

	created_aim = true
}
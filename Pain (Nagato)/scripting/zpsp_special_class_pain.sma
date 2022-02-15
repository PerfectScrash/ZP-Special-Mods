/*===========================================================================================================
				[ZPSp] Special Class: Pain/Nagato Mode

		[Requeriments]
	* Amxmodx 1.9 or higher
	* Zombie Plague Special 4.5 or higher

		[Skill Description]
	* Shinra Tensei: Can repel and kill anyone that around you
	* Chibaku Tensei: When we used it, the zombie in the certain radius will be sucked up to the air for a period of time. 
	It will float and whirling around in a circle like in a hurricane.
	* Bansho Ten’in: Can pull the player up to you.
	* Super Shinra Tensei: Kill all zombies (Zombies know the pain), skill available in latest 50 seconds.

		[Button Description]
	Press [R] Button for choose a skill
	Press [E] Button for use the skill

		[Cvars]
	zp_pain_minplayers "2"				// Min players for start a gamemode
	zp_pain_knife_damage "500" 			// Knife Damage
	zp_pain_chibaku_countdown "20.0"	// Time it had taken for Using Chibaku Tensei Again
	zp_pain_chibaku_range "2000"		// Chibaku Tensei Range
	zp_pain_chibaku_force "1200"		// Chibaku Tensei Force
	zp_pain_chibaku_time "10" 			// Chibaku Tensei Time (Now are for seconds)
	zp_pain_chibaku_particles "1" 		// Enable Particle Effect
	zp_pain_shinra_countdown "5.0"		// Time it had taken for Using Shinra Tensei Again
	zp_pain_shinra_radius "300"			// Shinra Tensei Radius
	zp_pain_shinra_damage "400"			// Shinra Tensei Damage
	zp_pain_bansho_reelspeed "2000"		// Bansho Push Speed
	zp_pain_bansho_damage "1000"		// Bansho Damage
	zp_pain_bansho_countdown "5.0"		// Time it had taken for Using Bansho Ten'in Again

		[Credits]
	[P]erfec[T] [S]cr[@]s[H]: For make this Gamemod/Special Class
	K-OS: For part of Hero Tornado’s Code

===========================================================================================================*/

#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <zombie_plague_special>
#include <amx_settings_api>
#include <xs>

#if ZPS_INC_VERSION < 45
	#assert Zombie Plague Special 4.5 Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

/*-------------------------------------
--> Class Configs
--------------------------------------*/
#define Make_Acess ADMIN_IMMUNITY 	// Flag Acess make
new const sp_name[] = "Pain"
new const sp_model[] = "zp_pain"
new const sp_hp = 7000
new const sp_speed = 280
new const Float:sp_gravity = 0.8
new const sp_aura_size = 0
new const sp_clip_type = 2 // Unlimited Ammo(0 - Disable | 1 - Unlimited Semi Clip | 2 - Unlimited Clip)
new const sp_allow_glow = 0
new sp_color_rgb[3] = { 255, 255, 255 }

// Default KNIFE Models
new const default_v_knife[] = "models/zombie_plague/v_kunai_pain.mdl"
new const default_p_knife[] = "models/zombie_plague/p_kunai_pain.mdl"

new const sprite_ring[] = "sprites/shockwave.spr"
new const chibaku_beam_spr[] = "sprites/3dmflared.spr"
new const chibaku_tensei_class[] = "chibaku_tensei_beam"

enum { SHINRA_TENSEI = 0, CHIBAKU_TENSEI, BANSHO_TENIN, SUPER_SHINRA_TENSEI, MAX_SKILLS }
new const skill_sounds[MAX_SKILLS][] = {
	"zp_pain_mode/shinra_tensei.wav", 
	"zp_pain_mode/chibaku_tensei.wav", 
	"zp_pain_mode/bansho_tenin.wav", 
	"zp_pain_mode/super_shinra_tensei.wav"
}
new const skill_string[MAX_SKILLS][] = { 
	"SHINRA_TENSEI", 
	"CHIBAKU_TENSEI", 
	"BANSHO_TENIN", 
	"SUPER_SHINRA_TENSEI"
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
	{ "zp_pain_mode/ambience_pain.mp3", 134.0 }
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
new g_gameid, g_msg_sync, cvar_minplayers, g_special_id, cvar_damage, v_knife_model[64], p_knife_model[64]
new white, gRange, gForce, super_shinra_allow, used_super_shinra, cvar_bansho[3], g_hooked[33]
new gMsgBarTime, cvar_countdown, cvar_range, cvar_force, cvar_time, g_msgDeathMsg, cvar_particles, g_spriteBlood, g_spriteBldSpray
new g_exploSpr, g_skill_id[33], g_used_skill[MAX_SKILLS][33], cvar_shinra_countdown, cvar_shinra_radius, cvar_shinra_dmg, Float:g_radius, g_damage, Float:g_shinra_countdown

enum (+= 100) {
	TASK_CHIBAKU = 1000, 
	TASK_CHIBAKU_COUNTDOWN, 
	TASK_SHINRA, 
	TASK_SUPER_SHINRA, 
	TASK_SUPER_SHINRA_USES, 
	TASK_SHINRA_COUNTDOWN, 
	TASK_BANSHO_COUNTDOWN,
	TASK_BANSHO_PUSH
}

#define GetUserPain(%1) (zp_get_human_special_class(%1) == g_special_id)
#define IsPainRound() (zp_get_current_mode() == g_gameid)

/*-------------------------------------
--> Plugin Registeration
--------------------------------------*/
public plugin_init() {	

	register_plugin("[ZPSp] Special Class: Pain", "1.2", "[P]erfec[T] [S]cr[@]s[H]")

	register_dictionary("zpsp_pain.txt")

	register_event("HLTV", "cache_cvars", "a", "1=0", "2=0")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_event("CurWeapon", "checkModel", "be", "1=1")

	register_think(chibaku_tensei_class, "fw_ChibakuThink")
	register_touch("player", "*", "player_touch")
	
	cvar_minplayers = register_cvar("zp_pain_minplayers", "2")			// Min players for start a gamemode
	cvar_damage = register_cvar("zp_pain_knife_damage", "500") 			// Knife Damage
	cvar_countdown = register_cvar("zp_pain_chibaku_countdown", "20.0")	// Time it had taken for Using Chibaku Tensei Again
	cvar_range = register_cvar("zp_pain_chibaku_range", "2000")			// Chibaku Tensei Range
	cvar_force = register_cvar("zp_pain_chibaku_force", "1200")			// Chibaku Tensei Force
	cvar_time = register_cvar("zp_pain_chibaku_time", "10") 			// Chibaku Tensei Time (Now are for seconds)
	cvar_particles = register_cvar("zp_pain_chibaku_particles", "1") 	// Enable Particle Effect
	cvar_shinra_countdown = register_cvar("zp_pain_shinra_countdown", "5.0")	// Time it had taken for Using Shinra Tensei Again
	cvar_shinra_radius = register_cvar("zp_pain_shinra_radius", "300")		// Shinra Tensei Radius
	cvar_shinra_dmg = register_cvar("zp_pain_shinra_damage", "400")		// Shinra Tensei Damage
	cvar_bansho[0] = register_cvar("zp_pain_bansho_reelspeed", "2000") // Bansho Push Speed
	cvar_bansho[1] = register_cvar("zp_pain_bansho_damage", "1000") // Bansho Damage
	cvar_bansho[2] = register_cvar("zp_pain_bansho_countdown", "5.0") // Time it had taken for Using Bansho Ten'in Again

	g_msgDeathMsg = get_user_msgid("DeathMsg")
	gMsgBarTime = get_user_msgid("BarTime")
	g_msg_sync = CreateHudSyncObj()
}

/*-------------------------------------
--> Plugin Precache
--------------------------------------*/
public plugin_precache() {
	// Special class and Game Mode Register
	g_gameid = zpsp_register_gamemode(sp_name, Start_Mode_Acess, g_chance, 0, ZP_DM_NONE, .uselang=1, .langkey="PAIN_CLASS_NAME")
	g_special_id = zp_register_human_special(sp_name, sp_model, sp_hp, sp_speed, sp_gravity, Make_Acess, sp_clip_type, sp_aura_size, sp_allow_glow, sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2])

	// Set lang configuration
	amx_save_setting_int(ZP_SPECIAL_CLASSES_FILE, fmt("H:%s", sp_name), "NAME BY LANG", 1)
	amx_save_setting_string(ZP_SPECIAL_CLASSES_FILE, fmt("H:%s", sp_name), "LANG KEY", "PAIN_CLASS_NAME")

	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_KNIFE PAIN", v_knife_model, charsmax(v_knife_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_KNIFE PAIN", default_v_knife)
		formatex(v_knife_model, charsmax(v_knife_model), default_v_knife)
	}
	precache_model(v_knife_model)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_KNIFE PAIN", p_knife_model, charsmax(p_knife_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "P_KNIFE PAIN", default_p_knife)
		formatex(p_knife_model, charsmax(p_knife_model), default_p_knife)
	}
	precache_model(p_knife_model)

	precache_model(chibaku_beam_spr)
	g_exploSpr = precache_model(sprite_ring)
	white = precache_model("sprites/xssmke1.spr")
	g_spriteBlood = precache_model("sprites/blood.spr")
	g_spriteBldSpray = precache_model("sprites/bloodspray.spr")
	
	static i
	for(i = 0; i < MAX_SKILLS; i++)
		precache_sound(skill_sounds[i])

	// Register round start sound
	for(i = 0; i < sizeof gamemode_round_start_snd; i++)
		zp_register_start_gamemode_snd(g_gameid, gamemode_round_start_snd[i])

	// Register ambience sounds
	for (i = 0; i < sizeof gamemode_ambiences; i++)
		zp_register_gamemode_ambience(g_gameid, gamemode_ambiences[i][AmbiencePrecache], gamemode_ambiences[i][AmbienceDuration], ambience_enable)
	
}

public cache_cvars() {
	g_radius = get_pcvar_float(cvar_shinra_radius)
	g_damage = get_pcvar_num(cvar_shinra_dmg)
	g_shinra_countdown = get_pcvar_float(cvar_shinra_countdown)
}

/*-------------------------------------
--> Natives
--------------------------------------*/
public plugin_natives() {
	register_native("zp_get_user_pain", "native_get_user_pain")
	register_native("zp_make_user_pain", "native_make_user_pain")
	register_native("zp_get_pain_count", "native_get_pain_count")
	register_native("zp_is_pain_round", "native_is_pain_round")
}
public native_get_user_pain(plugin_id, num_params)
	return GetUserPain(get_param(1));
	
public native_make_user_pain(plugin_id, num_params)
	return zp_make_user_special(get_param(1), g_special_id, GET_HUMAN);
	
public native_get_pain_count(plugin_id, num_params)
	return zp_get_special_count(GET_HUMAN, g_special_id);
	
public native_is_pain_round(plugin_id, num_params)
	return (IsPainRound());

/*-------------------------------------
--> Gamemode Functions
--------------------------------------*/
// Player spawn post
public zp_player_spawn_post(id) {
	reset_pain_vars(id, 0)
	
	// Check for current mode
	if(IsPainRound())
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
		start_pain_mode() // Start pain mode
}

// This function contains the whole code behind this game mode
start_pain_mode() {
	static id, i, has_pain
	has_pain = false
	for (i = 1; i <= MaxClients; i++) {
		if(!is_user_alive(i))
			continue

		if(GetUserPain(i)) {
			id = i
			has_pain = true
			break;
		}
	}

	if(!has_pain) {
		id = zp_get_random_player()
		zp_make_user_special(id, g_special_id, GET_HUMAN)
	}
	
	static name[32]; get_user_name(id, name, charsmax(name));
	set_hudmessage(sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2], -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "ARE_PAIN", name, sp_name)
		
	// Turn the remaining players into zombies
	for(id = 1; id <= MaxClients; id++) {
		if(!is_user_alive(id))
			continue;
			
		if(GetUserPain(id) || zp_get_user_zombie(id))
			continue;
			
		zp_infect_user(id, 0, 1, 0) // Turn into a zombie
	}
}

/*-------------------------------------
--> Class Functions/Skills
--------------------------------------*/
public checkModel(id) {
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;

	if(!GetUserPain(id))
		return PLUGIN_HANDLED;
	
	if(get_user_weapon(id) == CSW_KNIFE) {
		entity_set_string(id, EV_SZ_viewmodel, v_knife_model)
		entity_set_string(id, EV_SZ_weaponmodel, p_knife_model)
	}
	return PLUGIN_HANDLED
}

// Kunai Damage
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if(!is_user_alive(attacker) || !is_user_alive(victim))
		return HAM_IGNORED

	if(GetUserPain(attacker) && get_user_weapon(attacker) == CSW_KNIFE)
		SetHamParamFloat(4, get_pcvar_float(cvar_damage))

	return HAM_IGNORED;
}
public zp_user_humanized_post(id) {
	
	if(!GetUserPain(id)) 
		return;

	if(!zp_has_round_started())
		zp_set_custom_game_mod(g_gameid)
	
	if(is_user_bot(id)) {
		remove_task(id)
		set_task(random_float(5.0, 15.0), "bot_suport", id, _, _, "b")
	}
	
	reset_pain_vars(id, 0)
	client_print_color(id, print_team_default, "%L %L", id, "PAIN_TAG", id, "PAIN_INFO")

}
public zp_user_infected_post(id) reset_pain_vars(id, 0);
public client_disconnected(id) reset_pain_vars(id, 0);

public zp_round_ended() {
	if(zp_get_last_mode() == g_gameid)
		reset_pain_vars(0, 1);
}


public reset_pain_vars(id, resetall) {
	
	if(resetall) {
		used_super_shinra = false
		super_shinra_allow = false
		remove_task(TASK_SUPER_SHINRA)
		set_task(get_cvar_float("mp_roundtime") * 60.0 - 50.0, "allow_super_shinra", TASK_SUPER_SHINRA)
	
		static ent; ent = -1
		while((ent = find_ent_by_class(ent, chibaku_tensei_class)) > 0) {
			remove_entity(ent)
		}
	}
	
	if(id) {
		g_used_skill[CHIBAKU_TENSEI][id] = false
		g_used_skill[SHINRA_TENSEI][id] = false
		g_used_skill[BANSHO_TENIN][id] = false
		g_hooked[id] = 0
		g_skill_id[id] = SHINRA_TENSEI
		remove_task(id + TASK_CHIBAKU)
		remove_task(id + TASK_SHINRA)
		remove_task(id + TASK_SUPER_SHINRA_USES)
		remove_task(id + TASK_CHIBAKU_COUNTDOWN)
		remove_task(id + TASK_SHINRA_COUNTDOWN)
		remove_task(id + TASK_BANSHO_COUNTDOWN)
		remove_task(id + TASK_BANSHO_PUSH)
		
	}
	else {
		static i;
		for(i = 1; i <= MaxClients; i++) {
			g_used_skill[CHIBAKU_TENSEI][i] = false
			g_used_skill[SHINRA_TENSEI][i] = false
			g_used_skill[BANSHO_TENIN][i] = false
			g_hooked[i] = 0
			g_skill_id[i] = SHINRA_TENSEI
			remove_task(i + TASK_CHIBAKU)
			remove_task(i + TASK_SHINRA)
			remove_task(i + TASK_SUPER_SHINRA_USES)
			remove_task(i + TASK_CHIBAKU_COUNTDOWN)
			remove_task(i + TASK_SHINRA_COUNTDOWN)
			remove_task(i + TASK_BANSHO_COUNTDOWN)
			remove_task(i + TASK_BANSHO_PUSH)
		}
	}
		
}

public bot_suport(id) {
	if(!is_user_alive(id) || zp_has_round_ended() || used_super_shinra || !is_user_bot(id)) {
		remove_task(id)
		return
	}
	if(!GetUserPain(id)) {
		remove_task(id)
		return
	}
	switch(random_num(0, super_shinra_allow ? 3 : 2)) {
		case 0: chibaku_tensei(id + TASK_CHIBAKU)
		case 1: shinra_tensei(id + TASK_SHINRA)
		case 2: use_bansho_tenin(id)
		case 3: super_shinra_tensei(id + TASK_SUPER_SHINRA_USES)
	}
}

public client_PreThink(id) {
	if(!is_user_alive(id) || zp_has_round_ended() || used_super_shinra)
		return
	
	if(!GetUserPain(id)) 
		return;

	static userButton, userOldButton;
	userButton = get_user_button(id);
	userOldButton = get_user_oldbutton(id);

	if((userButton & IN_RELOAD) && !(userOldButton & IN_RELOAD)) {
		if(g_skill_id[id] >= BANSHO_TENIN && !super_shinra_allow || g_skill_id[id] >= SUPER_SHINRA_TENSEI && super_shinra_allow)
			g_skill_id[id] = SHINRA_TENSEI
		else
			g_skill_id[id]++

		client_print(id, print_center, "%L", id, skill_string[g_skill_id[id]])
		client_cmd(id, "spk common/wpn_moveselect.wav")
	}
	else if((userButton & IN_USE) && !(userOldButton & IN_USE)) {	
		switch(g_skill_id[id]) {
			case CHIBAKU_TENSEI: {
				// Chibaku Tensei
				if(g_used_skill[CHIBAKU_TENSEI][id]) {
					client_print_color(id, print_team_default, "%L %L", id, "PAIN_TAG", id, "CHIBAKU_WAIT")
					return
				}
				
				progressBar(id, 2)
				remove_task(id + TASK_CHIBAKU)
				set_task(2.0, "chibaku_tensei", id + TASK_CHIBAKU)
			}
			case SHINRA_TENSEI: {
				// Shinra Tensei
				if(g_used_skill[SHINRA_TENSEI][id]) {
					client_print_color(id, print_team_default, "%L %L", id, "PAIN_TAG", id, "SHINRA_WAIT")
					return
				}
				
				progressBar(id, 2)
				remove_task(id + TASK_SHINRA)
				set_task(2.0, "shinra_tensei", id + TASK_SHINRA)
			}
			case BANSHO_TENIN: use_bansho_tenin(id)

			case SUPER_SHINRA_TENSEI: {
				// Super Shinra Tensei
				if(super_shinra_allow && !used_super_shinra) {
					progressBar(id, 5)
					remove_task(id + TASK_SUPER_SHINRA_USES)
					set_task(5.0, "super_shinra_tensei", id + TASK_SUPER_SHINRA_USES)
				}
			}
		}
	}
	else if((userOldButton & IN_USE) && !(userButton & IN_USE)) {
		remove_task(id + TASK_SUPER_SHINRA_USES)
		remove_task(id + TASK_SHINRA)
		remove_task(id + TASK_CHIBAKU)
		progressBar(id, 0)

		if(g_hooked[id] && !is_user_bot(id)) {
			g_used_skill[BANSHO_TENIN][id] = true
			remove_task(id+TASK_BANSHO_COUNTDOWN)
			set_task(get_pcvar_float(cvar_bansho[2]), "allow_use_bansho", id+TASK_BANSHO_COUNTDOWN)
			g_hooked[id] = 0
		}
	}
}

/*===============================================================================
[Shinra Tensei]
=================================================================================*/
public shinra_tensei(id) {
	id -= TASK_SHINRA
	
	if(g_used_skill[SHINRA_TENSEI][id])
		return;
	
	g_used_skill[SHINRA_TENSEI][id] = true
	set_task(g_shinra_countdown, "allow_shinra_again", id+TASK_SHINRA_COUNTDOWN)
	
	emit_sound(id, CHAN_STATIC, skill_sounds[SHINRA_TENSEI], 1.0, ATTN_NORM, 0, PITCH_NORM) // Shinra Tensei Sound
	use_shinra_tensei(id)
}

public allow_shinra_again(id) {
	id -= TASK_SHINRA_COUNTDOWN

	if(!is_user_alive(id) || !GetUserPain(id))
		return;

	g_used_skill[SHINRA_TENSEI][id] = false
	client_print_color(id, print_team_default, "%L %L", id, "PAIN_TAG", id, "SHINRA_READY")
}

public use_shinra_tensei(attacker) {
	if(!is_user_alive(attacker) || !GetUserPain(attacker))
		return;

	// Get origin
	static Float:originF[3], origin[3], victim
	entity_get_vector(attacker, EV_VEC_origin, originF)
	
	FVecIVec(originF, origin)
	create_blast2(origin)
	
	victim = -1
	
	while((victim = find_ent_in_sphere(victim, originF, g_radius)) != 0) {
		if(!is_user_alive(victim))
			continue;

		if(!zp_get_user_zombie(victim) || zp_get_user_madness(victim)) 
			continue;
		
		zp_set_user_extra_damage(victim, attacker, g_damage, "Shinra Tensei")
		
		static Float:vec[3], Float:oldvelo[3];
		get_user_velocity(victim, oldvelo);
		create_velocity_vector(victim , attacker , vec);
		vec[0] += oldvelo[0];
		vec[1] += oldvelo[1];
		set_user_velocity(victim , vec);
	}
}

/*===============================================================================
[Super Shinra Tensei]
=================================================================================*/
public super_shinra_tensei(id) {
	id -= TASK_SUPER_SHINRA_USES
	
	if(used_super_shinra) return;
	
	// Launch sound
	client_cmd(0, "spk %s", skill_sounds[SUPER_SHINRA_TENSEI])
	
	set_task(5.0, "super_shinra_launch")
	set_task(17.0, "super_shinra_blast")
	
	used_super_shinra = true
	
	set_hudmessage(255, 0, 0, -1.0, -1.0, 1, 5.0, 5.0, 0.1, 0.2)
	show_hudmessage(0, "%L", LANG_PLAYER, "WORLD_KNOW_THE_PAIN")
}

public allow_super_shinra() {
	super_shinra_allow = true
	
	static id;
	for(id = 1; id <= MaxClients; id++) {
		if(!is_user_alive(id))
			continue;

		if(GetUserPain(id))
			client_print_color(id, print_team_default, "%L %L", id, "PAIN_TAG", id, "SUPER_SHINRA_READY")
	}
}

public super_shinra_launch() {
	// Screen fade effect
	message_begin(MSG_BROADCAST, get_user_msgid("ScreenFade"))
	write_short((1<<12)*12)	// Duration
	write_short((1<<12)*1)	// Hold time
	write_short(0x0001)	// Fade type
	write_byte(255)	// Red
	write_byte(255)	// Green
	write_byte(255)	// Blue
	write_byte(255)	// Alpha
	message_end()
}

public super_shinra_blast() {
	static id, deathmsg_block
	
	deathmsg_block = get_msg_block(g_msgDeathMsg)
	
	set_msg_block(g_msgDeathMsg, BLOCK_SET)
	
	for(id = 1; id <= MaxClients; id++) {
		if(!is_user_alive(id))
			continue;

		if(zp_get_user_zombie(id)) 
			user_kill(id, 1)
	}
	
	set_msg_block(g_msgDeathMsg, deathmsg_block)
}

/*===============================================================================
[Chibaku Tensei]
=================================================================================*/
public chibaku_tensei(id) {
	id -= TASK_CHIBAKU

	if(!is_user_alive(id))
		return;
	
	if(g_used_skill[CHIBAKU_TENSEI][id] || !GetUserPain(id))
		return	

	gForce = get_pcvar_num(cvar_force)
	
	g_used_skill[CHIBAKU_TENSEI][id] = true
	set_task(get_pcvar_float(cvar_countdown), "end_countdown_chibaku", id+TASK_CHIBAKU_COUNTDOWN)
	
	gRange = get_pcvar_num(cvar_range)
	
	emit_sound(id, CHAN_STATIC, skill_sounds[CHIBAKU_TENSEI], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	create_chibaku_tensei(id)
}

public create_chibaku_tensei(id) {
	static Float:Origin[3], Float:vAngle[3], NewEnt
	
	// Get position from eyes
	get_user_eye_position(id, Origin)
	
	// Get View Angles
	entity_get_vector(id, EV_VEC_v_angle, vAngle)
	
	NewEnt = create_entity("info_target")
	
	entity_set_string(NewEnt, EV_SZ_classname, chibaku_tensei_class)
	entity_set_model(NewEnt, chibaku_beam_spr)
	entity_set_size(NewEnt, Float:{ -0.5, -0.5, -0.5 }, Float:{ 0.5, 0.5, 0.5 })
	entity_set_origin(NewEnt, Origin)
	
	//make_vector(vAngle)
	entity_set_vector(NewEnt, EV_VEC_angles, vAngle)
	
	entity_set_int(NewEnt, EV_INT_solid, SOLID_TRIGGER)
	entity_set_int(NewEnt, EV_INT_movetype, MOVETYPE_FLY)
	
	entity_set_float(NewEnt, EV_FL_scale, 0.01)
	set_rendering(NewEnt, kRenderFxNone, 0, 0, 0, kRenderTransAdd, 255)
	
	entity_set_edict(NewEnt, EV_ENT_owner, id)
	entity_set_vector(NewEnt, EV_VEC_velocity, Float:{ 0.0, 10.0, 100.0 }) 

	entity_set_float(NewEnt, EV_FL_fuser1, get_pcvar_float(cvar_time))
	entity_set_float(NewEnt, EV_FL_fuser2, get_gametime())

	entity_set_float(NewEnt, EV_FL_nextthink, get_gametime() + 0.1)
}

public fw_ChibakuThink(ent) {
	if(!is_valid_ent(ent)) 
		return PLUGIN_HANDLED;
		
	static classname[32]; entity_get_string(ent, EV_SZ_classname, classname, charsmax(classname))

	if(!equal(classname, chibaku_tensei_class)) 
		return PLUGIN_HANDLED;

	static owner, Float:timer1, Float:timer2, Float:chibaku_size, Float:fl_Origin[3], Origin[3], randomNum, Float:GameTime;

	owner = entity_get_edict(ent, EV_ENT_owner)
	timer1 = entity_get_float(ent, EV_FL_fuser1)
	timer2 = entity_get_float(ent, EV_FL_fuser2)
	chibaku_size = entity_get_float(ent, EV_FL_scale)
	GameTime = get_gametime();

	if(!is_user_alive(owner) || GameTime-timer1 > timer2 || !GetUserPain(owner) || zp_has_round_ended()) {
		remove_entity(ent)
		return PLUGIN_HANDLED;
	}

	if(chibaku_size < 2.0)
		entity_set_float(ent, EV_FL_scale, chibaku_size+0.1)
	else
		entity_set_vector(ent, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 }) 
	
	entity_get_vector(ent, EV_VEC_origin, fl_Origin)

	FVecIVec(fl_Origin, Origin)

	if(get_pcvar_num(cvar_particles)) {
		// Particle effect
		message_begin(MSG_PVS, SVC_TEMPENTITY, Origin);
		write_byte(TE_IMPLOSION);
		write_coord(Origin[0]);
		write_coord(Origin[1]);
		write_coord(Origin[2]+10);
		write_byte(200)	// radius
		write_byte(40) // count
		write_byte(45) // life in 0.1's
		message_end()
	}


	Origin[2] += random(1000) - 200	// Mostly above the player
	randomNum = 1 + random(19)
	WhiteFluffyChibakuWave(Origin, gRange/2, randomNum)
	
	static i;
	for(i = 1; i <= MaxClients; i++) {
		if(!is_user_alive(i))
			continue;

		if(!zp_get_user_zombie(i) || zp_get_user_madness(i) || get_entity_distance(i, ent) > gRange) 
			continue

		SuckPlayerIntoChibaku(i, fl_Origin, gRange/2)
	}

	entity_set_float(ent, EV_FL_nextthink, GameTime + 0.15)
	return PLUGIN_HANDLED;
}

SuckPlayerIntoChibaku(id, Float:fl_Eye[3], offset) {
	if(!is_user_alive(id))
		return;

	if(!zp_get_user_zombie(id) || zp_get_user_madness(id))
		return;

	new Float:fl_Player[3], Float:fl_Target[3], Float:fl_Velocity[3], Float:fl_Distance
	entity_get_vector(id, EV_VEC_origin, fl_Player)
	
	// I only want the horizontal direction
	fl_Player[2] = 0.0
	
	fl_Target[0] = fl_Eye[0]
	fl_Target[1] = fl_Eye[1]
	fl_Target[2] = 0.0
	
	// Calculate the direction and add some offset to the original target, 
	// so we don't fly strait into the eye but to the side of it.
	
	fl_Distance = vector_distance(fl_Player, fl_Target)
	
	fl_Velocity[0] =(fl_Target[0] -  fl_Player[0]) / fl_Distance	
	fl_Velocity[1] =(fl_Target[1] -  fl_Player[1]) / fl_Distance
	
	fl_Target[0] += fl_Velocity[1]*offset
	fl_Target[1] -= fl_Velocity[0]*offset
	
	// Recalculate our direction and set our velocity
	fl_Distance = vector_distance(fl_Player, fl_Target)
	
	fl_Velocity[0] =(fl_Target[0] -  fl_Player[0]) / fl_Distance	
	fl_Velocity[1] =(fl_Target[1] -  fl_Player[1]) / fl_Distance
	
	fl_Velocity[0] = fl_Velocity[0] * gForce
	fl_Velocity[1] = fl_Velocity[1] * gForce
	fl_Velocity[2] = 0.4 * gForce
	
	entity_set_vector(id, EV_VEC_velocity, fl_Velocity)
}

WhiteFluffyChibakuWave(vec[3], radius, life) {
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, vec)
	write_byte(21)		//TE_BEAMCYLINDER
	write_coord(vec[0])
	write_coord(vec[1])
	write_coord(vec[2])
	write_coord(vec[0])
	write_coord(vec[1])
	write_coord(vec[2] + radius)
	write_short(white)
	write_byte(0)		// startframe
	write_byte(0)		// framerate
	write_byte(life)	// life
	write_byte(128)		// width 128
	write_byte(0)		// noise
	write_byte(255)		// r
	write_byte(255)		// g
	write_byte(255)		// b
	write_byte(200)		// brightness
	write_byte(0)		// scroll speed
	message_end()
}

public end_countdown_chibaku(id) {
	id -= TASK_CHIBAKU_COUNTDOWN
	if(!is_user_alive(id))
		return

	if(!GetUserPain(id))
		return;

	g_used_skill[CHIBAKU_TENSEI][id] = false
	client_print_color(id, print_team_default, "%L %L", id, "PAIN_TAG", id, "CHIBAKU_READY")
}

/*===============================================================================
[bansho Ten'in]
=================================================================================*/
public use_bansho_tenin(id) {
	if (!is_user_alive(id) || zp_has_round_ended() || used_super_shinra) 
		return

	if(!GetUserPain(id))
		return;

	if(g_used_skill[BANSHO_TENIN][id]) {
		client_print_color(id, print_team_default, "%L %L", id, "PAIN_TAG", id, "BANSHO_WAIT")
		return;
	}
	g_hooked[id] = 0
	static target, body
	get_user_aiming(id, target, body)

	if(!is_user_alive(target)) {
		client_print_color(id, print_team_default, "%L %L", id, "PAIN_TAG", id, "BANSHO_AIM_TO")
		return;
	}
	else if(zp_get_user_zombie(target)) {
		g_hooked[id] = target
		emit_sound(id, CHAN_STATIC, skill_sounds[BANSHO_TENIN], 1.0, ATTN_NORM, 0, PITCH_NORM)

		static parm[2]
		parm[0] = id
		parm[1] = g_hooked[id]
		set_task(0.1, "bansho_push", id+TASK_BANSHO_PUSH, _, _, "b")
	}
	else client_print_color(id, print_team_default, "%L %L", id, "PAIN_TAG", id, "BANSHO_AIM_TO")
		

}
public bansho_push(attacker) {
	attacker -= TASK_BANSHO_PUSH
	static victim, Float:fl_Velocity[3], Attacker_Origin[3], Victim_Origin[3], Float:fl_Time, distance

	if (!is_user_alive(attacker)) {
		remove_task(attacker+TASK_BANSHO_PUSH)
		return
	}

	if (!g_hooked[attacker] || !GetUserPain(attacker)) {
		remove_task(attacker+TASK_BANSHO_PUSH)
		return
	}

	victim = g_hooked[attacker]

	if (!is_user_alive(victim) || !zp_get_user_zombie(victim)) {
		g_used_skill[BANSHO_TENIN][attacker] = true
		remove_task(attacker+TASK_BANSHO_COUNTDOWN)
		set_task(get_pcvar_float(cvar_bansho[2]), "allow_use_bansho", attacker+TASK_BANSHO_COUNTDOWN)
		g_hooked[attacker] = 0
		remove_task(attacker+TASK_BANSHO_PUSH)
		return
	}

	get_user_origin(victim, Victim_Origin)
	get_user_origin(attacker, Attacker_Origin)

	distance = get_distance(Attacker_Origin, Victim_Origin)

	if (distance > 5) {
		fl_Time = distance / get_pcvar_float(cvar_bansho[0])
		fl_Velocity[0] = (Attacker_Origin[0] - Victim_Origin[0]) / fl_Time
		fl_Velocity[1] = (Attacker_Origin[1] - Victim_Origin[1]) / fl_Time
		fl_Velocity[2] = (Attacker_Origin[2] - Victim_Origin[2]) / fl_Time
	}
	else {
		fl_Velocity[0] = 0.0
		fl_Velocity[1] = 0.0
		fl_Velocity[2] = 0.0
	}

	entity_set_vector(victim, EV_VEC_velocity, fl_Velocity)
}

public allow_use_bansho(id) {
	id -= TASK_BANSHO_COUNTDOWN
	if(!is_user_alive(id))
		return;
	
	if(!GetUserPain(id))
		return;

	g_used_skill[BANSHO_TENIN][id] = false
	client_print_color(id, print_team_default, "%L %L", id, "PAIN_TAG", id, "BANSHO_READY")
}

public player_touch(victim, attacker) {

	if (!is_user_alive(victim) || !is_user_alive(attacker)) 
		return

	if(!zp_get_user_zombie(victim) || !GetUserPain(attacker))
		return

	if (g_hooked[attacker] == victim) {

		static parm[2]
		parm[0] = attacker
		parm[1] = victim
		set_task(0.1, "bansho_uppercut", attacker+100, parm, 2)

		g_used_skill[BANSHO_TENIN][attacker] = true
		remove_task(attacker+TASK_BANSHO_COUNTDOWN)
		set_task(get_pcvar_float(cvar_bansho[2]), "allow_use_bansho", attacker+TASK_BANSHO_COUNTDOWN)
		g_hooked[attacker] = 0
	}
}
public bansho_uppercut(parm[]) {
	static victim, attacker, Origin[3], vicOrigin[3], Float:fl_Time, Float:fl_vicVelocity[3]
	victim = parm[1]
	attacker = parm[0]
	
	if (!is_user_alive(victim) || !is_user_alive(attacker)) 
		return

	if(!zp_get_user_zombie(victim) || !GetUserPain(attacker))
		return;

	get_user_origin(attacker, Origin)
	get_user_origin(victim, vicOrigin)

	emit_sound(victim, CHAN_BODY, "player/headshot3.wav", 1.0, ATTN_NORM, 0, PITCH_LOW)
	blood_spray(victim, vicOrigin)

	fl_Time = get_distance(vicOrigin, Origin) / 300.0

	fl_vicVelocity[0] = (vicOrigin[0] - Origin[0]) / fl_Time
	fl_vicVelocity[1] = (vicOrigin[1] - Origin[1]) / fl_Time
	fl_vicVelocity[2] = 450.0

	entity_set_vector(victim, EV_VEC_velocity, fl_vicVelocity)
	zp_set_user_extra_damage(victim, attacker, get_pcvar_num(cvar_bansho[1]), "[Pain] Bansho Ten'in")
}

/*===============================================================================
[Stocks]
=================================================================================*/
// Progress Bar
progressBar(id, seconds) {
	if(!is_user_connected(id))
		return;

	message_begin(MSG_ONE_UNRELIABLE, gMsgBarTime, _, id)
	write_byte(seconds)
	write_byte(0)
	message_end()
}

// Shinra Tensei Ring(From Napalm Nade of MeRcyLeZZ)
create_blast2(const originF[3]) {
	static radius_shockwave, size, i
	size = 0
	radius_shockwave = get_pcvar_num(cvar_shinra_radius)
	while(radius_shockwave >= 60) {
		radius_shockwave -= 60
		size++
	}
	
	for(i = 0; i < 3; i++) {
		message_begin(MSG_PVS, SVC_TEMPENTITY, originF, 0)
		write_byte(TE_BEAMCYLINDER) // TE id
		write_coord(originF[0]) // x
		write_coord(originF[1]) // y
		write_coord(originF[2]) // z
		write_coord(originF[0]) // x axis
		write_coord(originF[1]) // y axis
		write_coord(originF[2]+floatround(g_radius)) // z axis
		write_short(g_exploSpr) // sprite
		write_byte(0) // startframe
		write_byte(0) // framerate
		write_byte(size) // life
		write_byte(60) // width
		write_byte(0) // noise
		write_byte(255) // red
		write_byte(255) // green
		write_byte(255) // blue
		write_byte(i == 1 ? 50 : 200) // brightness
		write_byte(0) // speed
		message_end()
	}
}

stock get_user_eye_position(id, Float:flOrigin[3]) {
	static Float:flViewOffs[3]
	entity_get_vector(id, EV_VEC_view_ofs, flViewOffs)
	entity_get_vector(id, EV_VEC_origin, flOrigin)
	xs_vec_add(flOrigin, flViewOffs, flOrigin)
}

// Shinra Tensei Knockback 
stock create_velocity_vector(victim, attacker, Float:velocity[3]) {
	if(is_user_connected(victim)) {
		if(!zp_get_user_zombie(victim) || !is_user_alive(attacker))
			return 0;
		
		static Float:vicorigin[3], Float:attorigin[3], Float:origin2[3], Float:largestnum, a
		entity_get_vector(victim, EV_VEC_origin, vicorigin);
		entity_get_vector(attacker, EV_VEC_origin, attorigin);
		
		origin2[0] = vicorigin[0] - attorigin[0];
		origin2[1] = vicorigin[1] - attorigin[1];

		largestnum = 0.0;
		if(floatabs(origin2[0])>largestnum) largestnum = floatabs(origin2[0]);
		if(floatabs(origin2[1])>largestnum) largestnum = floatabs(origin2[1]);
		
		origin2[0] /= largestnum;
		origin2[1] /= largestnum;
		
		a = 1500
		velocity[0] =(origin2[0] * (100 *a)) / get_entity_distance(victim , attacker);
		velocity[1] =(origin2[1] * (100 *a)) / get_entity_distance(victim , attacker);
		if(velocity[0] <= 20.0 || velocity[1] <= 20.0)
		velocity[2] = random_float(200.0 , 275.0);
	}
	return 1;
}

public blood_spray(vic, vicOrigin[3]) {
	static x, y, i, j
	for(i = 0; i < 2; i++) {
		x = random_num(-10, 10)
		y = random_num(-10, 10)
		for(j = 0; j < 2; j++) {
			// Blood spray
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(115)				// TE_BLOODSPRITE
			write_coord(vicOrigin[0]+(x*j))	// position
			write_coord(vicOrigin[1]+(y*j))
			write_coord(vicOrigin[2]+21)
			write_short(g_spriteBldSpray)	// sprite1 index
			write_short(g_spriteBlood)	// sprite2 index
			write_byte(248) 			// color RED = 248 YELLOW = 196
			write_byte(10) 			// scale
			message_end()
		}
	}
}
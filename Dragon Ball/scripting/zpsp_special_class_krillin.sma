/*===========================================================================================================
				[ZPSp] Special Class: Krillin

		[Requeriments]
	* Amxmodx 1.9 or higher
	* Zombie Plague Special 4.5 or higher

		[Button Description]
	Hold [E] Button for use a destruction disc

		[Cvars]
	zp_krillin_minplayers "2"		// Min players for start a gamemode
	zp_krillin_damage "250"			// Knife Damage
	zp_krillin_disc_damage "100"	// Destruction Disc Damage
	zp_krillin_cooldown "5.0"		// Skill Cooldown
	zp_krillin_diskspeed "999"		// Destruction Disc Speed
	zp_krillin_life "50"			// Destruction Disc Life
	zp_krillin_time_charge "4.0"	// Destruction Disc Time to Charge

		[Credits]
	[P]erfec[T] [S]cr[@]s[H]: For make this Gamemod/Special Class
	Gorlag/Batman and XxAvalanchexX: For Original Frieza Code from SH Mode

===========================================================================================================*/

#include <amxmodx>
#include <engine>
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

new const DiscSounds[][] = {
	"zombie_plague/destructodisc.wav",
	"zombie_plague/destructodisc_charge.wav",
	"zombie_plague/disc_fire.wav",
	"zombie_plague/disckill.wav"
}

/*-------------------------------------
--> Class Configs
--------------------------------------*/
#define Make_Acess ADMIN_IMMUNITY 	// Flag Acess make
new const sp_name[] = "Krillin"
new const sp_model[] = "dbz_krillin"
new const sp_hp = 5000
new const sp_speed = 300
new const Float:sp_gravity = 0.5
new const sp_aura_size = 25
new const sp_clip_type = 2
new const sp_allow_glow = 0
new sp_color_rgb[3] = { 255, 255, 0 }

new const default_v_knife[] = "models/zombie_plague/v_knife_dbz.mdl"
new v_knife_model[64]

/*-------------------------------------
--> Gamemode Config
--------------------------------------*/
new const g_chance = 90						// Gamemode chance
#define Start_Mode_Acess ADMIN_IMMUNITY

/*-------------------------------------
--> Variables/Defines
--------------------------------------*/
new g_gameid, g_msg_sync, cvar_minplayers
new g_special_id, g_power_used[33], diskTimer[33], disk[33], flash, cvar_disk_power[5], cvar_krillin_dmg

#define GetUserKrillin(%1) (zp_get_human_special_class(%1) == g_special_id)
#define IsKrillinRound() (zp_get_current_mode() == g_gameid)

// Tasks
#define TASK_FIRE 2312
#define TASK_POWER 4422

// Disk Entity Config
new const DISC_CLASSNAME[] = "destrucion_disc"
new const DISC_MODEL[] = "models/zombie_plague/kurilin_disc.mdl"
new const DISK_TRAIL[] = "sprites/muzzleflash2.spr"

/*-------------------------------------
--> Plugin Registeration
--------------------------------------*/
public plugin_init()
{
	register_plugin("[ZPSp] Special Class: Kurilin","1.0", "[P]erfec[T] [S]cr[@]s[H]")
	register_dictionary("zp_dbm_classes.txt")

	cvar_minplayers = register_cvar("zp_krillin_minplayers", "2")
	cvar_krillin_dmg = register_cvar("zp_krillin_damage", "250")
	cvar_disk_power[0] = register_cvar("zp_krillin_disc_damage", "100")
	cvar_disk_power[1] = register_cvar("zp_krillin_cooldown", "5.0")
	cvar_disk_power[2] = register_cvar("zp_krillin_diskspeed", "999")
	cvar_disk_power[3] = register_cvar("zp_krillin_life", "50")
	cvar_disk_power[4] = register_cvar("zp_krillin_time_charge", "4.0")

	register_touch(DISC_CLASSNAME, "*", "touch_event")
	register_think(DISC_CLASSNAME, "disklife")

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")

	g_msg_sync = CreateHudSyncObj()
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

	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_KNIFE KRILLIN", v_knife_model, charsmax(v_knife_model))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Weapon Models", "V_KNIFE KRILLIN", default_v_knife)
		formatex(v_knife_model, charsmax(v_knife_model), default_v_knife)
	}

	// Register our game mode
	g_gameid = zpsp_register_gamemode(sp_name, Start_Mode_Acess, g_chance, 0, ZP_DM_NONE, .uselang=1, .langkey="KRILLIN_CLASS_NAME")
	g_special_id = zp_register_human_special(sp_name, sp_model, sp_hp, sp_speed, sp_gravity, Make_Acess, sp_clip_type, sp_aura_size, sp_allow_glow, sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2])

	// Set lang configuration
	amx_save_setting_int(ZP_SPECIAL_CLASSES_FILE, fmt("H:%s", sp_name), "NAME BY LANG", 1)
	amx_save_setting_string(ZP_SPECIAL_CLASSES_FILE, fmt("H:%s", sp_name), "LANG KEY", "KRILLIN_CLASS_NAME")

	precache_model(v_knife_model)
	precache_model(DISC_MODEL)
	flash = precache_model(DISK_TRAIL)

	static i
	for(i = 0; i < sizeof DiscSounds; i++)
		precache_sound(DiscSounds[i])

	// Register round start sound
	for(i = 0; i < sizeof gamemode_round_start_snd; i++)
		zp_register_start_gamemode_snd(g_gameid, gamemode_round_start_snd[i])

	// Register ambience sounds
	for (i = 0; i < sizeof gamemode_ambiences; i++)
		zp_register_gamemode_ambience(g_gameid, gamemode_ambiences[i][AmbiencePrecache], gamemode_ambiences[i][AmbienceDuration], ambience_enable)
}

/*-------------------------------------
--> Plugin Natives
--------------------------------------*/
public plugin_natives()
{
	register_native("zp_get_user_krillin", "native_get_user_krillin")
	register_native("zp_make_user_krillin", "native_make_user_krillin")
	register_native("zp_get_krillin_count", "native_get_krillin_count")
	register_native("zp_is_krillin_round", "native_is_krillin_round")
}

public native_get_user_krillin(plugin_id, num_params)
	return GetUserKrillin(get_param(1));

public native_make_user_krillin(plugin_id, num_params)
	return zp_make_user_special(get_param(1), g_special_id, GET_HUMAN);

public native_get_krillin_count(plugin_id, num_params)
	return zp_get_special_count(GET_HUMAN, g_special_id);

public native_is_krillin_round(plugin_id, num_params)
	return (IsKrillinRound());

/*-------------------------------------
--> Gamemode Functions
--------------------------------------*/
public zp_player_spawn_post(id)
{
	if(disk[id] > 0)
		remove_power(id, disk[id]);

	g_power_used[id] = false
	progress_bar(id, 0)
	remove_task(id+TASK_FIRE)
	remove_task(id+TASK_POWER)

	// Check for current mode
	if(IsKrillinRound())
		zp_infect_user(id)
}

public zp_round_started_pre(game) {
	if(game != g_gameid)
		return PLUGIN_CONTINUE

	if(zp_get_alive_players() < get_pcvar_num(cvar_minplayers))
		return ZP_PLUGIN_HANDLED

	start_krillin_mode()
	return PLUGIN_CONTINUE
}
public zp_game_mode_selected(gameid, id) {
	if(gameid == g_gameid)
		start_krillin_mode()
}

// This function contains the whole code behind this game mode
start_krillin_mode()
{
	static id, i
	id = 0
	for (i = 1; i <= MaxClients; i++) {
		if(!is_user_alive(i))
			continue;

		if(GetUserKrillin(i)) {
			id = i
			break;
		}
	}

	if(!id) {
		id = zp_get_random_player()
		zp_make_user_special(id, g_special_id, GET_HUMAN)
	}

	static name[32]; get_user_name(id, name, charsmax(name));
	set_hudmessage(sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2], -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "AN_A_KRILLIN", name)

	// Turn the remaining players into zombies
	for (id = 1; id <= MaxClients; id++) {
		if(!is_user_alive(id))
			continue;

		if(GetUserKrillin(id) || zp_get_user_zombie(id))
			continue;

		zp_infect_user(id)
	}
}

/*-------------------------------------
--> Class Functions
--------------------------------------*/
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if(!is_user_alive(attacker))
		return HAM_IGNORED

	if(GetUserKrillin(attacker) && get_user_weapon(attacker) == CSW_KNIFE)
		SetHamParamFloat(4, get_pcvar_float(cvar_krillin_dmg))

	return HAM_IGNORED
}
public zp_fw_deploy_weapon(id, wpnid) {
	if(wpnid != CSW_KNIFE)
		return PLUGIN_HANDLED;

	if(!is_user_alive(id))
		return PLUGIN_HANDLED;

	if(GetUserKrillin(id)) {
		entity_set_string(id, EV_SZ_viewmodel, v_knife_model)
		entity_set_string(id, EV_SZ_weaponmodel, "")
	}
	return PLUGIN_HANDLED
}

public zp_round_ended() {
	static id;
	for(id = 1; id <= MaxClients; id++)
		reset_vars(id)
}

public zp_user_humanized_post(id) {
	reset_vars(id)
	if(!GetUserKrillin(id))
		return;

	if(!zp_has_round_started())
		zp_set_custom_game_mod(g_gameid)

	if(is_user_bot(id)) {
		remove_task(id)
		set_task(random_float(5.0, 15.0), "bot_support", id, _, _, "b")
	}

	client_print_color(id, print_team_default, "%L", id, "KRILLIN_INFO")
}

public client_disconnected(id) reset_vars(id);
public zp_user_infected_post(id) reset_vars(id);

public reset_vars(id) {
	if(disk[id] > 0)
		remove_power(id, disk[id]);

	g_power_used[id] = false
	progress_bar(id, 0)
	remove_task(id+TASK_FIRE)
	remove_task(id+TASK_POWER)
}

public client_PreThink(id) {
	if(!is_user_alive(id) || zp_has_round_ended())
		return

	if(!GetUserKrillin(id))
		return;

	static button, oldbutton;
	button = get_user_button(id);
	oldbutton = get_user_oldbutton(id);

	if((button & IN_USE) && !(oldbutton & IN_USE)) {
		if(g_power_used[id]) {
			client_print_color(id, print_team_default, "%L", id, "KRILLIN_WAIT")
			return
		}
		if(disk[id]) {
			client_print_color(id, print_team_default, "%L", id, "KRILLIN_ONCE_POWER")
			return
		}

		emit_sound(id, CHAN_STATIC, DiscSounds[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		set_task(get_pcvar_float(cvar_disk_power[4]), "fire_disk", id+TASK_FIRE)
		progress_bar(id, 4)
	}
	else if(!(button & IN_USE) && (oldbutton & IN_USE)) {
		progress_bar(id, 0)
		remove_task(id+TASK_FIRE)
		emit_sound(id, CHAN_STATIC, DiscSounds[1], VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)
	}
}

public bot_support(id) {
	if(!is_user_alive(id))
		return

	if(g_power_used[id] || disk[id] || !GetUserKrillin(id))
		return

	emit_sound(id, CHAN_STATIC, DiscSounds[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	set_task(get_pcvar_float(cvar_disk_power[4]), "fire_disk", id+TASK_FIRE)
}

public disklife(ent) {
	if(!is_valid_ent(ent))
		return PLUGIN_CONTINUE;

	static id
	id = entity_get_edict(ent, EV_ENT_owner)

	if(!is_user_alive(id) || zp_has_round_ended()) {
		remove_power(id, ent)
		return PLUGIN_CONTINUE;
	}

	if(diskTimer[id] <= 0 || !GetUserKrillin(id) || zp_get_user_zombie(id)) {
		remove_power(id, ent)
		return PLUGIN_CONTINUE;
	}

	static Float: fVelocity[3]
	diskTimer[id]--
	velocity_by_aim(id, get_pcvar_num(cvar_disk_power[2]), fVelocity)
	entity_set_vector(ent, EV_VEC_velocity, fVelocity)
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.1)

	return PLUGIN_CONTINUE;
}
public fire_disk(id) {
	id -= TASK_FIRE
	if(entity_count() == get_global_int(GL_maxEntities))
		return;

	diskTimer[id] = get_pcvar_num(cvar_disk_power[3]) //How long the disk can fly
	g_power_used[id] = true
	set_task(get_pcvar_float(cvar_disk_power[1]), "allow_power_again", id+TASK_POWER)
	emit_sound(id, CHAN_STATIC, DiscSounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	remove_task(id+TASK_FIRE)
	emit_sound(id, CHAN_STATIC, DiscSounds[1], VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)

	static origin[3], velocity[3], distance_from_user
	static Float:fOrigin[3], Float:fVelocity[3], lifetime, NewEnt
	static Float:minBound[3], Float:maxBound[3], Float:viewing_angles[3]

	get_user_origin(id, origin, 1)
	minBound = Float:{-50.0, -50.0, 0.0}  //sets the minimum bound of entity
	maxBound = Float:{50.0, 50.0, 0.0}    //sets the maximum bound of entity
	IVecFVec(origin, fOrigin)

	distance_from_user = 70
	entity_get_vector(id, EV_VEC_angles, viewing_angles)
	fOrigin[0] += floatcos(viewing_angles[1], degrees) * distance_from_user
	fOrigin[1] += floatsin(viewing_angles[1], degrees) * distance_from_user
	fOrigin[2] += floatsin(-viewing_angles[0], degrees) * distance_from_user

	NewEnt = create_entity("info_target")  //Makes an object
	entity_set_string(NewEnt, EV_SZ_classname, DISC_CLASSNAME) //sets the classname of the entity
	disk[id] = NewEnt

	entity_set_model(NewEnt, DISC_MODEL)
	entity_set_origin(NewEnt, fOrigin)
	entity_set_int(NewEnt,EV_INT_movetype, MOVETYPE_NOCLIP)
	entity_set_int(NewEnt, EV_INT_solid, SOLID_TRIGGER)

	velocity_by_aim(id, get_pcvar_num(cvar_disk_power[2]), fVelocity)
	FVecIVec(fVelocity, velocity) //converts a floating vector to an integer vector

	entity_set_size(NewEnt, minBound, maxBound)
	entity_set_edict(NewEnt, EV_ENT_owner, id)
	entity_set_vector(NewEnt, EV_VEC_velocity, fVelocity)
	emit_sound(NewEnt, CHAN_STATIC, DiscSounds[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	entity_set_float(NewEnt, EV_FL_animtime, get_gametime());
	entity_set_float(NewEnt, EV_FL_framerate, 1.0);
	entity_set_float(NewEnt, EV_FL_frame, 0.0);
	entity_set_int(NewEnt, EV_INT_sequence, 0);

	lifetime = get_pcvar_num(cvar_disk_power[3])

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(22)       //TE_BEAMFOLLOW
	write_short(NewEnt)  //The entity to attach the sprite to
	write_short(flash)  //sprite's model
	write_byte(lifetime)   //life in 0.1 seconds
	write_byte(50)   //width of sprite
	write_byte(255)  //red
	write_byte(255)    //green
	write_byte(0)  //blue
	write_byte(100)  //brightness
	message_end()

	entity_set_float(NewEnt, EV_FL_nextthink, get_gametime() + 0.1)
}

public touch_event(pToucher, pTouched) {
	static aimvec[3], Float:fAimvec[3]
	entity_get_vector(pTouched, EV_VEC_origin, fAimvec)
	FVecIVec(fAimvec, aimvec)

	if(pTouched == entity_get_edict(pToucher, EV_ENT_owner))
		return PLUGIN_HANDLED

	if(is_user_connected(pTouched)) {
		special_effects(pToucher, pTouched, aimvec)
		return PLUGIN_CONTINUE
	}

	special_effects(pToucher, 0, aimvec)

	return PLUGIN_CONTINUE
}

public special_effects(pToucher, victim, aimvec[3]) { //effects for when disk touch
	static Float:fVelocity[3], velocity[3], damage, killer
	entity_get_vector(pToucher, EV_VEC_velocity, fVelocity)
	FVecIVec(fVelocity, velocity)

	// Sparks effect
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(9)  //SPARKS
	write_coord(aimvec[0])
	write_coord(aimvec[1])
	write_coord(aimvec[2])
	message_end()

	killer = entity_get_edict(pToucher, EV_ENT_owner)
	if(!is_user_alive(victim))
		return

	if(!zp_get_user_zombie(victim))
		return;

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(101)  //BLOODSTREAM
	write_coord(aimvec[0])
	write_coord(aimvec[1])
	write_coord(aimvec[2])
	write_coord(velocity[0])
	write_coord(velocity[1])
	write_coord(velocity[2])
	write_byte(95)
	write_byte(100)
	message_end()

	damage = get_pcvar_num(cvar_disk_power[0])
	zp_set_user_extra_damage(victim, killer, damage, "Destruction Disc", 1)
	emit_sound(victim, CHAN_STATIC, DiscSounds[3], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

public allow_power_again(id) {
	id -= TASK_POWER
	if(!is_user_alive(id))
		return

	if(!GetUserKrillin(id))
		return;

	g_power_used[id] = false
	client_print_color(id, print_team_default, "%L", id, "KRILLIN_SKILL_ENABLE");

}
public remove_power(id, powerID) {
	if(!is_valid_ent(powerID))
		return

	static szClassName[32]
	entity_get_string(powerID, EV_SZ_classname, szClassName, charsmax(szClassName))

	if(equal(szClassName, DISC_CLASSNAME) && id == entity_get_edict(powerID, EV_ENT_owner)) {
		remove_entity(powerID)
		diskTimer[id] = -1
		disk[id] = 0
	}
}

public progress_bar(id, duration) {
	if(!is_user_connected(id))
		return

	message_begin(MSG_ONE, get_user_msgid("BarTime"), _, id)
	write_short(duration)
	message_end()
}
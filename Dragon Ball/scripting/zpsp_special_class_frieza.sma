/*===========================================================================================================
				[ZPSp] Special Class: Frieza

		[Requeriments]
	* Amxmodx 1.9 or higher
	* Zombie Plague Special 4.5 or higher

		[Button Description]
	Press [E] Button for use a destruction disc

		[Cvars]
	zp_frieza_minplayers "2"		// Min players for start a gamemode
	zp_frieza_damage "500"			// Knife Damage
	zp_frieza_disc_damage "10000"	// Destruction Disc Damage
	zp_frieza_cooldown "5"			// Skill Cooldown
	zp_frieza_diskspeed "750"		// Destruction Disc Speed
	zp_frieza_disklife "50"			// Destruction Disc Life

		[Credits]
	[P]erfec[T] [S]cr[@]s[H]: For make this Gamemod/Special Class
	Gorlag/Batman and XxAvalanchexX: For Original Frieza Code from SH Mode

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
	"zombie_plague/nemesis.wav"
}

/*-------------------------------------
--> Class Configs
--------------------------------------*/
#define Make_Acess ADMIN_IMMUNITY 	// Flag Acess make
new const sp_name[] = "Frieza"
new const sp_model[] = "dbs_golden_frieza"
new const sp_knifemodel[] = "models/zombie_plague/v_golden_frieza.mdl"
new const sp_painsound[] = "zombie_plague/nemesis_pain1.wav"
new const sp_hp = 10000
new const sp_speed = 300
new const Float:sp_gravity = 0.5
new const sp_aura_size = 0
new const Float:sp_knockback = 0.25
new const sp_allow_glow = 0
new sp_color_rgb[3] = { 255, 255, 0 }

/*-------------------------------------
--> Gamemode Config
--------------------------------------*/
new const g_chance = 90						// Gamemode chance
#define Start_Mode_Acess ADMIN_IMMUNITY

/*-------------------------------------
--> Variables/Defines
--------------------------------------*/
new g_gameid, g_msg_sync, cvar_minplayers, cvar_frieza_damage, g_special_id
new g_power_used[33], diskTimer[33], disk[33], flash, cvar_frieza_power[4]

// Tasks
#define TASK_POWER 4422

// Disk Entity Configuration
new const disk_classname[] = "frieza_disk"
new const DISK_MODEL[] = "models/zombie_plague/kurilin_disc.mdl"
new const DISK_SOUND[] = "zombie_plague/frieza_destructodisc.wav"
new const DISK_TRAIL[] = "sprites/muzzleflash2.spr"

#define GetUserFrieza(%1) (zp_get_zombie_special_class(%1) == g_special_id)
#define IsFriezaRound() (zp_get_current_mode() == g_gameid)

/*-------------------------------------
--> Plugin Registeration
--------------------------------------*/
public plugin_init()
{
	register_plugin("[ZPSp] Special Class: Frieza", "1.0", "[P]erfec[T] [S]cr[@]s[H]")
	register_dictionary("zp_dbm_classes.txt")

	cvar_minplayers = register_cvar("zp_frieza_minplayers", "2")
	cvar_frieza_damage = register_cvar("zp_frieza_damage", "500")
	cvar_frieza_power[0] = register_cvar("zp_frieza_disc_damage", "10000")
	cvar_frieza_power[1] = register_cvar("zp_frieza_cooldown", "5")
	cvar_frieza_power[2] = register_cvar("zp_frieza_diskspeed", "750")
	cvar_frieza_power[3] = register_cvar("zp_frieza_disklife", "50")

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_touch(disk_classname, "*", "touch_event")
	register_think(disk_classname, "frieza_disklife")

	g_msg_sync = CreateHudSyncObj()
}

/*-------------------------------------
--> Plugin Precache
--------------------------------------*/
public plugin_precache()
{
	// Enable Infinite leap (BHOP) by default
	static Float:loaded
	if(!amx_load_setting_float(ZP_SPECIAL_CLASSES_FILE, fmt("Z:%s", sp_name), "LEAP COOLDOWN", loaded))
		amx_save_setting_float(ZP_SPECIAL_CLASSES_FILE, fmt("Z:%s", sp_name), "LEAP COOLDOWN", 0.0)

	// Register our game mode
	g_gameid = zpsp_register_gamemode(sp_name, Start_Mode_Acess, g_chance, 0, ZP_DM_NONE, .uselang=1, .langkey="FRIEZA_CLASS_NAME")
	g_special_id = zp_register_zombie_special(sp_name, sp_model, sp_knifemodel, sp_painsound, sp_hp, sp_speed, sp_gravity, Make_Acess, sp_knockback, sp_aura_size, sp_allow_glow, sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2])

	// Set lang configuration
	amx_save_setting_int(ZP_SPECIAL_CLASSES_FILE, fmt("Z:%s", sp_name), "NAME BY LANG", 1)
	amx_save_setting_string(ZP_SPECIAL_CLASSES_FILE, fmt("Z:%s", sp_name), "LANG KEY", "FRIEZA_CLASS_NAME")

	precache_model(DISK_MODEL)
	precache_sound(DISK_SOUND)
	flash = precache_model(DISK_TRAIL)

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
	register_native("zp_get_user_frieza", "native_get_user_frieza")
	register_native("zp_make_user_frieza", "native_make_user_frieza")
	register_native("zp_get_frieza_count", "native_get_frieza_count")
	register_native("zp_is_frieza_round", "native_is_frieza_round")
}

public native_get_user_frieza(plugin_id, num_params)
	return GetUserFrieza(get_param(1));

public native_make_user_frieza(plugin_id, num_params)
	return zp_make_user_special(get_param(1), g_special_id, GET_ZOMBIE);

public native_get_frieza_count(plugin_id, num_params)
	return zp_get_special_count(GET_ZOMBIE, g_special_id);

public native_is_frieza_round(plugin_id, num_params)
	return (IsFriezaRound());

/*-------------------------------------
--> Gamemode Functions
--------------------------------------*/
public zp_player_spawn_post(id) {
	if(disk[id] > 0) remove_power(id, disk[id]);

	// Check for current mode
	if(IsFriezaRound())
		zp_disinfect_user(id)
}

public zp_round_started_pre(game) {
	if(game != g_gameid)
		return PLUGIN_CONTINUE

	// Check for min players
	if(zp_get_alive_players() < get_pcvar_num(cvar_minplayers))
		return ZP_PLUGIN_HANDLED

	start_frieza_mode() // Start our new mode

	return PLUGIN_CONTINUE
}

public zp_game_mode_selected(gameid, id) {
	if(gameid == g_gameid)
		start_frieza_mode()
}

// This function contains the whole code behind this game mode
start_frieza_mode() {
	static id, i
	id = 0
	for (i = 1; i <= MaxClients; i++) {
		if(!is_user_alive(i))
			continue;

		if(GetUserFrieza(i)) {
			id = i
			break;
		}
	}

	if(!id) {
		id = zp_get_random_player()
		zp_make_user_special(id, g_special_id, GET_ZOMBIE)
	}

	static name[32]; get_user_name(id, name, charsmax(name));
	set_hudmessage(sp_color_rgb[0], sp_color_rgb[1], sp_color_rgb[2], -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "AN_A_FRIEZA", name)

	// ScreenFade
	ScreenFade(0, 5, sp_color_rgb, 255)
}

/*-------------------------------------
--> Class Functions
--------------------------------------*/
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if(!is_user_alive(attacker))
		return HAM_IGNORED

	if(GetUserFrieza(attacker))
		SetHamParamFloat(4, get_pcvar_float(cvar_frieza_damage))

	return HAM_IGNORED
}

public zp_user_humanized_post(id) {
	if(disk[id] > 0) remove_power(id, disk[id]);
	if(is_user_bot(id)) remove_task(id)
}

public zp_user_infected_post(id) {
	if(disk[id] > 0)
		remove_power(id, disk[id]);

	if(!GetUserFrieza(id))
		return;

	if(!zp_has_round_started())
		zp_set_custom_game_mod(g_gameid)

	if(is_user_bot(id)) {
		remove_task(id)
		set_task(random_float(5.0, 15.0), "use_cmd", id, _, _, "b") // Frieza Skills Bot Suport
	}

	g_power_used[id] = false
	client_print_color(id, print_team_default, "%L", id, "FRIEZA_INFO") // Frieza Info Msg
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch) {
	if(equal(sample, "common/wpn_denyselect.wav") && (pev(id, pev_button) & IN_USE))
		use_cmd(id); // Use power with IN_USE button
}

public allow_power_again(id)
{
	id -= TASK_POWER

	if(!is_user_alive(id))
		return;

	if(!GetUserFrieza(id))
		return;

	g_power_used[id] = false
	client_print_color(id, print_team_default, "%L", id, "FRIEZA_POWER_ENABLE");
}

public frieza_disklife(ent) {
	if(!is_valid_ent(ent))
		return FMRES_IGNORED

	static id
	id = entity_get_edict(ent, EV_ENT_owner)

	if(!is_user_alive(id) || zp_has_round_ended()) {
		remove_power(id, ent)
		return FMRES_IGNORED
	}

	if(diskTimer[id] <= 0 || !GetUserFrieza(id) || !zp_get_user_zombie(id)) {
		remove_power(id, ent)
		return FMRES_IGNORED
	}

	static Float: fVelocity[3]
	diskTimer[id]--
	velocity_by_aim(id, get_pcvar_num(cvar_frieza_power[2]), fVelocity)
	entity_set_vector(ent, EV_VEC_velocity, fVelocity)
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.1)

	return FMRES_IGNORED
}

public fire_disk(id) {
	if(entity_count() == get_global_int(GL_maxEntities))
		return;

	static origin[3], velocity[3], Float:minBound[3], Float:maxBound[3], distance_from_user
	static Float:fOrigin[3], Float:fVelocity[3], Float:viewing_angles[3], NewEnt, lifetime

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
	entity_set_string(NewEnt, EV_SZ_classname, disk_classname) //sets the classname of the entity
	disk[id] = NewEnt

	entity_set_model(NewEnt, DISK_MODEL)  //This tells what the object will look like
	entity_set_origin(NewEnt, fOrigin)  //This will set the origin of the entity
	entity_set_int(NewEnt,EV_INT_movetype, MOVETYPE_NOCLIP)  //This will set the movetype of the entity
	entity_set_int(NewEnt, EV_INT_solid, SOLID_TRIGGER) //This makes the entity touchable

	velocity_by_aim(id, get_pcvar_num(cvar_frieza_power[2]), fVelocity)  //This will set the velocity of the entity
	FVecIVec(fVelocity, velocity) //converts a floating vector to an integer vector

	entity_set_size(NewEnt, minBound, maxBound) //Sets the size of the entity
	entity_set_edict(NewEnt, EV_ENT_owner, id) //Sets who the owner of the entity is
	entity_set_vector(NewEnt, EV_VEC_velocity, fVelocity)  //This will set the entity in motion
	emit_sound(NewEnt, CHAN_VOICE, DISK_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM) //This will make the entity have sound.

	lifetime = get_pcvar_num(cvar_frieza_power[3])

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(22)       //TE_BEAMFOLLOW
	write_short(NewEnt)  //The entity to attach the sprite to
	write_short(flash)  //sprite's model
	write_byte(lifetime)   //life in 0.1 seconds
	write_byte(50)   //width of sprite
	write_byte(255)  //red
	write_byte(255)    //green
	write_byte(0)  //blue
	write_byte(255)  //brightness
	message_end()

	entity_set_float(NewEnt, EV_FL_nextthink, get_gametime() + 0.1)
}

public touch_event(pToucher, pTouched) {
	static aimvec[3], Float:fAimvec[3]  //This is the position where the disk collides
	entity_get_vector(pTouched, EV_VEC_origin, fAimvec)
	FVecIVec(fAimvec, aimvec)

	if(pTouched == entity_get_edict(pToucher, EV_ENT_owner))
		return PLUGIN_HANDLED

	// Checks to see if entity is a player or an inanimate object.
	if(is_user_alive(pTouched)) {
		special_effects(pToucher, pTouched, aimvec)
		return PLUGIN_CONTINUE
	}
	special_effects(pToucher, 0, aimvec)

	return PLUGIN_CONTINUE
}

public special_effects(pToucher, victim, aimvec[3]) {
	static Float:fVelocity[3], velocity[3], damage, attacker
	entity_get_vector(pToucher, EV_VEC_velocity, fVelocity)
	FVecIVec(fVelocity, velocity)

	// Sparks Effect
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(9)
	write_coord(aimvec[0])
	write_coord(aimvec[1])
	write_coord(aimvec[2])
	message_end()

	attacker = entity_get_edict(pToucher, EV_ENT_owner)

	if(!is_user_alive(victim))
		return;
	if(zp_get_user_zombie(victim))
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

	damage = get_pcvar_num(cvar_frieza_power[0])
	zp_set_user_extra_damage(victim, attacker, damage, "Frieza's Energy Disk")
}

public remove_power(id, powerID) {
	if(!is_valid_ent(powerID))
		return

	static szClassName[32]
	entity_get_string(powerID, EV_SZ_classname, szClassName, charsmax(szClassName))

	if(equal(szClassName, disk_classname) && id == entity_get_edict(powerID, EV_ENT_owner)) {
		remove_entity(powerID)
		diskTimer[id] = -1
		disk[id] = 0
	}
}

public client_disconnected(id) {
	if(disk[id] > 0) remove_power(id, disk[id]);
	if(is_user_bot(id)) remove_task(id)
}

public use_cmd(id) {
	if(!is_user_alive(id) || zp_has_round_ended())
		return

	if(!GetUserFrieza(id))
		return

	if(g_power_used[id]) {
		client_print_color(id, print_team_default, "%L", id, "FRIEZA_WAIT")
		return
	}
	if(disk[id]) {
		client_print_color(id, print_team_default, "%L", id, "FRIEZA_ONCE_POWER")
		return
	}

	diskTimer[id] = get_pcvar_num(cvar_frieza_power[3]) //How long the disk can fly
	fire_disk(id)
	g_power_used[id] = true
	set_task(get_pcvar_float(cvar_frieza_power[1]), "allow_power_again", id+TASK_POWER)
}

/*-------------------------------------
--> Stocks
--------------------------------------*/
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
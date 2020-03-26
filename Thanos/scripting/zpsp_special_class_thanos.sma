/*
	[ZPSp] Special Class: Thanos

	* Skill Introduction:
		- You can choose and use any Infinity Stone and Snap the fingers too.

	* Buttons:
		- [E (IN_USE)] - Use an selected Infinty Stone
		- [R (IN_RELOAD)] - Choose an Infinity Stone

	* Infinity Stone / Snap Skill Descriptions:
		- Power Stone: can kill anyone that around you
		- Space Stone: can teleport to aim with a trisseract
		- Reality Stone: can remove weapons from the person who is firing
		- Soul Stone: can absorb humans into a soul stone (Basing in theories)
		- Time Stone: can stop time for a few seconds
		- Mind Stone: can use a laser ray (Basing in some of Vision powers)
		- Snap the Fingers: Kill half of alive humans (Thanos Round Available Only)

	* Cvars:
		// Gamemode cvars
		zp_minplayers_thanos 2	// Minimum players required for start thanos mod automaticaly
		zp_damage_thanos 300	// Thanos knife damage

		// Thanos Cvars
		zp_thanos_skill_countdown 5			// Skill use delay
		zp_thanos_all_gems_time_allow 120	// Delay for allowing to snap fingers (Only in a Thanos Round)

		// Power Stone Cvars
		zp_thanos_power_damage 10000	// Power Stone damage
		zp_thanos_power_radius 300		// Power Stone Radius
		zp_thanos_power_knockback 2000	// Power Stone Knockback force (If player survives)

		// Soul Stone Cvars
		zp_thanos_soul_speed 600	// Speed to push for absortion
		zp_thanos_soul_radius 500	// Radius of 'Black hole'
		zp_thanos_soul_duration 5	// Soul Stone Skill Duration

		// Reality/Mind/Time Stone
		zp_thanos_time_duration 10		// Time Stone Skill Duration
		zp_thanos_reality_duration 10	// Reality Stone Skill Duration
		zp_thanos_mind_duration 10		// Mind Stone Skill Duration

*/

#include <amxmodx>
#include <hamsandwich>
#include <fakemeta_util>
#include <engine>
#include <zombie_plague_special>
#include <amx_settings_api>

#if ZPS_INC_VERSION < 43
	#assert Zombie Plague Special 4.3 or Higher Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif

new const ZP_CUSTOMIZATION_FILE[] = "zombie_plague_special.ini"

new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10", "weapon_aug", "weapon_smokegrenade", 
"weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552", "weapon_ak47", "weapon_knife", "weapon_p90" }

const OFFSET_NEXTATTACK = 83
const OFFSET_WEAPONOWNER = 41
const OFFSET_LINUX = 5 // offsets 5 higher in Linux builds
const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux
const FFADE_STAYOUT = 0x0004
const FFADE_IN = 0x0000
const UNIT_SECOND = (1<<12)

new Array:g_sound, g_ambience_sounds, Array:g_sound_amb_dur, Array: g_sound_ambience, cvar_frost_dur

// Default Sounds
new const sound[][] = { "zombie_plague/thanos_i-am-inevitable.wav" }
new const ambience_sound[][] = { "zombie_plague/ambience.wav" } 
new const ambience_dur[][] = { "17" }
new const snap_sound[] = "zombie_plague/thanos-snap-fingers.wav"
new const use_stone[] = "zombie_plague/thanos-use-stone.wav"

new const sp_name[] = "Thanos"
new const sp_model[] = "zp_thanos"
new const sp_knifemodel[] = "models/zombie_plague/v_knife_thanos.mdl"
new const sp_painsound[] = "player/bhit_kevlar-1.wav"
new const sp_hp = 20000
new const sp_speed = 270
new const Float:sp_gravity = 0.7
new const sp_aura_size = 0
new const Float:sp_knockback = 0.25
new const sp_allow_glow = 0
new const sp_color_r =  255
new const sp_color_g = 0
new const sp_color_b = 100
new acess_flags[2]

// Variables
new g_gameid, g_msg_sync, cvar_minplayers, cvar_damage, g_speciald, g_maxplayers
new const g_chance = 90

new const sprite_ring[] = "sprites/shockwave.spr"
new TeleportSprite, g_exploSpr, BeamSpr_Id, BubbleSprite

enum {
	POWER = 0, // Poder
	SPACE, // Espaco (Trisserakit)
	REALITY, // Realidade
	SOUL, // Alma
	MIND, // Mente
	TIME, // Tempo
	ALL, // Todas ao mesmo tempo huehuehue
	MAX_GEMS
}

new g_used_skill[33], g_current_infgem[33], allow_use_all, g_using_skill[33], is_sttoped, g_msgScreenFade, Thunder
new const gem_string[MAX_GEMS][] = { 
	"POWER_GEM",
	"SPACE_GEM",
	"REALITY_GEM",
	"SOUL_GEM",
	"MIND_GEM",
	"TIME_GEM",
	"ALL_GEMS"
}

new cvar_skill_countdown, cvar_all_gems_time
new cvar_power_knockback, cvar_power_radius, cvar_power_damage
new cvar_soul_radius, cvar_soul_speed, cvar_soul_duration
new cvar_time_duration, cvar_reality_duration, cvar_mind_duration

// Enable Ambience?
#define AMBIENCE_ENABLE 0

// Tasks
#define TASK_AMB 3256
#define TASK_ENABLE_SKILL 12301902
#define TASK_END_SKILL 210301
#define TASK_SKILL_LOOP 123123
#define TASK_ALL_GEMS 2131231
#define TASK_BOT 1231252

public plugin_init()
{
	// Plugin registeration.
	register_plugin("[ZPSp] Special Class: Thanos","1.0", "[P]erfec[T] [S]cr[@]s[H]")
	register_dictionary("zpsp_thanos.txt")
	
	// Gamemode cvars
	cvar_minplayers = register_cvar("zp_minplayers_thanos", "2")
	cvar_damage = register_cvar("zp_damage_thanos", "300")

	// Thanos Cvars
	cvar_skill_countdown = register_cvar("zp_thanos_skill_countdown", "5")
	cvar_all_gems_time = register_cvar("zp_thanos_all_gems_time_allow", "120")

	// Power Gem Cvars
	cvar_power_damage = register_cvar("zp_thanos_power_damage", "10000")
	cvar_power_radius = register_cvar("zp_thanos_power_radius", "300")
	cvar_power_knockback = register_cvar("zp_thanos_power_knockback", "2000")

	// Soul Gem Cvars
	cvar_soul_speed = register_cvar("zp_thanos_soul_speed", "600")
	cvar_soul_radius = register_cvar("zp_thanos_soul_radius", "500")
	cvar_soul_duration = register_cvar("zp_thanos_soul_duration", "5")

	// Reality/Mind/Time Gem
	cvar_time_duration = register_cvar("zp_thanos_time_duration", "10")
	cvar_reality_duration = register_cvar("zp_thanos_reality_duration", "10")
	cvar_mind_duration = register_cvar("zp_thanos_mind_duration", "10")

	cvar_frost_dur = get_cvar_pointer("zp_frost_dur")

	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_KilledPost", 1)

	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if(WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)

	register_forward(FM_PlayerPreThink, "fm_PlayerPreThink")
	g_msgScreenFade = get_user_msgid("ScreenFade")
	
	g_msg_sync = CreateHudSyncObj()
	g_maxplayers = get_maxplayers()

	//register_clcmd("say /thanos", "set_next_thanos")
}

/*public set_next_thanos(id)
{
	if(get_user_flags(id) & ADMIN_ADMIN)
		zp_set_next_game_mode(g_gameid)
}*/

// Game modes MUST be registered in plugin precache ONLY
public plugin_precache()
{
	g_exploSpr = precache_model(sprite_ring)
	precache_sound("debris/beamstart7.wav")
	BubbleSprite = precache_model("sprites/bm1.spr");
	TeleportSprite = precache_model("sprites/b-tele1.spr");
	BeamSpr_Id = precache_model("sprites/laserbeam.spr")
	Thunder = precache_model("sprites/lgtning.spr");
	precache_sound(snap_sound)
	precache_sound(use_stone)
	//g_sprWhite = precache_model("sprites/white.spr");

	// Read the access flag
	static user_access[40], i, buffer[250]
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE THANOS", user_access, charsmax(user_access))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "START MODE THANOS", "a")
		formatex(user_access, charsmax(user_access), "a")
	}
	acess_flags[0] = read_flags(user_access)
	
	if(!amx_load_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "MAKE THANOS", user_access, charsmax(user_access))) {
		amx_save_setting_string(ZP_CUSTOMIZATION_FILE, "Access Flags", "MAKE THANOS", "a")
		formatex(user_access, charsmax(user_access), "a")
	}
	acess_flags[1] = read_flags(user_access)
	
	g_sound = ArrayCreate(64, 1)
	g_sound_ambience = ArrayCreate(64, 1)
	g_sound_amb_dur = ArrayCreate(64, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND THANOS", g_sound)
	
	// Precache the play sounds
	if (ArraySize(g_sound) == 0) {
		for (i = 0; i < sizeof sound; i++)
			ArrayPushString(g_sound, sound[i])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Sounds", "ROUND THANOS", g_sound)
	}
	
	// Precache sounds
	for (i = 0; i < ArraySize(g_sound); i++) {
		ArrayGetString(g_sound, i, buffer, charsmax(buffer))
		precache_ambience(buffer)
	}
	
	// Ambience Sounds
	g_ambience_sounds = AMBIENCE_ENABLE
	if(!amx_load_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "THANOS ENABLE", g_ambience_sounds))
		amx_save_setting_int(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "THANOS ENABLE", g_ambience_sounds)
	
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "THANOS SOUNDS", g_sound_ambience)
	amx_load_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "THANOS DURATIONS", g_sound_amb_dur)
	
	
	// Save to external file
	if (ArraySize(g_sound_ambience) == 0) {
		for (i = 0; i < sizeof ambience_sound; i++)
			ArrayPushString(g_sound_ambience, ambience_sound[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "THANOS SOUNDS", g_sound_ambience)
	}
	
	if (ArraySize(g_sound_amb_dur) == 0) {
		for (i = 0; i < sizeof ambience_dur; i++)
			ArrayPushString(g_sound_amb_dur, ambience_dur[i])
		
		amx_save_setting_string_arr(ZP_CUSTOMIZATION_FILE, "Ambience Sounds", "THANOS DURATIONS", g_sound_amb_dur)
	}
	
	// Ambience Sounds
	if (g_ambience_sounds) {
		for (i = 0; i < ArraySize(g_sound_ambience); i++) {
			ArrayGetString(g_sound_ambience, i, buffer, charsmax(buffer))
			precache_ambience(buffer)
		}
	}
	
	// Register Special Class and Game mod
	#if ZPS_INC_VERSION < 44
	g_gameid = zp_register_game_mode(sp_name, acess_flags[0], g_chance, 0, ZP_DM_NONE)
	#else
	g_gameid = zpsp_register_gamemode(sp_name, acess_flags[0], g_chance, 0, ZP_DM_NONE)
	#endif
	g_speciald = zp_register_zombie_special(sp_name, sp_model, sp_knifemodel, sp_painsound, sp_hp, sp_speed, sp_gravity, acess_flags[1], sp_knockback, sp_aura_size, sp_allow_glow, sp_color_r, sp_color_g, sp_color_b)
}

public plugin_natives() {
	// Register Natives
	register_native("zp_get_user_thanos", "native_get_user_thanos", 1)
	register_native("zp_make_user_thanos", "native_make_user_thanos", 1)
	register_native("zp_get_count_thanos", "native_get_count_thanos", 1)
	register_native("zp_is_round_thanos", "native_is_round_thanos", 1)
}

// Attack Damage
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(!is_user_connected(victim) || !is_user_connected(attacker))
		return HAM_IGNORED

	if(zp_get_zombie_special_class(victim) == g_speciald && g_using_skill[victim] == REALITY) {
		fm_strip_user_weapons(attacker)
		fm_give_item(attacker, "weapon_knife")
		//fm_give_item(attacker, "weapon_glock18")

		static BubbleOrigin[3], Float:fOrigin[3]
		Stock_Get_Postion(attacker, 20.0, 0.0, 0.0, fOrigin)

		BubbleOrigin[0] = floatround(fOrigin[0])
		BubbleOrigin[1] = floatround(fOrigin[1])
		BubbleOrigin[2] = floatround(fOrigin[2])
		message_begin(MSG_PVS, SVC_TEMPENTITY, BubbleOrigin)
		write_byte(TE_SPRITE) // TE id
		write_coord(BubbleOrigin[0]) // x
		write_coord(BubbleOrigin[1]) // y
		write_coord(BubbleOrigin[2]) // z
		write_short(BubbleSprite) // sprite
		write_byte(10) // scale
		write_byte(200) // brightness
		message_end()

		g_used_skill[victim] = true
		g_using_skill[victim] = -1
		set_screenfadein(victim, 1, 0, 0, 0, 0)
		zp_reset_user_rendering(victim)
		set_task(get_pcvar_float(cvar_skill_countdown), "enable_skill", victim+TASK_ENABLE_SKILL)
		client_printcolor(attacker, "%L %L", attacker, "THANOS_TAG", attacker, "REALITY_VICTIM")
	}	

	if(inflictor == attacker && zp_get_zombie_special_class(attacker) == g_speciald)
		SetHamParamFloat(4, get_pcvar_float(cvar_damage))
		
	return HAM_IGNORED
}

// Player spawn post
public zp_player_spawn_post(id) {
	// Check for current mode
	if(zp_get_current_mode() == g_gameid)
		zp_disinfect_user(id)
}

public zp_round_started_pre(game)
{
	// Check if it is our game mode
	if(game == g_gameid) {
		// Check for min players
		if(zp_get_alive_players() < get_pcvar_num(cvar_minplayers))
			return ZP_PLUGIN_HANDLED

		// Start our new mode
		start_mode()
	}
	return PLUGIN_CONTINUE
}

public zp_round_started(game, id)
{
	// Check if it is our game mode
	if(game == g_gameid)
	{
		// Play the starting sound
		static szSound[100]
		ArrayGetString(g_sound, random_num(0, ArraySize(g_sound) - 1), szSound, charsmax(szSound))
		#if ZPS_INC_VERSION < 44
		PlaySoundToClients(szSound)
		#else
		zp_play_sound(0, szSound)
		#endif
		
		// Remove ambience task affects
		remove_task(TASK_AMB)
		
		// Set task to start ambience sounds
		set_task(2.0, "start_ambience_sounds", TASK_AMB)

		allow_use_all = false
		remove_task(TASK_ALL_GEMS)
		set_task(get_pcvar_float(cvar_all_gems_time), "allow_all_gems", TASK_ALL_GEMS)
	}
}

public allow_all_gems() {
	allow_use_all = true
	for(new i = 0; i <= g_maxplayers; i++) {
		if(!is_user_alive(i))
			continue;

		if(zp_get_zombie_special_class(i) != g_speciald)
			continue;

		client_printcolor(i, "%L %L", i, "THANOS_TAG", i, "ALLOW_SNAP_FINGERS")
	}
}

public zp_game_mode_selected(gameid, id)
{
	// Check if our game mode was called
	if(gameid == g_gameid)
		start_mode()
	
	// Make the compiler happy again =)
	return PLUGIN_CONTINUE
}

// This function contains the whole code behind this game mode
start_mode()
{
	static id, i, has, name[32]; 
	has = false
	for (i = 1; i <= g_maxplayers; i++) {
		if(zp_get_zombie_special_class(i) == g_speciald) {
			id = i						// Get Thanos Index
			has = true
		}
	}
	if(!has) {
		id = zp_get_random_player()
		zp_make_user_special(id, g_speciald, 1)
	}
	
	get_user_name(id, name, charsmax(name));
	set_hudmessage(sp_color_r, sp_color_g, sp_color_b, -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
	ShowSyncHudMsg(0, g_msg_sync, "%L", LANG_PLAYER, "HUD_TURNED_THANOS", name)
		
	// Turn the remaining players into zombies
	for (id = 1; id <= g_maxplayers; id++) {
		// Not alive
		if(!is_user_alive(id))
			continue;
			
		set_screenfadein(id, 5, sp_color_r, sp_color_g, sp_color_b, 255)
	}
}

public start_ambience_sounds()
{
	if (!g_ambience_sounds)
		return;
	
	// Variables
	static amb_sound[64], sound,  str_dur[20]
	
	// Select our ambience sound
	sound = random_num(0, ArraySize(g_sound_ambience)-1)

	ArrayGetString(g_sound_ambience, sound, amb_sound, charsmax(amb_sound))
	ArrayGetString(g_sound_amb_dur, sound, str_dur, charsmax(str_dur))
	
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
	remove_task(TASK_ALL_GEMS)
	is_sttoped = false
	allow_use_all = false

	for(new i = 0; i <= g_maxplayers; i++) {
		if(!is_user_alive(i))
			continue

		if(zp_get_zombie_special_class(i) != g_speciald)
			continue

		reset_thanos_vars(i)
	}
}

public reset_thanos_vars(i) {
	remove_task(i)
	remove_task(i+TASK_ENABLE_SKILL)
	remove_task(i+TASK_END_SKILL)
	remove_task(i+TASK_SKILL_LOOP)
	g_current_infgem[i] = POWER
	g_used_skill[i] = false
	g_using_skill[i] = -1
}

public zp_user_infected_post(id) {
	reset_thanos_vars(id)
	if(zp_get_zombie_special_class(id) == g_speciald) 
	{
		if(!zp_has_round_started())
			zp_set_custom_game_mod(g_gameid)	// Force Start Thanos Round

		if(is_user_bot(id))
		{
			remove_task(id+TASK_BOT)
			set_task(random_float(5.0, 15.0), "bot_suport", id+TASK_BOT, _, _, "b")
		}

		client_printcolor(id, "%L %L", id, "THANOS_TAG", id, "YOU_ARE_THANOS")
		client_printcolor(id, "%L %L", id, "THANOS_TAG", id, "THANOS_INFO")
	}
}

public zp_user_humanized_post(id) reset_thanos_vars(id)
public fw_KilledPost(id) reset_thanos_vars(id)

#if AMXX_VERSION_NUM >= 183
public client_disconnected(id) reset_thanos_vars(id)
#else
public client_disconnect(id) reset_thanos_vars(id)
#endif

stock client_printcolor(const id, const input[], any:...)
{
	new msg[191], players[32], count = 1; vformat(msg,190,input,3);
	replace_all(msg,190,"!g","^4");    // green
	replace_all(msg,190,"!y","^1");    // normal
	replace_all(msg,190,"!t","^3");    // team
	
	if (id) players[0] = id; else get_players(players,count,"ch");
	
	for (new i=0;i<count;i++)
	{
		if (is_user_connected(players[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("SayText"),_,players[i]);
			write_byte(players[i]);
			write_string(msg);
			message_end();
		}
	}
} 

public native_get_user_thanos(id)
	return (zp_get_zombie_special_class(id) == g_speciald)
	
public native_make_user_thanos(id)
	return (zp_make_user_special(id, g_speciald, GET_ZOMBIE))
	
public native_get_count_thanos()
	return zp_get_special_count(GET_ZOMBIE, g_speciald)
	
public native_is_round_thanos()
	return (zp_get_current_mode() == g_gameid)	

precache_ambience(sound[])
{
	static buffer[150]
	if(equal(sound[strlen(sound)-4], ".mp3")) {
		if(!equal(sound, "sound/", 6) && !file_exists(sound) && !equal(sound, "media/", 6))
			format(buffer, charsmax(buffer), "sound/%s", sound)
		else
			format(buffer, charsmax(buffer), "%s", sound)
		
		precache_generic(buffer)
	}
	else  {
		if(equal(sound, "sound/", 6))
			format(buffer, charsmax(buffer), "%s", sound[6])
		else
			format(buffer, charsmax(buffer), "%s", sound)
		
		
		precache_sound(buffer)
	}
}

#if ZPS_INC_VERSION < 44
// Plays a sound on clients
stock PlaySoundToClients(const sound[])
{
	static buffer[150]

	if(equal(sound[strlen(sound)-4], ".mp3")) {
		if(!equal(sound, "sound/", 6) && !file_exists(sound) && !equal(sound, "media/", 6))
			format(buffer, charsmax(buffer), "sound/%s", sound)
		else
			format(buffer, charsmax(buffer), "%s", sound)
	
		client_cmd(0, "mp3 play ^"%s^"", buffer)

	}
	else {
		if(equal(sound, "sound/", 6))
			format(buffer, charsmax(buffer), "%s", sound[6])
		else
			format(buffer, charsmax(buffer), "%s", sound)
			
		client_cmd(0, "spk ^"%s^"", buffer)
	}
}
#endif

public fm_PlayerPreThink(id)
{
	if(!is_user_alive(id) || zp_has_round_ended())
		return;

	if(!zp_get_user_zombie(id) || zp_get_zombie_special_class(id) != g_speciald)
		return;


	if((fm_get_user_button(id) & IN_RELOAD) && !(fm_get_user_oldbutton(id) & IN_RELOAD) && !task_exists(id))
	{
		if(g_current_infgem[id] >= TIME && !allow_use_all || g_current_infgem[id] >= ALL && allow_use_all)
			g_current_infgem[id] = POWER
		else
			g_current_infgem[id]++

		client_print(id, print_center, "%L", id, gem_string[g_current_infgem[id]])
		client_cmd(id, "spk common/wpn_moveselect.wav")
	}

	else if((fm_get_user_button(id) & IN_USE) && !(fm_get_user_oldbutton(id) & IN_USE))
	{
		if(g_used_skill[id]) {
			client_printcolor(id, "%L %L", id, "THANOS_TAG", id, "INFINITY_GEM_WAIT")
			return;
		}

		progress_bar(id, 2)
		set_task(2.0, "set_skill", id)

		if(g_current_infgem[id] != ALL) 
			emit_sound(id, CHAN_WEAPON, use_stone, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
		if(g_current_infgem[id] == MIND)
			Set_Weapon_Anim(id, 10)
		else
			Set_Weapon_Anim(id, 8)

		set_attack_block(id, 0.9)

		//use_inf_gem(id, g_current_infgem[id])
	}
	else if(!(fm_get_user_button(id) & IN_USE) && (fm_get_user_oldbutton(id) & IN_USE) && !g_used_skill[id])
	{
		Set_Weapon_Anim(id, 3)
		progress_bar(id, 0)
		emit_sound(id, CHAN_WEAPON, use_stone, VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)
		remove_task(id)
	}

}

public set_skill(id) {
	use_inf_gem(id, g_current_infgem[id])
}

public bot_suport(id)
{ 
	id -= TASK_BOT

	if(!is_user_alive(id) || zp_has_round_ended()) {
		remove_task(id+TASK_BOT)
		return;
	}

	if(!is_user_bot(id) || zp_get_zombie_special_class(id) != g_speciald) {
		remove_task(id+TASK_BOT)
		return;
	}

	if(g_used_skill[id] || g_using_skill[id] != -1)
		return;

	g_current_infgem[id] = random_num(POWER, allow_use_all ? ALL : TIME)

	if(g_current_infgem[id] != ALL) 
		emit_sound(id, CHAN_WEAPON, use_stone, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

	set_task(2.0, "set_skill", id)
	if(g_current_infgem[id] == MIND)
		Set_Weapon_Anim(id, 10)
	else
		Set_Weapon_Anim(id, 8)

	set_attack_block(id, 0.9)
}

public use_inf_gem(id, gem)
{
	if(!is_user_alive(id) || zp_has_round_ended())
		return;

	if(!zp_get_user_zombie(id) || zp_get_zombie_special_class(id) != g_speciald || g_using_skill[id] != -1)
		return;

	if(g_used_skill[id]) {
		client_printcolor(id, "%L %L", id, "THANOS_TAG", id, "INFINITY_GEM_WAIT")
		return;
	}

	static Float:def_cvar, name[32]; 
	def_cvar = get_pcvar_float(cvar_frost_dur)
	get_user_name(id, name, charsmax(name))

	// Anti-Bug
	if(gem == ALL && !allow_use_all) {
		gem = POWER
		g_current_infgem[id] = POWER
	}

	switch(gem)
	{
		case POWER: {
			static Float:OriginF[3]
			pev(id, pev_origin, OriginF)
			thunder_effect(id)

			set_screenfadein(id, 1, 255, 0, 255, 150)

			// Custom explosion effect
			create_blast(OriginF, get_pcvar_num(cvar_power_radius), 255, 0, 255)
			for(new i = 0; i <= g_maxplayers; i++) {
				if(!is_user_alive(i) || i == id)
					continue

				if(zp_get_user_zombie(i) || entity_range(id, i) > get_pcvar_num(cvar_power_radius))
					continue;

				thunder_effect(i)
				#if ZPS_INC_VERSION < 44
				zp_set_extra_damage(i, id, get_pcvar_num(cvar_power_damage), "Thanos: Power Gem")
				#else
				zp_set_user_extra_damage(i, id, get_pcvar_num(cvar_power_damage), "Thanos: Power Gem")
				#endif

				if(get_pcvar_num(cvar_power_knockback))
					set_knockback(id, i, get_pcvar_num(cvar_power_knockback))
			}
		}
		case SPACE: {
			set_screenfadein(id, 1, 0, 100, 255, 150)
			static UserOrigin[3], NewLocation[3];
			get_user_origin(id, UserOrigin);

			// Get location where player is aiming(where he will be teleported)
			get_user_origin(id, NewLocation, 3);
			
			// Create bubbles in a place where player teleported			
			new BubbleOrigin[3], Float:Orig[3];
			BubbleOrigin[0] = UserOrigin[0];
			BubbleOrigin[1] = UserOrigin[1];
			BubbleOrigin[2] = UserOrigin[2] + 40;

			message_begin(MSG_PVS, SVC_TEMPENTITY, BubbleOrigin)
			write_byte(TE_SPRITE) // TE id
			write_coord(BubbleOrigin[0]) // x
			write_coord(BubbleOrigin[1]) // y
			write_coord(BubbleOrigin[2]+10) // z
			write_short(TeleportSprite) // sprite
			write_byte(10) // scale
			write_byte(255) // brightness
			message_end()

			// Play needed sound
			emit_sound(id, CHAN_STATIC, "debris/beamstart7.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

			IVecFVec(NewLocation, Orig)
			// Player cannot stuck in the wall/floor
			if(!is_hull_vacant(Orig)) {
				if ( engfunc(EngFunc_PointContents, Orig) == CONTENTS_SKY )
					Orig[2] -= 60.0;
				else
					Orig[2] += 40.0;
			}

			if(!is_hull_vacant(Orig))
				Orig[0] += ((Orig[0] - UserOrigin[0] > 0) ? -50.0 : 50.0);

			if(!is_hull_vacant(Orig))
				Orig[1] += ((Orig[1] - UserOrigin[1] > 0) ? -50.0 : 50.0);

			FVecIVec(Orig, NewLocation)

			message_begin(MSG_PVS, SVC_TEMPENTITY, NewLocation)
			write_byte(TE_SPRITE) // TE id
			write_coord(NewLocation[0]) // x
			write_coord(NewLocation[1]) // y
			write_coord(NewLocation[2]+10) // z
			write_short(TeleportSprite) // sprite
			write_byte(10) // scale
			write_byte(255) // brightness
			message_end()
			
			// Teleport player
			fm_set_user_origin(id, NewLocation);
			set_task(1.0, "check_stuck", id+TASK_END_SKILL)
			//fm_set_user_origin(index, origin[3])
			//set_pev(id, pev_origin, NewLocation)
		}
		case REALITY: {
			g_using_skill[id] = REALITY
			g_used_skill[id] = true
			zp_set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 255)
			set_screenfadein(id, get_pcvar_num(cvar_reality_duration), 255, 0, 0, 50)
			set_task(get_pcvar_float(cvar_reality_duration), "end_skill", id+TASK_END_SKILL)
			return;
		}
		case SOUL: {
			set_pcvar_float(cvar_frost_dur, 999999.0)

			zp_set_user_frozen(id, 2)
			//zp_set_user_maxspeed(id, 1.0)
			zp_set_user_rendering(id, kRenderFxGlowShell, 255, 69, 0, kRenderNormal, 255)
			
			message_begin(MSG_ONE, g_msgScreenFade, _, id)
			write_short(0) // duration
			write_short(0) // hold time
			write_short(FFADE_STAYOUT) // fade type
			write_byte(255) // red
			write_byte(69) // green
			write_byte(0) // blue
			write_byte(80) // alpha
			message_end()

			g_using_skill[id] = SOUL
			g_used_skill[id] = true
			set_attack_block(id, get_pcvar_float(cvar_soul_duration))
			remove_task(id+TASK_SKILL_LOOP)
			remove_task(id+TASK_END_SKILL)
			set_task(0.1, "Soul_Gem_Absorb", id+TASK_SKILL_LOOP, _, _, "b")
			set_task(1.0, "Soul_Gem_Effect", id+TASK_SKILL_LOOP, _, _, "b")
			set_task(get_pcvar_float(cvar_soul_duration), "end_soul_skill", id+TASK_END_SKILL)
			Set_Weapon_Anim(id, 9)
			client_printcolor(0, "%L %L", LANG_PLAYER, "THANOS_TAG", LANG_PLAYER, "SOUL_GEM_SKILL", name)
			set_pcvar_float(cvar_frost_dur, def_cvar)
			return;
		}
		case MIND: {
			set_attack_block(id, get_pcvar_float(cvar_mind_duration))
			Set_Weapon_Anim(id, 11)
			g_using_skill[id] = MIND
			g_used_skill[id] = true
			set_task(0.1, "Mind_Gem_Skill", id+TASK_SKILL_LOOP, _, _, "b")
			set_task(get_pcvar_float(cvar_mind_duration), "end_skill", id+TASK_END_SKILL)
			zp_set_user_rendering(id, kRenderFxGlowShell, 255, 255, 0, kRenderNormal, 255)
			return;
			
		}

		case TIME: {
			if(is_sttoped) {
				client_printcolor(id, "%L %L", id, "THANOS_TAG", id, "TIME_ALTERADY_STOPPED")
				return;
			}

			g_using_skill[id] = TIME
			g_used_skill[id] = true
			is_sttoped = true
			
			for(new i = 0; i <= g_maxplayers; i++)
			{
				if(!is_user_alive(i) || i == id)
					continue;

				if(zp_get_zombie_special_class(i) == g_speciald)
					continue;
				
				set_pcvar_float(cvar_frost_dur, 99999.0)
				zp_set_user_frozen(i, 2)
				set_pcvar_float(cvar_frost_dur, def_cvar)
				zp_set_user_rendering(i, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 255)

				set_attack_block(i, get_pcvar_float(cvar_time_duration))
			}
			
			client_printcolor(0, "%L %L", LANG_PLAYER, "THANOS_TAG", LANG_PLAYER, "STOPPED_TIME", name)
			set_screenfadein(0, get_pcvar_num(cvar_time_duration), 0, 255, 0, 100)
			remove_task(id+TASK_END_SKILL)
			set_task(get_pcvar_float(cvar_time_duration), "end_time_gem_skill", id+TASK_END_SKILL)
			Set_Weapon_Anim(id, 9)
			return;
		}
		case ALL: {
			if(!allow_use_all)
				return;

			allow_use_all = false
			remove_task(id+TASK_END_SKILL)
			g_used_skill[id] = true
			g_using_skill[id] = ALL
			client_cmd(0, "spk %s", snap_sound)
			set_task(4.0, "snap_fingers", id+TASK_END_SKILL)			
			return;
		}
	}
	g_used_skill[id] = true
	remove_task(id+TASK_ENABLE_SKILL)
	set_task(get_pcvar_float(cvar_skill_countdown), "enable_skill", id+TASK_ENABLE_SKILL)
}
public snap_fingers(id) {
	id -= TASK_END_SKILL
	if(!is_user_alive(id) || zp_has_round_ended())
		return;

	if(!zp_get_user_zombie(id) || zp_get_zombie_special_class(id) != g_speciald)
		return;

	static name[32]; 
	get_user_name(id, name, charsmax(name))

	set_screenfadein(0, 3, 255, 255, 255, 255)
	set_task(3.0, "kill_half_humans", id+TASK_END_SKILL)
	client_printcolor(0, "%L %L", LANG_PLAYER, "THANOS_TAG", LANG_PLAYER, "SNAP_FINGERS", name)
}

public check_stuck(id) {
	id -= TASK_END_SKILL

	if(!is_user_alive(id))
		return;

	if(zp_is_user_stuck(id)) {
		zp_do_random_spawn(id)
		client_printcolor(id, "%L %L", id, "THANOS_TAG", id, "THANOS_AUTO_UNSTUCK")
	}
}

public Soul_Gem_Absorb(id) {
	if(zp_has_round_ended()) {
		remove_task(id)
		return;
	}

	id -= TASK_SKILL_LOOP
	static Float:UserOrigin[3]
	pev(id, pev_origin, UserOrigin)
	//set_pev(id, pev_velocity, Float:{0.0,0.0,0.0})

	for(new i = 0; i <= g_maxplayers; i++)
	{
		if(!is_user_alive(i))
			continue

		if(zp_get_user_zombie(i))
			continue;
		
		static Float:Origin[3]
		pev(i, pev_origin, Origin)
		//get_user_origin(i, Origin)
		
		if(get_distance_f(Origin, UserOrigin) <= 150.0 && !zp_get_user_zombie(i)) {
			ExecuteHamB(Ham_Killed, i, id, 0)
			client_printcolor(i, "%L %L", i, "THANOS_TAG", i, "ABSORBEB_BY_SOUL_GEM")
			continue
		}
		
		if(get_distance_f(Origin, UserOrigin) > get_pcvar_float(cvar_soul_radius))
			continue

		hook_ent2(i, UserOrigin, get_pcvar_float(cvar_soul_speed))
	}
}
public Soul_Gem_Effect(id) {
	id -= TASK_SKILL_LOOP
	if(!is_user_alive(id))
		return

	static Float:UserOrigin[3]
	pev(id, pev_origin, UserOrigin)
	create_blast(UserOrigin, 400, 255, 69, 0)

}
public end_soul_skill(id) {
	id -= TASK_END_SKILL

	remove_task(id+TASK_SKILL_LOOP)
	remove_task(id+TASK_ENABLE_SKILL)
	if(is_user_alive(id)) {
		zp_set_user_frozen(id, UNSET)
		set_attack_block(id, 0.0)
		g_using_skill[id] = -1
		set_task(get_pcvar_float(cvar_skill_countdown), "enable_skill", id+TASK_ENABLE_SKILL)
		Set_Weapon_Anim(id, 0)
		//zp_reset_user_maxspeed(id)
	}
}
public end_skill(id)
{
	id -= TASK_END_SKILL

	if(!is_user_alive(id))
		return

	if(zp_get_zombie_special_class(id) != g_speciald)
		return;

	remove_task(id+TASK_ENABLE_SKILL)
	remove_task(id+TASK_SKILL_LOOP)
	g_using_skill[id] = -1
	set_task(get_pcvar_float(cvar_skill_countdown), "enable_skill", id+TASK_ENABLE_SKILL)
	zp_reset_user_rendering(id)
	Set_Weapon_Anim(id, 0)
	set_screenfadein(id, 1, 0, 0, 0, 0)
}
public end_time_gem_skill(id) {
	id -= TASK_END_SKILL
	for(new i = 0; i <= g_maxplayers; i++)
	{
		if(!is_user_alive(i))
			continue;

		zp_set_user_frozen(i, UNSET)
		set_attack_block(i, 0.0)
	}

	g_used_skill[id] = true
	is_sttoped = false
	g_using_skill[id] = -1
	remove_task(id+TASK_ENABLE_SKILL)
	set_task(get_pcvar_float(cvar_skill_countdown), "enable_skill", id+TASK_ENABLE_SKILL)
	client_printcolor(0, "%L %L", LANG_PLAYER, "THANOS_TAG", LANG_PLAYER, "TIME_RETURN_WORKS")
	Set_Weapon_Anim(id, 0)
}
public enable_skill(id) {
	id -= TASK_ENABLE_SKILL

	if(!is_user_alive(id))
		return;

	if(!zp_get_user_zombie(id) || zp_get_zombie_special_class(id) != g_speciald)
		return;

	g_used_skill[id] = false
	client_printcolor(id, "%L %L", id, "THANOS_TAG", id, "ALLOW_USE_GEM")
}

create_blast(const Float:originF[3], radius, r, g, b)
{
	new radius_shockwave, size
	radius_shockwave = radius
	while(radius_shockwave >= 60) {
		radius_shockwave -= 60
		size++
	}
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+385.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(size) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(r) // red
	write_byte(g) // green
	write_byte(b) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Medium ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+470.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(size) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(r) // red
	write_byte(g) // green
	write_byte(b) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+555.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(size) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(r) // red
	write_byte(g) // green
	write_byte(b) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
}

set_knockback(id, victim, power)
{
	static Float:vec[3], Float:oldvelo[3];
	get_user_velocity(victim, oldvelo);
	create_velocity_vector(victim , id , vec, power);
	vec[0] += oldvelo[0];
	vec[1] += oldvelo[1];
	set_user_velocity(victim , vec);
}
// Knockback 
stock create_velocity_vector(victim,attacker,Float:velocity[3], power)
{
	if(victim > 0 && victim < 33)
	{
		if(!is_user_alive(attacker))
		return 0;
		
		new Float:vicorigin[3];
		new Float:attorigin[3];
		entity_get_vector(victim, EV_VEC_origin, vicorigin);
		entity_get_vector(attacker, EV_VEC_origin, attorigin);
		
		new Float:origin2[3]
		origin2[0] = vicorigin[0] - attorigin[0];
		origin2[1] = vicorigin[1] - attorigin[1];
		
		new Float:largestnum = 0.0;
		
		if(floatabs(origin2[0])>largestnum) largestnum = floatabs(origin2[0]);
		if(floatabs(origin2[1])>largestnum) largestnum = floatabs(origin2[1]);
		
		origin2[0] /= largestnum;
		origin2[1] /= largestnum;
		
		new a = power
	
		velocity[0] =(origin2[0] * (100 *a)) / get_entity_distance(victim , attacker);
		velocity[1] =(origin2[1] * (100 *a)) / get_entity_distance(victim , attacker);
		if(velocity[0] <= 20.0 || velocity[1] <= 20.0)
		velocity[2] = random_float(200.0 , 275.0);
	}
	return 1;
}
set_attack_block(id, Float:time) {
	if(!is_user_alive(id))
		return;

	if(pev_valid(id) == 2)
		set_pdata_float(id, OFFSET_NEXTATTACK, time, OFFSET_LINUX)
}
public fw_Item_Deploy_Post(weapon_ent)
{
	if(!pev_valid(weapon_ent))
		return
	
	// Get weapon's owner
	static owner
	owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	
	// Invalid player id? (bugfix)
	if (!(1 <= owner <= g_maxplayers)) return;	

	if(!is_user_alive(owner))
		return;

	if(is_sttoped && zp_get_zombie_special_class(owner) != g_speciald)
		set_attack_block(owner, 10.0)
}	

stock fm_cs_get_weapon_ent_owner(ent) {
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != 2)
		return -1;
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}

stock hook_ent2(ent, Float:VicOrigin[3], Float:speed)
{
	if(!pev_valid(ent))
		return
	
	static Float:fl_Velocity[3], Float:EntOrigin[3], Float:distance_f, Float:fl_Time
	
	pev(ent, pev_origin, EntOrigin)
	
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	fl_Time = distance_f / speed
		
	fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
	fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
	fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time

	set_pev(ent, pev_velocity, fl_Velocity)
}

stock set_screenfadein(id, fadetime, r, g, b, alpha) {
	new players[32], count = 1
	if(id) players[0] = id; else get_players(players,count,"ch");
    
	for (new i=0;i<count;i++) {
		if(is_user_connected(players[i])) {
			message_begin(MSG_ONE, g_msgScreenFade, _, players[i])
			write_short(UNIT_SECOND*fadetime) // duration
			write_short(0) // hold time
			write_short(FFADE_IN) // fade type
			write_byte(r) // red
			write_byte(g) // green
			write_byte(b) // blue
			write_byte(alpha) // alpha
			message_end()
		}
	}
}

public Mind_Gem_Skill(id)
{
	id -= TASK_SKILL_LOOP

	if(!is_user_alive(id))
		return;

	if(!zp_get_user_zombie(id) || zp_get_zombie_special_class(id) != g_speciald)
		return;
		
	static Float:vEnd[3], Float:vOrigin[3]

	//get_user_eye_position(id, vOrigin)
	Stock_Get_Postion(id, 20.0, 0.0, -6.0, vOrigin)
	Stock_Get_Postion(id, 4096.0, 0.0, 0.0, vEnd)

	static iHit, Float:fFraction, Trace_Result;
	engfunc(EngFunc_TraceLine, vOrigin, vEnd, DONT_IGNORE_MONSTERS, id, Trace_Result);

	get_weapon_attachment(id, vEnd)
	get_tr2(Trace_Result, TR_vecEndPos, vEnd)
	
	get_tr2(0, TR_flFraction, fFraction);
	iHit = get_tr2(0, TR_pHit);

	// Do caso de um idiota passar no meio da linha
	if(fFraction < 1.0 && is_user_alive(iHit)) {
		get_tr2(Trace_Result, TR_vecEndPos, vEnd)

		#if ZPS_INC_VERSION < 44
		if(!zp_get_user_zombie(iHit)) zp_set_extra_damage(iHit, id, random_num(30, 100), "Thanos: Mind Gem")
		#else
		if(!zp_get_user_zombie(iHit)) zp_set_user_extra_damage(iHit, id, random_num(30, 100), "Thanos: Mind Gem", 1)
		#endif
	}

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMPOINTS);
	engfunc(EngFunc_WriteCoord,vOrigin[0]);
	engfunc(EngFunc_WriteCoord,vOrigin[1]);
	engfunc(EngFunc_WriteCoord,vOrigin[2]);
	engfunc(EngFunc_WriteCoord,vEnd[0]); //Random
	engfunc(EngFunc_WriteCoord,vEnd[1]); //Random
	engfunc(EngFunc_WriteCoord,vEnd[2]); //Random
	write_short(BeamSpr_Id);
	write_byte(0);
	write_byte(0);
	write_byte(2); //Life
	write_byte(10); //Width
	write_byte(0); //wave
	write_byte(255); // r
	write_byte(255); // g
	write_byte(0); // b
	write_byte(255);
	write_byte(100);
	message_end();


}
stock Set_Weapon_Anim(id, WeaponAnim)
{
	if(!is_user_alive(id))
		return

	set_pev(id, pev_weaponanim, WeaponAnim)

	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(WeaponAnim)
	write_byte(pev(id, pev_body))
	message_end()
}
public progress_bar(id, duration) {
	if(!is_user_connected(id))
		return 

	message_begin(MSG_ONE, get_user_msgid("BarTime"), _, id)
	write_short(duration)
	message_end()
}
stock Stock_Get_Postion(id,Float:forw,Float:right, Float:up,Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
} 
stock get_weapon_attachment(id, Float:output[3], Float:fDis = 40.0)
{ 
	static Float:vfEnd[3], viEnd[3] 
	get_user_origin(id, viEnd, 3)  
	IVecFVec(viEnd, vfEnd) 
	
	static Float:fOrigin[3], Float:fAngle[3]
	
	pev(id, pev_origin, fOrigin) 
	pev(id, pev_view_ofs, fAngle)
	
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	
	static Float:fAttack[3]
	
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	
	static Float:fRate
	
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	
	xs_vec_add(fOrigin, fAttack, output)
}
public kill_half_humans(id) {
	id -= TASK_END_SKILL

	if(!is_user_alive(id) || zp_has_round_ended())
		return;

	if(zp_get_zombie_special_class(id) != g_speciald)
		return;

	static kill_count, max_kills, i
	kill_count = 0
	i = 0
	max_kills = 0

	if(zp_get_human_count() > 1) {
		max_kills = zp_get_human_count() / 2

		while (kill_count < max_kills)
		{
			// Keep looping through all players
			if ((++i) > g_maxplayers) i = 1
			
			// Dead
			if (!is_user_alive(i))
				continue;

			if(zp_get_user_zombie(i))
				continue;
			
			// Random chance
			if (random_num(1, 5) == 1) {
				beam_effect(i)
				ExecuteHamB(Ham_Killed, i, id, 0)
				client_printcolor(i, "%L %L", i, "THANOS_TAG", i, "SNAP_CHOOSED")
				
				// Increase counter
				kill_count++
			}
		}
	}
	else  {
		for(i = 0; i <= g_maxplayers; i++) {
			if(!is_user_alive(i))
				continue;

			if(!zp_get_user_zombie(i)) {
				beam_effect(i)
				ExecuteHamB(Ham_Killed, i, id, 0)
				client_printcolor(i, "%L %L", i, "THANOS_TAG", i, "SNAP_CHOOSED")
			}
		}
	}
	g_current_infgem[id] = POWER
	g_using_skill[id] = -1
	remove_task(id+TASK_ENABLE_SKILL)
	set_task(get_pcvar_float(cvar_skill_countdown), "enable_skill", id+TASK_ENABLE_SKILL)
}
stock is_hull_vacant(Float:origin[3]) {
	engfunc(EngFunc_TraceHull, origin, origin, 0, HULL_HEAD, 0, 0)
	
	if(!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

stock thunder_effect(id) {
	if(!is_user_alive(id))
		return;

	static srco[3], vorigin[3];
	get_user_origin(id, vorigin);
	vorigin[2] -= 26
	srco[0] = vorigin[0] + 150
	srco[1] = vorigin[1] + 150
	srco[2] = vorigin[2] + 800
	
	thunder_effect2(srco,vorigin);
	thunder_effect2(srco,vorigin);
	thunder_effect2(srco,vorigin);
}

stock thunder_effect2(vec1[3],vec2[3]) {
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(0); 
	write_coord(vec1[0]); 
	write_coord(vec1[1]); 
	write_coord(vec1[2]); 
	write_coord(vec2[0]); 
	write_coord(vec2[1]); 
	write_coord(vec2[2]); 
	write_short(Thunder); 
	write_byte(1);
	write_byte(5);
	write_byte(2);
	write_byte(20);
	write_byte(30);
	write_byte(200); 
	write_byte(0);
	write_byte(100);
	write_byte(200);
	write_byte(200);
	message_end();
	
	message_begin( MSG_PVS, SVC_TEMPENTITY,vec2); 
	write_byte(9); 
	write_coord(vec2[0]); 
	write_coord(vec2[1]); 
	write_coord(vec2[2]); 
	message_end();
}

stock beam_effect(id) {
	if(!is_user_alive(id))
		return;

	static Float:fl_Origin[3], iOrigin[3]
	pev(id, pev_origin, fl_Origin)
	set_entity_visibility(id, 0)

	FVecIVec(fl_Origin, iOrigin)

	// Particle effect
	for(new i = 0; i <= 3; i++) {
		message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
		write_byte(TE_IMPLOSION);
		write_coord(iOrigin[0]);
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2]+20);
		write_byte(200)	// radius
		write_byte(40)		// count
		write_byte(45)		// life in 0.1's
		message_end()

		message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
		write_byte(TE_IMPLOSION);
		write_coord(iOrigin[0]);
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2]+10);
		write_byte(200)	// radius
		write_byte(40)		// count
		write_byte(45)		// life in 0.1's
		message_end()

		message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
		write_byte(TE_IMPLOSION);
		write_coord(iOrigin[0]);
		write_coord(iOrigin[1]);
		write_coord(iOrigin[2]-5);
		write_byte(200)	// radius
		write_byte(40)		// count
		write_byte(45)		// life in 0.1's
		message_end()
	}
}

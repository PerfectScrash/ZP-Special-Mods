#if defined _zpsp_sonic_shadow_included
  #endinput
#endif
#define _zpsp_sonic_shadow_included

#if !defined _zombie_special_new_included
#include <zombie_plague_special>
#endif

/**
 * Returns whether a player is a shadow.
 *
 * @param id	Player index.
 * @return		True if it is, false otherwise.
 */
native zp_get_user_shadow(id);

/**
 * Forces a player to become a shadow.
 *
 * @note Unavailable for last default/special human
 *
 * @param id	Player index to turn into shadow.
 * @return		True on success, false otherwise.
 */
native zp_make_user_shadow(id);

/**
 * Returns number of alive shadow.
 *
 * @return		shadow count.
 */
native zp_get_shadow_count();

/**
 * Returns whether the current round is a shadow round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_shadow_round();

/**
 * Returns if Sonic Special Class are enable
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_shadow_enable();

/**
 * Returns whether a player is a sonic.
 *
 * @param id	Player index.
 * @return		True if it is, false otherwise.
 */
native zp_get_user_sonic(id);

/**
 * Forces a player to become a sonic.
 *
 * @note Unavailable for last default/special zombie
 *
 * @param id	Player index to turn into sonic.
 * @return		True on success, false otherwise.
 */
native zp_make_user_sonic(id);

/**
 * Returns number of alive sonic.
 *
 * @return		sonic count.
 */
native zp_get_sonic_count();

/**
 * Returns whether the current round is a sonic round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_sonic_round();

/**
 * Returns if Sonic Special Class are enable
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_sonic_enable();

/**
 * Returns whether the current round is a sonic vs shadow round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_sonic_vs_shadow();

/**
 * Returns if Gamemode Sonic vs Shadow are enable
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_sonic_vs_shadow_enable();

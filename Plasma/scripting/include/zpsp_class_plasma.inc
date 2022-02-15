#if defined _zpsp_plasma_included
  #endinput
#endif
#define _zpsp_plasma_included

#if !defined _zombie_special_new_included
#include <zombie_plague_special>
#endif

/**
 * Returns whether a player is a plasma.
 *
 * @param id	Player index.
 * @return		True if it is, false otherwise.
 */
native zp_get_user_plasma(id);

/**
 * Forces a player to become a plasma.
 *
 * @note Unavailable for last default/special human
 *
 * @param id	Player index to turn into plasma.
 * @return		True on success, false otherwise.
 */
native zp_make_user_plasma(id);

/**
 * Returns number of alive plasma.
 *
 * @return		plasma count.
 */
native zp_get_plasma_count();

/**
 * Returns whether the current round is a plasma round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_plasma_round();
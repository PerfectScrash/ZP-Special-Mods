#if defined _zpsp_chuck_norris_included
  #endinput
#endif
#define _zpsp_chuck_norris_included

#if !defined _zombie_special_new_included
#include <zombie_plague_special>
#endif


/**
 * Returns whether a player is a chuck norris.
 *
 * @param id	Player index.
 * @return		True if it is, false otherwise.
 */
native zp_get_user_chuck_norris(id);

/**
 * Forces a player to become a chuck norris.
 *
 * @note Unavailable for last default/special zombie
 *
 * @param id	Player index to turn into chuck norris.
 * @return		True on success, false otherwise.
 */
native zp_make_user_chuck_norris(id);

/**
 * Returns number of alive chuck norris.
 *
 * @return		chuck norris count.
 */
native zp_get_chuck_norris_count();

/**
 * Returns whether the current round is a chuck norris round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_chuck_norris_round();
#if defined _zpsp_class_xiter_included
  #endinput
#endif
#define _zpsp_class_xiter_included

#if !defined _zombie_special_new_included
#include <zombie_plague_special>
#endif


/**
 * Returns whether a player is a xiter.
 *
 * @param id	Player index.
 * @return		True if it is, false otherwise.
 */
native zp_get_user_xiter(id);

/**
 * Forces a player to become a xiter.
 *
 * @note Unavailable for last default/special zombie
 *
 * @param id	Player index to turn into xiter.
 * @return		True on success, false otherwise.
 */
native zp_make_user_xiter(id);

/**
 * Returns number of alive xiter.
 *
 * @return		xiter count.
 */
native zp_get_xiter_count();

/**
 * Returns whether the current round is a xiter round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_xiter_round();

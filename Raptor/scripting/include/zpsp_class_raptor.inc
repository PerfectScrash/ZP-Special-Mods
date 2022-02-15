#if defined _zpsp_raptor_included
  #endinput
#endif
#define _zpsp_raptor_included

#if !defined _zombie_special_new_included
#include <zombie_plague_special>
#endif


/**
 * Returns whether a player is a raptor.
 *
 * @param id	Player index.
 * @return		True if it is, false otherwise.
 */
native zp_get_user_raptor(id);

/**
 * Forces a player to become a raptor.
 *
 * @note Unavailable for last default/special human
 *
 * @param id	Player index to turn into raptor.
 * @return		True on success, false otherwise.
 */
native zp_make_user_raptor(id);

/**
 * Returns number of alive raptor.
 *
 * @return		raptor count.
 */
native zp_get_raptor_count();

/**
 * Returns whether the current round is a raptor round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_raptor_round();

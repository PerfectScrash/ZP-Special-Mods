#if defined _zpsp_thanos_included
  #endinput
#endif
#define _zpsp_thanos_included

#if !defined _zombie_special_new_included
#include <zombie_plague_special>
#endif


/**
 * Returns whether a player is a thanos.
 *
 * @param id	Player index.
 * @return		True if it is, false otherwise.
 */
native zp_get_user_thanos(id);

/**
 * Forces a player to become a thanos.
 *
 * @note Unavailable for last default/special human
 *
 * @param id	Player index to turn into thanos.
 * @return		True on success, false otherwise.
 */
native zp_make_user_thanos(id);

/**
 * Returns number of alive thanos.
 *
 * @return		thanos count.
 */
native zp_get_thanos_count();

/**
 * Returns whether the current round is a thanos round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_thanos_round();

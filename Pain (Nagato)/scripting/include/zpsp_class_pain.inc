#if defined _zpsp_class_pain_included
  #endinput
#endif
#define _zpsp_class_pain_included

#if !defined _zombie_special_new_included
#include <zombie_plague_special>
#endif

/**
 * Returns whether a player is a pain.
 *
 * @param id	Player index.
 * @return		True if it is, false otherwise.
 */
native zp_get_user_pain(id);

/**
 * Forces a player to become a pain.
 *
 * @note Unavailable for last default/special human
 *
 * @param id	Player index to turn into pain.
 * @return		True on success, false otherwise.
 */
native zp_make_user_pain(id);

/**
 * Returns number of alive pain.
 *
 * @return		pain count.
 */
native zp_get_pain_count();

/**
 * Returns whether the current round is a pain round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_pain_round();
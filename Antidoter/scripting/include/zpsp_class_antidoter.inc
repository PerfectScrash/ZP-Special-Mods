#if defined _zpsp_class_antidoter_included
  #endinput
#endif
#define _zpsp_class_antidoter_included

#if !defined _zombie_special_new_included
#include <zombie_plague_special>
#endif

/**
 * Returns whether a player is a antidoter.
 *
 * @param id	Player index.
 * @return		True if it is, false otherwise.
 */
native zp_get_user_antidoter(id);

/**
 * Forces a player to become a antidoter.
 *
 * @note Unavailable for last default/special human
 *
 * @param id	Player index to turn into antidoter.
 * @return		True on success, false otherwise.
 */
native zp_make_user_antidoter(id);

/**
 * Returns number of alive antidoter.
 *
 * @return		antidoter count.
 */
native zp_get_antidoter_count();

/**
 * Returns whether the current round is a antidoter round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_antidoter_round();

#if defined _zpsp_class_grenadier_included
  #endinput
#endif
#define _zpsp_class_grenadier_included

#if !defined _zombie_special_new_included
#include <zombie_plague_special>
#endif

/**
 * Returns whether a player is a grenadier.
 *
 * @param id	Player index.
 * @return		True if it is, false otherwise.
 */
native zp_get_user_grenadier(id);

/**
 * Forces a player to become a grenadier.
 *
 * @note Unavailable for last default/special human
 *
 * @param id	Player index to turn into grenadier.
 * @return		True on success, false otherwise.
 */
native zp_make_user_grenadier(id);

/**
 * Returns number of alive grenadier.
 *
 * @return		grenadier count.
 */
native zp_get_grenadier_count();

/**
 * Returns whether the current round is a grenadier round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_grenadier_round();

/**
 * Returns whether the current round is a grenadier vs bombardier round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_gvb_round();

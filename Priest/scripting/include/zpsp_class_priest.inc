#if defined _zpsp_priest_included
  #endinput
#endif
#define _zpsp_priest_included

#if !defined _zombie_special_new_included
#include <zombie_plague_special>
#endif


/**
 * Returns whether a player is a priest.
 *
 * @param id	Player index.
 * @return		True if it is, false otherwise.
 */
native zp_get_user_priest(id);
#define zp_get_user_padre(%1) zp_get_user_priest(%1)

/**
 * Forces a player to become a priest.
 *
 * @note Unavailable for last default/special human
 *
 * @param id	Player index to turn into priest.
 * @return		True on success, false otherwise.
 */
native zp_make_user_priest(id);
#define zp_make_user_padre(%1) zp_make_user_priest(%1)

/**
 * Returns number of alive priest.
 *
 * @return		priest count.
 */
native zp_get_priest_count();
#define zp_get_padre_count() zp_get_priest_count()


/**
 * Returns whether the current round is a priest round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_priest_round();
#define zp_get_padre_round() zp_is_priest_round()
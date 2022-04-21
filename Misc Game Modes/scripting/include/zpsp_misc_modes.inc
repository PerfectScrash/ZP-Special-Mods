#if defined _zpsp_misc_modes
  #endinput
#endif
#define _zpsp_misc_modes

#if !defined _zombie_special_new_included
#include <zombie_plague_special>
#endif

/**
 * Returns whether the current round is a cannibal round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_cannibal_round();

/**
 * Returns whether the current round is a tag round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_tag_round();

/**
 * Returns whether the current round is a gravity round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_gravity_round();

/**
 * Returns whether the current round is a deathmatch round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_deathmatch_round();

/**
 * Returns whether the current round is a nemesis xtreme round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_nem_xtreme_round();
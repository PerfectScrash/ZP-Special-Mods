#if defined _zpsp_dog_included
  #endinput
#endif
#define _zpsp_dog_included

#if !defined _zombie_special_new_included
#include <zombie_plague_special>
#endif


/**
 * Returns whether a player is a dog.
 *
 * @param id	Player index.
 * @return		True if it is, false otherwise.
 */
native zp_get_user_dog(id);

/**
 * Forces a player to become a dog.
 *
 * @note Unavailable for last default/special human
 *
 * @param id	Player index to turn into dog.
 * @return		True on success, false otherwise.
 */
native zp_make_user_dog(id);

/**
 * Returns number of alive dog.
 *
 * @return		dog count.
 */
native zp_get_dog_count();

/**
 * Returns whether the current round is a dog round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_dog_round();
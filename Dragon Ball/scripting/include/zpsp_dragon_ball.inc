#if defined _zpsp_dragon_balll
  #endinput
#endif
#define _zpsp_dragon_balll

#if !defined _zombie_special_new_included
#include <zombie_plague_special>
#endif


/**
 * Returns whether a player is a goku.
 *
 * @param id	Player index.
 * @return		True if it is, false otherwise.
 */
native zp_get_user_goku(id);

/**
 * Forces a player to become a goku.
 *
 * @note Unavailable for last default/special human
 *
 * @param id	Player index to turn into goku.
 * @return		True on success, false otherwise.
 */
native zp_make_user_goku(id);

/**
 * Returns number of alive goku.
 *
 * @return		goku count.
 */
native zp_get_goku_count();

/**
 * Returns whether the current round is a goku round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_goku_round();


/**
 * Returns whether a player is a krillin.
 *
 * @param id	Player index.
 * @return		True if it is, false otherwise.
 */
native zp_get_user_krillin(id);

/**
 * Forces a player to become a krillin.
 *
 * @note Unavailable for last default/special human
 *
 * @param id	Player index to turn into krillin.
 * @return		True on success, false otherwise.
 */
native zp_make_user_krillin(id);

/**
 * Returns number of alive krillin.
 *
 * @return		krillin count.
 */
native zp_get_krillin_count();

/**
 * Returns whether the current round is a krillin round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_krillin_round();


/**
 * Returns whether a player is a frieza.
 *
 * @param id	Player index.
 * @return		True if it is, false otherwise.
 */
native zp_get_user_frieza(id);

/**
 * Forces a player to become a frieza.
 *
 * @note Unavailable for last default/special zombie
 *
 * @param id	Player index to turn into frieza.
 * @return		True on success, false otherwise.
 */
native zp_make_user_frieza(id);

/**
 * Returns number of alive frieza.
 *
 * @return		frieza count.
 */
native zp_get_frieza_count();

/**
 * Returns whether the current round is a frieza round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_frieza_round();

/**
 * Returns whether the current round is a dbz round.
 *
 * @return		True if it is, false otherwise.
 */
native zp_is_dbz_round();

/* * Defines * */
#define zp_get_user_kurilin(%1) zp_get_user_krillin(%1)
#define zp_make_user_kurilin(%1) zp_make_user_krillin(%1)
#define zp_get_kurilin_count() zp_get_krillin_count()
#define zp_is_kurilin_round() zp_is_krillin_round()
#define zp_is_dragon_ball_mod() zp_is_dbz_round()
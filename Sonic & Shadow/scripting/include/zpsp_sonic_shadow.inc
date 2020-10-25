#if defined _zpsp_sonic_shadow_included
  #endinput
#endif
#define _zpsp_sonic_shadow_included

#if !defined _zombie_special_new_included
#include <zombie_plague_special>
#endif

// Game mode Shadow vs Sonic Natives
native zp_is_sonic_vs_shadow()
native zp_is_sonic_vs_shadow_enable()

// Shadow Natives
native zp_get_user_shadow(id)
native zp_make_user_shadow(id)
native zp_get_shadow_count()
native zp_is_shadow_round()
native zp_is_shadow_enable()

// Sonic Natives
native zp_get_user_sonic(id)
native zp_make_user_sonic(id)
native zp_get_sonic_count()
native zp_is_sonic_round()
native zp_is_sonic_enable()
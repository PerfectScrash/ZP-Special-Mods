#if defined _zpsp_class_grenadier_included
  #endinput
#endif
#define _zpsp_class_grenadier_included

#if !defined _zombie_special_new_included
#include <zombie_plague_special>
#endif

native zp_get_user_grenadier(id)
native zp_make_user_grenadier(id)
native zp_get_grenadier_count()
native zp_is_grenadier_round()

// Only Works if Plugin of Grenadier vs Bombardier is enable
native zp_is_gvb_round()

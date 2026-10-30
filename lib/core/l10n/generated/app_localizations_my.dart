// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Burmese (`my`).
class AppLocalizationsMy extends AppLocalizations {
  AppLocalizationsMy([String locale = 'my']) : super(locale);

  @override
  String get appTitle => 'WeBuddhist';

  @override
  String get sign_in => 'ဝင်ရောက်ရန်';

  @override
  String get logout => 'ထွက်ရန်';

  @override
  String get onboarding_welcome => 'ကြိုဆိုပါသည်';

  @override
  String get onboarding_tagline => 'လေ့လာ၊ ကျင့်ကြံ၊ ချိတ်ဆက်ပါ။ နေ့စဉ်။';

  @override
  String get onboarding_find_peace => 'စတင်ရန်';

  @override
  String get onboarding_continue => 'ဆက်လက်ရန်';

  @override
  String get onboarding_first_question => 'သင့်ဘာသာစကားကို ရွေးပါ';

  @override
  String get onboarding_language_subtitle =>
      'ဤရွေးချယ်မှုဖြင့် အက်ပ်၏ ဘာသာစကားကို သတ်မှတ်ပါသည်';

  @override
  String get onboarding_all_set => 'အားလုံး အဆင်သင့်ဖြစ်ပါပြီ';

  @override
  String get onboarding_all_set_description => 'သင့်ကို စောင့်ကြိုနေသည်များ:';

  @override
  String get onboarding_all_set_practice_title => 'ကျင့်ကြံ';

  @override
  String get onboarding_all_set_practice_body =>
      'သင်ခန်းစာအစီအစဉ်၊ ရွတ်ဆိုရန်စာ၊ ပုတီးနှင့် တရားထိုင်ခြင်း';

  @override
  String get onboarding_all_set_connect_title => 'ချိတ်ဆက်';

  @override
  String get onboarding_all_set_connect_body =>
      'အဖွဲ့၊ ပွဲ၊ သတင်းစဉ်နှင့် ချတ်';

  @override
  String get home_today => 'ယနေ့';

  @override
  String get home_overall_stats => 'စုစုပေါင်း စာရင်းအင်း';

  @override
  String home_plans_count(int count) {
    return 'သင်ခန်းစာအစီအစဉ် $count ခု';
  }

  @override
  String home_recitation_count(int count) {
    return 'ရွတ်ဆိုရန်စာ $count ပုဒ်';
  }

  @override
  String get home_shortcut_plans => 'သင်ခန်းစာအစီအစဉ်များ';

  @override
  String get home_chants => 'ရွတ်ဆိုရန်စာများ';

  @override
  String get home_mala => 'ပုတီး';

  @override
  String get session_mala => 'ပုတီးများ';

  @override
  String get bookmark_mala => 'ပုတီးများ';

  @override
  String get bookmark_timers => 'အချိန်မှတ်စက်များ';

  @override
  String get bookmark_texts => 'ကျမ်းစာများ';

  @override
  String get bookmark_group_accumulation => 'အဖွဲ့ စုဆောင်းမှုများ';

  @override
  String get mala_add_to_practice => 'ကျွန်ုပ်၏ ကျင့်စဉ်များသို့ ထည့်ရန်';

  @override
  String get mala_add_mala_round => 'ပုတီး ပတ်ရေ ထည့်ရန်';

  @override
  String get mala_add_rounds_title => 'ပုတီး ပတ်ရေ ထည့်ရန်:';

  @override
  String get mala_add_rounds_message =>
      'အက်ပ်ပြင်ပတွင် စိပ်ခဲ့သော ပုတီးပတ်ရေကို ထည့်ပါ';

  @override
  String mala_rounds_unit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ပတ်',
      one: 'ပတ်',
    );
    return '$_temp0';
  }

  @override
  String get mala_add_to_bookmark => 'မှတ်ထားရန်';

  @override
  String get mala_sound => 'အသံ';

  @override
  String get mala_vibration => 'တုန်ခါမှု';

  @override
  String get mala_reset_count => 'အရေအတွက် ပြန်စရန်';

  @override
  String get mala_reset_title => 'ဤပုတီးကို ပြန်စမလား။';

  @override
  String get mala_reset_count_confirm =>
      'သင့်လက်ရှိ အရေအတွက်သည် သုညသို့ ပြန်ရောက်မည်ဖြစ်သော်လည်း သင့်စုဆောင်းမှုများမှာ တစ်သက်တာ စုစုပေါင်းတွင် ကျန်ရှိနေပါမည်';

  @override
  String get mala_reset_confirm => 'ပြန်စရန်';

  @override
  String get mala_action_coming_soon => 'မကြာမီ လာမည်';

  @override
  String mala_rounds_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ပတ်',
      one: '1 ပတ်',
      zero: '0 ပတ်',
    );
    return '$_temp0';
  }

  @override
  String get mala_hand_layout_tooltip => 'လက် အနေအထား ပြောင်းရန်';

  @override
  String get mala_settings_section => 'ပုတီး ဆက်တင်များ';

  @override
  String get mala_others_section => 'အခြား';

  @override
  String get mala_mantra_speed => 'မန္တန် အမြန်နှုန်း';

  @override
  String get mala_speed_normal => 'ပုံမှန်';

  @override
  String get mala_show_full_mantra => 'မန္တန် အပြည့်အစုံ ပြရန်';

  @override
  String mala_counter_semantics(int bead, int total, String rounds) {
    return 'အရေအတွက် $total အနက် $bead၊ $rounds';
  }

  @override
  String get mala_group_accumulations => 'ရွတ်ဆိုမှု ထည့်မည့်နေရာ';

  @override
  String get mala_groups_section => 'ပွဲများ';

  @override
  String get mala_group_untitled => 'အမည်မဲ့ အဖွဲ့';

  @override
  String get mala_all_time_accumulation => 'ကျွန်ုပ်၏ စုစုပေါင်း စုဆောင်းမှု';

  @override
  String get mala_personal_practice => 'ကိုယ်ပိုင် ကျင့်စဉ်';

  @override
  String get mala_events_section => 'ပွဲများ';

  @override
  String mala_my_total(String count) {
    return 'ကျွန်ုပ်၏ စုစုပေါင်း: $count';
  }

  @override
  String mala_group_total(String count) {
    return 'အဖွဲ့ စုစုပေါင်း: $count';
  }

  @override
  String get home_timer => 'အချိန်မှတ်စက်';

  @override
  String get preset_timers => 'ကြိုတင်သတ်မှတ်ထားသော အချိန်မှတ်စက်များ';

  @override
  String get meditation_timer => 'တရားထိုင် အချိန်မှတ်စက်';

  @override
  String get timer_min => 'မိနစ်';

  @override
  String get timer_finish => 'ပြီးဆုံးရန်';

  @override
  String get timer_discard_session => 'ဤအကြိမ်ကို စွန့်ပယ်ရန်';

  @override
  String get home_hello_prefix => 'မင်္ဂလာပါ ';

  @override
  String home_share_prompt(String appName) {
    return '$appName ကို နှစ်သက်ပါသလား။';
  }

  @override
  String get home_share_support =>
      'သင့်ပံ့ပိုးမှုက ကျွန်ုပ်တို့ အသိုင်းအဝိုင်း ကြီးထွားရန် ကူညီပါသည်';

  @override
  String get no_feature_content => 'အထူးဖော်ပြထားသော အကြောင်းအရာ မရှိပါ';

  @override
  String get nav_home => 'ပင်မ';

  @override
  String get nav_explore => 'ရှာဖွေ';

  @override
  String get nav_learn => 'လေ့လာ';

  @override
  String get nav_practice => 'ကျင့်ကြံ';

  @override
  String get nav_settings => 'ဆက်တင်များ';

  @override
  String get nav_connect => 'ချိတ်ဆက်';

  @override
  String get nav_me => 'ကျွန်ုပ်';

  @override
  String get tab_practices => 'ကျင့်စဉ်များ';

  @override
  String get text_search => 'ရှာဖွေရန်';

  @override
  String get text_commentary => 'အဖွင့်များ';

  @override
  String get resources => 'အရင်းအမြစ်များ';

  @override
  String get no_translation => 'ဘာသာပြန် မတွေ့ပါ';

  @override
  String get show_more => 'ထပ်ပြရန်';

  @override
  String get show_less => 'လျှော့ပြရန်';

  @override
  String get more => 'နောက်ထပ်';

  @override
  String get less => 'ပြန်ချုံ့ရန်';

  @override
  String get no_content => 'အကြောင်းအရာ မတွေ့ပါ';

  @override
  String commentary_not_available_for_language(String language) {
    return '$language ဘာသာဖြင့် အဖွင့် မရှိသေးပါ';
  }

  @override
  String get loading => 'ဖွင့်နေသည်...';

  @override
  String get save => 'သိမ်းရန်';

  @override
  String get done => 'ပြီးပါပြီ';

  @override
  String get my_plans => 'ကျွန်ုပ်၏ သင်ခန်းစာအစီအစဉ်များ';

  @override
  String get browse_plans => 'သင်ခန်းစာအစီအစဉ်များ ကြည့်ရန်';

  @override
  String get plan_info => 'သင်ခန်းစာအစီအစဉ် အချက်အလက်';

  @override
  String get start_reading => 'ယခု ကျင့်ကြံရန်';

  @override
  String get tibetan => 'တိဗက်';

  @override
  String get sanskrit => 'သက္ကတ';

  @override
  String get english => 'အင်္ဂလိပ်';

  @override
  String get chinese => 'တရုတ်';

  @override
  String get classicalChinese => 'ရှေးဟောင်း တရုတ်';

  @override
  String get pali => 'ပါဠိ';

  @override
  String get language => 'ဘာသာစကား';

  @override
  String get plan_unenroll => 'စာရင်းမှ ထွက်ရန်';

  @override
  String get unenroll_confirmation =>
      'ဤသင်ခန်းစာအစီအစဉ်မှ စာရင်းထွက်မှာ သေချာပါသလား';

  @override
  String get unenroll_message =>
      'သင့်တိုးတက်မှု အပြီးတိုင် ပျောက်သွားမည်ဖြစ်ပြီး ပြန်လည်ရယူ၍ မရပါ';

  @override
  String get practice_plan =>
      'နေ့စဉ် ကျင့်စဉ်ကို တည်ဆောက်ပါ။ သင်နှင့် ကိုက်ညီသည်ကို ရှာဖွေပါ။';

  @override
  String get search_plans => 'သင်ခန်းစာအစီအစဉ်များ ရှာဖွေရန်...';

  @override
  String get search_for_plans => 'သင်ခန်းစာအစီအစဉ်များ ရှာဖွေရန်';

  @override
  String get no_plans_found => 'သင်ခန်းစာအစီအစဉ် မတွေ့ပါ';

  @override
  String get no_days_available => 'ရက် မတွေ့ပါ';

  @override
  String get recitations_search => 'ရွတ်ဆိုရန်စာများ ရှာဖွေရန်...';

  @override
  String get recitations_search_for => 'ရွတ်ဆိုရန်စာများ ရှာဖွေရန်';

  @override
  String get recitations_no_found => 'ရွတ်ဆိုရန်စာ မတွေ့ပါ';

  @override
  String get recitations_no_content => 'ရွတ်ဆိုရန်စာ မရှိပါ';

  @override
  String get my_recitation_collection_new_title => 'စုစည်းမှုအသစ်';

  @override
  String get my_recitation_collection_next => 'ရှေ့ဆက်ရန်';

  @override
  String get my_recitation_collection_create => 'ဖန်တီးရန်';

  @override
  String get my_recitation_collection_create_button => 'စုစည်းမှု ဖန်တီးရန်';

  @override
  String get my_recitation_collection_change_title => 'ခေါင်းစဉ် ပြောင်းရန်';

  @override
  String get my_recitation_collection_change => 'ပြောင်းရန်';

  @override
  String get my_recitation_collection_add_chants => 'ရွတ်ဆိုရန်စာများ ထည့်ရန်';

  @override
  String get my_recitation_collection_search_chants =>
      'ရွတ်ဆိုရန်စာများ ရှာဖွေရန်';

  @override
  String get my_recitation_collection_add_to_collection =>
      'စုစည်းမှုသို့ ထည့်ရန်';

  @override
  String get my_recitation_collection_edit => 'စုစည်းမှု ပြင်ဆင်ရန်';

  @override
  String get my_recitation_collection_delete => 'စုစည်းမှု ဖျက်ရန်';

  @override
  String get my_recitation_collection_delete_title => 'စုစည်းမှုကို ဖျက်မလား။';

  @override
  String get my_recitation_collection_delete_message =>
      'ဤစုစည်းမှုကို အပြီးတိုင် ဖယ်ရှားပါမည်';

  @override
  String get my_recitation_collection_fallback_title =>
      'ရွတ်ဆိုရန်စာ စုစည်းမှု';

  @override
  String get my_recitation_collection_unavailable => 'မရရှိနိုင်တော့ပါ';

  @override
  String my_recitation_collection_chant_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ရွတ်ဆိုရန်စာ $count ပုဒ်',
      one: 'ရွတ်ဆိုရန်စာ 1 ပုဒ်',
      zero: 'ရွတ်ဆိုရန်စာ 0 ပုဒ်',
    );
    return '$_temp0';
  }

  @override
  String my_recitation_collection_chant_count_owner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ရွတ်ဆိုရန်စာ $count ပုဒ် • ကျွန်ုပ်',
      one: 'ရွတ်ဆိုရန်စာ 1 ပုဒ် • ကျွန်ုပ်',
      zero: 'ရွတ်ဆိုရန်စာ 0 ပုဒ် • ကျွန်ုပ်',
    );
    return '$_temp0';
  }

  @override
  String get bookmarks_empty_chant_collections_title =>
      'မှတ်ထားသော ရွတ်ဆိုရန်စာ စုစည်းမှု မရှိသေးပါ';

  @override
  String get bookmarks_empty_chant_collections_subtitle =>
      'တစ်ခုကို မှတ်ထားပါက ဤနေရာတွင် သိမ်းထားပါမည်';

  @override
  String get notification_allow_title => 'အသိပေးချက်များ ခွင့်ပြုရန်';

  @override
  String get notification_allow_subtitle_disabled =>
      'ခွင့်ပြုချက် လိုအပ်ပါသည်။ ဆက်တင်များတွင် ခွင့်ပြုရန် နှိပ်ပါ';

  @override
  String get notification_snack_permission_denied =>
      'အသိပေးချက်များကို ပိတ်ဆို့ထားပါသည်။ ဆက်တင်များတွင် ဖွင့်ပါ';

  @override
  String get notification_snack_disable_alarms_in_settings =>
      'ဆက်တင်များတွင် နှိုးစက်နှင့် သတိပေးချက်များကို ပိတ်ပါ';

  @override
  String get notification_allow_subtitle_on =>
      'WeBuddhist မှ သတိပေးချက်များနှင့် အပ်ဒိတ်များ';

  @override
  String get notification_allow_subtitle_off =>
      'ပိတ်ထားသည်။ သတိပေးချက်များနှင့် အပ်ဒိတ်များ ရယူရန် ဖွင့်ပါ။';

  @override
  String get notification_section_practice => 'ကျင့်ကြံ';

  @override
  String get notification_section_connect => 'ချိတ်ဆက်';

  @override
  String get notification_row_plans => 'သင်ခန်းစာအစီအစဉ်များ';

  @override
  String get notification_row_chants => 'ရွတ်ဆိုရန်စာများ';

  @override
  String get notification_row_mala => 'ပုတီးနှင့် စုဆောင်းမှုများ';

  @override
  String get notification_row_timer => 'အချိန်မှတ်စက်';

  @override
  String get notification_row_group_posts => 'အဖွဲ့ ပို့စ်များ';

  @override
  String get notification_row_group_chats => 'အဖွဲ့ ချတ်များ';

  @override
  String get notification_row_my_prayer_requests =>
      'ကျွန်ုပ်၏ ဆုတောင်းပေးရန် တောင်းဆိုချက်များ';

  @override
  String get notification_row_others_prayer_requests =>
      'အခြားသူများ၏ ဆုတောင်းပေးရန် တောင်းဆိုချက်များ';

  @override
  String get profile_default_bio => 'WeBuddhist မှ ကြိုဆိုပါသည်';

  @override
  String get profile_guest_title => 'ဧည့်သည် အသုံးပြုသူ';

  @override
  String get profile_guest_subtitle => 'ဧည့်သည်အဖြစ် ကြည့်ရှုနေပါသည်';

  @override
  String get profile_guest_benefits_header => 'ဝင်ရောက်ပြီး ရယူပါ:';

  @override
  String get profile_guest_benefit_save_progress =>
      'သင့်တိုးတက်မှုကို သိမ်းရန်';

  @override
  String get profile_guest_benefit_personalized =>
      'သင့်အတွက် ရွေးချယ်ထားသော အကြောင်းအရာ';

  @override
  String get profile_guest_benefit_notifications => 'စိတ်ကြိုက် အသိပေးချက်များ';

  @override
  String get auth_drawer_title => 'ဆက်လက်ရန် ဝင်ရောက်ပါ';

  @override
  String get auth_drawer_subtitle =>
      'မည်သည့်စက်ပစ္စည်းမှမဆို၊ မည်သည့်နေရာတွင်မဆို သင့်ကျင့်စဉ်ကို ဆက်လက်လုပ်ဆောင်ပါ';

  @override
  String get routine_delete_block_message =>
      'ဤအချိန်အပိုင်းနှင့် ၎င်းရှိ အရာအားလုံးကို ဖယ်ရှားပါမည်';

  @override
  String get something_went_wrong =>
      'တစ်ခုခု မှားယွင်းသွားပါသည်။ ထပ်ကြိုးစားပါ';

  @override
  String get onboarding_tradition_title =>
      'မြတ်စွာဘုရား၏ တရားတော်များကို ဘယ်လို လိုက်နာပါသလဲ။';

  @override
  String get onboarding_tradition_subtitle =>
      'သင့်အကြောင်းအရာအတွက် ဂိုဏ်း တစ်ခု သို့မဟုတ် တစ်ခုထက်ပို ရွေးပါ။ ဆက်တင်များတွင် အချိန်မရွေး ပြောင်းနိုင်ပါသည်။';

  @override
  String get onboarding_tradition_show_all_title => 'အားလုံးကို ပြပါ';

  @override
  String get plan_go_to_practice => 'ကျင့်စဉ်သို့ သွားရန်';

  @override
  String get plan_starts_soon_title => 'မကြာမီ စတင်မည်';

  @override
  String get plan_joining_late_title => 'စတင်ရက်ပြီးမှ ပါဝင်ခြင်း';

  @override
  String get got_it => 'နားလည်ပါပြီ';

  @override
  String get plan_no_tasks_error => 'လုပ်ဆောင်ရန်များကို ဖွင့်၍ မရပါ';

  @override
  String get plan_day_tasks_load_error => 'လုပ်ဆောင်ရန်များကို ဖွင့်၍ မရပါ';

  @override
  String get plans_empty_title => 'နောက်ထပ် လာပါဦးမည်';

  @override
  String get plans_empty_subtitle =>
      'ကျွန်ုပ်တို့၏ စာကြည့်တိုက် တိုးချဲ့နေပါသည်။ မကြာမီ ပြန်ကြည့်ပါ။';

  @override
  String get find_plans_load_error =>
      'ဖွင့်၍ မရပါ။\nအင်တာနက်ချိတ်ဆက်မှုကို စစ်ဆေးပြီး ထပ်ကြိုးစားပါ';

  @override
  String get connect_subtitle => 'အဖွဲ့များကို ရှာဖွေပြီး အတူတကွ ကျင့်ကြံပါ';

  @override
  String get discover_groups => 'အဖွဲ့များ ရှာဖွေရန်';

  @override
  String get my_groups => 'ကျွန်ုပ်၏ အဖွဲ့များ';

  @override
  String get see_all => 'အားလုံး ကြည့်ရန်';

  @override
  String get connect_groups_load_error =>
      'အဖွဲ့များကို ဖွင့်၍ မရပါ။\nအင်တာနက်ချိတ်ဆက်မှုကို စစ်ဆေးပြီး ထပ်ကြိုးစားပါ';

  @override
  String get connect_groups_empty_title => 'နောက်ထပ် အဖွဲ့ မရှိတော့ပါ';

  @override
  String get connect_tab_feed => 'သတင်းစဉ်';

  @override
  String get connect_tab_events => 'ပွဲများ';

  @override
  String get connect_tab_practices => 'ကျင့်စဉ်များ';

  @override
  String get connect_tab_groups => 'အဖွဲ့များ';

  @override
  String get connect_segment_my => 'သင့်အဖွဲ့များ';

  @override
  String get connect_segment_discover => 'ရှာဖွေရန်';

  @override
  String get connect_empty_discover_events => 'ရှာဖွေရန် ပွဲ မရှိပါ';

  @override
  String get connect_empty_discover_feed => 'ရှာဖွေရန် အရာ မရှိပါ';

  @override
  String get connect_empty_discover_groups => 'ရှာဖွေရန် အဖွဲ့ မရှိပါ';

  @override
  String get connect_all_groups => 'အဖွဲ့အားလုံး';

  @override
  String get connect_my_empty_feed_title => 'သတင်းအသစ် မရှိပါ';

  @override
  String get connect_my_empty_events_title => 'လာမည့် ပွဲ မရှိပါ';

  @override
  String get connect_my_empty_groups_title => 'အဖွဲ့ မရှိသေးပါ';

  @override
  String get connect_my_empty_feed_subtitle =>
      'သင့်အဖွဲ့များတွင် အသစ် မျှဝေထားသည်များ မရှိသေးပါ';

  @override
  String get connect_my_empty_events_subtitle =>
      'သင့်အဖွဲ့များတွင် စီစဉ်ထားသော ပွဲ မရှိသေးပါ';

  @override
  String get connect_my_empty_groups_subtitle =>
      'မည်သည့်အဖွဲ့တွင်မျှ မပါဝင်ရသေးပါ။ အတူကျင့်ကြံရန် အဖွဲ့များကို ရှာဖွေပါ';

  @override
  String get connect_my_empty_feed_browse =>
      'အခြားအဖွဲ့များ မျှဝေထားသည်များကို ကြည့်ရန်';

  @override
  String get connect_my_empty_events_browse =>
      'အများပါဝင်နိုင်သော ပွဲများ ကြည့်ရန်';

  @override
  String connect_comment_replying_to(String handle) {
    return '@$handle ကို ပြန်ကြားနေသည်';
  }

  @override
  String get connect_comment_hint => 'ဒီအကြောင်း ဘယ်လိုထင်ပါသလဲ။';

  @override
  String get connect_comment_reply_hint => 'ပြန်စာ ရေးပါ...';

  @override
  String get connect_comment_reply => 'ပြန်ကြားရန်';

  @override
  String get connect_comment_delete_title => 'မှတ်ချက်ကို ဖျက်မလား။';

  @override
  String get connect_comment_delete_message =>
      'ဤမှတ်ချက်ကို အပြီးတိုင် ဖယ်ရှားပါမည်';

  @override
  String get connect_comment_delete_failed => 'မှတ်ချက်ကို ဖျက်၍ မရပါ';

  @override
  String connect_post_comments_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'မှတ်ချက် $count ခု',
      one: 'မှတ်ချက် 1 ခု',
    );
    return '$_temp0';
  }

  @override
  String get connect_post_comments_empty =>
      'မှတ်ချက် မရှိသေးပါ။ စတင် ဆွေးနွေးလိုက်ပါ';

  @override
  String get connect_online => 'အွန်လိုင်း';

  @override
  String get connect_ended => 'ပြီးဆုံးပြီ';

  @override
  String connect_ended_on(String date) {
    return '$date တွင် ပြီးဆုံးခဲ့သည်';
  }

  @override
  String get home_group_events => 'အထူးဖော်ပြထားသော ပွဲများ';

  @override
  String get home_poems => 'ကဗျာများ';

  @override
  String get poems_load_error =>
      'ကဗျာများကို ဖွင့်၍ မရပါ။\nအင်တာနက်ချိတ်ဆက်မှုကို စစ်ဆေးပြီး ထပ်ကြိုးစားပါ';

  @override
  String get poems_empty => 'ကဗျာ မရှိသေးပါ။ မကြာမီ ပြန်ကြည့်ပါ';

  @override
  String get connect_events_filter_all => 'အားလုံး';

  @override
  String get connect_events_filter_in_person => 'ကိုယ်တိုင်တက်ရောက်';

  @override
  String get connect_events_filter_empty_online => 'အွန်လိုင်းပွဲ မရှိပါ';

  @override
  String get connect_events_filter_empty_in_person =>
      'ကိုယ်တိုင်တက်ရောက်ရသော ပွဲ မရှိပါ';

  @override
  String get connect_events_filter_hybrid => 'ပေါင်းစပ်';

  @override
  String get connect_events_filter_empty_hybrid => 'ပေါင်းစပ်ပွဲ မရှိပါ';

  @override
  String get connect_event_fallback_title => 'ပွဲ';

  @override
  String get connect_group_fallback_title => 'အဖွဲ့';

  @override
  String get connect_event_participation_prompt => 'ဘယ်လို တက်ရောက်မလဲ။';

  @override
  String get connect_event_practice_in_person =>
      'ကိုယ်တိုင်တက်ရောက် ကျင့်ကြံရန်';

  @override
  String get connect_event_practice_online => 'အွန်လိုင်းမှ ကျင့်ကြံရန်';

  @override
  String get connect_event_view_in_person => 'ကိုယ်တိုင်တက်ရောက်သူ မြင်ကွင်း';

  @override
  String get connect_event_view_online => 'အွန်လိုင်း မြင်ကွင်း';

  @override
  String get connect_event_accumulation_online => 'အွန်လိုင်း';

  @override
  String get connect_event_accumulation_in_person => 'ကိုယ်တိုင်တက်ရောက်';

  @override
  String get connect_event_has_ended => 'ဤပွဲ ပြီးဆုံးသွားပါပြီ';

  @override
  String get connect_event_join_to_practice => 'ကျင့်ကြံရန် ပွဲတွင် ပါဝင်ပါ';

  @override
  String get connect_event_leave => 'ပွဲမှ ထွက်ရန်';

  @override
  String get connect_event_leave_confirm_title => 'ဤပွဲမှ ထွက်မလား။';

  @override
  String connect_event_leave_confirm_message(String title) {
    return '$title ကို တက်ရောက်တော့မည် မဟုတ်ပါ။ ပွဲကို ဆက်ကြည့်နိုင်ပြီး အချိန်မရွေး ပြန်တက်ရောက်နိုင်ပါသည်။';
  }

  @override
  String connect_event_participants_attending(int count) {
    return 'ပါဝင်သူ $count ဦး';
  }

  @override
  String connect_event_participants_attended(int count) {
    return '$count ဦး တက်ရောက်ခဲ့သည်';
  }

  @override
  String get connect_event_participants_empty => 'ပါဝင်သူ မရှိသေးပါ';

  @override
  String get connect_event_organizer => 'စီစဉ်သူ';

  @override
  String get connect_event_tab_videos => 'ဗီဒီယိုများ';

  @override
  String get connect_event_tab_about => 'အကြောင်း';

  @override
  String get connect_event_links_title => 'နောက်ထပ် ပွဲအသေးစိတ်များ';

  @override
  String get connect_event_date_tba => 'ရက်စွဲကို နောက်မှ ကြေညာပါမည်';

  @override
  String get connect_event_when => 'အချိန်';

  @override
  String get connect_event_where => 'နေရာ';

  @override
  String get connect_event_tab_accumulations => 'စုဆောင်းမှုများ';

  @override
  String get connect_event_add_recitations => 'ရွတ်ဆိုမှု ထည့်ရန်';

  @override
  String get connect_event_add_recitations_message =>
      'တိုက်ရိုက်ထုတ်လွှင့်မှုနှင့်အတူ သို့မဟုတ် ဤအက်ပ်ပြင်ပတွင် ရွတ်ဆိုခဲ့သည်များကို ထည့်ပါ';

  @override
  String get connect_event_every_day => 'နေ့စဉ်';

  @override
  String connect_event_every_weekday(String weekday) {
    return '$weekday တိုင်း';
  }

  @override
  String get connect_event_every_month => 'လစဉ်';

  @override
  String connect_event_every_date(String date) {
    return '$date တိုင်း';
  }

  @override
  String get connect_event_about_empty => 'ပွဲအသေးစိတ် မရှိသေးပါ';

  @override
  String get search_groups => 'အဖွဲ့များ ရှာဖွေရန်';

  @override
  String get search_for_groups => 'အဖွဲ့များ ရှာဖွေရန်';

  @override
  String get no_groups_found => 'ကိုက်ညီသော အဖွဲ့ မတွေ့ပါ';

  @override
  String get explore_coming_soon_subtitle =>
      'ကျင့်စဉ်များ၊ တရားတော်များနှင့် အသိုင်းအဝိုင်းပွဲများကို ရှာဖွေနိုင်မည့် ရွေးချယ်စီစဉ်ထားသော နေရာ';

  @override
  String get learn_coming_soon_subtitle =>
      'နေ့စဉ်ဘဝနှင့် လိုက်လျောညီထွေ ဖြစ်အောင် ပြုလုပ်ထားသော သင့်ကိုယ်ပိုင် သင်ခန်းစာအစီအစဉ်များ';

  @override
  String get creator_featured_plan => 'အထူးဖော်ပြထားသော သင်ခန်းစာအစီအစဉ်များ';

  @override
  String get home_no_series_found => 'စီးရီး မတွေ့ပါ';

  @override
  String get home_no_tags_found => 'တဂ် မတွေ့ပါ';

  @override
  String get home_celebrated_by => 'ကျင်းပသူ: ';

  @override
  String get reader_font_size_tooltip => 'စာလုံးအရွယ်';

  @override
  String get reader_versions_load_error => 'ဗားရှင်းများကို ဖွင့်၍ မရပါ';

  @override
  String get reader_languages_load_error => 'ဘာသာစကားများကို ဖွင့်၍ မရပါ';

  @override
  String reader_no_versions_in_language(String language) {
    return '$language ဘာသာတွင် ဗားရှင်း မရှိပါ';
  }

  @override
  String get reader_no_languages => 'ဤကျမ်းစာအတွက် ဘာသာစကား မရှိပါ';

  @override
  String get reader_license => 'လိုင်စင်';

  @override
  String get text_search_hint => 'ရှာဖွေရန် ရိုက်ထည့်ပါ';

  @override
  String get text_search_press_button => 'ရှာဖွေရန် ရှာဖွေမည့်ခလုတ်ကို နှိပ်ပါ';

  @override
  String get text_search_error => 'ရှာဖွေ၍ မရပါ။\nထပ်ကြိုးစားပါ';

  @override
  String get create_image_share_error => 'မျှဝေ၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get my_plans_sign_in_prompt =>
      'သင့်သင်ခန်းစာအစီအစဉ်များကို ကြည့်ရန် ဝင်ရောက်ပါ';

  @override
  String plan_starts_soon_message(String date) {
    return '$date တွင် စတင်ပါမည်။ အကြောင်းအရာများကို ယခု ကြည့်ရှုနိုင်ပါသည်';
  }

  @override
  String plan_joining_late_message(String date) {
    return '$date တွင် စတင်ခဲ့ပါသည်။ ယခင်ရက်များ၏ လုပ်ဆောင်ရန်များကို ပြီးအောင် လုပ်နိုင်ပါသည်';
  }

  @override
  String get select_language => 'ဘာသာစကား ရွေးပါ';

  @override
  String get logout_confirmation => 'ထွက်မှာ သေချာပါသလား။';

  @override
  String get cancel => 'ပယ်ဖျက်ရန်';

  @override
  String get copy => 'ကူးယူရန်';

  @override
  String get copied => 'ကူးယူပြီးပါပြီ';

  @override
  String get share => 'မျှဝေရန်';

  @override
  String get bookmark => 'မှတ်ထားရန်';

  @override
  String get collection_audio_versions => 'အသံ ဗားရှင်းများ';

  @override
  String get playback_speed => 'Playback speed';

  @override
  String get author => 'စာရေးသူ';

  @override
  String get plans_created => 'ဖန်တီးထားသော သင်ခန်းစာအစီအစဉ်များ';

  @override
  String get ai_confirm => 'အတည်ပြုရန်';

  @override
  String search_no_results(String query) {
    return '\"$query\" အတွက် ရလဒ် မတွေ့ပါ';
  }

  @override
  String get search_all => 'အားလုံး';

  @override
  String get common_ok => 'အိုကေ';

  @override
  String get comingSoonHeadline => 'မကြာမီ လာမည်';

  @override
  String get routine_title => 'ကျွန်ုပ်၏ ကျင့်စဉ်များ';

  @override
  String get bookmarks => 'မှတ်ထားချက်များ';

  @override
  String get routine_empty_title => 'ကျင့်စဉ်များ';

  @override
  String get routine_edit => 'ပြင်ဆင်ရန်';

  @override
  String get routine_empty_description =>
      'သင့်နေ့စဉ်ကျင့်စဉ်ထဲ ထည့်ရန် တရားတော်များနှင့် ကျင့်စဉ်များကို ထပ်မံ ရှာဖွေပါ';

  @override
  String get routine_build => 'သင့်နေ့စဉ်ကျင့်စဉ်ကို တည်ဆောက်ပါ';

  @override
  String get routine_add_session => 'အချိန်အပိုင်းသို့ ထည့်ရန်';

  @override
  String get routine_edit_title => 'သင့်နေ့စဉ်ကျင့်စဉ်ကို ပြင်ဆင်ရန်';

  @override
  String get routine_delete_block => 'အပိုင်း ဖယ်ရှားရန်';

  @override
  String get routine_session_title_hint => 'ခေါင်းစဉ်...';

  @override
  String get routine_expand_all => 'အားလုံး ချဲ့ရန်';

  @override
  String get routine_collapse_all => 'အားလုံး ချုံ့ရန်';

  @override
  String get routine_add_plan => 'သင်ခန်းစာအစီအစဉ် ထည့်ရန်';

  @override
  String get routine_add_recitation => 'ရွတ်ဆိုရန်စာ ထည့်ရန်';

  @override
  String get routine_add_plan_to_routine => 'နေ့စဉ်ကျင့်စဉ်သို့ ထည့်ရန်';

  @override
  String get routine_load_error =>
      'ဖွင့်၍ မရပါ။ အင်တာနက်ချိတ်ဆက်မှုကို စစ်ဆေးပြီး ထပ်ကြိုးစားပါ';

  @override
  String get routine_empty_block_title_singular => 'ဗလာ အချိန်အပိုင်း';

  @override
  String routine_empty_block_title_plural(int count) {
    return 'ဗလာ အချိန်အပိုင်းများ ($count)';
  }

  @override
  String get routine_empty_block_message_singular =>
      'ဤအချိန်အပိုင်း ဗလာဖြစ်နေပါသည်။ အရာတစ်ခု ထည့်မလား၊ သို့မဟုတ် သင့်နေ့စဉ်ကျင့်စဉ်မှ ဖယ်ရှားမလား။';

  @override
  String routine_empty_block_message_plural(int count) {
    return 'အချိန်အပိုင်း $count ခု ဗလာဖြစ်နေပါသည်။ အရာများ ထည့်မလား၊ သို့မဟုတ် သင့်နေ့စဉ်ကျင့်စဉ်မှ ဖယ်ရှားမလား။';
  }

  @override
  String get routine_empty_block_add_items => 'အရာများ ထည့်ရန်';

  @override
  String get routine_empty_block_delete_singular => 'အပိုင်း ဖယ်ရှားရန်';

  @override
  String get routine_empty_block_delete_plural => 'အပိုင်းများ ဖယ်ရှားရန်';

  @override
  String get routine_notification_title =>
      'ကျင့်ကြံခြင်းကို အလေ့အကျင့်ဖြစ်အောင် ပြုလုပ်ပါ';

  @override
  String get routine_notification_description =>
      'ကျင့်ကြံရန် သတိပေးနိုင်စေရန် အသိပေးချက်များကို ခွင့်ပြုပါ';

  @override
  String get routine_notification_enable => 'အသိပေးချက်များ ဖွင့်ရန်';

  @override
  String get routine_notification_skip => 'ကျော်ရန်';

  @override
  String routine_time_adjusted(String time, int gap) {
    return '$time သို့ ချိန်ညှိလိုက်ပါသည် (အနည်းဆုံး $gap မိနစ် ခြားရမည်)';
  }

  @override
  String get routine_add_block_label => 'အချိန်အပိုင်း';

  @override
  String get continueWithGoogle => 'Google ဖြင့် ဆက်လက်ရန်';

  @override
  String get continueWithApple => 'Apple ဖြင့် ဆက်လက်ရန်';

  @override
  String get continueWithPhone => 'ဖုန်းဖြင့် ဆက်လက်ရန်';

  @override
  String get exploreAsGuest => 'ဧည့်သည်အဖြစ် လေ့လာရန်';

  @override
  String get signIn => 'ဝင်ရောက်ရန်';

  @override
  String get profileError => 'ပရိုဖိုင်ကို ဖွင့်ရာတွင် အမှားဖြစ်ပါသည်';

  @override
  String get profileTitle => 'ပရိုဖိုင်';

  @override
  String get notLoggedIn => 'ဝင်ရောက်ထားခြင်း မရှိပါ';

  @override
  String get retry => 'ထပ်ကြိုးစားပါ';

  @override
  String get back => 'နောက်သို့';

  @override
  String get delete => 'ဖျက်ရန်';

  @override
  String get close => 'ပိတ်ရန်';

  @override
  String get tryAgain => 'ထပ်ကြိုးစားပါ';

  @override
  String get pleaseTryAgain => 'ထပ်ကြိုးစားပါ';

  @override
  String get error => 'အမှား';

  @override
  String get anonymous => 'အမည်မဖော်လိုသူ';

  @override
  String get noContentAvailable => 'အကြောင်းအရာ မရှိပါ';

  @override
  String get unableToLoad =>
      'ဖွင့်၍ မရပါ။ အင်တာနက်ချိတ်ဆက်မှုကို စစ်ဆေးပြီး ထပ်ကြိုးစားပါ';

  @override
  String get somethingWrong =>
      'တစ်ခုခု မှားယွင်းသွားပါသည်။ အင်တာနက်ချိတ်ဆက်မှုကို စစ်ဆေးပြီး ထပ်ကြိုးစားပါ';

  @override
  String get source => 'ရင်းမြစ်';

  @override
  String get noTasks => 'လုပ်ဆောင်ရန် မရှိပါ';

  @override
  String get taskNotFound => 'လုပ်ဆောင်ရန် မတွေ့ပါ';

  @override
  String get updateTaskError => 'လုပ်ဆောင်ရန် အခြေအနေကို ပြင်ဆင်၍ မရပါ';

  @override
  String get enrollError =>
      'စာရင်းသွင်း၍ မရပါ။ အင်တာနက်ချိတ်ဆက်မှုကို စစ်ဆေးပြီး ထပ်ကြိုးစားပါ';

  @override
  String unenrollSuccess(String planTitle) {
    return '$planTitle မှ စာရင်းထွက်ပြီးပါပြီ';
  }

  @override
  String get unenrollError =>
      'စာရင်းမှ ထွက်၍ မရပါ။ အင်တာနက်ချိတ်ဆက်မှုကို စစ်ဆေးပြီး ထပ်ကြိုးစားပါ';

  @override
  String get unenrollGenericError =>
      'တစ်ခုခု မှားယွင်းသွားပါသည်။ အင်တာနက်ချိတ်ဆက်မှုကို စစ်ဆေးပြီး ထပ်ကြိုးစားပါ';

  @override
  String get notFound =>
      'ဤအရာ မရရှိနိုင်တော့ပါ။ အပ်ဒိတ်လုပ်ရန် သင့်နေ့စဉ်ကျင့်စဉ်ကို ပြင်ဆင်ပါ';

  @override
  String get noTimeSlot =>
      'အလွတ်အချိန် မရှိပါ။ အချိန်အပိုင်းတစ်ခုကို အရင်ဖယ်ရှားကြည့်ပါ';

  @override
  String maxBlocks(int max) {
    return 'အချိန်အပိုင်း အများဆုံး $max ခုအထိ ရောက်ရှိပါပြီ';
  }

  @override
  String get duplicateItem => 'ဤအရာသည် ဤအချိန်အပိုင်းတွင် ရှိပြီးသား ဖြစ်ပါသည်';

  @override
  String get removeItem => 'အရာကို ဖယ်ရှားမလား။';

  @override
  String removeConfirmation(String itemName) {
    return '\"$itemName\" ကို ဤအချိန်အပိုင်းမှ ဖယ်ရှားပါမည်';
  }

  @override
  String shareError(String error) {
    return 'မျှဝေ၍ မရပါ။ ထပ်ကြိုးစားပါ';
  }

  @override
  String get captureError => 'QR ကုဒ်ကို ရိုက်ယူ၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get qrShareError => 'QR ကုဒ်ကို မျှဝေ၍ မရပါ။ နောက်မှ ထပ်ကြိုးစားပါ';

  @override
  String errorDetail(String error) {
    return 'အမှား - $error';
  }

  @override
  String missedDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'လွတ်သွားသောရက် $count ရက်',
      one: 'လွတ်သွားသောရက် 1 ရက်',
      zero: 'လွတ်သွားသောရက် 0 ရက်',
    );
    return '$_temp0';
  }

  @override
  String get plan_status_on_track => 'အစီအစဉ်အတိုင်း ရှိနေပါသည်!';

  @override
  String get start_now => 'ယခု စတင်ရန်';

  @override
  String get plan_enroll => 'စာရင်းသွင်းရန်';

  @override
  String get root_text => 'မူလကျမ်း';

  @override
  String get version => 'ဗားရှင်းများ';

  @override
  String get reader_languages_title => 'ဘာသာစကားများ';

  @override
  String get reader_sections_title => 'အပိုင်းများ';

  @override
  String get reader_original_label => 'မူရင်း';

  @override
  String get reader_translation_label => 'ဘာသာပြန်';

  @override
  String get version_not_available => 'မရရှိနိုင်ပါ';

  @override
  String series_stats(int planCount, int totalDays) {
    return 'အခန်း $planCount ခန်း · $totalDays ရက်';
  }

  @override
  String get force_update_title => 'အပ်ဒိတ်လုပ်ရန် လိုအပ်ပါသည်';

  @override
  String get force_update_message =>
      'အက်ပ်ဗားရှင်းအသစ် ရနိုင်ပါပြီ။ ဆက်လက်အသုံးပြုရန် အပ်ဒိတ်လုပ်ပါ';

  @override
  String get force_update_button => 'ယခု အပ်ဒိတ်လုပ်ရန်';

  @override
  String get settings_section_personalisation => 'စိတ်ကြိုက်ပြင်ဆင်မှု';

  @override
  String get settings_section_more => 'နောက်ထပ်';

  @override
  String get settings_section_account => 'အကောင့်';

  @override
  String get settings_edit_profile => 'ပရိုဖိုင် ပြင်ဆင်ရန်';

  @override
  String get settings_theme => 'အပြင်အဆင်';

  @override
  String get settings_notification_row => 'အသိပေးချက်များ';

  @override
  String get settings_feedback_row => 'အကြံပြုချက်';

  @override
  String get edit_profile_title => 'ပရိုဖိုင် ပြင်ဆင်ရန်';

  @override
  String get edit_profile_save => 'သိမ်းရန်';

  @override
  String get edit_profile_display_name => 'ပြသမည့်အမည်';

  @override
  String get edit_profile_bio => 'ကိုယ်ရေးအကျဉ်း';

  @override
  String get edit_profile_bio_hint => 'သင့်အကြောင်း အနည်းငယ် မျှဝေပါ';

  @override
  String get edit_profile_delete_account => 'အကောင့် ဖျက်ရန်';

  @override
  String get edit_profile_photo_not_uploaded => 'ဓာတ်ပုံကို မတင်နိုင်ခဲ့ပါ';

  @override
  String get edit_profile_photo_too_large =>
      'ပုံ အရွယ်အစား ကြီးလွန်းပါသည်။ 1 MB အောက် ဓာတ်ပုံကို ရွေးပြီး ထပ်ကြိုးစားပါ';

  @override
  String get edit_profile_photo_upload_failed =>
      'သင့်ဓာတ်ပုံကို တင်၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get edit_profile_choose_from_library => 'ဓာတ်ပုံပြခန်းမှ ရွေးရန်';

  @override
  String get edit_profile_take_photo => 'ဓာတ်ပုံ ရိုက်ရန်';

  @override
  String get edit_profile_offline =>
      'အင်တာနက် ချိတ်ဆက်မှု မရှိပါ။ အင်တာနက်နှင့် ချိတ်ဆက်ပြီး ထပ်ကြိုးစားပါ';

  @override
  String get edit_profile_save_failed =>
      'ပြောင်းလဲမှုများကို သိမ်း၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get edit_profile_traditions => 'ဂိုဏ်းများ';

  @override
  String get edit_profile_choose_traditions => 'သင့်ဂိုဏ်းများကို ရွေးပါ';

  @override
  String get edit_profile_tradition_remove_failed =>
      'ဂိုဏ်းကို ဖယ်ရှား၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get edit_profile_tradition_save_failed =>
      'ဂိုဏ်းများကို သိမ်း၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get username_label => 'အသုံးပြုသူအမည်';

  @override
  String get username_taken => 'ဤအမည်ကို အခြားသူ အသုံးပြုထားပြီးပါပြီ';

  @override
  String get username_available_label => 'ရနိုင်သည်:';

  @override
  String get username_check_error =>
      'အသုံးပြုသူအမည်ကို စစ်ဆေး၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get username_invalid_format => 'အသုံးပြုသူအမည် ပုံစံ မမှန်ကန်ပါ';

  @override
  String get username_min_length =>
      'အသုံးပြုသူအမည်သည် အနည်းဆုံး စာလုံး 3 လုံး ရှိရပါမည်';

  @override
  String get username_max_length =>
      'အသုံးပြုသူအမည်သည် စာလုံး 30 လုံး သို့မဟုတ် ထိုထက်နည်းရပါမည်';

  @override
  String get username_no_spaces => 'အသုံးပြုသူအမည်တွင် ကွက်လပ် မပါရပါ';

  @override
  String get username_invalid_chars =>
      'စာလုံး၊ ဂဏန်းနှင့် _ . - တို့ကိုသာ ခွင့်ပြုပါသည်';

  @override
  String get username_must_start_alphanumeric =>
      'အသုံးပြုသူအမည်သည် စာလုံး သို့မဟုတ် ဂဏန်းဖြင့် စတင်ရပါမည်';

  @override
  String get username_must_end_alphanumeric =>
      'အသုံးပြုသူအမည်သည် စာလုံး သို့မဟုတ် ဂဏန်းဖြင့် အဆုံးသတ်ရပါမည်';

  @override
  String get person_name_min_length => 'အနည်းဆုံး စာလုံး 1 လုံး ရှိရပါမည်';

  @override
  String get person_name_max_length =>
      'စာလုံး 50 လုံး သို့မဟုတ် ထိုထက်နည်းရပါမည်';

  @override
  String get person_name_invalid_chars =>
      'စာလုံး၊ ကွက်လပ်၊ တုံးတို နှင့် အပိုစထရော့ဖီများကိုသာ ခွင့်ပြုပါသည်';

  @override
  String get about_title => 'အကြောင်း';

  @override
  String get about_connect_with_us => 'ကျွန်ုပ်တို့နှင့် ဆက်သွယ်ပါ...';

  @override
  String get about_description =>
      'ကျွန်ုပ်တို့သည် ဗုဒ္ဓဘာသာဝင်များ နေ့စဉ် လေ့လာခြင်း၊ ကျင့်ကြံခြင်းနှင့် ချိတ်ဆက်ခြင်းဖြင့် သူတစ်ပါးကို ထိခိုက်မှု နည်းပါးစေရန်၊ ကောင်းမှု ပိုမိုပြုနိုင်စေရန်နှင့် မိမိစိတ်ကို ပိုမိုသိမြင်နိုင်စေရန် ကူညီပါသည်။';

  @override
  String get about_social_website => 'ဝက်ဘ်ဆိုက်';

  @override
  String get me_guest_headline => 'လုပ်ဆောင်ချက်အားလုံးကို အသုံးပြုပါ';

  @override
  String get me_guest_subtitle =>
      'သင့်တိုးတက်မှုကို သိမ်းရန် အခမဲ့ အကောင့်ဖွင့်ပါ';

  @override
  String get me_my_stats => 'ကျွန်ုပ်၏ စာရင်းအင်း';

  @override
  String me_day_streak(int count) {
    return '$count ရက် ဆက်တိုက်';
  }

  @override
  String me_best_streak(int count) {
    return 'အရှည်ဆုံး ဆက်တိုက်ကျင့်ကြံမှု: $count ရက်';
  }

  @override
  String get accumulations => 'စုဆောင်းမှုများ';

  @override
  String get accumulations_search => 'စုဆောင်းမှုများ ရှာဖွေရန်...';

  @override
  String get accumulations_search_for => 'စုဆောင်းမှုများ ရှာဖွေရန်';

  @override
  String get accumulations_no_found => 'စုဆောင်းမှု မတွေ့ပါ';

  @override
  String get me_accumulation => 'စုစုပေါင်း စုဆောင်းမှု';

  @override
  String get me_minutes => 'မိနစ်';

  @override
  String get me_hours => 'နာရီ';

  @override
  String get me_total_meditation_time => 'စုစုပေါင်း တရားထိုင်ချိန်';

  @override
  String get me_days_plan_practiced_suffix =>
      'ပြီးမြောက်ခဲ့သော သင်ခန်းစာအစီအစဉ် ရက်ပေါင်း';

  @override
  String get me_streak_share_quote =>
      'WeBuddhist တွင် ကျွန်ုပ်၏ လက်ရှိ ဆက်တိုက်ကျင့်ကြံမှု!';

  @override
  String me_streak_days_count(int count) {
    return '$count ရက်';
  }

  @override
  String get share_this_streak => 'ကျွန်ုပ်၏ ဆက်တိုက်ကျင့်ကြံမှုကို မျှဝေရန်';

  @override
  String get me_streak_share_error =>
      'ဆက်တိုက်ကျင့်ကြံမှုကို မျှဝေ၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get delete_account_title => 'အကောင့် ဖျက်ရန်';

  @override
  String get delete_account_description =>
      'သင့်အကောင့်ကို ဖျက်လိုက်ပါက WeBuddhist ရှိ သင့်အချက်အလက်၊ မှတ်တမ်းနှင့် စိတ်ကြိုက်ဆက်တင်များ အားလုံး အပြီးတိုင် ပျက်သွားပါမည်။ ဤလုပ်ဆောင်ချက်ကို နောက်ပြန်ဆုတ်၍ မရကြောင်း သတိပြုပါ။ ဆက်လုပ်ရန် အောက်ပါခလုတ်ကို နှိပ်ပါ။';

  @override
  String get delete_account_button => 'အကောင့် ဖျက်ရန်';

  @override
  String get delete_account_confirm_message =>
      'သင်၏ WeBuddhist အကောင့်ကို ဖျက်မှာ သေချာပါသလား။';

  @override
  String get legal_title => 'ဥပဒေဆိုင်ရာ';

  @override
  String get legal_terms_of_service => 'ဝန်ဆောင်မှု စည်းမျဉ်းများ';

  @override
  String get legal_privacy_policy => 'ကိုယ်ရေးအချက်အလက် မူဝါဒ';

  @override
  String get follow => 'စောင့်ကြည့်ရန်';

  @override
  String get calendar_title => 'ပြက္ခဒိန်';

  @override
  String get calendar_upcoming_events => 'လာမည့် ပွဲများ';

  @override
  String get calendar_day_short => 'ရက်';

  @override
  String get calendar_day_label => 'ရက်';

  @override
  String calendar_lunar_month(String ordinal) {
    return '$ordinal စန္ဒရလ';
  }

  @override
  String get moon_phase_new_moon => 'လကွယ်';

  @override
  String get moon_phase_first_quarter => 'လဆန်း လဝက်';

  @override
  String get moon_phase_full_moon => 'လပြည့်';

  @override
  String get join => 'ပါဝင်ရန်';

  @override
  String get group_member => 'အဖွဲ့ဝင်';

  @override
  String get group_members => 'အဖွဲ့ဝင်';

  @override
  String get group_tab_members => 'အဖွဲ့ဝင်များ';

  @override
  String get group_tab_followers => 'စောင့်ကြည့်သူများ';

  @override
  String group_members_heading(int count) {
    return 'အဖွဲ့ဝင်များ ($count)';
  }

  @override
  String group_followers_heading(int count) {
    return 'စောင့်ကြည့်သူများ ($count)';
  }

  @override
  String get group_invite => 'ဖိတ်ခေါ်ရန်';

  @override
  String get group_notifications_title => 'အသိပေးချက်များ';

  @override
  String get group_notifications_chat => 'အဖွဲ့ ချတ်';

  @override
  String get group_notifications_content => 'အဖွဲ့ အကြောင်းအရာ';

  @override
  String get group_notifications_master_off =>
      'အက်ပ်အတွက် အသိပေးချက်များကို ပိတ်ထားပါသည်';

  @override
  String get group_notifications_open_settings => 'ဖွင့်ရန်';

  @override
  String get group_notifications_update_failed =>
      'အသိပေးချက် ဆက်တင်များကို ပြင်ဆင်၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get group_notifications_load_failed =>
      'အသိပေးချက် ဆက်တင်များကို ဖွင့်၍ မရပါ';

  @override
  String get group_chat_mute_notifications => 'ချတ် အသိပေးချက်များကို ပိတ်ရန်';

  @override
  String get group_chat_unmute_notifications =>
      'ချတ် အသိပေးချက်များကို ဖွင့်ရန်';

  @override
  String get group_chat_notifications_muted =>
      'ချတ် အသိပေးချက်များကို ပိတ်ထားပါသည်';

  @override
  String get group_chat_notifications_unmuted =>
      'ချတ် အသိပေးချက်များ ဖွင့်ထားပါသည်';

  @override
  String get group_leave_confirm_message =>
      'ဤအဖွဲ့ထံမှ မက်ဆေ့ချ်များနှင့် အပ်ဒိတ်များ ရရှိတော့မည် မဟုတ်ပါ';

  @override
  String get group_leave_space => 'အဖွဲ့မှ ထွက်ရန်';

  @override
  String get group_leave_space_confirm_title => 'ဤအဖွဲ့မှ ထွက်မလား။';

  @override
  String get group_leave_space_failed => 'အဖွဲ့မှ ထွက်၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get group_request_to_join => 'ပါဝင်ခွင့် တောင်းရန်';

  @override
  String get group_request => 'ပါဝင်ခွင့် တောင်းရန်';

  @override
  String get group_request_sent => 'တောင်းဆိုချက် ပို့ပြီးပါပြီ';

  @override
  String get group_join_request_title => 'ပါဝင်ခွင့် တောင်းရန်';

  @override
  String get group_join_request_message_label => 'မက်ဆေ့ချ် (ရွေးချယ်နိုင်)';

  @override
  String get group_join_request_message_hint =>
      'သင် ဘယ်လို ကျင့်ကြံလဲ၊ သို့မဟုတ် ဘယ်သူက ဖိတ်ခေါ်တာလဲ။';

  @override
  String get group_join_request_send => 'တောင်းဆိုချက် ပို့ရန်';

  @override
  String get group_join_request_sent_snackbar =>
      'တောင်းဆိုချက် ပို့ပြီးပါပြီ။ စီမံသူက စိစစ်ပါမည်';

  @override
  String get group_join_request_error =>
      'တောင်းဆိုချက် ပို့၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get group_join_requests_title => 'ပါဝင်ရန် တောင်းဆိုချက်များ';

  @override
  String get group_join_requests_admit => 'လက်ခံရန်';

  @override
  String get group_join_requests_deny => 'ငြင်းပယ်ရန်';

  @override
  String get group_join_requests_empty =>
      'စောင့်ဆိုင်းနေသော တောင်းဆိုချက် မရှိပါ';

  @override
  String get group_join_requests_load_error =>
      'ပါဝင်ရန် တောင်းဆိုချက်များကို ဖွင့်၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get group_join_requests_admit_error =>
      'ဤတောင်းဆိုချက်ကို လက်ခံ၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get group_join_requests_deny_error =>
      'ဤတောင်းဆိုချက်ကို ငြင်းပယ်၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get group_reports_title => 'တိုင်ကြားချက်များ';

  @override
  String get group_reports_section_posts => 'ပို့စ်များ';

  @override
  String get group_reports_section_comments => 'မှတ်ချက်များ';

  @override
  String get group_reports_section_messages => 'မက်ဆေ့ချ်များ';

  @override
  String group_reports_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'တိုင်ကြားချက် $count ခု',
      one: 'တိုင်ကြားချက် 1 ခု',
    );
    return '$_temp0';
  }

  @override
  String get group_reports_view_post => 'ပို့စ် ကြည့်ရန်';

  @override
  String get group_reports_view_message => 'မက်ဆေ့ချ် ကြည့်ရန်';

  @override
  String get group_reports_delete_post => 'ပို့စ် ဖျက်ရန်';

  @override
  String get group_reports_delete_comment => 'မှတ်ချက် ဖျက်ရန်';

  @override
  String get group_reports_delete_message => 'မက်ဆေ့ချ် ဖျက်ရန်';

  @override
  String get group_reports_empty => 'စိစစ်ရန် တိုင်ကြားချက် မရှိပါ';

  @override
  String get group_reports_load_error =>
      'တိုင်ကြားချက်များကို ဖွင့်၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get group_reports_delete_confirm_title => 'သေချာပါသလား။';

  @override
  String get group_reports_delete_message_confirm =>
      'ဤမက်ဆေ့ချ်ကို အပြီးတိုင် ဖယ်ရှားပါမည်';

  @override
  String get group_reports_message_removed => 'မက်ဆေ့ချ်ကို ဖယ်ရှားပြီးပါပြီ';

  @override
  String get group_reports_delete_message_error =>
      'မက်ဆေ့ချ်ကို ဖျက်၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get group_members_only_title => 'အဖွဲ့ဝင်များသာ';

  @override
  String get group_members_only_message =>
      'အကြောင်းအရာများ ကြည့်ရန် ဤအဖွဲ့တွင် ပါဝင်ပါ';

  @override
  String get group_join_request_waiting_title => 'စီမံသူကို စောင့်နေသည်';

  @override
  String get group_join_request_waiting_message =>
      'သင့်တောင်းဆိုချက်ကို စိစစ်ပြီးသည့်အခါ အသိပေးပါမည်';

  @override
  String get group_members_load_error =>
      'အဖွဲ့ဝင်များကို ဖွင့်၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get group_followers_load_error =>
      'စောင့်ကြည့်သူများကို ဖွင့်၍ မရပါ။ ထပ်ကြိုးစားပါ။';

  @override
  String get group_members_empty => 'အဖွဲ့ဝင် မရှိသေးပါ';

  @override
  String get group_member_admin => 'စီမံသူ';

  @override
  String get group_member_owner => 'ပိုင်ရှင်';

  @override
  String group_remove_member(String name) {
    return '$name ကို ဖယ်ရှားရန်';
  }

  @override
  String get group_remove_member_title => 'အဖွဲ့မှ ဖယ်ရှားမလား။';

  @override
  String group_remove_member_message(String name) {
    return '$name ကို ဤအဖွဲ့မှ ဖယ်ရှားမည်ဖြစ်ပြီး ပိတ်ပင်မှု မရုပ်သိမ်းမချင်း ပြန်ဝင်၍ မရပါ';
  }

  @override
  String get group_remove_member_blocked_for => 'ပိတ်ပင်မည့် ကာလ:';

  @override
  String get group_remove_member_duration_day => '1 ရက်';

  @override
  String group_remove_member_duration_days(int count) {
    return '$count ရက်';
  }

  @override
  String get group_remove_member_duration_year => '1 နှစ်';

  @override
  String get group_remove_member_reason_label => 'အကြောင်းရင်း (ရွေးချယ်နိုင်)';

  @override
  String get group_remove_member_reason_hint => 'အခြားအကြောင်းအရာ...';

  @override
  String get group_remove_member_action => 'ဖယ်ရှားရန်';

  @override
  String group_remove_member_success(String name) {
    return '$name ကို အဖွဲ့မှ ဖယ်ရှားလိုက်ပါပြီ';
  }

  @override
  String get group_remove_member_error =>
      'ဤအဖွဲ့ဝင်ကို ဖယ်ရှား၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String group_join_banned_until(String date) {
    return 'သင့်ကို ဤအဖွဲ့မှ ဖယ်ရှားထားသဖြင့် $date အထိ ပြန်ဝင်၍ မရပါ';
  }

  @override
  String get group_join_banned =>
      'သင့်ကို ဤအဖွဲ့မှ ဖယ်ရှားထားသဖြင့် ပိတ်ပင်မှု မရုပ်သိမ်းမချင်း ပြန်ဝင်၍ မရပါ';

  @override
  String get group_removed_title => 'သင့်ကို ဤအဖွဲ့မှ ဖယ်ရှားလိုက်ပါပြီ';

  @override
  String group_removed_message(String group, String duration) {
    return '$group ၏ စီမံသူတစ်ဦးက သင့်ကို ဤအဖွဲ့မှ ဖယ်ရှားလိုက်ပါသည်။ $duration ကြာ ၎င်း၏ ပို့စ်များ၊ ပွဲများနှင့် ကျင့်စဉ်များကို ကြည့်ရှုခြင်း သို့မဟုတ် ပြန်ဝင်ခွင့် တောင်းခြင်း မပြုနိုင်ပါ။';
  }

  @override
  String group_removed_message_no_date(String group) {
    return '$group ၏ စီမံသူတစ်ဦးက သင့်ကို ဤအဖွဲ့မှ ဖယ်ရှားလိုက်ပါသည်။ ၎င်း၏ ပို့စ်များ၊ ပွဲများနှင့် ကျင့်စဉ်များကို ကြည့်ရှုခြင်း သို့မဟုတ် ပြန်ဝင်ခွင့် တောင်းခြင်း မပြုနိုင်ပါ';
  }

  @override
  String get group_removed_rejoin_label =>
      'ဤအဖွဲ့တွင် ပြန်ဝင်ခွင့် တောင်းနိုင်မည့်ရက်';

  @override
  String group_removed_rejoin_value(String date, String remaining) {
    return '$date · $remaining';
  }

  @override
  String get group_removed_day_left => '1 ရက် ကျန်သည်';

  @override
  String group_removed_days_left(int count) {
    return '$count ရက် ကျန်သည်';
  }

  @override
  String get group_removed_last_day => 'တစ်ရက်အောက် ကျန်သည်';

  @override
  String get group_followers_empty => 'စောင့်ကြည့်သူ မရှိသေးပါ';

  @override
  String get group_follower => 'စောင့်ကြည့်သူ';

  @override
  String get group_followers => 'စောင့်ကြည့်သူ';

  @override
  String get group_links_title => 'လင့်ခ်များ';

  @override
  String get group_about_description => 'ဖော်ပြချက်';

  @override
  String get group_about_empty => 'အချက်အလက် မရှိသေးပါ';

  @override
  String group_and_more_links(int count) {
    return 'နှင့် နောက်ထပ် လင့်ခ် $count ခု';
  }

  @override
  String get group_practice_with_us => 'ကျွန်ုပ်တို့နှင့်အတူ ကျင့်ကြံပါ';

  @override
  String series_practicing_with_group(String groupName) {
    return '$groupName နှင့်အတူ ကျင့်ကြံနေသည်';
  }

  @override
  String get group_change_practice_title => 'ကျင့်ကြံမည့် အဖွဲ့ ပြောင်းရန်';

  @override
  String get group_change_practice_message =>
      'ဤသင်ခန်းစာအစီအစဉ်ကို အခြားအဖွဲ့တစ်ခုနှင့် ကျင့်ကြံနေပြီး ဖြစ်ပါသည်။ ကျင့်ကြံမည့် အဖွဲ့ကို ပြောင်းလိုပါသလား။';

  @override
  String get group_join_to_contribute => 'ပံ့ပိုးရန် ပါဝင်ပါ';

  @override
  String get group_accumulator_join_error =>
      'စုဆောင်းမှုတွင် ပါဝင်၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get group_accumulator_join_before_practice =>
      'သင့်ကျင့်စဉ်များထဲ မထည့်မီ ဤစုဆောင်းမှုတွင် ပါဝင်ပါ';

  @override
  String group_accumulator_participants(int count) {
    return 'ပါဝင်သူ $count ဦး';
  }

  @override
  String get group_accumulator_leaderboard => 'အဆင့်ဇယား';

  @override
  String get group_accumulator_everyone => 'အားလုံး';

  @override
  String get group_accumulator_me => 'ကျွန်ုပ်';

  @override
  String get group_accumulator_my_contributions => 'ကျွန်ုပ်၏ ပါဝင်မှုများ';

  @override
  String get group_accumulator_recited => 'ရွတ်ဆိုမှုများ';

  @override
  String get group_accumulator_total => 'စုစုပေါင်း';

  @override
  String get group_accumulator_contributions_empty =>
      'သင်၏ ပါဝင်မှုများကို မှတ်တမ်းတင်ရန် ဤစုဆောင်းမှုတွင် ပါဝင်ပါ';

  @override
  String get group_accumulator_leaderboard_empty => 'ရွတ်ဆိုမှု မရှိသေးပါ';

  @override
  String get group_accumulator_recite_now => 'ယခု ရွတ်ဆိုရန်';

  @override
  String get group_accumulator_view_practice => 'ကျင့်စဉ် ကြည့်ရန်';

  @override
  String get group_accumulator_chant_again => 'ထပ်ရွတ်ရန်';

  @override
  String get group_accumulator_finish_session => 'ဤအကြိမ် ပြီးဆုံးရန်';

  @override
  String get group_accumulator_offline_recitation => 'အက်ပ်ပြင်ပ ရွတ်ဆိုမှု';

  @override
  String get group_accumulator_add_offline_chants_title =>
      'အက်ပ်ပြင်ပ ရွတ်ဆိုမှု ထည့်ရန်:';

  @override
  String get group_accumulator_add_offline_chants_message =>
      'အက်ပ်ပြင်ပတွင် ရွတ်ဆိုခဲ့သည့် အကြိမ်ရေကို ထည့်ပါ';

  @override
  String get group_accumulator_session_complete => 'ဤအကြိမ် ပြီးဆုံးပါပြီ!';

  @override
  String group_accumulator_session_recitations(int count) {
    return 'ဤအကြိမ်တွင် $count ကြိမ် ရွတ်ဆိုခဲ့ပါသည်';
  }

  @override
  String group_accumulator_session_share_message(
    int count,
    String accumulation,
    String group,
  ) {
    return 'WeBuddhist ပေါ်ရှိ $group ၏ စုဆောင်းမှုဖြစ်သော \"$accumulation\" တွင် $count ကြိမ် ရွတ်ဆိုပြီးပါပြီ။ ကျွန်ုပ်နှင့်အတူ လာရောက်ပါဝင်ပါ!';
  }

  @override
  String group_accumulator_session_share_message_no_group(
    int count,
    String accumulation,
  ) {
    return 'WeBuddhist ပေါ်ရှိ \"$accumulation\" စုဆောင်းမှုတွင် $count ကြိမ် ရွတ်ဆိုပြီးပါပြီ။ ကျွန်ုပ်နှင့်အတူ လာရောက်ပါဝင်ပါ!';
  }

  @override
  String get group_accumulator_session_share_error =>
      'ဤအကြိမ်ကို မျှဝေ၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String group_recitation_collection_share_message(
    String collection,
    String group,
  ) {
    return 'WeBuddhist ပေါ်ရှိ $group ၏ ရွတ်ဆိုရန်စာ စုစည်းမှုဖြစ်သော \"$collection\" ကို ကြည့်ပါ။ ကျွန်ုပ်တို့နှင့်အတူ ကျင့်ကြံပါ!';
  }

  @override
  String group_recitation_collection_share_message_no_group(String collection) {
    return 'WeBuddhist ပေါ်ရှိ \"$collection\" ရွတ်ဆိုရန်စာ စုစည်းမှုကို ကြည့်ပါ။ ကျွန်ုပ်တို့နှင့်အတူ ကျင့်ကြံပါ!';
  }

  @override
  String group_recitation_collection_completed_title(String collection) {
    return '$collection ပြီးဆုံးပါပြီ';
  }

  @override
  String get group_recitation_collection_dedication =>
      'ဤကုသိုလ်ကြောင့် သတ္တဝါအားလုံး\nဆင်းရဲဒုက္ခမှ လွတ်မြောက်ကြပါစေ';

  @override
  String get share_this_quote => 'ဤဆိုမိန့်ကို မျှဝေရန်';

  @override
  String get shared_from => 'မျှဝေထားသည့်နေရာ';

  @override
  String get verse_share_error => 'ဆိုမိန့်ကို မျှဝေ၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String verse_comments_title(int count) {
    return 'မှတ်ချက်များ · $count';
  }

  @override
  String verse_likes_title(int count) {
    return 'နှစ်သက်မှုများ · $count';
  }

  @override
  String get verse_like_failed => 'နှစ်သက်မှုကို ပြင်ဆင်၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get verse_comment_failed => 'မှတ်ချက်ကို တင်၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String verse_comment_replying_to(String name) {
    return '$name ကို ပြန်ကြားနေသည်';
  }

  @override
  String get share_app_message =>
      'နေ့စဉ် ဗုဒ္ဓဘာသာ ကျင့်စဉ် တည်ဆောက်ရန် ဤအက်ပ်ကို အသုံးပြုနေပြီး သင်လည်း နှစ်သက်မည်ဟု ထင်ပါသည်။';

  @override
  String get share_streak_message =>
      'နေ့စဉ် ကျင့်ကြံသည့် အလေ့အကျင့်ကို တည်ဆောက်နေပြီး သင့်ထံ မျှဝေလိုပါသည်။ မိတ်ဆွေနှင့်အတူဆိုလျှင် ဆက်လက်ထိန်းသိမ်းရန် ပိုလွယ်ပါသည်။ WeBuddhist တွင် ကျွန်ုပ်နှင့်အတူ ပါဝင်ပါ။';

  @override
  String get share_chant_message =>
      'ဤရွတ်ဆိုရန်စာကို သင့်ထံ မျှဝေလိုပါသည်။ WeBuddhist တွင် ၎င်းကို ကျင့်ကြံနိုင်ပြီး အခြား ရွတ်ဆိုရန်စာများနှင့် ကျမ်းစာများ စုစည်းထားသော စာကြည့်တိုက်တစ်ခုလုံးကိုလည်း တွေ့ရှိနိုင်ပါသည်။';

  @override
  String get share_quote_message =>
      'WeBuddhist မှ ဤဆိုမိန့်ကို နှစ်သက်သဖြင့် သင့်ထံ မျှဝေလိုပါသည်။ WeBuddhist အက်ပ်တွင် ဤကဲ့သို့ အသိဉာဏ်ပေးသော ဆိုမိန့်များကို ထပ်မံ ဖတ်ရှုပါ။';

  @override
  String get share_poem_message =>
      'WeBuddhist မှ ဤကဗျာကို နှစ်သက်သဖြင့် သင့်ထံ မျှဝေလိုပါသည်။';

  @override
  String share_poem_title(String title) {
    return '“$title”';
  }

  @override
  String get share_mala_message =>
      'WeBuddhist ရှိ ဤဒစ်ဂျစ်တယ် ပုတီးကို အသုံးပြုနေပြီး သင့်ထံ မျှဝေလိုပါသည်။ မည်သည့်နေရာတွင်မဆို လွယ်ကူစွာ ကျင့်ကြံနိုင်သော နည်းလမ်းဖြစ်ပါသည်။';

  @override
  String get share_passage_message =>
      'ဤစာပိုဒ်ကို နှစ်သက်သဖြင့် သင့်ထံ မျှဝေလိုပါသည်။ WeBuddhist တွင် ဆက်စပ်အကြောင်းအရာနှင့်အတူ အပြည့်အစုံ ဖတ်ရှုနိုင်ပါသည်။';

  @override
  String get share_timer_message =>
      'WeBuddhist မှ ဤတရားထိုင် အချိန်မှတ်စက်ကို သင့်ထံ မျှဝေလိုပါသည်။ တရားထိုင်ခြင်းကို အလေ့အကျင့်အဖြစ် လွယ်ကူစွာ တည်ဆောက်နိုင်ပါသည်။';

  @override
  String get share_plan_message =>
      'ဤဗုဒ္ဓဘာသာ ကျင့်စဉ် သင်ခန်းစာအစီအစဉ်ကို လိုက်နာနေပြီး သင့်ထံ မျှဝေလိုပါသည်။ WeBuddhist တွင် ကျွန်ုပ်နှင့်အတူ အခမဲ့ ပါဝင်နိုင်ပါသည်။';

  @override
  String get share_plan_subject => 'WeBuddhist တွင် ကျွန်ုပ်နှင့်အတူ ပါဝင်ပါ';

  @override
  String get share_group_invite_message =>
      'ဤအဖွဲ့တွင် ကျွန်ုပ်နှင့်အတူ ပါဝင်ပါ။ WeBuddhist တွင် အတူတကွ ကျင့်ကြံကြပါစို့!';

  @override
  String get weekday_monday => 'လာ';

  @override
  String get weekday_tuesday => 'ဂါ';

  @override
  String get weekday_wednesday => 'ဟူး';

  @override
  String get weekday_thursday => 'တေး';

  @override
  String get weekday_friday => 'ကြာ';

  @override
  String get weekday_saturday => 'နေ';

  @override
  String get weekday_sunday => 'နွေ';

  @override
  String get reader_search_failed => 'ရှာဖွေ၍ မရပါ။\nထပ်ကြိုးစားပါ';

  @override
  String get reader_swipe_up_for_more => 'ထပ်ကြည့်ရန် အပေါ်သို့ ပွတ်ဆွဲပါ';

  @override
  String get reader_videos => 'ဗီဒီယိုများ';

  @override
  String get mala_no_mantras => 'မန္တန် မရှိပါ';

  @override
  String get mala_count_load_error => 'သင့်အရေအတွက်ကို ဖွင့်၍ မရပါ';

  @override
  String get bookmarks_empty_all_title => 'မှတ်ထားသည့်အရာ မရှိသေးပါ';

  @override
  String get bookmarks_empty_all_subtitle =>
      'မည်သည့်အရာကိုမဆို မှတ်ထားပါက ဤနေရာတွင် သိမ်းထားပါမည်';

  @override
  String get bookmarks_empty_plans_title =>
      'မှတ်ထားသော သင်ခန်းစာအစီအစဉ် မရှိသေးပါ';

  @override
  String get bookmarks_empty_plans_subtitle =>
      'တစ်ခုကို မှတ်ထားပါက ဤနေရာတွင် သိမ်းထားပါမည်';

  @override
  String get bookmarks_empty_malas_title => 'မှတ်ထားသော ပုတီး မရှိသေးပါ';

  @override
  String get bookmarks_empty_malas_subtitle =>
      'တစ်ခုကို မှတ်ထားပါက ဤနေရာတွင် သိမ်းထားပါမည်';

  @override
  String get bookmarks_empty_group_accumulations_title =>
      'မှတ်ထားသော အဖွဲ့ စုဆောင်းမှု မရှိသေးပါ';

  @override
  String get bookmarks_empty_group_accumulations_subtitle =>
      'တစ်ခုကို မှတ်ထားပါက ဤနေရာတွင် သိမ်းထားပါမည်';

  @override
  String get bookmarks_empty_timers_title =>
      'မှတ်ထားသော အချိန်မှတ်စက် မရှိသေးပါ';

  @override
  String get bookmarks_empty_timers_subtitle =>
      'တစ်ခုကို မှတ်ထားပါက ဤနေရာတွင် သိမ်းထားပါမည်';

  @override
  String get bookmarks_empty_texts_title => 'မှတ်ထားသော ကျမ်းစာ မရှိသေးပါ';

  @override
  String get bookmarks_empty_texts_subtitle =>
      'တစ်ခုကို မှတ်ထားပါက ဤနေရာတွင် သိမ်းထားပါမည်';

  @override
  String get bookmark_removed => 'မှတ်ထားချက်ကို ဖယ်ရှားပြီးပါပြီ';

  @override
  String get bookmark_remove_failed => 'မှတ်ထားချက်ကို ဖယ်ရှား၍ မရပါ';

  @override
  String get bookmark_saved => 'မှတ်ထားချက်ကို သိမ်းပြီးပါပြီ';

  @override
  String get bookmark_save_failed => 'မှတ်ထားချက်ကို သိမ်း၍ မရပါ';

  @override
  String get bookmarks_yesterday => 'မနေ့က';

  @override
  String get webview_timeout_error =>
      'စာမျက်နှာ ဖွင့်ရန် အချိန်ကြာလွန်းပါသည်။ အင်တာနက်ချိတ်ဆက်မှုကို စစ်ဆေးပါ';

  @override
  String get webview_load_failed => 'စာမျက်နှာကို ဖွင့်၍ မရပါ';

  @override
  String get privacy_policy_load_error =>
      'ကိုယ်ရေးအချက်အလက် မူဝါဒ စာမျက်နှာကို ဖွင့်၍ မရပါ';

  @override
  String get terms_of_service_load_error =>
      'ဝန်ဆောင်မှု စည်းမျဉ်းများ စာမျက်နှာကို ဖွင့်၍ မရပါ';

  @override
  String get series_enroll_error => 'စီးရီးတွင် စာရင်းသွင်း၍ မရပါ';

  @override
  String series_share_message(String title, String url) {
    return 'WeBuddhist တွင် $title ကို ကျွန်ုပ်နှင့်အတူ ကျင့်ကြံပါ။\n\n$url';
  }

  @override
  String get player_back_10 => '10 စက္ကန့် နောက်ပြန်ရန်';

  @override
  String get player_pause => 'ခေတ္တရပ်ရန်';

  @override
  String get player_play => 'ဖွင့်ရန်';

  @override
  String get player_forward_10 => '10 စက္ကန့် ရှေ့သို့';

  @override
  String get player_fullscreen => 'မျက်နှာပြင်အပြည့်';

  @override
  String get player_exit_fullscreen => 'မျက်နှာပြင်အပြည့်မှ ထွက်ရန်';

  @override
  String get session_plans_load_error =>
      'သင်ခန်းစာအစီအစဉ်များကို ဖွင့်၍ မရပါ။\nနောက်မှ ထပ်ကြိုးစားပါ';

  @override
  String get session_chants_load_error => 'ရွတ်ဆိုရန်စာများကို ဖွင့်၍ မရပါ';

  @override
  String get session_no_chants => 'ရွတ်ဆိုရန်စာ မတွေ့ပါ';

  @override
  String get session_malas_load_error => 'ပုတီးများကို ဖွင့်၍ မရပါ';

  @override
  String get session_no_malas => 'ပုတီး မတွေ့ပါ';

  @override
  String get session_timers_load_error => 'အချိန်မှတ်စက်များကို ဖွင့်၍ မရပါ';

  @override
  String get session_no_timers => 'အချိန်မှတ်စက် မတွေ့ပါ';

  @override
  String days_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ရက်',
      one: '1 ရက်',
    );
    return '$_temp0';
  }

  @override
  String timer_minute_session(int minutes) {
    return '$minutes မိနစ် တရားထိုင်ချိန်';
  }

  @override
  String get timer_notification_in_progress => 'တရားထိုင်နေသည်';

  @override
  String timer_notification_paused(String time) {
    return 'ခေတ္တရပ်ထားသည် · $time ကျန်သည်';
  }

  @override
  String get timer_notification_complete => 'သင့်တရားထိုင်ချိန် ပြီးဆုံးပါပြီ';

  @override
  String plan_day_of(int day, int total) {
    return '$total ရက်အနက် $day ရက်မြောက်';
  }

  @override
  String pagination_position(int current, int total) {
    return '$current / $total';
  }

  @override
  String get plan_shorts_title => 'အသိုင်းအဝိုင်းမှ ဗီဒီယိုတိုများ';

  @override
  String get author_details_load_error =>
      'စာရေးသူ အချက်အလက်ကို ဖွင့်၍ မရပါ။\nထပ်ကြိုးစားပါ';

  @override
  String get link_cannot_open => 'ဤလင့်ခ်ကို ဖွင့်၍ မရပါ';

  @override
  String get link_invalid => 'URL မမှန်ကန်ပါ';

  @override
  String get author_no_plans => 'ဖန်တီးထားသော သင်ခန်းစာအစီအစဉ် မရှိသေးပါ';

  @override
  String get author_plans_load_error => 'သင်ခန်းစာအစီအစဉ်များကို ဖွင့်၍ မရပါ';

  @override
  String get drag_to_resize => 'အရွယ်အစားပြောင်းရန် ဆွဲပါ';

  @override
  String get day_completion_share_message =>
      'WeBuddhist တွင် ကျွန်ုပ်၏ ကျင့်စဉ် တစ်ရက်ကို ပြီးမြောက်ခဲ့ပါပြီ။ ကျွန်ုပ်နှင့်အတူ ပါဝင်ပြီး နေ့စဉ်ကျင့်ကြံသည့် အလေ့အကျင့်ကို အတူတကွ တည်ဆောက်ကြပါစို့။';

  @override
  String group_accumulator_share_message(String accumulation, String group) {
    return 'WeBuddhist ပေါ်ရှိ $group ၏ စုဆောင်းမှုဖြစ်သော \"$accumulation\" တွင် ကျွန်ုပ် ပါဝင်နေပါသည်။ ကျွန်ုပ်နှင့်အတူ လာရောက်ပါဝင်ပါ!';
  }

  @override
  String group_accumulator_share_message_no_group(String accumulation) {
    return 'WeBuddhist ပေါ်ရှိ \"$accumulation\" စုဆောင်းမှုတွင် ကျွန်ုပ် ပါဝင်နေပါသည်။ ကျွန်ုပ်နှင့်အတူ လာရောက်ပါဝင်ပါ!';
  }

  @override
  String get chats_title => 'ချတ်များ';

  @override
  String get chats_empty_title => 'ချတ် မရှိသေးပါ';

  @override
  String get chats_empty_body => 'ချတ်စတင်ရန် အဖွဲ့တစ်ခုတွင် ပါဝင်ပါ';

  @override
  String get group_chat_inappropriate =>
      'ခွင့်မပြုထားသော စကားလုံးများ ပါဝင်သဖြင့် ဤမက်ဆေ့ချ်ကို ပို့၍ မရပါ';

  @override
  String get group_chat_not_a_member =>
      'အဖွဲ့ဝင်များသာ ဤချတ်ကို ဖွင့်နိုင်ပါသည်';

  @override
  String get group_chat_open => 'ချတ်';

  @override
  String get group_chat_message_hint => 'မက်ဆေ့ချ်';

  @override
  String get group_chat_today => 'ယနေ့';

  @override
  String get group_chat_yesterday => 'မနေ့က';

  @override
  String get group_chat_empty_title => 'မက်ဆေ့ချ် မရှိသေးပါ';

  @override
  String get group_chat_empty_body => 'သင့်အဖွဲ့နှင့် စကားစတင်ပြောပါ';

  @override
  String get group_chat_load_failed => 'မက်ဆေ့ချ်များကို ဖွင့်၍ မရပါ';

  @override
  String get chat_room_closed => 'This chat has been closed.';

  @override
  String get group_chat_message_not_found => 'ဤမက်ဆေ့ချ် ချတ်တွင် မရှိတော့ပါ';

  @override
  String get group_chat_message_too_far_back =>
      'ဤမက်ဆေ့ချ်သည် ချတ်၏ အရင်ပိုင်းတွင် ရှိပါသည်';

  @override
  String get group_chat_keep_looking => 'ဆက်ရှာရန်';

  @override
  String get group_chat_retry => 'ထပ်ကြိုးစားပါ';

  @override
  String get group_chat_unknown_sender => 'အဖွဲ့ဝင်';

  @override
  String get group_chat_reactions_all => 'အားလုံး';

  @override
  String get group_chat_reacted => 'တုံ့ပြန်ခဲ့သည်';

  @override
  String get group_chat_reply => 'ပြန်ကြားရန်';

  @override
  String get group_chat_copy => 'ကူးယူရန်';

  @override
  String get group_chat_copied => 'မက်ဆေ့ချ်ကို ကူးယူပြီးပါပြီ';

  @override
  String get group_chat_report => 'တိုင်ကြားရန်';

  @override
  String get group_chat_report_title => 'ဘာကြောင့် တိုင်ကြားတာလဲ။';

  @override
  String get group_chat_report_privacy => 'သင့်အမည်ကို လျှို့ဝှက်ထားပါမည်';

  @override
  String get group_chat_report_reason_harassment =>
      'နှောင့်ယှက်ခြင်း သို့မဟုတ် အနိုင်ကျင့်ခြင်း';

  @override
  String get group_chat_report_reason_hate =>
      'အမုန်းစကား သို့မဟုတ် ထိခိုက်စေသော စကား';

  @override
  String get group_chat_report_reason_sexual =>
      'လိင်ပိုင်းဆိုင်ရာ သို့မဟုတ် ညစ်ညမ်းသော အကြောင်းအရာ';

  @override
  String get group_chat_report_reason_spam => 'စပမ် သို့မဟုတ် လိမ်လည်မှု';

  @override
  String get group_chat_report_reason_off_topic =>
      'အကြောင်းအရာနှင့် မသက်ဆိုင်ခြင်း သို့မဟုတ် အနှောင့်အယှက်ဖြစ်စေခြင်း';

  @override
  String get group_chat_report_reason_other => 'အခြား';

  @override
  String get group_chat_report_note_title => 'မှတ်စု ထည့်ရန်';

  @override
  String get group_chat_report_note_hint => 'အခြားအကြောင်းအရာ...';

  @override
  String get group_chat_report_submit => 'တိုင်ကြားချက် ပေးပို့ရန်';

  @override
  String get group_chat_report_thanks => 'အကြံပြုချက်အတွက် ကျေးဇူးတင်ပါသည်';

  @override
  String get group_chat_report_offline =>
      'အင်တာနက် ချိတ်ဆက်မှု မရှိပါ။ နောက်မှ ထပ်ကြိုးစားပါ';

  @override
  String get group_chat_report_failed => 'တိုင်ကြားချက် ပို့၍ မရပါ';

  @override
  String get group_chat_report_retry => 'ထပ်ကြိုးစားပါ';

  @override
  String get group_chat_delete => 'ဖျက်ရန်';

  @override
  String get group_chat_delete_title => 'မက်ဆေ့ချ်ကို ဖျက်မလား။';

  @override
  String group_chat_delete_title_many(int count) {
    return 'မက်ဆေ့ချ် $count ခုကို ဖျက်မလား။';
  }

  @override
  String group_chat_delete_confirm_body(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ဤမက်ဆေ့ချ်များကို လူတိုင်းအတွက် ချတ်မှ ဖယ်ရှားပါမည်',
      one: 'ဤမက်ဆေ့ချ်ကို လူတိုင်းအတွက် ချတ်မှ ဖယ်ရှားပါမည်',
    );
    return '$_temp0';
  }

  @override
  String group_chat_delete_failed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'မက်ဆေ့ချ် $count ခုကို ဖျက်၍ မရပါ',
      one: 'မက်ဆေ့ချ်ကို ဖျက်၍ မရပါ',
    );
    return '$_temp0';
  }

  @override
  String group_chat_selection_limit(int count) {
    return 'မက်ဆေ့ချ် $count ခုအထိ ရွေးနိုင်ပါသည်';
  }

  @override
  String get group_chat_message_deleted_by_sender =>
      'ဤမက်ဆေ့ချ်ကို ဖျက်ထားပါသည်';

  @override
  String get group_chat_reaction_failed => 'သင့်တုံ့ပြန်မှုကို သိမ်း၍ မရပါ';

  @override
  String group_chat_reactions_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'တုံ့ပြန်မှု $count ခု',
      one: 'တုံ့ပြန်မှု 1 ခု',
    );
    return '$_temp0';
  }

  @override
  String get group_chat_you => 'သင်';

  @override
  String get group_chat_tap_to_remove => 'ဖယ်ရှားရန် နှိပ်ပါ';

  @override
  String get group_chat_reply_parent_gone =>
      'ထိုမက်ဆေ့ချ် မရှိတော့သဖြင့် ကိုးကားချက်ကို ဖယ်ရှားလိုက်ပါသည်။ သင့်မက်ဆေ့ချ်ကို တင်ရန် ထပ်ပို့ပါ';

  @override
  String get group_tab_posts => 'ပို့စ်များ';

  @override
  String get group_tab_events => 'ပွဲများ';

  @override
  String get group_posts_empty_title => 'ပို့စ် မရှိသေးပါ';

  @override
  String get group_posts_empty_message => 'သင့်အဖွဲ့၏ ပထမဆုံး သတင်းကို မျှဝေပါ';

  @override
  String get group_posts_load_error =>
      'ပို့စ်များကို ဖွင့်၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get group_post_button => 'ပို့စ်တင်ရန်';

  @override
  String get group_post_new_title => 'ပို့စ်အသစ်';

  @override
  String get group_post_posting_to => 'တင်မည့်နေရာ:';

  @override
  String get group_post_caption_hint => 'ဘာအသစ်တွေ ရှိလဲ။';

  @override
  String get group_post_photos => 'ဓာတ်ပုံများ';

  @override
  String get group_post_link => 'လင့်ခ်';

  @override
  String get group_post_discard_title => 'ပို့စ်ကို စွန့်ပယ်မလား။';

  @override
  String get group_post_discard_message => 'သင်ရေးထားသည်များ ပျောက်သွားပါမည်';

  @override
  String get group_post_keep_editing => 'ဆက်ပြင်ဆင်ရန်';

  @override
  String get group_post_discard => 'စွန့်ပယ်ရန်';

  @override
  String get group_post_add_link_title => 'လင့်ခ် ထည့်ရန်';

  @override
  String get group_post_add_link_hint =>
      'လင့်ခ်ကို ကူးထည့်ပါက အစမ်းကြည့်ပုံ ပြသပေးပါမည်';

  @override
  String get group_post_link_field_hint => 'လင့်ခ်';

  @override
  String get group_post_attach => 'ပူးတွဲရန်';

  @override
  String get group_post_attach_as_link => 'လင့်ခ်အဖြစ် ပူးတွဲရန်';

  @override
  String get group_post_preview_failed_title => 'အစမ်းကြည့်ပုံကို ဖွင့်၍ မရပါ';

  @override
  String get group_post_preview_failed_message =>
      'လင့်ခ်အဖြစ် ပူးတွဲနိုင်ပါသေးသည်';

  @override
  String get group_post_invalid_link =>
      'မှန်ကန်သော လင့်ခ် ထည့်ပါ၊ ဥပမာ - https://example.com';

  @override
  String get group_post_in_app_content => 'အက်ပ်အတွင်းရှိ အကြောင်းအရာ';

  @override
  String get group_post_add_in_app_content_title =>
      'အက်ပ်အတွင်းရှိ အကြောင်းအရာ ထည့်ရန်';

  @override
  String get group_post_in_app_content_empty => 'ထည့်ရန် မရှိသေးပါ';

  @override
  String group_post_photo_limit(int count) {
    return 'ဓာတ်ပုံ $count ပုံအထိ ထည့်နိုင်ပါသည်';
  }

  @override
  String get group_post_upload_error =>
      'ဓာတ်ပုံများကို တင်၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get group_post_publish_error =>
      'သင့်ပို့စ်ကို တင်၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get group_post_published => 'သင့်ပို့စ်ကို တင်ပြီးပါပြီ။';

  @override
  String get group_post_delete_title => 'ပို့စ်ကို ဖျက်မလား။';

  @override
  String get group_post_delete_message => 'ဤပို့စ်ကို အပြီးတိုင် ဖယ်ရှားပါမည်';

  @override
  String get group_post_delete_failed => 'ပို့စ်ကို ဖျက်၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get edit => 'ပြင်ဆင်ရန်';

  @override
  String get group_post_edit_title => 'ပို့စ် ပြင်ဆင်ရန်';

  @override
  String get group_post_update_error =>
      'သင့်ပြောင်းလဲမှုများကို သိမ်း၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get group_post_updated => 'သင့်ပြောင်းလဲမှုများကို သိမ်းပြီးပါပြီ';

  @override
  String get practice_collection_already_added =>
      'ဤစုစည်းမှုသည် သင့်ကျင့်စဉ်များထဲတွင် ရှိပြီးသားဖြစ်ပါသည်';

  @override
  String get practice_group_accumulator_already_added =>
      'ဤစုဆောင်းမှုသည် သင့်ကျင့်စဉ်များထဲတွင် ရှိပြီးသားဖြစ်ပါသည်';

  @override
  String get event_live_badge => 'တိုက်ရိုက်';

  @override
  String get event_live_video_mode => 'ဗီဒီယို';

  @override
  String get event_live_audio_mode => 'အသံ';

  @override
  String get event_live_go_live => 'တိုက်ရိုက်';

  @override
  String get event_replays => 'ပြန်ကြည့်ရန်';

  @override
  String event_replay_session(String day, String session) {
    return 'ရက် $day · အပိုင်း $session';
  }

  @override
  String get event_replay_recording => 'ရိုက်ကူးမှတ်တမ်း';

  @override
  String get event_replay_back_to_live => 'တိုက်ရိုက်သို့ ပြန်သွားရန်';

  @override
  String get event_replays_empty => 'ရိုက်ကူးမှတ်တမ်း မရှိသေးပါ';

  @override
  String get event_puja_starts_in => 'ပူဇော်ပွဲ စတင်ရန် ကျန်ချိန်';

  @override
  String get event_puja_not_started => 'ပူဇော်ပွဲ မစတင်သေးပါ';

  @override
  String get event_prayer_requests => 'ဆုတောင်းပေးရန် တောင်းဆိုချက်များ';

  @override
  String event_prayer_request_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'တောင်းဆိုချက် $count ခု',
      one: 'တောင်းဆိုချက် 1 ခု',
    );
    return '$_temp0';
  }

  @override
  String get event_prayer_empty_title =>
      'ဆုတောင်းပေးရန် တောင်းဆိုချက် မရှိသေးပါ';

  @override
  String get event_prayer_empty_body =>
      'သင့်တောင်းဆိုချက်နှင့် သင့်အဖွဲ့၏ တောင်းဆိုချက်များ ဤနေရာတွင် ပေါ်လာပါမည်';

  @override
  String get event_prayer_add => 'ဆုတောင်းပေးရန် တောင်းဆိုချက် ထည့်ရန်';

  @override
  String get event_prayer_hint => 'ဆုတောင်းပေးရန် တောင်းဆိုချက် မျှဝေပါ';

  @override
  String event_prayer_hint_intention(String topics) {
    return '$topics အတွက် ဆုတောင်းပေးရန် တောင်းဆိုပါ';
  }

  @override
  String get event_prayer_load_failed =>
      'ဆုတောင်းပေးရန် တောင်းဆိုချက်များကို ဖွင့်၍ မရပါ';

  @override
  String get event_prayer_closed =>
      'ဤပွဲအတွက် ဆုတောင်းပေးရန် တောင်းဆိုချက်များကို ပိတ်ထားပါသည်';

  @override
  String get group_prayer_closed =>
      'ဤအဖွဲ့အတွက် ဆုတောင်းပေးရန် တောင်းဆိုချက်များကို ပိတ်ထားပါသည်';

  @override
  String get group_prayer_delete_body =>
      'ဤအဖွဲ့ရှိ လူတိုင်းအတွက် ဖယ်ရှားသွားပါမည်။';

  @override
  String get event_prayer_pray => 'ဆုတောင်းရန်';

  @override
  String event_prayer_my_count(int count) {
    return '+$count';
  }

  @override
  String get event_prayer_new_request => 'ဆုတောင်းပေးရန် တောင်းဆိုချက်အသစ်';

  @override
  String get event_prayer_edit_request =>
      'ဆုတောင်းပေးရန် တောင်းဆိုချက် ပြင်ဆင်ရန်';

  @override
  String get event_prayer_delete_title =>
      'ဆုတောင်းပေးရန် တောင်းဆိုချက်ကို ဖျက်မလား။';

  @override
  String get event_prayer_delete_body =>
      'ဤပွဲရှိ လူတိုင်းအတွက် ဖယ်ရှားသွားပါမည်။';

  @override
  String get event_prayer_delete_failed =>
      'ဆုတောင်းပေးရန် တောင်းဆိုချက်ကို ဖျက်၍ မရပါ';

  @override
  String get event_prayer_choose_intention => 'ရည်ရွယ်ချက် ရွေးပါ';

  @override
  String get event_prayer_intentions_failed => 'ရည်ရွယ်ချက်များကို ဖွင့်၍ မရပါ';

  @override
  String get event_prayer_request_button => 'ဆုတောင်းပေးရန် တောင်းဆိုရန်';

  @override
  String get event_prayer_you => 'သင်';

  @override
  String get event_prayer_waiting_first =>
      'ပထမဆုံး ဆုတောင်းမှုကို စောင့်နေသည်...';

  @override
  String event_prayer_more_praying(int count) {
    return '+$count ဦး ထပ်မံ ဆုတောင်းပေးခဲ့သည်';
  }

  @override
  String event_prayer_people_praying(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ဦး ဆုတောင်းပေးခဲ့သည်',
      one: '$count ဦး ဆုတောင်းပေးခဲ့သည်',
    );
    return '$_temp0';
  }

  @override
  String get event_prayer_praying_for_you => 'သင့်အတွက် ဆုတောင်းပေးခဲ့သည်';

  @override
  String get event_prayer_your_request => 'သင့်တောင်းဆိုချက်';

  @override
  String get event_prayer_supporters_failed =>
      'ဆုတောင်းပေးသူများကို ဖွင့်၍ မရပါ။';

  @override
  String get event_prayer_no_supporters => 'ဆုတောင်းပေးသူ မရှိသေးပါ';

  @override
  String get event_prayer_sort_by => 'ဆုတောင်းပေးရန်';

  @override
  String get event_prayer_sort_needs_prayers => 'ဆုတောင်းပေးရန် လိုအပ်သည်';

  @override
  String get event_prayer_sort_most_prayed => 'ဆုတောင်းမှု အများဆုံး';

  @override
  String get event_prayer_sort_newest => 'အသစ်ဆုံး';

  @override
  String get event_prayer_sort_oldest => 'အဟောင်းဆုံး';

  @override
  String get event_prayer_sort_by_intention => 'ရည်ရွယ်ချက်အလိုက်';

  @override
  String get event_prayer_clear_intention => 'ရည်ရွယ်ချက် ဖယ်ရှားရန်';

  @override
  String get event_prayer_filter_empty_title =>
      'ကိုက်ညီသော တောင်းဆိုချက် မရှိပါ';

  @override
  String get event_prayer_filter_empty_body =>
      'အခြား စီစဉ်ပုံ သို့မဟုတ် ရည်ရွယ်ချက်ကို စမ်းကြည့်ပါ';

  @override
  String get event_prayer_see_translation => 'ဘာသာပြန် ကြည့်ရန်';

  @override
  String get event_prayer_see_original => 'မူရင်း ကြည့်ရန်';

  @override
  String event_prayer_translated_from(String language) {
    return '$language မှ ဘာသာပြန်ထားသည်';
  }

  @override
  String get event_prayer_translated => 'ဘာသာပြန်ထားသည်';

  @override
  String get event_prayer_sort_mine => 'ကျွန်ုပ်၏ ဆုတောင်းချက်များ';

  @override
  String get event_prayer_section_active => 'လက်ရှိ';

  @override
  String get event_prayer_section_accomplished => 'ပြည့်ဝပြီ';

  @override
  String get event_prayer_mark_accomplished => 'ပြည့်ဝပြီ';

  @override
  String get event_prayer_mark_active => 'လက်ရှိအဖြစ် မှတ်ရန်';

  @override
  String get event_prayer_mine_empty_title =>
      'သင်တင်ထားသော ဆုတောင်းပေးရန် တောင်းဆိုချက် မရှိသေးပါ';

  @override
  String get event_prayer_mine_empty_body =>
      'ဤနေရာတွင် သင်တင်သော တောင်းဆိုချက်များ ဤစာရင်းတွင် ပေါ်လာပါမည်';

  @override
  String get event_prayer_update_failed =>
      'ဆုတောင်းပေးရန် တောင်းဆိုချက်ကို ပြင်ဆင်၍ မရပါ';

  @override
  String get event_prayer_find => 'ဆုတောင်းပေးရန် တစ်ခု ရှာပါ';

  @override
  String get event_prayer_random => 'ကျပန်း';

  @override
  String get event_prayer_finding => 'ဆုတောင်းချက် ရှာနေသည်...';

  @override
  String get event_prayer_found => 'သင် ဆုတောင်းပေးရန် တစ်ခု';

  @override
  String get event_prayer_skip => 'ကျော်ရန်';

  @override
  String get event_prayer_next => 'နောက်ထပ် ဆုတောင်းချက်';

  @override
  String get event_prayer_be_first => 'ပထမဆုံး ဆုတောင်းပေးလိုက်ပါ';

  @override
  String get event_prayer_random_empty_title => 'ရှာရန် ဆုတောင်းချက် မရှိသေးပါ';

  @override
  String get event_prayer_random_empty_body =>
      'ဤနေရာတွင် အခြားသူများ တောင်းဆိုချက် မတင်ရသေးပါ';

  @override
  String get event_prayer_random_failed => 'ဆုတောင်းချက် ရှာ၍ မရပါ';

  @override
  String event_prayer_people_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ဦး',
      one: '1 ဦး',
    );
    return '$_temp0';
  }

  @override
  String event_prayer_prayers_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ဆုတောင်းမှု $count ကြိမ်',
      one: 'ဆုတောင်းမှု 1 ကြိမ်',
    );
    return '$_temp0';
  }

  @override
  String get me_prayer_requests => 'ကျွန်ုပ်၏ ဆုတောင်းပေးရန် တောင်းဆိုချက်များ';

  @override
  String get me_prayer_requests_empty_title =>
      'ဆုတောင်းပေးရန် တောင်းဆိုချက် မရှိသေးပါ';

  @override
  String get me_prayer_requests_empty_body =>
      'အဖွဲ့များနှင့် ပွဲများတွင် သင်တင်သော တောင်းဆိုချက်များ ဤနေရာတွင် ပေါ်လာပါမည်';

  @override
  String get me_prayer_delete_body =>
      'ထိုအဖွဲ့ သို့မဟုတ် ပွဲရှိ လူတိုင်းအတွက် ဖယ်ရှားသွားပါမည်။';

  @override
  String get recitation_live_sync => 'ချိန်ကိုက်ရန်';

  @override
  String get recitation_live_label => 'တိုက်ရိုက်';

  @override
  String get recitation_live_session_ended =>
      'တိုက်ရိုက်ထုတ်လွှင့်မှု ပြီးဆုံးသွားပါပြီ';

  @override
  String get feedback_add_image => 'ပုံ ထည့်ရန်';

  @override
  String feedback_image_limit(int count) {
    return 'ပုံ $count ပုံအထိ ပူးတွဲနိုင်ပါသည်';
  }

  @override
  String get feedback_send => 'ပို့ရန်';

  @override
  String get feedback_error_offline =>
      'အင်တာနက် ချိတ်ဆက်မှု မရှိပါ။ နောက်မှ ထပ်ကြိုးစားပါ';

  @override
  String get feedback_error_rate_limited =>
      'တောင်းဆိုမှု များလွန်းပါသည်။ ခဏစောင့်ပြီး ထပ်ကြိုးစားပါ';

  @override
  String get feedback_error_too_large =>
      'ပုံများ အရွယ်အစား ကြီးလွန်းပါသည်။ တစ်ပုံ ဖယ်ရှားပြီး ထပ်ကြိုးစားပါ';

  @override
  String get feedback_error_failed =>
      'အကြံပြုချက်ကို ပို့၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get feedback_error_unavailable =>
      'လောလောဆယ် အကြံပြုချက် ပေးပို့၍ မရပါ';

  @override
  String get settings_help_contact_row => 'အကူအညီနှင့် ဆက်သွယ်ရန်';

  @override
  String get help_contact_title => 'အကူအညီနှင့် ဆက်သွယ်ရန်';

  @override
  String get help_contact_intro =>
      'ပြဿနာကို တိုင်ကြားပါ၊ အကြံဉာဏ် မျှဝေပါ သို့မဟုတ် ကူညီရန်၊ ပူးပေါင်းဆောင်ရွက်ရန် ကမ်းလှမ်းပါ။ မက်ဆေ့ချ်တိုင်းကို ကျွန်ုပ်တို့ ဖတ်ပါသည်။';

  @override
  String get help_contact_message => 'မက်ဆေ့ချ်';

  @override
  String get help_contact_photos =>
      'ဓာတ်ပုံ သို့မဟုတ် ဖန်သားပြင်ဓာတ်ပုံများ (ရွေးချယ်နိုင်)';

  @override
  String get help_contact_topic => 'ဘာအကြောင်းလဲ။ (ရွေးချယ်နိုင်)';

  @override
  String get help_contact_hint_default => 'ကျွန်ုပ်တို့ကို ဘာပြောပြချင်ပါသလဲ။';

  @override
  String get help_contact_hint_report_problem =>
      'ဘာဖြစ်ခဲ့သလဲ၊ မဖြစ်ခင် ဘာလုပ်နေခဲ့သလဲ။ ဖန်သားပြင်ဓာတ်ပုံ ပါလျှင် ပိုအထောက်အကူ ဖြစ်ပါသည်။';

  @override
  String get help_contact_hint_idea_feedback =>
      'သင့်ကျင့်စဉ်အတွက် WeBuddhist ကို ပိုမို အထောက်အကူဖြစ်စေမည့်အရာ ဘာလဲ။';

  @override
  String get help_contact_hint_suggest_content =>
      'ဘယ်တရားတော်၊ ကျမ်းစာ သို့မဟုတ် ဆရာကို ဤနေရာတွင် မြင်ချင်ပါသလဲ။ လင့်ခ်များ ပေးပို့နိုင်ပါသည်။';

  @override
  String get help_contact_hint_help_collaborate =>
      'ဘယ်လို ကူညီချင်ပါသလဲ။ သင့်ကျွမ်းကျင်မှု၊ ဘာသာစကားများ သို့မဟုတ် ပေးနိုင်သော အချိန်ကို မျှဝေပါ။';

  @override
  String get help_topic_report_problem => 'ပြဿနာ တိုင်ကြားရန်';

  @override
  String get help_topic_idea_feedback => 'အကြံဉာဏ် သို့မဟုတ် အကြံပြုချက်';

  @override
  String get help_topic_suggest_content => 'အကြောင်းအရာ အကြံပြုရန်';

  @override
  String get help_topic_help_collaborate => 'ကူညီရန် သို့မဟုတ် ပူးပေါင်းရန်';

  @override
  String get help_contact_footer =>
      'WeBuddhist အဖွဲ့ထံမှ ပြန်စာများကို သင့်ချတ်များတွင် ရရှိပါမည်။';

  @override
  String get help_contact_sent_title => 'မက်ဆေ့ချ် ပို့ပြီးပါပြီ';

  @override
  String get help_contact_sent_body =>
      'ကျေးဇူးတင်ပါသည်။ များသောအားဖြင့် 1 ရက်အတွင်း ပြန်ကြားပါသည်။ WeBuddhist အဖွဲ့ထံမှ ပြန်စာကို သင့်ချတ်များတွင် တွေ့ရပါမည်။';

  @override
  String help_contact_sent_body_named(String name) {
    return 'ကျေးဇူးတင်ပါသည်၊ $name။ များသောအားဖြင့် 1 ရက်အတွင်း ပြန်ကြားပါသည်။ WeBuddhist အဖွဲ့ထံမှ ပြန်စာကို သင့်ချတ်များတွင် တွေ့ရပါမည်။';
  }

  @override
  String get help_contact_your_request => 'သင့်တောင်းဆိုချက်';

  @override
  String get help_contact_open_chat => 'ချတ် ဖွင့်ရန်';

  @override
  String get help_context_sent_from => 'အကူအညီနှင့် ဆက်သွယ်ရန် မှ ပို့သည်';

  @override
  String help_context_photos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ဓာတ်ပုံ $count ပုံ',
      one: 'ဓာတ်ပုံ 1 ပုံ',
    );
    return '$_temp0';
  }

  @override
  String get chat_official_badge => 'တရားဝင်';

  @override
  String get chat_team_reply_time =>
      'များသောအားဖြင့် 1 ရက်အတွင်း ပြန်ကြားပါသည်';

  @override
  String get connect_failed_load_discover_groups_error =>
      'အဖွဲ့များကို ဖွင့်၍ မရပါ';

  @override
  String get connect_failed_like_post_error => 'ပို့စ်ကို နှစ်သက်၍ မရပါ';

  @override
  String get connect_failed_unlike_post_error =>
      'ပို့စ်ကို နှစ်သက်မှု ပြန်ဖြုတ်၍ မရပါ';

  @override
  String get group_events_load_error =>
      'ပွဲများကို ဖွင့်၍ မရပါ။ ထပ်ကြိုးစားပါ။';

  @override
  String get group_events_empty => 'ပွဲ မရှိသေးပါ';

  @override
  String get group_events_empty_message =>
      'ပထမဆုံး စုဝေးပွဲကို ဖန်တီးပါ — အဖွဲ့ဝင်များကို အသိပေးပါမည်။';

  @override
  String get group_event_create_button => 'ပွဲ ဖန်တီးရန်';

  @override
  String get group_event_new_title => 'ပွဲအသစ်';

  @override
  String group_event_step_of(int current, int total) {
    return 'အဆင့် $current / $total';
  }

  @override
  String get group_event_step_about => 'အကြောင်း';

  @override
  String get group_event_cover_image => 'မျက်နှာဖုံးပုံ';

  @override
  String get group_event_add_cover_photo => 'မျက်နှာဖုံးပုံ ထည့်ရန်';

  @override
  String get group_event_change_cover => 'ပြောင်းရန်';

  @override
  String get group_event_name_and_description => 'အမည်နှင့် ဖော်ပြချက်';

  @override
  String get group_event_name_label => 'ပွဲအမည်';

  @override
  String get group_event_name_hint =>
      'ဥပမာ - ဗုဒ္ဓဟူးနေ့ အဖွဲ့လိုက် ကျင့်ကြံမှု';

  @override
  String get group_event_description_label => 'ဖော်ပြချက် (ရွေးချယ်နိုင်)';

  @override
  String get group_event_description_hint =>
      'အတူတကွ ဘာကို ကျင့်ကြံမလဲ။ ယူလာရမည့်အရာ ရှိပါသလား။';

  @override
  String get group_event_write => 'ရေးရန်';

  @override
  String get group_event_preview => 'အစမ်းကြည့်ရန်';

  @override
  String get group_event_preview_empty => 'အစမ်းကြည့်ရန် မရှိသေးပါ';

  @override
  String get group_event_continue => 'ဆက်လက်ရန်';

  @override
  String get group_event_name_required_hint => 'ဆက်လက်ရန် ပွဲအမည် ထည့်ပါ';

  @override
  String get group_event_languages_title => 'ပွဲ ဘာသာစကားများ';

  @override
  String get group_event_languages_add => 'ဘာသာစကား ထည့်ရန်';

  @override
  String get group_event_languages_hint =>
      'သင့်အဖွဲ့၏ ဘာသာစကားများမှ ကြိုတင်ရွေးထားပါသည်။ ဖတ်ရှုသူများသည် ၎င်းတို့၏ ဘာသာစကား ရရှိနိုင်ပါက ထိုဘာသာဖြင့် ပွဲကို မြင်ရပါမည်။';

  @override
  String get group_event_discard_title => 'ပွဲကို စွန့်ပယ်မလား။';

  @override
  String get group_event_discard_message => 'သင်ထည့်ထားသည်များ ပျောက်သွားပါမည်';

  @override
  String get group_event_format_bold => 'စာလုံးထူ';

  @override
  String get group_event_format_italic => 'စာလုံးစောင်း';

  @override
  String get group_event_format_heading => 'ခေါင်းစီး';

  @override
  String get group_event_format_bullet_list => 'အမှတ်အသားစာရင်း';

  @override
  String get group_event_format_numbered_list => 'နံပါတ်စဉ်စာရင်း';

  @override
  String get group_event_format_link => 'လင့်ခ်';

  @override
  String get group_event_link_title => 'လင့်ခ် ထည့်သွင်းရန်';

  @override
  String get group_event_link_text_hint => 'စာသား';

  @override
  String get group_event_link_url_hint => 'https://';

  @override
  String get group_event_link_insert => 'ထည့်သွင်းရန်';

  @override
  String get group_event_step_when_where => 'အချိန်နှင့် နေရာ';

  @override
  String get group_event_when => 'အချိန်';

  @override
  String get group_event_where => 'နေရာ';

  @override
  String get group_event_one_time => 'တစ်ကြိမ်တည်း';

  @override
  String get group_event_recurring => 'ထပ်ခါထပ်ခါ';

  @override
  String get group_event_date => 'ရက်စွဲ';

  @override
  String get group_event_start_date => 'စတင်ရက်';

  @override
  String get group_event_end_date => 'ပြီးဆုံးရက်';

  @override
  String get group_event_first_date => 'ပထမရက်';

  @override
  String get group_event_choose_date => 'ရက်စွဲ ရွေးပါ';

  @override
  String get group_event_multi_day => 'ရက်ပေါင်းများစွာ ကျင်းပသော ပွဲ';

  @override
  String get group_event_all_day => 'တစ်နေ့လုံး';

  @override
  String get group_event_all_day_hint =>
      'ပွဲစာမျက်နှာတွင် တစ်နေ့လုံးအဖြစ် ပြသပါမည်။';

  @override
  String get group_event_start_time => 'စတင်ချိန်';

  @override
  String get group_event_end_time => 'ပြီးဆုံးချိန်';

  @override
  String get group_event_add_start_time => 'စတင်ချိန် ထည့်ရန်';

  @override
  String get group_event_add_end_time => 'ပြီးဆုံးချိန် ထည့်ရန်';

  @override
  String group_event_time_starts(String time) {
    return '$time တွင် စတင်မည်';
  }

  @override
  String group_event_time_ends(String time) {
    return '$time တွင် ပြီးဆုံးမည်';
  }

  @override
  String get group_event_timezone => 'အချိန်ဇုန်';

  @override
  String get group_event_repeats => 'ထပ်ကျင်းပမှု';

  @override
  String get group_event_choose_repeats => 'ထပ်ကျင်းပမည့်ပုံစံ ရွေးပါ';

  @override
  String get group_event_duration => 'ကြာချိန်';

  @override
  String get group_event_duration_decrease => 'ကြာချိန် လျှော့ရန်';

  @override
  String get group_event_duration_increase => 'ကြာချိန် တိုးရန်';

  @override
  String group_event_duration_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ရက်',
      one: '1 ရက်',
    );
    return '$_temp0';
  }

  @override
  String group_event_repeats_weekly(String weekday) {
    return 'အပတ်စဉ် $weekday တွင်';
  }

  @override
  String group_event_repeats_monthly(String day) {
    return 'လစဉ် $day တွင်';
  }

  @override
  String group_event_repeats_monthly_lunar(String day) {
    return 'လစဉ် စန္ဒရရက် $day တွင်';
  }

  @override
  String group_event_repeats_yearly(String date) {
    return 'နှစ်စဉ် $date တွင်';
  }

  @override
  String get group_event_repeats_yearly_lunar => 'နှစ်စဉ် ဤစန္ဒရရက်တွင်';

  @override
  String get group_event_full_moon => 'လပြည့်';

  @override
  String get group_event_new_moon => 'လကွယ်';

  @override
  String get group_event_gregorian => 'အင်္ဂလိပ်ပြက္ခဒိန်';

  @override
  String get group_event_tibetan_lunar => 'တိဗက် စန္ဒရ ပြက္ခဒိန်';

  @override
  String get group_event_next_dates => 'နောက်လာမည့် ရက်များ';

  @override
  String get group_event_repeats_hint =>
      'ရွေးချယ်စရာများသည် ပထမရက်ပေါ် အခြေခံပါသည်။';

  @override
  String get group_event_in_person => 'ကိုယ်တိုင်တက်ရောက်';

  @override
  String get group_event_live => 'တိုက်ရိုက်';

  @override
  String get group_event_both => 'နှစ်မျိုးလုံး';

  @override
  String get group_event_venue => 'ကျင်းပရာနေရာ';

  @override
  String get group_event_add_venue => 'ကျင်းပမည့်နေရာ ထည့်ရန်';

  @override
  String get group_event_venue_search_hint =>
      'ဒေသ၊ လမ်း သို့မဟုတ် အမှတ်အသားနေရာ ရှာဖွေရန်';

  @override
  String get group_event_venue_no_results => 'နေရာ မတွေ့ပါ';

  @override
  String get group_event_venue_search_error => 'ယခု ရှာဖွေ၍ မရပါ';

  @override
  String get group_event_drop_pin => 'တည်နေရာ ပင်ထိုးရန်';

  @override
  String get group_event_drop_pin_hint => 'မြေပုံပေါ်တွင် နေရာကို ရွေးပါ';

  @override
  String get group_event_pin_marker => 'ပွဲကျင်းပရာနေရာ';

  @override
  String get group_event_selected_location => 'ရွေးထားသော တည်နေရာ';

  @override
  String get group_event_pin_unnamed => 'ပင်ထိုးထားသော နေရာ';

  @override
  String get group_event_confirm_location => 'တည်နေရာ အတည်ပြုရန်';

  @override
  String get group_event_name_location => 'တည်နေရာကို အမည်ပေးပါ';

  @override
  String get group_event_venue_name => 'ကျင်းပရာနေရာ အမည်';

  @override
  String get group_event_venue_name_hint => 'ဥပမာ - ဝဇိရသတ္တ ဓမ္မစင်တာ';

  @override
  String get group_event_save_venue => 'နေရာ သိမ်းရန်';

  @override
  String get group_event_live_link => 'တိုက်ရိုက်လင့်ခ်';

  @override
  String get group_event_live_link_hint =>
      'youtube.com/… သို့မဟုတ် အစည်းအဝေးလင့်ခ်';

  @override
  String get group_event_use_channel_link => 'ချန်နယ်လင့်ခ် အသုံးပြုရန်';

  @override
  String get group_event_live_link_youtube_help =>
      'သင့်အဖွဲ့၏ YouTube တိုက်ရိုက်ထုတ်လွှင့်မှု။ WeBuddhist အတွင်း၌ ဖွင့်ပါမည်။ ပြောင်းလိုပါက အခြားလင့်ခ်ကို ကူးထည့်ပါ။';

  @override
  String get group_event_live_link_custom_help =>
      'စိတ်ကြိုက်လင့်ခ်။ ကြည့်ရှုသူများက WeBuddhist ပြင်ပတွင် ဖွင့်ရပါမည်။';

  @override
  String get group_event_live_link_invalid => 'လင့်ခ် ပုံစံ မဟုတ်သေးပါ';

  @override
  String get group_event_pick_date_hint => 'ဆက်လက်ရန် ရက်စွဲ ရွေးပါ';

  @override
  String get group_event_pick_repeats_hint =>
      'ဆက်လက်ရန် ထပ်ကျင်းပမည့်ပုံစံ ရွေးပါ';

  @override
  String get group_event_end_date_hint =>
      'ပြီးဆုံးရက်သည် စတင်ရက်နောက်တွင် ဖြစ်ရပါမည်';

  @override
  String get group_event_end_time_hint =>
      'ပြီးဆုံးချိန်သည် စတင်ချိန်နောက်တွင် ဖြစ်ရပါမည်';

  @override
  String get group_event_venue_hint => 'ဆက်လက်ရန် ကျင်းပရာနေရာ ရွေးပါ';

  @override
  String get group_event_link_required_hint =>
      'ဆက်လက်ရန် အစည်းအဝေးလင့်ခ် ထည့်ပါ';

  @override
  String get group_event_map_attribution => '© OpenStreetMap ပါဝင်ကူညီသူများ';

  @override
  String get group_event_step_practices => 'ကျင့်စဉ်နှင့် ဗီဒီယိုများ';

  @override
  String get group_event_optional_note =>
      'ဤနေရာရှိ အရာအားလုံးသည် မဖြစ်မနေ မဟုတ်ပါ။ ဤအသေးစိတ်များကို နောက်မှ ထည့်နိုင်ပါသည်။';

  @override
  String get group_event_practices_section => 'ပွဲ ကျင့်စဉ်များ';

  @override
  String get group_event_add_practice => 'ကျင့်စဉ် ထည့်ရန်';

  @override
  String get group_event_practice_search_hint =>
      'သင့်အဖွဲ့၏ ကျင့်စဉ်များကို ရှာဖွေရန်';

  @override
  String get group_event_practice_filter_all => 'အားလုံး';

  @override
  String get group_event_practice_filter_content =>
      'သင်ခန်းစာအစီအစဉ်နှင့် စီးရီးများ';

  @override
  String get group_event_practice_filter_collections =>
      'ရွတ်ဆိုရန်စာ စုစည်းမှုများ';

  @override
  String get group_event_practice_filter_accumulators => 'စုဆောင်းမှုများ';

  @override
  String get group_event_practice_rule =>
      'ပွဲတစ်ပွဲလျှင် သင်ခန်းစာအစီအစဉ် သို့မဟုတ် စီးရီး တစ်ခုနှင့် ရွတ်ဆိုရန်စာ စုစည်းမှု တစ်ခုသာ ထည့်နိုင်ပါသည်။ စုဆောင်းမှုများကိုမူ လိုသလောက် ထည့်နိုင်ပါသည်။';

  @override
  String group_event_practice_replaced(String chosen, String previous) {
    return '$chosen ကို ရွေးလိုက်သဖြင့် $previous ကို အစားထိုးလိုက်ပါသည်။';
  }

  @override
  String get group_event_practices_empty => 'ဤအဖွဲ့တွင် ကျင့်စဉ် မရှိသေးပါ';

  @override
  String get group_event_practices_load_error =>
      'ကျင့်စဉ်များကို ဖွင့်၍ မရပါ။ ထပ်ကြိုးစားပါ။';

  @override
  String get group_event_practices_none_match => 'ကိုက်ညီသော ကျင့်စဉ် မရှိပါ';

  @override
  String group_event_add_practices_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ကျင့်စဉ် $count ခု ထည့်ရန်',
      one: 'ကျင့်စဉ် 1 ခု ထည့်ရန်',
      zero: 'ကျင့်စဉ်များ ထည့်ရန်',
    );
    return '$_temp0';
  }

  @override
  String get group_event_counted_by => 'ရေတွက်သူ';

  @override
  String get group_event_count_mode_title => 'အရေအတွက်ကို ဘယ်သူ ထည့်မလဲ။';

  @override
  String get group_event_count_mode_attendees =>
      'တက်ရောက်သူများက အက်ပ်တွင် ထည့်မည်';

  @override
  String get group_event_count_mode_attendees_hint =>
      'ပွဲအတွင်း သို့မဟုတ် ပွဲပြီးနောက် လူတစ်ဦးချင်းစီက မိမိ၏ ရွတ်ဆိုမှုကို ထည့်ပါမည်';

  @override
  String get group_event_count_mode_admin =>
      'ကိုယ်တိုင်တက်ရောက်သူများအတွက် စီမံသူက ထည့်မည်';

  @override
  String get group_event_count_mode_admin_hint =>
      'အဖွဲ့၏ အရေအတွက်ကို သင်ထည့်ရပါမည်၊ ဥပမာ လူဦးရေ × ပတ်ရေ';

  @override
  String get group_event_count_mode_admin_short => 'စီမံသူက ထည့်မည်';

  @override
  String get group_event_count_mode_attendees_taken =>
      'အခြားစုဆောင်းမှုတစ်ခုက ဤနည်းလမ်းကို အသုံးပြုထားပြီး ဖြစ်ပါသည်။ ပွဲတစ်ပွဲလျှင် စုဆောင်းမှု တစ်ခုတွင်သာ တက်ရောက်သူများက အရေအတွက် ထည့်နိုင်ပါသည်။';

  @override
  String group_event_remove_practice(String title) {
    return '$title ကို ဖယ်ရှားရန်';
  }

  @override
  String get group_event_videos_section => 'မိတ်ဆက် ဗီဒီယိုများ';

  @override
  String get group_event_videos_hint =>
      'ပွဲ၏ အကြောင်း စာမျက်နှာတွင် ပြသပါမည်။ ပွဲကို မိတ်ဆက်ရန် သို့မဟုတ် မျှော်လင့်နိုင်သည်များကို ရှင်းပြရန် အသုံးပြုပါ။';

  @override
  String get group_event_add_video => 'ဗီဒီယို ထည့်ရန်';

  @override
  String get group_event_video_link => 'YouTube လင့်ခ်';

  @override
  String get group_event_video_link_hint => 'https://youtu.be/…';

  @override
  String get group_event_paste => 'ကူးထည့်ရန်';

  @override
  String get group_event_video_loading => 'ဗီဒီယို အသေးစိတ် ရယူနေသည်…';

  @override
  String get group_event_video_invalid =>
      'YouTube လင့်ခ် ပုံစံ မဟုတ်ပါ။ YouTube မှ လင့်ခ်ကို ကူးထည့်ပါ။';

  @override
  String get group_event_video_source => 'YouTube';

  @override
  String get group_event_video_untitled => 'YouTube ဗီဒီယို';

  @override
  String get group_event_remove_video => 'ဗီဒီယို ဖယ်ရှားရန်';

  @override
  String get group_event_skip => 'ကျော်ရန်';

  @override
  String get group_event_step_review => 'ပြန်စစ်ပြီး ထုတ်ပြန်ရန်';

  @override
  String get group_event_review_event => 'ပွဲ';

  @override
  String get group_event_review_settings => 'ဆက်တင်များ';

  @override
  String get group_event_review_name => 'အမည်';

  @override
  String get group_event_review_languages => 'ဘာသာစကားများ';

  @override
  String get group_event_review_when => 'အချိန်';

  @override
  String get group_event_review_where => 'နေရာ';

  @override
  String get group_event_review_live_link => 'တိုက်ရိုက်လင့်ခ်';

  @override
  String get group_event_review_practices => 'ကျင့်စဉ်များ';

  @override
  String get group_event_review_videos => 'မိတ်ဆက် ဗီဒီယိုများ';

  @override
  String get group_event_review_event_settings => 'ပွဲ ဆက်တင်များ';

  @override
  String get group_event_review_none => 'မရှိ';

  @override
  String get group_event_review_tap_hint =>
      'ပြောင်းလဲရန် မည်သည့်အတန်းကိုမဆို နှိပ်ပါ။';

  @override
  String get group_event_review_notify_hint =>
      'ထုတ်ပြန်သည့်အခါ အဖွဲ့ဝင်များကို အသိပေးပါမည်။';

  @override
  String group_event_review_more(String first, int count) {
    return '$first + နောက်ထပ် $count ခု';
  }

  @override
  String group_event_review_recurring_from(
    String rule,
    String times,
    String date,
  ) {
    return '$rule · $times · $date မှစ၍';
  }

  @override
  String get group_event_review_youtube_live => 'YouTube တိုက်ရိုက်';

  @override
  String get group_event_review_online => 'အွန်လိုင်း';

  @override
  String get group_event_chat_on => 'ချတ် ဖွင့်ထားသည်';

  @override
  String get group_event_chat_off => 'ချတ် ပိတ်ထားသည်';

  @override
  String get group_event_notifications_on => 'အသိပေးချက် ဖွင့်ထားသည်';

  @override
  String get group_event_notifications_off => 'အသိပေးချက် ပိတ်ထားသည်';

  @override
  String get group_event_all_intentions => 'ရည်ရွယ်ချက်အားလုံး';

  @override
  String group_event_intentions_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ရည်ရွယ်ချက် $count ခု',
      one: 'ရည်ရွယ်ချက် 1 ခု',
    );
    return '$_temp0';
  }

  @override
  String get group_event_publish => 'ထုတ်ပြန်ရန်';

  @override
  String get group_event_publish_error =>
      'ပွဲကို ထုတ်ပြန်၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get group_event_settings_title => 'ပွဲ ဆက်တင်များ';

  @override
  String get group_event_settings_chat => 'ပွဲ ချတ်';

  @override
  String get group_event_settings_chat_hint =>
      'ပွဲအတွက် သီးသန့်ချတ် ပေးပါမည်။ ထိုတွင် အဖွဲ့ဝင်များ စကားပြောနိုင်ပြီး ဆုတောင်းပေးရန် တောင်းဆိုချက်များ တင်နိုင်ပါသည်။';

  @override
  String get group_event_settings_notifications => 'အသိပေးချက်များ';

  @override
  String get group_event_settings_notifications_hint =>
      'ထုတ်ပြန်သည့်အခါ အသိပေးချက်၊ မစတင်မီ သတိပေးချက်နှင့် သင်ကိုယ်တိုင် ပို့သော အသိပေးချက်များ။';

  @override
  String get group_event_settings_intentions => 'ဆုတောင်း ရည်ရွယ်ချက်များ';

  @override
  String get group_event_settings_intentions_hint =>
      'ရည်ရွယ်ချက်အားလုံးကို ခွင့်ပြုရန် မည်သည့်အရာကိုမျှ မရွေးဘဲ ထားပါ။';

  @override
  String get group_event_settings_intentions_error =>
      'ယခု ရည်ရွယ်ချက်များကို ဖွင့်၍ မရပါ။';

  @override
  String get group_event_published_title => 'ထုတ်ပြန်ပြီးပါပြီ';

  @override
  String group_event_published_headline(String name) {
    return '$name ကို ထုတ်ပြန်ပြီးပါပြီ';
  }

  @override
  String group_event_published_message(String group) {
    return '$group ၏ အဖွဲ့ဝင်များကို အသိပေးပြီးပါပြီ။ ပွဲစာမျက်နှာမှ အချိန်မရွေး ပြင်ဆင်နိုင်ပါသည်။';
  }

  @override
  String get group_event_published_message_silent =>
      'ပွဲစာမျက်နှာမှ အချိန်မရွေး ပြင်ဆင်နိုင်ပါသည်။';

  @override
  String get group_event_view_event => 'ပွဲ ကြည့်ရန်';

  @override
  String get group_event_drafts_section => 'မူကြမ်းများ';

  @override
  String get group_event_draft_label => 'မူကြမ်း';

  @override
  String get group_event_draft_untitled => 'အမည်မဲ့ ပွဲ';

  @override
  String get group_event_draft_menu_continue => 'ဆက်ပြင်ဆင်ရန်';

  @override
  String get group_event_draft_menu_delete => 'မူကြမ်း ဖျက်ရန်';

  @override
  String get group_event_draft_menu_delete_hint => 'နောက်ပြန်ဆုတ်၍ မရပါ';

  @override
  String get group_event_draft_saved => 'မူကြမ်းအဖြစ် သိမ်းပြီးပါပြီ';

  @override
  String get group_event_draft_save_error =>
      'မူကြမ်းကို သိမ်း၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get group_event_draft_deleted => 'မူကြမ်းကို ဖျက်ပြီးပါပြီ';

  @override
  String get group_event_draft_delete_error =>
      'မူကြမ်းကို ဖျက်၍ မရပါ။ ထပ်ကြိုးစားပါ';

  @override
  String get group_event_draft_delete_title => 'မူကြမ်းကို ဖျက်မလား။';

  @override
  String get group_event_draft_delete_message =>
      'ဤမူကြမ်းကို အပြီးတိုင် ဖယ်ရှားပါမည်';

  @override
  String get group_event_edit_draft_title => 'မူကြမ်း ပြင်ဆင်ရန်';

  @override
  String get group_event_edit_title => 'ပွဲ ပြင်ဆင်ရန်';

  @override
  String get group_event_save_changes => 'ပြောင်းလဲမှုများ သိမ်းရန်';

  @override
  String get group_event_changes_saved => 'ပြောင်းလဲမှုများကို သိမ်းပြီးပါပြီ';

  @override
  String get group_event_manage => 'ပွဲ စီမံရန်';

  @override
  String get group_event_manage_details => 'အသေးစိတ်';

  @override
  String get group_event_manage_counts => 'အရေအတွက်များ';

  @override
  String get group_event_manage_accumulations => 'စုဆောင်းမှုများ';

  @override
  String get group_event_manage_admin_adds_pending => 'စီမံသူက ထည့်မည်';

  @override
  String group_event_manage_admin_adds(String count) {
    return 'စီမံသူက ထည့်မည် · ယခုထိ $count';
  }

  @override
  String get group_event_manage_attendees_add_pending =>
      'တက်ရောက်သူများက အက်ပ်တွင် ထည့်မည်';

  @override
  String group_event_manage_attendees_add(String count, int people) {
    String _temp0 = intl.Intl.pluralLogic(
      people,
      locale: localeName,
      other: 'တက်ရောက်သူများက အက်ပ်တွင် ထည့်မည် · $people ဦးထံမှ $count',
      one: 'တက်ရောက်သူများက အက်ပ်တွင် ထည့်မည် · 1 ဦးထံမှ $count',
    );
    return '$_temp0';
  }

  @override
  String get group_event_manage_add_count => 'အရေအတွက် ထည့်ရန်';

  @override
  String get group_event_manage_no_accumulations =>
      'ဤပွဲတွင် စုဆောင်းမှု မရှိပါ။';

  @override
  String get group_event_manage_recurring_note =>
      'ထပ်ခါထပ်ခါ ကျင်းပသော ပွဲများအတွက် တက်ရောက်သူစာရင်းကို မသိမ်းထားပါ။ အရေအတွက်များကို အကြိမ်အားလုံးမှ ပေါင်းထည့်ပါသည်။';

  @override
  String group_event_in_person_of_target(String count, String target) {
    return '$target အနက် $count';
  }

  @override
  String group_event_in_person_in_total(String count) {
    return 'စုစုပေါင်း $count';
  }

  @override
  String get group_event_in_person_legend_app => 'အက်ပ်';

  @override
  String get group_event_in_person_legend_in_person => 'ကိုယ်တိုင်တက်ရောက်';

  @override
  String get group_event_in_person_add_day => 'ရက် ထည့်ရန်';

  @override
  String get group_event_in_person_day => 'ရက်';

  @override
  String get group_event_in_person_count => 'အရေအတွက်';

  @override
  String get group_event_in_person_empty =>
      'ကိုယ်တိုင်တက်ရောက်သူ အရေအတွက် မရှိသေးပါ။';

  @override
  String get group_event_in_person_invalid_count =>
      'အနည်းဆုံး 1 ရှိသော ကိန်းပြည့်ကို ထည့်ပါ';

  @override
  String get group_event_in_person_added =>
      'ကိုယ်တိုင်တက်ရောက်သူ အရေအတွက် ထည့်ပြီးပါပြီ';

  @override
  String get group_event_in_person_updated =>
      'ကိုယ်တိုင်တက်ရောက်သူ အရေအတွက်ကို ပြင်ဆင်ပြီးပါပြီ';

  @override
  String get group_event_in_person_deleted =>
      'ကိုယ်တိုင်တက်ရောက်သူ အရေအတွက်ကို ဖျက်ပြီးပါပြီ';

  @override
  String get group_event_in_person_delete_title =>
      'ကိုယ်တိုင်တက်ရောက်သူ အရေအတွက်ကို ဖျက်မလား။';

  @override
  String group_event_in_person_delete_message(String count, String day) {
    return '$day အတွက် $count ကို စုဆောင်းမှု စုစုပေါင်းမှ နုတ်ပါမည်။';
  }

  @override
  String get group_event_in_person_exists =>
      'ထိုရက်အတွက် အရေအတွက် ရှိပြီးသားဖြစ်ပါသည်။ ၎င်းကို ပြင်ဆင်ပါ။';

  @override
  String get group_event_in_person_no_accumulation =>
      'ကိုယ်တိုင်တက်ရောက်သူ အရေအတွက်ကို မှတ်တမ်းတင်ရန် ဤပွဲနှင့် အဖွဲ့စုဆောင်းမှုတစ်ခုကို ချိတ်ဆက်ပါ။';

  @override
  String get group_event_in_person_save_error => 'အရေအတွက်ကို သိမ်း၍ မရပါ။';

  @override
  String get group_event_in_person_load_more => 'ထပ်ဖွင့်ရန်';

  @override
  String get mala_failed_load_catalogue_error => 'စာရင်းကို ဖွင့်၍ မရပါ';

  @override
  String get chant_collection_reload_error =>
      'အစီအစဉ်ပြန်စီရန် စုစည်းမှုကို ပြန်ဖွင့်၍ မရပါ';

  @override
  String get chant_collection_reorder_error =>
      'ရွတ်ဆိုရန်စာများကို အစီအစဉ်ပြန်စီ၍ မရပါ';

  @override
  String get timer_duration_label => 'ကြာချိန်';

  @override
  String get timer_ambient_sound_label => 'နောက်ခံ အသံ';

  @override
  String get timer_begin_session => 'တရားထိုင်ခြင်း စတင်ရန်';

  @override
  String get timer_save_changes => 'ပြောင်းလဲမှုများ သိမ်းရန်';

  @override
  String get timer_new_title => 'အချိန်မှတ်စက် အသစ်';

  @override
  String get timer_title_hint => 'ခေါင်းစဉ်...';

  @override
  String get timer_edit_title => 'အချိန်မှတ်စက် ပြင်ဆင်ရန်';

  @override
  String get timer_your_timers => 'သင့်အချိန်မှတ်စက်များ';

  @override
  String get timer_ambient_sounds_title => 'နောက်ခံ အသံများ';

  @override
  String get timer_ambient_sound_none => 'မူလ (အသံမရှိ)';

  @override
  String get timer_ambient_sounds_load_error =>
      'နောက်ခံ အသံများကို ဖွင့်၍ မရပါ';

  @override
  String get timer_volume_label => 'အသံအတိုးအကျယ်';

  @override
  String get timer_duration_title => 'ကြာချိန်';

  @override
  String get timer_edit => 'အချိန်မှတ်စက် ပြင်ဆင်ရန်';

  @override
  String get timer_delete => 'အချိန်မှတ်စက် ဖျက်ရန်';

  @override
  String get timer_delete_title => 'အချိန်မှတ်စက်ကို ဖျက်မလား။';

  @override
  String get timer_delete_message =>
      'ဤအချိန်မှတ်စက်ကို သင့်အချိန်မှတ်စက်များထဲမှ ဖယ်ရှားပါမည်။';

  @override
  String get timer_duration_must_be_greater_than_error =>
      'ကြာချိန်သည် 0 ထက် ကြီးရပါမည်';

  @override
  String get splash_tagline_1 =>
      'ဗုဒ္ဓဘာသာဝင် ကျွန်ုပ်တို့ အတူတကွ ကျင့်ကြံကြသည်';

  @override
  String get splash_tagline_2 =>
      'ဗုဒ္ဓဘာသာဝင် ကျွန်ုပ်တို့ နေ့စဉ် ကျင့်ကြံကြသည်';

  @override
  String get timer_create_custom => 'စိတ်ကြိုက် အချိန်မှတ်စက် ဖန်တီးရန်';

  @override
  String get timer_starting => 'စတင်နေသည်...';

  @override
  String get timer_duration_hours => 'နာရီ';

  @override
  String get timer_duration_sec => 'စက္ကန့်';

  @override
  String get reader_display_title => 'Display';

  @override
  String get text_size => 'Text size';

  @override
  String get reader_more_settings => 'More settings';

  @override
  String get reader_spacing => 'Line spacing';

  @override
  String get reader_spacing_compact => 'Compact';

  @override
  String get reader_spacing_normal => 'Normal';

  @override
  String get reader_spacing_relaxed => 'Relaxed';

  @override
  String get reader_background => 'Background';

  @override
  String get reader_background_rice_paper => 'Rice Paper';

  @override
  String get reader_background_gold => 'Gold';

  @override
  String get reader_background_sky => 'Sky';

  @override
  String get reader_background_white => 'White';

  @override
  String get reader_background_plum => 'Plum';

  @override
  String get reader_background_temple_red => 'Temple Red';

  @override
  String get reader_background_robe_saffron => 'Robe Saffron';

  @override
  String get reader_in_the_text => 'In the text';

  @override
  String get reader_ritual_instructions => 'Ritual instructions';

  @override
  String get reader_verse_numbers => 'Verse numbers';

  @override
  String get reader_change_languages => 'Change languages';

  @override
  String get reader_live_paused => 'Paused';

  @override
  String get reader_text_smaller => 'Smaller text';

  @override
  String get reader_text_larger => 'Larger text';

  @override
  String reader_section_position(String current, String total) {
    return 'Section $current / $total';
  }

  @override
  String reader_round_position(String current, String total) {
    return 'Round $current / $total';
  }

  @override
  String reader_round_number(String current) {
    return 'Round $current';
  }

  @override
  String reader_count_position(String current, String total) {
    return '$current / $total';
  }

  @override
  String reader_show_script_in(String language) {
    return 'Show $language in';
  }

  @override
  String reader_verse_label(String number) {
    return 'Verse $number';
  }

  @override
  String get reader_tab_commentary => 'Commentary';

  @override
  String get reader_tab_versions => 'Versions';
}

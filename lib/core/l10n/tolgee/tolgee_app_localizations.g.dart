// GENERATED CODE - DO NOT MODIFY BY HAND
//
// Regenerate with:
//   dart run tool/generate_tolgee_bridge.dart

import '../generated/app_localizations.dart';
import 'tolgee_bridge.dart';

// ignore_for_file: type=lint

/// Wraps the bundled gen-l10n translations so every key can be
/// overridden at runtime from Tolgee, falling back to [_fallback]
/// whenever no remote value is available.
class TolgeeAppLocalizations extends AppLocalizations {
  TolgeeAppLocalizations(this._fallback) : super(_fallback.localeName);

  final AppLocalizations _fallback;

  @override
  String get appTitle =>
      TolgeeBridge.get(localeName, 'appTitle', () => _fallback.appTitle);

  @override
  String get sign_in =>
      TolgeeBridge.get(localeName, 'sign_in', () => _fallback.sign_in);

  @override
  String get logout =>
      TolgeeBridge.get(localeName, 'logout', () => _fallback.logout);

  @override
  String get onboarding_welcome => TolgeeBridge.get(
    localeName,
    'onboarding_welcome',
    () => _fallback.onboarding_welcome,
  );

  @override
  String get onboarding_tagline => TolgeeBridge.get(
    localeName,
    'onboarding_tagline',
    () => _fallback.onboarding_tagline,
  );

  @override
  String get onboarding_find_peace => TolgeeBridge.get(
    localeName,
    'onboarding_find_peace',
    () => _fallback.onboarding_find_peace,
  );

  @override
  String get onboarding_continue => TolgeeBridge.get(
    localeName,
    'onboarding_continue',
    () => _fallback.onboarding_continue,
  );

  @override
  String get onboarding_first_question => TolgeeBridge.get(
    localeName,
    'onboarding_first_question',
    () => _fallback.onboarding_first_question,
  );

  @override
  String get onboarding_language_subtitle => TolgeeBridge.get(
    localeName,
    'onboarding_language_subtitle',
    () => _fallback.onboarding_language_subtitle,
  );

  @override
  String get onboarding_all_set => TolgeeBridge.get(
    localeName,
    'onboarding_all_set',
    () => _fallback.onboarding_all_set,
  );

  @override
  String get onboarding_all_set_description => TolgeeBridge.get(
    localeName,
    'onboarding_all_set_description',
    () => _fallback.onboarding_all_set_description,
  );

  @override
  String get onboarding_all_set_practice_title => TolgeeBridge.get(
    localeName,
    'onboarding_all_set_practice_title',
    () => _fallback.onboarding_all_set_practice_title,
  );

  @override
  String get onboarding_all_set_practice_body => TolgeeBridge.get(
    localeName,
    'onboarding_all_set_practice_body',
    () => _fallback.onboarding_all_set_practice_body,
  );

  @override
  String get onboarding_all_set_connect_title => TolgeeBridge.get(
    localeName,
    'onboarding_all_set_connect_title',
    () => _fallback.onboarding_all_set_connect_title,
  );

  @override
  String get onboarding_all_set_connect_body => TolgeeBridge.get(
    localeName,
    'onboarding_all_set_connect_body',
    () => _fallback.onboarding_all_set_connect_body,
  );

  @override
  String get home_today =>
      TolgeeBridge.get(localeName, 'home_today', () => _fallback.home_today);

  @override
  String get home_overall_stats => TolgeeBridge.get(
    localeName,
    'home_overall_stats',
    () => _fallback.home_overall_stats,
  );

  @override
  String home_plans_count(int count) => TolgeeBridge.format(
    localeName,
    'home_plans_count',
    <String, Object>{'count': count},
    () => _fallback.home_plans_count(count),
  );

  @override
  String home_recitation_count(int count) => TolgeeBridge.format(
    localeName,
    'home_recitation_count',
    <String, Object>{'count': count},
    () => _fallback.home_recitation_count(count),
  );

  @override
  String get home_shortcut_plans => TolgeeBridge.get(
    localeName,
    'home_shortcut_plans',
    () => _fallback.home_shortcut_plans,
  );

  @override
  String get home_chants =>
      TolgeeBridge.get(localeName, 'home_chants', () => _fallback.home_chants);

  @override
  String get home_mala =>
      TolgeeBridge.get(localeName, 'home_mala', () => _fallback.home_mala);

  @override
  String get session_mala => TolgeeBridge.get(
    localeName,
    'session_mala',
    () => _fallback.session_mala,
  );

  @override
  String get bookmark_mala => TolgeeBridge.get(
    localeName,
    'bookmark_mala',
    () => _fallback.bookmark_mala,
  );

  @override
  String get bookmark_timers => TolgeeBridge.get(
    localeName,
    'bookmark_timers',
    () => _fallback.bookmark_timers,
  );

  @override
  String get bookmark_texts => TolgeeBridge.get(
    localeName,
    'bookmark_texts',
    () => _fallback.bookmark_texts,
  );

  @override
  String get bookmark_group_accumulation => TolgeeBridge.get(
    localeName,
    'bookmark_group_accumulation',
    () => _fallback.bookmark_group_accumulation,
  );

  @override
  String get mala_add_to_practice => TolgeeBridge.get(
    localeName,
    'mala_add_to_practice',
    () => _fallback.mala_add_to_practice,
  );

  @override
  String get mala_add_mala_round => TolgeeBridge.get(
    localeName,
    'mala_add_mala_round',
    () => _fallback.mala_add_mala_round,
  );

  @override
  String get mala_add_rounds_title => TolgeeBridge.get(
    localeName,
    'mala_add_rounds_title',
    () => _fallback.mala_add_rounds_title,
  );

  @override
  String get mala_add_rounds_message => TolgeeBridge.get(
    localeName,
    'mala_add_rounds_message',
    () => _fallback.mala_add_rounds_message,
  );

  @override
  String mala_rounds_unit(int count) => TolgeeBridge.format(
    localeName,
    'mala_rounds_unit',
    <String, Object>{'count': count},
    () => _fallback.mala_rounds_unit(count),
  );

  @override
  String get mala_add_to_bookmark => TolgeeBridge.get(
    localeName,
    'mala_add_to_bookmark',
    () => _fallback.mala_add_to_bookmark,
  );

  @override
  String get mala_sound =>
      TolgeeBridge.get(localeName, 'mala_sound', () => _fallback.mala_sound);

  @override
  String get mala_vibration => TolgeeBridge.get(
    localeName,
    'mala_vibration',
    () => _fallback.mala_vibration,
  );

  @override
  String get mala_reset_count => TolgeeBridge.get(
    localeName,
    'mala_reset_count',
    () => _fallback.mala_reset_count,
  );

  @override
  String get mala_reset_title => TolgeeBridge.get(
    localeName,
    'mala_reset_title',
    () => _fallback.mala_reset_title,
  );

  @override
  String get mala_reset_count_confirm => TolgeeBridge.get(
    localeName,
    'mala_reset_count_confirm',
    () => _fallback.mala_reset_count_confirm,
  );

  @override
  String get mala_reset_confirm => TolgeeBridge.get(
    localeName,
    'mala_reset_confirm',
    () => _fallback.mala_reset_confirm,
  );

  @override
  String get mala_action_coming_soon => TolgeeBridge.get(
    localeName,
    'mala_action_coming_soon',
    () => _fallback.mala_action_coming_soon,
  );

  @override
  String mala_rounds_count(int count) => TolgeeBridge.format(
    localeName,
    'mala_rounds_count',
    <String, Object>{'count': count},
    () => _fallback.mala_rounds_count(count),
  );

  @override
  String get mala_hand_layout_tooltip => TolgeeBridge.get(
    localeName,
    'mala_hand_layout_tooltip',
    () => _fallback.mala_hand_layout_tooltip,
  );

  @override
  String get mala_settings_section => TolgeeBridge.get(
    localeName,
    'mala_settings_section',
    () => _fallback.mala_settings_section,
  );

  @override
  String get mala_others_section => TolgeeBridge.get(
    localeName,
    'mala_others_section',
    () => _fallback.mala_others_section,
  );

  @override
  String get mala_mantra_speed => TolgeeBridge.get(
    localeName,
    'mala_mantra_speed',
    () => _fallback.mala_mantra_speed,
  );

  @override
  String get mala_speed_normal => TolgeeBridge.get(
    localeName,
    'mala_speed_normal',
    () => _fallback.mala_speed_normal,
  );

  @override
  String get mala_show_full_mantra => TolgeeBridge.get(
    localeName,
    'mala_show_full_mantra',
    () => _fallback.mala_show_full_mantra,
  );

  @override
  String mala_counter_semantics(int bead, int total, String rounds) =>
      TolgeeBridge.format(
        localeName,
        'mala_counter_semantics',
        <String, Object>{'bead': bead, 'total': total, 'rounds': rounds},
        () => _fallback.mala_counter_semantics(bead, total, rounds),
      );

  @override
  String get mala_group_accumulations => TolgeeBridge.get(
    localeName,
    'mala_group_accumulations',
    () => _fallback.mala_group_accumulations,
  );

  @override
  String get mala_groups_section => TolgeeBridge.get(
    localeName,
    'mala_groups_section',
    () => _fallback.mala_groups_section,
  );

  @override
  String get mala_group_untitled => TolgeeBridge.get(
    localeName,
    'mala_group_untitled',
    () => _fallback.mala_group_untitled,
  );

  @override
  String get mala_all_time_accumulation => TolgeeBridge.get(
    localeName,
    'mala_all_time_accumulation',
    () => _fallback.mala_all_time_accumulation,
  );

  @override
  String get mala_personal_practice => TolgeeBridge.get(
    localeName,
    'mala_personal_practice',
    () => _fallback.mala_personal_practice,
  );

  @override
  String get mala_events_section => TolgeeBridge.get(
    localeName,
    'mala_events_section',
    () => _fallback.mala_events_section,
  );

  @override
  String mala_my_total(String count) => TolgeeBridge.format(
    localeName,
    'mala_my_total',
    <String, Object>{'count': count},
    () => _fallback.mala_my_total(count),
  );

  @override
  String mala_group_total(String count) => TolgeeBridge.format(
    localeName,
    'mala_group_total',
    <String, Object>{'count': count},
    () => _fallback.mala_group_total(count),
  );

  @override
  String get home_timer =>
      TolgeeBridge.get(localeName, 'home_timer', () => _fallback.home_timer);

  @override
  String get preset_timers => TolgeeBridge.get(
    localeName,
    'preset_timers',
    () => _fallback.preset_timers,
  );

  @override
  String get meditation_timer => TolgeeBridge.get(
    localeName,
    'meditation_timer',
    () => _fallback.meditation_timer,
  );

  @override
  String get timer_min =>
      TolgeeBridge.get(localeName, 'timer_min', () => _fallback.timer_min);

  @override
  String get timer_finish => TolgeeBridge.get(
    localeName,
    'timer_finish',
    () => _fallback.timer_finish,
  );

  @override
  String get timer_discard_session => TolgeeBridge.get(
    localeName,
    'timer_discard_session',
    () => _fallback.timer_discard_session,
  );

  @override
  String get home_hello_prefix => TolgeeBridge.get(
    localeName,
    'home_hello_prefix',
    () => _fallback.home_hello_prefix,
  );

  @override
  String home_share_prompt(String appName) => TolgeeBridge.format(
    localeName,
    'home_share_prompt',
    <String, Object>{'appName': appName},
    () => _fallback.home_share_prompt(appName),
  );

  @override
  String get home_share_support => TolgeeBridge.get(
    localeName,
    'home_share_support',
    () => _fallback.home_share_support,
  );

  @override
  String get no_feature_content => TolgeeBridge.get(
    localeName,
    'no_feature_content',
    () => _fallback.no_feature_content,
  );

  @override
  String get nav_home =>
      TolgeeBridge.get(localeName, 'nav_home', () => _fallback.nav_home);

  @override
  String get nav_explore =>
      TolgeeBridge.get(localeName, 'nav_explore', () => _fallback.nav_explore);

  @override
  String get nav_learn =>
      TolgeeBridge.get(localeName, 'nav_learn', () => _fallback.nav_learn);

  @override
  String get nav_practice => TolgeeBridge.get(
    localeName,
    'nav_practice',
    () => _fallback.nav_practice,
  );

  @override
  String get nav_settings => TolgeeBridge.get(
    localeName,
    'nav_settings',
    () => _fallback.nav_settings,
  );

  @override
  String get nav_connect =>
      TolgeeBridge.get(localeName, 'nav_connect', () => _fallback.nav_connect);

  @override
  String get nav_me =>
      TolgeeBridge.get(localeName, 'nav_me', () => _fallback.nav_me);

  @override
  String get tab_practices => TolgeeBridge.get(
    localeName,
    'tab_practices',
    () => _fallback.tab_practices,
  );

  @override
  String get text_search =>
      TolgeeBridge.get(localeName, 'text_search', () => _fallback.text_search);

  @override
  String get text_commentary => TolgeeBridge.get(
    localeName,
    'text_commentary',
    () => _fallback.text_commentary,
  );

  @override
  String get resources =>
      TolgeeBridge.get(localeName, 'resources', () => _fallback.resources);

  @override
  String get no_translation => TolgeeBridge.get(
    localeName,
    'no_translation',
    () => _fallback.no_translation,
  );

  @override
  String get show_more =>
      TolgeeBridge.get(localeName, 'show_more', () => _fallback.show_more);

  @override
  String get show_less =>
      TolgeeBridge.get(localeName, 'show_less', () => _fallback.show_less);

  @override
  String get more => TolgeeBridge.get(localeName, 'more', () => _fallback.more);

  @override
  String get less => TolgeeBridge.get(localeName, 'less', () => _fallback.less);

  @override
  String get no_content =>
      TolgeeBridge.get(localeName, 'no_content', () => _fallback.no_content);

  @override
  String commentary_not_available_for_language(String language) =>
      TolgeeBridge.format(
        localeName,
        'commentary_not_available_for_language',
        <String, Object>{'language': language},
        () => _fallback.commentary_not_available_for_language(language),
      );

  @override
  String get loading =>
      TolgeeBridge.get(localeName, 'loading', () => _fallback.loading);

  @override
  String get save => TolgeeBridge.get(localeName, 'save', () => _fallback.save);

  @override
  String get done => TolgeeBridge.get(localeName, 'done', () => _fallback.done);

  @override
  String get my_plans =>
      TolgeeBridge.get(localeName, 'my_plans', () => _fallback.my_plans);

  @override
  String get browse_plans => TolgeeBridge.get(
    localeName,
    'browse_plans',
    () => _fallback.browse_plans,
  );

  @override
  String get plan_info =>
      TolgeeBridge.get(localeName, 'plan_info', () => _fallback.plan_info);

  @override
  String get start_reading => TolgeeBridge.get(
    localeName,
    'start_reading',
    () => _fallback.start_reading,
  );

  @override
  String get tibetan =>
      TolgeeBridge.get(localeName, 'tibetan', () => _fallback.tibetan);

  @override
  String get sanskrit =>
      TolgeeBridge.get(localeName, 'sanskrit', () => _fallback.sanskrit);

  @override
  String get english =>
      TolgeeBridge.get(localeName, 'english', () => _fallback.english);

  @override
  String get chinese =>
      TolgeeBridge.get(localeName, 'chinese', () => _fallback.chinese);

  @override
  String get classicalChinese => TolgeeBridge.get(
    localeName,
    'classicalChinese',
    () => _fallback.classicalChinese,
  );

  @override
  String get pali => TolgeeBridge.get(localeName, 'pali', () => _fallback.pali);

  @override
  String get language =>
      TolgeeBridge.get(localeName, 'language', () => _fallback.language);

  @override
  String get plan_unenroll => TolgeeBridge.get(
    localeName,
    'plan_unenroll',
    () => _fallback.plan_unenroll,
  );

  @override
  String get unenroll_confirmation => TolgeeBridge.get(
    localeName,
    'unenroll_confirmation',
    () => _fallback.unenroll_confirmation,
  );

  @override
  String get unenroll_message => TolgeeBridge.get(
    localeName,
    'unenroll_message',
    () => _fallback.unenroll_message,
  );

  @override
  String get practice_plan => TolgeeBridge.get(
    localeName,
    'practice_plan',
    () => _fallback.practice_plan,
  );

  @override
  String get search_plans => TolgeeBridge.get(
    localeName,
    'search_plans',
    () => _fallback.search_plans,
  );

  @override
  String get search_for_plans => TolgeeBridge.get(
    localeName,
    'search_for_plans',
    () => _fallback.search_for_plans,
  );

  @override
  String get no_plans_found => TolgeeBridge.get(
    localeName,
    'no_plans_found',
    () => _fallback.no_plans_found,
  );

  @override
  String get no_days_available => TolgeeBridge.get(
    localeName,
    'no_days_available',
    () => _fallback.no_days_available,
  );

  @override
  String get recitations_search => TolgeeBridge.get(
    localeName,
    'recitations_search',
    () => _fallback.recitations_search,
  );

  @override
  String get recitations_search_for => TolgeeBridge.get(
    localeName,
    'recitations_search_for',
    () => _fallback.recitations_search_for,
  );

  @override
  String get recitations_no_found => TolgeeBridge.get(
    localeName,
    'recitations_no_found',
    () => _fallback.recitations_no_found,
  );

  @override
  String get recitations_no_content => TolgeeBridge.get(
    localeName,
    'recitations_no_content',
    () => _fallback.recitations_no_content,
  );

  @override
  String get my_recitation_collection_new_title => TolgeeBridge.get(
    localeName,
    'my_recitation_collection_new_title',
    () => _fallback.my_recitation_collection_new_title,
  );

  @override
  String get my_recitation_collection_next => TolgeeBridge.get(
    localeName,
    'my_recitation_collection_next',
    () => _fallback.my_recitation_collection_next,
  );

  @override
  String get my_recitation_collection_create => TolgeeBridge.get(
    localeName,
    'my_recitation_collection_create',
    () => _fallback.my_recitation_collection_create,
  );

  @override
  String get my_recitation_collection_create_button => TolgeeBridge.get(
    localeName,
    'my_recitation_collection_create_button',
    () => _fallback.my_recitation_collection_create_button,
  );

  @override
  String get my_recitation_collection_change_title => TolgeeBridge.get(
    localeName,
    'my_recitation_collection_change_title',
    () => _fallback.my_recitation_collection_change_title,
  );

  @override
  String get my_recitation_collection_change => TolgeeBridge.get(
    localeName,
    'my_recitation_collection_change',
    () => _fallback.my_recitation_collection_change,
  );

  @override
  String get my_recitation_collection_add_chants => TolgeeBridge.get(
    localeName,
    'my_recitation_collection_add_chants',
    () => _fallback.my_recitation_collection_add_chants,
  );

  @override
  String get my_recitation_collection_search_chants => TolgeeBridge.get(
    localeName,
    'my_recitation_collection_search_chants',
    () => _fallback.my_recitation_collection_search_chants,
  );

  @override
  String get my_recitation_collection_add_to_collection => TolgeeBridge.get(
    localeName,
    'my_recitation_collection_add_to_collection',
    () => _fallback.my_recitation_collection_add_to_collection,
  );

  @override
  String get my_recitation_collection_edit => TolgeeBridge.get(
    localeName,
    'my_recitation_collection_edit',
    () => _fallback.my_recitation_collection_edit,
  );

  @override
  String get my_recitation_collection_delete => TolgeeBridge.get(
    localeName,
    'my_recitation_collection_delete',
    () => _fallback.my_recitation_collection_delete,
  );

  @override
  String get my_recitation_collection_delete_title => TolgeeBridge.get(
    localeName,
    'my_recitation_collection_delete_title',
    () => _fallback.my_recitation_collection_delete_title,
  );

  @override
  String get my_recitation_collection_delete_message => TolgeeBridge.get(
    localeName,
    'my_recitation_collection_delete_message',
    () => _fallback.my_recitation_collection_delete_message,
  );

  @override
  String get my_recitation_collection_fallback_title => TolgeeBridge.get(
    localeName,
    'my_recitation_collection_fallback_title',
    () => _fallback.my_recitation_collection_fallback_title,
  );

  @override
  String get my_recitation_collection_unavailable => TolgeeBridge.get(
    localeName,
    'my_recitation_collection_unavailable',
    () => _fallback.my_recitation_collection_unavailable,
  );

  @override
  String my_recitation_collection_chant_count(int count) => TolgeeBridge.format(
    localeName,
    'my_recitation_collection_chant_count',
    <String, Object>{'count': count},
    () => _fallback.my_recitation_collection_chant_count(count),
  );

  @override
  String my_recitation_collection_chant_count_owner(int count) =>
      TolgeeBridge.format(
        localeName,
        'my_recitation_collection_chant_count_owner',
        <String, Object>{'count': count},
        () => _fallback.my_recitation_collection_chant_count_owner(count),
      );

  @override
  String get bookmarks_empty_chant_collections_title => TolgeeBridge.get(
    localeName,
    'bookmarks_empty_chant_collections_title',
    () => _fallback.bookmarks_empty_chant_collections_title,
  );

  @override
  String get bookmarks_empty_chant_collections_subtitle => TolgeeBridge.get(
    localeName,
    'bookmarks_empty_chant_collections_subtitle',
    () => _fallback.bookmarks_empty_chant_collections_subtitle,
  );

  @override
  String get notification_allow_title => TolgeeBridge.get(
    localeName,
    'notification_allow_title',
    () => _fallback.notification_allow_title,
  );

  @override
  String get notification_allow_subtitle_disabled => TolgeeBridge.get(
    localeName,
    'notification_allow_subtitle_disabled',
    () => _fallback.notification_allow_subtitle_disabled,
  );

  @override
  String get notification_snack_permission_denied => TolgeeBridge.get(
    localeName,
    'notification_snack_permission_denied',
    () => _fallback.notification_snack_permission_denied,
  );

  @override
  String get notification_snack_disable_alarms_in_settings => TolgeeBridge.get(
    localeName,
    'notification_snack_disable_alarms_in_settings',
    () => _fallback.notification_snack_disable_alarms_in_settings,
  );

  @override
  String get notification_allow_subtitle_on => TolgeeBridge.get(
    localeName,
    'notification_allow_subtitle_on',
    () => _fallback.notification_allow_subtitle_on,
  );

  @override
  String get notification_allow_subtitle_off => TolgeeBridge.get(
    localeName,
    'notification_allow_subtitle_off',
    () => _fallback.notification_allow_subtitle_off,
  );

  @override
  String get notification_section_practice => TolgeeBridge.get(
    localeName,
    'notification_section_practice',
    () => _fallback.notification_section_practice,
  );

  @override
  String get notification_section_connect => TolgeeBridge.get(
    localeName,
    'notification_section_connect',
    () => _fallback.notification_section_connect,
  );

  @override
  String get notification_row_plans => TolgeeBridge.get(
    localeName,
    'notification_row_plans',
    () => _fallback.notification_row_plans,
  );

  @override
  String get notification_row_chants => TolgeeBridge.get(
    localeName,
    'notification_row_chants',
    () => _fallback.notification_row_chants,
  );

  @override
  String get notification_row_mala => TolgeeBridge.get(
    localeName,
    'notification_row_mala',
    () => _fallback.notification_row_mala,
  );

  @override
  String get notification_row_timer => TolgeeBridge.get(
    localeName,
    'notification_row_timer',
    () => _fallback.notification_row_timer,
  );

  @override
  String get notification_row_group_posts => TolgeeBridge.get(
    localeName,
    'notification_row_group_posts',
    () => _fallback.notification_row_group_posts,
  );

  @override
  String get notification_row_group_chats => TolgeeBridge.get(
    localeName,
    'notification_row_group_chats',
    () => _fallback.notification_row_group_chats,
  );

  @override
  String get notification_row_my_prayer_requests => TolgeeBridge.get(
    localeName,
    'notification_row_my_prayer_requests',
    () => _fallback.notification_row_my_prayer_requests,
  );

  @override
  String get notification_row_others_prayer_requests => TolgeeBridge.get(
    localeName,
    'notification_row_others_prayer_requests',
    () => _fallback.notification_row_others_prayer_requests,
  );

  @override
  String get profile_default_bio => TolgeeBridge.get(
    localeName,
    'profile_default_bio',
    () => _fallback.profile_default_bio,
  );

  @override
  String get profile_guest_title => TolgeeBridge.get(
    localeName,
    'profile_guest_title',
    () => _fallback.profile_guest_title,
  );

  @override
  String get profile_guest_subtitle => TolgeeBridge.get(
    localeName,
    'profile_guest_subtitle',
    () => _fallback.profile_guest_subtitle,
  );

  @override
  String get profile_guest_benefits_header => TolgeeBridge.get(
    localeName,
    'profile_guest_benefits_header',
    () => _fallback.profile_guest_benefits_header,
  );

  @override
  String get profile_guest_benefit_save_progress => TolgeeBridge.get(
    localeName,
    'profile_guest_benefit_save_progress',
    () => _fallback.profile_guest_benefit_save_progress,
  );

  @override
  String get profile_guest_benefit_personalized => TolgeeBridge.get(
    localeName,
    'profile_guest_benefit_personalized',
    () => _fallback.profile_guest_benefit_personalized,
  );

  @override
  String get profile_guest_benefit_notifications => TolgeeBridge.get(
    localeName,
    'profile_guest_benefit_notifications',
    () => _fallback.profile_guest_benefit_notifications,
  );

  @override
  String get auth_drawer_title => TolgeeBridge.get(
    localeName,
    'auth_drawer_title',
    () => _fallback.auth_drawer_title,
  );

  @override
  String get auth_drawer_subtitle => TolgeeBridge.get(
    localeName,
    'auth_drawer_subtitle',
    () => _fallback.auth_drawer_subtitle,
  );

  @override
  String get routine_delete_block_message => TolgeeBridge.get(
    localeName,
    'routine_delete_block_message',
    () => _fallback.routine_delete_block_message,
  );

  @override
  String get something_went_wrong => TolgeeBridge.get(
    localeName,
    'something_went_wrong',
    () => _fallback.something_went_wrong,
  );

  @override
  String get onboarding_tradition_title => TolgeeBridge.get(
    localeName,
    'onboarding_tradition_title',
    () => _fallback.onboarding_tradition_title,
  );

  @override
  String get onboarding_tradition_subtitle => TolgeeBridge.get(
    localeName,
    'onboarding_tradition_subtitle',
    () => _fallback.onboarding_tradition_subtitle,
  );

  @override
  String get onboarding_tradition_show_all_title => TolgeeBridge.get(
    localeName,
    'onboarding_tradition_show_all_title',
    () => _fallback.onboarding_tradition_show_all_title,
  );

  @override
  String get plan_go_to_practice => TolgeeBridge.get(
    localeName,
    'plan_go_to_practice',
    () => _fallback.plan_go_to_practice,
  );

  @override
  String get plan_starts_soon_title => TolgeeBridge.get(
    localeName,
    'plan_starts_soon_title',
    () => _fallback.plan_starts_soon_title,
  );

  @override
  String get plan_joining_late_title => TolgeeBridge.get(
    localeName,
    'plan_joining_late_title',
    () => _fallback.plan_joining_late_title,
  );

  @override
  String get got_it =>
      TolgeeBridge.get(localeName, 'got_it', () => _fallback.got_it);

  @override
  String get plan_no_tasks_error => TolgeeBridge.get(
    localeName,
    'plan_no_tasks_error',
    () => _fallback.plan_no_tasks_error,
  );

  @override
  String get plan_day_tasks_load_error => TolgeeBridge.get(
    localeName,
    'plan_day_tasks_load_error',
    () => _fallback.plan_day_tasks_load_error,
  );

  @override
  String get plans_empty_title => TolgeeBridge.get(
    localeName,
    'plans_empty_title',
    () => _fallback.plans_empty_title,
  );

  @override
  String get plans_empty_subtitle => TolgeeBridge.get(
    localeName,
    'plans_empty_subtitle',
    () => _fallback.plans_empty_subtitle,
  );

  @override
  String get find_plans_load_error => TolgeeBridge.get(
    localeName,
    'find_plans_load_error',
    () => _fallback.find_plans_load_error,
  );

  @override
  String get connect_subtitle => TolgeeBridge.get(
    localeName,
    'connect_subtitle',
    () => _fallback.connect_subtitle,
  );

  @override
  String get discover_groups => TolgeeBridge.get(
    localeName,
    'discover_groups',
    () => _fallback.discover_groups,
  );

  @override
  String get my_groups =>
      TolgeeBridge.get(localeName, 'my_groups', () => _fallback.my_groups);

  @override
  String get see_all =>
      TolgeeBridge.get(localeName, 'see_all', () => _fallback.see_all);

  @override
  String get connect_groups_load_error => TolgeeBridge.get(
    localeName,
    'connect_groups_load_error',
    () => _fallback.connect_groups_load_error,
  );

  @override
  String get connect_groups_empty_title => TolgeeBridge.get(
    localeName,
    'connect_groups_empty_title',
    () => _fallback.connect_groups_empty_title,
  );

  @override
  String get connect_tab_feed => TolgeeBridge.get(
    localeName,
    'connect_tab_feed',
    () => _fallback.connect_tab_feed,
  );

  @override
  String get connect_tab_events => TolgeeBridge.get(
    localeName,
    'connect_tab_events',
    () => _fallback.connect_tab_events,
  );

  @override
  String get connect_tab_practices => TolgeeBridge.get(
    localeName,
    'connect_tab_practices',
    () => _fallback.connect_tab_practices,
  );

  @override
  String get connect_tab_groups => TolgeeBridge.get(
    localeName,
    'connect_tab_groups',
    () => _fallback.connect_tab_groups,
  );

  @override
  String get connect_segment_my => TolgeeBridge.get(
    localeName,
    'connect_segment_my',
    () => _fallback.connect_segment_my,
  );

  @override
  String get connect_segment_discover => TolgeeBridge.get(
    localeName,
    'connect_segment_discover',
    () => _fallback.connect_segment_discover,
  );

  @override
  String get connect_empty_discover_events => TolgeeBridge.get(
    localeName,
    'connect_empty_discover_events',
    () => _fallback.connect_empty_discover_events,
  );

  @override
  String get connect_empty_discover_feed => TolgeeBridge.get(
    localeName,
    'connect_empty_discover_feed',
    () => _fallback.connect_empty_discover_feed,
  );

  @override
  String get connect_empty_discover_groups => TolgeeBridge.get(
    localeName,
    'connect_empty_discover_groups',
    () => _fallback.connect_empty_discover_groups,
  );

  @override
  String get connect_all_groups => TolgeeBridge.get(
    localeName,
    'connect_all_groups',
    () => _fallback.connect_all_groups,
  );

  @override
  String get connect_my_empty_feed_title => TolgeeBridge.get(
    localeName,
    'connect_my_empty_feed_title',
    () => _fallback.connect_my_empty_feed_title,
  );

  @override
  String get connect_my_empty_events_title => TolgeeBridge.get(
    localeName,
    'connect_my_empty_events_title',
    () => _fallback.connect_my_empty_events_title,
  );

  @override
  String get connect_my_empty_groups_title => TolgeeBridge.get(
    localeName,
    'connect_my_empty_groups_title',
    () => _fallback.connect_my_empty_groups_title,
  );

  @override
  String get connect_my_empty_feed_subtitle => TolgeeBridge.get(
    localeName,
    'connect_my_empty_feed_subtitle',
    () => _fallback.connect_my_empty_feed_subtitle,
  );

  @override
  String get connect_my_empty_events_subtitle => TolgeeBridge.get(
    localeName,
    'connect_my_empty_events_subtitle',
    () => _fallback.connect_my_empty_events_subtitle,
  );

  @override
  String get connect_my_empty_groups_subtitle => TolgeeBridge.get(
    localeName,
    'connect_my_empty_groups_subtitle',
    () => _fallback.connect_my_empty_groups_subtitle,
  );

  @override
  String get connect_my_empty_feed_browse => TolgeeBridge.get(
    localeName,
    'connect_my_empty_feed_browse',
    () => _fallback.connect_my_empty_feed_browse,
  );

  @override
  String get connect_my_empty_events_browse => TolgeeBridge.get(
    localeName,
    'connect_my_empty_events_browse',
    () => _fallback.connect_my_empty_events_browse,
  );

  @override
  String connect_comment_replying_to(String handle) => TolgeeBridge.format(
    localeName,
    'connect_comment_replying_to',
    <String, Object>{'handle': handle},
    () => _fallback.connect_comment_replying_to(handle),
  );

  @override
  String get connect_comment_hint => TolgeeBridge.get(
    localeName,
    'connect_comment_hint',
    () => _fallback.connect_comment_hint,
  );

  @override
  String get connect_comment_reply_hint => TolgeeBridge.get(
    localeName,
    'connect_comment_reply_hint',
    () => _fallback.connect_comment_reply_hint,
  );

  @override
  String get connect_comment_reply => TolgeeBridge.get(
    localeName,
    'connect_comment_reply',
    () => _fallback.connect_comment_reply,
  );

  @override
  String get connect_comment_delete_title => TolgeeBridge.get(
    localeName,
    'connect_comment_delete_title',
    () => _fallback.connect_comment_delete_title,
  );

  @override
  String get connect_comment_delete_message => TolgeeBridge.get(
    localeName,
    'connect_comment_delete_message',
    () => _fallback.connect_comment_delete_message,
  );

  @override
  String get connect_comment_delete_failed => TolgeeBridge.get(
    localeName,
    'connect_comment_delete_failed',
    () => _fallback.connect_comment_delete_failed,
  );

  @override
  String connect_post_comments_count(int count) => TolgeeBridge.format(
    localeName,
    'connect_post_comments_count',
    <String, Object>{'count': count},
    () => _fallback.connect_post_comments_count(count),
  );

  @override
  String get connect_post_comments_empty => TolgeeBridge.get(
    localeName,
    'connect_post_comments_empty',
    () => _fallback.connect_post_comments_empty,
  );

  @override
  String get connect_online => TolgeeBridge.get(
    localeName,
    'connect_online',
    () => _fallback.connect_online,
  );

  @override
  String get connect_ended => TolgeeBridge.get(
    localeName,
    'connect_ended',
    () => _fallback.connect_ended,
  );

  @override
  String connect_ended_on(String date) => TolgeeBridge.format(
    localeName,
    'connect_ended_on',
    <String, Object>{'date': date},
    () => _fallback.connect_ended_on(date),
  );

  @override
  String get home_group_events => TolgeeBridge.get(
    localeName,
    'home_group_events',
    () => _fallback.home_group_events,
  );

  @override
  String get home_poems =>
      TolgeeBridge.get(localeName, 'home_poems', () => _fallback.home_poems);

  @override
  String get poems_load_error => TolgeeBridge.get(
    localeName,
    'poems_load_error',
    () => _fallback.poems_load_error,
  );

  @override
  String get poems_empty =>
      TolgeeBridge.get(localeName, 'poems_empty', () => _fallback.poems_empty);

  @override
  String get connect_events_filter_all => TolgeeBridge.get(
    localeName,
    'connect_events_filter_all',
    () => _fallback.connect_events_filter_all,
  );

  @override
  String get connect_events_filter_in_person => TolgeeBridge.get(
    localeName,
    'connect_events_filter_in_person',
    () => _fallback.connect_events_filter_in_person,
  );

  @override
  String get connect_events_filter_empty_online => TolgeeBridge.get(
    localeName,
    'connect_events_filter_empty_online',
    () => _fallback.connect_events_filter_empty_online,
  );

  @override
  String get connect_events_filter_empty_in_person => TolgeeBridge.get(
    localeName,
    'connect_events_filter_empty_in_person',
    () => _fallback.connect_events_filter_empty_in_person,
  );

  @override
  String get connect_events_filter_hybrid => TolgeeBridge.get(
    localeName,
    'connect_events_filter_hybrid',
    () => _fallback.connect_events_filter_hybrid,
  );

  @override
  String get connect_events_filter_empty_hybrid => TolgeeBridge.get(
    localeName,
    'connect_events_filter_empty_hybrid',
    () => _fallback.connect_events_filter_empty_hybrid,
  );

  @override
  String get connect_event_fallback_title => TolgeeBridge.get(
    localeName,
    'connect_event_fallback_title',
    () => _fallback.connect_event_fallback_title,
  );

  @override
  String get connect_group_fallback_title => TolgeeBridge.get(
    localeName,
    'connect_group_fallback_title',
    () => _fallback.connect_group_fallback_title,
  );

  @override
  String get connect_event_participation_prompt => TolgeeBridge.get(
    localeName,
    'connect_event_participation_prompt',
    () => _fallback.connect_event_participation_prompt,
  );

  @override
  String get connect_event_practice_in_person => TolgeeBridge.get(
    localeName,
    'connect_event_practice_in_person',
    () => _fallback.connect_event_practice_in_person,
  );

  @override
  String get connect_event_practice_online => TolgeeBridge.get(
    localeName,
    'connect_event_practice_online',
    () => _fallback.connect_event_practice_online,
  );

  @override
  String get connect_event_view_in_person => TolgeeBridge.get(
    localeName,
    'connect_event_view_in_person',
    () => _fallback.connect_event_view_in_person,
  );

  @override
  String get connect_event_view_online => TolgeeBridge.get(
    localeName,
    'connect_event_view_online',
    () => _fallback.connect_event_view_online,
  );

  @override
  String get connect_event_accumulation_online => TolgeeBridge.get(
    localeName,
    'connect_event_accumulation_online',
    () => _fallback.connect_event_accumulation_online,
  );

  @override
  String get connect_event_accumulation_in_person => TolgeeBridge.get(
    localeName,
    'connect_event_accumulation_in_person',
    () => _fallback.connect_event_accumulation_in_person,
  );

  @override
  String get connect_event_has_ended => TolgeeBridge.get(
    localeName,
    'connect_event_has_ended',
    () => _fallback.connect_event_has_ended,
  );

  @override
  String get connect_event_join_to_practice => TolgeeBridge.get(
    localeName,
    'connect_event_join_to_practice',
    () => _fallback.connect_event_join_to_practice,
  );

  @override
  String get connect_event_leave => TolgeeBridge.get(
    localeName,
    'connect_event_leave',
    () => _fallback.connect_event_leave,
  );

  @override
  String get connect_event_leave_confirm_title => TolgeeBridge.get(
    localeName,
    'connect_event_leave_confirm_title',
    () => _fallback.connect_event_leave_confirm_title,
  );

  @override
  String connect_event_leave_confirm_message(String title) =>
      TolgeeBridge.format(
        localeName,
        'connect_event_leave_confirm_message',
        <String, Object>{'title': title},
        () => _fallback.connect_event_leave_confirm_message(title),
      );

  @override
  String connect_event_participants_attending(int count) => TolgeeBridge.format(
    localeName,
    'connect_event_participants_attending',
    <String, Object>{'count': count},
    () => _fallback.connect_event_participants_attending(count),
  );

  @override
  String connect_event_participants_attended(int count) => TolgeeBridge.format(
    localeName,
    'connect_event_participants_attended',
    <String, Object>{'count': count},
    () => _fallback.connect_event_participants_attended(count),
  );

  @override
  String get connect_event_participants_empty => TolgeeBridge.get(
    localeName,
    'connect_event_participants_empty',
    () => _fallback.connect_event_participants_empty,
  );

  @override
  String get connect_event_organizer => TolgeeBridge.get(
    localeName,
    'connect_event_organizer',
    () => _fallback.connect_event_organizer,
  );

  @override
  String get connect_event_tab_videos => TolgeeBridge.get(
    localeName,
    'connect_event_tab_videos',
    () => _fallback.connect_event_tab_videos,
  );

  @override
  String get connect_event_tab_about => TolgeeBridge.get(
    localeName,
    'connect_event_tab_about',
    () => _fallback.connect_event_tab_about,
  );

  @override
  String get connect_event_links_title => TolgeeBridge.get(
    localeName,
    'connect_event_links_title',
    () => _fallback.connect_event_links_title,
  );

  @override
  String get connect_event_date_tba => TolgeeBridge.get(
    localeName,
    'connect_event_date_tba',
    () => _fallback.connect_event_date_tba,
  );

  @override
  String get connect_event_when => TolgeeBridge.get(
    localeName,
    'connect_event_when',
    () => _fallback.connect_event_when,
  );

  @override
  String get connect_event_where => TolgeeBridge.get(
    localeName,
    'connect_event_where',
    () => _fallback.connect_event_where,
  );

  @override
  String get connect_event_tab_accumulations => TolgeeBridge.get(
    localeName,
    'connect_event_tab_accumulations',
    () => _fallback.connect_event_tab_accumulations,
  );

  @override
  String get connect_event_add_recitations => TolgeeBridge.get(
    localeName,
    'connect_event_add_recitations',
    () => _fallback.connect_event_add_recitations,
  );

  @override
  String get connect_event_add_recitations_message => TolgeeBridge.get(
    localeName,
    'connect_event_add_recitations_message',
    () => _fallback.connect_event_add_recitations_message,
  );

  @override
  String get connect_event_every_day => TolgeeBridge.get(
    localeName,
    'connect_event_every_day',
    () => _fallback.connect_event_every_day,
  );

  @override
  String connect_event_every_weekday(String weekday) => TolgeeBridge.format(
    localeName,
    'connect_event_every_weekday',
    <String, Object>{'weekday': weekday},
    () => _fallback.connect_event_every_weekday(weekday),
  );

  @override
  String get connect_event_every_month => TolgeeBridge.get(
    localeName,
    'connect_event_every_month',
    () => _fallback.connect_event_every_month,
  );

  @override
  String connect_event_every_date(String date) => TolgeeBridge.format(
    localeName,
    'connect_event_every_date',
    <String, Object>{'date': date},
    () => _fallback.connect_event_every_date(date),
  );

  @override
  String get connect_event_about_empty => TolgeeBridge.get(
    localeName,
    'connect_event_about_empty',
    () => _fallback.connect_event_about_empty,
  );

  @override
  String get search_groups => TolgeeBridge.get(
    localeName,
    'search_groups',
    () => _fallback.search_groups,
  );

  @override
  String get search_for_groups => TolgeeBridge.get(
    localeName,
    'search_for_groups',
    () => _fallback.search_for_groups,
  );

  @override
  String get no_groups_found => TolgeeBridge.get(
    localeName,
    'no_groups_found',
    () => _fallback.no_groups_found,
  );

  @override
  String get explore_coming_soon_subtitle => TolgeeBridge.get(
    localeName,
    'explore_coming_soon_subtitle',
    () => _fallback.explore_coming_soon_subtitle,
  );

  @override
  String get learn_coming_soon_subtitle => TolgeeBridge.get(
    localeName,
    'learn_coming_soon_subtitle',
    () => _fallback.learn_coming_soon_subtitle,
  );

  @override
  String get creator_featured_plan => TolgeeBridge.get(
    localeName,
    'creator_featured_plan',
    () => _fallback.creator_featured_plan,
  );

  @override
  String get home_no_series_found => TolgeeBridge.get(
    localeName,
    'home_no_series_found',
    () => _fallback.home_no_series_found,
  );

  @override
  String get home_no_tags_found => TolgeeBridge.get(
    localeName,
    'home_no_tags_found',
    () => _fallback.home_no_tags_found,
  );

  @override
  String get home_celebrated_by => TolgeeBridge.get(
    localeName,
    'home_celebrated_by',
    () => _fallback.home_celebrated_by,
  );

  @override
  String get reader_font_size_tooltip => TolgeeBridge.get(
    localeName,
    'reader_font_size_tooltip',
    () => _fallback.reader_font_size_tooltip,
  );

  @override
  String get reader_versions_load_error => TolgeeBridge.get(
    localeName,
    'reader_versions_load_error',
    () => _fallback.reader_versions_load_error,
  );

  @override
  String get reader_languages_load_error => TolgeeBridge.get(
    localeName,
    'reader_languages_load_error',
    () => _fallback.reader_languages_load_error,
  );

  @override
  String reader_no_versions_in_language(String language) => TolgeeBridge.format(
    localeName,
    'reader_no_versions_in_language',
    <String, Object>{'language': language},
    () => _fallback.reader_no_versions_in_language(language),
  );

  @override
  String get reader_no_languages => TolgeeBridge.get(
    localeName,
    'reader_no_languages',
    () => _fallback.reader_no_languages,
  );

  @override
  String get reader_license => TolgeeBridge.get(
    localeName,
    'reader_license',
    () => _fallback.reader_license,
  );

  @override
  String get text_search_hint => TolgeeBridge.get(
    localeName,
    'text_search_hint',
    () => _fallback.text_search_hint,
  );

  @override
  String get text_search_press_button => TolgeeBridge.get(
    localeName,
    'text_search_press_button',
    () => _fallback.text_search_press_button,
  );

  @override
  String get text_search_error => TolgeeBridge.get(
    localeName,
    'text_search_error',
    () => _fallback.text_search_error,
  );

  @override
  String get create_image_share_error => TolgeeBridge.get(
    localeName,
    'create_image_share_error',
    () => _fallback.create_image_share_error,
  );

  @override
  String get my_plans_sign_in_prompt => TolgeeBridge.get(
    localeName,
    'my_plans_sign_in_prompt',
    () => _fallback.my_plans_sign_in_prompt,
  );

  @override
  String plan_starts_soon_message(String date) => TolgeeBridge.format(
    localeName,
    'plan_starts_soon_message',
    <String, Object>{'date': date},
    () => _fallback.plan_starts_soon_message(date),
  );

  @override
  String plan_joining_late_message(String date) => TolgeeBridge.format(
    localeName,
    'plan_joining_late_message',
    <String, Object>{'date': date},
    () => _fallback.plan_joining_late_message(date),
  );

  @override
  String get select_language => TolgeeBridge.get(
    localeName,
    'select_language',
    () => _fallback.select_language,
  );

  @override
  String get logout_confirmation => TolgeeBridge.get(
    localeName,
    'logout_confirmation',
    () => _fallback.logout_confirmation,
  );

  @override
  String get cancel =>
      TolgeeBridge.get(localeName, 'cancel', () => _fallback.cancel);

  @override
  String get copy => TolgeeBridge.get(localeName, 'copy', () => _fallback.copy);

  @override
  String get copied =>
      TolgeeBridge.get(localeName, 'copied', () => _fallback.copied);

  @override
  String get share =>
      TolgeeBridge.get(localeName, 'share', () => _fallback.share);

  @override
  String get bookmark =>
      TolgeeBridge.get(localeName, 'bookmark', () => _fallback.bookmark);

  @override
  String get collection_audio_versions => TolgeeBridge.get(
    localeName,
    'collection_audio_versions',
    () => _fallback.collection_audio_versions,
  );

  @override
  String get author =>
      TolgeeBridge.get(localeName, 'author', () => _fallback.author);

  @override
  String get plans_created => TolgeeBridge.get(
    localeName,
    'plans_created',
    () => _fallback.plans_created,
  );

  @override
  String get ai_confirm =>
      TolgeeBridge.get(localeName, 'ai_confirm', () => _fallback.ai_confirm);

  @override
  String search_no_results(String query) => TolgeeBridge.format(
    localeName,
    'search_no_results',
    <String, Object>{'query': query},
    () => _fallback.search_no_results(query),
  );

  @override
  String get search_all =>
      TolgeeBridge.get(localeName, 'search_all', () => _fallback.search_all);

  @override
  String get common_ok =>
      TolgeeBridge.get(localeName, 'common_ok', () => _fallback.common_ok);

  @override
  String get comingSoonHeadline => TolgeeBridge.get(
    localeName,
    'comingSoonHeadline',
    () => _fallback.comingSoonHeadline,
  );

  @override
  String get routine_title => TolgeeBridge.get(
    localeName,
    'routine_title',
    () => _fallback.routine_title,
  );

  @override
  String get bookmarks =>
      TolgeeBridge.get(localeName, 'bookmarks', () => _fallback.bookmarks);

  @override
  String get routine_empty_title => TolgeeBridge.get(
    localeName,
    'routine_empty_title',
    () => _fallback.routine_empty_title,
  );

  @override
  String get routine_edit => TolgeeBridge.get(
    localeName,
    'routine_edit',
    () => _fallback.routine_edit,
  );

  @override
  String get routine_empty_description => TolgeeBridge.get(
    localeName,
    'routine_empty_description',
    () => _fallback.routine_empty_description,
  );

  @override
  String get routine_build => TolgeeBridge.get(
    localeName,
    'routine_build',
    () => _fallback.routine_build,
  );

  @override
  String get routine_add_session => TolgeeBridge.get(
    localeName,
    'routine_add_session',
    () => _fallback.routine_add_session,
  );

  @override
  String get routine_edit_title => TolgeeBridge.get(
    localeName,
    'routine_edit_title',
    () => _fallback.routine_edit_title,
  );

  @override
  String get routine_delete_block => TolgeeBridge.get(
    localeName,
    'routine_delete_block',
    () => _fallback.routine_delete_block,
  );

  @override
  String get routine_session_title_hint => TolgeeBridge.get(
    localeName,
    'routine_session_title_hint',
    () => _fallback.routine_session_title_hint,
  );

  @override
  String get routine_expand_all => TolgeeBridge.get(
    localeName,
    'routine_expand_all',
    () => _fallback.routine_expand_all,
  );

  @override
  String get routine_collapse_all => TolgeeBridge.get(
    localeName,
    'routine_collapse_all',
    () => _fallback.routine_collapse_all,
  );

  @override
  String get routine_add_plan => TolgeeBridge.get(
    localeName,
    'routine_add_plan',
    () => _fallback.routine_add_plan,
  );

  @override
  String get routine_add_recitation => TolgeeBridge.get(
    localeName,
    'routine_add_recitation',
    () => _fallback.routine_add_recitation,
  );

  @override
  String get routine_add_plan_to_routine => TolgeeBridge.get(
    localeName,
    'routine_add_plan_to_routine',
    () => _fallback.routine_add_plan_to_routine,
  );

  @override
  String get routine_load_error => TolgeeBridge.get(
    localeName,
    'routine_load_error',
    () => _fallback.routine_load_error,
  );

  @override
  String get routine_empty_block_title_singular => TolgeeBridge.get(
    localeName,
    'routine_empty_block_title_singular',
    () => _fallback.routine_empty_block_title_singular,
  );

  @override
  String routine_empty_block_title_plural(int count) => TolgeeBridge.format(
    localeName,
    'routine_empty_block_title_plural',
    <String, Object>{'count': count},
    () => _fallback.routine_empty_block_title_plural(count),
  );

  @override
  String get routine_empty_block_message_singular => TolgeeBridge.get(
    localeName,
    'routine_empty_block_message_singular',
    () => _fallback.routine_empty_block_message_singular,
  );

  @override
  String routine_empty_block_message_plural(int count) => TolgeeBridge.format(
    localeName,
    'routine_empty_block_message_plural',
    <String, Object>{'count': count},
    () => _fallback.routine_empty_block_message_plural(count),
  );

  @override
  String get routine_empty_block_add_items => TolgeeBridge.get(
    localeName,
    'routine_empty_block_add_items',
    () => _fallback.routine_empty_block_add_items,
  );

  @override
  String get routine_empty_block_delete_singular => TolgeeBridge.get(
    localeName,
    'routine_empty_block_delete_singular',
    () => _fallback.routine_empty_block_delete_singular,
  );

  @override
  String get routine_empty_block_delete_plural => TolgeeBridge.get(
    localeName,
    'routine_empty_block_delete_plural',
    () => _fallback.routine_empty_block_delete_plural,
  );

  @override
  String get routine_notification_title => TolgeeBridge.get(
    localeName,
    'routine_notification_title',
    () => _fallback.routine_notification_title,
  );

  @override
  String get routine_notification_description => TolgeeBridge.get(
    localeName,
    'routine_notification_description',
    () => _fallback.routine_notification_description,
  );

  @override
  String get routine_notification_enable => TolgeeBridge.get(
    localeName,
    'routine_notification_enable',
    () => _fallback.routine_notification_enable,
  );

  @override
  String get routine_notification_skip => TolgeeBridge.get(
    localeName,
    'routine_notification_skip',
    () => _fallback.routine_notification_skip,
  );

  @override
  String routine_time_adjusted(String time, int gap) => TolgeeBridge.format(
    localeName,
    'routine_time_adjusted',
    <String, Object>{'time': time, 'gap': gap},
    () => _fallback.routine_time_adjusted(time, gap),
  );

  @override
  String get routine_add_block_label => TolgeeBridge.get(
    localeName,
    'routine_add_block_label',
    () => _fallback.routine_add_block_label,
  );

  @override
  String get continueWithGoogle => TolgeeBridge.get(
    localeName,
    'continueWithGoogle',
    () => _fallback.continueWithGoogle,
  );

  @override
  String get continueWithApple => TolgeeBridge.get(
    localeName,
    'continueWithApple',
    () => _fallback.continueWithApple,
  );

  @override
  String get continueWithPhone => TolgeeBridge.get(
    localeName,
    'continueWithPhone',
    () => _fallback.continueWithPhone,
  );

  @override
  String get exploreAsGuest => TolgeeBridge.get(
    localeName,
    'exploreAsGuest',
    () => _fallback.exploreAsGuest,
  );

  @override
  String get signIn =>
      TolgeeBridge.get(localeName, 'signIn', () => _fallback.signIn);

  @override
  String get profileError => TolgeeBridge.get(
    localeName,
    'profileError',
    () => _fallback.profileError,
  );

  @override
  String get profileTitle => TolgeeBridge.get(
    localeName,
    'profileTitle',
    () => _fallback.profileTitle,
  );

  @override
  String get notLoggedIn =>
      TolgeeBridge.get(localeName, 'notLoggedIn', () => _fallback.notLoggedIn);

  @override
  String get retry =>
      TolgeeBridge.get(localeName, 'retry', () => _fallback.retry);

  @override
  String get back => TolgeeBridge.get(localeName, 'back', () => _fallback.back);

  @override
  String get delete =>
      TolgeeBridge.get(localeName, 'delete', () => _fallback.delete);

  @override
  String get close =>
      TolgeeBridge.get(localeName, 'close', () => _fallback.close);

  @override
  String get tryAgain =>
      TolgeeBridge.get(localeName, 'tryAgain', () => _fallback.tryAgain);

  @override
  String get pleaseTryAgain => TolgeeBridge.get(
    localeName,
    'pleaseTryAgain',
    () => _fallback.pleaseTryAgain,
  );

  @override
  String get error =>
      TolgeeBridge.get(localeName, 'error', () => _fallback.error);

  @override
  String get anonymous =>
      TolgeeBridge.get(localeName, 'anonymous', () => _fallback.anonymous);

  @override
  String get noContentAvailable => TolgeeBridge.get(
    localeName,
    'noContentAvailable',
    () => _fallback.noContentAvailable,
  );

  @override
  String get unableToLoad => TolgeeBridge.get(
    localeName,
    'unableToLoad',
    () => _fallback.unableToLoad,
  );

  @override
  String get somethingWrong => TolgeeBridge.get(
    localeName,
    'somethingWrong',
    () => _fallback.somethingWrong,
  );

  @override
  String get source =>
      TolgeeBridge.get(localeName, 'source', () => _fallback.source);

  @override
  String get noTasks =>
      TolgeeBridge.get(localeName, 'noTasks', () => _fallback.noTasks);

  @override
  String get taskNotFound => TolgeeBridge.get(
    localeName,
    'taskNotFound',
    () => _fallback.taskNotFound,
  );

  @override
  String get updateTaskError => TolgeeBridge.get(
    localeName,
    'updateTaskError',
    () => _fallback.updateTaskError,
  );

  @override
  String get enrollError =>
      TolgeeBridge.get(localeName, 'enrollError', () => _fallback.enrollError);

  @override
  String unenrollSuccess(String planTitle) => TolgeeBridge.format(
    localeName,
    'unenrollSuccess',
    <String, Object>{'planTitle': planTitle},
    () => _fallback.unenrollSuccess(planTitle),
  );

  @override
  String get unenrollError => TolgeeBridge.get(
    localeName,
    'unenrollError',
    () => _fallback.unenrollError,
  );

  @override
  String get unenrollGenericError => TolgeeBridge.get(
    localeName,
    'unenrollGenericError',
    () => _fallback.unenrollGenericError,
  );

  @override
  String get notFound =>
      TolgeeBridge.get(localeName, 'notFound', () => _fallback.notFound);

  @override
  String get noTimeSlot =>
      TolgeeBridge.get(localeName, 'noTimeSlot', () => _fallback.noTimeSlot);

  @override
  String maxBlocks(int max) => TolgeeBridge.format(
    localeName,
    'maxBlocks',
    <String, Object>{'max': max},
    () => _fallback.maxBlocks(max),
  );

  @override
  String get duplicateItem => TolgeeBridge.get(
    localeName,
    'duplicateItem',
    () => _fallback.duplicateItem,
  );

  @override
  String get removeItem =>
      TolgeeBridge.get(localeName, 'removeItem', () => _fallback.removeItem);

  @override
  String removeConfirmation(String itemName) => TolgeeBridge.format(
    localeName,
    'removeConfirmation',
    <String, Object>{'itemName': itemName},
    () => _fallback.removeConfirmation(itemName),
  );

  @override
  String shareError(String error) => TolgeeBridge.format(
    localeName,
    'shareError',
    <String, Object>{'error': error},
    () => _fallback.shareError(error),
  );

  @override
  String get captureError => TolgeeBridge.get(
    localeName,
    'captureError',
    () => _fallback.captureError,
  );

  @override
  String get qrShareError => TolgeeBridge.get(
    localeName,
    'qrShareError',
    () => _fallback.qrShareError,
  );

  @override
  String errorDetail(String error) => TolgeeBridge.format(
    localeName,
    'errorDetail',
    <String, Object>{'error': error},
    () => _fallback.errorDetail(error),
  );

  @override
  String missedDaysCount(int count) => TolgeeBridge.format(
    localeName,
    'missedDaysCount',
    <String, Object>{'count': count},
    () => _fallback.missedDaysCount(count),
  );

  @override
  String get plan_status_on_track => TolgeeBridge.get(
    localeName,
    'plan_status_on_track',
    () => _fallback.plan_status_on_track,
  );

  @override
  String get start_now =>
      TolgeeBridge.get(localeName, 'start_now', () => _fallback.start_now);

  @override
  String get plan_enroll =>
      TolgeeBridge.get(localeName, 'plan_enroll', () => _fallback.plan_enroll);

  @override
  String get root_text =>
      TolgeeBridge.get(localeName, 'root_text', () => _fallback.root_text);

  @override
  String get version =>
      TolgeeBridge.get(localeName, 'version', () => _fallback.version);

  @override
  String get reader_languages_title => TolgeeBridge.get(
    localeName,
    'reader_languages_title',
    () => _fallback.reader_languages_title,
  );

  @override
  String get reader_sections_title => TolgeeBridge.get(
    localeName,
    'reader_sections_title',
    () => _fallback.reader_sections_title,
  );

  @override
  String get reader_original_label => TolgeeBridge.get(
    localeName,
    'reader_original_label',
    () => _fallback.reader_original_label,
  );

  @override
  String get reader_translation_label => TolgeeBridge.get(
    localeName,
    'reader_translation_label',
    () => _fallback.reader_translation_label,
  );

  @override
  String get version_not_available => TolgeeBridge.get(
    localeName,
    'version_not_available',
    () => _fallback.version_not_available,
  );

  @override
  String series_stats(int planCount, int totalDays) => TolgeeBridge.format(
    localeName,
    'series_stats',
    <String, Object>{'planCount': planCount, 'totalDays': totalDays},
    () => _fallback.series_stats(planCount, totalDays),
  );

  @override
  String get force_update_title => TolgeeBridge.get(
    localeName,
    'force_update_title',
    () => _fallback.force_update_title,
  );

  @override
  String get force_update_message => TolgeeBridge.get(
    localeName,
    'force_update_message',
    () => _fallback.force_update_message,
  );

  @override
  String get force_update_button => TolgeeBridge.get(
    localeName,
    'force_update_button',
    () => _fallback.force_update_button,
  );

  @override
  String get settings_section_personalisation => TolgeeBridge.get(
    localeName,
    'settings_section_personalisation',
    () => _fallback.settings_section_personalisation,
  );

  @override
  String get settings_section_more => TolgeeBridge.get(
    localeName,
    'settings_section_more',
    () => _fallback.settings_section_more,
  );

  @override
  String get settings_section_account => TolgeeBridge.get(
    localeName,
    'settings_section_account',
    () => _fallback.settings_section_account,
  );

  @override
  String get settings_edit_profile => TolgeeBridge.get(
    localeName,
    'settings_edit_profile',
    () => _fallback.settings_edit_profile,
  );

  @override
  String get settings_theme => TolgeeBridge.get(
    localeName,
    'settings_theme',
    () => _fallback.settings_theme,
  );

  @override
  String get settings_notification_row => TolgeeBridge.get(
    localeName,
    'settings_notification_row',
    () => _fallback.settings_notification_row,
  );

  @override
  String get settings_feedback_row => TolgeeBridge.get(
    localeName,
    'settings_feedback_row',
    () => _fallback.settings_feedback_row,
  );

  @override
  String get edit_profile_title => TolgeeBridge.get(
    localeName,
    'edit_profile_title',
    () => _fallback.edit_profile_title,
  );

  @override
  String get edit_profile_save => TolgeeBridge.get(
    localeName,
    'edit_profile_save',
    () => _fallback.edit_profile_save,
  );

  @override
  String get edit_profile_display_name => TolgeeBridge.get(
    localeName,
    'edit_profile_display_name',
    () => _fallback.edit_profile_display_name,
  );

  @override
  String get edit_profile_bio => TolgeeBridge.get(
    localeName,
    'edit_profile_bio',
    () => _fallback.edit_profile_bio,
  );

  @override
  String get edit_profile_bio_hint => TolgeeBridge.get(
    localeName,
    'edit_profile_bio_hint',
    () => _fallback.edit_profile_bio_hint,
  );

  @override
  String get edit_profile_delete_account => TolgeeBridge.get(
    localeName,
    'edit_profile_delete_account',
    () => _fallback.edit_profile_delete_account,
  );

  @override
  String get edit_profile_photo_not_uploaded => TolgeeBridge.get(
    localeName,
    'edit_profile_photo_not_uploaded',
    () => _fallback.edit_profile_photo_not_uploaded,
  );

  @override
  String get edit_profile_photo_too_large => TolgeeBridge.get(
    localeName,
    'edit_profile_photo_too_large',
    () => _fallback.edit_profile_photo_too_large,
  );

  @override
  String get edit_profile_photo_upload_failed => TolgeeBridge.get(
    localeName,
    'edit_profile_photo_upload_failed',
    () => _fallback.edit_profile_photo_upload_failed,
  );

  @override
  String get edit_profile_choose_from_library => TolgeeBridge.get(
    localeName,
    'edit_profile_choose_from_library',
    () => _fallback.edit_profile_choose_from_library,
  );

  @override
  String get edit_profile_take_photo => TolgeeBridge.get(
    localeName,
    'edit_profile_take_photo',
    () => _fallback.edit_profile_take_photo,
  );

  @override
  String get edit_profile_offline => TolgeeBridge.get(
    localeName,
    'edit_profile_offline',
    () => _fallback.edit_profile_offline,
  );

  @override
  String get edit_profile_save_failed => TolgeeBridge.get(
    localeName,
    'edit_profile_save_failed',
    () => _fallback.edit_profile_save_failed,
  );

  @override
  String get edit_profile_traditions => TolgeeBridge.get(
    localeName,
    'edit_profile_traditions',
    () => _fallback.edit_profile_traditions,
  );

  @override
  String get edit_profile_choose_traditions => TolgeeBridge.get(
    localeName,
    'edit_profile_choose_traditions',
    () => _fallback.edit_profile_choose_traditions,
  );

  @override
  String get edit_profile_tradition_remove_failed => TolgeeBridge.get(
    localeName,
    'edit_profile_tradition_remove_failed',
    () => _fallback.edit_profile_tradition_remove_failed,
  );

  @override
  String get edit_profile_tradition_save_failed => TolgeeBridge.get(
    localeName,
    'edit_profile_tradition_save_failed',
    () => _fallback.edit_profile_tradition_save_failed,
  );

  @override
  String get username_label => TolgeeBridge.get(
    localeName,
    'username_label',
    () => _fallback.username_label,
  );

  @override
  String get username_taken => TolgeeBridge.get(
    localeName,
    'username_taken',
    () => _fallback.username_taken,
  );

  @override
  String get username_available_label => TolgeeBridge.get(
    localeName,
    'username_available_label',
    () => _fallback.username_available_label,
  );

  @override
  String get username_check_error => TolgeeBridge.get(
    localeName,
    'username_check_error',
    () => _fallback.username_check_error,
  );

  @override
  String get username_invalid_format => TolgeeBridge.get(
    localeName,
    'username_invalid_format',
    () => _fallback.username_invalid_format,
  );

  @override
  String get username_min_length => TolgeeBridge.get(
    localeName,
    'username_min_length',
    () => _fallback.username_min_length,
  );

  @override
  String get username_max_length => TolgeeBridge.get(
    localeName,
    'username_max_length',
    () => _fallback.username_max_length,
  );

  @override
  String get username_no_spaces => TolgeeBridge.get(
    localeName,
    'username_no_spaces',
    () => _fallback.username_no_spaces,
  );

  @override
  String get username_invalid_chars => TolgeeBridge.get(
    localeName,
    'username_invalid_chars',
    () => _fallback.username_invalid_chars,
  );

  @override
  String get username_must_start_alphanumeric => TolgeeBridge.get(
    localeName,
    'username_must_start_alphanumeric',
    () => _fallback.username_must_start_alphanumeric,
  );

  @override
  String get username_must_end_alphanumeric => TolgeeBridge.get(
    localeName,
    'username_must_end_alphanumeric',
    () => _fallback.username_must_end_alphanumeric,
  );

  @override
  String get person_name_min_length => TolgeeBridge.get(
    localeName,
    'person_name_min_length',
    () => _fallback.person_name_min_length,
  );

  @override
  String get person_name_max_length => TolgeeBridge.get(
    localeName,
    'person_name_max_length',
    () => _fallback.person_name_max_length,
  );

  @override
  String get person_name_invalid_chars => TolgeeBridge.get(
    localeName,
    'person_name_invalid_chars',
    () => _fallback.person_name_invalid_chars,
  );

  @override
  String get about_title =>
      TolgeeBridge.get(localeName, 'about_title', () => _fallback.about_title);

  @override
  String get about_connect_with_us => TolgeeBridge.get(
    localeName,
    'about_connect_with_us',
    () => _fallback.about_connect_with_us,
  );

  @override
  String get about_description => TolgeeBridge.get(
    localeName,
    'about_description',
    () => _fallback.about_description,
  );

  @override
  String get about_social_website => TolgeeBridge.get(
    localeName,
    'about_social_website',
    () => _fallback.about_social_website,
  );

  @override
  String get me_guest_headline => TolgeeBridge.get(
    localeName,
    'me_guest_headline',
    () => _fallback.me_guest_headline,
  );

  @override
  String get me_guest_subtitle => TolgeeBridge.get(
    localeName,
    'me_guest_subtitle',
    () => _fallback.me_guest_subtitle,
  );

  @override
  String get me_my_stats =>
      TolgeeBridge.get(localeName, 'me_my_stats', () => _fallback.me_my_stats);

  @override
  String me_day_streak(int count) => TolgeeBridge.format(
    localeName,
    'me_day_streak',
    <String, Object>{'count': count},
    () => _fallback.me_day_streak(count),
  );

  @override
  String me_best_streak(int count) => TolgeeBridge.format(
    localeName,
    'me_best_streak',
    <String, Object>{'count': count},
    () => _fallback.me_best_streak(count),
  );

  @override
  String get accumulations => TolgeeBridge.get(
    localeName,
    'accumulations',
    () => _fallback.accumulations,
  );

  @override
  String get accumulations_search => TolgeeBridge.get(
    localeName,
    'accumulations_search',
    () => _fallback.accumulations_search,
  );

  @override
  String get accumulations_search_for => TolgeeBridge.get(
    localeName,
    'accumulations_search_for',
    () => _fallback.accumulations_search_for,
  );

  @override
  String get accumulations_no_found => TolgeeBridge.get(
    localeName,
    'accumulations_no_found',
    () => _fallback.accumulations_no_found,
  );

  @override
  String get me_accumulation => TolgeeBridge.get(
    localeName,
    'me_accumulation',
    () => _fallback.me_accumulation,
  );

  @override
  String get me_minutes =>
      TolgeeBridge.get(localeName, 'me_minutes', () => _fallback.me_minutes);

  @override
  String get me_hours =>
      TolgeeBridge.get(localeName, 'me_hours', () => _fallback.me_hours);

  @override
  String get me_total_meditation_time => TolgeeBridge.get(
    localeName,
    'me_total_meditation_time',
    () => _fallback.me_total_meditation_time,
  );

  @override
  String get me_days_plan_practiced_suffix => TolgeeBridge.get(
    localeName,
    'me_days_plan_practiced_suffix',
    () => _fallback.me_days_plan_practiced_suffix,
  );

  @override
  String get me_streak_share_quote => TolgeeBridge.get(
    localeName,
    'me_streak_share_quote',
    () => _fallback.me_streak_share_quote,
  );

  @override
  String me_streak_days_count(int count) => TolgeeBridge.format(
    localeName,
    'me_streak_days_count',
    <String, Object>{'count': count},
    () => _fallback.me_streak_days_count(count),
  );

  @override
  String get share_this_streak => TolgeeBridge.get(
    localeName,
    'share_this_streak',
    () => _fallback.share_this_streak,
  );

  @override
  String get me_streak_share_error => TolgeeBridge.get(
    localeName,
    'me_streak_share_error',
    () => _fallback.me_streak_share_error,
  );

  @override
  String get delete_account_title => TolgeeBridge.get(
    localeName,
    'delete_account_title',
    () => _fallback.delete_account_title,
  );

  @override
  String get delete_account_description => TolgeeBridge.get(
    localeName,
    'delete_account_description',
    () => _fallback.delete_account_description,
  );

  @override
  String get delete_account_button => TolgeeBridge.get(
    localeName,
    'delete_account_button',
    () => _fallback.delete_account_button,
  );

  @override
  String get delete_account_confirm_message => TolgeeBridge.get(
    localeName,
    'delete_account_confirm_message',
    () => _fallback.delete_account_confirm_message,
  );

  @override
  String get legal_title =>
      TolgeeBridge.get(localeName, 'legal_title', () => _fallback.legal_title);

  @override
  String get legal_terms_of_service => TolgeeBridge.get(
    localeName,
    'legal_terms_of_service',
    () => _fallback.legal_terms_of_service,
  );

  @override
  String get legal_privacy_policy => TolgeeBridge.get(
    localeName,
    'legal_privacy_policy',
    () => _fallback.legal_privacy_policy,
  );

  @override
  String get follow =>
      TolgeeBridge.get(localeName, 'follow', () => _fallback.follow);

  @override
  String get calendar_title => TolgeeBridge.get(
    localeName,
    'calendar_title',
    () => _fallback.calendar_title,
  );

  @override
  String get calendar_upcoming_events => TolgeeBridge.get(
    localeName,
    'calendar_upcoming_events',
    () => _fallback.calendar_upcoming_events,
  );

  @override
  String get calendar_day_short => TolgeeBridge.get(
    localeName,
    'calendar_day_short',
    () => _fallback.calendar_day_short,
  );

  @override
  String get calendar_day_label => TolgeeBridge.get(
    localeName,
    'calendar_day_label',
    () => _fallback.calendar_day_label,
  );

  @override
  String calendar_lunar_month(String ordinal) => TolgeeBridge.format(
    localeName,
    'calendar_lunar_month',
    <String, Object>{'ordinal': ordinal},
    () => _fallback.calendar_lunar_month(ordinal),
  );

  @override
  String get moon_phase_new_moon => TolgeeBridge.get(
    localeName,
    'moon_phase_new_moon',
    () => _fallback.moon_phase_new_moon,
  );

  @override
  String get moon_phase_first_quarter => TolgeeBridge.get(
    localeName,
    'moon_phase_first_quarter',
    () => _fallback.moon_phase_first_quarter,
  );

  @override
  String get moon_phase_full_moon => TolgeeBridge.get(
    localeName,
    'moon_phase_full_moon',
    () => _fallback.moon_phase_full_moon,
  );

  @override
  String get join => TolgeeBridge.get(localeName, 'join', () => _fallback.join);

  @override
  String get group_member => TolgeeBridge.get(
    localeName,
    'group_member',
    () => _fallback.group_member,
  );

  @override
  String get group_members => TolgeeBridge.get(
    localeName,
    'group_members',
    () => _fallback.group_members,
  );

  @override
  String get group_tab_members => TolgeeBridge.get(
    localeName,
    'group_tab_members',
    () => _fallback.group_tab_members,
  );

  @override
  String get group_tab_followers => TolgeeBridge.get(
    localeName,
    'group_tab_followers',
    () => _fallback.group_tab_followers,
  );

  @override
  String group_members_heading(int count) => TolgeeBridge.format(
    localeName,
    'group_members_heading',
    <String, Object>{'count': count},
    () => _fallback.group_members_heading(count),
  );

  @override
  String group_followers_heading(int count) => TolgeeBridge.format(
    localeName,
    'group_followers_heading',
    <String, Object>{'count': count},
    () => _fallback.group_followers_heading(count),
  );

  @override
  String get group_invite => TolgeeBridge.get(
    localeName,
    'group_invite',
    () => _fallback.group_invite,
  );

  @override
  String get group_notifications_title => TolgeeBridge.get(
    localeName,
    'group_notifications_title',
    () => _fallback.group_notifications_title,
  );

  @override
  String get group_notifications_chat => TolgeeBridge.get(
    localeName,
    'group_notifications_chat',
    () => _fallback.group_notifications_chat,
  );

  @override
  String get group_notifications_content => TolgeeBridge.get(
    localeName,
    'group_notifications_content',
    () => _fallback.group_notifications_content,
  );

  @override
  String get group_notifications_master_off => TolgeeBridge.get(
    localeName,
    'group_notifications_master_off',
    () => _fallback.group_notifications_master_off,
  );

  @override
  String get group_notifications_open_settings => TolgeeBridge.get(
    localeName,
    'group_notifications_open_settings',
    () => _fallback.group_notifications_open_settings,
  );

  @override
  String get group_notifications_update_failed => TolgeeBridge.get(
    localeName,
    'group_notifications_update_failed',
    () => _fallback.group_notifications_update_failed,
  );

  @override
  String get group_notifications_load_failed => TolgeeBridge.get(
    localeName,
    'group_notifications_load_failed',
    () => _fallback.group_notifications_load_failed,
  );

  @override
  String get group_chat_mute_notifications => TolgeeBridge.get(
    localeName,
    'group_chat_mute_notifications',
    () => _fallback.group_chat_mute_notifications,
  );

  @override
  String get group_chat_unmute_notifications => TolgeeBridge.get(
    localeName,
    'group_chat_unmute_notifications',
    () => _fallback.group_chat_unmute_notifications,
  );

  @override
  String get group_chat_notifications_muted => TolgeeBridge.get(
    localeName,
    'group_chat_notifications_muted',
    () => _fallback.group_chat_notifications_muted,
  );

  @override
  String get group_chat_notifications_unmuted => TolgeeBridge.get(
    localeName,
    'group_chat_notifications_unmuted',
    () => _fallback.group_chat_notifications_unmuted,
  );

  @override
  String get group_leave_confirm_message => TolgeeBridge.get(
    localeName,
    'group_leave_confirm_message',
    () => _fallback.group_leave_confirm_message,
  );

  @override
  String get group_leave_space => TolgeeBridge.get(
    localeName,
    'group_leave_space',
    () => _fallback.group_leave_space,
  );

  @override
  String get group_leave_space_confirm_title => TolgeeBridge.get(
    localeName,
    'group_leave_space_confirm_title',
    () => _fallback.group_leave_space_confirm_title,
  );

  @override
  String get group_leave_space_failed => TolgeeBridge.get(
    localeName,
    'group_leave_space_failed',
    () => _fallback.group_leave_space_failed,
  );

  @override
  String get group_request_to_join => TolgeeBridge.get(
    localeName,
    'group_request_to_join',
    () => _fallback.group_request_to_join,
  );

  @override
  String get group_request => TolgeeBridge.get(
    localeName,
    'group_request',
    () => _fallback.group_request,
  );

  @override
  String get group_request_sent => TolgeeBridge.get(
    localeName,
    'group_request_sent',
    () => _fallback.group_request_sent,
  );

  @override
  String get group_join_request_title => TolgeeBridge.get(
    localeName,
    'group_join_request_title',
    () => _fallback.group_join_request_title,
  );

  @override
  String get group_join_request_message_label => TolgeeBridge.get(
    localeName,
    'group_join_request_message_label',
    () => _fallback.group_join_request_message_label,
  );

  @override
  String get group_join_request_message_hint => TolgeeBridge.get(
    localeName,
    'group_join_request_message_hint',
    () => _fallback.group_join_request_message_hint,
  );

  @override
  String get group_join_request_send => TolgeeBridge.get(
    localeName,
    'group_join_request_send',
    () => _fallback.group_join_request_send,
  );

  @override
  String get group_join_request_sent_snackbar => TolgeeBridge.get(
    localeName,
    'group_join_request_sent_snackbar',
    () => _fallback.group_join_request_sent_snackbar,
  );

  @override
  String get group_join_request_error => TolgeeBridge.get(
    localeName,
    'group_join_request_error',
    () => _fallback.group_join_request_error,
  );

  @override
  String get group_join_requests_title => TolgeeBridge.get(
    localeName,
    'group_join_requests_title',
    () => _fallback.group_join_requests_title,
  );

  @override
  String get group_join_requests_admit => TolgeeBridge.get(
    localeName,
    'group_join_requests_admit',
    () => _fallback.group_join_requests_admit,
  );

  @override
  String get group_join_requests_deny => TolgeeBridge.get(
    localeName,
    'group_join_requests_deny',
    () => _fallback.group_join_requests_deny,
  );

  @override
  String get group_join_requests_empty => TolgeeBridge.get(
    localeName,
    'group_join_requests_empty',
    () => _fallback.group_join_requests_empty,
  );

  @override
  String get group_join_requests_load_error => TolgeeBridge.get(
    localeName,
    'group_join_requests_load_error',
    () => _fallback.group_join_requests_load_error,
  );

  @override
  String get group_join_requests_admit_error => TolgeeBridge.get(
    localeName,
    'group_join_requests_admit_error',
    () => _fallback.group_join_requests_admit_error,
  );

  @override
  String get group_join_requests_deny_error => TolgeeBridge.get(
    localeName,
    'group_join_requests_deny_error',
    () => _fallback.group_join_requests_deny_error,
  );

  @override
  String get group_reports_title => TolgeeBridge.get(
    localeName,
    'group_reports_title',
    () => _fallback.group_reports_title,
  );

  @override
  String get group_reports_section_posts => TolgeeBridge.get(
    localeName,
    'group_reports_section_posts',
    () => _fallback.group_reports_section_posts,
  );

  @override
  String get group_reports_section_comments => TolgeeBridge.get(
    localeName,
    'group_reports_section_comments',
    () => _fallback.group_reports_section_comments,
  );

  @override
  String get group_reports_section_messages => TolgeeBridge.get(
    localeName,
    'group_reports_section_messages',
    () => _fallback.group_reports_section_messages,
  );

  @override
  String group_reports_count(int count) => TolgeeBridge.format(
    localeName,
    'group_reports_count',
    <String, Object>{'count': count},
    () => _fallback.group_reports_count(count),
  );

  @override
  String get group_reports_view_post => TolgeeBridge.get(
    localeName,
    'group_reports_view_post',
    () => _fallback.group_reports_view_post,
  );

  @override
  String get group_reports_view_message => TolgeeBridge.get(
    localeName,
    'group_reports_view_message',
    () => _fallback.group_reports_view_message,
  );

  @override
  String get group_reports_delete_post => TolgeeBridge.get(
    localeName,
    'group_reports_delete_post',
    () => _fallback.group_reports_delete_post,
  );

  @override
  String get group_reports_delete_comment => TolgeeBridge.get(
    localeName,
    'group_reports_delete_comment',
    () => _fallback.group_reports_delete_comment,
  );

  @override
  String get group_reports_delete_message => TolgeeBridge.get(
    localeName,
    'group_reports_delete_message',
    () => _fallback.group_reports_delete_message,
  );

  @override
  String get group_reports_empty => TolgeeBridge.get(
    localeName,
    'group_reports_empty',
    () => _fallback.group_reports_empty,
  );

  @override
  String get group_reports_load_error => TolgeeBridge.get(
    localeName,
    'group_reports_load_error',
    () => _fallback.group_reports_load_error,
  );

  @override
  String get group_reports_delete_confirm_title => TolgeeBridge.get(
    localeName,
    'group_reports_delete_confirm_title',
    () => _fallback.group_reports_delete_confirm_title,
  );

  @override
  String get group_reports_delete_message_confirm => TolgeeBridge.get(
    localeName,
    'group_reports_delete_message_confirm',
    () => _fallback.group_reports_delete_message_confirm,
  );

  @override
  String get group_reports_message_removed => TolgeeBridge.get(
    localeName,
    'group_reports_message_removed',
    () => _fallback.group_reports_message_removed,
  );

  @override
  String get group_reports_delete_message_error => TolgeeBridge.get(
    localeName,
    'group_reports_delete_message_error',
    () => _fallback.group_reports_delete_message_error,
  );

  @override
  String get group_members_only_title => TolgeeBridge.get(
    localeName,
    'group_members_only_title',
    () => _fallback.group_members_only_title,
  );

  @override
  String get group_members_only_message => TolgeeBridge.get(
    localeName,
    'group_members_only_message',
    () => _fallback.group_members_only_message,
  );

  @override
  String get group_join_request_waiting_title => TolgeeBridge.get(
    localeName,
    'group_join_request_waiting_title',
    () => _fallback.group_join_request_waiting_title,
  );

  @override
  String get group_join_request_waiting_message => TolgeeBridge.get(
    localeName,
    'group_join_request_waiting_message',
    () => _fallback.group_join_request_waiting_message,
  );

  @override
  String get group_members_load_error => TolgeeBridge.get(
    localeName,
    'group_members_load_error',
    () => _fallback.group_members_load_error,
  );

  @override
  String get group_followers_load_error => TolgeeBridge.get(
    localeName,
    'group_followers_load_error',
    () => _fallback.group_followers_load_error,
  );

  @override
  String get group_members_empty => TolgeeBridge.get(
    localeName,
    'group_members_empty',
    () => _fallback.group_members_empty,
  );

  @override
  String get group_member_admin => TolgeeBridge.get(
    localeName,
    'group_member_admin',
    () => _fallback.group_member_admin,
  );

  @override
  String get group_member_owner => TolgeeBridge.get(
    localeName,
    'group_member_owner',
    () => _fallback.group_member_owner,
  );

  @override
  String group_remove_member(String name) => TolgeeBridge.format(
    localeName,
    'group_remove_member',
    <String, Object>{'name': name},
    () => _fallback.group_remove_member(name),
  );

  @override
  String get group_remove_member_title => TolgeeBridge.get(
    localeName,
    'group_remove_member_title',
    () => _fallback.group_remove_member_title,
  );

  @override
  String group_remove_member_message(String name) => TolgeeBridge.format(
    localeName,
    'group_remove_member_message',
    <String, Object>{'name': name},
    () => _fallback.group_remove_member_message(name),
  );

  @override
  String get group_remove_member_blocked_for => TolgeeBridge.get(
    localeName,
    'group_remove_member_blocked_for',
    () => _fallback.group_remove_member_blocked_for,
  );

  @override
  String get group_remove_member_duration_day => TolgeeBridge.get(
    localeName,
    'group_remove_member_duration_day',
    () => _fallback.group_remove_member_duration_day,
  );

  @override
  String group_remove_member_duration_days(int count) => TolgeeBridge.format(
    localeName,
    'group_remove_member_duration_days',
    <String, Object>{'count': count},
    () => _fallback.group_remove_member_duration_days(count),
  );

  @override
  String get group_remove_member_duration_year => TolgeeBridge.get(
    localeName,
    'group_remove_member_duration_year',
    () => _fallback.group_remove_member_duration_year,
  );

  @override
  String get group_remove_member_reason_label => TolgeeBridge.get(
    localeName,
    'group_remove_member_reason_label',
    () => _fallback.group_remove_member_reason_label,
  );

  @override
  String get group_remove_member_reason_hint => TolgeeBridge.get(
    localeName,
    'group_remove_member_reason_hint',
    () => _fallback.group_remove_member_reason_hint,
  );

  @override
  String get group_remove_member_action => TolgeeBridge.get(
    localeName,
    'group_remove_member_action',
    () => _fallback.group_remove_member_action,
  );

  @override
  String group_remove_member_success(String name) => TolgeeBridge.format(
    localeName,
    'group_remove_member_success',
    <String, Object>{'name': name},
    () => _fallback.group_remove_member_success(name),
  );

  @override
  String get group_remove_member_error => TolgeeBridge.get(
    localeName,
    'group_remove_member_error',
    () => _fallback.group_remove_member_error,
  );

  @override
  String group_join_banned_until(String date) => TolgeeBridge.format(
    localeName,
    'group_join_banned_until',
    <String, Object>{'date': date},
    () => _fallback.group_join_banned_until(date),
  );

  @override
  String get group_join_banned => TolgeeBridge.get(
    localeName,
    'group_join_banned',
    () => _fallback.group_join_banned,
  );

  @override
  String get group_removed_title => TolgeeBridge.get(
    localeName,
    'group_removed_title',
    () => _fallback.group_removed_title,
  );

  @override
  String group_removed_message(String group, String duration) =>
      TolgeeBridge.format(
        localeName,
        'group_removed_message',
        <String, Object>{'group': group, 'duration': duration},
        () => _fallback.group_removed_message(group, duration),
      );

  @override
  String group_removed_message_no_date(String group) => TolgeeBridge.format(
    localeName,
    'group_removed_message_no_date',
    <String, Object>{'group': group},
    () => _fallback.group_removed_message_no_date(group),
  );

  @override
  String get group_removed_rejoin_label => TolgeeBridge.get(
    localeName,
    'group_removed_rejoin_label',
    () => _fallback.group_removed_rejoin_label,
  );

  @override
  String group_removed_rejoin_value(String date, String remaining) =>
      TolgeeBridge.format(
        localeName,
        'group_removed_rejoin_value',
        <String, Object>{'date': date, 'remaining': remaining},
        () => _fallback.group_removed_rejoin_value(date, remaining),
      );

  @override
  String get group_removed_day_left => TolgeeBridge.get(
    localeName,
    'group_removed_day_left',
    () => _fallback.group_removed_day_left,
  );

  @override
  String group_removed_days_left(int count) => TolgeeBridge.format(
    localeName,
    'group_removed_days_left',
    <String, Object>{'count': count},
    () => _fallback.group_removed_days_left(count),
  );

  @override
  String get group_removed_last_day => TolgeeBridge.get(
    localeName,
    'group_removed_last_day',
    () => _fallback.group_removed_last_day,
  );

  @override
  String get group_followers_empty => TolgeeBridge.get(
    localeName,
    'group_followers_empty',
    () => _fallback.group_followers_empty,
  );

  @override
  String get group_follower => TolgeeBridge.get(
    localeName,
    'group_follower',
    () => _fallback.group_follower,
  );

  @override
  String get group_followers => TolgeeBridge.get(
    localeName,
    'group_followers',
    () => _fallback.group_followers,
  );

  @override
  String get group_links_title => TolgeeBridge.get(
    localeName,
    'group_links_title',
    () => _fallback.group_links_title,
  );

  @override
  String get group_about_description => TolgeeBridge.get(
    localeName,
    'group_about_description',
    () => _fallback.group_about_description,
  );

  @override
  String get group_about_empty => TolgeeBridge.get(
    localeName,
    'group_about_empty',
    () => _fallback.group_about_empty,
  );

  @override
  String group_and_more_links(int count) => TolgeeBridge.format(
    localeName,
    'group_and_more_links',
    <String, Object>{'count': count},
    () => _fallback.group_and_more_links(count),
  );

  @override
  String get group_practice_with_us => TolgeeBridge.get(
    localeName,
    'group_practice_with_us',
    () => _fallback.group_practice_with_us,
  );

  @override
  String series_practicing_with_group(String groupName) => TolgeeBridge.format(
    localeName,
    'series_practicing_with_group',
    <String, Object>{'groupName': groupName},
    () => _fallback.series_practicing_with_group(groupName),
  );

  @override
  String get group_change_practice_title => TolgeeBridge.get(
    localeName,
    'group_change_practice_title',
    () => _fallback.group_change_practice_title,
  );

  @override
  String get group_change_practice_message => TolgeeBridge.get(
    localeName,
    'group_change_practice_message',
    () => _fallback.group_change_practice_message,
  );

  @override
  String get group_join_to_contribute => TolgeeBridge.get(
    localeName,
    'group_join_to_contribute',
    () => _fallback.group_join_to_contribute,
  );

  @override
  String get group_accumulator_join_error => TolgeeBridge.get(
    localeName,
    'group_accumulator_join_error',
    () => _fallback.group_accumulator_join_error,
  );

  @override
  String get group_accumulator_join_before_practice => TolgeeBridge.get(
    localeName,
    'group_accumulator_join_before_practice',
    () => _fallback.group_accumulator_join_before_practice,
  );

  @override
  String group_accumulator_participants(int count) => TolgeeBridge.format(
    localeName,
    'group_accumulator_participants',
    <String, Object>{'count': count},
    () => _fallback.group_accumulator_participants(count),
  );

  @override
  String get group_accumulator_leaderboard => TolgeeBridge.get(
    localeName,
    'group_accumulator_leaderboard',
    () => _fallback.group_accumulator_leaderboard,
  );

  @override
  String get group_accumulator_everyone => TolgeeBridge.get(
    localeName,
    'group_accumulator_everyone',
    () => _fallback.group_accumulator_everyone,
  );

  @override
  String get group_accumulator_me => TolgeeBridge.get(
    localeName,
    'group_accumulator_me',
    () => _fallback.group_accumulator_me,
  );

  @override
  String get group_accumulator_my_contributions => TolgeeBridge.get(
    localeName,
    'group_accumulator_my_contributions',
    () => _fallback.group_accumulator_my_contributions,
  );

  @override
  String get group_accumulator_recited => TolgeeBridge.get(
    localeName,
    'group_accumulator_recited',
    () => _fallback.group_accumulator_recited,
  );

  @override
  String get group_accumulator_total => TolgeeBridge.get(
    localeName,
    'group_accumulator_total',
    () => _fallback.group_accumulator_total,
  );

  @override
  String get group_accumulator_contributions_empty => TolgeeBridge.get(
    localeName,
    'group_accumulator_contributions_empty',
    () => _fallback.group_accumulator_contributions_empty,
  );

  @override
  String get group_accumulator_leaderboard_empty => TolgeeBridge.get(
    localeName,
    'group_accumulator_leaderboard_empty',
    () => _fallback.group_accumulator_leaderboard_empty,
  );

  @override
  String get group_accumulator_recite_now => TolgeeBridge.get(
    localeName,
    'group_accumulator_recite_now',
    () => _fallback.group_accumulator_recite_now,
  );

  @override
  String get group_accumulator_view_practice => TolgeeBridge.get(
    localeName,
    'group_accumulator_view_practice',
    () => _fallback.group_accumulator_view_practice,
  );

  @override
  String get group_accumulator_chant_again => TolgeeBridge.get(
    localeName,
    'group_accumulator_chant_again',
    () => _fallback.group_accumulator_chant_again,
  );

  @override
  String get group_accumulator_finish_session => TolgeeBridge.get(
    localeName,
    'group_accumulator_finish_session',
    () => _fallback.group_accumulator_finish_session,
  );

  @override
  String get group_accumulator_offline_recitation => TolgeeBridge.get(
    localeName,
    'group_accumulator_offline_recitation',
    () => _fallback.group_accumulator_offline_recitation,
  );

  @override
  String get group_accumulator_add_offline_chants_title => TolgeeBridge.get(
    localeName,
    'group_accumulator_add_offline_chants_title',
    () => _fallback.group_accumulator_add_offline_chants_title,
  );

  @override
  String get group_accumulator_add_offline_chants_message => TolgeeBridge.get(
    localeName,
    'group_accumulator_add_offline_chants_message',
    () => _fallback.group_accumulator_add_offline_chants_message,
  );

  @override
  String get group_accumulator_session_complete => TolgeeBridge.get(
    localeName,
    'group_accumulator_session_complete',
    () => _fallback.group_accumulator_session_complete,
  );

  @override
  String group_accumulator_session_recitations(int count) =>
      TolgeeBridge.format(
        localeName,
        'group_accumulator_session_recitations',
        <String, Object>{'count': count},
        () => _fallback.group_accumulator_session_recitations(count),
      );

  @override
  String group_accumulator_session_share_message(
    int count,
    String accumulation,
    String group,
  ) => TolgeeBridge.format(
    localeName,
    'group_accumulator_session_share_message',
    <String, Object>{
      'count': count,
      'accumulation': accumulation,
      'group': group,
    },
    () => _fallback.group_accumulator_session_share_message(
      count,
      accumulation,
      group,
    ),
  );

  @override
  String group_accumulator_session_share_message_no_group(
    int count,
    String accumulation,
  ) => TolgeeBridge.format(
    localeName,
    'group_accumulator_session_share_message_no_group',
    <String, Object>{'count': count, 'accumulation': accumulation},
    () => _fallback.group_accumulator_session_share_message_no_group(
      count,
      accumulation,
    ),
  );

  @override
  String get group_accumulator_session_share_error => TolgeeBridge.get(
    localeName,
    'group_accumulator_session_share_error',
    () => _fallback.group_accumulator_session_share_error,
  );

  @override
  String group_recitation_collection_share_message(
    String collection,
    String group,
  ) => TolgeeBridge.format(
    localeName,
    'group_recitation_collection_share_message',
    <String, Object>{'collection': collection, 'group': group},
    () =>
        _fallback.group_recitation_collection_share_message(collection, group),
  );

  @override
  String group_recitation_collection_share_message_no_group(
    String collection,
  ) => TolgeeBridge.format(
    localeName,
    'group_recitation_collection_share_message_no_group',
    <String, Object>{'collection': collection},
    () => _fallback.group_recitation_collection_share_message_no_group(
      collection,
    ),
  );

  @override
  String group_recitation_collection_completed_title(String collection) =>
      TolgeeBridge.format(
        localeName,
        'group_recitation_collection_completed_title',
        <String, Object>{'collection': collection},
        () => _fallback.group_recitation_collection_completed_title(collection),
      );

  @override
  String get group_recitation_collection_dedication => TolgeeBridge.get(
    localeName,
    'group_recitation_collection_dedication',
    () => _fallback.group_recitation_collection_dedication,
  );

  @override
  String get share_this_quote => TolgeeBridge.get(
    localeName,
    'share_this_quote',
    () => _fallback.share_this_quote,
  );

  @override
  String get shared_from =>
      TolgeeBridge.get(localeName, 'shared_from', () => _fallback.shared_from);

  @override
  String get verse_share_error => TolgeeBridge.get(
    localeName,
    'verse_share_error',
    () => _fallback.verse_share_error,
  );

  @override
  String verse_comments_title(int count) => TolgeeBridge.format(
    localeName,
    'verse_comments_title',
    <String, Object>{'count': count},
    () => _fallback.verse_comments_title(count),
  );

  @override
  String verse_likes_title(int count) => TolgeeBridge.format(
    localeName,
    'verse_likes_title',
    <String, Object>{'count': count},
    () => _fallback.verse_likes_title(count),
  );

  @override
  String get verse_like_failed => TolgeeBridge.get(
    localeName,
    'verse_like_failed',
    () => _fallback.verse_like_failed,
  );

  @override
  String get verse_comment_failed => TolgeeBridge.get(
    localeName,
    'verse_comment_failed',
    () => _fallback.verse_comment_failed,
  );

  @override
  String verse_comment_replying_to(String name) => TolgeeBridge.format(
    localeName,
    'verse_comment_replying_to',
    <String, Object>{'name': name},
    () => _fallback.verse_comment_replying_to(name),
  );

  @override
  String get share_app_message => TolgeeBridge.get(
    localeName,
    'share_app_message',
    () => _fallback.share_app_message,
  );

  @override
  String get share_streak_message => TolgeeBridge.get(
    localeName,
    'share_streak_message',
    () => _fallback.share_streak_message,
  );

  @override
  String get share_chant_message => TolgeeBridge.get(
    localeName,
    'share_chant_message',
    () => _fallback.share_chant_message,
  );

  @override
  String get share_quote_message => TolgeeBridge.get(
    localeName,
    'share_quote_message',
    () => _fallback.share_quote_message,
  );

  @override
  String get share_poem_message => TolgeeBridge.get(
    localeName,
    'share_poem_message',
    () => _fallback.share_poem_message,
  );

  @override
  String share_poem_title(String title) => TolgeeBridge.format(
    localeName,
    'share_poem_title',
    <String, Object>{'title': title},
    () => _fallback.share_poem_title(title),
  );

  @override
  String get share_mala_message => TolgeeBridge.get(
    localeName,
    'share_mala_message',
    () => _fallback.share_mala_message,
  );

  @override
  String get share_passage_message => TolgeeBridge.get(
    localeName,
    'share_passage_message',
    () => _fallback.share_passage_message,
  );

  @override
  String get share_timer_message => TolgeeBridge.get(
    localeName,
    'share_timer_message',
    () => _fallback.share_timer_message,
  );

  @override
  String get share_plan_message => TolgeeBridge.get(
    localeName,
    'share_plan_message',
    () => _fallback.share_plan_message,
  );

  @override
  String get share_plan_subject => TolgeeBridge.get(
    localeName,
    'share_plan_subject',
    () => _fallback.share_plan_subject,
  );

  @override
  String get share_group_invite_message => TolgeeBridge.get(
    localeName,
    'share_group_invite_message',
    () => _fallback.share_group_invite_message,
  );

  @override
  String get weekday_monday => TolgeeBridge.get(
    localeName,
    'weekday_monday',
    () => _fallback.weekday_monday,
  );

  @override
  String get weekday_tuesday => TolgeeBridge.get(
    localeName,
    'weekday_tuesday',
    () => _fallback.weekday_tuesday,
  );

  @override
  String get weekday_wednesday => TolgeeBridge.get(
    localeName,
    'weekday_wednesday',
    () => _fallback.weekday_wednesday,
  );

  @override
  String get weekday_thursday => TolgeeBridge.get(
    localeName,
    'weekday_thursday',
    () => _fallback.weekday_thursday,
  );

  @override
  String get weekday_friday => TolgeeBridge.get(
    localeName,
    'weekday_friday',
    () => _fallback.weekday_friday,
  );

  @override
  String get weekday_saturday => TolgeeBridge.get(
    localeName,
    'weekday_saturday',
    () => _fallback.weekday_saturday,
  );

  @override
  String get weekday_sunday => TolgeeBridge.get(
    localeName,
    'weekday_sunday',
    () => _fallback.weekday_sunday,
  );

  @override
  String get reader_search_failed => TolgeeBridge.get(
    localeName,
    'reader_search_failed',
    () => _fallback.reader_search_failed,
  );

  @override
  String get reader_swipe_up_for_more => TolgeeBridge.get(
    localeName,
    'reader_swipe_up_for_more',
    () => _fallback.reader_swipe_up_for_more,
  );

  @override
  String get reader_videos => TolgeeBridge.get(
    localeName,
    'reader_videos',
    () => _fallback.reader_videos,
  );

  @override
  String get mala_no_mantras => TolgeeBridge.get(
    localeName,
    'mala_no_mantras',
    () => _fallback.mala_no_mantras,
  );

  @override
  String get mala_count_load_error => TolgeeBridge.get(
    localeName,
    'mala_count_load_error',
    () => _fallback.mala_count_load_error,
  );

  @override
  String get bookmarks_empty_all_title => TolgeeBridge.get(
    localeName,
    'bookmarks_empty_all_title',
    () => _fallback.bookmarks_empty_all_title,
  );

  @override
  String get bookmarks_empty_all_subtitle => TolgeeBridge.get(
    localeName,
    'bookmarks_empty_all_subtitle',
    () => _fallback.bookmarks_empty_all_subtitle,
  );

  @override
  String get bookmarks_empty_plans_title => TolgeeBridge.get(
    localeName,
    'bookmarks_empty_plans_title',
    () => _fallback.bookmarks_empty_plans_title,
  );

  @override
  String get bookmarks_empty_plans_subtitle => TolgeeBridge.get(
    localeName,
    'bookmarks_empty_plans_subtitle',
    () => _fallback.bookmarks_empty_plans_subtitle,
  );

  @override
  String get bookmarks_empty_malas_title => TolgeeBridge.get(
    localeName,
    'bookmarks_empty_malas_title',
    () => _fallback.bookmarks_empty_malas_title,
  );

  @override
  String get bookmarks_empty_malas_subtitle => TolgeeBridge.get(
    localeName,
    'bookmarks_empty_malas_subtitle',
    () => _fallback.bookmarks_empty_malas_subtitle,
  );

  @override
  String get bookmarks_empty_group_accumulations_title => TolgeeBridge.get(
    localeName,
    'bookmarks_empty_group_accumulations_title',
    () => _fallback.bookmarks_empty_group_accumulations_title,
  );

  @override
  String get bookmarks_empty_group_accumulations_subtitle => TolgeeBridge.get(
    localeName,
    'bookmarks_empty_group_accumulations_subtitle',
    () => _fallback.bookmarks_empty_group_accumulations_subtitle,
  );

  @override
  String get bookmarks_empty_timers_title => TolgeeBridge.get(
    localeName,
    'bookmarks_empty_timers_title',
    () => _fallback.bookmarks_empty_timers_title,
  );

  @override
  String get bookmarks_empty_timers_subtitle => TolgeeBridge.get(
    localeName,
    'bookmarks_empty_timers_subtitle',
    () => _fallback.bookmarks_empty_timers_subtitle,
  );

  @override
  String get bookmarks_empty_texts_title => TolgeeBridge.get(
    localeName,
    'bookmarks_empty_texts_title',
    () => _fallback.bookmarks_empty_texts_title,
  );

  @override
  String get bookmarks_empty_texts_subtitle => TolgeeBridge.get(
    localeName,
    'bookmarks_empty_texts_subtitle',
    () => _fallback.bookmarks_empty_texts_subtitle,
  );

  @override
  String get bookmark_removed => TolgeeBridge.get(
    localeName,
    'bookmark_removed',
    () => _fallback.bookmark_removed,
  );

  @override
  String get bookmark_remove_failed => TolgeeBridge.get(
    localeName,
    'bookmark_remove_failed',
    () => _fallback.bookmark_remove_failed,
  );

  @override
  String get bookmark_saved => TolgeeBridge.get(
    localeName,
    'bookmark_saved',
    () => _fallback.bookmark_saved,
  );

  @override
  String get bookmark_save_failed => TolgeeBridge.get(
    localeName,
    'bookmark_save_failed',
    () => _fallback.bookmark_save_failed,
  );

  @override
  String get bookmarks_yesterday => TolgeeBridge.get(
    localeName,
    'bookmarks_yesterday',
    () => _fallback.bookmarks_yesterday,
  );

  @override
  String get webview_timeout_error => TolgeeBridge.get(
    localeName,
    'webview_timeout_error',
    () => _fallback.webview_timeout_error,
  );

  @override
  String get webview_load_failed => TolgeeBridge.get(
    localeName,
    'webview_load_failed',
    () => _fallback.webview_load_failed,
  );

  @override
  String get privacy_policy_load_error => TolgeeBridge.get(
    localeName,
    'privacy_policy_load_error',
    () => _fallback.privacy_policy_load_error,
  );

  @override
  String get terms_of_service_load_error => TolgeeBridge.get(
    localeName,
    'terms_of_service_load_error',
    () => _fallback.terms_of_service_load_error,
  );

  @override
  String get series_enroll_error => TolgeeBridge.get(
    localeName,
    'series_enroll_error',
    () => _fallback.series_enroll_error,
  );

  @override
  String series_share_message(String title, String url) => TolgeeBridge.format(
    localeName,
    'series_share_message',
    <String, Object>{'title': title, 'url': url},
    () => _fallback.series_share_message(title, url),
  );

  @override
  String get player_back_10 => TolgeeBridge.get(
    localeName,
    'player_back_10',
    () => _fallback.player_back_10,
  );

  @override
  String get player_pause => TolgeeBridge.get(
    localeName,
    'player_pause',
    () => _fallback.player_pause,
  );

  @override
  String get player_play =>
      TolgeeBridge.get(localeName, 'player_play', () => _fallback.player_play);

  @override
  String get player_forward_10 => TolgeeBridge.get(
    localeName,
    'player_forward_10',
    () => _fallback.player_forward_10,
  );

  @override
  String get player_fullscreen => TolgeeBridge.get(
    localeName,
    'player_fullscreen',
    () => _fallback.player_fullscreen,
  );

  @override
  String get player_exit_fullscreen => TolgeeBridge.get(
    localeName,
    'player_exit_fullscreen',
    () => _fallback.player_exit_fullscreen,
  );

  @override
  String get session_plans_load_error => TolgeeBridge.get(
    localeName,
    'session_plans_load_error',
    () => _fallback.session_plans_load_error,
  );

  @override
  String get session_chants_load_error => TolgeeBridge.get(
    localeName,
    'session_chants_load_error',
    () => _fallback.session_chants_load_error,
  );

  @override
  String get session_no_chants => TolgeeBridge.get(
    localeName,
    'session_no_chants',
    () => _fallback.session_no_chants,
  );

  @override
  String get session_malas_load_error => TolgeeBridge.get(
    localeName,
    'session_malas_load_error',
    () => _fallback.session_malas_load_error,
  );

  @override
  String get session_no_malas => TolgeeBridge.get(
    localeName,
    'session_no_malas',
    () => _fallback.session_no_malas,
  );

  @override
  String get session_timers_load_error => TolgeeBridge.get(
    localeName,
    'session_timers_load_error',
    () => _fallback.session_timers_load_error,
  );

  @override
  String get session_no_timers => TolgeeBridge.get(
    localeName,
    'session_no_timers',
    () => _fallback.session_no_timers,
  );

  @override
  String days_count(int count) => TolgeeBridge.format(
    localeName,
    'days_count',
    <String, Object>{'count': count},
    () => _fallback.days_count(count),
  );

  @override
  String timer_minute_session(int minutes) => TolgeeBridge.format(
    localeName,
    'timer_minute_session',
    <String, Object>{'minutes': minutes},
    () => _fallback.timer_minute_session(minutes),
  );

  @override
  String get timer_notification_in_progress => TolgeeBridge.get(
    localeName,
    'timer_notification_in_progress',
    () => _fallback.timer_notification_in_progress,
  );

  @override
  String timer_notification_paused(String time) => TolgeeBridge.format(
    localeName,
    'timer_notification_paused',
    <String, Object>{'time': time},
    () => _fallback.timer_notification_paused(time),
  );

  @override
  String get timer_notification_complete => TolgeeBridge.get(
    localeName,
    'timer_notification_complete',
    () => _fallback.timer_notification_complete,
  );

  @override
  String plan_day_of(int day, int total) => TolgeeBridge.format(
    localeName,
    'plan_day_of',
    <String, Object>{'day': day, 'total': total},
    () => _fallback.plan_day_of(day, total),
  );

  @override
  String pagination_position(int current, int total) => TolgeeBridge.format(
    localeName,
    'pagination_position',
    <String, Object>{'current': current, 'total': total},
    () => _fallback.pagination_position(current, total),
  );

  @override
  String get plan_shorts_title => TolgeeBridge.get(
    localeName,
    'plan_shorts_title',
    () => _fallback.plan_shorts_title,
  );

  @override
  String get author_details_load_error => TolgeeBridge.get(
    localeName,
    'author_details_load_error',
    () => _fallback.author_details_load_error,
  );

  @override
  String get link_cannot_open => TolgeeBridge.get(
    localeName,
    'link_cannot_open',
    () => _fallback.link_cannot_open,
  );

  @override
  String get link_invalid => TolgeeBridge.get(
    localeName,
    'link_invalid',
    () => _fallback.link_invalid,
  );

  @override
  String get author_no_plans => TolgeeBridge.get(
    localeName,
    'author_no_plans',
    () => _fallback.author_no_plans,
  );

  @override
  String get author_plans_load_error => TolgeeBridge.get(
    localeName,
    'author_plans_load_error',
    () => _fallback.author_plans_load_error,
  );

  @override
  String get drag_to_resize => TolgeeBridge.get(
    localeName,
    'drag_to_resize',
    () => _fallback.drag_to_resize,
  );

  @override
  String get day_completion_share_message => TolgeeBridge.get(
    localeName,
    'day_completion_share_message',
    () => _fallback.day_completion_share_message,
  );

  @override
  String group_accumulator_share_message(String accumulation, String group) =>
      TolgeeBridge.format(
        localeName,
        'group_accumulator_share_message',
        <String, Object>{'accumulation': accumulation, 'group': group},
        () => _fallback.group_accumulator_share_message(accumulation, group),
      );

  @override
  String group_accumulator_share_message_no_group(String accumulation) =>
      TolgeeBridge.format(
        localeName,
        'group_accumulator_share_message_no_group',
        <String, Object>{'accumulation': accumulation},
        () => _fallback.group_accumulator_share_message_no_group(accumulation),
      );

  @override
  String get chats_title =>
      TolgeeBridge.get(localeName, 'chats_title', () => _fallback.chats_title);

  @override
  String get chats_empty_title => TolgeeBridge.get(
    localeName,
    'chats_empty_title',
    () => _fallback.chats_empty_title,
  );

  @override
  String get chats_empty_body => TolgeeBridge.get(
    localeName,
    'chats_empty_body',
    () => _fallback.chats_empty_body,
  );

  @override
  String get group_chat_inappropriate => TolgeeBridge.get(
    localeName,
    'group_chat_inappropriate',
    () => _fallback.group_chat_inappropriate,
  );

  @override
  String get group_chat_not_a_member => TolgeeBridge.get(
    localeName,
    'group_chat_not_a_member',
    () => _fallback.group_chat_not_a_member,
  );

  @override
  String get group_chat_open => TolgeeBridge.get(
    localeName,
    'group_chat_open',
    () => _fallback.group_chat_open,
  );

  @override
  String get group_chat_message_hint => TolgeeBridge.get(
    localeName,
    'group_chat_message_hint',
    () => _fallback.group_chat_message_hint,
  );

  @override
  String get group_chat_today => TolgeeBridge.get(
    localeName,
    'group_chat_today',
    () => _fallback.group_chat_today,
  );

  @override
  String get group_chat_yesterday => TolgeeBridge.get(
    localeName,
    'group_chat_yesterday',
    () => _fallback.group_chat_yesterday,
  );

  @override
  String get group_chat_empty_title => TolgeeBridge.get(
    localeName,
    'group_chat_empty_title',
    () => _fallback.group_chat_empty_title,
  );

  @override
  String get group_chat_empty_body => TolgeeBridge.get(
    localeName,
    'group_chat_empty_body',
    () => _fallback.group_chat_empty_body,
  );

  @override
  String get group_chat_load_failed => TolgeeBridge.get(
    localeName,
    'group_chat_load_failed',
    () => _fallback.group_chat_load_failed,
  );

  @override
  String get group_chat_message_not_found => TolgeeBridge.get(
    localeName,
    'group_chat_message_not_found',
    () => _fallback.group_chat_message_not_found,
  );

  @override
  String get group_chat_message_too_far_back => TolgeeBridge.get(
    localeName,
    'group_chat_message_too_far_back',
    () => _fallback.group_chat_message_too_far_back,
  );

  @override
  String get group_chat_keep_looking => TolgeeBridge.get(
    localeName,
    'group_chat_keep_looking',
    () => _fallback.group_chat_keep_looking,
  );

  @override
  String get group_chat_retry => TolgeeBridge.get(
    localeName,
    'group_chat_retry',
    () => _fallback.group_chat_retry,
  );

  @override
  String get group_chat_unknown_sender => TolgeeBridge.get(
    localeName,
    'group_chat_unknown_sender',
    () => _fallback.group_chat_unknown_sender,
  );

  @override
  String get group_chat_reactions_all => TolgeeBridge.get(
    localeName,
    'group_chat_reactions_all',
    () => _fallback.group_chat_reactions_all,
  );

  @override
  String get group_chat_reacted => TolgeeBridge.get(
    localeName,
    'group_chat_reacted',
    () => _fallback.group_chat_reacted,
  );

  @override
  String get group_chat_reply => TolgeeBridge.get(
    localeName,
    'group_chat_reply',
    () => _fallback.group_chat_reply,
  );

  @override
  String get group_chat_copy => TolgeeBridge.get(
    localeName,
    'group_chat_copy',
    () => _fallback.group_chat_copy,
  );

  @override
  String get group_chat_copied => TolgeeBridge.get(
    localeName,
    'group_chat_copied',
    () => _fallback.group_chat_copied,
  );

  @override
  String get group_chat_report => TolgeeBridge.get(
    localeName,
    'group_chat_report',
    () => _fallback.group_chat_report,
  );

  @override
  String get group_chat_report_title => TolgeeBridge.get(
    localeName,
    'group_chat_report_title',
    () => _fallback.group_chat_report_title,
  );

  @override
  String get group_chat_report_privacy => TolgeeBridge.get(
    localeName,
    'group_chat_report_privacy',
    () => _fallback.group_chat_report_privacy,
  );

  @override
  String get group_chat_report_reason_harassment => TolgeeBridge.get(
    localeName,
    'group_chat_report_reason_harassment',
    () => _fallback.group_chat_report_reason_harassment,
  );

  @override
  String get group_chat_report_reason_hate => TolgeeBridge.get(
    localeName,
    'group_chat_report_reason_hate',
    () => _fallback.group_chat_report_reason_hate,
  );

  @override
  String get group_chat_report_reason_sexual => TolgeeBridge.get(
    localeName,
    'group_chat_report_reason_sexual',
    () => _fallback.group_chat_report_reason_sexual,
  );

  @override
  String get group_chat_report_reason_spam => TolgeeBridge.get(
    localeName,
    'group_chat_report_reason_spam',
    () => _fallback.group_chat_report_reason_spam,
  );

  @override
  String get group_chat_report_reason_off_topic => TolgeeBridge.get(
    localeName,
    'group_chat_report_reason_off_topic',
    () => _fallback.group_chat_report_reason_off_topic,
  );

  @override
  String get group_chat_report_reason_other => TolgeeBridge.get(
    localeName,
    'group_chat_report_reason_other',
    () => _fallback.group_chat_report_reason_other,
  );

  @override
  String get group_chat_report_note_title => TolgeeBridge.get(
    localeName,
    'group_chat_report_note_title',
    () => _fallback.group_chat_report_note_title,
  );

  @override
  String get group_chat_report_note_hint => TolgeeBridge.get(
    localeName,
    'group_chat_report_note_hint',
    () => _fallback.group_chat_report_note_hint,
  );

  @override
  String get group_chat_report_submit => TolgeeBridge.get(
    localeName,
    'group_chat_report_submit',
    () => _fallback.group_chat_report_submit,
  );

  @override
  String get group_chat_report_thanks => TolgeeBridge.get(
    localeName,
    'group_chat_report_thanks',
    () => _fallback.group_chat_report_thanks,
  );

  @override
  String get group_chat_report_offline => TolgeeBridge.get(
    localeName,
    'group_chat_report_offline',
    () => _fallback.group_chat_report_offline,
  );

  @override
  String get group_chat_report_failed => TolgeeBridge.get(
    localeName,
    'group_chat_report_failed',
    () => _fallback.group_chat_report_failed,
  );

  @override
  String get group_chat_report_retry => TolgeeBridge.get(
    localeName,
    'group_chat_report_retry',
    () => _fallback.group_chat_report_retry,
  );

  @override
  String get group_chat_delete => TolgeeBridge.get(
    localeName,
    'group_chat_delete',
    () => _fallback.group_chat_delete,
  );

  @override
  String get group_chat_delete_title => TolgeeBridge.get(
    localeName,
    'group_chat_delete_title',
    () => _fallback.group_chat_delete_title,
  );

  @override
  String group_chat_delete_title_many(int count) => TolgeeBridge.format(
    localeName,
    'group_chat_delete_title_many',
    <String, Object>{'count': count},
    () => _fallback.group_chat_delete_title_many(count),
  );

  @override
  String group_chat_delete_confirm_body(int count) => TolgeeBridge.format(
    localeName,
    'group_chat_delete_confirm_body',
    <String, Object>{'count': count},
    () => _fallback.group_chat_delete_confirm_body(count),
  );

  @override
  String group_chat_delete_failed(int count) => TolgeeBridge.format(
    localeName,
    'group_chat_delete_failed',
    <String, Object>{'count': count},
    () => _fallback.group_chat_delete_failed(count),
  );

  @override
  String group_chat_selection_limit(int count) => TolgeeBridge.format(
    localeName,
    'group_chat_selection_limit',
    <String, Object>{'count': count},
    () => _fallback.group_chat_selection_limit(count),
  );

  @override
  String get group_chat_message_deleted_by_sender => TolgeeBridge.get(
    localeName,
    'group_chat_message_deleted_by_sender',
    () => _fallback.group_chat_message_deleted_by_sender,
  );

  @override
  String get group_chat_reaction_failed => TolgeeBridge.get(
    localeName,
    'group_chat_reaction_failed',
    () => _fallback.group_chat_reaction_failed,
  );

  @override
  String group_chat_reactions_count(int count) => TolgeeBridge.format(
    localeName,
    'group_chat_reactions_count',
    <String, Object>{'count': count},
    () => _fallback.group_chat_reactions_count(count),
  );

  @override
  String get group_chat_you => TolgeeBridge.get(
    localeName,
    'group_chat_you',
    () => _fallback.group_chat_you,
  );

  @override
  String get group_chat_tap_to_remove => TolgeeBridge.get(
    localeName,
    'group_chat_tap_to_remove',
    () => _fallback.group_chat_tap_to_remove,
  );

  @override
  String get group_chat_reply_parent_gone => TolgeeBridge.get(
    localeName,
    'group_chat_reply_parent_gone',
    () => _fallback.group_chat_reply_parent_gone,
  );

  @override
  String get group_tab_posts => TolgeeBridge.get(
    localeName,
    'group_tab_posts',
    () => _fallback.group_tab_posts,
  );

  @override
  String get group_tab_events => TolgeeBridge.get(
    localeName,
    'group_tab_events',
    () => _fallback.group_tab_events,
  );

  @override
  String get group_posts_empty_title => TolgeeBridge.get(
    localeName,
    'group_posts_empty_title',
    () => _fallback.group_posts_empty_title,
  );

  @override
  String get group_posts_empty_message => TolgeeBridge.get(
    localeName,
    'group_posts_empty_message',
    () => _fallback.group_posts_empty_message,
  );

  @override
  String get group_posts_load_error => TolgeeBridge.get(
    localeName,
    'group_posts_load_error',
    () => _fallback.group_posts_load_error,
  );

  @override
  String get group_post_button => TolgeeBridge.get(
    localeName,
    'group_post_button',
    () => _fallback.group_post_button,
  );

  @override
  String get group_post_new_title => TolgeeBridge.get(
    localeName,
    'group_post_new_title',
    () => _fallback.group_post_new_title,
  );

  @override
  String get group_post_posting_to => TolgeeBridge.get(
    localeName,
    'group_post_posting_to',
    () => _fallback.group_post_posting_to,
  );

  @override
  String get group_post_caption_hint => TolgeeBridge.get(
    localeName,
    'group_post_caption_hint',
    () => _fallback.group_post_caption_hint,
  );

  @override
  String get group_post_photos => TolgeeBridge.get(
    localeName,
    'group_post_photos',
    () => _fallback.group_post_photos,
  );

  @override
  String get group_post_link => TolgeeBridge.get(
    localeName,
    'group_post_link',
    () => _fallback.group_post_link,
  );

  @override
  String get group_post_discard_title => TolgeeBridge.get(
    localeName,
    'group_post_discard_title',
    () => _fallback.group_post_discard_title,
  );

  @override
  String get group_post_discard_message => TolgeeBridge.get(
    localeName,
    'group_post_discard_message',
    () => _fallback.group_post_discard_message,
  );

  @override
  String get group_post_keep_editing => TolgeeBridge.get(
    localeName,
    'group_post_keep_editing',
    () => _fallback.group_post_keep_editing,
  );

  @override
  String get group_post_discard => TolgeeBridge.get(
    localeName,
    'group_post_discard',
    () => _fallback.group_post_discard,
  );

  @override
  String get group_post_add_link_title => TolgeeBridge.get(
    localeName,
    'group_post_add_link_title',
    () => _fallback.group_post_add_link_title,
  );

  @override
  String get group_post_add_link_hint => TolgeeBridge.get(
    localeName,
    'group_post_add_link_hint',
    () => _fallback.group_post_add_link_hint,
  );

  @override
  String get group_post_link_field_hint => TolgeeBridge.get(
    localeName,
    'group_post_link_field_hint',
    () => _fallback.group_post_link_field_hint,
  );

  @override
  String get group_post_attach => TolgeeBridge.get(
    localeName,
    'group_post_attach',
    () => _fallback.group_post_attach,
  );

  @override
  String get group_post_attach_as_link => TolgeeBridge.get(
    localeName,
    'group_post_attach_as_link',
    () => _fallback.group_post_attach_as_link,
  );

  @override
  String get group_post_preview_failed_title => TolgeeBridge.get(
    localeName,
    'group_post_preview_failed_title',
    () => _fallback.group_post_preview_failed_title,
  );

  @override
  String get group_post_preview_failed_message => TolgeeBridge.get(
    localeName,
    'group_post_preview_failed_message',
    () => _fallback.group_post_preview_failed_message,
  );

  @override
  String get group_post_invalid_link => TolgeeBridge.get(
    localeName,
    'group_post_invalid_link',
    () => _fallback.group_post_invalid_link,
  );

  @override
  String get group_post_in_app_content => TolgeeBridge.get(
    localeName,
    'group_post_in_app_content',
    () => _fallback.group_post_in_app_content,
  );

  @override
  String get group_post_add_in_app_content_title => TolgeeBridge.get(
    localeName,
    'group_post_add_in_app_content_title',
    () => _fallback.group_post_add_in_app_content_title,
  );

  @override
  String get group_post_in_app_content_empty => TolgeeBridge.get(
    localeName,
    'group_post_in_app_content_empty',
    () => _fallback.group_post_in_app_content_empty,
  );

  @override
  String group_post_photo_limit(int count) => TolgeeBridge.format(
    localeName,
    'group_post_photo_limit',
    <String, Object>{'count': count},
    () => _fallback.group_post_photo_limit(count),
  );

  @override
  String get group_post_upload_error => TolgeeBridge.get(
    localeName,
    'group_post_upload_error',
    () => _fallback.group_post_upload_error,
  );

  @override
  String get group_post_publish_error => TolgeeBridge.get(
    localeName,
    'group_post_publish_error',
    () => _fallback.group_post_publish_error,
  );

  @override
  String get group_post_published => TolgeeBridge.get(
    localeName,
    'group_post_published',
    () => _fallback.group_post_published,
  );

  @override
  String get group_post_delete_title => TolgeeBridge.get(
    localeName,
    'group_post_delete_title',
    () => _fallback.group_post_delete_title,
  );

  @override
  String get group_post_delete_message => TolgeeBridge.get(
    localeName,
    'group_post_delete_message',
    () => _fallback.group_post_delete_message,
  );

  @override
  String get group_post_delete_failed => TolgeeBridge.get(
    localeName,
    'group_post_delete_failed',
    () => _fallback.group_post_delete_failed,
  );

  @override
  String get edit => TolgeeBridge.get(localeName, 'edit', () => _fallback.edit);

  @override
  String get group_post_edit_title => TolgeeBridge.get(
    localeName,
    'group_post_edit_title',
    () => _fallback.group_post_edit_title,
  );

  @override
  String get group_post_update_error => TolgeeBridge.get(
    localeName,
    'group_post_update_error',
    () => _fallback.group_post_update_error,
  );

  @override
  String get group_post_updated => TolgeeBridge.get(
    localeName,
    'group_post_updated',
    () => _fallback.group_post_updated,
  );

  @override
  String get practice_collection_already_added => TolgeeBridge.get(
    localeName,
    'practice_collection_already_added',
    () => _fallback.practice_collection_already_added,
  );

  @override
  String get practice_group_accumulator_already_added => TolgeeBridge.get(
    localeName,
    'practice_group_accumulator_already_added',
    () => _fallback.practice_group_accumulator_already_added,
  );

  @override
  String get event_live_badge => TolgeeBridge.get(
    localeName,
    'event_live_badge',
    () => _fallback.event_live_badge,
  );

  @override
  String get event_live_video_mode => TolgeeBridge.get(
    localeName,
    'event_live_video_mode',
    () => _fallback.event_live_video_mode,
  );

  @override
  String get event_live_audio_mode => TolgeeBridge.get(
    localeName,
    'event_live_audio_mode',
    () => _fallback.event_live_audio_mode,
  );

  @override
  String get event_live_go_live => TolgeeBridge.get(
    localeName,
    'event_live_go_live',
    () => _fallback.event_live_go_live,
  );

  @override
  String get event_replays => TolgeeBridge.get(
    localeName,
    'event_replays',
    () => _fallback.event_replays,
  );

  @override
  String event_replay_session(String day, String session) =>
      TolgeeBridge.format(
        localeName,
        'event_replay_session',
        <String, Object>{'day': day, 'session': session},
        () => _fallback.event_replay_session(day, session),
      );

  @override
  String get event_replay_recording => TolgeeBridge.get(
    localeName,
    'event_replay_recording',
    () => _fallback.event_replay_recording,
  );

  @override
  String get event_replay_back_to_live => TolgeeBridge.get(
    localeName,
    'event_replay_back_to_live',
    () => _fallback.event_replay_back_to_live,
  );

  @override
  String get event_replays_empty => TolgeeBridge.get(
    localeName,
    'event_replays_empty',
    () => _fallback.event_replays_empty,
  );

  @override
  String get event_puja_starts_in => TolgeeBridge.get(
    localeName,
    'event_puja_starts_in',
    () => _fallback.event_puja_starts_in,
  );

  @override
  String get event_puja_not_started => TolgeeBridge.get(
    localeName,
    'event_puja_not_started',
    () => _fallback.event_puja_not_started,
  );

  @override
  String get event_prayer_requests => TolgeeBridge.get(
    localeName,
    'event_prayer_requests',
    () => _fallback.event_prayer_requests,
  );

  @override
  String event_prayer_request_count(int count) => TolgeeBridge.format(
    localeName,
    'event_prayer_request_count',
    <String, Object>{'count': count},
    () => _fallback.event_prayer_request_count(count),
  );

  @override
  String get event_prayer_empty_title => TolgeeBridge.get(
    localeName,
    'event_prayer_empty_title',
    () => _fallback.event_prayer_empty_title,
  );

  @override
  String get event_prayer_empty_body => TolgeeBridge.get(
    localeName,
    'event_prayer_empty_body',
    () => _fallback.event_prayer_empty_body,
  );

  @override
  String get event_prayer_add => TolgeeBridge.get(
    localeName,
    'event_prayer_add',
    () => _fallback.event_prayer_add,
  );

  @override
  String get event_prayer_hint => TolgeeBridge.get(
    localeName,
    'event_prayer_hint',
    () => _fallback.event_prayer_hint,
  );

  @override
  String event_prayer_hint_intention(String topics) => TolgeeBridge.format(
    localeName,
    'event_prayer_hint_intention',
    <String, Object>{'topics': topics},
    () => _fallback.event_prayer_hint_intention(topics),
  );

  @override
  String get event_prayer_load_failed => TolgeeBridge.get(
    localeName,
    'event_prayer_load_failed',
    () => _fallback.event_prayer_load_failed,
  );

  @override
  String get event_prayer_closed => TolgeeBridge.get(
    localeName,
    'event_prayer_closed',
    () => _fallback.event_prayer_closed,
  );

  @override
  String get group_prayer_closed => TolgeeBridge.get(
    localeName,
    'group_prayer_closed',
    () => _fallback.group_prayer_closed,
  );

  @override
  String get group_prayer_delete_body => TolgeeBridge.get(
    localeName,
    'group_prayer_delete_body',
    () => _fallback.group_prayer_delete_body,
  );

  @override
  String get event_prayer_pray => TolgeeBridge.get(
    localeName,
    'event_prayer_pray',
    () => _fallback.event_prayer_pray,
  );

  @override
  String event_prayer_my_count(int count) => TolgeeBridge.format(
    localeName,
    'event_prayer_my_count',
    <String, Object>{'count': count},
    () => _fallback.event_prayer_my_count(count),
  );

  @override
  String get event_prayer_new_request => TolgeeBridge.get(
    localeName,
    'event_prayer_new_request',
    () => _fallback.event_prayer_new_request,
  );

  @override
  String get event_prayer_edit_request => TolgeeBridge.get(
    localeName,
    'event_prayer_edit_request',
    () => _fallback.event_prayer_edit_request,
  );

  @override
  String get event_prayer_delete_title => TolgeeBridge.get(
    localeName,
    'event_prayer_delete_title',
    () => _fallback.event_prayer_delete_title,
  );

  @override
  String get event_prayer_delete_body => TolgeeBridge.get(
    localeName,
    'event_prayer_delete_body',
    () => _fallback.event_prayer_delete_body,
  );

  @override
  String get event_prayer_delete_failed => TolgeeBridge.get(
    localeName,
    'event_prayer_delete_failed',
    () => _fallback.event_prayer_delete_failed,
  );

  @override
  String get event_prayer_choose_intention => TolgeeBridge.get(
    localeName,
    'event_prayer_choose_intention',
    () => _fallback.event_prayer_choose_intention,
  );

  @override
  String get event_prayer_intentions_failed => TolgeeBridge.get(
    localeName,
    'event_prayer_intentions_failed',
    () => _fallback.event_prayer_intentions_failed,
  );

  @override
  String get event_prayer_request_button => TolgeeBridge.get(
    localeName,
    'event_prayer_request_button',
    () => _fallback.event_prayer_request_button,
  );

  @override
  String get event_prayer_you => TolgeeBridge.get(
    localeName,
    'event_prayer_you',
    () => _fallback.event_prayer_you,
  );

  @override
  String get event_prayer_waiting_first => TolgeeBridge.get(
    localeName,
    'event_prayer_waiting_first',
    () => _fallback.event_prayer_waiting_first,
  );

  @override
  String event_prayer_more_praying(int count) => TolgeeBridge.format(
    localeName,
    'event_prayer_more_praying',
    <String, Object>{'count': count},
    () => _fallback.event_prayer_more_praying(count),
  );

  @override
  String event_prayer_people_praying(int count) => TolgeeBridge.format(
    localeName,
    'event_prayer_people_praying',
    <String, Object>{'count': count},
    () => _fallback.event_prayer_people_praying(count),
  );

  @override
  String get event_prayer_praying_for_you => TolgeeBridge.get(
    localeName,
    'event_prayer_praying_for_you',
    () => _fallback.event_prayer_praying_for_you,
  );

  @override
  String get event_prayer_your_request => TolgeeBridge.get(
    localeName,
    'event_prayer_your_request',
    () => _fallback.event_prayer_your_request,
  );

  @override
  String get event_prayer_supporters_failed => TolgeeBridge.get(
    localeName,
    'event_prayer_supporters_failed',
    () => _fallback.event_prayer_supporters_failed,
  );

  @override
  String get event_prayer_no_supporters => TolgeeBridge.get(
    localeName,
    'event_prayer_no_supporters',
    () => _fallback.event_prayer_no_supporters,
  );

  @override
  String get event_prayer_sort_by => TolgeeBridge.get(
    localeName,
    'event_prayer_sort_by',
    () => _fallback.event_prayer_sort_by,
  );

  @override
  String get event_prayer_sort_needs_prayers => TolgeeBridge.get(
    localeName,
    'event_prayer_sort_needs_prayers',
    () => _fallback.event_prayer_sort_needs_prayers,
  );

  @override
  String get event_prayer_sort_most_prayed => TolgeeBridge.get(
    localeName,
    'event_prayer_sort_most_prayed',
    () => _fallback.event_prayer_sort_most_prayed,
  );

  @override
  String get event_prayer_sort_newest => TolgeeBridge.get(
    localeName,
    'event_prayer_sort_newest',
    () => _fallback.event_prayer_sort_newest,
  );

  @override
  String get event_prayer_sort_oldest => TolgeeBridge.get(
    localeName,
    'event_prayer_sort_oldest',
    () => _fallback.event_prayer_sort_oldest,
  );

  @override
  String get event_prayer_sort_by_intention => TolgeeBridge.get(
    localeName,
    'event_prayer_sort_by_intention',
    () => _fallback.event_prayer_sort_by_intention,
  );

  @override
  String get event_prayer_clear_intention => TolgeeBridge.get(
    localeName,
    'event_prayer_clear_intention',
    () => _fallback.event_prayer_clear_intention,
  );

  @override
  String get event_prayer_filter_empty_title => TolgeeBridge.get(
    localeName,
    'event_prayer_filter_empty_title',
    () => _fallback.event_prayer_filter_empty_title,
  );

  @override
  String get event_prayer_filter_empty_body => TolgeeBridge.get(
    localeName,
    'event_prayer_filter_empty_body',
    () => _fallback.event_prayer_filter_empty_body,
  );

  @override
  String get event_prayer_see_translation => TolgeeBridge.get(
    localeName,
    'event_prayer_see_translation',
    () => _fallback.event_prayer_see_translation,
  );

  @override
  String get event_prayer_see_original => TolgeeBridge.get(
    localeName,
    'event_prayer_see_original',
    () => _fallback.event_prayer_see_original,
  );

  @override
  String event_prayer_translated_from(String language) => TolgeeBridge.format(
    localeName,
    'event_prayer_translated_from',
    <String, Object>{'language': language},
    () => _fallback.event_prayer_translated_from(language),
  );

  @override
  String get event_prayer_translated => TolgeeBridge.get(
    localeName,
    'event_prayer_translated',
    () => _fallback.event_prayer_translated,
  );

  @override
  String get event_prayer_sort_mine => TolgeeBridge.get(
    localeName,
    'event_prayer_sort_mine',
    () => _fallback.event_prayer_sort_mine,
  );

  @override
  String get event_prayer_section_active => TolgeeBridge.get(
    localeName,
    'event_prayer_section_active',
    () => _fallback.event_prayer_section_active,
  );

  @override
  String get event_prayer_section_accomplished => TolgeeBridge.get(
    localeName,
    'event_prayer_section_accomplished',
    () => _fallback.event_prayer_section_accomplished,
  );

  @override
  String get event_prayer_mark_accomplished => TolgeeBridge.get(
    localeName,
    'event_prayer_mark_accomplished',
    () => _fallback.event_prayer_mark_accomplished,
  );

  @override
  String get event_prayer_mark_active => TolgeeBridge.get(
    localeName,
    'event_prayer_mark_active',
    () => _fallback.event_prayer_mark_active,
  );

  @override
  String get event_prayer_mine_empty_title => TolgeeBridge.get(
    localeName,
    'event_prayer_mine_empty_title',
    () => _fallback.event_prayer_mine_empty_title,
  );

  @override
  String get event_prayer_mine_empty_body => TolgeeBridge.get(
    localeName,
    'event_prayer_mine_empty_body',
    () => _fallback.event_prayer_mine_empty_body,
  );

  @override
  String get event_prayer_update_failed => TolgeeBridge.get(
    localeName,
    'event_prayer_update_failed',
    () => _fallback.event_prayer_update_failed,
  );

  @override
  String get event_prayer_find => TolgeeBridge.get(
    localeName,
    'event_prayer_find',
    () => _fallback.event_prayer_find,
  );

  @override
  String get event_prayer_random => TolgeeBridge.get(
    localeName,
    'event_prayer_random',
    () => _fallback.event_prayer_random,
  );

  @override
  String get event_prayer_finding => TolgeeBridge.get(
    localeName,
    'event_prayer_finding',
    () => _fallback.event_prayer_finding,
  );

  @override
  String get event_prayer_found => TolgeeBridge.get(
    localeName,
    'event_prayer_found',
    () => _fallback.event_prayer_found,
  );

  @override
  String get event_prayer_skip => TolgeeBridge.get(
    localeName,
    'event_prayer_skip',
    () => _fallback.event_prayer_skip,
  );

  @override
  String get event_prayer_next => TolgeeBridge.get(
    localeName,
    'event_prayer_next',
    () => _fallback.event_prayer_next,
  );

  @override
  String get event_prayer_be_first => TolgeeBridge.get(
    localeName,
    'event_prayer_be_first',
    () => _fallback.event_prayer_be_first,
  );

  @override
  String get event_prayer_random_empty_title => TolgeeBridge.get(
    localeName,
    'event_prayer_random_empty_title',
    () => _fallback.event_prayer_random_empty_title,
  );

  @override
  String get event_prayer_random_empty_body => TolgeeBridge.get(
    localeName,
    'event_prayer_random_empty_body',
    () => _fallback.event_prayer_random_empty_body,
  );

  @override
  String get event_prayer_random_failed => TolgeeBridge.get(
    localeName,
    'event_prayer_random_failed',
    () => _fallback.event_prayer_random_failed,
  );

  @override
  String event_prayer_people_count(int count) => TolgeeBridge.format(
    localeName,
    'event_prayer_people_count',
    <String, Object>{'count': count},
    () => _fallback.event_prayer_people_count(count),
  );

  @override
  String event_prayer_prayers_count(int count) => TolgeeBridge.format(
    localeName,
    'event_prayer_prayers_count',
    <String, Object>{'count': count},
    () => _fallback.event_prayer_prayers_count(count),
  );

  @override
  String get me_prayer_requests => TolgeeBridge.get(
    localeName,
    'me_prayer_requests',
    () => _fallback.me_prayer_requests,
  );

  @override
  String get me_prayer_requests_empty_title => TolgeeBridge.get(
    localeName,
    'me_prayer_requests_empty_title',
    () => _fallback.me_prayer_requests_empty_title,
  );

  @override
  String get me_prayer_requests_empty_body => TolgeeBridge.get(
    localeName,
    'me_prayer_requests_empty_body',
    () => _fallback.me_prayer_requests_empty_body,
  );

  @override
  String get me_prayer_delete_body => TolgeeBridge.get(
    localeName,
    'me_prayer_delete_body',
    () => _fallback.me_prayer_delete_body,
  );

  @override
  String get recitation_live_sync => TolgeeBridge.get(
    localeName,
    'recitation_live_sync',
    () => _fallback.recitation_live_sync,
  );

  @override
  String get recitation_live_label => TolgeeBridge.get(
    localeName,
    'recitation_live_label',
    () => _fallback.recitation_live_label,
  );

  @override
  String get recitation_live_session_ended => TolgeeBridge.get(
    localeName,
    'recitation_live_session_ended',
    () => _fallback.recitation_live_session_ended,
  );

  @override
  String get feedback_add_image => TolgeeBridge.get(
    localeName,
    'feedback_add_image',
    () => _fallback.feedback_add_image,
  );

  @override
  String feedback_image_limit(int count) => TolgeeBridge.format(
    localeName,
    'feedback_image_limit',
    <String, Object>{'count': count},
    () => _fallback.feedback_image_limit(count),
  );

  @override
  String get feedback_send => TolgeeBridge.get(
    localeName,
    'feedback_send',
    () => _fallback.feedback_send,
  );

  @override
  String get feedback_error_offline => TolgeeBridge.get(
    localeName,
    'feedback_error_offline',
    () => _fallback.feedback_error_offline,
  );

  @override
  String get feedback_error_rate_limited => TolgeeBridge.get(
    localeName,
    'feedback_error_rate_limited',
    () => _fallback.feedback_error_rate_limited,
  );

  @override
  String get feedback_error_too_large => TolgeeBridge.get(
    localeName,
    'feedback_error_too_large',
    () => _fallback.feedback_error_too_large,
  );

  @override
  String get feedback_error_failed => TolgeeBridge.get(
    localeName,
    'feedback_error_failed',
    () => _fallback.feedback_error_failed,
  );

  @override
  String get feedback_error_unavailable => TolgeeBridge.get(
    localeName,
    'feedback_error_unavailable',
    () => _fallback.feedback_error_unavailable,
  );

  @override
  String get settings_help_contact_row => TolgeeBridge.get(
    localeName,
    'settings_help_contact_row',
    () => _fallback.settings_help_contact_row,
  );

  @override
  String get help_contact_title => TolgeeBridge.get(
    localeName,
    'help_contact_title',
    () => _fallback.help_contact_title,
  );

  @override
  String get help_contact_intro => TolgeeBridge.get(
    localeName,
    'help_contact_intro',
    () => _fallback.help_contact_intro,
  );

  @override
  String get help_contact_message => TolgeeBridge.get(
    localeName,
    'help_contact_message',
    () => _fallback.help_contact_message,
  );

  @override
  String get help_contact_photos => TolgeeBridge.get(
    localeName,
    'help_contact_photos',
    () => _fallback.help_contact_photos,
  );

  @override
  String get help_contact_topic => TolgeeBridge.get(
    localeName,
    'help_contact_topic',
    () => _fallback.help_contact_topic,
  );

  @override
  String get help_contact_hint_default => TolgeeBridge.get(
    localeName,
    'help_contact_hint_default',
    () => _fallback.help_contact_hint_default,
  );

  @override
  String get help_contact_hint_report_problem => TolgeeBridge.get(
    localeName,
    'help_contact_hint_report_problem',
    () => _fallback.help_contact_hint_report_problem,
  );

  @override
  String get help_contact_hint_idea_feedback => TolgeeBridge.get(
    localeName,
    'help_contact_hint_idea_feedback',
    () => _fallback.help_contact_hint_idea_feedback,
  );

  @override
  String get help_contact_hint_suggest_content => TolgeeBridge.get(
    localeName,
    'help_contact_hint_suggest_content',
    () => _fallback.help_contact_hint_suggest_content,
  );

  @override
  String get help_contact_hint_help_collaborate => TolgeeBridge.get(
    localeName,
    'help_contact_hint_help_collaborate',
    () => _fallback.help_contact_hint_help_collaborate,
  );

  @override
  String get help_topic_report_problem => TolgeeBridge.get(
    localeName,
    'help_topic_report_problem',
    () => _fallback.help_topic_report_problem,
  );

  @override
  String get help_topic_idea_feedback => TolgeeBridge.get(
    localeName,
    'help_topic_idea_feedback',
    () => _fallback.help_topic_idea_feedback,
  );

  @override
  String get help_topic_suggest_content => TolgeeBridge.get(
    localeName,
    'help_topic_suggest_content',
    () => _fallback.help_topic_suggest_content,
  );

  @override
  String get help_topic_help_collaborate => TolgeeBridge.get(
    localeName,
    'help_topic_help_collaborate',
    () => _fallback.help_topic_help_collaborate,
  );

  @override
  String get help_contact_footer => TolgeeBridge.get(
    localeName,
    'help_contact_footer',
    () => _fallback.help_contact_footer,
  );

  @override
  String get help_contact_sent_title => TolgeeBridge.get(
    localeName,
    'help_contact_sent_title',
    () => _fallback.help_contact_sent_title,
  );

  @override
  String get help_contact_sent_body => TolgeeBridge.get(
    localeName,
    'help_contact_sent_body',
    () => _fallback.help_contact_sent_body,
  );

  @override
  String help_contact_sent_body_named(String name) => TolgeeBridge.format(
    localeName,
    'help_contact_sent_body_named',
    <String, Object>{'name': name},
    () => _fallback.help_contact_sent_body_named(name),
  );

  @override
  String get help_contact_your_request => TolgeeBridge.get(
    localeName,
    'help_contact_your_request',
    () => _fallback.help_contact_your_request,
  );

  @override
  String get help_contact_open_chat => TolgeeBridge.get(
    localeName,
    'help_contact_open_chat',
    () => _fallback.help_contact_open_chat,
  );

  @override
  String get help_context_sent_from => TolgeeBridge.get(
    localeName,
    'help_context_sent_from',
    () => _fallback.help_context_sent_from,
  );

  @override
  String help_context_photos(int count) => TolgeeBridge.format(
    localeName,
    'help_context_photos',
    <String, Object>{'count': count},
    () => _fallback.help_context_photos(count),
  );

  @override
  String get chat_official_badge => TolgeeBridge.get(
    localeName,
    'chat_official_badge',
    () => _fallback.chat_official_badge,
  );

  @override
  String get chat_team_reply_time => TolgeeBridge.get(
    localeName,
    'chat_team_reply_time',
    () => _fallback.chat_team_reply_time,
  );

  @override
  String get connect_failed_load_discover_groups_error => TolgeeBridge.get(
    localeName,
    'connect_failed_load_discover_groups_error',
    () => _fallback.connect_failed_load_discover_groups_error,
  );

  @override
  String get connect_failed_like_post_error => TolgeeBridge.get(
    localeName,
    'connect_failed_like_post_error',
    () => _fallback.connect_failed_like_post_error,
  );

  @override
  String get connect_failed_unlike_post_error => TolgeeBridge.get(
    localeName,
    'connect_failed_unlike_post_error',
    () => _fallback.connect_failed_unlike_post_error,
  );

  @override
  String get group_events_load_error => TolgeeBridge.get(
    localeName,
    'group_events_load_error',
    () => _fallback.group_events_load_error,
  );

  @override
  String get group_events_empty => TolgeeBridge.get(
    localeName,
    'group_events_empty',
    () => _fallback.group_events_empty,
  );

  @override
  String get group_events_empty_message => TolgeeBridge.get(
    localeName,
    'group_events_empty_message',
    () => _fallback.group_events_empty_message,
  );

  @override
  String get group_event_create_button => TolgeeBridge.get(
    localeName,
    'group_event_create_button',
    () => _fallback.group_event_create_button,
  );

  @override
  String get group_event_new_title => TolgeeBridge.get(
    localeName,
    'group_event_new_title',
    () => _fallback.group_event_new_title,
  );

  @override
  String group_event_step_of(int current, int total) => TolgeeBridge.format(
    localeName,
    'group_event_step_of',
    <String, Object>{'current': current, 'total': total},
    () => _fallback.group_event_step_of(current, total),
  );

  @override
  String get group_event_step_about => TolgeeBridge.get(
    localeName,
    'group_event_step_about',
    () => _fallback.group_event_step_about,
  );

  @override
  String get group_event_cover_image => TolgeeBridge.get(
    localeName,
    'group_event_cover_image',
    () => _fallback.group_event_cover_image,
  );

  @override
  String get group_event_add_cover_photo => TolgeeBridge.get(
    localeName,
    'group_event_add_cover_photo',
    () => _fallback.group_event_add_cover_photo,
  );

  @override
  String get group_event_change_cover => TolgeeBridge.get(
    localeName,
    'group_event_change_cover',
    () => _fallback.group_event_change_cover,
  );

  @override
  String get group_event_name_and_description => TolgeeBridge.get(
    localeName,
    'group_event_name_and_description',
    () => _fallback.group_event_name_and_description,
  );

  @override
  String get group_event_name_label => TolgeeBridge.get(
    localeName,
    'group_event_name_label',
    () => _fallback.group_event_name_label,
  );

  @override
  String get group_event_name_hint => TolgeeBridge.get(
    localeName,
    'group_event_name_hint',
    () => _fallback.group_event_name_hint,
  );

  @override
  String get group_event_description_label => TolgeeBridge.get(
    localeName,
    'group_event_description_label',
    () => _fallback.group_event_description_label,
  );

  @override
  String get group_event_description_hint => TolgeeBridge.get(
    localeName,
    'group_event_description_hint',
    () => _fallback.group_event_description_hint,
  );

  @override
  String get group_event_write => TolgeeBridge.get(
    localeName,
    'group_event_write',
    () => _fallback.group_event_write,
  );

  @override
  String get group_event_preview => TolgeeBridge.get(
    localeName,
    'group_event_preview',
    () => _fallback.group_event_preview,
  );

  @override
  String get group_event_preview_empty => TolgeeBridge.get(
    localeName,
    'group_event_preview_empty',
    () => _fallback.group_event_preview_empty,
  );

  @override
  String get group_event_continue => TolgeeBridge.get(
    localeName,
    'group_event_continue',
    () => _fallback.group_event_continue,
  );

  @override
  String get group_event_name_required_hint => TolgeeBridge.get(
    localeName,
    'group_event_name_required_hint',
    () => _fallback.group_event_name_required_hint,
  );

  @override
  String get group_event_languages_title => TolgeeBridge.get(
    localeName,
    'group_event_languages_title',
    () => _fallback.group_event_languages_title,
  );

  @override
  String get group_event_languages_add => TolgeeBridge.get(
    localeName,
    'group_event_languages_add',
    () => _fallback.group_event_languages_add,
  );

  @override
  String get group_event_languages_hint => TolgeeBridge.get(
    localeName,
    'group_event_languages_hint',
    () => _fallback.group_event_languages_hint,
  );

  @override
  String get group_event_discard_title => TolgeeBridge.get(
    localeName,
    'group_event_discard_title',
    () => _fallback.group_event_discard_title,
  );

  @override
  String get group_event_discard_message => TolgeeBridge.get(
    localeName,
    'group_event_discard_message',
    () => _fallback.group_event_discard_message,
  );

  @override
  String get group_event_format_bold => TolgeeBridge.get(
    localeName,
    'group_event_format_bold',
    () => _fallback.group_event_format_bold,
  );

  @override
  String get group_event_format_italic => TolgeeBridge.get(
    localeName,
    'group_event_format_italic',
    () => _fallback.group_event_format_italic,
  );

  @override
  String get group_event_format_heading => TolgeeBridge.get(
    localeName,
    'group_event_format_heading',
    () => _fallback.group_event_format_heading,
  );

  @override
  String get group_event_format_bullet_list => TolgeeBridge.get(
    localeName,
    'group_event_format_bullet_list',
    () => _fallback.group_event_format_bullet_list,
  );

  @override
  String get group_event_format_numbered_list => TolgeeBridge.get(
    localeName,
    'group_event_format_numbered_list',
    () => _fallback.group_event_format_numbered_list,
  );

  @override
  String get group_event_format_link => TolgeeBridge.get(
    localeName,
    'group_event_format_link',
    () => _fallback.group_event_format_link,
  );

  @override
  String get group_event_link_title => TolgeeBridge.get(
    localeName,
    'group_event_link_title',
    () => _fallback.group_event_link_title,
  );

  @override
  String get group_event_link_text_hint => TolgeeBridge.get(
    localeName,
    'group_event_link_text_hint',
    () => _fallback.group_event_link_text_hint,
  );

  @override
  String get group_event_link_url_hint => TolgeeBridge.get(
    localeName,
    'group_event_link_url_hint',
    () => _fallback.group_event_link_url_hint,
  );

  @override
  String get group_event_link_insert => TolgeeBridge.get(
    localeName,
    'group_event_link_insert',
    () => _fallback.group_event_link_insert,
  );

  @override
  String get group_event_step_when_where => TolgeeBridge.get(
    localeName,
    'group_event_step_when_where',
    () => _fallback.group_event_step_when_where,
  );

  @override
  String get group_event_when => TolgeeBridge.get(
    localeName,
    'group_event_when',
    () => _fallback.group_event_when,
  );

  @override
  String get group_event_where => TolgeeBridge.get(
    localeName,
    'group_event_where',
    () => _fallback.group_event_where,
  );

  @override
  String get group_event_one_time => TolgeeBridge.get(
    localeName,
    'group_event_one_time',
    () => _fallback.group_event_one_time,
  );

  @override
  String get group_event_recurring => TolgeeBridge.get(
    localeName,
    'group_event_recurring',
    () => _fallback.group_event_recurring,
  );

  @override
  String get group_event_date => TolgeeBridge.get(
    localeName,
    'group_event_date',
    () => _fallback.group_event_date,
  );

  @override
  String get group_event_start_date => TolgeeBridge.get(
    localeName,
    'group_event_start_date',
    () => _fallback.group_event_start_date,
  );

  @override
  String get group_event_end_date => TolgeeBridge.get(
    localeName,
    'group_event_end_date',
    () => _fallback.group_event_end_date,
  );

  @override
  String get group_event_first_date => TolgeeBridge.get(
    localeName,
    'group_event_first_date',
    () => _fallback.group_event_first_date,
  );

  @override
  String get group_event_choose_date => TolgeeBridge.get(
    localeName,
    'group_event_choose_date',
    () => _fallback.group_event_choose_date,
  );

  @override
  String get group_event_multi_day => TolgeeBridge.get(
    localeName,
    'group_event_multi_day',
    () => _fallback.group_event_multi_day,
  );

  @override
  String get group_event_all_day => TolgeeBridge.get(
    localeName,
    'group_event_all_day',
    () => _fallback.group_event_all_day,
  );

  @override
  String get group_event_all_day_hint => TolgeeBridge.get(
    localeName,
    'group_event_all_day_hint',
    () => _fallback.group_event_all_day_hint,
  );

  @override
  String get group_event_start_time => TolgeeBridge.get(
    localeName,
    'group_event_start_time',
    () => _fallback.group_event_start_time,
  );

  @override
  String get group_event_end_time => TolgeeBridge.get(
    localeName,
    'group_event_end_time',
    () => _fallback.group_event_end_time,
  );

  @override
  String get group_event_add_start_time => TolgeeBridge.get(
    localeName,
    'group_event_add_start_time',
    () => _fallback.group_event_add_start_time,
  );

  @override
  String get group_event_add_end_time => TolgeeBridge.get(
    localeName,
    'group_event_add_end_time',
    () => _fallback.group_event_add_end_time,
  );

  @override
  String group_event_time_starts(String time) => TolgeeBridge.format(
    localeName,
    'group_event_time_starts',
    <String, Object>{'time': time},
    () => _fallback.group_event_time_starts(time),
  );

  @override
  String group_event_time_ends(String time) => TolgeeBridge.format(
    localeName,
    'group_event_time_ends',
    <String, Object>{'time': time},
    () => _fallback.group_event_time_ends(time),
  );

  @override
  String get group_event_timezone => TolgeeBridge.get(
    localeName,
    'group_event_timezone',
    () => _fallback.group_event_timezone,
  );

  @override
  String get group_event_repeats => TolgeeBridge.get(
    localeName,
    'group_event_repeats',
    () => _fallback.group_event_repeats,
  );

  @override
  String get group_event_choose_repeats => TolgeeBridge.get(
    localeName,
    'group_event_choose_repeats',
    () => _fallback.group_event_choose_repeats,
  );

  @override
  String get group_event_duration => TolgeeBridge.get(
    localeName,
    'group_event_duration',
    () => _fallback.group_event_duration,
  );

  @override
  String get group_event_duration_decrease => TolgeeBridge.get(
    localeName,
    'group_event_duration_decrease',
    () => _fallback.group_event_duration_decrease,
  );

  @override
  String get group_event_duration_increase => TolgeeBridge.get(
    localeName,
    'group_event_duration_increase',
    () => _fallback.group_event_duration_increase,
  );

  @override
  String group_event_duration_days(int count) => TolgeeBridge.format(
    localeName,
    'group_event_duration_days',
    <String, Object>{'count': count},
    () => _fallback.group_event_duration_days(count),
  );

  @override
  String group_event_repeats_weekly(String weekday) => TolgeeBridge.format(
    localeName,
    'group_event_repeats_weekly',
    <String, Object>{'weekday': weekday},
    () => _fallback.group_event_repeats_weekly(weekday),
  );

  @override
  String group_event_repeats_monthly(String day) => TolgeeBridge.format(
    localeName,
    'group_event_repeats_monthly',
    <String, Object>{'day': day},
    () => _fallback.group_event_repeats_monthly(day),
  );

  @override
  String group_event_repeats_monthly_lunar(String day) => TolgeeBridge.format(
    localeName,
    'group_event_repeats_monthly_lunar',
    <String, Object>{'day': day},
    () => _fallback.group_event_repeats_monthly_lunar(day),
  );

  @override
  String group_event_repeats_yearly(String date) => TolgeeBridge.format(
    localeName,
    'group_event_repeats_yearly',
    <String, Object>{'date': date},
    () => _fallback.group_event_repeats_yearly(date),
  );

  @override
  String get group_event_repeats_yearly_lunar => TolgeeBridge.get(
    localeName,
    'group_event_repeats_yearly_lunar',
    () => _fallback.group_event_repeats_yearly_lunar,
  );

  @override
  String get group_event_full_moon => TolgeeBridge.get(
    localeName,
    'group_event_full_moon',
    () => _fallback.group_event_full_moon,
  );

  @override
  String get group_event_new_moon => TolgeeBridge.get(
    localeName,
    'group_event_new_moon',
    () => _fallback.group_event_new_moon,
  );

  @override
  String get group_event_gregorian => TolgeeBridge.get(
    localeName,
    'group_event_gregorian',
    () => _fallback.group_event_gregorian,
  );

  @override
  String get group_event_tibetan_lunar => TolgeeBridge.get(
    localeName,
    'group_event_tibetan_lunar',
    () => _fallback.group_event_tibetan_lunar,
  );

  @override
  String get group_event_next_dates => TolgeeBridge.get(
    localeName,
    'group_event_next_dates',
    () => _fallback.group_event_next_dates,
  );

  @override
  String get group_event_repeats_hint => TolgeeBridge.get(
    localeName,
    'group_event_repeats_hint',
    () => _fallback.group_event_repeats_hint,
  );

  @override
  String get group_event_in_person => TolgeeBridge.get(
    localeName,
    'group_event_in_person',
    () => _fallback.group_event_in_person,
  );

  @override
  String get group_event_live => TolgeeBridge.get(
    localeName,
    'group_event_live',
    () => _fallback.group_event_live,
  );

  @override
  String get group_event_both => TolgeeBridge.get(
    localeName,
    'group_event_both',
    () => _fallback.group_event_both,
  );

  @override
  String get group_event_venue => TolgeeBridge.get(
    localeName,
    'group_event_venue',
    () => _fallback.group_event_venue,
  );

  @override
  String get group_event_add_venue => TolgeeBridge.get(
    localeName,
    'group_event_add_venue',
    () => _fallback.group_event_add_venue,
  );

  @override
  String get group_event_venue_search_hint => TolgeeBridge.get(
    localeName,
    'group_event_venue_search_hint',
    () => _fallback.group_event_venue_search_hint,
  );

  @override
  String get group_event_venue_no_results => TolgeeBridge.get(
    localeName,
    'group_event_venue_no_results',
    () => _fallback.group_event_venue_no_results,
  );

  @override
  String get group_event_venue_search_error => TolgeeBridge.get(
    localeName,
    'group_event_venue_search_error',
    () => _fallback.group_event_venue_search_error,
  );

  @override
  String get group_event_drop_pin => TolgeeBridge.get(
    localeName,
    'group_event_drop_pin',
    () => _fallback.group_event_drop_pin,
  );

  @override
  String get group_event_drop_pin_hint => TolgeeBridge.get(
    localeName,
    'group_event_drop_pin_hint',
    () => _fallback.group_event_drop_pin_hint,
  );

  @override
  String get group_event_pin_marker => TolgeeBridge.get(
    localeName,
    'group_event_pin_marker',
    () => _fallback.group_event_pin_marker,
  );

  @override
  String get group_event_selected_location => TolgeeBridge.get(
    localeName,
    'group_event_selected_location',
    () => _fallback.group_event_selected_location,
  );

  @override
  String get group_event_pin_unnamed => TolgeeBridge.get(
    localeName,
    'group_event_pin_unnamed',
    () => _fallback.group_event_pin_unnamed,
  );

  @override
  String get group_event_confirm_location => TolgeeBridge.get(
    localeName,
    'group_event_confirm_location',
    () => _fallback.group_event_confirm_location,
  );

  @override
  String get group_event_name_location => TolgeeBridge.get(
    localeName,
    'group_event_name_location',
    () => _fallback.group_event_name_location,
  );

  @override
  String get group_event_venue_name => TolgeeBridge.get(
    localeName,
    'group_event_venue_name',
    () => _fallback.group_event_venue_name,
  );

  @override
  String get group_event_venue_name_hint => TolgeeBridge.get(
    localeName,
    'group_event_venue_name_hint',
    () => _fallback.group_event_venue_name_hint,
  );

  @override
  String get group_event_save_venue => TolgeeBridge.get(
    localeName,
    'group_event_save_venue',
    () => _fallback.group_event_save_venue,
  );

  @override
  String get group_event_live_link => TolgeeBridge.get(
    localeName,
    'group_event_live_link',
    () => _fallback.group_event_live_link,
  );

  @override
  String get group_event_live_link_hint => TolgeeBridge.get(
    localeName,
    'group_event_live_link_hint',
    () => _fallback.group_event_live_link_hint,
  );

  @override
  String get group_event_use_channel_link => TolgeeBridge.get(
    localeName,
    'group_event_use_channel_link',
    () => _fallback.group_event_use_channel_link,
  );

  @override
  String get group_event_live_link_youtube_help => TolgeeBridge.get(
    localeName,
    'group_event_live_link_youtube_help',
    () => _fallback.group_event_live_link_youtube_help,
  );

  @override
  String get group_event_live_link_custom_help => TolgeeBridge.get(
    localeName,
    'group_event_live_link_custom_help',
    () => _fallback.group_event_live_link_custom_help,
  );

  @override
  String get group_event_live_link_invalid => TolgeeBridge.get(
    localeName,
    'group_event_live_link_invalid',
    () => _fallback.group_event_live_link_invalid,
  );

  @override
  String get group_event_pick_date_hint => TolgeeBridge.get(
    localeName,
    'group_event_pick_date_hint',
    () => _fallback.group_event_pick_date_hint,
  );

  @override
  String get group_event_pick_repeats_hint => TolgeeBridge.get(
    localeName,
    'group_event_pick_repeats_hint',
    () => _fallback.group_event_pick_repeats_hint,
  );

  @override
  String get group_event_end_date_hint => TolgeeBridge.get(
    localeName,
    'group_event_end_date_hint',
    () => _fallback.group_event_end_date_hint,
  );

  @override
  String get group_event_end_time_hint => TolgeeBridge.get(
    localeName,
    'group_event_end_time_hint',
    () => _fallback.group_event_end_time_hint,
  );

  @override
  String get group_event_venue_hint => TolgeeBridge.get(
    localeName,
    'group_event_venue_hint',
    () => _fallback.group_event_venue_hint,
  );

  @override
  String get group_event_link_required_hint => TolgeeBridge.get(
    localeName,
    'group_event_link_required_hint',
    () => _fallback.group_event_link_required_hint,
  );

  @override
  String get group_event_map_attribution => TolgeeBridge.get(
    localeName,
    'group_event_map_attribution',
    () => _fallback.group_event_map_attribution,
  );

  @override
  String get group_event_step_practices => TolgeeBridge.get(
    localeName,
    'group_event_step_practices',
    () => _fallback.group_event_step_practices,
  );

  @override
  String get group_event_optional_note => TolgeeBridge.get(
    localeName,
    'group_event_optional_note',
    () => _fallback.group_event_optional_note,
  );

  @override
  String get group_event_practices_section => TolgeeBridge.get(
    localeName,
    'group_event_practices_section',
    () => _fallback.group_event_practices_section,
  );

  @override
  String get group_event_add_practice => TolgeeBridge.get(
    localeName,
    'group_event_add_practice',
    () => _fallback.group_event_add_practice,
  );

  @override
  String get group_event_practice_search_hint => TolgeeBridge.get(
    localeName,
    'group_event_practice_search_hint',
    () => _fallback.group_event_practice_search_hint,
  );

  @override
  String get group_event_practice_filter_all => TolgeeBridge.get(
    localeName,
    'group_event_practice_filter_all',
    () => _fallback.group_event_practice_filter_all,
  );

  @override
  String get group_event_practice_filter_content => TolgeeBridge.get(
    localeName,
    'group_event_practice_filter_content',
    () => _fallback.group_event_practice_filter_content,
  );

  @override
  String get group_event_practice_filter_collections => TolgeeBridge.get(
    localeName,
    'group_event_practice_filter_collections',
    () => _fallback.group_event_practice_filter_collections,
  );

  @override
  String get group_event_practice_filter_accumulators => TolgeeBridge.get(
    localeName,
    'group_event_practice_filter_accumulators',
    () => _fallback.group_event_practice_filter_accumulators,
  );

  @override
  String get group_event_practice_rule => TolgeeBridge.get(
    localeName,
    'group_event_practice_rule',
    () => _fallback.group_event_practice_rule,
  );

  @override
  String group_event_practice_replaced(String chosen, String previous) =>
      TolgeeBridge.format(
        localeName,
        'group_event_practice_replaced',
        <String, Object>{'chosen': chosen, 'previous': previous},
        () => _fallback.group_event_practice_replaced(chosen, previous),
      );

  @override
  String get group_event_practices_empty => TolgeeBridge.get(
    localeName,
    'group_event_practices_empty',
    () => _fallback.group_event_practices_empty,
  );

  @override
  String get group_event_practices_load_error => TolgeeBridge.get(
    localeName,
    'group_event_practices_load_error',
    () => _fallback.group_event_practices_load_error,
  );

  @override
  String get group_event_practices_none_match => TolgeeBridge.get(
    localeName,
    'group_event_practices_none_match',
    () => _fallback.group_event_practices_none_match,
  );

  @override
  String group_event_add_practices_count(int count) => TolgeeBridge.format(
    localeName,
    'group_event_add_practices_count',
    <String, Object>{'count': count},
    () => _fallback.group_event_add_practices_count(count),
  );

  @override
  String get group_event_counted_by => TolgeeBridge.get(
    localeName,
    'group_event_counted_by',
    () => _fallback.group_event_counted_by,
  );

  @override
  String get group_event_count_mode_title => TolgeeBridge.get(
    localeName,
    'group_event_count_mode_title',
    () => _fallback.group_event_count_mode_title,
  );

  @override
  String get group_event_count_mode_attendees => TolgeeBridge.get(
    localeName,
    'group_event_count_mode_attendees',
    () => _fallback.group_event_count_mode_attendees,
  );

  @override
  String get group_event_count_mode_attendees_hint => TolgeeBridge.get(
    localeName,
    'group_event_count_mode_attendees_hint',
    () => _fallback.group_event_count_mode_attendees_hint,
  );

  @override
  String get group_event_count_mode_admin => TolgeeBridge.get(
    localeName,
    'group_event_count_mode_admin',
    () => _fallback.group_event_count_mode_admin,
  );

  @override
  String get group_event_count_mode_admin_hint => TolgeeBridge.get(
    localeName,
    'group_event_count_mode_admin_hint',
    () => _fallback.group_event_count_mode_admin_hint,
  );

  @override
  String get group_event_count_mode_admin_short => TolgeeBridge.get(
    localeName,
    'group_event_count_mode_admin_short',
    () => _fallback.group_event_count_mode_admin_short,
  );

  @override
  String get group_event_count_mode_attendees_taken => TolgeeBridge.get(
    localeName,
    'group_event_count_mode_attendees_taken',
    () => _fallback.group_event_count_mode_attendees_taken,
  );

  @override
  String group_event_remove_practice(String title) => TolgeeBridge.format(
    localeName,
    'group_event_remove_practice',
    <String, Object>{'title': title},
    () => _fallback.group_event_remove_practice(title),
  );

  @override
  String get group_event_videos_section => TolgeeBridge.get(
    localeName,
    'group_event_videos_section',
    () => _fallback.group_event_videos_section,
  );

  @override
  String get group_event_videos_hint => TolgeeBridge.get(
    localeName,
    'group_event_videos_hint',
    () => _fallback.group_event_videos_hint,
  );

  @override
  String get group_event_add_video => TolgeeBridge.get(
    localeName,
    'group_event_add_video',
    () => _fallback.group_event_add_video,
  );

  @override
  String get group_event_video_link => TolgeeBridge.get(
    localeName,
    'group_event_video_link',
    () => _fallback.group_event_video_link,
  );

  @override
  String get group_event_video_link_hint => TolgeeBridge.get(
    localeName,
    'group_event_video_link_hint',
    () => _fallback.group_event_video_link_hint,
  );

  @override
  String get group_event_paste => TolgeeBridge.get(
    localeName,
    'group_event_paste',
    () => _fallback.group_event_paste,
  );

  @override
  String get group_event_video_loading => TolgeeBridge.get(
    localeName,
    'group_event_video_loading',
    () => _fallback.group_event_video_loading,
  );

  @override
  String get group_event_video_invalid => TolgeeBridge.get(
    localeName,
    'group_event_video_invalid',
    () => _fallback.group_event_video_invalid,
  );

  @override
  String get group_event_video_source => TolgeeBridge.get(
    localeName,
    'group_event_video_source',
    () => _fallback.group_event_video_source,
  );

  @override
  String get group_event_video_untitled => TolgeeBridge.get(
    localeName,
    'group_event_video_untitled',
    () => _fallback.group_event_video_untitled,
  );

  @override
  String get group_event_remove_video => TolgeeBridge.get(
    localeName,
    'group_event_remove_video',
    () => _fallback.group_event_remove_video,
  );

  @override
  String get group_event_skip => TolgeeBridge.get(
    localeName,
    'group_event_skip',
    () => _fallback.group_event_skip,
  );

  @override
  String get group_event_step_review => TolgeeBridge.get(
    localeName,
    'group_event_step_review',
    () => _fallback.group_event_step_review,
  );

  @override
  String get group_event_review_event => TolgeeBridge.get(
    localeName,
    'group_event_review_event',
    () => _fallback.group_event_review_event,
  );

  @override
  String get group_event_review_settings => TolgeeBridge.get(
    localeName,
    'group_event_review_settings',
    () => _fallback.group_event_review_settings,
  );

  @override
  String get group_event_review_name => TolgeeBridge.get(
    localeName,
    'group_event_review_name',
    () => _fallback.group_event_review_name,
  );

  @override
  String get group_event_review_languages => TolgeeBridge.get(
    localeName,
    'group_event_review_languages',
    () => _fallback.group_event_review_languages,
  );

  @override
  String get group_event_review_when => TolgeeBridge.get(
    localeName,
    'group_event_review_when',
    () => _fallback.group_event_review_when,
  );

  @override
  String get group_event_review_where => TolgeeBridge.get(
    localeName,
    'group_event_review_where',
    () => _fallback.group_event_review_where,
  );

  @override
  String get group_event_review_live_link => TolgeeBridge.get(
    localeName,
    'group_event_review_live_link',
    () => _fallback.group_event_review_live_link,
  );

  @override
  String get group_event_review_practices => TolgeeBridge.get(
    localeName,
    'group_event_review_practices',
    () => _fallback.group_event_review_practices,
  );

  @override
  String get group_event_review_videos => TolgeeBridge.get(
    localeName,
    'group_event_review_videos',
    () => _fallback.group_event_review_videos,
  );

  @override
  String get group_event_review_event_settings => TolgeeBridge.get(
    localeName,
    'group_event_review_event_settings',
    () => _fallback.group_event_review_event_settings,
  );

  @override
  String get group_event_review_none => TolgeeBridge.get(
    localeName,
    'group_event_review_none',
    () => _fallback.group_event_review_none,
  );

  @override
  String get group_event_review_tap_hint => TolgeeBridge.get(
    localeName,
    'group_event_review_tap_hint',
    () => _fallback.group_event_review_tap_hint,
  );

  @override
  String get group_event_review_notify_hint => TolgeeBridge.get(
    localeName,
    'group_event_review_notify_hint',
    () => _fallback.group_event_review_notify_hint,
  );

  @override
  String group_event_review_more(String first, int count) =>
      TolgeeBridge.format(
        localeName,
        'group_event_review_more',
        <String, Object>{'first': first, 'count': count},
        () => _fallback.group_event_review_more(first, count),
      );

  @override
  String group_event_review_recurring_from(
    String rule,
    String times,
    String date,
  ) => TolgeeBridge.format(
    localeName,
    'group_event_review_recurring_from',
    <String, Object>{'rule': rule, 'times': times, 'date': date},
    () => _fallback.group_event_review_recurring_from(rule, times, date),
  );

  @override
  String get group_event_review_youtube_live => TolgeeBridge.get(
    localeName,
    'group_event_review_youtube_live',
    () => _fallback.group_event_review_youtube_live,
  );

  @override
  String get group_event_review_online => TolgeeBridge.get(
    localeName,
    'group_event_review_online',
    () => _fallback.group_event_review_online,
  );

  @override
  String get group_event_chat_on => TolgeeBridge.get(
    localeName,
    'group_event_chat_on',
    () => _fallback.group_event_chat_on,
  );

  @override
  String get group_event_chat_off => TolgeeBridge.get(
    localeName,
    'group_event_chat_off',
    () => _fallback.group_event_chat_off,
  );

  @override
  String get group_event_notifications_on => TolgeeBridge.get(
    localeName,
    'group_event_notifications_on',
    () => _fallback.group_event_notifications_on,
  );

  @override
  String get group_event_notifications_off => TolgeeBridge.get(
    localeName,
    'group_event_notifications_off',
    () => _fallback.group_event_notifications_off,
  );

  @override
  String get group_event_all_intentions => TolgeeBridge.get(
    localeName,
    'group_event_all_intentions',
    () => _fallback.group_event_all_intentions,
  );

  @override
  String group_event_intentions_count(int count) => TolgeeBridge.format(
    localeName,
    'group_event_intentions_count',
    <String, Object>{'count': count},
    () => _fallback.group_event_intentions_count(count),
  );

  @override
  String get group_event_publish => TolgeeBridge.get(
    localeName,
    'group_event_publish',
    () => _fallback.group_event_publish,
  );

  @override
  String get group_event_publish_error => TolgeeBridge.get(
    localeName,
    'group_event_publish_error',
    () => _fallback.group_event_publish_error,
  );

  @override
  String get group_event_settings_title => TolgeeBridge.get(
    localeName,
    'group_event_settings_title',
    () => _fallback.group_event_settings_title,
  );

  @override
  String get group_event_settings_chat => TolgeeBridge.get(
    localeName,
    'group_event_settings_chat',
    () => _fallback.group_event_settings_chat,
  );

  @override
  String get group_event_settings_chat_hint => TolgeeBridge.get(
    localeName,
    'group_event_settings_chat_hint',
    () => _fallback.group_event_settings_chat_hint,
  );

  @override
  String get group_event_settings_notifications => TolgeeBridge.get(
    localeName,
    'group_event_settings_notifications',
    () => _fallback.group_event_settings_notifications,
  );

  @override
  String get group_event_settings_notifications_hint => TolgeeBridge.get(
    localeName,
    'group_event_settings_notifications_hint',
    () => _fallback.group_event_settings_notifications_hint,
  );

  @override
  String get group_event_settings_intentions => TolgeeBridge.get(
    localeName,
    'group_event_settings_intentions',
    () => _fallback.group_event_settings_intentions,
  );

  @override
  String get group_event_settings_intentions_hint => TolgeeBridge.get(
    localeName,
    'group_event_settings_intentions_hint',
    () => _fallback.group_event_settings_intentions_hint,
  );

  @override
  String get group_event_settings_intentions_error => TolgeeBridge.get(
    localeName,
    'group_event_settings_intentions_error',
    () => _fallback.group_event_settings_intentions_error,
  );

  @override
  String get group_event_published_title => TolgeeBridge.get(
    localeName,
    'group_event_published_title',
    () => _fallback.group_event_published_title,
  );

  @override
  String group_event_published_headline(String name) => TolgeeBridge.format(
    localeName,
    'group_event_published_headline',
    <String, Object>{'name': name},
    () => _fallback.group_event_published_headline(name),
  );

  @override
  String group_event_published_message(String group) => TolgeeBridge.format(
    localeName,
    'group_event_published_message',
    <String, Object>{'group': group},
    () => _fallback.group_event_published_message(group),
  );

  @override
  String get group_event_published_message_silent => TolgeeBridge.get(
    localeName,
    'group_event_published_message_silent',
    () => _fallback.group_event_published_message_silent,
  );

  @override
  String get group_event_view_event => TolgeeBridge.get(
    localeName,
    'group_event_view_event',
    () => _fallback.group_event_view_event,
  );

  @override
  String get group_event_drafts_section => TolgeeBridge.get(
    localeName,
    'group_event_drafts_section',
    () => _fallback.group_event_drafts_section,
  );

  @override
  String get group_event_draft_label => TolgeeBridge.get(
    localeName,
    'group_event_draft_label',
    () => _fallback.group_event_draft_label,
  );

  @override
  String get group_event_draft_untitled => TolgeeBridge.get(
    localeName,
    'group_event_draft_untitled',
    () => _fallback.group_event_draft_untitled,
  );

  @override
  String get group_event_draft_menu_continue => TolgeeBridge.get(
    localeName,
    'group_event_draft_menu_continue',
    () => _fallback.group_event_draft_menu_continue,
  );

  @override
  String get group_event_draft_menu_delete => TolgeeBridge.get(
    localeName,
    'group_event_draft_menu_delete',
    () => _fallback.group_event_draft_menu_delete,
  );

  @override
  String get group_event_draft_menu_delete_hint => TolgeeBridge.get(
    localeName,
    'group_event_draft_menu_delete_hint',
    () => _fallback.group_event_draft_menu_delete_hint,
  );

  @override
  String get group_event_draft_saved => TolgeeBridge.get(
    localeName,
    'group_event_draft_saved',
    () => _fallback.group_event_draft_saved,
  );

  @override
  String get group_event_draft_save_error => TolgeeBridge.get(
    localeName,
    'group_event_draft_save_error',
    () => _fallback.group_event_draft_save_error,
  );

  @override
  String get group_event_draft_deleted => TolgeeBridge.get(
    localeName,
    'group_event_draft_deleted',
    () => _fallback.group_event_draft_deleted,
  );

  @override
  String get group_event_draft_delete_error => TolgeeBridge.get(
    localeName,
    'group_event_draft_delete_error',
    () => _fallback.group_event_draft_delete_error,
  );

  @override
  String get group_event_draft_delete_title => TolgeeBridge.get(
    localeName,
    'group_event_draft_delete_title',
    () => _fallback.group_event_draft_delete_title,
  );

  @override
  String get group_event_draft_delete_message => TolgeeBridge.get(
    localeName,
    'group_event_draft_delete_message',
    () => _fallback.group_event_draft_delete_message,
  );

  @override
  String get group_event_edit_draft_title => TolgeeBridge.get(
    localeName,
    'group_event_edit_draft_title',
    () => _fallback.group_event_edit_draft_title,
  );

  @override
  String get group_event_edit_title => TolgeeBridge.get(
    localeName,
    'group_event_edit_title',
    () => _fallback.group_event_edit_title,
  );

  @override
  String get group_event_save_changes => TolgeeBridge.get(
    localeName,
    'group_event_save_changes',
    () => _fallback.group_event_save_changes,
  );

  @override
  String get group_event_changes_saved => TolgeeBridge.get(
    localeName,
    'group_event_changes_saved',
    () => _fallback.group_event_changes_saved,
  );

  @override
  String get group_event_manage => TolgeeBridge.get(
    localeName,
    'group_event_manage',
    () => _fallback.group_event_manage,
  );

  @override
  String get group_event_manage_details => TolgeeBridge.get(
    localeName,
    'group_event_manage_details',
    () => _fallback.group_event_manage_details,
  );

  @override
  String get group_event_manage_counts => TolgeeBridge.get(
    localeName,
    'group_event_manage_counts',
    () => _fallback.group_event_manage_counts,
  );

  @override
  String get group_event_manage_accumulations => TolgeeBridge.get(
    localeName,
    'group_event_manage_accumulations',
    () => _fallback.group_event_manage_accumulations,
  );

  @override
  String get group_event_manage_admin_adds_pending => TolgeeBridge.get(
    localeName,
    'group_event_manage_admin_adds_pending',
    () => _fallback.group_event_manage_admin_adds_pending,
  );

  @override
  String group_event_manage_admin_adds(String count) => TolgeeBridge.format(
    localeName,
    'group_event_manage_admin_adds',
    <String, Object>{'count': count},
    () => _fallback.group_event_manage_admin_adds(count),
  );

  @override
  String get group_event_manage_attendees_add_pending => TolgeeBridge.get(
    localeName,
    'group_event_manage_attendees_add_pending',
    () => _fallback.group_event_manage_attendees_add_pending,
  );

  @override
  String group_event_manage_attendees_add(String count, int people) =>
      TolgeeBridge.format(
        localeName,
        'group_event_manage_attendees_add',
        <String, Object>{'count': count, 'people': people},
        () => _fallback.group_event_manage_attendees_add(count, people),
      );

  @override
  String get group_event_manage_add_count => TolgeeBridge.get(
    localeName,
    'group_event_manage_add_count',
    () => _fallback.group_event_manage_add_count,
  );

  @override
  String get group_event_manage_no_accumulations => TolgeeBridge.get(
    localeName,
    'group_event_manage_no_accumulations',
    () => _fallback.group_event_manage_no_accumulations,
  );

  @override
  String get group_event_manage_recurring_note => TolgeeBridge.get(
    localeName,
    'group_event_manage_recurring_note',
    () => _fallback.group_event_manage_recurring_note,
  );

  @override
  String group_event_in_person_of_target(String count, String target) =>
      TolgeeBridge.format(
        localeName,
        'group_event_in_person_of_target',
        <String, Object>{'count': count, 'target': target},
        () => _fallback.group_event_in_person_of_target(count, target),
      );

  @override
  String group_event_in_person_in_total(String count) => TolgeeBridge.format(
    localeName,
    'group_event_in_person_in_total',
    <String, Object>{'count': count},
    () => _fallback.group_event_in_person_in_total(count),
  );

  @override
  String get group_event_in_person_legend_app => TolgeeBridge.get(
    localeName,
    'group_event_in_person_legend_app',
    () => _fallback.group_event_in_person_legend_app,
  );

  @override
  String get group_event_in_person_legend_in_person => TolgeeBridge.get(
    localeName,
    'group_event_in_person_legend_in_person',
    () => _fallback.group_event_in_person_legend_in_person,
  );

  @override
  String get group_event_in_person_add_day => TolgeeBridge.get(
    localeName,
    'group_event_in_person_add_day',
    () => _fallback.group_event_in_person_add_day,
  );

  @override
  String get group_event_in_person_day => TolgeeBridge.get(
    localeName,
    'group_event_in_person_day',
    () => _fallback.group_event_in_person_day,
  );

  @override
  String get group_event_in_person_count => TolgeeBridge.get(
    localeName,
    'group_event_in_person_count',
    () => _fallback.group_event_in_person_count,
  );

  @override
  String get group_event_in_person_empty => TolgeeBridge.get(
    localeName,
    'group_event_in_person_empty',
    () => _fallback.group_event_in_person_empty,
  );

  @override
  String get group_event_in_person_invalid_count => TolgeeBridge.get(
    localeName,
    'group_event_in_person_invalid_count',
    () => _fallback.group_event_in_person_invalid_count,
  );

  @override
  String get group_event_in_person_added => TolgeeBridge.get(
    localeName,
    'group_event_in_person_added',
    () => _fallback.group_event_in_person_added,
  );

  @override
  String get group_event_in_person_updated => TolgeeBridge.get(
    localeName,
    'group_event_in_person_updated',
    () => _fallback.group_event_in_person_updated,
  );

  @override
  String get group_event_in_person_deleted => TolgeeBridge.get(
    localeName,
    'group_event_in_person_deleted',
    () => _fallback.group_event_in_person_deleted,
  );

  @override
  String get group_event_in_person_delete_title => TolgeeBridge.get(
    localeName,
    'group_event_in_person_delete_title',
    () => _fallback.group_event_in_person_delete_title,
  );

  @override
  String group_event_in_person_delete_message(String count, String day) =>
      TolgeeBridge.format(
        localeName,
        'group_event_in_person_delete_message',
        <String, Object>{'count': count, 'day': day},
        () => _fallback.group_event_in_person_delete_message(count, day),
      );

  @override
  String get group_event_in_person_exists => TolgeeBridge.get(
    localeName,
    'group_event_in_person_exists',
    () => _fallback.group_event_in_person_exists,
  );

  @override
  String get group_event_in_person_no_accumulation => TolgeeBridge.get(
    localeName,
    'group_event_in_person_no_accumulation',
    () => _fallback.group_event_in_person_no_accumulation,
  );

  @override
  String get group_event_in_person_save_error => TolgeeBridge.get(
    localeName,
    'group_event_in_person_save_error',
    () => _fallback.group_event_in_person_save_error,
  );

  @override
  String get group_event_in_person_load_more => TolgeeBridge.get(
    localeName,
    'group_event_in_person_load_more',
    () => _fallback.group_event_in_person_load_more,
  );

  @override
  String get mala_failed_load_catalogue_error => TolgeeBridge.get(
    localeName,
    'mala_failed_load_catalogue_error',
    () => _fallback.mala_failed_load_catalogue_error,
  );

  @override
  String get chant_collection_reload_error => TolgeeBridge.get(
    localeName,
    'chant_collection_reload_error',
    () => _fallback.chant_collection_reload_error,
  );

  @override
  String get chant_collection_reorder_error => TolgeeBridge.get(
    localeName,
    'chant_collection_reorder_error',
    () => _fallback.chant_collection_reorder_error,
  );

  @override
  String get timer_duration_label => TolgeeBridge.get(
    localeName,
    'timer_duration_label',
    () => _fallback.timer_duration_label,
  );

  @override
  String get timer_ambient_sound_label => TolgeeBridge.get(
    localeName,
    'timer_ambient_sound_label',
    () => _fallback.timer_ambient_sound_label,
  );

  @override
  String get timer_begin_session => TolgeeBridge.get(
    localeName,
    'timer_begin_session',
    () => _fallback.timer_begin_session,
  );

  @override
  String get timer_save_changes => TolgeeBridge.get(
    localeName,
    'timer_save_changes',
    () => _fallback.timer_save_changes,
  );

  @override
  String get timer_new_title => TolgeeBridge.get(
    localeName,
    'timer_new_title',
    () => _fallback.timer_new_title,
  );

  @override
  String get timer_title_hint => TolgeeBridge.get(
    localeName,
    'timer_title_hint',
    () => _fallback.timer_title_hint,
  );

  @override
  String get timer_edit_title => TolgeeBridge.get(
    localeName,
    'timer_edit_title',
    () => _fallback.timer_edit_title,
  );

  @override
  String get timer_your_timers => TolgeeBridge.get(
    localeName,
    'timer_your_timers',
    () => _fallback.timer_your_timers,
  );

  @override
  String get timer_ambient_sounds_title => TolgeeBridge.get(
    localeName,
    'timer_ambient_sounds_title',
    () => _fallback.timer_ambient_sounds_title,
  );

  @override
  String get timer_ambient_sound_none => TolgeeBridge.get(
    localeName,
    'timer_ambient_sound_none',
    () => _fallback.timer_ambient_sound_none,
  );

  @override
  String get timer_ambient_sounds_load_error => TolgeeBridge.get(
    localeName,
    'timer_ambient_sounds_load_error',
    () => _fallback.timer_ambient_sounds_load_error,
  );

  @override
  String get timer_volume_label => TolgeeBridge.get(
    localeName,
    'timer_volume_label',
    () => _fallback.timer_volume_label,
  );

  @override
  String get timer_duration_title => TolgeeBridge.get(
    localeName,
    'timer_duration_title',
    () => _fallback.timer_duration_title,
  );

  @override
  String get timer_edit =>
      TolgeeBridge.get(localeName, 'timer_edit', () => _fallback.timer_edit);

  @override
  String get timer_delete => TolgeeBridge.get(
    localeName,
    'timer_delete',
    () => _fallback.timer_delete,
  );

  @override
  String get timer_delete_title => TolgeeBridge.get(
    localeName,
    'timer_delete_title',
    () => _fallback.timer_delete_title,
  );

  @override
  String get timer_delete_message => TolgeeBridge.get(
    localeName,
    'timer_delete_message',
    () => _fallback.timer_delete_message,
  );

  @override
  String get timer_duration_must_be_greater_than_error => TolgeeBridge.get(
    localeName,
    'timer_duration_must_be_greater_than_error',
    () => _fallback.timer_duration_must_be_greater_than_error,
  );

  @override
  String get splash_tagline_1 => TolgeeBridge.get(
    localeName,
    'splash_tagline_1',
    () => _fallback.splash_tagline_1,
  );

  @override
  String get splash_tagline_2 => TolgeeBridge.get(
    localeName,
    'splash_tagline_2',
    () => _fallback.splash_tagline_2,
  );

  @override
  String get timer_create_custom => TolgeeBridge.get(
    localeName,
    'timer_create_custom',
    () => _fallback.timer_create_custom,
  );

  @override
  String get timer_starting => TolgeeBridge.get(
    localeName,
    'timer_starting',
    () => _fallback.timer_starting,
  );

  @override
  String get timer_duration_hours => TolgeeBridge.get(
    localeName,
    'timer_duration_hours',
    () => _fallback.timer_duration_hours,
  );

  @override
  String get timer_duration_sec => TolgeeBridge.get(
    localeName,
    'timer_duration_sec',
    () => _fallback.timer_duration_sec,
  );

  @override
  String get reader_display_title => TolgeeBridge.get(
    localeName,
    'reader_display_title',
    () => _fallback.reader_display_title,
  );

  @override
  String get text_size =>
      TolgeeBridge.get(localeName, 'text_size', () => _fallback.text_size);

  @override
  String get reader_more_settings => TolgeeBridge.get(
    localeName,
    'reader_more_settings',
    () => _fallback.reader_more_settings,
  );

  @override
  String get reader_spacing => TolgeeBridge.get(
    localeName,
    'reader_spacing',
    () => _fallback.reader_spacing,
  );

  @override
  String get reader_spacing_compact => TolgeeBridge.get(
    localeName,
    'reader_spacing_compact',
    () => _fallback.reader_spacing_compact,
  );

  @override
  String get reader_spacing_normal => TolgeeBridge.get(
    localeName,
    'reader_spacing_normal',
    () => _fallback.reader_spacing_normal,
  );

  @override
  String get reader_spacing_relaxed => TolgeeBridge.get(
    localeName,
    'reader_spacing_relaxed',
    () => _fallback.reader_spacing_relaxed,
  );

  @override
  String get reader_background => TolgeeBridge.get(
    localeName,
    'reader_background',
    () => _fallback.reader_background,
  );

  @override
  String get reader_background_rice_paper => TolgeeBridge.get(
    localeName,
    'reader_background_rice_paper',
    () => _fallback.reader_background_rice_paper,
  );

  @override
  String get reader_background_gold => TolgeeBridge.get(
    localeName,
    'reader_background_gold',
    () => _fallback.reader_background_gold,
  );

  @override
  String get reader_background_sky => TolgeeBridge.get(
    localeName,
    'reader_background_sky',
    () => _fallback.reader_background_sky,
  );

  @override
  String get reader_background_white => TolgeeBridge.get(
    localeName,
    'reader_background_white',
    () => _fallback.reader_background_white,
  );

  @override
  String get reader_background_plum => TolgeeBridge.get(
    localeName,
    'reader_background_plum',
    () => _fallback.reader_background_plum,
  );

  @override
  String get reader_background_temple_red => TolgeeBridge.get(
    localeName,
    'reader_background_temple_red',
    () => _fallback.reader_background_temple_red,
  );

  @override
  String get reader_background_robe_saffron => TolgeeBridge.get(
    localeName,
    'reader_background_robe_saffron',
    () => _fallback.reader_background_robe_saffron,
  );

  @override
  String get reader_in_the_text => TolgeeBridge.get(
    localeName,
    'reader_in_the_text',
    () => _fallback.reader_in_the_text,
  );

  @override
  String get reader_ritual_instructions => TolgeeBridge.get(
    localeName,
    'reader_ritual_instructions',
    () => _fallback.reader_ritual_instructions,
  );

  @override
  String get reader_verse_numbers => TolgeeBridge.get(
    localeName,
    'reader_verse_numbers',
    () => _fallback.reader_verse_numbers,
  );

  @override
  String get reader_change_languages => TolgeeBridge.get(
    localeName,
    'reader_change_languages',
    () => _fallback.reader_change_languages,
  );

  @override
  String get reader_live_paused => TolgeeBridge.get(
    localeName,
    'reader_live_paused',
    () => _fallback.reader_live_paused,
  );

  @override
  String get reader_text_smaller => TolgeeBridge.get(
    localeName,
    'reader_text_smaller',
    () => _fallback.reader_text_smaller,
  );

  @override
  String get reader_text_larger => TolgeeBridge.get(
    localeName,
    'reader_text_larger',
    () => _fallback.reader_text_larger,
  );

  @override
  String reader_section_position(String current, String total) =>
      TolgeeBridge.format(
        localeName,
        'reader_section_position',
        <String, Object>{'current': current, 'total': total},
        () => _fallback.reader_section_position(current, total),
      );

  @override
  String reader_round_position(String current, String total) =>
      TolgeeBridge.format(
        localeName,
        'reader_round_position',
        <String, Object>{'current': current, 'total': total},
        () => _fallback.reader_round_position(current, total),
      );

  @override
  String reader_round_number(String current) => TolgeeBridge.format(
    localeName,
    'reader_round_number',
    <String, Object>{'current': current},
    () => _fallback.reader_round_number(current),
  );

  @override
  String reader_count_position(String current, String total) =>
      TolgeeBridge.format(
        localeName,
        'reader_count_position',
        <String, Object>{'current': current, 'total': total},
        () => _fallback.reader_count_position(current, total),
      );

  @override
  String reader_show_script_in(String language) => TolgeeBridge.format(
    localeName,
    'reader_show_script_in',
    <String, Object>{'language': language},
    () => _fallback.reader_show_script_in(language),
  );

  @override
  String reader_verse_label(String number) => TolgeeBridge.format(
    localeName,
    'reader_verse_label',
    <String, Object>{'number': number},
    () => _fallback.reader_verse_label(number),
  );

  @override
  String get reader_tab_commentary => TolgeeBridge.get(
    localeName,
    'reader_tab_commentary',
    () => _fallback.reader_tab_commentary,
  );

  @override
  String get reader_tab_versions => TolgeeBridge.get(
    localeName,
    'reader_tab_versions',
    () => _fallback.reader_tab_versions,
  );
}

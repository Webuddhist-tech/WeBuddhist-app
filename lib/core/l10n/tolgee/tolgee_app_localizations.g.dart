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
  String get onboarding_setup_subtitle => TolgeeBridge.get(
    localeName,
    'onboarding_setup_subtitle',
    () => _fallback.onboarding_setup_subtitle,
  );

  @override
  String get onboarding_tagline => TolgeeBridge.get(
    localeName,
    'onboarding_tagline',
    () => _fallback.onboarding_tagline,
  );

  @override
  String get onboarding_quote => TolgeeBridge.get(
    localeName,
    'onboarding_quote',
    () => _fallback.onboarding_quote,
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
  String get onboarding_choose_option => TolgeeBridge.get(
    localeName,
    'onboarding_choose_option',
    () => _fallback.onboarding_choose_option,
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
  String get onboarding_all_set_feature_practices => TolgeeBridge.get(
    localeName,
    'onboarding_all_set_feature_practices',
    () => _fallback.onboarding_all_set_feature_practices,
  );

  @override
  String get onboarding_all_set_feature_reminders => TolgeeBridge.get(
    localeName,
    'onboarding_all_set_feature_reminders',
    () => _fallback.onboarding_all_set_feature_reminders,
  );

  @override
  String get onboarding_begin_practice => TolgeeBridge.get(
    localeName,
    'onboarding_begin_practice',
    () => _fallback.onboarding_begin_practice,
  );

  @override
  String get onboarding_2_title => TolgeeBridge.get(
    localeName,
    'onboarding_2_title',
    () => _fallback.onboarding_2_title,
  );

  @override
  String get onboarding_2_subtitle => TolgeeBridge.get(
    localeName,
    'onboarding_2_subtitle',
    () => _fallback.onboarding_2_subtitle,
  );

  @override
  String get onboarding_2_step1_title => TolgeeBridge.get(
    localeName,
    'onboarding_2_step1_title',
    () => _fallback.onboarding_2_step1_title,
  );

  @override
  String get onboarding_2_step1_desc => TolgeeBridge.get(
    localeName,
    'onboarding_2_step1_desc',
    () => _fallback.onboarding_2_step1_desc,
  );

  @override
  String get onboarding_2_step2_title => TolgeeBridge.get(
    localeName,
    'onboarding_2_step2_title',
    () => _fallback.onboarding_2_step2_title,
  );

  @override
  String get onboarding_2_step2_desc => TolgeeBridge.get(
    localeName,
    'onboarding_2_step2_desc',
    () => _fallback.onboarding_2_step2_desc,
  );

  @override
  String get onboarding_2_step3_title => TolgeeBridge.get(
    localeName,
    'onboarding_2_step3_title',
    () => _fallback.onboarding_2_step3_title,
  );

  @override
  String get onboarding_2_step3_desc => TolgeeBridge.get(
    localeName,
    'onboarding_2_step3_desc',
    () => _fallback.onboarding_2_step3_desc,
  );

  @override
  String get home_recitation => TolgeeBridge.get(
    localeName,
    'home_recitation',
    () => _fallback.home_recitation,
  );

  @override
  String get home_today =>
      TolgeeBridge.get(localeName, 'home_today', () => _fallback.home_today);

  @override
  String get home_good_morning => TolgeeBridge.get(
    localeName,
    'home_good_morning',
    () => _fallback.home_good_morning,
  );

  @override
  String get home_good_afternoon => TolgeeBridge.get(
    localeName,
    'home_good_afternoon',
    () => _fallback.home_good_afternoon,
  );

  @override
  String get home_good_evening => TolgeeBridge.get(
    localeName,
    'home_good_evening',
    () => _fallback.home_good_evening,
  );

  @override
  String get home_meditationTitle => TolgeeBridge.get(
    localeName,
    'home_meditationTitle',
    () => _fallback.home_meditationTitle,
  );

  @override
  String get home_prayerTitle => TolgeeBridge.get(
    localeName,
    'home_prayerTitle',
    () => _fallback.home_prayerTitle,
  );

  @override
  String get home_scripture => TolgeeBridge.get(
    localeName,
    'home_scripture',
    () => _fallback.home_scripture,
  );

  @override
  String get home_meditation => TolgeeBridge.get(
    localeName,
    'home_meditation',
    () => _fallback.home_meditation,
  );

  @override
  String get home_goDeeper => TolgeeBridge.get(
    localeName,
    'home_goDeeper',
    () => _fallback.home_goDeeper,
  );

  @override
  String get home_intention => TolgeeBridge.get(
    localeName,
    'home_intention',
    () => _fallback.home_intention,
  );

  @override
  String get home_overall_stats => TolgeeBridge.get(
    localeName,
    'home_overall_stats',
    () => _fallback.home_overall_stats,
  );

  @override
  String get home_plans =>
      TolgeeBridge.get(localeName, 'home_plans', () => _fallback.home_plans);

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
  String get timer_start =>
      TolgeeBridge.get(localeName, 'timer_start', () => _fallback.timer_start);

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
  String get home_greeting_fallback_name => TolgeeBridge.get(
    localeName,
    'home_greeting_fallback_name',
    () => _fallback.home_greeting_fallback_name,
  );

  @override
  String home_share_prompt(String appName) => TolgeeBridge.format(
    localeName,
    'home_share_prompt',
    <String, Object>{'appName': appName},
    () => _fallback.home_share_prompt(appName),
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
  String get text_toc_versions => TolgeeBridge.get(
    localeName,
    'text_toc_versions',
    () => _fallback.text_toc_versions,
  );

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
  String get text_close_commentary => TolgeeBridge.get(
    localeName,
    'text_close_commentary',
    () => _fallback.text_close_commentary,
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
  String get no_commentary => TolgeeBridge.get(
    localeName,
    'no_commentary',
    () => _fallback.no_commentary,
  );

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
  String get choose_image => TolgeeBridge.get(
    localeName,
    'choose_image',
    () => _fallback.choose_image,
  );

  @override
  String get choose_bg_image => TolgeeBridge.get(
    localeName,
    'choose_bg_image',
    () => _fallback.choose_bg_image,
  );

  @override
  String get create_image => TolgeeBridge.get(
    localeName,
    'create_image',
    () => _fallback.create_image,
  );

  @override
  String get save => TolgeeBridge.get(localeName, 'save', () => _fallback.save);

  @override
  String get done => TolgeeBridge.get(localeName, 'done', () => _fallback.done);

  @override
  String get customise_message => TolgeeBridge.get(
    localeName,
    'customise_message',
    () => _fallback.customise_message,
  );

  @override
  String get download_image => TolgeeBridge.get(
    localeName,
    'download_image',
    () => _fallback.download_image,
  );

  @override
  String get no_images_available => TolgeeBridge.get(
    localeName,
    'no_images_available',
    () => _fallback.no_images_available,
  );

  @override
  String get customise_text => TolgeeBridge.get(
    localeName,
    'customise_text',
    () => _fallback.customise_text,
  );

  @override
  String get text_size =>
      TolgeeBridge.get(localeName, 'text_size', () => _fallback.text_size);

  @override
  String get text_color =>
      TolgeeBridge.get(localeName, 'text_color', () => _fallback.text_color);

  @override
  String get text_shadow =>
      TolgeeBridge.get(localeName, 'text_shadow', () => _fallback.text_shadow);

  @override
  String get apply =>
      TolgeeBridge.get(localeName, 'apply', () => _fallback.apply);

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
  String get recitations_title => TolgeeBridge.get(
    localeName,
    'recitations_title',
    () => _fallback.recitations_title,
  );

  @override
  String get recitations_my_recitations => TolgeeBridge.get(
    localeName,
    'recitations_my_recitations',
    () => _fallback.recitations_my_recitations,
  );

  @override
  String get browse_recitations => TolgeeBridge.get(
    localeName,
    'browse_recitations',
    () => _fallback.browse_recitations,
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
  String get recitations_no_saved => TolgeeBridge.get(
    localeName,
    'recitations_no_saved',
    () => _fallback.recitations_no_saved,
  );

  @override
  String get recitations_login_prompt => TolgeeBridge.get(
    localeName,
    'recitations_login_prompt',
    () => _fallback.recitations_login_prompt,
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
  String get notification_settings => TolgeeBridge.get(
    localeName,
    'notification_settings',
    () => _fallback.notification_settings,
  );

  @override
  String get notification_allow_title => TolgeeBridge.get(
    localeName,
    'notification_allow_title',
    () => _fallback.notification_allow_title,
  );

  @override
  String get notification_allow_subtitle_enabled => TolgeeBridge.get(
    localeName,
    'notification_allow_subtitle_enabled',
    () => _fallback.notification_allow_subtitle_enabled,
  );

  @override
  String get notification_allow_subtitle_disabled => TolgeeBridge.get(
    localeName,
    'notification_allow_subtitle_disabled',
    () => _fallback.notification_allow_subtitle_disabled,
  );

  @override
  String get notification_allow_subtitle_paused => TolgeeBridge.get(
    localeName,
    'notification_allow_subtitle_paused',
    () => _fallback.notification_allow_subtitle_paused,
  );

  @override
  String get notification_routine_title => TolgeeBridge.get(
    localeName,
    'notification_routine_title',
    () => _fallback.notification_routine_title,
  );

  @override
  String get notification_routine_subtitle_enabled => TolgeeBridge.get(
    localeName,
    'notification_routine_subtitle_enabled',
    () => _fallback.notification_routine_subtitle_enabled,
  );

  @override
  String get notification_routine_subtitle_disabled => TolgeeBridge.get(
    localeName,
    'notification_routine_subtitle_disabled',
    () => _fallback.notification_routine_subtitle_disabled,
  );

  @override
  String get notification_battery_title => TolgeeBridge.get(
    localeName,
    'notification_battery_title',
    () => _fallback.notification_battery_title,
  );

  @override
  String get notification_battery_subtitle_enabled => TolgeeBridge.get(
    localeName,
    'notification_battery_subtitle_enabled',
    () => _fallback.notification_battery_subtitle_enabled,
  );

  @override
  String get notification_battery_subtitle_disabled => TolgeeBridge.get(
    localeName,
    'notification_battery_subtitle_disabled',
    () => _fallback.notification_battery_subtitle_disabled,
  );

  @override
  String get notification_recitation_title => TolgeeBridge.get(
    localeName,
    'notification_recitation_title',
    () => _fallback.notification_recitation_title,
  );

  @override
  String get notification_recitation_subtitle_enabled => TolgeeBridge.get(
    localeName,
    'notification_recitation_subtitle_enabled',
    () => _fallback.notification_recitation_subtitle_enabled,
  );

  @override
  String get notification_recitation_subtitle_disabled => TolgeeBridge.get(
    localeName,
    'notification_recitation_subtitle_disabled',
    () => _fallback.notification_recitation_subtitle_disabled,
  );

  @override
  String get notification_practice_title => TolgeeBridge.get(
    localeName,
    'notification_practice_title',
    () => _fallback.notification_practice_title,
  );

  @override
  String get notification_practice_subtitle_enabled => TolgeeBridge.get(
    localeName,
    'notification_practice_subtitle_enabled',
    () => _fallback.notification_practice_subtitle_enabled,
  );

  @override
  String get notification_practice_subtitle_disabled => TolgeeBridge.get(
    localeName,
    'notification_practice_subtitle_disabled',
    () => _fallback.notification_practice_subtitle_disabled,
  );

  @override
  String get notification_timer_title => TolgeeBridge.get(
    localeName,
    'notification_timer_title',
    () => _fallback.notification_timer_title,
  );

  @override
  String get notification_timer_subtitle_enabled => TolgeeBridge.get(
    localeName,
    'notification_timer_subtitle_enabled',
    () => _fallback.notification_timer_subtitle_enabled,
  );

  @override
  String get notification_timer_subtitle_disabled => TolgeeBridge.get(
    localeName,
    'notification_timer_subtitle_disabled',
    () => _fallback.notification_timer_subtitle_disabled,
  );

  @override
  String get notification_battery_info_title => TolgeeBridge.get(
    localeName,
    'notification_battery_info_title',
    () => _fallback.notification_battery_info_title,
  );

  @override
  String get notification_battery_info_body => TolgeeBridge.get(
    localeName,
    'notification_battery_info_body',
    () => _fallback.notification_battery_info_body,
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
  String get notification_snack_battery_reenable => TolgeeBridge.get(
    localeName,
    'notification_snack_battery_reenable',
    () => _fallback.notification_snack_battery_reenable,
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
  String get onboarding_quote_citation => TolgeeBridge.get(
    localeName,
    'onboarding_quote_citation',
    () => _fallback.onboarding_quote_citation,
  );

  @override
  String get onboarding_traditions_question => TolgeeBridge.get(
    localeName,
    'onboarding_traditions_question',
    () => _fallback.onboarding_traditions_question,
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
  String get onboarding_tradition_option_intro => TolgeeBridge.get(
    localeName,
    'onboarding_tradition_option_intro',
    () => _fallback.onboarding_tradition_option_intro,
  );

  @override
  String get onboarding_tradition_show_all_title => TolgeeBridge.get(
    localeName,
    'onboarding_tradition_show_all_title',
    () => _fallback.onboarding_tradition_show_all_title,
  );

  @override
  String get onboarding_tradition_show_all_description => TolgeeBridge.get(
    localeName,
    'onboarding_tradition_show_all_description',
    () => _fallback.onboarding_tradition_show_all_description,
  );

  @override
  String get onboarding_skip_for_now => TolgeeBridge.get(
    localeName,
    'onboarding_skip_for_now',
    () => _fallback.onboarding_skip_for_now,
  );

  @override
  String get onboarding_add_another_tradition => TolgeeBridge.get(
    localeName,
    'onboarding_add_another_tradition',
    () => _fallback.onboarding_add_another_tradition,
  );

  @override
  String get onboarding_select_all => TolgeeBridge.get(
    localeName,
    'onboarding_select_all',
    () => _fallback.onboarding_select_all,
  );

  @override
  String get onboarding_event_enrollment_error => TolgeeBridge.get(
    localeName,
    'onboarding_event_enrollment_error',
    () => _fallback.onboarding_event_enrollment_error,
  );

  @override
  String get onboarding_event_question => TolgeeBridge.get(
    localeName,
    'onboarding_event_question',
    () => _fallback.onboarding_event_question,
  );

  @override
  String get onboarding_event_optional => TolgeeBridge.get(
    localeName,
    'onboarding_event_optional',
    () => _fallback.onboarding_event_optional,
  );

  @override
  String onboarding_event_duration(String description, int days) =>
      TolgeeBridge.format(
        localeName,
        'onboarding_event_duration',
        <String, Object>{'description': description, 'days': days},
        () => _fallback.onboarding_event_duration(description, days),
      );

  @override
  String get onboarding_event_reminder_note => TolgeeBridge.get(
    localeName,
    'onboarding_event_reminder_note',
    () => _fallback.onboarding_event_reminder_note,
  );

  @override
  String get tradition_theravada => TolgeeBridge.get(
    localeName,
    'tradition_theravada',
    () => _fallback.tradition_theravada,
  );

  @override
  String get tradition_zen => TolgeeBridge.get(
    localeName,
    'tradition_zen',
    () => _fallback.tradition_zen,
  );

  @override
  String get tradition_tibetan_buddhism => TolgeeBridge.get(
    localeName,
    'tradition_tibetan_buddhism',
    () => _fallback.tradition_tibetan_buddhism,
  );

  @override
  String get tradition_pure_land => TolgeeBridge.get(
    localeName,
    'tradition_pure_land',
    () => _fallback.tradition_pure_land,
  );

  @override
  String get tradition_ambedkar_buddhism => TolgeeBridge.get(
    localeName,
    'tradition_ambedkar_buddhism',
    () => _fallback.tradition_ambedkar_buddhism,
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
  String get connect_coming_soon_subtitle => TolgeeBridge.get(
    localeName,
    'connect_coming_soon_subtitle',
    () => _fallback.connect_coming_soon_subtitle,
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
  String get connect_groups_empty_subtitle => TolgeeBridge.get(
    localeName,
    'connect_groups_empty_subtitle',
    () => _fallback.connect_groups_empty_subtitle,
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
  String get connect_tab_posts => TolgeeBridge.get(
    localeName,
    'connect_tab_posts',
    () => _fallback.connect_tab_posts,
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
  String get connect_empty_discover_posts => TolgeeBridge.get(
    localeName,
    'connect_empty_discover_posts',
    () => _fallback.connect_empty_discover_posts,
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
  String get connect_empty_discover_practices => TolgeeBridge.get(
    localeName,
    'connect_empty_discover_practices',
    () => _fallback.connect_empty_discover_practices,
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
  String get connect_my_empty_posts_title => TolgeeBridge.get(
    localeName,
    'connect_my_empty_posts_title',
    () => _fallback.connect_my_empty_posts_title,
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
  String get connect_my_empty_posts_subtitle => TolgeeBridge.get(
    localeName,
    'connect_my_empty_posts_subtitle',
    () => _fallback.connect_my_empty_posts_subtitle,
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
  String get connect_my_empty_posts_browse => TolgeeBridge.get(
    localeName,
    'connect_my_empty_posts_browse',
    () => _fallback.connect_my_empty_posts_browse,
  );

  @override
  String get connect_my_empty_practices_title => TolgeeBridge.get(
    localeName,
    'connect_my_empty_practices_title',
    () => _fallback.connect_my_empty_practices_title,
  );

  @override
  String get connect_my_empty_practices_subtitle => TolgeeBridge.get(
    localeName,
    'connect_my_empty_practices_subtitle',
    () => _fallback.connect_my_empty_practices_subtitle,
  );

  @override
  String get connect_my_empty_practices_browse => TolgeeBridge.get(
    localeName,
    'connect_my_empty_practices_browse',
    () => _fallback.connect_my_empty_practices_browse,
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
  String get connect_caption_more => TolgeeBridge.get(
    localeName,
    'connect_caption_more',
    () => _fallback.connect_caption_more,
  );

  @override
  String get connect_online => TolgeeBridge.get(
    localeName,
    'connect_online',
    () => _fallback.connect_online,
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
  String get connect_open => TolgeeBridge.get(
    localeName,
    'connect_open',
    () => _fallback.connect_open,
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
  String get connect_event_attend => TolgeeBridge.get(
    localeName,
    'connect_event_attend',
    () => _fallback.connect_event_attend,
  );

  @override
  String get connect_event_attending => TolgeeBridge.get(
    localeName,
    'connect_event_attending',
    () => _fallback.connect_event_attending,
  );

  @override
  String connect_event_participants_attending(int count) => TolgeeBridge.format(
    localeName,
    'connect_event_participants_attending',
    <String, Object>{'count': count},
    () => _fallback.connect_event_participants_attending(count),
  );

  @override
  String get connect_event_participants_empty => TolgeeBridge.get(
    localeName,
    'connect_event_participants_empty',
    () => _fallback.connect_event_participants_empty,
  );

  @override
  String get connect_event_tab_videos => TolgeeBridge.get(
    localeName,
    'connect_event_tab_videos',
    () => _fallback.connect_event_tab_videos,
  );

  @override
  String get connect_event_tab_links => TolgeeBridge.get(
    localeName,
    'connect_event_tab_links',
    () => _fallback.connect_event_tab_links,
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
  String get connect_event_links_empty => TolgeeBridge.get(
    localeName,
    'connect_event_links_empty',
    () => _fallback.connect_event_links_empty,
  );

  @override
  String get connect_event_link_tap_to_join => TolgeeBridge.get(
    localeName,
    'connect_event_link_tap_to_join',
    () => _fallback.connect_event_link_tap_to_join,
  );

  @override
  String get connect_event_link_open => TolgeeBridge.get(
    localeName,
    'connect_event_link_open',
    () => _fallback.connect_event_link_open,
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
  String get connect_event_practices => TolgeeBridge.get(
    localeName,
    'connect_event_practices',
    () => _fallback.connect_event_practices,
  );

  @override
  String get connect_event_tab_accumulations => TolgeeBridge.get(
    localeName,
    'connect_event_tab_accumulations',
    () => _fallback.connect_event_tab_accumulations,
  );

  @override
  String get connect_event_tab_recitations => TolgeeBridge.get(
    localeName,
    'connect_event_tab_recitations',
    () => _fallback.connect_event_tab_recitations,
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
  String get audio_init_error => TolgeeBridge.get(
    localeName,
    'audio_init_error',
    () => _fallback.audio_init_error,
  );

  @override
  String get meditation_audio_load_error => TolgeeBridge.get(
    localeName,
    'meditation_audio_load_error',
    () => _fallback.meditation_audio_load_error,
  );

  @override
  String get prayer_audio_load_error => TolgeeBridge.get(
    localeName,
    'prayer_audio_load_error',
    () => _fallback.prayer_audio_load_error,
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
  String get reader_settings_tooltip => TolgeeBridge.get(
    localeName,
    'reader_settings_tooltip',
    () => _fallback.reader_settings_tooltip,
  );

  @override
  String get reader_translate_tooltip => TolgeeBridge.get(
    localeName,
    'reader_translate_tooltip',
    () => _fallback.reader_translate_tooltip,
  );

  @override
  String get reader_translate_unavailable => TolgeeBridge.get(
    localeName,
    'reader_translate_unavailable',
    () => _fallback.reader_translate_unavailable,
  );

  @override
  String get reader_font_size_tooltip => TolgeeBridge.get(
    localeName,
    'reader_font_size_tooltip',
    () => _fallback.reader_font_size_tooltip,
  );

  @override
  String reader_version_title(String language) => TolgeeBridge.format(
    localeName,
    'reader_version_title',
    <String, Object>{'language': language},
    () => _fallback.reader_version_title(language),
  );

  @override
  String reader_script_title(String language) => TolgeeBridge.format(
    localeName,
    'reader_script_title',
    <String, Object>{'language': language},
    () => _fallback.reader_script_title(language),
  );

  @override
  String get reader_versions_load_error => TolgeeBridge.get(
    localeName,
    'reader_versions_load_error',
    () => _fallback.reader_versions_load_error,
  );

  @override
  String get reader_scripts_load_error => TolgeeBridge.get(
    localeName,
    'reader_scripts_load_error',
    () => _fallback.reader_scripts_load_error,
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
  String reader_no_scripts_in_language(String language) => TolgeeBridge.format(
    localeName,
    'reader_no_scripts_in_language',
    <String, Object>{'language': language},
    () => _fallback.reader_no_scripts_in_language(language),
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
  String get reader_version_details_load_error => TolgeeBridge.get(
    localeName,
    'reader_version_details_load_error',
    () => _fallback.reader_version_details_load_error,
  );

  @override
  String get reader_no_version_info => TolgeeBridge.get(
    localeName,
    'reader_no_version_info',
    () => _fallback.reader_no_version_info,
  );

  @override
  String get recitation_unavailable => TolgeeBridge.get(
    localeName,
    'recitation_unavailable',
    () => _fallback.recitation_unavailable,
  );

  @override
  String get recitation_sign_in_required => TolgeeBridge.get(
    localeName,
    'recitation_sign_in_required',
    () => _fallback.recitation_sign_in_required,
  );

  @override
  String get my_recitations_load_error => TolgeeBridge.get(
    localeName,
    'my_recitations_load_error',
    () => _fallback.my_recitations_load_error,
  );

  @override
  String get recitations_load_error => TolgeeBridge.get(
    localeName,
    'recitations_load_error',
    () => _fallback.recitations_load_error,
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
  String get unknown_error => TolgeeBridge.get(
    localeName,
    'unknown_error',
    () => _fallback.unknown_error,
  );

  @override
  String image_share_error(String error) => TolgeeBridge.format(
    localeName,
    'image_share_error',
    <String, Object>{'error': error},
    () => _fallback.image_share_error(error),
  );

  @override
  String get create_image_capture_error => TolgeeBridge.get(
    localeName,
    'create_image_capture_error',
    () => _fallback.create_image_capture_error,
  );

  @override
  String get create_image_share_error => TolgeeBridge.get(
    localeName,
    'create_image_share_error',
    () => _fallback.create_image_share_error,
  );

  @override
  String get create_image_save_success => TolgeeBridge.get(
    localeName,
    'create_image_save_success',
    () => _fallback.create_image_save_success,
  );

  @override
  String get create_image_save_error => TolgeeBridge.get(
    localeName,
    'create_image_save_error',
    () => _fallback.create_image_save_error,
  );

  @override
  String get create_image_download_error => TolgeeBridge.get(
    localeName,
    'create_image_download_error',
    () => _fallback.create_image_download_error,
  );

  @override
  String get create_image_customize_tooltip => TolgeeBridge.get(
    localeName,
    'create_image_customize_tooltip',
    () => _fallback.create_image_customize_tooltip,
  );

  @override
  String get create_image_text_too_long => TolgeeBridge.get(
    localeName,
    'create_image_text_too_long',
    () => _fallback.create_image_text_too_long,
  );

  @override
  String version_search_no_results(String query) => TolgeeBridge.format(
    localeName,
    'version_search_no_results',
    <String, Object>{'query': query},
    () => _fallback.version_search_no_results(query),
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
  String get image =>
      TolgeeBridge.get(localeName, 'image', () => _fallback.image);

  @override
  String get feedback =>
      TolgeeBridge.get(localeName, 'feedback', () => _fallback.feedback);

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
  String get ai_chat_history => TolgeeBridge.get(
    localeName,
    'ai_chat_history',
    () => _fallback.ai_chat_history,
  );

  @override
  String get ai_buddhist_assistant => TolgeeBridge.get(
    localeName,
    'ai_buddhist_assistant',
    () => _fallback.ai_buddhist_assistant,
  );

  @override
  String get ai_new_chat =>
      TolgeeBridge.get(localeName, 'ai_new_chat', () => _fallback.ai_new_chat);

  @override
  String get ai_retry =>
      TolgeeBridge.get(localeName, 'ai_retry', () => _fallback.ai_retry);

  @override
  String get ai_dismiss =>
      TolgeeBridge.get(localeName, 'ai_dismiss', () => _fallback.ai_dismiss);

  @override
  String get ai_sign_in_prompt => TolgeeBridge.get(
    localeName,
    'ai_sign_in_prompt',
    () => _fallback.ai_sign_in_prompt,
  );

  @override
  String get ai_explore_wisdom => TolgeeBridge.get(
    localeName,
    'ai_explore_wisdom',
    () => _fallback.ai_explore_wisdom,
  );

  @override
  String get ai_ask_question => TolgeeBridge.get(
    localeName,
    'ai_ask_question',
    () => _fallback.ai_ask_question,
  );

  @override
  String get ai_search_chats => TolgeeBridge.get(
    localeName,
    'ai_search_chats',
    () => _fallback.ai_search_chats,
  );

  @override
  String get ai_chats =>
      TolgeeBridge.get(localeName, 'ai_chats', () => _fallback.ai_chats);

  @override
  String get ai_chat_deleted => TolgeeBridge.get(
    localeName,
    'ai_chat_deleted',
    () => _fallback.ai_chat_deleted,
  );

  @override
  String get ai_no_conversations => TolgeeBridge.get(
    localeName,
    'ai_no_conversations',
    () => _fallback.ai_no_conversations,
  );

  @override
  String get ai_start_new_chat => TolgeeBridge.get(
    localeName,
    'ai_start_new_chat',
    () => _fallback.ai_start_new_chat,
  );

  @override
  String get ai_delete_chat => TolgeeBridge.get(
    localeName,
    'ai_delete_chat',
    () => _fallback.ai_delete_chat,
  );

  @override
  String get ai_delete_confirmation => TolgeeBridge.get(
    localeName,
    'ai_delete_confirmation',
    () => _fallback.ai_delete_confirmation,
  );

  @override
  String get ai_delete_warning => TolgeeBridge.get(
    localeName,
    'ai_delete_warning',
    () => _fallback.ai_delete_warning,
  );

  @override
  String get ai_confirm =>
      TolgeeBridge.get(localeName, 'ai_confirm', () => _fallback.ai_confirm);

  @override
  String get ai_delete =>
      TolgeeBridge.get(localeName, 'ai_delete', () => _fallback.ai_delete);

  @override
  String ai_greeting(String name) => TolgeeBridge.format(
    localeName,
    'ai_greeting',
    <String, Object>{'name': name},
    () => _fallback.ai_greeting(name),
  );

  @override
  String get ai_text_not_found => TolgeeBridge.get(
    localeName,
    'ai_text_not_found',
    () => _fallback.ai_text_not_found,
  );

  @override
  String ai_text_not_found_message(String title) => TolgeeBridge.format(
    localeName,
    'ai_text_not_found_message',
    <String, Object>{'title': title},
    () => _fallback.ai_text_not_found_message(title),
  );

  @override
  String get ai_sources =>
      TolgeeBridge.get(localeName, 'ai_sources', () => _fallback.ai_sources);

  @override
  String ai_sources_count(int count) => TolgeeBridge.format(
    localeName,
    'ai_sources_count',
    <String, Object>{'count': count},
    () => _fallback.ai_sources_count(count),
  );

  @override
  String search_no_results(String query) => TolgeeBridge.format(
    localeName,
    'search_no_results',
    <String, Object>{'query': query},
    () => _fallback.search_no_results(query),
  );

  @override
  String get search_show_more => TolgeeBridge.get(
    localeName,
    'search_show_more',
    () => _fallback.search_show_more,
  );

  @override
  String get search_contents => TolgeeBridge.get(
    localeName,
    'search_contents',
    () => _fallback.search_contents,
  );

  @override
  String get search_titles => TolgeeBridge.get(
    localeName,
    'search_titles',
    () => _fallback.search_titles,
  );

  @override
  String get search_all =>
      TolgeeBridge.get(localeName, 'search_all', () => _fallback.search_all);

  @override
  String get search_author => TolgeeBridge.get(
    localeName,
    'search_author',
    () => _fallback.search_author,
  );

  @override
  String get search_tab_ai_mode => TolgeeBridge.get(
    localeName,
    'search_tab_ai_mode',
    () => _fallback.search_tab_ai_mode,
  );

  @override
  String search_error(String message) => TolgeeBridge.format(
    localeName,
    'search_error',
    <String, Object>{'message': message},
    () => _fallback.search_error(message),
  );

  @override
  String get search_retrying => TolgeeBridge.get(
    localeName,
    'search_retrying',
    () => _fallback.search_retrying,
  );

  @override
  String search_no_titles_found(String query) => TolgeeBridge.format(
    localeName,
    'search_no_titles_found',
    <String, Object>{'query': query},
    () => _fallback.search_no_titles_found(query),
  );

  @override
  String search_no_contents_found(String query) => TolgeeBridge.format(
    localeName,
    'search_no_contents_found',
    <String, Object>{'query': query},
    () => _fallback.search_no_contents_found(query),
  );

  @override
  String search_no_authors_found(String query) => TolgeeBridge.format(
    localeName,
    'search_no_authors_found',
    <String, Object>{'query': query},
    () => _fallback.search_no_authors_found(query),
  );

  @override
  String get search_buddhist_texts => TolgeeBridge.get(
    localeName,
    'search_buddhist_texts',
    () => _fallback.search_buddhist_texts,
  );

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
  String get routine_delete_time_block => TolgeeBridge.get(
    localeName,
    'routine_delete_time_block',
    () => _fallback.routine_delete_time_block,
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
  String get continueAsGuest => TolgeeBridge.get(
    localeName,
    'continueAsGuest',
    () => _fallback.continueAsGuest,
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
  String get searchResults => TolgeeBridge.get(
    localeName,
    'searchResults',
    () => _fallback.searchResults,
  );

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
  String get updateOrderError => TolgeeBridge.get(
    localeName,
    'updateOrderError',
    () => _fallback.updateOrderError,
  );

  @override
  String get loadFailed =>
      TolgeeBridge.get(localeName, 'loadFailed', () => _fallback.loadFailed);

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
  String get show_second_version => TolgeeBridge.get(
    localeName,
    'show_second_version',
    () => _fallback.show_second_version,
  );

  @override
  String get enable_add_msg => TolgeeBridge.get(
    localeName,
    'enable_add_msg',
    () => _fallback.enable_add_msg,
  );

  @override
  String get main_version => TolgeeBridge.get(
    localeName,
    'main_version',
    () => _fallback.main_version,
  );

  @override
  String get second_version => TolgeeBridge.get(
    localeName,
    'second_version',
    () => _fallback.second_version,
  );

  @override
  String get second_version_msg => TolgeeBridge.get(
    localeName,
    'second_version_msg',
    () => _fallback.second_version_msg,
  );

  @override
  String get version =>
      TolgeeBridge.get(localeName, 'version', () => _fallback.version);

  @override
  String get parallel_version => TolgeeBridge.get(
    localeName,
    'parallel_version',
    () => _fallback.parallel_version,
  );

  @override
  String get version_not_available => TolgeeBridge.get(
    localeName,
    'version_not_available',
    () => _fallback.version_not_available,
  );

  @override
  String get read_full_text => TolgeeBridge.get(
    localeName,
    'read_full_text',
    () => _fallback.read_full_text,
  );

  @override
  String get reader_source_label => TolgeeBridge.get(
    localeName,
    'reader_source_label',
    () => _fallback.reader_source_label,
  );

  @override
  String get reader_license_label => TolgeeBridge.get(
    localeName,
    'reader_license_label',
    () => _fallback.reader_license_label,
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
  String get edit_profile_first_name => TolgeeBridge.get(
    localeName,
    'edit_profile_first_name',
    () => _fallback.edit_profile_first_name,
  );

  @override
  String get edit_profile_last_name => TolgeeBridge.get(
    localeName,
    'edit_profile_last_name',
    () => _fallback.edit_profile_last_name,
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
  String get me_counts =>
      TolgeeBridge.get(localeName, 'me_counts', () => _fallback.me_counts);

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
  String me_streak_share_message(int count, String appName) =>
      TolgeeBridge.format(
        localeName,
        'me_streak_share_message',
        <String, Object>{'count': count, 'appName': appName},
        () => _fallback.me_streak_share_message(count, appName),
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
  String get following =>
      TolgeeBridge.get(localeName, 'following', () => _fallback.following);

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
  String calendar_day_month(int day, int month) => TolgeeBridge.format(
    localeName,
    'calendar_day_month',
    <String, Object>{'day': day, 'month': month},
    () => _fallback.calendar_day_month(day, month),
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
  String get moon_phase_waxing_crescent => TolgeeBridge.get(
    localeName,
    'moon_phase_waxing_crescent',
    () => _fallback.moon_phase_waxing_crescent,
  );

  @override
  String get moon_phase_first_quarter => TolgeeBridge.get(
    localeName,
    'moon_phase_first_quarter',
    () => _fallback.moon_phase_first_quarter,
  );

  @override
  String get moon_phase_waxing_gibbous => TolgeeBridge.get(
    localeName,
    'moon_phase_waxing_gibbous',
    () => _fallback.moon_phase_waxing_gibbous,
  );

  @override
  String get moon_phase_full_moon => TolgeeBridge.get(
    localeName,
    'moon_phase_full_moon',
    () => _fallback.moon_phase_full_moon,
  );

  @override
  String get moon_phase_waning_gibbous => TolgeeBridge.get(
    localeName,
    'moon_phase_waning_gibbous',
    () => _fallback.moon_phase_waning_gibbous,
  );

  @override
  String get moon_phase_last_quarter => TolgeeBridge.get(
    localeName,
    'moon_phase_last_quarter',
    () => _fallback.moon_phase_last_quarter,
  );

  @override
  String get moon_phase_waning_crescent => TolgeeBridge.get(
    localeName,
    'moon_phase_waning_crescent',
    () => _fallback.moon_phase_waning_crescent,
  );

  @override
  String get join => TolgeeBridge.get(localeName, 'join', () => _fallback.join);

  @override
  String get joined =>
      TolgeeBridge.get(localeName, 'joined', () => _fallback.joined);

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
  String get reader_about_this_version => TolgeeBridge.get(
    localeName,
    'reader_about_this_version',
    () => _fallback.reader_about_this_version,
  );

  @override
  String reader_version_count(int count) => TolgeeBridge.format(
    localeName,
    'reader_version_count',
    <String, Object>{'count': count},
    () => _fallback.reader_version_count(count),
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
  String get mala_mantra_label => TolgeeBridge.get(
    localeName,
    'mala_mantra_label',
    () => _fallback.mala_mantra_label,
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
  String get ai_use_search_instead => TolgeeBridge.get(
    localeName,
    'ai_use_search_instead',
    () => _fallback.ai_use_search_instead,
  );

  @override
  String get ai_mode_label => TolgeeBridge.get(
    localeName,
    'ai_mode_label',
    () => _fallback.ai_mode_label,
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
  String source_with_value(String value) => TolgeeBridge.format(
    localeName,
    'source_with_value',
    <String, Object>{'value': value},
    () => _fallback.source_with_value(value),
  );

  @override
  String license_with_value(String value) => TolgeeBridge.format(
    localeName,
    'license_with_value',
    <String, Object>{'value': value},
    () => _fallback.license_with_value(value),
  );

  @override
  String loading_previous_pages(int count) => TolgeeBridge.format(
    localeName,
    'loading_previous_pages',
    <String, Object>{'count': count},
    () => _fallback.loading_previous_pages(count),
  );

  @override
  String loading_more_pages(int count) => TolgeeBridge.format(
    localeName,
    'loading_more_pages',
    <String, Object>{'count': count},
    () => _fallback.loading_more_pages(count),
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
  String get group_chat_title => TolgeeBridge.get(
    localeName,
    'group_chat_title',
    () => _fallback.group_chat_title,
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
  String get group_chat_join_to_send => TolgeeBridge.get(
    localeName,
    'group_chat_join_to_send',
    () => _fallback.group_chat_join_to_send,
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
  String get group_chat_delete_confirm_body => TolgeeBridge.get(
    localeName,
    'group_chat_delete_confirm_body',
    () => _fallback.group_chat_delete_confirm_body,
  );

  @override
  String get group_chat_delete_for_everyone => TolgeeBridge.get(
    localeName,
    'group_chat_delete_for_everyone',
    () => _fallback.group_chat_delete_for_everyone,
  );

  @override
  String get group_chat_delete_failed => TolgeeBridge.get(
    localeName,
    'group_chat_delete_failed',
    () => _fallback.group_chat_delete_failed,
  );

  @override
  String get group_chat_message_deleted => TolgeeBridge.get(
    localeName,
    'group_chat_message_deleted',
    () => _fallback.group_chat_message_deleted,
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
  String get event_live_audio => TolgeeBridge.get(
    localeName,
    'event_live_audio',
    () => _fallback.event_live_audio,
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
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'WeBuddhist';

  @override
  String get sign_in => 'Sign in';

  @override
  String get logout => 'Log out';

  @override
  String get onboarding_welcome => 'Welcome to';

  @override
  String get onboarding_setup_subtitle =>
      'Let\'s get you set up, It\'ll only take a minute';

  @override
  String get onboarding_tagline => 'Learn, practice, and connect. Daily.';

  @override
  String get onboarding_quote =>
      'Drop by drop the water pot is filled. Likewise, the wise person, gathering it little by little, fills themselves with good.';

  @override
  String get onboarding_find_peace => 'Get started';

  @override
  String get onboarding_continue => 'Continue';

  @override
  String get onboarding_first_question => 'Choose your language:';

  @override
  String get onboarding_choose_option => 'Choose at least one:';

  @override
  String get onboarding_all_set => 'You\'re all set';

  @override
  String get onboarding_all_set_description =>
      'Here\'s what\'s ready for your practice.';

  @override
  String get onboarding_all_set_feature_practices =>
      'Chants, accumulations, meditation, and study plans to choose from';

  @override
  String get onboarding_all_set_feature_reminders =>
      'Gentle daily reminders, whenever you\'re ready';

  @override
  String get onboarding_begin_practice => 'Find your first practices';

  @override
  String get onboarding_2_title => 'Next, here\'s how it works.';

  @override
  String get onboarding_2_subtitle => 'Three small steps to build the habit';

  @override
  String get onboarding_2_step1_title => 'Choose your practices';

  @override
  String get onboarding_2_step1_desc =>
      'Chant, count mantras, set a meditation timer, or follow a study plan from your tradition.';

  @override
  String get onboarding_2_step2_title => 'Add them to your day';

  @override
  String get onboarding_2_step2_desc =>
      'Build a daily routine and we\'ll send gentle reminders to keep it going.';

  @override
  String get onboarding_2_step3_title => 'Practice a few minutes a day';

  @override
  String get onboarding_2_step3_desc =>
      'Even a moment counts. Day by day, your practice grows.';

  @override
  String get home_recitation => 'recitations';

  @override
  String get home_today => 'Today';

  @override
  String get home_good_morning => 'Good morning';

  @override
  String get home_good_afternoon => 'Good afternoon';

  @override
  String get home_good_evening => 'Good evening';

  @override
  String get home_meditationTitle => 'Meditation';

  @override
  String get home_prayerTitle => 'Prayer of the day';

  @override
  String get home_scripture => 'Guided scripture';

  @override
  String get home_meditation => 'Guided meditation';

  @override
  String get home_goDeeper => 'Go deeper';

  @override
  String get home_intention => 'My intention for today';

  @override
  String get home_overall_stats => 'Overall stats';

  @override
  String get home_plans => 'plans';

  @override
  String home_plans_count(int count) {
    return '$count plans';
  }

  @override
  String home_recitation_count(int count) {
    return '$count chants';
  }

  @override
  String get home_shortcut_plans => 'Plans';

  @override
  String get home_chants => 'Chants';

  @override
  String get home_mala => 'Mala';

  @override
  String get session_mala => 'Malas';

  @override
  String get bookmark_mala => 'Malas';

  @override
  String get bookmark_timers => 'Timers';

  @override
  String get bookmark_texts => 'Texts';

  @override
  String get bookmark_group_accumulation => 'Group accumulation';

  @override
  String get mala_add_to_practice => 'Add to my practices';

  @override
  String get mala_add_mala_round => 'Add mala round';

  @override
  String get mala_add_rounds_title => 'Add mala rounds:';

  @override
  String get mala_add_rounds_message =>
      'Add the number of mala rounds you did outside this app.';

  @override
  String get mala_add_to_bookmark => 'Bookmark';

  @override
  String get mala_sound => 'Sound';

  @override
  String get mala_vibration => 'Vibration';

  @override
  String get mala_reset_count => 'Reset count';

  @override
  String get mala_reset_title => 'Reset this mala?';

  @override
  String get mala_reset_count_confirm =>
      'Your current count will go back to zero, but your accumulations will stay in your lifetime total.';

  @override
  String get mala_reset_confirm => 'Reset';

  @override
  String get mala_action_coming_soon => 'Coming soon';

  @override
  String mala_rounds_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rounds',
      one: '1 round',
      zero: '0 rounds',
    );
    return '$_temp0';
  }

  @override
  String mala_counter_semantics(int bead, int total, String rounds) {
    return 'Count $bead of $total, $rounds';
  }

  @override
  String get mala_group_accumulations => 'Group accumulations';

  @override
  String get mala_groups_section => 'Groups';

  @override
  String get mala_group_untitled => 'Untitled group';

  @override
  String get home_timer => 'Timer';

  @override
  String get preset_timers => 'Preset timers';

  @override
  String get meditation_timer => 'Meditation Timer';

  @override
  String get timer_min => 'min';

  @override
  String get timer_start => 'Start';

  @override
  String get timer_finish => 'Finish';

  @override
  String get timer_discard_session => 'Discard session';

  @override
  String get home_hello_prefix => 'Hello, ';

  @override
  String get home_greeting_fallback_name => 'there';

  @override
  String home_share_prompt(String appName) {
    return 'Enjoying $appName?';
  }

  @override
  String get no_feature_content => 'No featured content available';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_explore => 'Explore';

  @override
  String get nav_learn => 'Learn';

  @override
  String get nav_practice => 'Practice';

  @override
  String get nav_settings => 'Settings';

  @override
  String get nav_connect => 'Connect';

  @override
  String get nav_me => 'Me';

  @override
  String get tab_practices => 'Practices';

  @override
  String get text_search => 'Search';

  @override
  String get text_toc_versions => 'Versions';

  @override
  String get text_commentary => 'Commentaries';

  @override
  String get resources => 'Resources';

  @override
  String get no_translation => 'No translations found';

  @override
  String get text_close_commentary => 'Close commentary';

  @override
  String get show_more => 'Show more';

  @override
  String get show_less => 'Show less';

  @override
  String get more => 'More';

  @override
  String get less => 'Less';

  @override
  String get no_content => 'No content found';

  @override
  String get no_commentary => 'No commentaries found';

  @override
  String commentary_not_available_for_language(String language) {
    return '$language commentary not available';
  }

  @override
  String get loading => 'Loading...';

  @override
  String get choose_image => 'Choose image';

  @override
  String get choose_bg_image => 'Choose a background image';

  @override
  String get create_image => 'Create image';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get customise_message => 'Tap the customize icon to adjust text style';

  @override
  String get download_image => 'Download image';

  @override
  String get no_images_available => 'No images available';

  @override
  String get customise_text => 'Customize text';

  @override
  String get text_size => 'Text size';

  @override
  String get text_color => 'Text color';

  @override
  String get text_shadow => 'Text shadow';

  @override
  String get apply => 'Apply';

  @override
  String get my_plans => 'My plans';

  @override
  String get browse_plans => 'Browse plans';

  @override
  String get plan_info => 'Plan info';

  @override
  String get start_reading => 'Practice now';

  @override
  String get tibetan => 'Tibetan';

  @override
  String get sanskrit => 'Sanskrit';

  @override
  String get english => 'English';

  @override
  String get chinese => 'Chinese';

  @override
  String get classicalChinese => 'Classical Chinese';

  @override
  String get pali => 'Pali';

  @override
  String get language => 'Language';

  @override
  String get plan_unenroll => 'Unenroll';

  @override
  String get unenroll_confirmation => 'Are you sure you want to unenroll in';

  @override
  String get unenroll_message =>
      'Your progress will be permanently lost and cannot be recovered';

  @override
  String get practice_plan => 'Build a daily practice. Explore what fits you.';

  @override
  String get search_plans => 'Search plans...';

  @override
  String get search_for_plans => 'Search for plans';

  @override
  String get no_plans_found => 'No plans found';

  @override
  String get no_days_available => 'No days found';

  @override
  String get recitations_title => 'Recitations';

  @override
  String get recitations_my_recitations => 'My recitations';

  @override
  String get browse_recitations => 'Browse recitations';

  @override
  String get recitations_search => 'Search for recitations...';

  @override
  String get recitations_search_for => 'Search for recitations';

  @override
  String get recitations_no_found => 'No recitations founds';

  @override
  String get recitations_no_content => 'No recitations available';

  @override
  String get recitations_no_saved => 'No saved recitations';

  @override
  String get recitations_login_prompt =>
      'Sign in to view your saved recitations';

  @override
  String get my_recitation_collection_new_title => 'New Collection';

  @override
  String get my_recitation_collection_next => 'Next';

  @override
  String get my_recitation_collection_create => 'Create';

  @override
  String get my_recitation_collection_create_button => 'Create collection';

  @override
  String get my_recitation_collection_change_title => 'Change title';

  @override
  String get my_recitation_collection_change => 'Change';

  @override
  String get my_recitation_collection_add_chants => 'Add chants';

  @override
  String get my_recitation_collection_search_chants => 'Search chants';

  @override
  String get my_recitation_collection_add_to_collection => 'Add to collection';

  @override
  String get my_recitation_collection_edit => 'Edit collection';

  @override
  String get my_recitation_collection_delete => 'Delete collection';

  @override
  String get my_recitation_collection_delete_title => 'Delete collection?';

  @override
  String get my_recitation_collection_delete_message =>
      'This collection will be permanently removed.';

  @override
  String get my_recitation_collection_fallback_title => 'Chant collection';

  @override
  String get my_recitation_collection_unavailable => 'No longer available';

  @override
  String my_recitation_collection_chant_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chants',
      one: '1 chant',
      zero: '0 chants',
    );
    return '$_temp0';
  }

  @override
  String my_recitation_collection_chant_count_owner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chants • me',
      one: '1 chant • me',
      zero: '0 chants • me',
    );
    return '$_temp0';
  }

  @override
  String get bookmarks_empty_chant_collections_title =>
      'No chant collections bookmarked yet.';

  @override
  String get bookmarks_empty_chant_collections_subtitle =>
      'Bookmark a chant collection to save it here.';

  @override
  String get notification_settings => 'Notification settings';

  @override
  String get notification_allow_title => 'Allow notifications';

  @override
  String get notification_allow_subtitle_enabled =>
      'Notifications are enabled for this app';

  @override
  String get notification_allow_subtitle_disabled =>
      'Permission needed. Tap to grant in Settings.';

  @override
  String get notification_allow_subtitle_paused =>
      'Reminders are paused. Tap to resume.';

  @override
  String get notification_routine_title => 'Plan reminders';

  @override
  String get notification_routine_subtitle_enabled =>
      'Daily reminders for your plans';

  @override
  String get notification_routine_subtitle_disabled =>
      'Plan reminders are paused. Tap to resume';

  @override
  String get notification_battery_title => 'Background reminders';

  @override
  String get notification_battery_subtitle_enabled =>
      'Your reminders are sent on time, even when the app is closed.';

  @override
  String get notification_battery_subtitle_disabled =>
      'Some Android phones pause background apps to save battery, which can delay or skip your reminders. Tap to keep yours running.';

  @override
  String get notification_recitation_title => 'Chant reminders';

  @override
  String get notification_recitation_subtitle_enabled =>
      'Daily reminders for your chants';

  @override
  String get notification_recitation_subtitle_disabled =>
      'Chant reminders are paused. Tap to resume';

  @override
  String get notification_practice_title => 'Mala reminders';

  @override
  String get notification_practice_subtitle_enabled =>
      'Daily reminders for your mala practice';

  @override
  String get notification_practice_subtitle_disabled =>
      'Mala reminders are paused. Tap to resume.';

  @override
  String get notification_timer_title => 'Timer reminders';

  @override
  String get notification_timer_subtitle_enabled =>
      'Daily reminders for your timer sessions';

  @override
  String get notification_timer_subtitle_disabled =>
      'Timer reminders are paused. Tap to resume.';

  @override
  String get notification_battery_info_title => 'About background reminders';

  @override
  String get notification_battery_info_body =>
      'Some Android phones pause background apps to save battery, which can delay or cancel your scheduled reminders. Exempting the app keeps your reminders reliably on time.';

  @override
  String get notification_snack_permission_denied =>
      'Notifications are blocked. Turn them on in Settings';

  @override
  String get notification_snack_disable_alarms_in_settings =>
      'Turn off alarms & reminders in Settings.';

  @override
  String get notification_snack_battery_reenable =>
      'Restore battery optimization in Settings → Battery.';

  @override
  String get profile_default_bio => 'Welcome to WeBuddhist';

  @override
  String get profile_guest_title => 'Guest user';

  @override
  String get profile_guest_subtitle => 'You\'re browsing as a guest';

  @override
  String get profile_guest_benefits_header => 'Sign in to unlock:';

  @override
  String get profile_guest_benefit_save_progress => 'Save your progress';

  @override
  String get profile_guest_benefit_personalized => 'Personalized content';

  @override
  String get profile_guest_benefit_notifications => 'Custom notifications';

  @override
  String get auth_drawer_title => 'Log in to continue';

  @override
  String get auth_drawer_subtitle =>
      'Continue your practice on any device, wherever you go.';

  @override
  String get routine_delete_block_message =>
      'The session and all its items will be removed';

  @override
  String get something_went_wrong => 'Something went wrong. Please try again';

  @override
  String get onboarding_quote_citation => '— Dhammapada 122';

  @override
  String get onboarding_traditions_question =>
      'Which traditions\ndo you follow?';

  @override
  String get onboarding_tradition_title => 'How do you follow the Buddha?';

  @override
  String get onboarding_tradition_subtitle =>
      'We\'ll show you the practices and texts of your path. You can change this anytime in the app settings.';

  @override
  String get onboarding_tradition_option_intro => 'Through:';

  @override
  String get onboarding_tradition_show_all_title => 'Show me everything';

  @override
  String get onboarding_tradition_show_all_description =>
      'Practices and texts from every path';

  @override
  String get onboarding_skip_for_now => 'Skip for now';

  @override
  String get onboarding_add_another_tradition => 'Add another tradition';

  @override
  String get onboarding_select_all => 'Select all';

  @override
  String get onboarding_event_enrollment_error =>
      'Unable to enroll you. Check your connection and try again';

  @override
  String get onboarding_event_question => 'Join an\nevent?';

  @override
  String get onboarding_event_optional => 'Optional · Tap to enroll';

  @override
  String onboarding_event_duration(String description, int days) {
    return '$description · $days days';
  }

  @override
  String get onboarding_event_reminder_note =>
      'We\'ll send you a daily reminder at 7:30 AM. (Change anytime.)';

  @override
  String get tradition_theravada => 'Theravada';

  @override
  String get tradition_zen => 'Zen';

  @override
  String get tradition_tibetan_buddhism => 'Tibetan Buddhism';

  @override
  String get tradition_pure_land => 'Pure Land';

  @override
  String get tradition_ambedkar_buddhism => 'Ambedkar Buddhism';

  @override
  String get plan_go_to_practice => 'Go to practice';

  @override
  String get plan_starts_soon_title => 'Starts soon';

  @override
  String get plan_joining_late_title => 'Joining after start date';

  @override
  String get got_it => 'Got it';

  @override
  String get plan_no_tasks_error => 'Unable to load tasks';

  @override
  String get plan_day_tasks_load_error => 'Unable to load tasks';

  @override
  String get plans_empty_title => 'More is on the way';

  @override
  String get plans_empty_subtitle => 'Our library is growing. Check back soon.';

  @override
  String get find_plans_load_error =>
      'Unable to load.\nCheck your connection and try again';

  @override
  String get connect_coming_soon_subtitle =>
      'Teachers, communities, challenges, and events to support you on the path';

  @override
  String get connect_subtitle => 'Find your groups and practice together';

  @override
  String get discover_groups => 'Discover groups';

  @override
  String get my_groups => 'My groups';

  @override
  String get see_all => 'See all';

  @override
  String get connect_groups_load_error =>
      'Unable to load groups.\nCheck your connection and try again';

  @override
  String get connect_groups_empty_title => 'No more groups';

  @override
  String get connect_groups_empty_subtitle =>
      'Congratulations, you\'ve joined all our groups! Check back soon. New ones are on the way';

  @override
  String get connect_tab_feed => 'Feed';

  @override
  String get connect_tab_events => 'Events';

  @override
  String get connect_tab_posts => 'Posts';

  @override
  String get connect_tab_practices => 'Practices';

  @override
  String get connect_tab_groups => 'Groups';

  @override
  String get connect_segment_my => 'For you';

  @override
  String get connect_segment_discover => 'Discover';

  @override
  String get connect_empty_discover_posts => 'No posts to discover';

  @override
  String get connect_empty_discover_events => 'No events to discover';

  @override
  String get connect_empty_discover_feed => 'Nothing to discover';

  @override
  String get connect_empty_discover_groups => 'No groups to discover';

  @override
  String get connect_empty_discover_practices => 'No practices to discover';

  @override
  String get connect_all_groups => 'All groups';

  @override
  String get connect_my_empty_feed_title => 'Your groups have been quiet';

  @override
  String get connect_my_empty_events_title => 'No upcoming events';

  @override
  String get connect_my_empty_posts_title => 'No posts yet';

  @override
  String get connect_my_empty_groups_title => 'No groups yet';

  @override
  String get connect_my_empty_feed_subtitle =>
      'Nothing new from the groups you have joined. Other groups are posting today.';

  @override
  String get connect_my_empty_events_subtitle =>
      'None of your groups have anything scheduled. Other groups have events open to everyone.';

  @override
  String get connect_my_empty_posts_subtitle =>
      'Your groups have not posted anything. See what other groups are sharing.';

  @override
  String get connect_my_empty_groups_subtitle =>
      'You have not joined any groups yet. Discover communities to practice with.';

  @override
  String get connect_my_empty_feed_browse => 'See what other groups share';

  @override
  String get connect_my_empty_events_browse => 'Browse open events';

  @override
  String get connect_my_empty_posts_browse => 'Browse other posts';

  @override
  String get connect_my_empty_practices_title => 'No practices yet';

  @override
  String get connect_my_empty_practices_subtitle =>
      'Your groups have not started any practices. See what other groups are offering.';

  @override
  String get connect_my_empty_practices_browse => 'Browse other practices';

  @override
  String connect_comment_replying_to(String handle) {
    return 'Replying to @$handle';
  }

  @override
  String get connect_comment_hint => 'What do you think of this?';

  @override
  String get connect_comment_reply_hint => 'Write a reply...';

  @override
  String get connect_comment_reply => 'Reply';

  @override
  String get connect_comment_delete_title => 'Delete comment?';

  @override
  String get connect_comment_delete_message =>
      'This comment will be permanently removed.';

  @override
  String get connect_comment_delete_failed => 'Failed to delete comment';

  @override
  String connect_post_comments_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
    );
    return '$_temp0';
  }

  @override
  String get connect_post_comments_empty =>
      'No comments yet. Start the conversation.';

  @override
  String get connect_caption_more => 'More';

  @override
  String get connect_online => 'Online';

  @override
  String get home_group_events => 'Group Events';

  @override
  String get home_poems => 'Poems';

  @override
  String get poems_load_error =>
      'Unable to load poems.\nCheck your connection and try again';

  @override
  String get poems_empty => 'No poems yet. Check back soon.';

  @override
  String get connect_events_filter_all => 'All';

  @override
  String get connect_events_filter_in_person => 'In person';

  @override
  String get connect_events_filter_empty_online => 'No online events';

  @override
  String get connect_events_filter_empty_in_person => 'No in-person events';

  @override
  String get connect_events_filter_hybrid => 'Hybrid';

  @override
  String get connect_events_filter_empty_hybrid => 'No hybrid events';

  @override
  String get connect_open => 'Open';

  @override
  String get connect_event_fallback_title => 'Event';

  @override
  String get connect_group_fallback_title => 'Group';

  @override
  String get connect_event_attend => 'Attend';

  @override
  String get connect_event_attending => 'Attending';

  @override
  String connect_event_participants_attending(int count) {
    return '$count attending';
  }

  @override
  String get connect_event_participants_empty => 'No participants yet';

  @override
  String get connect_event_tab_videos => 'Videos';

  @override
  String get connect_event_tab_links => 'Links';

  @override
  String get connect_event_tab_about => 'About';

  @override
  String get connect_event_links_title => 'More about this event';

  @override
  String get connect_event_links_empty => 'No links yet';

  @override
  String get connect_event_link_tap_to_join => 'Tap to join';

  @override
  String get connect_event_link_open => 'Open link';

  @override
  String get connect_event_date_tba => 'Date to be announced';

  @override
  String get connect_event_when => 'When';

  @override
  String get connect_event_where => 'Where';

  @override
  String get connect_event_practices => 'Event practices';

  @override
  String get connect_event_tab_accumulations => 'Accumulations';

  @override
  String get connect_event_tab_recitations => 'Recitations';

  @override
  String get connect_event_add_recitations => 'Add recitations';

  @override
  String get connect_event_add_recitations_message =>
      'Add the number of recitations you did with the livestream or outside this app.';

  @override
  String get connect_event_every_day => 'Every day';

  @override
  String connect_event_every_weekday(String weekday) {
    return 'Every $weekday';
  }

  @override
  String get connect_event_every_month => 'Every month';

  @override
  String connect_event_every_date(String date) {
    return 'Every $date';
  }

  @override
  String get connect_event_about_empty => 'No event details yet';

  @override
  String get search_groups => 'Search groups';

  @override
  String get search_for_groups => 'Search for groups';

  @override
  String get no_groups_found => 'No matching groups found';

  @override
  String get explore_coming_soon_subtitle =>
      'A curated space to discover practices, teachings, and community events';

  @override
  String get learn_coming_soon_subtitle =>
      'Your personal study plans, designed to fit into everyday life';

  @override
  String get creator_featured_plan => 'Featured plans';

  @override
  String get audio_init_error =>
      'Unable to initialize audio player. Check your connection and try again';

  @override
  String get meditation_audio_load_error =>
      'Unable to load. Check your connection and try again';

  @override
  String get prayer_audio_load_error =>
      'Unable to load audio. Check your connection and try again';

  @override
  String get home_no_series_found => 'No series found';

  @override
  String get home_no_tags_found => 'No tags found';

  @override
  String get home_celebrated_by => 'Celebrated by: ';

  @override
  String get reader_settings_tooltip => 'Reader settings';

  @override
  String get reader_translate_tooltip => 'Show translation';

  @override
  String get reader_translate_unavailable =>
      'Translation not available for this text';

  @override
  String get reader_font_size_tooltip => 'Font size';

  @override
  String reader_version_title(String language) {
    return 'Version · $language';
  }

  @override
  String reader_script_title(String language) {
    return 'Script · $language';
  }

  @override
  String get reader_versions_load_error => 'Failed to load versions';

  @override
  String get reader_scripts_load_error => 'Failed to load scripts';

  @override
  String get reader_languages_load_error => 'Failed to load languages';

  @override
  String reader_no_versions_in_language(String language) {
    return 'No versions available in $language';
  }

  @override
  String reader_no_scripts_in_language(String language) {
    return 'No scripts available in $language';
  }

  @override
  String get reader_no_languages => 'No languages available for this text';

  @override
  String get reader_license => 'License';

  @override
  String get reader_version_details_load_error =>
      'Unable to load version details';

  @override
  String get reader_no_version_info =>
      'No additional information is available for this version';

  @override
  String get recitation_unavailable =>
      'Recitation content is currently unavailable.\nTry again later or contact support';

  @override
  String get recitation_sign_in_required => 'Sign in to access this recitation';

  @override
  String get my_recitations_load_error =>
      'Unable to load.\nCheck your connection and try again';

  @override
  String get recitations_load_error =>
      'Unable to load recitations.\nTry again later';

  @override
  String get text_search_hint => 'Type to search';

  @override
  String get text_search_press_button => 'Press search button to search';

  @override
  String get text_search_error => 'Unable to perform search.\nPlease try again';

  @override
  String get unknown_error => 'Unknown error';

  @override
  String image_share_error(String error) {
    return 'Unable to share: $error';
  }

  @override
  String get create_image_capture_error =>
      'Failed to create image. Please try again';

  @override
  String get create_image_share_error => 'Unable to share. Please try again';

  @override
  String get create_image_save_success => 'Image saved';

  @override
  String get create_image_save_error =>
      'Unable to save image. Check that the app has photo access, or try again';

  @override
  String get create_image_download_error =>
      'Unable to download your image. Please try again';

  @override
  String get create_image_customize_tooltip => 'Customize';

  @override
  String get create_image_text_too_long =>
      'Text is too long to increase font size';

  @override
  String version_search_no_results(String query) {
    return 'No versions found for \"$query\"';
  }

  @override
  String get my_plans_sign_in_prompt => 'Sign in to view your plans';

  @override
  String plan_starts_soon_message(String date) {
    return 'Starts on $date. You can browse the content now';
  }

  @override
  String plan_joining_late_message(String date) {
    return 'Started on $date. Feel free to complete previous days\' tasks';
  }

  @override
  String get select_language => 'Select language';

  @override
  String get logout_confirmation => 'Are you sure you want to log out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get share => 'Share';

  @override
  String get bookmark => 'Bookmark';

  @override
  String get image => 'Image';

  @override
  String get feedback => 'Feedback';

  @override
  String get author => 'Author';

  @override
  String get plans_created => 'Plan created';

  @override
  String get ai_chat_history => 'Chat history';

  @override
  String get ai_buddhist_assistant =>
      'Build your daily rhythm. Set times, and we\'ll remind you to practice';

  @override
  String get ai_new_chat => 'New chat';

  @override
  String get ai_retry => 'Retry';

  @override
  String get ai_dismiss => 'Dismiss';

  @override
  String get ai_sign_in_prompt => 'Sign in to use the Buddhist AI Assistant';

  @override
  String get ai_explore_wisdom => 'Explore Buddhist wisdom';

  @override
  String get ai_ask_question => 'Ask a question...';

  @override
  String get ai_search_chats => 'Search for chats';

  @override
  String get ai_chats => 'Chats';

  @override
  String get ai_chat_deleted => 'Chat deleted';

  @override
  String get ai_no_conversations => 'No conversations yet';

  @override
  String get ai_start_new_chat => 'Start a new chat to begin.';

  @override
  String get ai_delete_chat => 'Delete chat';

  @override
  String get ai_delete_confirmation =>
      'Are you sure you want to delete this chat?';

  @override
  String get ai_delete_warning => 'This action cannot be undone.';

  @override
  String get ai_confirm => 'Confirm';

  @override
  String get ai_delete => 'Delete';

  @override
  String ai_greeting(String name) {
    return 'Hi $name';
  }

  @override
  String get ai_text_not_found => 'Text not found.';

  @override
  String ai_text_not_found_message(String title) {
    return 'We don\'t have \"$title\" in our library yet.\n\nTry a different title, or ask another way';
  }

  @override
  String get ai_sources => 'Sources';

  @override
  String ai_sources_count(int count) {
    return '$count sources';
  }

  @override
  String search_no_results(String query) {
    return 'No results found for \"$query\"';
  }

  @override
  String get search_show_more => 'Show more';

  @override
  String get search_contents => 'Contents';

  @override
  String get search_titles => 'Titles';

  @override
  String get search_all => 'All';

  @override
  String get search_author => 'Author';

  @override
  String get search_tab_ai_mode => 'AI mode';

  @override
  String search_error(String message) {
    return 'Error: $message';
  }

  @override
  String get search_retrying => 'Retrying...';

  @override
  String search_no_titles_found(String query) {
    return 'No titles found for \"$query\"';
  }

  @override
  String search_no_contents_found(String query) {
    return 'No contents found for \"$query\"';
  }

  @override
  String search_no_authors_found(String query) {
    return 'No authors found for \"$query\"';
  }

  @override
  String get search_buddhist_texts => 'Search Buddhist texts...';

  @override
  String get common_ok => 'OK';

  @override
  String get comingSoonHeadline => 'Coming soon';

  @override
  String get routine_title => 'My practices';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get routine_empty_title => 'Practices';

  @override
  String get routine_edit => 'Edit';

  @override
  String get routine_empty_description =>
      'Explore more teachings and practices to add to your routine';

  @override
  String get routine_build => 'Build your routine';

  @override
  String get routine_add_session => 'Add to session';

  @override
  String get routine_edit_title => 'Edit your practices';

  @override
  String get routine_delete_block => 'Remove session';

  @override
  String get routine_session_title_hint => 'Title...';

  @override
  String get routine_expand_all => 'Expand all';

  @override
  String get routine_collapse_all => 'Collapse all';

  @override
  String get routine_delete_time_block => 'Remove time block';

  @override
  String get routine_add_plan => 'Add plan';

  @override
  String get routine_add_recitation => 'Add recitation';

  @override
  String get routine_add_plan_to_routine => 'Add to routine';

  @override
  String get routine_load_error =>
      'Unable to load. Check your connection and try again';

  @override
  String get routine_empty_block_title_singular => 'Empty time block';

  @override
  String routine_empty_block_title_plural(int count) {
    return 'Empty time blocks ($count)';
  }

  @override
  String get routine_empty_block_message_singular =>
      'This time block is empty. Add an item, or remove it from your routine?';

  @override
  String routine_empty_block_message_plural(int count) {
    return '$count time blocks are empty. Add items, or remove them from your routine?';
  }

  @override
  String get routine_empty_block_add_items => 'Add items';

  @override
  String get routine_empty_block_delete_singular => 'Remove session';

  @override
  String get routine_empty_block_delete_plural => 'Remove sessions';

  @override
  String get routine_notification_title => 'Make practice a habit';

  @override
  String get routine_notification_description =>
      'Allow notifications so we can remind you to practice';

  @override
  String get routine_notification_enable => 'Enable notifications';

  @override
  String get routine_notification_skip => 'Skip';

  @override
  String routine_time_adjusted(String time, int gap) {
    return 'Adjusted to $time ($gap-min minimum gap)';
  }

  @override
  String get routine_add_block_label => 'Time block';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithPhone => 'Continue with phone';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get exploreAsGuest => 'Explore as a Guest';

  @override
  String get signIn => 'Sign In';

  @override
  String get profileError => 'Error loading profile';

  @override
  String get profileTitle => 'Profile';

  @override
  String get notLoggedIn => 'Not logged in';

  @override
  String get retry => 'Retry';

  @override
  String get back => 'Back';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get tryAgain => 'Try again';

  @override
  String get pleaseTryAgain => 'Please try again';

  @override
  String get error => 'Error';

  @override
  String get anonymous => 'Anonymous';

  @override
  String get noContentAvailable => 'No content available';

  @override
  String get unableToLoad =>
      'Unable to load. Check your connection and try again';

  @override
  String get somethingWrong =>
      'Something went wrong. Check your connection and try again';

  @override
  String get source => 'Source';

  @override
  String get searchResults => 'Search results';

  @override
  String get noTasks => 'No tasks available';

  @override
  String get taskNotFound => 'Task not found';

  @override
  String get updateTaskError => 'Unable to update task status';

  @override
  String get enrollError =>
      'Unable to enroll you. Check your connection and try again';

  @override
  String unenrollSuccess(String planTitle) {
    return 'You have unenrolled in $planTitle';
  }

  @override
  String get unenrollError =>
      'Unable to unenroll you. Check your connection and try again';

  @override
  String get unenrollGenericError =>
      'Something went wrong. Check your connection and try again';

  @override
  String get notFound =>
      'This is no longer available. Edit your routine to update.';

  @override
  String get noTimeSlot =>
      'No available time slots. Try removing a block first';

  @override
  String maxBlocks(int max) {
    return 'Maximum of $max time blocks reached';
  }

  @override
  String get duplicateItem => 'This item is already in the block';

  @override
  String get removeItem => 'Remove item?';

  @override
  String removeConfirmation(String itemName) {
    return '\"$itemName\" will be removed from this block';
  }

  @override
  String shareError(String error) {
    return 'Unable to share. Please try again';
  }

  @override
  String get updateOrderError => 'Unable to update order. Please try again';

  @override
  String get loadFailed =>
      'Unable to load. Check your connection and try again';

  @override
  String get captureError => 'Failed to capture QR code. Please try again';

  @override
  String get qrShareError => 'Unable to share QR code. Try again later';

  @override
  String errorDetail(String error) {
    return 'Error: $error';
  }

  @override
  String missedDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count missed days',
      one: '1 missed day',
      zero: '0 missed days',
    );
    return '$_temp0';
  }

  @override
  String get plan_status_on_track => 'On track!';

  @override
  String get start_now => 'Start now';

  @override
  String get plan_enroll => 'Enroll';

  @override
  String get show_second_version => 'Show second version';

  @override
  String get enable_add_msg =>
      'Enable to add a translation or transliteration alongside the main text';

  @override
  String get main_version => 'Main version';

  @override
  String get second_version => 'Second version';

  @override
  String get second_version_msg =>
      'The second version will appear below each verse of the main text';

  @override
  String get version => 'Versions';

  @override
  String get parallel_version => 'Parallel version';

  @override
  String get version_not_available => 'Not available';

  @override
  String get read_full_text => 'Read full text';

  @override
  String get reader_source_label => 'Source';

  @override
  String get reader_license_label => 'License';

  @override
  String series_stats(int planCount, int totalDays) {
    return '$planCount CHAPTERS · $totalDays DAYS';
  }

  @override
  String get force_update_title => 'Update required';

  @override
  String get force_update_message =>
      'A new version of the app is available. Please update to continue';

  @override
  String get force_update_button => 'Update now';

  @override
  String get settings_section_personalisation => 'PERSONALIZATION';

  @override
  String get settings_section_more => 'MORE';

  @override
  String get settings_section_account => 'ACCOUNT';

  @override
  String get settings_edit_profile => 'Edit profile';

  @override
  String get settings_theme => 'Theme';

  @override
  String get settings_notification_row => 'Notifications';

  @override
  String get settings_feedback_row => 'Feedback';

  @override
  String get edit_profile_title => 'Edit profile';

  @override
  String get edit_profile_save => 'Save';

  @override
  String get edit_profile_first_name => 'First name';

  @override
  String get edit_profile_last_name => 'Last name';

  @override
  String get edit_profile_bio => 'Bio';

  @override
  String get edit_profile_bio_hint => 'Share a little about yourself';

  @override
  String get edit_profile_delete_account => 'Delete account';

  @override
  String get edit_profile_photo_not_uploaded => 'Photo not uploaded';

  @override
  String get edit_profile_photo_too_large =>
      'Image is too large. Please choose a photo under 1 MB and try again';

  @override
  String get edit_profile_photo_upload_failed =>
      'Could not upload your photo. Please try again';

  @override
  String get edit_profile_choose_from_library => 'Choose from library';

  @override
  String get edit_profile_take_photo => 'Take a photo';

  @override
  String get edit_profile_offline =>
      'You\'re offline. Connect to the internet and try again';

  @override
  String get edit_profile_save_failed =>
      'Couldn\'t save your changes. Please try again';

  @override
  String get edit_profile_traditions => 'Traditions';

  @override
  String get edit_profile_choose_traditions => 'Choose your traditions';

  @override
  String get edit_profile_tradition_remove_failed =>
      'Couldn\'t remove tradition. Please try again';

  @override
  String get edit_profile_tradition_save_failed =>
      'Couldn\'t save traditions. Please try again';

  @override
  String get username_label => 'Username';

  @override
  String get username_taken => 'Someone already used this name';

  @override
  String get username_available_label => 'Available:';

  @override
  String get username_check_error => 'Unable to check username. Try again';

  @override
  String get username_invalid_format => 'Invalid username format';

  @override
  String get username_min_length => 'Username must be at least 3 characters';

  @override
  String get username_max_length => 'Username must be 30 characters or less';

  @override
  String get username_no_spaces => 'Username cannot contain spaces';

  @override
  String get username_invalid_chars =>
      'Only letters, numbers, _ . - are allowed';

  @override
  String get username_must_start_alphanumeric =>
      'Username must start with a letter or number';

  @override
  String get username_must_end_alphanumeric =>
      'Username must end with a letter or number';

  @override
  String get person_name_min_length => 'Must be at least 1 character';

  @override
  String get person_name_max_length => 'Must be 50 characters or less';

  @override
  String get person_name_invalid_chars =>
      'Only letters, spaces, hyphens, and apostrophes are allowed';

  @override
  String get about_title => 'About';

  @override
  String get about_connect_with_us => 'Connect with us...';

  @override
  String get about_description =>
      'We help Buddhists do less harm, more good, and know their own mind better by learning, practicing and connecting daily.';

  @override
  String get about_social_website => 'Website';

  @override
  String get me_guest_headline => 'Access the full experience';

  @override
  String get me_guest_subtitle => 'Create a free account to save your progress';

  @override
  String get me_my_stats => 'My stats';

  @override
  String me_day_streak(int count) {
    return '$count-day streak';
  }

  @override
  String me_best_streak(int count) {
    return 'Longest streak: $count days';
  }

  @override
  String get accumulations => 'Accumulations';

  @override
  String get accumulations_search => 'Search for accumulations...';

  @override
  String get accumulations_search_for => 'Search for accumulations';

  @override
  String get accumulations_no_found => 'No accumulations found';

  @override
  String get me_accumulation => 'Total accumulations';

  @override
  String get me_counts => 'counts';

  @override
  String get me_minutes => 'minutes';

  @override
  String get me_hours => 'hours';

  @override
  String get me_total_meditation_time => 'Total meditation time';

  @override
  String get me_days_plan_practiced_suffix => 'Total plan days completed';

  @override
  String me_streak_share_message(int count, String appName) {
    return 'I\'m on a $count-day streak on $appName!';
  }

  @override
  String get me_streak_share_quote => 'My current streak on WeBuddhist!';

  @override
  String me_streak_days_count(int count) {
    return '$count days';
  }

  @override
  String get share_this_streak => 'Share my streak';

  @override
  String get me_streak_share_error =>
      'Unable to share streak. Please try again';

  @override
  String get delete_account_title => 'Delete account';

  @override
  String get delete_account_description =>
      'If you delete your account, all your information, history, and personalized settings within WeBuddhist will be permanently eliminated. Please note that this action is irreversible. To proceed, tap the button below.';

  @override
  String get delete_account_button => 'Delete account';

  @override
  String get delete_account_confirm_message =>
      'Are you sure you want to delete your WeBuddhist account?';

  @override
  String get legal_title => 'Legal';

  @override
  String get legal_terms_of_service => 'Terms of service';

  @override
  String get legal_privacy_policy => 'Privacy policy';

  @override
  String get follow => 'Follow';

  @override
  String get following => 'Following';

  @override
  String get calendar_title => 'Calendar';

  @override
  String get calendar_upcoming_events => 'Upcoming events';

  @override
  String get calendar_day_short => 'DAY';

  @override
  String get calendar_day_label => 'Day';

  @override
  String calendar_day_month(int day, int month) {
    return 'Day $day · Month $month';
  }

  @override
  String calendar_lunar_month(String ordinal) {
    return '$ordinal lunar month';
  }

  @override
  String get moon_phase_new_moon => 'New moon';

  @override
  String get moon_phase_waxing_crescent => 'Waxing crescent';

  @override
  String get moon_phase_first_quarter => 'First quarter';

  @override
  String get moon_phase_waxing_gibbous => 'Waxing gibbous';

  @override
  String get moon_phase_full_moon => 'Full moon';

  @override
  String get moon_phase_waning_gibbous => 'Waning gibbous';

  @override
  String get moon_phase_last_quarter => 'Last quarter';

  @override
  String get moon_phase_waning_crescent => 'Waning crescent';

  @override
  String get join => 'Join';

  @override
  String get joined => 'Joined';

  @override
  String get group_member => 'member';

  @override
  String get group_members => 'members';

  @override
  String get group_tab_members => 'Members';

  @override
  String get group_tab_followers => 'Followers';

  @override
  String group_members_heading(int count) {
    return 'Members($count)';
  }

  @override
  String group_followers_heading(int count) {
    return 'Followers($count)';
  }

  @override
  String get group_invite => 'Invite';

  @override
  String get group_request_to_join => 'Request to join';

  @override
  String get group_request => 'Request';

  @override
  String get group_request_sent => 'Request sent';

  @override
  String get group_join_request_title => 'Request to join';

  @override
  String get group_join_request_message_label => 'Message (optional)';

  @override
  String get group_join_request_message_hint =>
      'How do you practice, or who invited you?';

  @override
  String get group_join_request_send => 'Send request';

  @override
  String get group_join_request_sent_snackbar =>
      'Request sent — an admin will review it.';

  @override
  String get group_join_request_error =>
      'Unable to send request. Please try again.';

  @override
  String get group_members_only_title => 'Members only';

  @override
  String get group_members_only_message =>
      'Join to see this group\'s chants, events and posts.';

  @override
  String get group_join_request_waiting_title => 'Waiting on an admin';

  @override
  String get group_join_request_waiting_message =>
      'We\'ll notify you as soon as your request is reviewed.';

  @override
  String get group_members_load_error =>
      'Unable to load members. Please try again.';

  @override
  String get group_followers_load_error =>
      'Unable to load followers. Please try again.';

  @override
  String get group_members_empty => 'No members yet';

  @override
  String get group_followers_empty => 'No followers yet';

  @override
  String get group_follower => 'follower';

  @override
  String get group_followers => 'followers';

  @override
  String get group_links_title => 'Links';

  @override
  String get group_about_description => 'Description';

  @override
  String get group_about_empty => 'No information available yet';

  @override
  String group_and_more_links(int count) {
    return 'and $count more links';
  }

  @override
  String get group_practice_with_us => 'Practice with us';

  @override
  String series_practicing_with_group(String groupName) {
    return 'Practicing with $groupName';
  }

  @override
  String get group_change_practice_title => 'Change group practice';

  @override
  String get group_change_practice_message =>
      'You are already practicing this plan with another group. Would you like to change your practice group?';

  @override
  String get group_join_to_contribute => 'Join to contribute';

  @override
  String get group_accumulator_join_error =>
      'Unable to join accumulation. Please try again.';

  @override
  String get group_accumulator_join_before_practice =>
      'Join this accumulation before adding it to your practices';

  @override
  String group_accumulator_participants(int count) {
    return '$count participants';
  }

  @override
  String get group_accumulator_leaderboard => 'Leaderboard';

  @override
  String get group_accumulator_my_contributions => 'My Contributions';

  @override
  String get group_accumulator_recited => 'Recited';

  @override
  String get group_accumulator_total => 'Total';

  @override
  String get group_accumulator_contributions_empty =>
      'Join this accumulation to track your contributions.';

  @override
  String get group_accumulator_leaderboard_empty => 'No recitations yet.';

  @override
  String get group_accumulator_recite_now => 'Recite now';

  @override
  String get group_accumulator_chant_again => 'Chant again';

  @override
  String get group_accumulator_finish_session => 'Finish session';

  @override
  String get group_accumulator_offline_recitation => 'Offline recitation';

  @override
  String get group_accumulator_add_offline_chants_title =>
      'Add offline chants:';

  @override
  String get group_accumulator_add_offline_chants_message =>
      'Add the number of chants you did outside this app.';

  @override
  String get group_accumulator_session_complete => 'Session complete!';

  @override
  String group_accumulator_session_recitations(int count) {
    return 'You completed $count recitations this session';
  }

  @override
  String group_accumulator_session_share_message(
    int count,
    String accumulation,
    String group,
  ) {
    return 'I completed $count recitations in \"$accumulation\", a group accumulation by $group on WeBuddhist. Come join me!';
  }

  @override
  String group_accumulator_session_share_message_no_group(
    int count,
    String accumulation,
  ) {
    return 'I completed $count recitations in the group accumulation \"$accumulation\" on WeBuddhist. Come join me!';
  }

  @override
  String get group_accumulator_session_share_error =>
      'Unable to share session. Please try again';

  @override
  String group_recitation_collection_share_message(
    String collection,
    String group,
  ) {
    return 'Check out \"$collection\", a recitation collection by $group on WeBuddhist. Join us in practice!';
  }

  @override
  String group_recitation_collection_share_message_no_group(String collection) {
    return 'Check out the recitation collection \"$collection\" on WeBuddhist. Join us in practice!';
  }

  @override
  String group_recitation_collection_completed_title(String collection) {
    return '$collection completed';
  }

  @override
  String get group_recitation_collection_dedication =>
      'By this merit, may all beings\nbe free from suffering.';

  @override
  String get share_this_quote => 'Share this quote';

  @override
  String get shared_from => 'Shared from';

  @override
  String get verse_share_error => 'Unable to share quote. Please try again';

  @override
  String get share_app_message =>
      'I\'ve been using this app to build a daily Buddhist practice, and thought you\'d love it.';

  @override
  String get share_streak_message =>
      'I\'ve been building a daily practice habit and wanted to share it with you. It\'s easier to keep it up with a friend. Join me on WeBuddhist.';

  @override
  String get share_chant_message =>
      'I wanted to share this chant with you. You can practice it and find a whole library of other chants and texts on WeBuddhist.';

  @override
  String get share_quote_message =>
      'I liked this quote from WeBuddhist and wanted to share it with you. Read more such insightful quotes on the WeBuddhist App';

  @override
  String get share_poem_message =>
      'I liked this poem from WeBuddhist and wanted to share it with you.';

  @override
  String get share_mala_message =>
      'I\'ve been using this digital mala on WeBuddhist and wanted to share it with you. It\'s an easy way to practice wherever you go.';

  @override
  String get share_passage_message =>
      'I liked this passage and wanted to share it with you. You can read the whole quote in context on WeBuddhist.';

  @override
  String get share_timer_message =>
      'I wanted to share this meditation timer from WeBuddhist with you. It makes it easy to build a meditation practice.';

  @override
  String get share_plan_message =>
      'I\'m following this Buddhist practice plan and wanted to share it with you. You can join me for free on WeBuddhist.';

  @override
  String get share_plan_subject => 'Join me on WeBuddhist';

  @override
  String get share_group_invite_message =>
      'I\'d love for you to join our group. Let\'s practice together on WeBuddhist.';

  @override
  String get weekday_monday => 'MON';

  @override
  String get weekday_tuesday => 'TUE';

  @override
  String get weekday_wednesday => 'WED';

  @override
  String get weekday_thursday => 'THU';

  @override
  String get weekday_friday => 'FRI';

  @override
  String get weekday_saturday => 'SAT';

  @override
  String get weekday_sunday => 'SUN';

  @override
  String get reader_search_failed => 'Search failed.\nPlease try again';

  @override
  String get reader_swipe_up_for_more => 'Swipe up for more';

  @override
  String get reader_videos => 'Videos';

  @override
  String get reader_about_this_version => 'About this version';

  @override
  String reader_version_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versions',
      one: '1 version',
    );
    return '$_temp0';
  }

  @override
  String get mala_no_mantras => 'No mantras available';

  @override
  String get mala_count_load_error => 'Could not load your count';

  @override
  String get mala_mantra_label => 'Mantra';

  @override
  String get bookmarks_empty_all_title => 'Nothing bookmarked yet.';

  @override
  String get bookmarks_empty_all_subtitle =>
      'Bookmark anything to save it here.';

  @override
  String get bookmarks_empty_plans_title => 'No plans bookmarked yet.';

  @override
  String get bookmarks_empty_plans_subtitle =>
      'Bookmark a plan to save it here.';

  @override
  String get bookmarks_empty_malas_title => 'No malas bookmarked yet.';

  @override
  String get bookmarks_empty_malas_subtitle =>
      'Bookmark a mala to save it here.';

  @override
  String get bookmarks_empty_group_accumulations_title =>
      'No group accumulations bookmarked yet.';

  @override
  String get bookmarks_empty_group_accumulations_subtitle =>
      'Bookmark a group accumulation to save it here.';

  @override
  String get bookmarks_empty_timers_title => 'No timers bookmarked yet.';

  @override
  String get bookmarks_empty_timers_subtitle =>
      'Bookmark a timer to save it here.';

  @override
  String get bookmarks_empty_texts_title => 'No texts bookmarked yet.';

  @override
  String get bookmarks_empty_texts_subtitle =>
      'Bookmark a text to save it here.';

  @override
  String get bookmark_removed => 'Bookmark removed';

  @override
  String get bookmark_remove_failed => 'Failed to remove bookmark';

  @override
  String get bookmark_saved => 'Bookmark saved';

  @override
  String get bookmark_save_failed => 'Failed to save bookmark';

  @override
  String get bookmarks_yesterday => 'Yesterday';

  @override
  String get webview_timeout_error =>
      'Page took too long to load. Please check your internet connection.';

  @override
  String get webview_load_failed => 'Failed to load page';

  @override
  String get privacy_policy_load_error =>
      'Unable to load the privacy policy page.';

  @override
  String get terms_of_service_load_error =>
      'Unable to load the terms of service page.';

  @override
  String get series_enroll_error => 'Failed to enroll in series';

  @override
  String series_share_message(String title, String url) {
    return 'Join me in practicing $title on WeBuddhist.\n\n$url';
  }

  @override
  String get player_back_10 => 'Back 10 seconds';

  @override
  String get player_pause => 'Pause';

  @override
  String get player_play => 'Play';

  @override
  String get player_forward_10 => 'Forward 10 seconds';

  @override
  String get session_plans_load_error =>
      'Unable to load plans.\nPlease try again later.';

  @override
  String get session_chants_load_error => 'Unable to load chants';

  @override
  String get session_no_chants => 'No chants found';

  @override
  String get session_malas_load_error => 'Unable to load malas';

  @override
  String get session_no_malas => 'No malas found';

  @override
  String get session_timers_load_error => 'Unable to load timers';

  @override
  String get session_no_timers => 'No timers found';

  @override
  String days_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Days',
      one: '1 Day',
    );
    return '$_temp0';
  }

  @override
  String timer_minute_session(int minutes) {
    return '$minutes min session';
  }

  @override
  String get timer_notification_in_progress => 'Meditation in progress';

  @override
  String timer_notification_paused(String time) {
    return 'Paused · $time left';
  }

  @override
  String get timer_notification_complete => 'Your session is complete';

  @override
  String get ai_use_search_instead => 'Use Search Instead';

  @override
  String get ai_mode_label => 'AI';

  @override
  String plan_day_of(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String pagination_position(int current, int total) {
    return '$current of $total';
  }

  @override
  String get plan_shorts_title => 'Shorts from the community';

  @override
  String get author_details_load_error =>
      'Unable to load author details.\nPlease try again.';

  @override
  String get link_cannot_open => 'Cannot open this link';

  @override
  String get link_invalid => 'Invalid URL';

  @override
  String get author_no_plans => 'No plans created yet';

  @override
  String get author_plans_load_error => 'Unable to load plans';

  @override
  String source_with_value(String value) {
    return 'Source: $value';
  }

  @override
  String license_with_value(String value) {
    return 'License: $value';
  }

  @override
  String loading_previous_pages(int count) {
    return 'Loading previous... ($count pages)';
  }

  @override
  String loading_more_pages(int count) {
    return 'Loading more... ($count pages)';
  }

  @override
  String get drag_to_resize => 'Drag to resize';

  @override
  String get day_completion_share_message =>
      'I just completed a day of my practice on WeBuddhist. Join me and build a daily practice habit together.';

  @override
  String group_accumulator_share_message(String accumulation, String group) {
    return 'I am taking part in \"$accumulation\", a group accumulation by $group on WeBuddhist. Come join me!';
  }

  @override
  String group_accumulator_share_message_no_group(String accumulation) {
    return 'I am taking part in the group accumulation \"$accumulation\" on WeBuddhist. Come join me!';
  }

  @override
  String get group_chat_title => 'Chat';

  @override
  String get chats_title => 'Chats';

  @override
  String get chats_empty_title => 'No chats yet';

  @override
  String get chats_empty_body => 'Join a community to start chatting.';

  @override
  String get group_chat_inappropriate =>
      'This message couldn\'t be sent because it contains language that isn\'t allowed.';

  @override
  String get group_chat_not_a_member => 'Only members can open this chat.';

  @override
  String get group_chat_open => 'Chat';

  @override
  String get group_chat_message_hint => 'Message';

  @override
  String get group_chat_join_to_send => 'Join chat to send message.';

  @override
  String get group_chat_today => 'Today';

  @override
  String get group_chat_yesterday => 'Yesterday';

  @override
  String get group_chat_empty_title => 'No messages yet';

  @override
  String get group_chat_empty_body => 'Start the conversation with your group.';

  @override
  String get group_chat_load_failed => 'Messages couldn\'t be loaded.';

  @override
  String get group_chat_retry => 'Retry';

  @override
  String get group_chat_unknown_sender => 'Member';

  @override
  String get group_chat_reactions_all => 'All';

  @override
  String get group_chat_reacted => 'Reacted';

  @override
  String get group_chat_reply => 'Reply';

  @override
  String get group_chat_copy => 'Copy';

  @override
  String get group_chat_copied => 'Message copied';

  @override
  String get group_chat_report => 'Report';

  @override
  String get group_chat_report_title => 'Why are you reporting this?';

  @override
  String get group_chat_report_privacy => 'Your name stays private.';

  @override
  String get group_chat_report_reason_harassment => 'Harassment or bullying';

  @override
  String get group_chat_report_reason_hate => 'Hateful or harmful speech';

  @override
  String get group_chat_report_reason_sexual => 'Sexual or explicit content';

  @override
  String get group_chat_report_reason_spam => 'Spam or scams';

  @override
  String get group_chat_report_reason_off_topic => 'Off-topic or disruptive';

  @override
  String get group_chat_report_reason_other => 'Something else';

  @override
  String get group_chat_report_note_title => 'Add a note';

  @override
  String get group_chat_report_note_hint => 'Something else...';

  @override
  String get group_chat_report_submit => 'Submit report';

  @override
  String get group_chat_report_thanks => 'Thank you for the feedback';

  @override
  String get group_chat_report_offline => 'You\'re offline — try again later';

  @override
  String get group_chat_report_failed => 'Couldn\'t send report';

  @override
  String get group_chat_report_retry => 'Retry';

  @override
  String get group_chat_delete => 'Delete';

  @override
  String get group_chat_delete_title => 'Delete message?';

  @override
  String get group_chat_delete_confirm_body =>
      'This message will be deleted for everyone in this chat.';

  @override
  String get group_chat_delete_for_everyone => 'Delete for everyone';

  @override
  String get group_chat_delete_failed => 'The message couldn\'t be deleted.';

  @override
  String get group_chat_message_deleted => 'You deleted this message';

  @override
  String get group_chat_message_deleted_by_sender => 'This message was deleted';

  @override
  String get group_chat_reaction_failed => 'Your reaction couldn\'t be saved.';

  @override
  String group_chat_reactions_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reactions',
      one: '1 reaction',
    );
    return '$_temp0';
  }

  @override
  String get group_chat_you => 'You';

  @override
  String get group_chat_tap_to_remove => 'Tap to remove';

  @override
  String get group_chat_reply_parent_gone =>
      'That message is no longer available, so the quote was removed. Send again to post your message.';

  @override
  String get group_tab_posts => 'Posts';

  @override
  String get group_tab_events => 'Events';

  @override
  String get group_posts_empty_title => 'No posts yet';

  @override
  String get group_posts_empty_message =>
      'Share your first update with your community.';

  @override
  String get group_posts_load_error =>
      'Unable to load posts. Please try again.';

  @override
  String get group_post_button => 'Post';

  @override
  String get group_post_new_title => 'New post';

  @override
  String get group_post_posting_to => 'Posting to:';

  @override
  String get group_post_caption_hint => 'What\'s new?';

  @override
  String get group_post_photos => 'Photos';

  @override
  String get group_post_link => 'Link';

  @override
  String get group_post_discard_title => 'Discard post?';

  @override
  String get group_post_discard_message => 'You\'ll lose what you\'ve written.';

  @override
  String get group_post_keep_editing => 'Keep editing';

  @override
  String get group_post_discard => 'Discard';

  @override
  String get group_post_add_link_title => 'Add link';

  @override
  String get group_post_add_link_hint =>
      'Paste a link and we\'ll show a preview.';

  @override
  String get group_post_link_field_hint => 'Link';

  @override
  String get group_post_attach => 'Attach';

  @override
  String get group_post_attach_as_link => 'Attach as link';

  @override
  String get group_post_preview_failed_title => 'Couldn\'t load a preview';

  @override
  String get group_post_preview_failed_message =>
      'You can still attach it as a link.';

  @override
  String get group_post_invalid_link =>
      'Enter a valid link, for example https://example.com';

  @override
  String group_post_photo_limit(int count) {
    return 'You can add up to $count photos.';
  }

  @override
  String get group_post_upload_error =>
      'Unable to upload photos. Please try again.';

  @override
  String get group_post_publish_error =>
      'Unable to publish your post. Please try again.';

  @override
  String get group_post_published => 'Your post is live.';

  @override
  String get group_post_delete_title => 'Delete post?';

  @override
  String get group_post_delete_message =>
      'This post will be permanently removed.';

  @override
  String get group_post_delete_failed =>
      'Unable to delete the post. Please try again.';

  @override
  String get edit => 'Edit';

  @override
  String get group_post_edit_title => 'Edit post';

  @override
  String get group_post_update_error =>
      'Unable to save your changes. Please try again.';

  @override
  String get group_post_updated => 'Your changes are saved.';

  @override
  String get practice_collection_already_added =>
      'This collection is already in your practices';

  @override
  String get practice_group_accumulator_already_added =>
      'This accumulation is already in your practices';

  @override
  String get event_live_badge => 'LIVE';

  @override
  String get event_live_audio => 'Live audio';

  @override
  String get event_live_video_mode => 'Video';

  @override
  String get event_live_audio_mode => 'Audio';

  @override
  String get event_live_go_live => 'Live';
}

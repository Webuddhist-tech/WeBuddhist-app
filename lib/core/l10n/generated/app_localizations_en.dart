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
  String get onboarding_tagline => 'Learn, practice, and connect. Daily.';

  @override
  String get onboarding_find_peace => 'Get started';

  @override
  String get onboarding_continue => 'Continue';

  @override
  String get onboarding_first_question => 'Choose your language';

  @override
  String get onboarding_language_subtitle =>
      'This sets the language of the app';

  @override
  String get onboarding_all_set => 'You\'re all set';

  @override
  String get onboarding_all_set_description =>
      'Here\'s what\'s waiting for you:';

  @override
  String get onboarding_all_set_practice_title => 'Practice';

  @override
  String get onboarding_all_set_practice_body =>
      'Plans, chants, malas and meditation';

  @override
  String get onboarding_all_set_connect_title => 'Connect';

  @override
  String get onboarding_all_set_connect_body =>
      'Spaces, events, newsfeed and chat';

  @override
  String get home_today => 'Today';

  @override
  String get home_overall_stats => 'Overall stats';

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
  String get bookmark_group_accumulation => 'Space accumulations';

  @override
  String get mala_add_to_practice => 'Add to my practices';

  @override
  String get mala_add_mala_round => 'Add mala round';

  @override
  String get mala_add_rounds_title => 'Add mala rounds:';

  @override
  String get mala_add_rounds_message =>
      'Add the mala rounds you did outside the app';

  @override
  String mala_rounds_unit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'rounds',
      one: 'round',
    );
    return '$_temp0';
  }

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
      'Your current count will go back to zero, but your accumulations will stay in your lifetime total';

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
  String get mala_hand_layout_tooltip => 'Switch hand layout';

  @override
  String get mala_settings_section => 'Mala settings';

  @override
  String get mala_others_section => 'Others';

  @override
  String get mala_mantra_speed => 'Mantra speed';

  @override
  String get mala_speed_normal => 'Normal';

  @override
  String get mala_show_full_mantra => 'Show full mantra';

  @override
  String mala_counter_semantics(int bead, int total, String rounds) {
    return 'Count $bead of $total, $rounds';
  }

  @override
  String get mala_group_accumulations => 'Add recitation to';

  @override
  String get mala_groups_section => 'Events';

  @override
  String get mala_group_untitled => 'Untitled space';

  @override
  String get mala_all_time_accumulation => 'My all-time accumulation';

  @override
  String get mala_personal_practice => 'Personal practice';

  @override
  String get mala_events_section => 'Events';

  @override
  String mala_my_total(String count) {
    return 'My total: $count';
  }

  @override
  String mala_group_total(String count) {
    return 'Group total: $count';
  }

  @override
  String get home_timer => 'Timer';

  @override
  String get preset_timers => 'Preset timers';

  @override
  String get meditation_timer => 'Meditation timer';

  @override
  String get timer_min => 'min';

  @override
  String get timer_finish => 'Finish';

  @override
  String get timer_discard_session => 'Discard session';

  @override
  String get home_hello_prefix => 'Hello, ';

  @override
  String home_share_prompt(String appName) {
    return 'Enjoying $appName?';
  }

  @override
  String get home_share_support => 'Your support helps our community grow';

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
  String get text_commentary => 'Commentaries';

  @override
  String get resources => 'Resources';

  @override
  String get no_translation => 'No translations found';

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
  String commentary_not_available_for_language(String language) {
    return '$language commentary not available';
  }

  @override
  String get loading => 'Loading...';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

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
  String get recitations_search => 'Search for recitations...';

  @override
  String get recitations_search_for => 'Search for recitations';

  @override
  String get recitations_no_found => 'No recitations founds';

  @override
  String get recitations_no_content => 'No recitations available';

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
      'This collection will be permanently removed';

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
      'No chant collections bookmarked yet';

  @override
  String get bookmarks_empty_chant_collections_subtitle =>
      'Bookmark one to save it here';

  @override
  String get notification_allow_title => 'Allow notifications';

  @override
  String get notification_allow_subtitle_disabled =>
      'Permission needed. Tap to grant in Settings';

  @override
  String get notification_snack_permission_denied =>
      'Notifications are blocked. Turn them on in Settings';

  @override
  String get notification_snack_disable_alarms_in_settings =>
      'Turn off alarms & reminders in Settings';

  @override
  String get notification_allow_subtitle_on =>
      'Reminders and updates from WeBuddhist';

  @override
  String get notification_allow_subtitle_off =>
      'Off. Turn on to get reminders and updates.';

  @override
  String get notification_section_practice => 'Practice';

  @override
  String get notification_section_connect => 'Connect';

  @override
  String get notification_row_plans => 'Plans';

  @override
  String get notification_row_chants => 'Chants';

  @override
  String get notification_row_mala => 'Mala & accumulations';

  @override
  String get notification_row_timer => 'Timer';

  @override
  String get notification_row_group_posts => 'Group posts';

  @override
  String get notification_row_group_chats => 'Group chats';

  @override
  String get notification_row_my_prayer_requests => 'My prayer requests';

  @override
  String get notification_row_others_prayer_requests =>
      'Other people\'s prayer requests';

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
      'Continue your practice on any device, wherever you go';

  @override
  String get routine_delete_block_message =>
      'The time block and all its items will be removed';

  @override
  String get something_went_wrong => 'Something went wrong. Please try again';

  @override
  String get onboarding_tradition_title =>
      'How do you follow the Buddha’s teachings?';

  @override
  String get onboarding_tradition_subtitle =>
      'Choose one or more traditions for your content. You can change this anytime in Settings.';

  @override
  String get onboarding_tradition_show_all_title => 'Show me everything';

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
  String get connect_subtitle => 'Find spaces and practice together';

  @override
  String get discover_groups => 'Discover spaces';

  @override
  String get my_groups => 'My spaces';

  @override
  String get see_all => 'See all';

  @override
  String get connect_groups_load_error =>
      'Unable to load spaces.\nCheck your connection and try again';

  @override
  String get connect_groups_empty_title => 'No more spaces';

  @override
  String get connect_tab_feed => 'Feed';

  @override
  String get connect_tab_events => 'Events';

  @override
  String get connect_tab_practices => 'Practices';

  @override
  String get connect_tab_groups => 'Spaces';

  @override
  String get connect_segment_my => 'Your spaces';

  @override
  String get connect_segment_discover => 'Discover';

  @override
  String get connect_empty_discover_events => 'No events to discover';

  @override
  String get connect_empty_discover_feed => 'Nothing to discover';

  @override
  String get connect_empty_discover_groups => 'No spaces to discover';

  @override
  String get connect_all_groups => 'All spaces';

  @override
  String get connect_my_empty_feed_title => 'No new updates';

  @override
  String get connect_my_empty_events_title => 'No upcoming events';

  @override
  String get connect_my_empty_groups_title => 'No spaces yet';

  @override
  String get connect_my_empty_feed_subtitle =>
      'Your spaces haven\'t shared anything new';

  @override
  String get connect_my_empty_events_subtitle =>
      'Your spaces haven\'t scheduled any events';

  @override
  String get connect_my_empty_groups_subtitle =>
      'You haven\'t joined any spaces yet. Discover some to practice with';

  @override
  String get connect_my_empty_feed_browse =>
      'See what other spaces are sharing';

  @override
  String get connect_my_empty_events_browse => 'Browse open events';

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
      'This comment will be permanently removed';

  @override
  String get connect_comment_delete_failed => 'Unable to delete comment';

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
      'No comments yet. Start the conversation';

  @override
  String get connect_online => 'Online';

  @override
  String get connect_ended => 'Ended';

  @override
  String connect_ended_on(String date) {
    return 'Ended $date';
  }

  @override
  String get home_group_events => 'Featured events';

  @override
  String get home_poems => 'Poems';

  @override
  String get poems_load_error =>
      'Unable to load poems.\nCheck your connection and try again';

  @override
  String get poems_empty => 'No poems yet. Check back soon';

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
  String get connect_event_fallback_title => 'Event';

  @override
  String get connect_group_fallback_title => 'Space';

  @override
  String get connect_event_participation_prompt => 'How are you attending?';

  @override
  String get connect_event_practice_in_person => 'Practice in-person';

  @override
  String get connect_event_practice_online => 'Practice online';

  @override
  String get connect_event_view_in_person => 'In-person view';

  @override
  String get connect_event_view_online => 'Online view';

  @override
  String get connect_event_accumulation_online => 'Online';

  @override
  String get connect_event_accumulation_in_person => 'In-person';

  @override
  String get connect_event_has_ended => 'This event has ended';

  @override
  String get connect_event_join_to_practice => 'Join the event to practice';

  @override
  String get connect_event_leave => 'Leave event';

  @override
  String get connect_event_leave_confirm_title => 'Leave this event?';

  @override
  String connect_event_leave_confirm_message(String title) {
    return 'You\'ll no longer be attending $title. You can still view the event and attend again anytime.';
  }

  @override
  String connect_event_participants_attending(int count) {
    return '$count participants';
  }

  @override
  String connect_event_participants_attended(int count) {
    return '$count attended';
  }

  @override
  String get connect_event_participants_empty => 'No participants yet';

  @override
  String get connect_event_organizer => 'Organizer';

  @override
  String get connect_event_tab_videos => 'Videos';

  @override
  String get connect_event_tab_about => 'About';

  @override
  String get connect_event_links_title => 'More event details';

  @override
  String get connect_event_date_tba => 'Date to be announced';

  @override
  String get connect_event_when => 'When';

  @override
  String get connect_event_where => 'Where';

  @override
  String get connect_event_tab_accumulations => 'Accumulations';

  @override
  String get connect_event_add_recitations => 'Add recitations';

  @override
  String get connect_event_add_recitations_message =>
      'Add recitations you did with the livestream or outside this app';

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
  String get search_groups => 'Search spaces';

  @override
  String get search_for_groups => 'Search for spaces';

  @override
  String get no_groups_found => 'No matching spaces found';

  @override
  String get explore_coming_soon_subtitle =>
      'A curated space to discover practices, teachings, and community events';

  @override
  String get learn_coming_soon_subtitle =>
      'Your personal study plans, designed to fit into everyday life';

  @override
  String get creator_featured_plan => 'Featured plans';

  @override
  String get home_no_series_found => 'No series found';

  @override
  String get home_no_tags_found => 'No tags found';

  @override
  String get home_celebrated_by => 'Celebrated by: ';

  @override
  String get reader_font_size_tooltip => 'Font size';

  @override
  String get reader_versions_load_error => 'Unable to load versions';

  @override
  String get reader_languages_load_error => 'Unable to load languages';

  @override
  String reader_no_versions_in_language(String language) {
    return 'No versions available in $language';
  }

  @override
  String get reader_no_languages => 'No languages available for this text';

  @override
  String get reader_license => 'License';

  @override
  String get text_search_hint => 'Type to search';

  @override
  String get text_search_press_button => 'Press search button to search';

  @override
  String get text_search_error => 'Unable to perform search.\nPlease try again';

  @override
  String get create_image_share_error => 'Unable to share. Please try again';

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
  String get collection_audio_versions => 'Audio versions';

  @override
  String get author => 'Author';

  @override
  String get plans_created => 'Plans created';

  @override
  String get ai_confirm => 'Confirm';

  @override
  String search_no_results(String query) {
    return 'No results found for \"$query\"';
  }

  @override
  String get search_all => 'All';

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
  String get routine_edit_title => 'Edit your routine';

  @override
  String get routine_delete_block => 'Remove block';

  @override
  String get routine_session_title_hint => 'Title...';

  @override
  String get routine_expand_all => 'Expand all';

  @override
  String get routine_collapse_all => 'Collapse all';

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
  String get routine_empty_block_delete_singular => 'Remove block';

  @override
  String get routine_empty_block_delete_plural => 'Remove blocks';

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
  String get exploreAsGuest => 'Explore as a guest';

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
      'This is no longer available. Edit your routine to update';

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
  String get root_text => 'Root text';

  @override
  String get version => 'Versions';

  @override
  String get reader_languages_title => 'Languages';

  @override
  String get reader_sections_title => 'Sections';

  @override
  String get reader_original_label => 'Original';

  @override
  String get reader_translation_label => 'Translation';

  @override
  String get version_not_available => 'Not available';

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
  String get edit_profile_display_name => 'Display name';

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
  String get me_minutes => 'minutes';

  @override
  String get me_hours => 'hours';

  @override
  String get me_total_meditation_time => 'Total meditation time';

  @override
  String get me_days_plan_practiced_suffix => 'total plan days completed';

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
      'If you delete your account, all your information, history, and personalized settings on WeBuddhist will be permanently deleted. Note that this action is irreversible. To proceed, tap the button below.';

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
  String get calendar_title => 'Calendar';

  @override
  String get calendar_upcoming_events => 'Upcoming events';

  @override
  String get calendar_day_short => 'DAY';

  @override
  String get calendar_day_label => 'Day';

  @override
  String calendar_lunar_month(String ordinal) {
    return '$ordinal lunar month';
  }

  @override
  String get moon_phase_new_moon => 'New moon';

  @override
  String get moon_phase_first_quarter => 'First quarter';

  @override
  String get moon_phase_full_moon => 'Full moon';

  @override
  String get join => 'Join';

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
    return 'Members ($count)';
  }

  @override
  String group_followers_heading(int count) {
    return 'Followers($count)';
  }

  @override
  String get group_invite => 'Invite';

  @override
  String get group_notifications_title => 'Notifications';

  @override
  String get group_notifications_chat => 'Space chat';

  @override
  String get group_notifications_content => 'Space content';

  @override
  String get group_notifications_master_off =>
      'Notifications are turned off for the app';

  @override
  String get group_notifications_open_settings => 'Turn on';

  @override
  String get group_notifications_update_failed =>
      'Couldn\'t update notification settings. Try again';

  @override
  String get group_notifications_load_failed =>
      'Couldn\'t load notification settings';

  @override
  String get group_chat_mute_notifications => 'Mute chat notifications';

  @override
  String get group_chat_unmute_notifications => 'Unmute chat notifications';

  @override
  String get group_chat_notifications_muted => 'Chat notifications muted';

  @override
  String get group_chat_notifications_unmuted => 'Chat notifications on';

  @override
  String get group_leave_confirm_message =>
      'You\'ll stop getting messages and updates from this space';

  @override
  String get group_leave_space => 'Leave space';

  @override
  String get group_leave_space_confirm_title => 'Leave this space?';

  @override
  String get group_leave_space_failed => 'Couldn\'t leave the space. Try again';

  @override
  String get group_request_to_join => 'Ask to join';

  @override
  String get group_request => 'Ask to join';

  @override
  String get group_request_sent => 'Request sent';

  @override
  String get group_join_request_title => 'Ask to join';

  @override
  String get group_join_request_message_label => 'Message (optional)';

  @override
  String get group_join_request_message_hint =>
      'How do you practice, or who invited you?';

  @override
  String get group_join_request_send => 'Send request';

  @override
  String get group_join_request_sent_snackbar =>
      'Request sent. An admin will review it';

  @override
  String get group_join_request_error =>
      'Unable to send request. Please try again';

  @override
  String get group_join_requests_title => 'Join requests';

  @override
  String get group_join_requests_admit => 'Admit';

  @override
  String get group_join_requests_deny => 'Deny';

  @override
  String get group_join_requests_empty => 'No pending requests';

  @override
  String get group_join_requests_load_error =>
      'Unable to load join requests. Please try again';

  @override
  String get group_join_requests_admit_error =>
      'Unable to admit this request. Please try again';

  @override
  String get group_join_requests_deny_error =>
      'Unable to deny this request. Please try again';

  @override
  String get group_reports_title => 'Reports';

  @override
  String get group_reports_section_posts => 'Posts';

  @override
  String get group_reports_section_comments => 'Comments';

  @override
  String get group_reports_section_messages => 'Messages';

  @override
  String group_reports_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports',
      one: '1 report',
    );
    return '$_temp0';
  }

  @override
  String get group_reports_view_post => 'View post';

  @override
  String get group_reports_view_message => 'View message';

  @override
  String get group_reports_delete_post => 'Delete post';

  @override
  String get group_reports_delete_comment => 'Delete comment';

  @override
  String get group_reports_delete_message => 'Delete message';

  @override
  String get group_reports_empty => 'No reports to review';

  @override
  String get group_reports_load_error =>
      'Unable to load reports. Please try again';

  @override
  String get group_reports_delete_confirm_title => 'Are you sure?';

  @override
  String get group_reports_delete_message_confirm =>
      'This message will be permanently removed';

  @override
  String get group_reports_message_removed => 'Message has been removed';

  @override
  String get group_reports_delete_message_error =>
      'Unable to delete message. Please try again';

  @override
  String get group_members_only_title => 'Members only';

  @override
  String get group_members_only_message => 'Join this space to see its content';

  @override
  String get group_join_request_waiting_title => 'Waiting on an admin';

  @override
  String get group_join_request_waiting_message =>
      'We\'ll notify you when your request is reviewed';

  @override
  String get group_members_load_error =>
      'Unable to load members. Please try again';

  @override
  String get group_followers_load_error =>
      'Unable to load followers. Please try again.';

  @override
  String get group_members_empty => 'No members yet';

  @override
  String get group_member_admin => 'Admin';

  @override
  String get group_member_owner => 'Owner';

  @override
  String group_remove_member(String name) {
    return 'Remove $name';
  }

  @override
  String get group_remove_member_title => 'Remove from space?';

  @override
  String group_remove_member_message(String name) {
    return '$name will be removed from this space and unable to rejoin it until the ban is lifted';
  }

  @override
  String get group_remove_member_blocked_for => 'Blocked for:';

  @override
  String get group_remove_member_duration_day => '1 day';

  @override
  String group_remove_member_duration_days(int count) {
    return '$count days';
  }

  @override
  String get group_remove_member_duration_year => '1 year';

  @override
  String get group_remove_member_reason_label => 'Reason (optional)';

  @override
  String get group_remove_member_reason_hint => 'Something else...';

  @override
  String get group_remove_member_action => 'Remove';

  @override
  String group_remove_member_success(String name) {
    return '$name was removed from the space';
  }

  @override
  String get group_remove_member_error =>
      'Couldn\'t remove this member. Try again';

  @override
  String group_join_banned_until(String date) {
    return 'You were removed from this space and can\'t rejoin until $date';
  }

  @override
  String get group_join_banned =>
      'You were removed from this space and can\'t rejoin until the ban is lifted';

  @override
  String get group_removed_title => 'You\'ve been removed from this space';

  @override
  String group_removed_message(String group, String duration) {
    return 'An admin from $group removed you from this space. You won\'t be able to view its posts, events and practices, or ask to rejoin for $duration.';
  }

  @override
  String group_removed_message_no_date(String group) {
    return 'An admin from $group removed you from this space. You won\'t be able to view its posts, events and practices, or ask to rejoin';
  }

  @override
  String get group_removed_rejoin_label =>
      'You can ask to join to this space on';

  @override
  String group_removed_rejoin_value(String date, String remaining) {
    return '$date · $remaining';
  }

  @override
  String get group_removed_day_left => '1 day left';

  @override
  String group_removed_days_left(int count) {
    return '$count days left';
  }

  @override
  String get group_removed_last_day => 'Less than a day left';

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
  String get group_change_practice_title => 'Change practice space';

  @override
  String get group_change_practice_message =>
      'You are already practicing this plan with another space. Would you like to change your practice space?';

  @override
  String get group_join_to_contribute => 'Join to contribute';

  @override
  String get group_accumulator_join_error =>
      'Unable to join accumulation. Please try again';

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
  String get group_accumulator_everyone => 'Everyone';

  @override
  String get group_accumulator_me => 'Me';

  @override
  String get group_accumulator_my_contributions => 'My contributions';

  @override
  String get group_accumulator_recited => 'Recitations';

  @override
  String get group_accumulator_total => 'Total';

  @override
  String get group_accumulator_contributions_empty =>
      'Join this accumulation to track your contributions';

  @override
  String get group_accumulator_leaderboard_empty => 'No recitations yet';

  @override
  String get group_accumulator_recite_now => 'Recite now';

  @override
  String get group_accumulator_view_practice => 'View practice';

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
      'Add the number of chants you did outside the app';

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
    return 'I completed $count recitations in \"$accumulation\", an accumulation by $group on WeBuddhist. Come join me!';
  }

  @override
  String group_accumulator_session_share_message_no_group(
    int count,
    String accumulation,
  ) {
    return 'I completed $count recitations in the \"$accumulation\" accumulation on WeBuddhist. Come join me!';
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
      'By this merit, may all beings\nbe free from suffering';

  @override
  String get share_this_quote => 'Share this quote';

  @override
  String get shared_from => 'Shared from';

  @override
  String get verse_share_error => 'Unable to share quote. Please try again';

  @override
  String verse_comments_title(int count) {
    return 'Comments · $count';
  }

  @override
  String verse_likes_title(int count) {
    return 'Likes · $count';
  }

  @override
  String get verse_like_failed => 'Unable to update like. Please try again';

  @override
  String get verse_comment_failed => 'Unable to post comment. Please try again';

  @override
  String verse_comment_replying_to(String name) {
    return 'Replying to $name';
  }

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
      'I liked this quote from WeBuddhist and wanted to share it with you. Read more such insightful quotes on the WeBuddhist app.';

  @override
  String get share_poem_message =>
      'I liked this poem from WeBuddhist and wanted to share it with you.';

  @override
  String share_poem_title(String title) {
    return '“$title”';
  }

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
      'Join me in this space. Let\'s practice together on WeBuddhist!';

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
  String get mala_no_mantras => 'No mantras available';

  @override
  String get mala_count_load_error => 'Could not load your count';

  @override
  String get bookmarks_empty_all_title => 'Nothing bookmarked yet';

  @override
  String get bookmarks_empty_all_subtitle =>
      'Bookmark anything to save it here';

  @override
  String get bookmarks_empty_plans_title => 'No plans bookmarked yet';

  @override
  String get bookmarks_empty_plans_subtitle => 'Bookmark one to save it here';

  @override
  String get bookmarks_empty_malas_title => 'No malas bookmarked yet';

  @override
  String get bookmarks_empty_malas_subtitle => 'Bookmark one to save it here';

  @override
  String get bookmarks_empty_group_accumulations_title =>
      'No space accumulations bookmarked yet';

  @override
  String get bookmarks_empty_group_accumulations_subtitle =>
      'Bookmark one to save it here';

  @override
  String get bookmarks_empty_timers_title => 'No timers bookmarked yet';

  @override
  String get bookmarks_empty_timers_subtitle => 'Bookmark one to save it here';

  @override
  String get bookmarks_empty_texts_title => 'No texts bookmarked yet';

  @override
  String get bookmarks_empty_texts_subtitle => 'Bookmark one to save it here';

  @override
  String get bookmark_removed => 'Bookmark removed';

  @override
  String get bookmark_remove_failed => 'Unable to remove bookmark';

  @override
  String get bookmark_saved => 'Bookmark saved';

  @override
  String get bookmark_save_failed => 'Unable to save bookmark';

  @override
  String get bookmarks_yesterday => 'Yesterday';

  @override
  String get webview_timeout_error =>
      'Page took too long to load. Please check your internet connection';

  @override
  String get webview_load_failed => 'Unable to load page';

  @override
  String get privacy_policy_load_error =>
      'Unable to load the privacy policy page';

  @override
  String get terms_of_service_load_error =>
      'Unable to load the terms of service page';

  @override
  String get series_enroll_error => 'Unable to enroll in series';

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
  String get player_fullscreen => 'Fullscreen';

  @override
  String get player_exit_fullscreen => 'Exit fullscreen';

  @override
  String get session_plans_load_error =>
      'Unable to load plans.\nPlease try again later';

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
      'Unable to load author details.\nPlease try again';

  @override
  String get link_cannot_open => 'Cannot open this link';

  @override
  String get link_invalid => 'Invalid URL';

  @override
  String get author_no_plans => 'No plans created yet';

  @override
  String get author_plans_load_error => 'Unable to load plans';

  @override
  String get drag_to_resize => 'Drag to resize';

  @override
  String get day_completion_share_message =>
      'I just completed a day of my practice on WeBuddhist. Join me and build a daily practice habit together.';

  @override
  String group_accumulator_share_message(String accumulation, String group) {
    return 'I am taking part in \"$accumulation\", an accumulation by $group on WeBuddhist. Come join me!';
  }

  @override
  String group_accumulator_share_message_no_group(String accumulation) {
    return 'I am taking part in the \"$accumulation\" accumulation on WeBuddhist. Come join me!';
  }

  @override
  String get chats_title => 'Chats';

  @override
  String get chats_empty_title => 'No chats yet';

  @override
  String get chats_empty_body => 'Join a space to start chatting';

  @override
  String get group_chat_inappropriate =>
      'This message couldn\'t be sent because it contains language that isn\'t allowed';

  @override
  String get group_chat_not_a_member => 'Only members can open this chat';

  @override
  String get group_chat_open => 'Chat';

  @override
  String get group_chat_message_hint => 'Message';

  @override
  String get group_chat_today => 'Today';

  @override
  String get group_chat_yesterday => 'Yesterday';

  @override
  String get group_chat_empty_title => 'No messages yet';

  @override
  String get group_chat_empty_body => 'Start the conversation with your space';

  @override
  String get group_chat_load_failed => 'Messages couldn\'t be loaded';

  @override
  String get group_chat_message_not_found =>
      'This message is no longer in the chat';

  @override
  String get group_chat_message_too_far_back =>
      'This message is further back in the chat';

  @override
  String get group_chat_keep_looking => 'Keep looking';

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
  String get group_chat_report_privacy => 'Your name stays private';

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
  String get group_chat_report_offline => 'You\'re offline. Try again later';

  @override
  String get group_chat_report_failed => 'Couldn\'t send report';

  @override
  String get group_chat_report_retry => 'Retry';

  @override
  String get group_chat_delete => 'Delete';

  @override
  String get group_chat_delete_title => 'Delete message?';

  @override
  String group_chat_delete_title_many(int count) {
    return 'Delete $count messages?';
  }

  @override
  String group_chat_delete_confirm_body(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'These messages will be removed from the chat for everyone',
      one: 'This message will be removed from the chat for everyone',
    );
    return '$_temp0';
  }

  @override
  String group_chat_delete_failed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages couldn\'t be deleted',
      one: 'The message couldn\'t be deleted',
    );
    return '$_temp0';
  }

  @override
  String group_chat_selection_limit(int count) {
    return 'You can select up to $count messages';
  }

  @override
  String get group_chat_message_deleted_by_sender => 'This message was deleted';

  @override
  String get group_chat_reaction_failed => 'Your reaction couldn\'t be saved';

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
      'That message is no longer available, so the quote was removed. Send again to post your message';

  @override
  String get group_tab_posts => 'Posts';

  @override
  String get group_tab_events => 'Events';

  @override
  String get group_posts_empty_title => 'No posts yet';

  @override
  String get group_posts_empty_message => 'Share your space\'s first update';

  @override
  String get group_posts_load_error => 'Unable to load posts. Please try again';

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
  String get group_post_discard_message => 'You\'ll lose what you\'ve written';

  @override
  String get group_post_keep_editing => 'Keep editing';

  @override
  String get group_post_discard => 'Discard';

  @override
  String get group_post_add_link_title => 'Add link';

  @override
  String get group_post_add_link_hint =>
      'Paste a link and we\'ll show a preview';

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
      'You can still attach it as a link';

  @override
  String get group_post_invalid_link =>
      'Enter a valid link, for example: https://example.com';

  @override
  String get group_post_in_app_content => 'In-app content';

  @override
  String get group_post_add_in_app_content_title => 'Add in-app content';

  @override
  String get group_post_in_app_content_empty => 'Nothing to add yet';

  @override
  String group_post_photo_limit(int count) {
    return 'You can add up to $count photos';
  }

  @override
  String get group_post_upload_error =>
      'Unable to upload photos. Please try again';

  @override
  String get group_post_publish_error =>
      'Unable to publish your post. Please try again';

  @override
  String get group_post_published => 'Your post is live.';

  @override
  String get group_post_delete_title => 'Delete post?';

  @override
  String get group_post_delete_message =>
      'This post will be permanently removed';

  @override
  String get group_post_delete_failed =>
      'Unable to delete post. Please try again';

  @override
  String get edit => 'Edit';

  @override
  String get group_post_edit_title => 'Edit post';

  @override
  String get group_post_update_error =>
      'Unable to save your changes. Please try again';

  @override
  String get group_post_updated => 'Your changes are saved';

  @override
  String get practice_collection_already_added =>
      'This collection is already in your practices';

  @override
  String get practice_group_accumulator_already_added =>
      'This accumulation is already in your practices';

  @override
  String get event_live_badge => 'LIVE';

  @override
  String get event_live_video_mode => 'Video';

  @override
  String get event_live_audio_mode => 'Audio';

  @override
  String get event_live_go_live => 'Live';

  @override
  String get event_replays => 'Replays';

  @override
  String event_replay_session(String day, String session) {
    return 'Day $day · Session $session';
  }

  @override
  String get event_replay_recording => 'Recording';

  @override
  String get event_replay_back_to_live => 'Back to live';

  @override
  String get event_replays_empty => 'No recordings yet';

  @override
  String get event_puja_starts_in => 'Puja starts in';

  @override
  String get event_puja_not_started => 'Puja not started yet';

  @override
  String get event_prayer_requests => 'Prayer requests';

  @override
  String event_prayer_request_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      one: '1 request',
      other: '$count requests',
    );
    return '$_temp0';
  }

  @override
  String get event_prayer_empty_title => 'No prayer requests yet';

  @override
  String get event_prayer_empty_body =>
      'Your request and your space\'s requests will appear here';

  @override
  String get event_prayer_add => 'Add a prayer request';

  @override
  String get event_prayer_hint => 'Share a prayer request';

  @override
  String event_prayer_hint_intention(String topics) {
    return 'Request a prayer for: $topics';
  }

  @override
  String get event_prayer_load_failed => 'Prayer requests couldn\'t be loaded';

  @override
  String get event_prayer_closed => 'Prayer requests are closed for this event';

  @override
  String get group_prayer_closed => 'Prayer requests are closed for this space';

  @override
  String get group_prayer_delete_body =>
      'It will be removed for everyone in this space.';

  @override
  String get event_prayer_pray => 'Pray';

  @override
  String event_prayer_my_count(int count) {
    return '+$count';
  }

  @override
  String get event_prayer_new_request => 'New prayer request';

  @override
  String get event_prayer_edit_request => 'Edit prayer request';

  @override
  String get event_prayer_delete_title => 'Delete prayer request?';

  @override
  String get event_prayer_delete_body =>
      'It will be removed for everyone in this event.';

  @override
  String get event_prayer_delete_failed =>
      'The prayer request couldn\'t be deleted';

  @override
  String get event_prayer_choose_intention => 'Choose an intention';

  @override
  String get event_prayer_intentions_failed => 'Intentions couldn\'t be loaded';

  @override
  String get event_prayer_request_button => 'Request prayer';

  @override
  String get event_prayer_you => 'You';

  @override
  String get event_prayer_waiting_first => 'Waiting for the first prayer...';

  @override
  String event_prayer_more_praying(int count) {
    return '+$count more prayed';
  }

  @override
  String event_prayer_people_praying(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people prayed',
      one: '$count person prayed',
    );
    return '$_temp0';
  }

  @override
  String get event_prayer_praying_for_you => 'Prayed for you';

  @override
  String get event_prayer_your_request => 'Your request';

  @override
  String get event_prayer_supporters_failed => 'Couldn\'t load who is praying.';

  @override
  String get event_prayer_no_supporters => 'No one is praying yet';

  @override
  String get event_prayer_sort_by => 'Pray for';

  @override
  String get event_prayer_sort_needs_prayers => 'Needs prayers';

  @override
  String get event_prayer_sort_most_prayed => 'Most prayed';

  @override
  String get event_prayer_sort_newest => 'Newest';

  @override
  String get event_prayer_sort_oldest => 'Oldest';

  @override
  String get event_prayer_sort_by_intention => 'By intention';

  @override
  String get event_prayer_clear_intention => 'Clear intention';

  @override
  String get event_prayer_filter_empty_title => 'No requests match';

  @override
  String get event_prayer_filter_empty_body => 'Try another sort or intention';

  @override
  String get event_prayer_see_translation => 'See translation';

  @override
  String get event_prayer_see_original => 'See original';

  @override
  String event_prayer_translated_from(String language) {
    return 'Translated from $language';
  }

  @override
  String get event_prayer_translated => 'Translated';

  @override
  String get event_prayer_sort_mine => 'My prayers';

  @override
  String get event_prayer_section_active => 'Active';

  @override
  String get event_prayer_section_accomplished => 'Accomplished';

  @override
  String get event_prayer_mark_accomplished => 'Accomplished';

  @override
  String get event_prayer_mark_active => 'Mark as active';

  @override
  String get event_prayer_mine_empty_title => 'No prayer requests from you yet';

  @override
  String get event_prayer_mine_empty_body =>
      'Requests you post here will appear in this list';

  @override
  String get event_prayer_update_failed =>
      'The prayer request couldn\'t be updated';

  @override
  String get event_prayer_find => 'Find a prayer for you';

  @override
  String get event_prayer_random => 'Random';

  @override
  String get event_prayer_finding => 'Finding a prayer...';

  @override
  String get event_prayer_found => 'A prayer for you';

  @override
  String get event_prayer_skip => 'Skip';

  @override
  String get event_prayer_next => 'Next prayer';

  @override
  String get event_prayer_be_first => 'Be the first to pray';

  @override
  String get event_prayer_random_empty_title => 'No prayers to find yet';

  @override
  String get event_prayer_random_empty_body =>
      'No one else has posted a request here yet';

  @override
  String get event_prayer_random_failed => 'Couldn\'t find a prayer';

  @override
  String event_prayer_people_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String event_prayer_prayers_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prayers',
      one: '1 prayer',
    );
    return '$_temp0';
  }

  @override
  String get me_prayer_requests => 'My prayer requests';

  @override
  String get me_prayer_requests_empty_title => 'No prayer requests yet';

  @override
  String get me_prayer_requests_empty_body =>
      'Requests you post in spaces and events will appear here';

  @override
  String get me_prayer_delete_body =>
      'It will be removed for everyone in that space or event.';

  @override
  String get recitation_live_sync => 'Sync';

  @override
  String get recitation_live_label => 'Live';

  @override
  String get recitation_live_session_ended => 'The live session has ended';

  @override
  String get feedback_add_image => 'Add image';

  @override
  String feedback_image_limit(int count) {
    return 'You can attach up to $count images';
  }

  @override
  String get feedback_send => 'Send';

  @override
  String get feedback_error_offline =>
      'You\'re offline. Please try again later';

  @override
  String get feedback_error_rate_limited =>
      'Too many requests. Wait a moment and try again';

  @override
  String get feedback_error_too_large =>
      'Images are too large. Remove one and try again';

  @override
  String get feedback_error_failed =>
      'Couldn\'t send feedback. Please try again';

  @override
  String get feedback_error_unavailable =>
      'Feedback is not available right now';

  @override
  String get settings_help_contact_row => 'Help & contact';

  @override
  String get help_contact_title => 'Help & contact';

  @override
  String get help_contact_intro =>
      'Report a problem, share an idea, or offer to help or collaborate. We read every message.';

  @override
  String get help_contact_message => 'Message';

  @override
  String get help_contact_photos => 'Photos or screenshots (optional)';

  @override
  String get help_contact_topic => 'What\'s this about? (optional)';

  @override
  String get help_contact_hint_default => 'What would you like to tell us?';

  @override
  String get help_contact_hint_report_problem =>
      'What happened, and what were you doing just before? A screenshot helps.';

  @override
  String get help_contact_hint_idea_feedback =>
      'What would make WeBuddhist more helpful for your practice?';

  @override
  String get help_contact_hint_suggest_content =>
      'Which teaching, text, or teacher would you like to see here? Links are welcome.';

  @override
  String get help_contact_hint_help_collaborate =>
      'How would you like to help? Share your skills, languages, or the time you can offer.';

  @override
  String get help_topic_report_problem => 'Report a problem';

  @override
  String get help_topic_idea_feedback => 'Idea or feedback';

  @override
  String get help_topic_suggest_content => 'Suggest content';

  @override
  String get help_topic_help_collaborate => 'Help or collaborate';

  @override
  String get help_contact_footer =>
      'Replies come from the WeBuddhist Team in your Chats.';

  @override
  String get help_contact_sent_title => 'Message sent';

  @override
  String get help_contact_sent_body =>
      'Thanks. We usually reply within 1 day. You\'ll find the reply in your Chats, from the WeBuddhist Team.';

  @override
  String help_contact_sent_body_named(String name) {
    return 'Thanks, $name. We usually reply within 1 day. You\'ll find the reply in your Chats, from the WeBuddhist Team.';
  }

  @override
  String get help_contact_your_request => 'YOUR REQUEST';

  @override
  String get help_contact_open_chat => 'Open chat';

  @override
  String get help_context_sent_from => 'Sent from Help & contact';

  @override
  String help_context_photos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get chat_official_badge => 'Official';

  @override
  String get chat_team_reply_time => 'Usually replies within 1 day';

  @override
  String get connect_failed_load_discover_groups_error =>
      'Unable to load spaces';

  @override
  String get connect_failed_like_post_error => 'Unable to like post';

  @override
  String get connect_failed_unlike_post_error => 'Unable to unlike post';

  @override
  String get group_events_load_error =>
      'Unable to load events. Please try again.';

  @override
  String get group_events_empty => 'No events yet';

  @override
  String get group_events_empty_message =>
      'Create your first gathering — members will be notified.';

  @override
  String get group_event_create_button => 'Create event';

  @override
  String get group_event_new_title => 'New event';

  @override
  String group_event_step_of(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get group_event_step_about => 'About';

  @override
  String get group_event_cover_image => 'Cover image';

  @override
  String get group_event_add_cover_photo => 'Add cover photo';

  @override
  String get group_event_change_cover => 'Change';

  @override
  String get group_event_name_and_description => 'Name & description';

  @override
  String get group_event_name_label => 'Event name';

  @override
  String get group_event_name_hint => 'e.g. Wednesday group practice';

  @override
  String get group_event_description_label => 'Description (optional)';

  @override
  String get group_event_description_hint =>
      'What will you practise together? Anything to bring?';

  @override
  String get group_event_write => 'Write';

  @override
  String get group_event_preview => 'Preview';

  @override
  String get group_event_preview_empty => 'Nothing to preview yet';

  @override
  String get group_event_continue => 'Continue';

  @override
  String get group_event_name_required_hint => 'Add an event name to continue';

  @override
  String get group_event_languages_title => 'Event languages';

  @override
  String get group_event_languages_add => 'Add language';

  @override
  String get group_event_languages_hint =>
      'Preselected from your space\'s languages. Readers see the event in their language when it\'s available.';

  @override
  String get group_event_discard_title => 'Discard event?';

  @override
  String get group_event_discard_message => 'You\'ll lose what you\'ve entered';

  @override
  String get group_event_format_bold => 'Bold';

  @override
  String get group_event_format_italic => 'Italic';

  @override
  String get group_event_format_heading => 'Heading';

  @override
  String get group_event_format_bullet_list => 'Bullet list';

  @override
  String get group_event_format_numbered_list => 'Numbered list';

  @override
  String get group_event_format_link => 'Link';

  @override
  String get group_event_link_title => 'Insert link';

  @override
  String get group_event_link_text_hint => 'Text';

  @override
  String get group_event_link_url_hint => 'https://';

  @override
  String get group_event_link_insert => 'Insert';

  @override
  String get group_event_step_when_where => 'When & where';

  @override
  String get group_event_when => 'When';

  @override
  String get group_event_where => 'Where';

  @override
  String get group_event_one_time => 'One-time';

  @override
  String get group_event_recurring => 'Recurring';

  @override
  String get group_event_date => 'Date';

  @override
  String get group_event_start_date => 'Start date';

  @override
  String get group_event_end_date => 'End date';

  @override
  String get group_event_first_date => 'First date';

  @override
  String get group_event_choose_date => 'Choose a date';

  @override
  String get group_event_multi_day => 'Multi-day event';

  @override
  String get group_event_all_day => 'All day';

  @override
  String get group_event_all_day_hint => 'Shown as all day on the event page.';

  @override
  String get group_event_start_time => 'Start time';

  @override
  String get group_event_end_time => 'End time';

  @override
  String get group_event_add_start_time => 'Add start time';

  @override
  String get group_event_add_end_time => 'Add end time';

  @override
  String group_event_time_starts(String time) {
    return 'starts $time';
  }

  @override
  String group_event_time_ends(String time) {
    return 'ends $time';
  }

  @override
  String get group_event_timezone => 'Timezone';

  @override
  String get group_event_repeats => 'Repeats';

  @override
  String get group_event_choose_repeats => 'Choose how it repeats';

  @override
  String get group_event_duration => 'Duration';

  @override
  String get group_event_duration_decrease => 'Decrease duration';

  @override
  String get group_event_duration_increase => 'Increase duration';

  @override
  String group_event_duration_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String group_event_repeats_weekly(String weekday) {
    return 'Weekly on $weekday';
  }

  @override
  String group_event_repeats_monthly(String day) {
    return 'Monthly on the $day';
  }

  @override
  String group_event_repeats_monthly_lunar(String day) {
    return 'Monthly on the $day lunar day';
  }

  @override
  String group_event_repeats_yearly(String date) {
    return 'Yearly on $date';
  }

  @override
  String get group_event_repeats_yearly_lunar => 'Yearly on this lunar date';

  @override
  String get group_event_full_moon => 'Full moon';

  @override
  String get group_event_new_moon => 'New moon';

  @override
  String get group_event_gregorian => 'Gregorian';

  @override
  String get group_event_tibetan_lunar => 'Tibetan Lunar';

  @override
  String get group_event_next_dates => 'Next dates';

  @override
  String get group_event_repeats_hint => 'Options are based on the first date.';

  @override
  String get group_event_in_person => 'In person';

  @override
  String get group_event_live => 'Live';

  @override
  String get group_event_both => 'Both';

  @override
  String get group_event_venue => 'Venue';

  @override
  String get group_event_add_venue => 'Add venue location';

  @override
  String get group_event_venue_search_hint => 'Search area, street or landmark';

  @override
  String get group_event_venue_no_results => 'No places found';

  @override
  String get group_event_venue_search_error =>
      'Search isn\'t available right now';

  @override
  String get group_event_drop_pin => 'Drop a pin';

  @override
  String get group_event_drop_pin_hint => 'Choose the spot on a map';

  @override
  String get group_event_pin_marker => 'Event venue';

  @override
  String get group_event_selected_location => 'Selected location';

  @override
  String get group_event_pin_unnamed => 'Pinned location';

  @override
  String get group_event_confirm_location => 'Confirm location';

  @override
  String get group_event_name_location => 'Name the location';

  @override
  String get group_event_venue_name => 'Venue name';

  @override
  String get group_event_venue_name_hint => 'e.g. Vajrasattva Dharma Center';

  @override
  String get group_event_save_venue => 'Save venue';

  @override
  String get group_event_live_link => 'Live link';

  @override
  String get group_event_live_link_hint => 'youtube.com/… or a meeting link';

  @override
  String get group_event_use_channel_link => 'Use channel link';

  @override
  String get group_event_live_link_youtube_help =>
      'Your space\'s YouTube live. It plays inside WeBuddhist. Paste a different link to change it.';

  @override
  String get group_event_live_link_custom_help =>
      'Custom link. Viewers open it outside WeBuddhist.';

  @override
  String get group_event_live_link_invalid =>
      'That doesn\'t look like a link yet';

  @override
  String get group_event_pick_date_hint => 'Pick a date to continue';

  @override
  String get group_event_pick_repeats_hint =>
      'Choose how it repeats to continue';

  @override
  String get group_event_end_date_hint =>
      'End date must be after the start date';

  @override
  String get group_event_end_time_hint =>
      'End time must be after the start time';

  @override
  String get group_event_venue_hint => 'Choose a venue to continue';

  @override
  String get group_event_link_required_hint => 'Add a meeting link to continue';

  @override
  String get group_event_map_attribution => '© OpenStreetMap contributors';

  @override
  String get group_event_step_practices => 'Practices & videos';

  @override
  String get group_event_optional_note =>
      'Everything here is optional. You can add these details later.';

  @override
  String get group_event_practices_section => 'Event practices';

  @override
  String get group_event_add_practice => 'Add practice';

  @override
  String get group_event_practice_search_hint =>
      'Search your space\'s practices';

  @override
  String get group_event_practice_filter_all => 'All';

  @override
  String get group_event_practice_filter_content => 'Plans & series';

  @override
  String get group_event_practice_filter_collections => 'Chant collections';

  @override
  String get group_event_practice_filter_accumulators => 'Accumulations';

  @override
  String get group_event_practice_rule =>
      'One plan or series and one chant collection per event. Add as many accumulations as you need.';

  @override
  String group_event_practice_replaced(String chosen, String previous) {
    return 'Choosing $chosen replaced $previous.';
  }

  @override
  String get group_event_practices_empty => 'No practices in this space yet';

  @override
  String get group_event_practices_load_error =>
      'Unable to load practices. Please try again.';

  @override
  String get group_event_practices_none_match => 'No practices match';

  @override
  String group_event_add_practices_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count practices',
      one: 'Add 1 practice',
      zero: 'Add practices',
    );
    return '$_temp0';
  }

  @override
  String get group_event_counted_by => 'Counted by';

  @override
  String get group_event_count_mode_title => 'Who adds the count?';

  @override
  String get group_event_count_mode_attendees => 'Attendees add in app';

  @override
  String get group_event_count_mode_attendees_hint =>
      'Each person adds their own recitations, during or after the event';

  @override
  String get group_event_count_mode_admin =>
      'Admin adds for in-person attendees';

  @override
  String get group_event_count_mode_admin_hint =>
      'You enter the group\'s count, i.e. people × rounds';

  @override
  String get group_event_count_mode_admin_short => 'Admin adds';

  @override
  String get group_event_count_mode_attendees_taken =>
      'Another accumulation already uses this. Attendees can add counts to only one accumulation per event.';

  @override
  String group_event_remove_practice(String title) {
    return 'Remove $title';
  }

  @override
  String get group_event_videos_section => 'About videos';

  @override
  String get group_event_videos_hint =>
      'Shown on the event\'s About page. Use them to introduce the event or explain what to expect.';

  @override
  String get group_event_add_video => 'Add video';

  @override
  String get group_event_video_link => 'YouTube link';

  @override
  String get group_event_video_link_hint => 'https://youtu.be/…';

  @override
  String get group_event_paste => 'Paste';

  @override
  String get group_event_video_loading => 'Getting video details…';

  @override
  String get group_event_video_invalid =>
      'That doesn\'t look like a YouTube link. Paste a link from YouTube.';

  @override
  String get group_event_video_source => 'YouTube';

  @override
  String get group_event_video_untitled => 'YouTube video';

  @override
  String get group_event_remove_video => 'Remove video';

  @override
  String get group_event_skip => 'Skip';

  @override
  String get group_event_step_review => 'Review & publish';

  @override
  String get group_event_review_event => 'Event';

  @override
  String get group_event_review_settings => 'Settings';

  @override
  String get group_event_review_name => 'Name';

  @override
  String get group_event_review_languages => 'Languages';

  @override
  String get group_event_review_when => 'When';

  @override
  String get group_event_review_where => 'Where';

  @override
  String get group_event_review_live_link => 'Live link';

  @override
  String get group_event_review_practices => 'Practices';

  @override
  String get group_event_review_videos => 'About videos';

  @override
  String get group_event_review_event_settings => 'Event settings';

  @override
  String get group_event_review_none => 'None';

  @override
  String get group_event_review_tap_hint => 'Tap any row to change it.';

  @override
  String get group_event_review_notify_hint =>
      'Members are notified when you publish.';

  @override
  String group_event_review_more(String first, int count) {
    return '$first + $count more';
  }

  @override
  String group_event_review_recurring_from(
    String rule,
    String times,
    String date,
  ) {
    return '$rule · $times · from $date';
  }

  @override
  String get group_event_review_youtube_live => 'YouTube live';

  @override
  String get group_event_review_online => 'Online';

  @override
  String get group_event_chat_on => 'Chat on';

  @override
  String get group_event_chat_off => 'Chat off';

  @override
  String get group_event_notifications_on => 'Notifications on';

  @override
  String get group_event_notifications_off => 'Notifications off';

  @override
  String get group_event_all_intentions => 'All intentions';

  @override
  String group_event_intentions_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count intentions',
      one: '1 intention',
    );
    return '$_temp0';
  }

  @override
  String get group_event_publish => 'Publish';

  @override
  String get group_event_publish_error =>
      'Unable to publish the event. Please try again';

  @override
  String get group_event_settings_title => 'Event settings';

  @override
  String get group_event_settings_chat => 'Event chat';

  @override
  String get group_event_settings_chat_hint =>
      'Gives the event its own chat, where members can talk and post prayer requests.';

  @override
  String get group_event_settings_notifications => 'Notifications';

  @override
  String get group_event_settings_notifications_hint =>
      'The notice when you publish, the reminder before it starts, and any you send yourself.';

  @override
  String get group_event_settings_intentions => 'Prayer intentions';

  @override
  String get group_event_settings_intentions_hint =>
      'Leave all unchecked to allow every intention.';

  @override
  String get group_event_settings_intentions_error =>
      'Unable to load intentions right now.';

  @override
  String get group_event_published_title => 'Published';

  @override
  String group_event_published_headline(String name) {
    return '$name is live';
  }

  @override
  String group_event_published_message(String group) {
    return 'Members of $group have been notified. You can edit it any time from the event page.';
  }

  @override
  String get group_event_published_message_silent =>
      'You can edit it any time from the event page.';

  @override
  String get group_event_view_event => 'View event';

  @override
  String get group_event_drafts_section => 'Drafts';

  @override
  String get group_event_draft_label => 'Draft';

  @override
  String get group_event_draft_untitled => 'Untitled event';

  @override
  String get group_event_draft_menu_continue => 'Continue editing';

  @override
  String get group_event_draft_menu_delete => 'Delete draft';

  @override
  String get group_event_draft_menu_delete_hint => 'This can\'t be undone';

  @override
  String get group_event_draft_saved => 'Saved as draft';

  @override
  String get group_event_draft_save_error =>
      'Unable to save the draft. Please try again';

  @override
  String get group_event_draft_deleted => 'Draft deleted';

  @override
  String get group_event_draft_delete_error =>
      'Unable to delete the draft. Please try again';

  @override
  String get group_event_draft_delete_title => 'Delete draft?';

  @override
  String get group_event_draft_delete_message =>
      'This draft will be permanently removed';

  @override
  String get group_event_edit_draft_title => 'Edit draft';

  @override
  String get group_event_edit_title => 'Edit event';

  @override
  String get group_event_save_changes => 'Save changes';

  @override
  String get group_event_changes_saved => 'Changes saved';

  @override
  String get group_event_manage => 'Manage event';

  @override
  String get group_event_manage_details => 'Details';

  @override
  String get group_event_manage_counts => 'Counts';

  @override
  String get group_event_manage_accumulations => 'Accumulations';

  @override
  String get group_event_manage_admin_adds_pending => 'Admin adds';

  @override
  String group_event_manage_admin_adds(String count) {
    return 'Admin adds · $count so far';
  }

  @override
  String get group_event_manage_attendees_add_pending => 'Attendees add in app';

  @override
  String group_event_manage_attendees_add(String count, int people) {
    String _temp0 = intl.Intl.pluralLogic(
      people,
      locale: localeName,
      other: 'Attendees add in app · $count from $people people',
      one: 'Attendees add in app · $count from 1 person',
    );
    return '$_temp0';
  }

  @override
  String get group_event_manage_add_count => 'Add count';

  @override
  String get group_event_manage_no_accumulations =>
      'This event has no accumulations.';

  @override
  String get group_event_manage_recurring_note =>
      'Attendee lists aren\'t kept for recurring events. Counts add up across all sessions.';

  @override
  String group_event_in_person_of_target(String count, String target) {
    return '$count of $target';
  }

  @override
  String group_event_in_person_in_total(String count) {
    return '$count in total';
  }

  @override
  String get group_event_in_person_legend_app => 'App';

  @override
  String get group_event_in_person_legend_in_person => 'In person';

  @override
  String get group_event_in_person_add_day => 'Add day';

  @override
  String get group_event_in_person_day => 'Day';

  @override
  String get group_event_in_person_count => 'Count';

  @override
  String get group_event_in_person_empty => 'No in-person counts yet.';

  @override
  String get group_event_in_person_invalid_count =>
      'Enter a whole number of at least 1';

  @override
  String get group_event_in_person_added => 'In-person count added';

  @override
  String get group_event_in_person_updated => 'In-person count updated';

  @override
  String get group_event_in_person_deleted => 'In-person count deleted';

  @override
  String get group_event_in_person_delete_title => 'Delete in-person count?';

  @override
  String group_event_in_person_delete_message(String count, String day) {
    return '$count for $day will be taken off the accumulation\'s total.';
  }

  @override
  String get group_event_in_person_exists =>
      'That day already has a count. Edit it instead.';

  @override
  String get group_event_in_person_no_accumulation =>
      'Link a group accumulation to this event to record in-person counts.';

  @override
  String get group_event_in_person_save_error => 'Could not save the count.';

  @override
  String get group_event_in_person_load_more => 'Load more';

  @override
  String get mala_failed_load_catalogue_error => 'Unable to load catalogue';

  @override
  String get chant_collection_reload_error =>
      'Unable to reload collection to reorder';

  @override
  String get chant_collection_reorder_error => 'Unable to reorder chants';

  @override
  String get timer_duration_label => 'DURATION';

  @override
  String get timer_ambient_sound_label => 'AMBIENT SOUND';

  @override
  String get timer_begin_session => 'Begin session';

  @override
  String get timer_save_changes => 'Save changes';

  @override
  String get timer_new_title => 'New timer';

  @override
  String get timer_title_hint => 'Title...';

  @override
  String get timer_edit_title => 'Edit timer';

  @override
  String get timer_your_timers => 'Your timers';

  @override
  String get timer_ambient_sounds_title => 'Ambient sounds';

  @override
  String get timer_ambient_sound_none => 'Default (no sound)';

  @override
  String get timer_ambient_sounds_load_error => 'Unable to load ambient sounds';

  @override
  String get timer_volume_label => 'VOLUME';

  @override
  String get timer_duration_title => 'Duration';

  @override
  String get timer_edit => 'Edit timer';

  @override
  String get timer_delete => 'Delete timer';

  @override
  String get timer_delete_title => 'Delete timer?';

  @override
  String get timer_delete_message =>
      'This timer will be removed from your timers.';

  @override
  String get timer_duration_must_be_greater_than_error =>
      'Duration must be greater than 0';

  @override
  String get splash_tagline_1 => 'We Buddhists practice together';

  @override
  String get splash_tagline_2 => 'We Buddhists practice daily';

  @override
  String get timer_create_custom => 'Create a custom timer';

  @override
  String get timer_starting => 'Starting...';

  @override
  String get timer_duration_hours => 'hours';

  @override
  String get timer_duration_sec => 'sec';

  @override
  String get reader_display_title => 'Display';

  @override
  String get reader_more_settings => 'More settings';

  @override
  String get reader_spacing => 'Spacing';

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

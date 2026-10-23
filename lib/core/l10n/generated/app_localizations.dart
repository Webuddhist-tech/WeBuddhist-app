import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bo.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mn.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bo'),
    Locale('en'),
    Locale('hi'),
    Locale('mn'),
    Locale('ne'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'WeBuddhist'**
  String get appTitle;

  /// No description provided for @sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get sign_in;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @onboarding_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to'**
  String get onboarding_welcome;

  /// No description provided for @onboarding_setup_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get you set up, It\'ll only take a minute'**
  String get onboarding_setup_subtitle;

  /// No description provided for @onboarding_tagline.
  ///
  /// In en, this message translates to:
  /// **'Learn, practice, and connect. Daily.'**
  String get onboarding_tagline;

  /// No description provided for @onboarding_quote.
  ///
  /// In en, this message translates to:
  /// **'Drop by drop the water pot is filled. Likewise, the wise person, gathering it little by little, fills themselves with good.'**
  String get onboarding_quote;

  /// No description provided for @onboarding_find_peace.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboarding_find_peace;

  /// No description provided for @onboarding_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboarding_continue;

  /// No description provided for @onboarding_first_question.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get onboarding_first_question;

  /// No description provided for @onboarding_language_subtitle.
  ///
  /// In en, this message translates to:
  /// **'This sets the language of the app'**
  String get onboarding_language_subtitle;

  /// No description provided for @onboarding_choose_option.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one:'**
  String get onboarding_choose_option;

  /// No description provided for @onboarding_all_set.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set'**
  String get onboarding_all_set;

  /// No description provided for @onboarding_all_set_description.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what\'s waiting for you:'**
  String get onboarding_all_set_description;

  /// No description provided for @onboarding_all_set_practice_title.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get onboarding_all_set_practice_title;

  /// No description provided for @onboarding_all_set_practice_body.
  ///
  /// In en, this message translates to:
  /// **'Plans, chants, malas and meditation'**
  String get onboarding_all_set_practice_body;

  /// No description provided for @onboarding_all_set_connect_title.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get onboarding_all_set_connect_title;

  /// No description provided for @onboarding_all_set_connect_body.
  ///
  /// In en, this message translates to:
  /// **'Spaces, events, newsfeed and chat'**
  String get onboarding_all_set_connect_body;

  /// No description provided for @home_recitation.
  ///
  /// In en, this message translates to:
  /// **'recitations'**
  String get home_recitation;

  /// No description provided for @home_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get home_today;

  /// No description provided for @home_good_morning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get home_good_morning;

  /// No description provided for @home_good_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get home_good_afternoon;

  /// No description provided for @home_good_evening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get home_good_evening;

  /// No description provided for @home_meditationTitle.
  ///
  /// In en, this message translates to:
  /// **'Meditation'**
  String get home_meditationTitle;

  /// No description provided for @home_prayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer of the day'**
  String get home_prayerTitle;

  /// No description provided for @home_scripture.
  ///
  /// In en, this message translates to:
  /// **'Guided scripture'**
  String get home_scripture;

  /// No description provided for @home_meditation.
  ///
  /// In en, this message translates to:
  /// **'Guided meditation'**
  String get home_meditation;

  /// No description provided for @home_goDeeper.
  ///
  /// In en, this message translates to:
  /// **'Go deeper'**
  String get home_goDeeper;

  /// No description provided for @home_intention.
  ///
  /// In en, this message translates to:
  /// **'My intention for today'**
  String get home_intention;

  /// No description provided for @home_overall_stats.
  ///
  /// In en, this message translates to:
  /// **'Overall stats'**
  String get home_overall_stats;

  /// No description provided for @home_plans.
  ///
  /// In en, this message translates to:
  /// **'plans'**
  String get home_plans;

  /// No description provided for @home_plans_count.
  ///
  /// In en, this message translates to:
  /// **'{count} plans'**
  String home_plans_count(int count);

  /// No description provided for @home_recitation_count.
  ///
  /// In en, this message translates to:
  /// **'{count} chants'**
  String home_recitation_count(int count);

  /// No description provided for @home_shortcut_plans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get home_shortcut_plans;

  /// No description provided for @home_chants.
  ///
  /// In en, this message translates to:
  /// **'Chants'**
  String get home_chants;

  /// No description provided for @home_mala.
  ///
  /// In en, this message translates to:
  /// **'Mala'**
  String get home_mala;

  /// No description provided for @session_mala.
  ///
  /// In en, this message translates to:
  /// **'Malas'**
  String get session_mala;

  /// No description provided for @bookmark_mala.
  ///
  /// In en, this message translates to:
  /// **'Malas'**
  String get bookmark_mala;

  /// No description provided for @bookmark_timers.
  ///
  /// In en, this message translates to:
  /// **'Timers'**
  String get bookmark_timers;

  /// No description provided for @bookmark_texts.
  ///
  /// In en, this message translates to:
  /// **'Texts'**
  String get bookmark_texts;

  /// No description provided for @bookmark_group_accumulation.
  ///
  /// In en, this message translates to:
  /// **'Space accumulations'**
  String get bookmark_group_accumulation;

  /// No description provided for @mala_add_to_practice.
  ///
  /// In en, this message translates to:
  /// **'Add to my practices'**
  String get mala_add_to_practice;

  /// No description provided for @mala_add_mala_round.
  ///
  /// In en, this message translates to:
  /// **'Add mala round'**
  String get mala_add_mala_round;

  /// No description provided for @mala_add_rounds_title.
  ///
  /// In en, this message translates to:
  /// **'Add mala rounds:'**
  String get mala_add_rounds_title;

  /// No description provided for @mala_add_rounds_message.
  ///
  /// In en, this message translates to:
  /// **'Add the mala rounds you did outside the app'**
  String get mala_add_rounds_message;

  /// Unit shown beside the number picked in the add mala rounds wheel
  ///
  /// In en, this message translates to:
  /// **'{count, plural,\n=1 {round}\nother {rounds}\n}'**
  String mala_rounds_unit(int count);

  /// No description provided for @mala_add_to_bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get mala_add_to_bookmark;

  /// No description provided for @mala_sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get mala_sound;

  /// No description provided for @mala_vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get mala_vibration;

  /// No description provided for @mala_reset_count.
  ///
  /// In en, this message translates to:
  /// **'Reset count'**
  String get mala_reset_count;

  /// No description provided for @mala_reset_title.
  ///
  /// In en, this message translates to:
  /// **'Reset this mala?'**
  String get mala_reset_title;

  /// No description provided for @mala_reset_count_confirm.
  ///
  /// In en, this message translates to:
  /// **'Your current count will go back to zero, but your accumulations will stay in your lifetime total'**
  String get mala_reset_count_confirm;

  /// No description provided for @mala_reset_confirm.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get mala_reset_confirm;

  /// No description provided for @mala_action_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get mala_action_coming_soon;

  /// No description provided for @mala_rounds_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural,\n=0 {0 rounds}\n=1 {1 round}\nother {{count} rounds}\n}'**
  String mala_rounds_count(int count);

  /// No description provided for @mala_hand_layout_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch hand layout'**
  String get mala_hand_layout_tooltip;

  /// No description provided for @mala_settings_section.
  ///
  /// In en, this message translates to:
  /// **'Mala settings'**
  String get mala_settings_section;

  /// No description provided for @mala_others_section.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get mala_others_section;

  /// No description provided for @mala_mantra_speed.
  ///
  /// In en, this message translates to:
  /// **'Mantra speed'**
  String get mala_mantra_speed;

  /// No description provided for @mala_speed_normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get mala_speed_normal;

  /// No description provided for @mala_show_full_mantra.
  ///
  /// In en, this message translates to:
  /// **'Show full mantra'**
  String get mala_show_full_mantra;

  /// No description provided for @mala_counter_semantics.
  ///
  /// In en, this message translates to:
  /// **'Count {bead} of {total}, {rounds}'**
  String mala_counter_semantics(int bead, int total, String rounds);

  /// No description provided for @mala_group_accumulations.
  ///
  /// In en, this message translates to:
  /// **'Add recitation to'**
  String get mala_group_accumulations;

  /// No description provided for @mala_groups_section.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get mala_groups_section;

  /// No description provided for @mala_group_untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled space'**
  String get mala_group_untitled;

  /// No description provided for @mala_all_time_accumulation.
  ///
  /// In en, this message translates to:
  /// **'My all-time accumulation'**
  String get mala_all_time_accumulation;

  /// No description provided for @mala_personal_practice.
  ///
  /// In en, this message translates to:
  /// **'Personal practice'**
  String get mala_personal_practice;

  /// No description provided for @mala_events_section.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get mala_events_section;

  /// No description provided for @mala_my_total.
  ///
  /// In en, this message translates to:
  /// **'My total: {count}'**
  String mala_my_total(String count);

  /// No description provided for @mala_group_total.
  ///
  /// In en, this message translates to:
  /// **'Group total: {count}'**
  String mala_group_total(String count);

  /// No description provided for @home_timer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get home_timer;

  /// No description provided for @preset_timers.
  ///
  /// In en, this message translates to:
  /// **'Preset timers'**
  String get preset_timers;

  /// No description provided for @meditation_timer.
  ///
  /// In en, this message translates to:
  /// **'Meditation timer'**
  String get meditation_timer;

  /// No description provided for @timer_min.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get timer_min;

  /// No description provided for @timer_start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get timer_start;

  /// No description provided for @timer_finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get timer_finish;

  /// No description provided for @timer_discard_session.
  ///
  /// In en, this message translates to:
  /// **'Discard session'**
  String get timer_discard_session;

  /// No description provided for @home_hello_prefix.
  ///
  /// In en, this message translates to:
  /// **'Hello, '**
  String get home_hello_prefix;

  /// No description provided for @home_greeting_fallback_name.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get home_greeting_fallback_name;

  /// No description provided for @home_share_prompt.
  ///
  /// In en, this message translates to:
  /// **'Enjoying {appName}?'**
  String home_share_prompt(String appName);

  /// No description provided for @home_share_support.
  ///
  /// In en, this message translates to:
  /// **'Your support helps our community grow'**
  String get home_share_support;

  /// No description provided for @no_feature_content.
  ///
  /// In en, this message translates to:
  /// **'No featured content available'**
  String get no_feature_content;

  /// No description provided for @nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get nav_explore;

  /// No description provided for @nav_learn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get nav_learn;

  /// No description provided for @nav_practice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get nav_practice;

  /// No description provided for @nav_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get nav_settings;

  /// No description provided for @nav_connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get nav_connect;

  /// No description provided for @nav_me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get nav_me;

  /// No description provided for @tab_practices.
  ///
  /// In en, this message translates to:
  /// **'Practices'**
  String get tab_practices;

  /// No description provided for @text_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get text_search;

  /// No description provided for @text_toc_versions.
  ///
  /// In en, this message translates to:
  /// **'Versions'**
  String get text_toc_versions;

  /// No description provided for @text_commentary.
  ///
  /// In en, this message translates to:
  /// **'Commentaries'**
  String get text_commentary;

  /// No description provided for @resources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get resources;

  /// No description provided for @no_translation.
  ///
  /// In en, this message translates to:
  /// **'No translations found'**
  String get no_translation;

  /// No description provided for @text_close_commentary.
  ///
  /// In en, this message translates to:
  /// **'Close commentary'**
  String get text_close_commentary;

  /// No description provided for @show_more.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get show_more;

  /// No description provided for @show_less.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get show_less;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @less.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get less;

  /// No description provided for @no_content.
  ///
  /// In en, this message translates to:
  /// **'No content found'**
  String get no_content;

  /// No description provided for @no_commentary.
  ///
  /// In en, this message translates to:
  /// **'No commentaries found'**
  String get no_commentary;

  /// No description provided for @commentary_not_available_for_language.
  ///
  /// In en, this message translates to:
  /// **'{language} commentary not available'**
  String commentary_not_available_for_language(String language);

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @choose_bg_image.
  ///
  /// In en, this message translates to:
  /// **'Choose a background image'**
  String get choose_bg_image;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @customise_message.
  ///
  /// In en, this message translates to:
  /// **'Tap the customize icon to adjust text style'**
  String get customise_message;

  /// No description provided for @download_image.
  ///
  /// In en, this message translates to:
  /// **'Download image'**
  String get download_image;

  /// No description provided for @no_images_available.
  ///
  /// In en, this message translates to:
  /// **'No images available'**
  String get no_images_available;

  /// No description provided for @customise_text.
  ///
  /// In en, this message translates to:
  /// **'Customize text'**
  String get customise_text;

  /// No description provided for @text_size.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get text_size;

  /// No description provided for @text_color.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get text_color;

  /// No description provided for @text_shadow.
  ///
  /// In en, this message translates to:
  /// **'Text shadow'**
  String get text_shadow;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @my_plans.
  ///
  /// In en, this message translates to:
  /// **'My plans'**
  String get my_plans;

  /// No description provided for @browse_plans.
  ///
  /// In en, this message translates to:
  /// **'Browse plans'**
  String get browse_plans;

  /// No description provided for @plan_info.
  ///
  /// In en, this message translates to:
  /// **'Plan info'**
  String get plan_info;

  /// No description provided for @start_reading.
  ///
  /// In en, this message translates to:
  /// **'Practice now'**
  String get start_reading;

  /// No description provided for @tibetan.
  ///
  /// In en, this message translates to:
  /// **'Tibetan'**
  String get tibetan;

  /// No description provided for @sanskrit.
  ///
  /// In en, this message translates to:
  /// **'Sanskrit'**
  String get sanskrit;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// No description provided for @classicalChinese.
  ///
  /// In en, this message translates to:
  /// **'Classical Chinese'**
  String get classicalChinese;

  /// No description provided for @pali.
  ///
  /// In en, this message translates to:
  /// **'Pali'**
  String get pali;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @plan_unenroll.
  ///
  /// In en, this message translates to:
  /// **'Unenroll'**
  String get plan_unenroll;

  /// No description provided for @unenroll_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unenroll in'**
  String get unenroll_confirmation;

  /// No description provided for @unenroll_message.
  ///
  /// In en, this message translates to:
  /// **'Your progress will be permanently lost and cannot be recovered'**
  String get unenroll_message;

  /// No description provided for @practice_plan.
  ///
  /// In en, this message translates to:
  /// **'Build a daily practice. Explore what fits you.'**
  String get practice_plan;

  /// No description provided for @search_plans.
  ///
  /// In en, this message translates to:
  /// **'Search plans...'**
  String get search_plans;

  /// No description provided for @search_for_plans.
  ///
  /// In en, this message translates to:
  /// **'Search for plans'**
  String get search_for_plans;

  /// No description provided for @no_plans_found.
  ///
  /// In en, this message translates to:
  /// **'No plans found'**
  String get no_plans_found;

  /// No description provided for @no_days_available.
  ///
  /// In en, this message translates to:
  /// **'No days found'**
  String get no_days_available;

  /// No description provided for @recitations_title.
  ///
  /// In en, this message translates to:
  /// **'Recitations'**
  String get recitations_title;

  /// No description provided for @recitations_my_recitations.
  ///
  /// In en, this message translates to:
  /// **'My recitations'**
  String get recitations_my_recitations;

  /// No description provided for @browse_recitations.
  ///
  /// In en, this message translates to:
  /// **'Browse recitations'**
  String get browse_recitations;

  /// No description provided for @recitations_search.
  ///
  /// In en, this message translates to:
  /// **'Search for recitations...'**
  String get recitations_search;

  /// No description provided for @recitations_search_for.
  ///
  /// In en, this message translates to:
  /// **'Search for recitations'**
  String get recitations_search_for;

  /// No description provided for @recitations_no_found.
  ///
  /// In en, this message translates to:
  /// **'No recitations founds'**
  String get recitations_no_found;

  /// No description provided for @recitations_no_content.
  ///
  /// In en, this message translates to:
  /// **'No recitations available'**
  String get recitations_no_content;

  /// No description provided for @recitations_no_saved.
  ///
  /// In en, this message translates to:
  /// **'No saved recitations'**
  String get recitations_no_saved;

  /// No description provided for @recitations_login_prompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your saved recitations'**
  String get recitations_login_prompt;

  /// No description provided for @my_recitation_collection_new_title.
  ///
  /// In en, this message translates to:
  /// **'New Collection'**
  String get my_recitation_collection_new_title;

  /// No description provided for @my_recitation_collection_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get my_recitation_collection_next;

  /// No description provided for @my_recitation_collection_create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get my_recitation_collection_create;

  /// No description provided for @my_recitation_collection_create_button.
  ///
  /// In en, this message translates to:
  /// **'Create collection'**
  String get my_recitation_collection_create_button;

  /// No description provided for @my_recitation_collection_change_title.
  ///
  /// In en, this message translates to:
  /// **'Change title'**
  String get my_recitation_collection_change_title;

  /// No description provided for @my_recitation_collection_change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get my_recitation_collection_change;

  /// No description provided for @my_recitation_collection_add_chants.
  ///
  /// In en, this message translates to:
  /// **'Add chants'**
  String get my_recitation_collection_add_chants;

  /// No description provided for @my_recitation_collection_search_chants.
  ///
  /// In en, this message translates to:
  /// **'Search chants'**
  String get my_recitation_collection_search_chants;

  /// No description provided for @my_recitation_collection_add_to_collection.
  ///
  /// In en, this message translates to:
  /// **'Add to collection'**
  String get my_recitation_collection_add_to_collection;

  /// No description provided for @my_recitation_collection_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit collection'**
  String get my_recitation_collection_edit;

  /// No description provided for @my_recitation_collection_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete collection'**
  String get my_recitation_collection_delete;

  /// No description provided for @my_recitation_collection_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete collection?'**
  String get my_recitation_collection_delete_title;

  /// No description provided for @my_recitation_collection_delete_message.
  ///
  /// In en, this message translates to:
  /// **'This collection will be permanently removed'**
  String get my_recitation_collection_delete_message;

  /// No description provided for @my_recitation_collection_fallback_title.
  ///
  /// In en, this message translates to:
  /// **'Chant collection'**
  String get my_recitation_collection_fallback_title;

  /// No description provided for @my_recitation_collection_unavailable.
  ///
  /// In en, this message translates to:
  /// **'No longer available'**
  String get my_recitation_collection_unavailable;

  /// No description provided for @my_recitation_collection_chant_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural,\n=0 {0 chants}\n=1 {1 chant}\nother {{count} chants}\n}'**
  String my_recitation_collection_chant_count(int count);

  /// No description provided for @my_recitation_collection_chant_count_owner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural,\n=0 {0 chants • me}\n=1 {1 chant • me}\nother {{count} chants • me}\n}'**
  String my_recitation_collection_chant_count_owner(int count);

  /// No description provided for @bookmarks_empty_chant_collections_title.
  ///
  /// In en, this message translates to:
  /// **'No chant collections bookmarked yet'**
  String get bookmarks_empty_chant_collections_title;

  /// No description provided for @bookmarks_empty_chant_collections_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmark one to save it here'**
  String get bookmarks_empty_chant_collections_subtitle;

  /// No description provided for @notification_allow_title.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get notification_allow_title;

  /// No description provided for @notification_allow_subtitle_disabled.
  ///
  /// In en, this message translates to:
  /// **'Permission needed. Tap to grant in Settings'**
  String get notification_allow_subtitle_disabled;

  /// No description provided for @notification_snack_permission_denied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked. Turn them on in Settings'**
  String get notification_snack_permission_denied;

  /// No description provided for @notification_snack_disable_alarms_in_settings.
  ///
  /// In en, this message translates to:
  /// **'Turn off alarms & reminders in Settings'**
  String get notification_snack_disable_alarms_in_settings;

  /// No description provided for @notification_allow_subtitle_on.
  ///
  /// In en, this message translates to:
  /// **'Reminders and updates from WeBuddhist'**
  String get notification_allow_subtitle_on;

  /// No description provided for @notification_allow_subtitle_off.
  ///
  /// In en, this message translates to:
  /// **'Off. Turn on to get reminders and updates.'**
  String get notification_allow_subtitle_off;

  /// No description provided for @notification_section_practice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get notification_section_practice;

  /// No description provided for @notification_section_connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get notification_section_connect;

  /// No description provided for @notification_row_plans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get notification_row_plans;

  /// No description provided for @notification_row_chants.
  ///
  /// In en, this message translates to:
  /// **'Chants'**
  String get notification_row_chants;

  /// No description provided for @notification_row_mala.
  ///
  /// In en, this message translates to:
  /// **'Mala & accumulations'**
  String get notification_row_mala;

  /// No description provided for @notification_row_timer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get notification_row_timer;

  /// No description provided for @notification_row_group_posts.
  ///
  /// In en, this message translates to:
  /// **'Group posts'**
  String get notification_row_group_posts;

  /// No description provided for @notification_row_group_chats.
  ///
  /// In en, this message translates to:
  /// **'Group chats'**
  String get notification_row_group_chats;

  /// No description provided for @notification_row_my_prayer_requests.
  ///
  /// In en, this message translates to:
  /// **'My prayer requests'**
  String get notification_row_my_prayer_requests;

  /// No description provided for @notification_row_others_prayer_requests.
  ///
  /// In en, this message translates to:
  /// **'Other people\'s prayer requests'**
  String get notification_row_others_prayer_requests;

  /// No description provided for @profile_default_bio.
  ///
  /// In en, this message translates to:
  /// **'Welcome to WeBuddhist'**
  String get profile_default_bio;

  /// No description provided for @profile_guest_title.
  ///
  /// In en, this message translates to:
  /// **'Guest user'**
  String get profile_guest_title;

  /// No description provided for @profile_guest_subtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re browsing as a guest'**
  String get profile_guest_subtitle;

  /// No description provided for @profile_guest_benefits_header.
  ///
  /// In en, this message translates to:
  /// **'Sign in to unlock:'**
  String get profile_guest_benefits_header;

  /// No description provided for @profile_guest_benefit_save_progress.
  ///
  /// In en, this message translates to:
  /// **'Save your progress'**
  String get profile_guest_benefit_save_progress;

  /// No description provided for @profile_guest_benefit_personalized.
  ///
  /// In en, this message translates to:
  /// **'Personalized content'**
  String get profile_guest_benefit_personalized;

  /// No description provided for @profile_guest_benefit_notifications.
  ///
  /// In en, this message translates to:
  /// **'Custom notifications'**
  String get profile_guest_benefit_notifications;

  /// No description provided for @auth_drawer_title.
  ///
  /// In en, this message translates to:
  /// **'Log in to continue'**
  String get auth_drawer_title;

  /// No description provided for @auth_drawer_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Continue your practice on any device, wherever you go'**
  String get auth_drawer_subtitle;

  /// No description provided for @routine_delete_block_message.
  ///
  /// In en, this message translates to:
  /// **'The time block and all its items will be removed'**
  String get routine_delete_block_message;

  /// No description provided for @something_went_wrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again'**
  String get something_went_wrong;

  /// No description provided for @onboarding_quote_citation.
  ///
  /// In en, this message translates to:
  /// **'— Dhammapada 122'**
  String get onboarding_quote_citation;

  /// No description provided for @onboarding_traditions_question.
  ///
  /// In en, this message translates to:
  /// **'Which traditions\ndo you follow?'**
  String get onboarding_traditions_question;

  /// No description provided for @onboarding_tradition_title.
  ///
  /// In en, this message translates to:
  /// **'How do you follow the Buddha’s teachings?'**
  String get onboarding_tradition_title;

  /// No description provided for @onboarding_tradition_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose one or more traditions for your content. You can change this anytime in Settings.'**
  String get onboarding_tradition_subtitle;

  /// No description provided for @onboarding_tradition_option_intro.
  ///
  /// In en, this message translates to:
  /// **'Through:'**
  String get onboarding_tradition_option_intro;

  /// No description provided for @onboarding_tradition_show_all_title.
  ///
  /// In en, this message translates to:
  /// **'Show me everything'**
  String get onboarding_tradition_show_all_title;

  /// No description provided for @onboarding_skip_for_now.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get onboarding_skip_for_now;

  /// No description provided for @onboarding_add_another_tradition.
  ///
  /// In en, this message translates to:
  /// **'Add another tradition'**
  String get onboarding_add_another_tradition;

  /// No description provided for @onboarding_select_all.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get onboarding_select_all;

  /// No description provided for @onboarding_event_enrollment_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to enroll you. Check your connection and try again'**
  String get onboarding_event_enrollment_error;

  /// No description provided for @onboarding_event_question.
  ///
  /// In en, this message translates to:
  /// **'Join an\nevent?'**
  String get onboarding_event_question;

  /// No description provided for @onboarding_event_optional.
  ///
  /// In en, this message translates to:
  /// **'Optional · Tap to enroll'**
  String get onboarding_event_optional;

  /// No description provided for @onboarding_event_duration.
  ///
  /// In en, this message translates to:
  /// **'{description} · {days} days'**
  String onboarding_event_duration(String description, int days);

  /// No description provided for @onboarding_event_reminder_note.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a daily reminder at 7:30 AM. (Change anytime.)'**
  String get onboarding_event_reminder_note;

  /// No description provided for @tradition_theravada.
  ///
  /// In en, this message translates to:
  /// **'Theravada'**
  String get tradition_theravada;

  /// No description provided for @tradition_zen.
  ///
  /// In en, this message translates to:
  /// **'Zen'**
  String get tradition_zen;

  /// No description provided for @tradition_tibetan_buddhism.
  ///
  /// In en, this message translates to:
  /// **'Tibetan Buddhism'**
  String get tradition_tibetan_buddhism;

  /// No description provided for @tradition_pure_land.
  ///
  /// In en, this message translates to:
  /// **'Pure Land'**
  String get tradition_pure_land;

  /// No description provided for @tradition_ambedkar_buddhism.
  ///
  /// In en, this message translates to:
  /// **'Ambedkar Buddhism'**
  String get tradition_ambedkar_buddhism;

  /// No description provided for @plan_go_to_practice.
  ///
  /// In en, this message translates to:
  /// **'Go to practice'**
  String get plan_go_to_practice;

  /// No description provided for @plan_starts_soon_title.
  ///
  /// In en, this message translates to:
  /// **'Starts soon'**
  String get plan_starts_soon_title;

  /// No description provided for @plan_joining_late_title.
  ///
  /// In en, this message translates to:
  /// **'Joining after start date'**
  String get plan_joining_late_title;

  /// No description provided for @got_it.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get got_it;

  /// No description provided for @plan_no_tasks_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load tasks'**
  String get plan_no_tasks_error;

  /// No description provided for @plan_day_tasks_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load tasks'**
  String get plan_day_tasks_load_error;

  /// No description provided for @plans_empty_title.
  ///
  /// In en, this message translates to:
  /// **'More is on the way'**
  String get plans_empty_title;

  /// No description provided for @plans_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Our library is growing. Check back soon.'**
  String get plans_empty_subtitle;

  /// No description provided for @find_plans_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load.\nCheck your connection and try again'**
  String get find_plans_load_error;

  /// No description provided for @connect_coming_soon_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Teachers, communities, challenges, and events to support you on the path'**
  String get connect_coming_soon_subtitle;

  /// No description provided for @connect_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Find spaces and practice together'**
  String get connect_subtitle;

  /// No description provided for @discover_groups.
  ///
  /// In en, this message translates to:
  /// **'Discover spaces'**
  String get discover_groups;

  /// No description provided for @my_groups.
  ///
  /// In en, this message translates to:
  /// **'My spaces'**
  String get my_groups;

  /// No description provided for @see_all.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get see_all;

  /// No description provided for @connect_groups_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load spaces.\nCheck your connection and try again'**
  String get connect_groups_load_error;

  /// No description provided for @connect_groups_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No more spaces'**
  String get connect_groups_empty_title;

  /// No description provided for @connect_groups_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Congrats, you\'ve joined all our spaces! Check back soon. New ones are on the way...'**
  String get connect_groups_empty_subtitle;

  /// No description provided for @connect_tab_feed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get connect_tab_feed;

  /// No description provided for @connect_tab_events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get connect_tab_events;

  /// No description provided for @connect_tab_posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get connect_tab_posts;

  /// No description provided for @connect_tab_practices.
  ///
  /// In en, this message translates to:
  /// **'Practices'**
  String get connect_tab_practices;

  /// No description provided for @connect_tab_groups.
  ///
  /// In en, this message translates to:
  /// **'Spaces'**
  String get connect_tab_groups;

  /// No description provided for @connect_segment_my.
  ///
  /// In en, this message translates to:
  /// **'Your spaces'**
  String get connect_segment_my;

  /// No description provided for @connect_segment_discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get connect_segment_discover;

  /// No description provided for @connect_empty_discover_posts.
  ///
  /// In en, this message translates to:
  /// **'No posts to discover'**
  String get connect_empty_discover_posts;

  /// No description provided for @connect_empty_discover_events.
  ///
  /// In en, this message translates to:
  /// **'No events to discover'**
  String get connect_empty_discover_events;

  /// No description provided for @connect_empty_discover_feed.
  ///
  /// In en, this message translates to:
  /// **'Nothing to discover'**
  String get connect_empty_discover_feed;

  /// No description provided for @connect_empty_discover_groups.
  ///
  /// In en, this message translates to:
  /// **'No spaces to discover'**
  String get connect_empty_discover_groups;

  /// No description provided for @connect_empty_discover_practices.
  ///
  /// In en, this message translates to:
  /// **'No practices to discover'**
  String get connect_empty_discover_practices;

  /// No description provided for @connect_all_groups.
  ///
  /// In en, this message translates to:
  /// **'All spaces'**
  String get connect_all_groups;

  /// No description provided for @connect_my_empty_feed_title.
  ///
  /// In en, this message translates to:
  /// **'No new updates'**
  String get connect_my_empty_feed_title;

  /// No description provided for @connect_my_empty_events_title.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events'**
  String get connect_my_empty_events_title;

  /// No description provided for @connect_my_empty_posts_title.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get connect_my_empty_posts_title;

  /// No description provided for @connect_my_empty_groups_title.
  ///
  /// In en, this message translates to:
  /// **'No spaces yet'**
  String get connect_my_empty_groups_title;

  /// No description provided for @connect_my_empty_feed_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your spaces haven\'t shared anything new'**
  String get connect_my_empty_feed_subtitle;

  /// No description provided for @connect_my_empty_events_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your spaces haven\'t scheduled any events'**
  String get connect_my_empty_events_subtitle;

  /// No description provided for @connect_my_empty_posts_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your spaces haven\'t posted anything'**
  String get connect_my_empty_posts_subtitle;

  /// No description provided for @connect_my_empty_groups_subtitle.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t joined any spaces yet. Discover some to practice with'**
  String get connect_my_empty_groups_subtitle;

  /// No description provided for @connect_my_empty_feed_browse.
  ///
  /// In en, this message translates to:
  /// **'See what other spaces are sharing'**
  String get connect_my_empty_feed_browse;

  /// No description provided for @connect_my_empty_events_browse.
  ///
  /// In en, this message translates to:
  /// **'Browse open events'**
  String get connect_my_empty_events_browse;

  /// No description provided for @connect_my_empty_posts_browse.
  ///
  /// In en, this message translates to:
  /// **'Browse other posts'**
  String get connect_my_empty_posts_browse;

  /// No description provided for @connect_my_empty_practices_title.
  ///
  /// In en, this message translates to:
  /// **'No practices yet'**
  String get connect_my_empty_practices_title;

  /// No description provided for @connect_my_empty_practices_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your spaces haven\'t started any practices'**
  String get connect_my_empty_practices_subtitle;

  /// No description provided for @connect_my_empty_practices_browse.
  ///
  /// In en, this message translates to:
  /// **'Browse other practices'**
  String get connect_my_empty_practices_browse;

  /// No description provided for @connect_comment_replying_to.
  ///
  /// In en, this message translates to:
  /// **'Replying to @{handle}'**
  String connect_comment_replying_to(String handle);

  /// No description provided for @connect_comment_hint.
  ///
  /// In en, this message translates to:
  /// **'What do you think of this?'**
  String get connect_comment_hint;

  /// No description provided for @connect_comment_reply_hint.
  ///
  /// In en, this message translates to:
  /// **'Write a reply...'**
  String get connect_comment_reply_hint;

  /// No description provided for @connect_comment_reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get connect_comment_reply;

  /// No description provided for @connect_comment_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete comment?'**
  String get connect_comment_delete_title;

  /// No description provided for @connect_comment_delete_message.
  ///
  /// In en, this message translates to:
  /// **'This comment will be permanently removed'**
  String get connect_comment_delete_message;

  /// No description provided for @connect_comment_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete comment'**
  String get connect_comment_delete_failed;

  /// No description provided for @connect_post_comments_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 comment} other{{count} comments}}'**
  String connect_post_comments_count(int count);

  /// No description provided for @connect_post_comments_empty.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Start the conversation'**
  String get connect_post_comments_empty;

  /// No description provided for @connect_caption_more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get connect_caption_more;

  /// No description provided for @connect_online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get connect_online;

  /// No description provided for @connect_ended.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get connect_ended;

  /// No description provided for @connect_ended_on.
  ///
  /// In en, this message translates to:
  /// **'Ended {date}'**
  String connect_ended_on(String date);

  /// No description provided for @home_group_events.
  ///
  /// In en, this message translates to:
  /// **'Featured events'**
  String get home_group_events;

  /// No description provided for @home_poems.
  ///
  /// In en, this message translates to:
  /// **'Poems'**
  String get home_poems;

  /// No description provided for @poems_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load poems.\nCheck your connection and try again'**
  String get poems_load_error;

  /// No description provided for @poems_empty.
  ///
  /// In en, this message translates to:
  /// **'No poems yet. Check back soon'**
  String get poems_empty;

  /// No description provided for @connect_events_filter_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get connect_events_filter_all;

  /// No description provided for @connect_events_filter_in_person.
  ///
  /// In en, this message translates to:
  /// **'In person'**
  String get connect_events_filter_in_person;

  /// No description provided for @connect_events_filter_empty_online.
  ///
  /// In en, this message translates to:
  /// **'No online events'**
  String get connect_events_filter_empty_online;

  /// No description provided for @connect_events_filter_empty_in_person.
  ///
  /// In en, this message translates to:
  /// **'No in-person events'**
  String get connect_events_filter_empty_in_person;

  /// No description provided for @connect_events_filter_hybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get connect_events_filter_hybrid;

  /// No description provided for @connect_events_filter_empty_hybrid.
  ///
  /// In en, this message translates to:
  /// **'No hybrid events'**
  String get connect_events_filter_empty_hybrid;

  /// No description provided for @connect_open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get connect_open;

  /// No description provided for @connect_event_fallback_title.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get connect_event_fallback_title;

  /// No description provided for @connect_group_fallback_title.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get connect_group_fallback_title;

  /// No description provided for @connect_event_enter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get connect_event_enter;

  /// No description provided for @connect_event_participation_prompt.
  ///
  /// In en, this message translates to:
  /// **'How are you attending?'**
  String get connect_event_participation_prompt;

  /// No description provided for @connect_event_practice_in_person.
  ///
  /// In en, this message translates to:
  /// **'Practice in-person'**
  String get connect_event_practice_in_person;

  /// No description provided for @connect_event_practice_online.
  ///
  /// In en, this message translates to:
  /// **'Practice online'**
  String get connect_event_practice_online;

  /// No description provided for @connect_event_view_in_person.
  ///
  /// In en, this message translates to:
  /// **'In-person view'**
  String get connect_event_view_in_person;

  /// No description provided for @connect_event_view_online.
  ///
  /// In en, this message translates to:
  /// **'Online view'**
  String get connect_event_view_online;

  /// No description provided for @connect_event_accumulation_online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get connect_event_accumulation_online;

  /// No description provided for @connect_event_accumulation_in_person.
  ///
  /// In en, this message translates to:
  /// **'In-person'**
  String get connect_event_accumulation_in_person;

  /// No description provided for @connect_event_has_ended.
  ///
  /// In en, this message translates to:
  /// **'This event has ended'**
  String get connect_event_has_ended;

  /// No description provided for @connect_event_join_to_practice.
  ///
  /// In en, this message translates to:
  /// **'Join the event to practice'**
  String get connect_event_join_to_practice;

  /// No description provided for @connect_event_leave.
  ///
  /// In en, this message translates to:
  /// **'Leave event'**
  String get connect_event_leave;

  /// No description provided for @connect_event_leave_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Leave this event?'**
  String get connect_event_leave_confirm_title;

  /// No description provided for @connect_event_leave_confirm_message.
  ///
  /// In en, this message translates to:
  /// **'You\'ll no longer be attending {title}. You can still view the event and attend again anytime.'**
  String connect_event_leave_confirm_message(String title);

  /// No description provided for @connect_event_participants_attending.
  ///
  /// In en, this message translates to:
  /// **'{count} participants'**
  String connect_event_participants_attending(int count);

  /// No description provided for @connect_event_participants_attended.
  ///
  /// In en, this message translates to:
  /// **'{count} attended'**
  String connect_event_participants_attended(int count);

  /// No description provided for @connect_event_participants_empty.
  ///
  /// In en, this message translates to:
  /// **'No participants yet'**
  String get connect_event_participants_empty;

  /// No description provided for @connect_event_organizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get connect_event_organizer;

  /// No description provided for @connect_event_tab_videos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get connect_event_tab_videos;

  /// No description provided for @connect_event_tab_links.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get connect_event_tab_links;

  /// No description provided for @connect_event_tab_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get connect_event_tab_about;

  /// No description provided for @connect_event_links_title.
  ///
  /// In en, this message translates to:
  /// **'More event details'**
  String get connect_event_links_title;

  /// No description provided for @connect_event_links_empty.
  ///
  /// In en, this message translates to:
  /// **'No links yet'**
  String get connect_event_links_empty;

  /// No description provided for @connect_event_link_tap_to_join.
  ///
  /// In en, this message translates to:
  /// **'Tap to join'**
  String get connect_event_link_tap_to_join;

  /// No description provided for @connect_event_link_open.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get connect_event_link_open;

  /// No description provided for @connect_event_date_tba.
  ///
  /// In en, this message translates to:
  /// **'Date to be announced'**
  String get connect_event_date_tba;

  /// No description provided for @connect_event_when.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get connect_event_when;

  /// No description provided for @connect_event_where.
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get connect_event_where;

  /// No description provided for @connect_event_practices.
  ///
  /// In en, this message translates to:
  /// **'Event practices'**
  String get connect_event_practices;

  /// No description provided for @connect_event_tab_accumulations.
  ///
  /// In en, this message translates to:
  /// **'Accumulations'**
  String get connect_event_tab_accumulations;

  /// No description provided for @connect_event_tab_recitations.
  ///
  /// In en, this message translates to:
  /// **'Recitations'**
  String get connect_event_tab_recitations;

  /// No description provided for @connect_event_add_recitations.
  ///
  /// In en, this message translates to:
  /// **'Add recitations'**
  String get connect_event_add_recitations;

  /// No description provided for @connect_event_add_recitations_message.
  ///
  /// In en, this message translates to:
  /// **'Add recitations you did with the livestream or outside this app'**
  String get connect_event_add_recitations_message;

  /// No description provided for @connect_event_every_day.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get connect_event_every_day;

  /// No description provided for @connect_event_every_weekday.
  ///
  /// In en, this message translates to:
  /// **'Every {weekday}'**
  String connect_event_every_weekday(String weekday);

  /// No description provided for @connect_event_every_month.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get connect_event_every_month;

  /// No description provided for @connect_event_every_date.
  ///
  /// In en, this message translates to:
  /// **'Every {date}'**
  String connect_event_every_date(String date);

  /// No description provided for @connect_event_about_empty.
  ///
  /// In en, this message translates to:
  /// **'No event details yet'**
  String get connect_event_about_empty;

  /// No description provided for @search_groups.
  ///
  /// In en, this message translates to:
  /// **'Search spaces'**
  String get search_groups;

  /// No description provided for @search_for_groups.
  ///
  /// In en, this message translates to:
  /// **'Search for spaces'**
  String get search_for_groups;

  /// No description provided for @no_groups_found.
  ///
  /// In en, this message translates to:
  /// **'No matching spaces found'**
  String get no_groups_found;

  /// No description provided for @explore_coming_soon_subtitle.
  ///
  /// In en, this message translates to:
  /// **'A curated space to discover practices, teachings, and community events'**
  String get explore_coming_soon_subtitle;

  /// No description provided for @learn_coming_soon_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your personal study plans, designed to fit into everyday life'**
  String get learn_coming_soon_subtitle;

  /// No description provided for @creator_featured_plan.
  ///
  /// In en, this message translates to:
  /// **'Featured plans'**
  String get creator_featured_plan;

  /// No description provided for @audio_init_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to initialize audio player. Check your connection and try again'**
  String get audio_init_error;

  /// No description provided for @meditation_audio_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load. Check your connection and try again'**
  String get meditation_audio_load_error;

  /// No description provided for @prayer_audio_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load audio. Check your connection and try again'**
  String get prayer_audio_load_error;

  /// No description provided for @home_no_series_found.
  ///
  /// In en, this message translates to:
  /// **'No series found'**
  String get home_no_series_found;

  /// No description provided for @home_no_tags_found.
  ///
  /// In en, this message translates to:
  /// **'No tags found'**
  String get home_no_tags_found;

  /// No description provided for @home_celebrated_by.
  ///
  /// In en, this message translates to:
  /// **'Celebrated by: '**
  String get home_celebrated_by;

  /// No description provided for @reader_settings_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Reader settings'**
  String get reader_settings_tooltip;

  /// No description provided for @reader_translate_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Show translation'**
  String get reader_translate_tooltip;

  /// No description provided for @reader_translate_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Translation not available for this text'**
  String get reader_translate_unavailable;

  /// No description provided for @reader_font_size_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get reader_font_size_tooltip;

  /// No description provided for @reader_version_title.
  ///
  /// In en, this message translates to:
  /// **'Version · {language}'**
  String reader_version_title(String language);

  /// No description provided for @reader_script_title.
  ///
  /// In en, this message translates to:
  /// **'Script · {language}'**
  String reader_script_title(String language);

  /// No description provided for @reader_versions_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load versions'**
  String get reader_versions_load_error;

  /// No description provided for @reader_scripts_load_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to load scripts'**
  String get reader_scripts_load_error;

  /// No description provided for @reader_languages_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load languages'**
  String get reader_languages_load_error;

  /// No description provided for @reader_no_versions_in_language.
  ///
  /// In en, this message translates to:
  /// **'No versions available in {language}'**
  String reader_no_versions_in_language(String language);

  /// No description provided for @reader_no_scripts_in_language.
  ///
  /// In en, this message translates to:
  /// **'No scripts available in {language}'**
  String reader_no_scripts_in_language(String language);

  /// No description provided for @reader_no_languages.
  ///
  /// In en, this message translates to:
  /// **'No languages available for this text'**
  String get reader_no_languages;

  /// No description provided for @reader_license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get reader_license;

  /// No description provided for @reader_version_details_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load version details'**
  String get reader_version_details_load_error;

  /// No description provided for @reader_no_version_info.
  ///
  /// In en, this message translates to:
  /// **'No additional information is available for this version'**
  String get reader_no_version_info;

  /// No description provided for @recitation_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Recitation content is currently unavailable.\nTry again later or contact support'**
  String get recitation_unavailable;

  /// No description provided for @recitation_sign_in_required.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access this recitation'**
  String get recitation_sign_in_required;

  /// No description provided for @my_recitations_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load.\nCheck your connection and try again'**
  String get my_recitations_load_error;

  /// No description provided for @recitations_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load recitations.\nTry again later'**
  String get recitations_load_error;

  /// No description provided for @text_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Type to search'**
  String get text_search_hint;

  /// No description provided for @text_search_press_button.
  ///
  /// In en, this message translates to:
  /// **'Press search button to search'**
  String get text_search_press_button;

  /// No description provided for @text_search_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to perform search.\nPlease try again'**
  String get text_search_error;

  /// No description provided for @unknown_error.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknown_error;

  /// No description provided for @create_image_share_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to share. Please try again'**
  String get create_image_share_error;

  /// No description provided for @version_search_no_results.
  ///
  /// In en, this message translates to:
  /// **'No versions found for \"{query}\"'**
  String version_search_no_results(String query);

  /// No description provided for @my_plans_sign_in_prompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your plans'**
  String get my_plans_sign_in_prompt;

  /// No description provided for @plan_starts_soon_message.
  ///
  /// In en, this message translates to:
  /// **'Starts on {date}. You can browse the content now'**
  String plan_starts_soon_message(String date);

  /// No description provided for @plan_joining_late_message.
  ///
  /// In en, this message translates to:
  /// **'Started on {date}. Feel free to complete previous days\' tasks'**
  String plan_joining_late_message(String date);

  /// No description provided for @select_language.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get select_language;

  /// No description provided for @logout_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logout_confirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmark;

  /// No description provided for @collection_audio_versions.
  ///
  /// In en, this message translates to:
  /// **'Audio versions'**
  String get collection_audio_versions;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Give feedback'**
  String get feedback;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @plans_created.
  ///
  /// In en, this message translates to:
  /// **'Plans created'**
  String get plans_created;

  /// No description provided for @ai_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get ai_confirm;

  /// No description provided for @search_no_results.
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{query}\"'**
  String search_no_results(String query);

  /// No description provided for @search_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get search_all;

  /// No description provided for @common_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @comingSoonHeadline.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoonHeadline;

  /// No description provided for @routine_title.
  ///
  /// In en, this message translates to:
  /// **'My practices'**
  String get routine_title;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @routine_empty_title.
  ///
  /// In en, this message translates to:
  /// **'Practices'**
  String get routine_empty_title;

  /// No description provided for @routine_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get routine_edit;

  /// No description provided for @routine_empty_description.
  ///
  /// In en, this message translates to:
  /// **'Explore more teachings and practices to add to your routine'**
  String get routine_empty_description;

  /// No description provided for @routine_build.
  ///
  /// In en, this message translates to:
  /// **'Build your routine'**
  String get routine_build;

  /// No description provided for @routine_add_session.
  ///
  /// In en, this message translates to:
  /// **'Add to session'**
  String get routine_add_session;

  /// No description provided for @routine_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit your routine'**
  String get routine_edit_title;

  /// No description provided for @routine_delete_block.
  ///
  /// In en, this message translates to:
  /// **'Remove block'**
  String get routine_delete_block;

  /// No description provided for @routine_session_title_hint.
  ///
  /// In en, this message translates to:
  /// **'Title...'**
  String get routine_session_title_hint;

  /// No description provided for @routine_expand_all.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get routine_expand_all;

  /// No description provided for @routine_collapse_all.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get routine_collapse_all;

  /// No description provided for @routine_delete_time_block.
  ///
  /// In en, this message translates to:
  /// **'Remove time block'**
  String get routine_delete_time_block;

  /// No description provided for @routine_add_plan.
  ///
  /// In en, this message translates to:
  /// **'Add plan'**
  String get routine_add_plan;

  /// No description provided for @routine_add_recitation.
  ///
  /// In en, this message translates to:
  /// **'Add recitation'**
  String get routine_add_recitation;

  /// No description provided for @routine_add_plan_to_routine.
  ///
  /// In en, this message translates to:
  /// **'Add to routine'**
  String get routine_add_plan_to_routine;

  /// No description provided for @routine_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load. Check your connection and try again'**
  String get routine_load_error;

  /// No description provided for @routine_empty_block_title_singular.
  ///
  /// In en, this message translates to:
  /// **'Empty time block'**
  String get routine_empty_block_title_singular;

  /// No description provided for @routine_empty_block_title_plural.
  ///
  /// In en, this message translates to:
  /// **'Empty time blocks ({count})'**
  String routine_empty_block_title_plural(int count);

  /// No description provided for @routine_empty_block_message_singular.
  ///
  /// In en, this message translates to:
  /// **'This time block is empty. Add an item, or remove it from your routine?'**
  String get routine_empty_block_message_singular;

  /// No description provided for @routine_empty_block_message_plural.
  ///
  /// In en, this message translates to:
  /// **'{count} time blocks are empty. Add items, or remove them from your routine?'**
  String routine_empty_block_message_plural(int count);

  /// No description provided for @routine_empty_block_add_items.
  ///
  /// In en, this message translates to:
  /// **'Add items'**
  String get routine_empty_block_add_items;

  /// No description provided for @routine_empty_block_delete_singular.
  ///
  /// In en, this message translates to:
  /// **'Remove block'**
  String get routine_empty_block_delete_singular;

  /// No description provided for @routine_empty_block_delete_plural.
  ///
  /// In en, this message translates to:
  /// **'Remove blocks'**
  String get routine_empty_block_delete_plural;

  /// No description provided for @routine_notification_title.
  ///
  /// In en, this message translates to:
  /// **'Make practice a habit'**
  String get routine_notification_title;

  /// No description provided for @routine_notification_description.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications so we can remind you to practice'**
  String get routine_notification_description;

  /// No description provided for @routine_notification_enable.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get routine_notification_enable;

  /// No description provided for @routine_notification_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get routine_notification_skip;

  /// No description provided for @routine_time_adjusted.
  ///
  /// In en, this message translates to:
  /// **'Adjusted to {time} ({gap}-min minimum gap)'**
  String routine_time_adjusted(String time, int gap);

  /// No description provided for @routine_add_block_label.
  ///
  /// In en, this message translates to:
  /// **'Time block'**
  String get routine_add_block_label;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with phone'**
  String get continueWithPhone;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// No description provided for @exploreAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Explore as a guest'**
  String get exploreAsGuest;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @profileError.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get profileError;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @pleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get pleaseTryAgain;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// No description provided for @noContentAvailable.
  ///
  /// In en, this message translates to:
  /// **'No content available'**
  String get noContentAvailable;

  /// No description provided for @unableToLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load. Check your connection and try again'**
  String get unableToLoad;

  /// No description provided for @somethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Check your connection and try again'**
  String get somethingWrong;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get searchResults;

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks available'**
  String get noTasks;

  /// No description provided for @taskNotFound.
  ///
  /// In en, this message translates to:
  /// **'Task not found'**
  String get taskNotFound;

  /// No description provided for @updateTaskError.
  ///
  /// In en, this message translates to:
  /// **'Unable to update task status'**
  String get updateTaskError;

  /// No description provided for @enrollError.
  ///
  /// In en, this message translates to:
  /// **'Unable to enroll you. Check your connection and try again'**
  String get enrollError;

  /// No description provided for @unenrollSuccess.
  ///
  /// In en, this message translates to:
  /// **'You have unenrolled in {planTitle}'**
  String unenrollSuccess(String planTitle);

  /// No description provided for @unenrollError.
  ///
  /// In en, this message translates to:
  /// **'Unable to unenroll you. Check your connection and try again'**
  String get unenrollError;

  /// No description provided for @unenrollGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Check your connection and try again'**
  String get unenrollGenericError;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'This is no longer available. Edit your routine to update'**
  String get notFound;

  /// No description provided for @noTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'No available time slots. Try removing a block first'**
  String get noTimeSlot;

  /// No description provided for @maxBlocks.
  ///
  /// In en, this message translates to:
  /// **'Maximum of {max} time blocks reached'**
  String maxBlocks(int max);

  /// No description provided for @duplicateItem.
  ///
  /// In en, this message translates to:
  /// **'This item is already in the block'**
  String get duplicateItem;

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove item?'**
  String get removeItem;

  /// No description provided for @removeConfirmation.
  ///
  /// In en, this message translates to:
  /// **'\"{itemName}\" will be removed from this block'**
  String removeConfirmation(String itemName);

  /// No description provided for @shareError.
  ///
  /// In en, this message translates to:
  /// **'Unable to share. Please try again'**
  String shareError(String error);

  /// No description provided for @updateOrderError.
  ///
  /// In en, this message translates to:
  /// **'Unable to update order. Please try again'**
  String get updateOrderError;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load. Check your connection and try again'**
  String get loadFailed;

  /// No description provided for @captureError.
  ///
  /// In en, this message translates to:
  /// **'Failed to capture QR code. Please try again'**
  String get captureError;

  /// No description provided for @qrShareError.
  ///
  /// In en, this message translates to:
  /// **'Unable to share QR code. Try again later'**
  String get qrShareError;

  /// No description provided for @errorDetail.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorDetail(String error);

  /// No description provided for @missedDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural,\n=0 {0 missed days}\n=1 {1 missed day}\nother {{count} missed days}\n}'**
  String missedDaysCount(int count);

  /// No description provided for @plan_status_on_track.
  ///
  /// In en, this message translates to:
  /// **'On track!'**
  String get plan_status_on_track;

  /// No description provided for @start_now.
  ///
  /// In en, this message translates to:
  /// **'Start now'**
  String get start_now;

  /// No description provided for @plan_enroll.
  ///
  /// In en, this message translates to:
  /// **'Enroll'**
  String get plan_enroll;

  /// No description provided for @show_second_version.
  ///
  /// In en, this message translates to:
  /// **'Show second version'**
  String get show_second_version;

  /// No description provided for @enable_add_msg.
  ///
  /// In en, this message translates to:
  /// **'Enable to add a translation or transliteration alongside the main text'**
  String get enable_add_msg;

  /// No description provided for @main_version.
  ///
  /// In en, this message translates to:
  /// **'Main version'**
  String get main_version;

  /// No description provided for @second_version.
  ///
  /// In en, this message translates to:
  /// **'Second version'**
  String get second_version;

  /// No description provided for @second_version_msg.
  ///
  /// In en, this message translates to:
  /// **'The second version will appear below each verse of the main text'**
  String get second_version_msg;

  /// No description provided for @root_text.
  ///
  /// In en, this message translates to:
  /// **'Root text'**
  String get root_text;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Versions'**
  String get version;

  /// No description provided for @parallel_version.
  ///
  /// In en, this message translates to:
  /// **'Parallel version'**
  String get parallel_version;

  /// No description provided for @reader_languages_title.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get reader_languages_title;

  /// No description provided for @reader_sections_title.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get reader_sections_title;

  /// No description provided for @reader_original_label.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get reader_original_label;

  /// No description provided for @reader_translation_label.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get reader_translation_label;

  /// No description provided for @version_not_available.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get version_not_available;

  /// No description provided for @read_full_text.
  ///
  /// In en, this message translates to:
  /// **'Read full text'**
  String get read_full_text;

  /// No description provided for @reader_source_label.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get reader_source_label;

  /// No description provided for @reader_license_label.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get reader_license_label;

  /// No description provided for @series_stats.
  ///
  /// In en, this message translates to:
  /// **'{planCount} CHAPTERS · {totalDays} DAYS'**
  String series_stats(int planCount, int totalDays);

  /// No description provided for @force_update_title.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get force_update_title;

  /// No description provided for @force_update_message.
  ///
  /// In en, this message translates to:
  /// **'A new version of the app is available. Please update to continue'**
  String get force_update_message;

  /// No description provided for @force_update_button.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get force_update_button;

  /// No description provided for @settings_section_personalisation.
  ///
  /// In en, this message translates to:
  /// **'PERSONALIZATION'**
  String get settings_section_personalisation;

  /// No description provided for @settings_section_more.
  ///
  /// In en, this message translates to:
  /// **'MORE'**
  String get settings_section_more;

  /// No description provided for @settings_section_account.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get settings_section_account;

  /// No description provided for @settings_edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get settings_edit_profile;

  /// No description provided for @settings_theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settings_theme;

  /// No description provided for @settings_notification_row.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settings_notification_row;

  /// No description provided for @settings_feedback_row.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get settings_feedback_row;

  /// No description provided for @edit_profile_title.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get edit_profile_title;

  /// No description provided for @edit_profile_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get edit_profile_save;

  /// No description provided for @edit_profile_first_name.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get edit_profile_first_name;

  /// No description provided for @edit_profile_last_name.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get edit_profile_last_name;

  /// No description provided for @edit_profile_bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get edit_profile_bio;

  /// No description provided for @edit_profile_bio_hint.
  ///
  /// In en, this message translates to:
  /// **'Share a little about yourself'**
  String get edit_profile_bio_hint;

  /// No description provided for @edit_profile_delete_account.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get edit_profile_delete_account;

  /// No description provided for @edit_profile_photo_not_uploaded.
  ///
  /// In en, this message translates to:
  /// **'Photo not uploaded'**
  String get edit_profile_photo_not_uploaded;

  /// No description provided for @edit_profile_photo_too_large.
  ///
  /// In en, this message translates to:
  /// **'Image is too large. Please choose a photo under 1 MB and try again'**
  String get edit_profile_photo_too_large;

  /// No description provided for @edit_profile_photo_upload_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not upload your photo. Please try again'**
  String get edit_profile_photo_upload_failed;

  /// No description provided for @edit_profile_choose_from_library.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get edit_profile_choose_from_library;

  /// No description provided for @edit_profile_take_photo.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get edit_profile_take_photo;

  /// No description provided for @edit_profile_offline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Connect to the internet and try again'**
  String get edit_profile_offline;

  /// No description provided for @edit_profile_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your changes. Please try again'**
  String get edit_profile_save_failed;

  /// No description provided for @edit_profile_traditions.
  ///
  /// In en, this message translates to:
  /// **'Traditions'**
  String get edit_profile_traditions;

  /// No description provided for @edit_profile_choose_traditions.
  ///
  /// In en, this message translates to:
  /// **'Choose your traditions'**
  String get edit_profile_choose_traditions;

  /// No description provided for @edit_profile_tradition_remove_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove tradition. Please try again'**
  String get edit_profile_tradition_remove_failed;

  /// No description provided for @edit_profile_tradition_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save traditions. Please try again'**
  String get edit_profile_tradition_save_failed;

  /// No description provided for @username_label.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username_label;

  /// No description provided for @username_taken.
  ///
  /// In en, this message translates to:
  /// **'Someone already used this name'**
  String get username_taken;

  /// No description provided for @username_available_label.
  ///
  /// In en, this message translates to:
  /// **'Available:'**
  String get username_available_label;

  /// No description provided for @username_check_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to check username. Try again'**
  String get username_check_error;

  /// No description provided for @username_invalid_format.
  ///
  /// In en, this message translates to:
  /// **'Invalid username format'**
  String get username_invalid_format;

  /// No description provided for @username_min_length.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get username_min_length;

  /// No description provided for @username_max_length.
  ///
  /// In en, this message translates to:
  /// **'Username must be 30 characters or less'**
  String get username_max_length;

  /// No description provided for @username_no_spaces.
  ///
  /// In en, this message translates to:
  /// **'Username cannot contain spaces'**
  String get username_no_spaces;

  /// No description provided for @username_invalid_chars.
  ///
  /// In en, this message translates to:
  /// **'Only letters, numbers, _ . - are allowed'**
  String get username_invalid_chars;

  /// No description provided for @username_must_start_alphanumeric.
  ///
  /// In en, this message translates to:
  /// **'Username must start with a letter or number'**
  String get username_must_start_alphanumeric;

  /// No description provided for @username_must_end_alphanumeric.
  ///
  /// In en, this message translates to:
  /// **'Username must end with a letter or number'**
  String get username_must_end_alphanumeric;

  /// No description provided for @person_name_min_length.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 1 character'**
  String get person_name_min_length;

  /// No description provided for @person_name_max_length.
  ///
  /// In en, this message translates to:
  /// **'Must be 50 characters or less'**
  String get person_name_max_length;

  /// No description provided for @person_name_invalid_chars.
  ///
  /// In en, this message translates to:
  /// **'Only letters, spaces, hyphens, and apostrophes are allowed'**
  String get person_name_invalid_chars;

  /// No description provided for @about_title.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about_title;

  /// No description provided for @about_connect_with_us.
  ///
  /// In en, this message translates to:
  /// **'Connect with us...'**
  String get about_connect_with_us;

  /// No description provided for @about_description.
  ///
  /// In en, this message translates to:
  /// **'We help Buddhists do less harm, more good, and know their own mind better by learning, practicing and connecting daily.'**
  String get about_description;

  /// No description provided for @about_social_website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get about_social_website;

  /// No description provided for @me_guest_headline.
  ///
  /// In en, this message translates to:
  /// **'Access the full experience'**
  String get me_guest_headline;

  /// No description provided for @me_guest_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a free account to save your progress'**
  String get me_guest_subtitle;

  /// No description provided for @me_my_stats.
  ///
  /// In en, this message translates to:
  /// **'My stats'**
  String get me_my_stats;

  /// No description provided for @me_day_streak.
  ///
  /// In en, this message translates to:
  /// **'{count}-day streak'**
  String me_day_streak(int count);

  /// No description provided for @me_best_streak.
  ///
  /// In en, this message translates to:
  /// **'Longest streak: {count} days'**
  String me_best_streak(int count);

  /// No description provided for @accumulations.
  ///
  /// In en, this message translates to:
  /// **'Accumulations'**
  String get accumulations;

  /// No description provided for @accumulations_search.
  ///
  /// In en, this message translates to:
  /// **'Search for accumulations...'**
  String get accumulations_search;

  /// No description provided for @accumulations_search_for.
  ///
  /// In en, this message translates to:
  /// **'Search for accumulations'**
  String get accumulations_search_for;

  /// No description provided for @accumulations_no_found.
  ///
  /// In en, this message translates to:
  /// **'No accumulations found'**
  String get accumulations_no_found;

  /// No description provided for @me_accumulation.
  ///
  /// In en, this message translates to:
  /// **'Total accumulations'**
  String get me_accumulation;

  /// No description provided for @me_counts.
  ///
  /// In en, this message translates to:
  /// **'counts'**
  String get me_counts;

  /// No description provided for @me_minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get me_minutes;

  /// No description provided for @me_hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get me_hours;

  /// No description provided for @me_total_meditation_time.
  ///
  /// In en, this message translates to:
  /// **'Total meditation time'**
  String get me_total_meditation_time;

  /// No description provided for @me_days_plan_practiced_suffix.
  ///
  /// In en, this message translates to:
  /// **'total plan days completed'**
  String get me_days_plan_practiced_suffix;

  /// No description provided for @me_streak_share_message.
  ///
  /// In en, this message translates to:
  /// **'I\'m on a {count}-day streak on {appName}!'**
  String me_streak_share_message(int count, String appName);

  /// No description provided for @me_streak_share_quote.
  ///
  /// In en, this message translates to:
  /// **'My current streak on WeBuddhist!'**
  String get me_streak_share_quote;

  /// No description provided for @me_streak_days_count.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String me_streak_days_count(int count);

  /// No description provided for @share_this_streak.
  ///
  /// In en, this message translates to:
  /// **'Share my streak'**
  String get share_this_streak;

  /// No description provided for @me_streak_share_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to share streak. Please try again'**
  String get me_streak_share_error;

  /// No description provided for @delete_account_title.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get delete_account_title;

  /// No description provided for @delete_account_description.
  ///
  /// In en, this message translates to:
  /// **'If you delete your account, all your information, history, and personalized settings on WeBuddhist will be permanently deleted. Note that this action is irreversible. To proceed, tap the button below.'**
  String get delete_account_description;

  /// No description provided for @delete_account_button.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get delete_account_button;

  /// No description provided for @delete_account_confirm_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your WeBuddhist account?'**
  String get delete_account_confirm_message;

  /// No description provided for @legal_title.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal_title;

  /// No description provided for @legal_terms_of_service.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get legal_terms_of_service;

  /// No description provided for @legal_privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get legal_privacy_policy;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @calendar_title.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar_title;

  /// No description provided for @calendar_upcoming_events.
  ///
  /// In en, this message translates to:
  /// **'Upcoming events'**
  String get calendar_upcoming_events;

  /// No description provided for @calendar_day_short.
  ///
  /// In en, this message translates to:
  /// **'DAY'**
  String get calendar_day_short;

  /// No description provided for @calendar_day_label.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get calendar_day_label;

  /// No description provided for @calendar_day_month.
  ///
  /// In en, this message translates to:
  /// **'Day {day} · Month {month}'**
  String calendar_day_month(int day, int month);

  /// No description provided for @calendar_lunar_month.
  ///
  /// In en, this message translates to:
  /// **'{ordinal} lunar month'**
  String calendar_lunar_month(String ordinal);

  /// No description provided for @moon_phase_new_moon.
  ///
  /// In en, this message translates to:
  /// **'New moon'**
  String get moon_phase_new_moon;

  /// No description provided for @moon_phase_waxing_crescent.
  ///
  /// In en, this message translates to:
  /// **'Waxing crescent'**
  String get moon_phase_waxing_crescent;

  /// No description provided for @moon_phase_first_quarter.
  ///
  /// In en, this message translates to:
  /// **'First quarter'**
  String get moon_phase_first_quarter;

  /// No description provided for @moon_phase_waxing_gibbous.
  ///
  /// In en, this message translates to:
  /// **'Waxing gibbous'**
  String get moon_phase_waxing_gibbous;

  /// No description provided for @moon_phase_full_moon.
  ///
  /// In en, this message translates to:
  /// **'Full moon'**
  String get moon_phase_full_moon;

  /// No description provided for @moon_phase_waning_gibbous.
  ///
  /// In en, this message translates to:
  /// **'Waning gibbous'**
  String get moon_phase_waning_gibbous;

  /// No description provided for @moon_phase_last_quarter.
  ///
  /// In en, this message translates to:
  /// **'Last quarter'**
  String get moon_phase_last_quarter;

  /// No description provided for @moon_phase_waning_crescent.
  ///
  /// In en, this message translates to:
  /// **'Waning crescent'**
  String get moon_phase_waning_crescent;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @group_member.
  ///
  /// In en, this message translates to:
  /// **'member'**
  String get group_member;

  /// No description provided for @group_members.
  ///
  /// In en, this message translates to:
  /// **'members'**
  String get group_members;

  /// No description provided for @group_tab_members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get group_tab_members;

  /// No description provided for @group_tab_followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get group_tab_followers;

  /// No description provided for @group_members_heading.
  ///
  /// In en, this message translates to:
  /// **'Members ({count})'**
  String group_members_heading(int count);

  /// No description provided for @group_followers_heading.
  ///
  /// In en, this message translates to:
  /// **'Followers({count})'**
  String group_followers_heading(int count);

  /// No description provided for @group_invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get group_invite;

  /// No description provided for @group_notifications_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get group_notifications_title;

  /// No description provided for @group_notifications_chat.
  ///
  /// In en, this message translates to:
  /// **'Space chat'**
  String get group_notifications_chat;

  /// No description provided for @group_notifications_content.
  ///
  /// In en, this message translates to:
  /// **'Space content'**
  String get group_notifications_content;

  /// No description provided for @group_notifications_master_off.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off for the app'**
  String get group_notifications_master_off;

  /// No description provided for @group_notifications_open_settings.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get group_notifications_open_settings;

  /// No description provided for @group_notifications_update_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update notification settings. Try again'**
  String get group_notifications_update_failed;

  /// No description provided for @group_notifications_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load notification settings'**
  String get group_notifications_load_failed;

  /// No description provided for @group_chat_mute_notifications.
  ///
  /// In en, this message translates to:
  /// **'Mute chat notifications'**
  String get group_chat_mute_notifications;

  /// No description provided for @group_chat_unmute_notifications.
  ///
  /// In en, this message translates to:
  /// **'Unmute chat notifications'**
  String get group_chat_unmute_notifications;

  /// No description provided for @group_chat_notifications_muted.
  ///
  /// In en, this message translates to:
  /// **'Chat notifications muted'**
  String get group_chat_notifications_muted;

  /// No description provided for @group_chat_notifications_unmuted.
  ///
  /// In en, this message translates to:
  /// **'Chat notifications on'**
  String get group_chat_notifications_unmuted;

  /// No description provided for @group_leave_confirm_message.
  ///
  /// In en, this message translates to:
  /// **'You\'ll stop getting messages and updates from this space'**
  String get group_leave_confirm_message;

  /// No description provided for @group_leave_space.
  ///
  /// In en, this message translates to:
  /// **'Leave space'**
  String get group_leave_space;

  /// No description provided for @group_leave_space_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Leave this space?'**
  String get group_leave_space_confirm_title;

  /// No description provided for @group_leave_space_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t leave the space. Try again'**
  String get group_leave_space_failed;

  /// No description provided for @group_request_to_join.
  ///
  /// In en, this message translates to:
  /// **'Ask to join'**
  String get group_request_to_join;

  /// No description provided for @group_request.
  ///
  /// In en, this message translates to:
  /// **'Ask to join'**
  String get group_request;

  /// No description provided for @group_request_sent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get group_request_sent;

  /// No description provided for @group_join_request_title.
  ///
  /// In en, this message translates to:
  /// **'Ask to join'**
  String get group_join_request_title;

  /// No description provided for @group_join_request_message_label.
  ///
  /// In en, this message translates to:
  /// **'Message (optional)'**
  String get group_join_request_message_label;

  /// No description provided for @group_join_request_message_hint.
  ///
  /// In en, this message translates to:
  /// **'How do you practice, or who invited you?'**
  String get group_join_request_message_hint;

  /// No description provided for @group_join_request_send.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get group_join_request_send;

  /// No description provided for @group_join_request_sent_snackbar.
  ///
  /// In en, this message translates to:
  /// **'Request sent. An admin will review it'**
  String get group_join_request_sent_snackbar;

  /// No description provided for @group_join_request_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to send request. Please try again'**
  String get group_join_request_error;

  /// No description provided for @group_join_requests_title.
  ///
  /// In en, this message translates to:
  /// **'Join requests'**
  String get group_join_requests_title;

  /// No description provided for @group_join_requests_admit.
  ///
  /// In en, this message translates to:
  /// **'Admit'**
  String get group_join_requests_admit;

  /// No description provided for @group_join_requests_deny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get group_join_requests_deny;

  /// No description provided for @group_join_requests_empty.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get group_join_requests_empty;

  /// No description provided for @group_join_requests_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load join requests. Please try again'**
  String get group_join_requests_load_error;

  /// No description provided for @group_join_requests_admit_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to admit this request. Please try again'**
  String get group_join_requests_admit_error;

  /// No description provided for @group_join_requests_deny_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to deny this request. Please try again'**
  String get group_join_requests_deny_error;

  /// No description provided for @group_reports_title.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get group_reports_title;

  /// No description provided for @group_reports_section_posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get group_reports_section_posts;

  /// No description provided for @group_reports_section_comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get group_reports_section_comments;

  /// No description provided for @group_reports_section_messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get group_reports_section_messages;

  /// No description provided for @group_reports_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural,\n=1 {1 report}\nother {{count} reports}\n}'**
  String group_reports_count(int count);

  /// No description provided for @group_reports_view_post.
  ///
  /// In en, this message translates to:
  /// **'View post'**
  String get group_reports_view_post;

  /// No description provided for @group_reports_view_message.
  ///
  /// In en, this message translates to:
  /// **'View message'**
  String get group_reports_view_message;

  /// No description provided for @group_reports_delete_post.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get group_reports_delete_post;

  /// No description provided for @group_reports_delete_comment.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get group_reports_delete_comment;

  /// No description provided for @group_reports_delete_message.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get group_reports_delete_message;

  /// No description provided for @group_reports_empty.
  ///
  /// In en, this message translates to:
  /// **'No reports to review'**
  String get group_reports_empty;

  /// No description provided for @group_reports_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load reports. Please try again'**
  String get group_reports_load_error;

  /// No description provided for @group_reports_delete_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get group_reports_delete_confirm_title;

  /// No description provided for @group_reports_delete_message_confirm.
  ///
  /// In en, this message translates to:
  /// **'This message will be permanently removed'**
  String get group_reports_delete_message_confirm;

  /// No description provided for @group_reports_message_removed.
  ///
  /// In en, this message translates to:
  /// **'Message has been removed'**
  String get group_reports_message_removed;

  /// No description provided for @group_reports_delete_message_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete message. Please try again'**
  String get group_reports_delete_message_error;

  /// No description provided for @group_members_only_title.
  ///
  /// In en, this message translates to:
  /// **'Members only'**
  String get group_members_only_title;

  /// No description provided for @group_members_only_message.
  ///
  /// In en, this message translates to:
  /// **'Join this space to see its content'**
  String get group_members_only_message;

  /// No description provided for @group_join_request_waiting_title.
  ///
  /// In en, this message translates to:
  /// **'Waiting on an admin'**
  String get group_join_request_waiting_title;

  /// No description provided for @group_join_request_waiting_message.
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you when your request is reviewed'**
  String get group_join_request_waiting_message;

  /// No description provided for @group_members_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load members. Please try again'**
  String get group_members_load_error;

  /// No description provided for @group_followers_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load followers. Please try again.'**
  String get group_followers_load_error;

  /// No description provided for @group_members_empty.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get group_members_empty;

  /// No description provided for @group_member_admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get group_member_admin;

  /// No description provided for @group_member_owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get group_member_owner;

  /// No description provided for @group_remove_member.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String group_remove_member(String name);

  /// No description provided for @group_remove_member_title.
  ///
  /// In en, this message translates to:
  /// **'Remove from space?'**
  String get group_remove_member_title;

  /// No description provided for @group_remove_member_message.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed from this space and unable to rejoin it until the ban is lifted'**
  String group_remove_member_message(String name);

  /// No description provided for @group_remove_member_blocked_for.
  ///
  /// In en, this message translates to:
  /// **'Blocked for:'**
  String get group_remove_member_blocked_for;

  /// No description provided for @group_remove_member_duration_day.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get group_remove_member_duration_day;

  /// No description provided for @group_remove_member_duration_days.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String group_remove_member_duration_days(int count);

  /// No description provided for @group_remove_member_duration_year.
  ///
  /// In en, this message translates to:
  /// **'1 year'**
  String get group_remove_member_duration_year;

  /// No description provided for @group_remove_member_reason_label.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get group_remove_member_reason_label;

  /// No description provided for @group_remove_member_reason_hint.
  ///
  /// In en, this message translates to:
  /// **'Something else...'**
  String get group_remove_member_reason_hint;

  /// No description provided for @group_remove_member_action.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get group_remove_member_action;

  /// No description provided for @group_remove_member_success.
  ///
  /// In en, this message translates to:
  /// **'{name} was removed from the space'**
  String group_remove_member_success(String name);

  /// No description provided for @group_remove_member_error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove this member. Try again'**
  String get group_remove_member_error;

  /// No description provided for @group_join_banned_until.
  ///
  /// In en, this message translates to:
  /// **'You were removed from this space and can\'t rejoin until {date}'**
  String group_join_banned_until(String date);

  /// No description provided for @group_join_banned.
  ///
  /// In en, this message translates to:
  /// **'You were removed from this space and can\'t rejoin until the ban is lifted'**
  String get group_join_banned;

  /// No description provided for @group_removed_title.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been removed from this space'**
  String get group_removed_title;

  /// No description provided for @group_removed_message.
  ///
  /// In en, this message translates to:
  /// **'An admin from {group} removed you from this space. You won\'t be able to view its posts, events and practices, or ask to rejoin for {duration}.'**
  String group_removed_message(String group, String duration);

  /// No description provided for @group_removed_message_no_date.
  ///
  /// In en, this message translates to:
  /// **'An admin from {group} removed you from this space. You won\'t be able to view its posts, events and practices, or ask to rejoin'**
  String group_removed_message_no_date(String group);

  /// No description provided for @group_removed_rejoin_label.
  ///
  /// In en, this message translates to:
  /// **'You can ask to join to this space on'**
  String get group_removed_rejoin_label;

  /// No description provided for @group_removed_rejoin_value.
  ///
  /// In en, this message translates to:
  /// **'{date} · {remaining}'**
  String group_removed_rejoin_value(String date, String remaining);

  /// No description provided for @group_removed_day_left.
  ///
  /// In en, this message translates to:
  /// **'1 day left'**
  String get group_removed_day_left;

  /// No description provided for @group_removed_days_left.
  ///
  /// In en, this message translates to:
  /// **'{count} days left'**
  String group_removed_days_left(int count);

  /// No description provided for @group_removed_last_day.
  ///
  /// In en, this message translates to:
  /// **'Less than a day left'**
  String get group_removed_last_day;

  /// No description provided for @group_followers_empty.
  ///
  /// In en, this message translates to:
  /// **'No followers yet'**
  String get group_followers_empty;

  /// No description provided for @group_follower.
  ///
  /// In en, this message translates to:
  /// **'follower'**
  String get group_follower;

  /// No description provided for @group_followers.
  ///
  /// In en, this message translates to:
  /// **'followers'**
  String get group_followers;

  /// No description provided for @group_links_title.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get group_links_title;

  /// No description provided for @group_about_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get group_about_description;

  /// No description provided for @group_about_empty.
  ///
  /// In en, this message translates to:
  /// **'No information available yet'**
  String get group_about_empty;

  /// No description provided for @group_and_more_links.
  ///
  /// In en, this message translates to:
  /// **'and {count} more links'**
  String group_and_more_links(int count);

  /// No description provided for @group_practice_with_us.
  ///
  /// In en, this message translates to:
  /// **'Practice with us'**
  String get group_practice_with_us;

  /// No description provided for @series_practicing_with_group.
  ///
  /// In en, this message translates to:
  /// **'Practicing with {groupName}'**
  String series_practicing_with_group(String groupName);

  /// No description provided for @group_change_practice_title.
  ///
  /// In en, this message translates to:
  /// **'Change practice space'**
  String get group_change_practice_title;

  /// No description provided for @group_change_practice_message.
  ///
  /// In en, this message translates to:
  /// **'You are already practicing this plan with another space. Would you like to change your practice space?'**
  String get group_change_practice_message;

  /// No description provided for @group_join_to_contribute.
  ///
  /// In en, this message translates to:
  /// **'Join to contribute'**
  String get group_join_to_contribute;

  /// No description provided for @group_accumulator_join_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to join accumulation. Please try again'**
  String get group_accumulator_join_error;

  /// No description provided for @group_accumulator_join_before_practice.
  ///
  /// In en, this message translates to:
  /// **'Join this accumulation before adding it to your practices'**
  String get group_accumulator_join_before_practice;

  /// No description provided for @group_accumulator_participants.
  ///
  /// In en, this message translates to:
  /// **'{count} participants'**
  String group_accumulator_participants(int count);

  /// No description provided for @group_accumulator_leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get group_accumulator_leaderboard;

  /// No description provided for @group_accumulator_my_contributions.
  ///
  /// In en, this message translates to:
  /// **'My contributions'**
  String get group_accumulator_my_contributions;

  /// No description provided for @group_accumulator_recited.
  ///
  /// In en, this message translates to:
  /// **'Recitations'**
  String get group_accumulator_recited;

  /// No description provided for @group_accumulator_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get group_accumulator_total;

  /// No description provided for @group_accumulator_contributions_empty.
  ///
  /// In en, this message translates to:
  /// **'Join this accumulation to track your contributions'**
  String get group_accumulator_contributions_empty;

  /// No description provided for @group_accumulator_leaderboard_empty.
  ///
  /// In en, this message translates to:
  /// **'No recitations yet'**
  String get group_accumulator_leaderboard_empty;

  /// No description provided for @group_accumulator_recite_now.
  ///
  /// In en, this message translates to:
  /// **'Recite now'**
  String get group_accumulator_recite_now;

  /// No description provided for @group_accumulator_view_practice.
  ///
  /// In en, this message translates to:
  /// **'View practice'**
  String get group_accumulator_view_practice;

  /// No description provided for @group_accumulator_chant_again.
  ///
  /// In en, this message translates to:
  /// **'Chant again'**
  String get group_accumulator_chant_again;

  /// No description provided for @group_accumulator_finish_session.
  ///
  /// In en, this message translates to:
  /// **'Finish session'**
  String get group_accumulator_finish_session;

  /// No description provided for @group_accumulator_offline_recitation.
  ///
  /// In en, this message translates to:
  /// **'Offline recitation'**
  String get group_accumulator_offline_recitation;

  /// No description provided for @group_accumulator_add_offline_chants_title.
  ///
  /// In en, this message translates to:
  /// **'Add offline chants:'**
  String get group_accumulator_add_offline_chants_title;

  /// No description provided for @group_accumulator_add_offline_chants_message.
  ///
  /// In en, this message translates to:
  /// **'Add the number of chants you did outside the app'**
  String get group_accumulator_add_offline_chants_message;

  /// No description provided for @group_accumulator_session_complete.
  ///
  /// In en, this message translates to:
  /// **'Session complete!'**
  String get group_accumulator_session_complete;

  /// No description provided for @group_accumulator_session_recitations.
  ///
  /// In en, this message translates to:
  /// **'You completed {count} recitations this session'**
  String group_accumulator_session_recitations(int count);

  /// No description provided for @group_accumulator_session_share_message.
  ///
  /// In en, this message translates to:
  /// **'I completed {count} recitations in \"{accumulation}\", an accumulation by {group} on WeBuddhist. Come join me!'**
  String group_accumulator_session_share_message(
    int count,
    String accumulation,
    String group,
  );

  /// No description provided for @group_accumulator_session_share_message_no_group.
  ///
  /// In en, this message translates to:
  /// **'I completed {count} recitations in the \"{accumulation}\" accumulation on WeBuddhist. Come join me!'**
  String group_accumulator_session_share_message_no_group(
    int count,
    String accumulation,
  );

  /// No description provided for @group_accumulator_session_share_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to share session. Please try again'**
  String get group_accumulator_session_share_error;

  /// No description provided for @group_recitation_collection_share_message.
  ///
  /// In en, this message translates to:
  /// **'Check out \"{collection}\", a recitation collection by {group} on WeBuddhist. Join us in practice!'**
  String group_recitation_collection_share_message(
    String collection,
    String group,
  );

  /// No description provided for @group_recitation_collection_share_message_no_group.
  ///
  /// In en, this message translates to:
  /// **'Check out the recitation collection \"{collection}\" on WeBuddhist. Join us in practice!'**
  String group_recitation_collection_share_message_no_group(String collection);

  /// No description provided for @group_recitation_collection_completed_title.
  ///
  /// In en, this message translates to:
  /// **'{collection} completed'**
  String group_recitation_collection_completed_title(String collection);

  /// No description provided for @group_recitation_collection_dedication.
  ///
  /// In en, this message translates to:
  /// **'By this merit, may all beings\nbe free from suffering'**
  String get group_recitation_collection_dedication;

  /// No description provided for @share_this_quote.
  ///
  /// In en, this message translates to:
  /// **'Share this quote'**
  String get share_this_quote;

  /// No description provided for @shared_from.
  ///
  /// In en, this message translates to:
  /// **'Shared from'**
  String get shared_from;

  /// No description provided for @verse_share_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to share quote. Please try again'**
  String get verse_share_error;

  /// No description provided for @verse_comments_title.
  ///
  /// In en, this message translates to:
  /// **'Comments · {count}'**
  String verse_comments_title(int count);

  /// No description provided for @verse_likes_title.
  ///
  /// In en, this message translates to:
  /// **'Likes · {count}'**
  String verse_likes_title(int count);

  /// No description provided for @verse_like_failed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update like. Please try again'**
  String get verse_like_failed;

  /// No description provided for @verse_comment_failed.
  ///
  /// In en, this message translates to:
  /// **'Unable to post comment. Please try again'**
  String get verse_comment_failed;

  /// No description provided for @verse_comment_replying_to.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String verse_comment_replying_to(String name);

  /// No description provided for @share_app_message.
  ///
  /// In en, this message translates to:
  /// **'I\'ve been using this app to build a daily Buddhist practice, and thought you\'d love it.'**
  String get share_app_message;

  /// No description provided for @share_streak_message.
  ///
  /// In en, this message translates to:
  /// **'I\'ve been building a daily practice habit and wanted to share it with you. It\'s easier to keep it up with a friend. Join me on WeBuddhist.'**
  String get share_streak_message;

  /// No description provided for @share_chant_message.
  ///
  /// In en, this message translates to:
  /// **'I wanted to share this chant with you. You can practice it and find a whole library of other chants and texts on WeBuddhist.'**
  String get share_chant_message;

  /// No description provided for @share_quote_message.
  ///
  /// In en, this message translates to:
  /// **'I liked this quote from WeBuddhist and wanted to share it with you. Read more such insightful quotes on the WeBuddhist app.'**
  String get share_quote_message;

  /// No description provided for @share_poem_message.
  ///
  /// In en, this message translates to:
  /// **'I liked this poem from WeBuddhist and wanted to share it with you.'**
  String get share_poem_message;

  /// No description provided for @share_poem_title.
  ///
  /// In en, this message translates to:
  /// **'“{title}”'**
  String share_poem_title(String title);

  /// No description provided for @share_mala_message.
  ///
  /// In en, this message translates to:
  /// **'I\'ve been using this digital mala on WeBuddhist and wanted to share it with you. It\'s an easy way to practice wherever you go.'**
  String get share_mala_message;

  /// No description provided for @share_passage_message.
  ///
  /// In en, this message translates to:
  /// **'I liked this passage and wanted to share it with you. You can read the whole quote in context on WeBuddhist.'**
  String get share_passage_message;

  /// No description provided for @share_timer_message.
  ///
  /// In en, this message translates to:
  /// **'I wanted to share this meditation timer from WeBuddhist with you. It makes it easy to build a meditation practice.'**
  String get share_timer_message;

  /// No description provided for @share_plan_message.
  ///
  /// In en, this message translates to:
  /// **'I\'m following this Buddhist practice plan and wanted to share it with you. You can join me for free on WeBuddhist.'**
  String get share_plan_message;

  /// No description provided for @share_plan_subject.
  ///
  /// In en, this message translates to:
  /// **'Join me on WeBuddhist'**
  String get share_plan_subject;

  /// No description provided for @share_group_invite_message.
  ///
  /// In en, this message translates to:
  /// **'Join me in this space. Let\'s practice together on WeBuddhist!'**
  String get share_group_invite_message;

  /// No description provided for @weekday_monday.
  ///
  /// In en, this message translates to:
  /// **'MON'**
  String get weekday_monday;

  /// No description provided for @weekday_tuesday.
  ///
  /// In en, this message translates to:
  /// **'TUE'**
  String get weekday_tuesday;

  /// No description provided for @weekday_wednesday.
  ///
  /// In en, this message translates to:
  /// **'WED'**
  String get weekday_wednesday;

  /// No description provided for @weekday_thursday.
  ///
  /// In en, this message translates to:
  /// **'THU'**
  String get weekday_thursday;

  /// No description provided for @weekday_friday.
  ///
  /// In en, this message translates to:
  /// **'FRI'**
  String get weekday_friday;

  /// No description provided for @weekday_saturday.
  ///
  /// In en, this message translates to:
  /// **'SAT'**
  String get weekday_saturday;

  /// No description provided for @weekday_sunday.
  ///
  /// In en, this message translates to:
  /// **'SUN'**
  String get weekday_sunday;

  /// No description provided for @reader_search_failed.
  ///
  /// In en, this message translates to:
  /// **'Search failed.\nPlease try again'**
  String get reader_search_failed;

  /// No description provided for @reader_swipe_up_for_more.
  ///
  /// In en, this message translates to:
  /// **'Swipe up for more'**
  String get reader_swipe_up_for_more;

  /// No description provided for @reader_videos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get reader_videos;

  /// No description provided for @reader_about_this_version.
  ///
  /// In en, this message translates to:
  /// **'About this version'**
  String get reader_about_this_version;

  /// No description provided for @reader_version_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 version} other{{count} versions}}'**
  String reader_version_count(int count);

  /// No description provided for @mala_no_mantras.
  ///
  /// In en, this message translates to:
  /// **'No mantras available'**
  String get mala_no_mantras;

  /// No description provided for @mala_count_load_error.
  ///
  /// In en, this message translates to:
  /// **'Could not load your count'**
  String get mala_count_load_error;

  /// No description provided for @mala_mantra_label.
  ///
  /// In en, this message translates to:
  /// **'Mantra'**
  String get mala_mantra_label;

  /// No description provided for @bookmarks_empty_all_title.
  ///
  /// In en, this message translates to:
  /// **'Nothing bookmarked yet'**
  String get bookmarks_empty_all_title;

  /// No description provided for @bookmarks_empty_all_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmark anything to save it here'**
  String get bookmarks_empty_all_subtitle;

  /// No description provided for @bookmarks_empty_plans_title.
  ///
  /// In en, this message translates to:
  /// **'No plans bookmarked yet'**
  String get bookmarks_empty_plans_title;

  /// No description provided for @bookmarks_empty_plans_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmark one to save it here'**
  String get bookmarks_empty_plans_subtitle;

  /// No description provided for @bookmarks_empty_malas_title.
  ///
  /// In en, this message translates to:
  /// **'No malas bookmarked yet'**
  String get bookmarks_empty_malas_title;

  /// No description provided for @bookmarks_empty_malas_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmark one to save it here'**
  String get bookmarks_empty_malas_subtitle;

  /// No description provided for @bookmarks_empty_group_accumulations_title.
  ///
  /// In en, this message translates to:
  /// **'No space accumulations bookmarked yet'**
  String get bookmarks_empty_group_accumulations_title;

  /// No description provided for @bookmarks_empty_group_accumulations_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmark one to save it here'**
  String get bookmarks_empty_group_accumulations_subtitle;

  /// No description provided for @bookmarks_empty_timers_title.
  ///
  /// In en, this message translates to:
  /// **'No timers bookmarked yet'**
  String get bookmarks_empty_timers_title;

  /// No description provided for @bookmarks_empty_timers_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmark one to save it here'**
  String get bookmarks_empty_timers_subtitle;

  /// No description provided for @bookmarks_empty_texts_title.
  ///
  /// In en, this message translates to:
  /// **'No texts bookmarked yet'**
  String get bookmarks_empty_texts_title;

  /// No description provided for @bookmarks_empty_texts_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmark one to save it here'**
  String get bookmarks_empty_texts_subtitle;

  /// No description provided for @bookmark_removed.
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get bookmark_removed;

  /// No description provided for @bookmark_remove_failed.
  ///
  /// In en, this message translates to:
  /// **'Unable to remove bookmark'**
  String get bookmark_remove_failed;

  /// No description provided for @bookmark_saved.
  ///
  /// In en, this message translates to:
  /// **'Bookmark saved'**
  String get bookmark_saved;

  /// No description provided for @bookmark_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save bookmark'**
  String get bookmark_save_failed;

  /// No description provided for @bookmarks_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get bookmarks_yesterday;

  /// No description provided for @webview_timeout_error.
  ///
  /// In en, this message translates to:
  /// **'Page took too long to load. Please check your internet connection'**
  String get webview_timeout_error;

  /// No description provided for @webview_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load page'**
  String get webview_load_failed;

  /// No description provided for @privacy_policy_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the privacy policy page'**
  String get privacy_policy_load_error;

  /// No description provided for @terms_of_service_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the terms of service page'**
  String get terms_of_service_load_error;

  /// No description provided for @series_enroll_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to enroll in series'**
  String get series_enroll_error;

  /// No description provided for @series_share_message.
  ///
  /// In en, this message translates to:
  /// **'Join me in practicing {title} on WeBuddhist.\n\n{url}'**
  String series_share_message(String title, String url);

  /// No description provided for @player_back_10.
  ///
  /// In en, this message translates to:
  /// **'Back 10 seconds'**
  String get player_back_10;

  /// No description provided for @player_pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get player_pause;

  /// No description provided for @player_play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get player_play;

  /// No description provided for @player_forward_10.
  ///
  /// In en, this message translates to:
  /// **'Forward 10 seconds'**
  String get player_forward_10;

  /// No description provided for @player_fullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get player_fullscreen;

  /// No description provided for @player_exit_fullscreen.
  ///
  /// In en, this message translates to:
  /// **'Exit fullscreen'**
  String get player_exit_fullscreen;

  /// No description provided for @session_plans_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load plans.\nPlease try again later'**
  String get session_plans_load_error;

  /// No description provided for @session_chants_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load chants'**
  String get session_chants_load_error;

  /// No description provided for @session_no_chants.
  ///
  /// In en, this message translates to:
  /// **'No chants found'**
  String get session_no_chants;

  /// No description provided for @session_malas_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load malas'**
  String get session_malas_load_error;

  /// No description provided for @session_no_malas.
  ///
  /// In en, this message translates to:
  /// **'No malas found'**
  String get session_no_malas;

  /// No description provided for @session_timers_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load timers'**
  String get session_timers_load_error;

  /// No description provided for @session_no_timers.
  ///
  /// In en, this message translates to:
  /// **'No timers found'**
  String get session_no_timers;

  /// No description provided for @days_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Day} other{{count} Days}}'**
  String days_count(int count);

  /// No description provided for @timer_minute_session.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min session'**
  String timer_minute_session(int minutes);

  /// No description provided for @timer_notification_in_progress.
  ///
  /// In en, this message translates to:
  /// **'Meditation in progress'**
  String get timer_notification_in_progress;

  /// No description provided for @timer_notification_paused.
  ///
  /// In en, this message translates to:
  /// **'Paused · {time} left'**
  String timer_notification_paused(String time);

  /// No description provided for @timer_notification_complete.
  ///
  /// In en, this message translates to:
  /// **'Your session is complete'**
  String get timer_notification_complete;

  /// No description provided for @plan_day_of.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {total}'**
  String plan_day_of(int day, int total);

  /// No description provided for @pagination_position.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String pagination_position(int current, int total);

  /// No description provided for @plan_shorts_title.
  ///
  /// In en, this message translates to:
  /// **'Shorts from the community'**
  String get plan_shorts_title;

  /// No description provided for @author_details_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load author details.\nPlease try again'**
  String get author_details_load_error;

  /// No description provided for @link_cannot_open.
  ///
  /// In en, this message translates to:
  /// **'Cannot open this link'**
  String get link_cannot_open;

  /// No description provided for @link_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get link_invalid;

  /// No description provided for @author_no_plans.
  ///
  /// In en, this message translates to:
  /// **'No plans created yet'**
  String get author_no_plans;

  /// No description provided for @author_plans_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load plans'**
  String get author_plans_load_error;

  /// No description provided for @source_with_value.
  ///
  /// In en, this message translates to:
  /// **'Source: {value}'**
  String source_with_value(String value);

  /// No description provided for @license_with_value.
  ///
  /// In en, this message translates to:
  /// **'License: {value}'**
  String license_with_value(String value);

  /// No description provided for @loading_previous_pages.
  ///
  /// In en, this message translates to:
  /// **'Loading previous... ({count} pages)'**
  String loading_previous_pages(int count);

  /// No description provided for @loading_more_pages.
  ///
  /// In en, this message translates to:
  /// **'Loading more... ({count} pages)'**
  String loading_more_pages(int count);

  /// No description provided for @drag_to_resize.
  ///
  /// In en, this message translates to:
  /// **'Drag to resize'**
  String get drag_to_resize;

  /// No description provided for @day_completion_share_message.
  ///
  /// In en, this message translates to:
  /// **'I just completed a day of my practice on WeBuddhist. Join me and build a daily practice habit together.'**
  String get day_completion_share_message;

  /// No description provided for @group_accumulator_share_message.
  ///
  /// In en, this message translates to:
  /// **'I am taking part in \"{accumulation}\", an accumulation by {group} on WeBuddhist. Come join me!'**
  String group_accumulator_share_message(String accumulation, String group);

  /// No description provided for @group_accumulator_share_message_no_group.
  ///
  /// In en, this message translates to:
  /// **'I am taking part in the \"{accumulation}\" accumulation on WeBuddhist. Come join me!'**
  String group_accumulator_share_message_no_group(String accumulation);

  /// No description provided for @group_chat_title.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get group_chat_title;

  /// No description provided for @chats_title.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats_title;

  /// No description provided for @chats_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get chats_empty_title;

  /// No description provided for @chats_empty_body.
  ///
  /// In en, this message translates to:
  /// **'Join a space to start chatting'**
  String get chats_empty_body;

  /// No description provided for @group_chat_inappropriate.
  ///
  /// In en, this message translates to:
  /// **'This message couldn\'t be sent because it contains language that isn\'t allowed'**
  String get group_chat_inappropriate;

  /// No description provided for @group_chat_not_a_member.
  ///
  /// In en, this message translates to:
  /// **'Only members can open this chat'**
  String get group_chat_not_a_member;

  /// No description provided for @group_chat_open.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get group_chat_open;

  /// No description provided for @group_chat_message_hint.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get group_chat_message_hint;

  /// No description provided for @group_chat_join_to_send.
  ///
  /// In en, this message translates to:
  /// **'Join chat to send message'**
  String get group_chat_join_to_send;

  /// No description provided for @group_chat_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get group_chat_today;

  /// No description provided for @group_chat_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get group_chat_yesterday;

  /// No description provided for @group_chat_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get group_chat_empty_title;

  /// No description provided for @group_chat_empty_body.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation with your space'**
  String get group_chat_empty_body;

  /// No description provided for @group_chat_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Messages couldn\'t be loaded'**
  String get group_chat_load_failed;

  /// No description provided for @group_chat_message_not_found.
  ///
  /// In en, this message translates to:
  /// **'This message is no longer in the chat'**
  String get group_chat_message_not_found;

  /// No description provided for @group_chat_message_too_far_back.
  ///
  /// In en, this message translates to:
  /// **'This message is further back in the chat'**
  String get group_chat_message_too_far_back;

  /// No description provided for @group_chat_keep_looking.
  ///
  /// In en, this message translates to:
  /// **'Keep looking'**
  String get group_chat_keep_looking;

  /// No description provided for @group_chat_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get group_chat_retry;

  /// No description provided for @group_chat_unknown_sender.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get group_chat_unknown_sender;

  /// No description provided for @group_chat_reactions_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get group_chat_reactions_all;

  /// No description provided for @group_chat_reacted.
  ///
  /// In en, this message translates to:
  /// **'Reacted'**
  String get group_chat_reacted;

  /// No description provided for @group_chat_reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get group_chat_reply;

  /// No description provided for @group_chat_copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get group_chat_copy;

  /// No description provided for @group_chat_copied.
  ///
  /// In en, this message translates to:
  /// **'Message copied'**
  String get group_chat_copied;

  /// No description provided for @group_chat_report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get group_chat_report;

  /// No description provided for @group_chat_report_title.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this?'**
  String get group_chat_report_title;

  /// No description provided for @group_chat_report_privacy.
  ///
  /// In en, this message translates to:
  /// **'Your name stays private'**
  String get group_chat_report_privacy;

  /// No description provided for @group_chat_report_reason_harassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or bullying'**
  String get group_chat_report_reason_harassment;

  /// No description provided for @group_chat_report_reason_hate.
  ///
  /// In en, this message translates to:
  /// **'Hateful or harmful speech'**
  String get group_chat_report_reason_hate;

  /// No description provided for @group_chat_report_reason_sexual.
  ///
  /// In en, this message translates to:
  /// **'Sexual or explicit content'**
  String get group_chat_report_reason_sexual;

  /// No description provided for @group_chat_report_reason_spam.
  ///
  /// In en, this message translates to:
  /// **'Spam or scams'**
  String get group_chat_report_reason_spam;

  /// No description provided for @group_chat_report_reason_off_topic.
  ///
  /// In en, this message translates to:
  /// **'Off-topic or disruptive'**
  String get group_chat_report_reason_off_topic;

  /// No description provided for @group_chat_report_reason_other.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get group_chat_report_reason_other;

  /// No description provided for @group_chat_report_note_title.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get group_chat_report_note_title;

  /// No description provided for @group_chat_report_note_hint.
  ///
  /// In en, this message translates to:
  /// **'Something else...'**
  String get group_chat_report_note_hint;

  /// No description provided for @group_chat_report_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get group_chat_report_submit;

  /// No description provided for @group_chat_report_thanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for the feedback'**
  String get group_chat_report_thanks;

  /// No description provided for @group_chat_report_offline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Try again later'**
  String get group_chat_report_offline;

  /// No description provided for @group_chat_report_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send report'**
  String get group_chat_report_failed;

  /// No description provided for @group_chat_report_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get group_chat_report_retry;

  /// No description provided for @group_chat_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get group_chat_delete;

  /// No description provided for @group_chat_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete message?'**
  String get group_chat_delete_title;

  /// No description provided for @group_chat_delete_title_many.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} messages?'**
  String group_chat_delete_title_many(int count);

  /// No description provided for @group_chat_delete_confirm_body.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This message will be removed from the chat for everyone} other{These messages will be removed from the chat for everyone}}'**
  String group_chat_delete_confirm_body(int count);

  /// No description provided for @group_chat_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The message couldn\'t be deleted} other{{count} messages couldn\'t be deleted}}'**
  String group_chat_delete_failed(int count);

  /// No description provided for @group_chat_selection_limit.
  ///
  /// In en, this message translates to:
  /// **'You can select up to {count} messages'**
  String group_chat_selection_limit(int count);

  /// No description provided for @group_chat_message_deleted_by_sender.
  ///
  /// In en, this message translates to:
  /// **'This message was deleted'**
  String get group_chat_message_deleted_by_sender;

  /// No description provided for @group_chat_reaction_failed.
  ///
  /// In en, this message translates to:
  /// **'Your reaction couldn\'t be saved'**
  String get group_chat_reaction_failed;

  /// No description provided for @group_chat_reactions_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural,\n=1 {1 reaction}\nother {{count} reactions}\n}'**
  String group_chat_reactions_count(int count);

  /// No description provided for @group_chat_you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get group_chat_you;

  /// No description provided for @group_chat_tap_to_remove.
  ///
  /// In en, this message translates to:
  /// **'Tap to remove'**
  String get group_chat_tap_to_remove;

  /// No description provided for @group_chat_reply_parent_gone.
  ///
  /// In en, this message translates to:
  /// **'That message is no longer available, so the quote was removed. Send again to post your message'**
  String get group_chat_reply_parent_gone;

  /// No description provided for @group_tab_posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get group_tab_posts;

  /// No description provided for @group_tab_events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get group_tab_events;

  /// No description provided for @group_posts_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get group_posts_empty_title;

  /// No description provided for @group_posts_empty_message.
  ///
  /// In en, this message translates to:
  /// **'Share your space\'s first update'**
  String get group_posts_empty_message;

  /// No description provided for @group_posts_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load posts. Please try again'**
  String get group_posts_load_error;

  /// No description provided for @group_post_button.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get group_post_button;

  /// No description provided for @group_post_new_title.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get group_post_new_title;

  /// No description provided for @group_post_posting_to.
  ///
  /// In en, this message translates to:
  /// **'Posting to:'**
  String get group_post_posting_to;

  /// No description provided for @group_post_caption_hint.
  ///
  /// In en, this message translates to:
  /// **'What\'s new?'**
  String get group_post_caption_hint;

  /// No description provided for @group_post_photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get group_post_photos;

  /// No description provided for @group_post_link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get group_post_link;

  /// No description provided for @group_post_discard_title.
  ///
  /// In en, this message translates to:
  /// **'Discard post?'**
  String get group_post_discard_title;

  /// No description provided for @group_post_discard_message.
  ///
  /// In en, this message translates to:
  /// **'You\'ll lose what you\'ve written'**
  String get group_post_discard_message;

  /// No description provided for @group_post_keep_editing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get group_post_keep_editing;

  /// No description provided for @group_post_discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get group_post_discard;

  /// No description provided for @group_post_add_link_title.
  ///
  /// In en, this message translates to:
  /// **'Add link'**
  String get group_post_add_link_title;

  /// No description provided for @group_post_add_link_hint.
  ///
  /// In en, this message translates to:
  /// **'Paste a link and we\'ll show a preview'**
  String get group_post_add_link_hint;

  /// No description provided for @group_post_link_field_hint.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get group_post_link_field_hint;

  /// No description provided for @group_post_attach.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get group_post_attach;

  /// No description provided for @group_post_attach_as_link.
  ///
  /// In en, this message translates to:
  /// **'Attach as link'**
  String get group_post_attach_as_link;

  /// No description provided for @group_post_preview_failed_title.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load a preview'**
  String get group_post_preview_failed_title;

  /// No description provided for @group_post_preview_failed_message.
  ///
  /// In en, this message translates to:
  /// **'You can still attach it as a link'**
  String get group_post_preview_failed_message;

  /// No description provided for @group_post_invalid_link.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid link, for example: https://example.com'**
  String get group_post_invalid_link;

  /// No description provided for @group_post_in_app_content.
  ///
  /// In en, this message translates to:
  /// **'In-app content'**
  String get group_post_in_app_content;

  /// No description provided for @group_post_add_in_app_content_title.
  ///
  /// In en, this message translates to:
  /// **'Add in-app content'**
  String get group_post_add_in_app_content_title;

  /// No description provided for @group_post_in_app_content_empty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to add yet'**
  String get group_post_in_app_content_empty;

  /// No description provided for @group_post_photo_limit.
  ///
  /// In en, this message translates to:
  /// **'You can add up to {count} photos'**
  String group_post_photo_limit(int count);

  /// No description provided for @group_post_upload_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to upload photos. Please try again'**
  String get group_post_upload_error;

  /// No description provided for @group_post_publish_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to publish your post. Please try again'**
  String get group_post_publish_error;

  /// No description provided for @group_post_published.
  ///
  /// In en, this message translates to:
  /// **'Your post is live.'**
  String get group_post_published;

  /// No description provided for @group_post_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete post?'**
  String get group_post_delete_title;

  /// No description provided for @group_post_delete_message.
  ///
  /// In en, this message translates to:
  /// **'This post will be permanently removed'**
  String get group_post_delete_message;

  /// No description provided for @group_post_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete post. Please try again'**
  String get group_post_delete_failed;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @group_post_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit post'**
  String get group_post_edit_title;

  /// No description provided for @group_post_update_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to save your changes. Please try again'**
  String get group_post_update_error;

  /// No description provided for @group_post_updated.
  ///
  /// In en, this message translates to:
  /// **'Your changes are saved'**
  String get group_post_updated;

  /// No description provided for @practice_collection_already_added.
  ///
  /// In en, this message translates to:
  /// **'This collection is already in your practices'**
  String get practice_collection_already_added;

  /// No description provided for @practice_group_accumulator_already_added.
  ///
  /// In en, this message translates to:
  /// **'This accumulation is already in your practices'**
  String get practice_group_accumulator_already_added;

  /// No description provided for @event_live_badge.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get event_live_badge;

  /// No description provided for @event_live_audio.
  ///
  /// In en, this message translates to:
  /// **'Live audio'**
  String get event_live_audio;

  /// No description provided for @event_live_video_mode.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get event_live_video_mode;

  /// No description provided for @event_live_audio_mode.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get event_live_audio_mode;

  /// No description provided for @event_live_go_live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get event_live_go_live;

  /// No description provided for @event_replays.
  ///
  /// In en, this message translates to:
  /// **'Replays'**
  String get event_replays;

  /// No description provided for @event_replay_session.
  ///
  /// In en, this message translates to:
  /// **'Day {day} · Session {session}'**
  String event_replay_session(String day, String session);

  /// No description provided for @event_replay_recording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get event_replay_recording;

  /// No description provided for @event_replay_back_to_live.
  ///
  /// In en, this message translates to:
  /// **'Back to live'**
  String get event_replay_back_to_live;

  /// No description provided for @event_replays_empty.
  ///
  /// In en, this message translates to:
  /// **'No recordings yet'**
  String get event_replays_empty;

  /// No description provided for @event_puja_starts_in.
  ///
  /// In en, this message translates to:
  /// **'Puja starts in'**
  String get event_puja_starts_in;

  /// No description provided for @event_puja_not_started.
  ///
  /// In en, this message translates to:
  /// **'Puja not started yet'**
  String get event_puja_not_started;

  /// No description provided for @event_prayer_requests.
  ///
  /// In en, this message translates to:
  /// **'Prayer requests'**
  String get event_prayer_requests;

  /// No description provided for @event_prayer_request_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural,\n=1 {1 request}\nother {{count} requests}\none {1 request}\n}'**
  String event_prayer_request_count(int count);

  /// No description provided for @event_prayer_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No prayer requests yet'**
  String get event_prayer_empty_title;

  /// No description provided for @event_prayer_empty_body.
  ///
  /// In en, this message translates to:
  /// **'Your request and your space\'s requests will appear here'**
  String get event_prayer_empty_body;

  /// No description provided for @event_prayer_add.
  ///
  /// In en, this message translates to:
  /// **'Add a prayer request'**
  String get event_prayer_add;

  /// No description provided for @event_prayer_hint.
  ///
  /// In en, this message translates to:
  /// **'Share a prayer request'**
  String get event_prayer_hint;

  /// No description provided for @event_prayer_hint_intention.
  ///
  /// In en, this message translates to:
  /// **'Request a prayer for: {topics}'**
  String event_prayer_hint_intention(String topics);

  /// No description provided for @event_prayer_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Prayer requests couldn\'t be loaded'**
  String get event_prayer_load_failed;

  /// No description provided for @event_prayer_closed.
  ///
  /// In en, this message translates to:
  /// **'Prayer requests are closed for this event'**
  String get event_prayer_closed;

  /// No description provided for @event_prayer_pray.
  ///
  /// In en, this message translates to:
  /// **'Pray'**
  String get event_prayer_pray;

  /// No description provided for @event_prayer_praying.
  ///
  /// In en, this message translates to:
  /// **'Prayed'**
  String get event_prayer_praying;

  /// No description provided for @event_prayer_my_count.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String event_prayer_my_count(int count);

  /// No description provided for @event_prayer_new_request.
  ///
  /// In en, this message translates to:
  /// **'New prayer request'**
  String get event_prayer_new_request;

  /// No description provided for @event_prayer_edit_request.
  ///
  /// In en, this message translates to:
  /// **'Edit prayer request'**
  String get event_prayer_edit_request;

  /// No description provided for @event_prayer_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete prayer request?'**
  String get event_prayer_delete_title;

  /// No description provided for @event_prayer_delete_body.
  ///
  /// In en, this message translates to:
  /// **'It will be removed for everyone in this event.'**
  String get event_prayer_delete_body;

  /// No description provided for @event_prayer_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'The prayer request couldn\'t be deleted'**
  String get event_prayer_delete_failed;

  /// No description provided for @event_prayer_choose_intention.
  ///
  /// In en, this message translates to:
  /// **'Choose an intention'**
  String get event_prayer_choose_intention;

  /// No description provided for @event_prayer_intentions_failed.
  ///
  /// In en, this message translates to:
  /// **'Intentions couldn\'t be loaded'**
  String get event_prayer_intentions_failed;

  /// No description provided for @event_prayer_request_button.
  ///
  /// In en, this message translates to:
  /// **'Request prayer'**
  String get event_prayer_request_button;

  /// No description provided for @event_prayer_you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get event_prayer_you;

  /// No description provided for @event_prayer_waiting_first.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the first prayer...'**
  String get event_prayer_waiting_first;

  /// No description provided for @event_prayer_more_praying.
  ///
  /// In en, this message translates to:
  /// **'+{count} more prayed'**
  String event_prayer_more_praying(int count);

  /// No description provided for @event_prayer_people_praying.
  ///
  /// In en, this message translates to:
  /// **'{count, plural,\n=1 {{count} person prayed}\nother {{count} people prayed}\n}'**
  String event_prayer_people_praying(int count);

  /// No description provided for @event_prayer_praying_for_you.
  ///
  /// In en, this message translates to:
  /// **'Prayed for you'**
  String get event_prayer_praying_for_you;

  /// No description provided for @event_prayer_praying_for.
  ///
  /// In en, this message translates to:
  /// **'Prayed for {name}'**
  String event_prayer_praying_for(String name);

  /// No description provided for @event_prayer_your_request.
  ///
  /// In en, this message translates to:
  /// **'Your request'**
  String get event_prayer_your_request;

  /// No description provided for @event_prayer_supporters_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load who is praying.'**
  String get event_prayer_supporters_failed;

  /// No description provided for @event_prayer_no_supporters.
  ///
  /// In en, this message translates to:
  /// **'No one is praying yet'**
  String get event_prayer_no_supporters;

  /// No description provided for @event_prayer_sort_by.
  ///
  /// In en, this message translates to:
  /// **'Pray for'**
  String get event_prayer_sort_by;

  /// No description provided for @event_prayer_sort_needs_prayers.
  ///
  /// In en, this message translates to:
  /// **'Needs prayers'**
  String get event_prayer_sort_needs_prayers;

  /// No description provided for @event_prayer_sort_most_prayed.
  ///
  /// In en, this message translates to:
  /// **'Most prayed'**
  String get event_prayer_sort_most_prayed;

  /// No description provided for @event_prayer_sort_newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get event_prayer_sort_newest;

  /// No description provided for @event_prayer_sort_oldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get event_prayer_sort_oldest;

  /// No description provided for @event_prayer_sort_by_intention.
  ///
  /// In en, this message translates to:
  /// **'By intention'**
  String get event_prayer_sort_by_intention;

  /// No description provided for @event_prayer_clear_intention.
  ///
  /// In en, this message translates to:
  /// **'Clear intention'**
  String get event_prayer_clear_intention;

  /// No description provided for @event_prayer_filter_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No requests match'**
  String get event_prayer_filter_empty_title;

  /// No description provided for @event_prayer_filter_empty_body.
  ///
  /// In en, this message translates to:
  /// **'Try another sort or intention'**
  String get event_prayer_filter_empty_body;

  /// No description provided for @event_prayer_see_translation.
  ///
  /// In en, this message translates to:
  /// **'See translation'**
  String get event_prayer_see_translation;

  /// No description provided for @event_prayer_see_original.
  ///
  /// In en, this message translates to:
  /// **'See original'**
  String get event_prayer_see_original;

  /// No description provided for @event_prayer_translated_from.
  ///
  /// In en, this message translates to:
  /// **'Translated from {language}'**
  String event_prayer_translated_from(String language);

  /// No description provided for @event_prayer_translated.
  ///
  /// In en, this message translates to:
  /// **'Translated'**
  String get event_prayer_translated;

  /// No description provided for @recitation_live_sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get recitation_live_sync;

  /// No description provided for @recitation_live_label.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get recitation_live_label;

  /// No description provided for @recitation_live_session_ended.
  ///
  /// In en, this message translates to:
  /// **'The live session has ended'**
  String get recitation_live_session_ended;

  /// No description provided for @feedback_add_image.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get feedback_add_image;

  /// No description provided for @feedback_image_limit.
  ///
  /// In en, this message translates to:
  /// **'You can attach up to {count} images'**
  String feedback_image_limit(int count);

  /// No description provided for @feedback_send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get feedback_send;

  /// No description provided for @feedback_error_offline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Please try again later'**
  String get feedback_error_offline;

  /// No description provided for @feedback_error_rate_limited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Wait a moment and try again'**
  String get feedback_error_rate_limited;

  /// No description provided for @feedback_error_too_large.
  ///
  /// In en, this message translates to:
  /// **'Images are too large. Remove one and try again'**
  String get feedback_error_too_large;

  /// No description provided for @feedback_error_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send feedback. Please try again'**
  String get feedback_error_failed;

  /// No description provided for @feedback_error_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Feedback is not available right now'**
  String get feedback_error_unavailable;

  /// No description provided for @settings_help_contact_row.
  ///
  /// In en, this message translates to:
  /// **'Help & contact'**
  String get settings_help_contact_row;

  /// No description provided for @help_contact_title.
  ///
  /// In en, this message translates to:
  /// **'Help & contact'**
  String get help_contact_title;

  /// No description provided for @help_contact_intro.
  ///
  /// In en, this message translates to:
  /// **'Report a problem, share an idea, or offer to help or collaborate. We read every message.'**
  String get help_contact_intro;

  /// No description provided for @help_contact_message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get help_contact_message;

  /// No description provided for @help_contact_photos.
  ///
  /// In en, this message translates to:
  /// **'Photos or screenshots (optional)'**
  String get help_contact_photos;

  /// No description provided for @help_contact_topic.
  ///
  /// In en, this message translates to:
  /// **'What\'s this about? (optional)'**
  String get help_contact_topic;

  /// No description provided for @help_contact_hint_default.
  ///
  /// In en, this message translates to:
  /// **'What would you like to tell us?'**
  String get help_contact_hint_default;

  /// No description provided for @help_contact_hint_report_problem.
  ///
  /// In en, this message translates to:
  /// **'What happened, and what were you doing just before? A screenshot helps.'**
  String get help_contact_hint_report_problem;

  /// No description provided for @help_contact_hint_idea_feedback.
  ///
  /// In en, this message translates to:
  /// **'What would make WeBuddhist more helpful for your practice?'**
  String get help_contact_hint_idea_feedback;

  /// No description provided for @help_contact_hint_suggest_content.
  ///
  /// In en, this message translates to:
  /// **'Which teaching, text, or teacher would you like to see here? Links are welcome.'**
  String get help_contact_hint_suggest_content;

  /// No description provided for @help_contact_hint_help_collaborate.
  ///
  /// In en, this message translates to:
  /// **'How would you like to help? Share your skills, languages, or the time you can offer.'**
  String get help_contact_hint_help_collaborate;

  /// No description provided for @help_topic_report_problem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get help_topic_report_problem;

  /// No description provided for @help_topic_idea_feedback.
  ///
  /// In en, this message translates to:
  /// **'Idea or feedback'**
  String get help_topic_idea_feedback;

  /// No description provided for @help_topic_suggest_content.
  ///
  /// In en, this message translates to:
  /// **'Suggest content'**
  String get help_topic_suggest_content;

  /// No description provided for @help_topic_help_collaborate.
  ///
  /// In en, this message translates to:
  /// **'Help or collaborate'**
  String get help_topic_help_collaborate;

  /// No description provided for @help_contact_footer.
  ///
  /// In en, this message translates to:
  /// **'Replies come from the WeBuddhist Team in your Chats.'**
  String get help_contact_footer;

  /// No description provided for @help_contact_sent_title.
  ///
  /// In en, this message translates to:
  /// **'Message sent'**
  String get help_contact_sent_title;

  /// No description provided for @help_contact_sent_body.
  ///
  /// In en, this message translates to:
  /// **'Thanks. We usually reply within 1 day. You\'ll find the reply in your Chats, from the WeBuddhist Team.'**
  String get help_contact_sent_body;

  /// No description provided for @help_contact_sent_body_named.
  ///
  /// In en, this message translates to:
  /// **'Thanks, {name}. We usually reply within 1 day. You\'ll find the reply in your Chats, from the WeBuddhist Team.'**
  String help_contact_sent_body_named(String name);

  /// No description provided for @help_contact_your_request.
  ///
  /// In en, this message translates to:
  /// **'YOUR REQUEST'**
  String get help_contact_your_request;

  /// No description provided for @help_contact_open_chat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get help_contact_open_chat;

  /// No description provided for @help_context_sent_from.
  ///
  /// In en, this message translates to:
  /// **'Sent from Help & contact'**
  String get help_context_sent_from;

  /// No description provided for @help_context_photos.
  ///
  /// In en, this message translates to:
  /// **'{count, plural,\n=1 {1 photo}\nother {{count} photos}\n}'**
  String help_context_photos(int count);

  /// No description provided for @chat_official_badge.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get chat_official_badge;

  /// No description provided for @chat_team_reply_time.
  ///
  /// In en, this message translates to:
  /// **'Usually replies within 1 day'**
  String get chat_team_reply_time;

  /// No description provided for @connect_failed_load_discover_groups_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load spaces'**
  String get connect_failed_load_discover_groups_error;

  /// No description provided for @connect_failed_like_post_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to like post'**
  String get connect_failed_like_post_error;

  /// No description provided for @connect_failed_unlike_post_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to unlike post'**
  String get connect_failed_unlike_post_error;

  /// No description provided for @connect_failed_like_comment_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to like comment'**
  String get connect_failed_like_comment_error;

  /// No description provided for @connect_failed_unlike_comment_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to unlike comment'**
  String get connect_failed_unlike_comment_error;

  /// No description provided for @group_events_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load events. Please try again.'**
  String get group_events_load_error;

  /// No description provided for @group_events_empty.
  ///
  /// In en, this message translates to:
  /// **'No events yet'**
  String get group_events_empty;

  /// No description provided for @group_events_empty_message.
  ///
  /// In en, this message translates to:
  /// **'Create your first gathering — members will be notified.'**
  String get group_events_empty_message;

  /// No description provided for @group_event_create_button.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get group_event_create_button;

  /// No description provided for @group_event_new_title.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get group_event_new_title;

  /// No description provided for @group_event_step_of.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String group_event_step_of(int current, int total);

  /// No description provided for @group_event_step_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get group_event_step_about;

  /// No description provided for @group_event_cover_image.
  ///
  /// In en, this message translates to:
  /// **'Cover image'**
  String get group_event_cover_image;

  /// No description provided for @group_event_add_cover_photo.
  ///
  /// In en, this message translates to:
  /// **'Add cover photo'**
  String get group_event_add_cover_photo;

  /// No description provided for @group_event_change_cover.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get group_event_change_cover;

  /// No description provided for @group_event_name_and_description.
  ///
  /// In en, this message translates to:
  /// **'Name & description'**
  String get group_event_name_and_description;

  /// No description provided for @group_event_name_label.
  ///
  /// In en, this message translates to:
  /// **'Event name'**
  String get group_event_name_label;

  /// No description provided for @group_event_name_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Wednesday group practice'**
  String get group_event_name_hint;

  /// No description provided for @group_event_description_label.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get group_event_description_label;

  /// No description provided for @group_event_description_hint.
  ///
  /// In en, this message translates to:
  /// **'What will you practise together? Anything to bring?'**
  String get group_event_description_hint;

  /// No description provided for @group_event_write.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get group_event_write;

  /// No description provided for @group_event_preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get group_event_preview;

  /// No description provided for @group_event_preview_empty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to preview yet'**
  String get group_event_preview_empty;

  /// No description provided for @group_event_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get group_event_continue;

  /// No description provided for @group_event_name_required_hint.
  ///
  /// In en, this message translates to:
  /// **'Add an event name to continue'**
  String get group_event_name_required_hint;

  /// No description provided for @group_event_languages_title.
  ///
  /// In en, this message translates to:
  /// **'Event languages'**
  String get group_event_languages_title;

  /// No description provided for @group_event_languages_add.
  ///
  /// In en, this message translates to:
  /// **'Add language'**
  String get group_event_languages_add;

  /// No description provided for @group_event_languages_hint.
  ///
  /// In en, this message translates to:
  /// **'Preselected from your space\'s languages. Readers see the event in their language when it\'s available.'**
  String get group_event_languages_hint;

  /// No description provided for @group_event_discard_title.
  ///
  /// In en, this message translates to:
  /// **'Discard event?'**
  String get group_event_discard_title;

  /// No description provided for @group_event_discard_message.
  ///
  /// In en, this message translates to:
  /// **'You\'ll lose what you\'ve entered'**
  String get group_event_discard_message;

  /// No description provided for @group_event_format_bold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get group_event_format_bold;

  /// No description provided for @group_event_format_italic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get group_event_format_italic;

  /// No description provided for @group_event_format_heading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get group_event_format_heading;

  /// No description provided for @group_event_format_bullet_list.
  ///
  /// In en, this message translates to:
  /// **'Bullet list'**
  String get group_event_format_bullet_list;

  /// No description provided for @group_event_format_numbered_list.
  ///
  /// In en, this message translates to:
  /// **'Numbered list'**
  String get group_event_format_numbered_list;

  /// No description provided for @group_event_format_link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get group_event_format_link;

  /// No description provided for @group_event_link_title.
  ///
  /// In en, this message translates to:
  /// **'Insert link'**
  String get group_event_link_title;

  /// No description provided for @group_event_link_text_hint.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get group_event_link_text_hint;

  /// No description provided for @group_event_link_url_hint.
  ///
  /// In en, this message translates to:
  /// **'https://'**
  String get group_event_link_url_hint;

  /// No description provided for @group_event_link_insert.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get group_event_link_insert;

  /// No description provided for @group_event_step_when_where.
  ///
  /// In en, this message translates to:
  /// **'When & where'**
  String get group_event_step_when_where;

  /// No description provided for @group_event_when.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get group_event_when;

  /// No description provided for @group_event_where.
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get group_event_where;

  /// No description provided for @group_event_one_time.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get group_event_one_time;

  /// No description provided for @group_event_recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get group_event_recurring;

  /// No description provided for @group_event_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get group_event_date;

  /// No description provided for @group_event_start_date.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get group_event_start_date;

  /// No description provided for @group_event_end_date.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get group_event_end_date;

  /// No description provided for @group_event_first_date.
  ///
  /// In en, this message translates to:
  /// **'First date'**
  String get group_event_first_date;

  /// No description provided for @group_event_choose_date.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get group_event_choose_date;

  /// No description provided for @group_event_multi_day.
  ///
  /// In en, this message translates to:
  /// **'Multi-day event'**
  String get group_event_multi_day;

  /// No description provided for @group_event_all_day.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get group_event_all_day;

  /// No description provided for @group_event_all_day_hint.
  ///
  /// In en, this message translates to:
  /// **'Shown as all day on the event page.'**
  String get group_event_all_day_hint;

  /// No description provided for @group_event_start_time.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get group_event_start_time;

  /// No description provided for @group_event_end_time.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get group_event_end_time;

  /// No description provided for @group_event_add_start_time.
  ///
  /// In en, this message translates to:
  /// **'Add start time'**
  String get group_event_add_start_time;

  /// No description provided for @group_event_add_end_time.
  ///
  /// In en, this message translates to:
  /// **'Add end time'**
  String get group_event_add_end_time;

  /// No description provided for @group_event_time_starts.
  ///
  /// In en, this message translates to:
  /// **'starts {time}'**
  String group_event_time_starts(String time);

  /// No description provided for @group_event_time_ends.
  ///
  /// In en, this message translates to:
  /// **'ends {time}'**
  String group_event_time_ends(String time);

  /// No description provided for @group_event_timezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get group_event_timezone;

  /// No description provided for @group_event_repeats.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get group_event_repeats;

  /// No description provided for @group_event_choose_repeats.
  ///
  /// In en, this message translates to:
  /// **'Choose how it repeats'**
  String get group_event_choose_repeats;

  /// No description provided for @group_event_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get group_event_duration;

  /// No description provided for @group_event_duration_decrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease duration'**
  String get group_event_duration_decrease;

  /// No description provided for @group_event_duration_increase.
  ///
  /// In en, this message translates to:
  /// **'Increase duration'**
  String get group_event_duration_increase;

  /// No description provided for @group_event_duration_days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural,\n=1 {1 day}\nother {{count} days}\n}'**
  String group_event_duration_days(int count);

  /// No description provided for @group_event_repeats_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly on {weekday}'**
  String group_event_repeats_weekly(String weekday);

  /// No description provided for @group_event_repeats_monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly on the {day}'**
  String group_event_repeats_monthly(String day);

  /// No description provided for @group_event_repeats_monthly_lunar.
  ///
  /// In en, this message translates to:
  /// **'Monthly on the {day} lunar day'**
  String group_event_repeats_monthly_lunar(String day);

  /// No description provided for @group_event_repeats_yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly on {date}'**
  String group_event_repeats_yearly(String date);

  /// No description provided for @group_event_repeats_yearly_lunar.
  ///
  /// In en, this message translates to:
  /// **'Yearly on this lunar date'**
  String get group_event_repeats_yearly_lunar;

  /// No description provided for @group_event_full_moon.
  ///
  /// In en, this message translates to:
  /// **'Full moon'**
  String get group_event_full_moon;

  /// No description provided for @group_event_new_moon.
  ///
  /// In en, this message translates to:
  /// **'New moon'**
  String get group_event_new_moon;

  /// No description provided for @group_event_gregorian.
  ///
  /// In en, this message translates to:
  /// **'Gregorian'**
  String get group_event_gregorian;

  /// No description provided for @group_event_tibetan_lunar.
  ///
  /// In en, this message translates to:
  /// **'Tibetan Lunar'**
  String get group_event_tibetan_lunar;

  /// No description provided for @group_event_next_dates.
  ///
  /// In en, this message translates to:
  /// **'Next dates'**
  String get group_event_next_dates;

  /// No description provided for @group_event_repeats_hint.
  ///
  /// In en, this message translates to:
  /// **'Options are based on the first date.'**
  String get group_event_repeats_hint;

  /// No description provided for @group_event_in_person.
  ///
  /// In en, this message translates to:
  /// **'In person'**
  String get group_event_in_person;

  /// No description provided for @group_event_live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get group_event_live;

  /// No description provided for @group_event_both.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get group_event_both;

  /// No description provided for @group_event_venue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get group_event_venue;

  /// No description provided for @group_event_add_venue.
  ///
  /// In en, this message translates to:
  /// **'Add venue location'**
  String get group_event_add_venue;

  /// No description provided for @group_event_venue_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search area, street or landmark'**
  String get group_event_venue_search_hint;

  /// No description provided for @group_event_venue_no_results.
  ///
  /// In en, this message translates to:
  /// **'No places found'**
  String get group_event_venue_no_results;

  /// No description provided for @group_event_venue_search_error.
  ///
  /// In en, this message translates to:
  /// **'Search isn\'t available right now'**
  String get group_event_venue_search_error;

  /// No description provided for @group_event_drop_pin.
  ///
  /// In en, this message translates to:
  /// **'Drop a pin'**
  String get group_event_drop_pin;

  /// No description provided for @group_event_drop_pin_hint.
  ///
  /// In en, this message translates to:
  /// **'Choose the spot on a map'**
  String get group_event_drop_pin_hint;

  /// No description provided for @group_event_pin_marker.
  ///
  /// In en, this message translates to:
  /// **'Event venue'**
  String get group_event_pin_marker;

  /// No description provided for @group_event_selected_location.
  ///
  /// In en, this message translates to:
  /// **'Selected location'**
  String get group_event_selected_location;

  /// No description provided for @group_event_pin_unnamed.
  ///
  /// In en, this message translates to:
  /// **'Pinned location'**
  String get group_event_pin_unnamed;

  /// No description provided for @group_event_confirm_location.
  ///
  /// In en, this message translates to:
  /// **'Confirm location'**
  String get group_event_confirm_location;

  /// No description provided for @group_event_name_location.
  ///
  /// In en, this message translates to:
  /// **'Name the location'**
  String get group_event_name_location;

  /// No description provided for @group_event_venue_name.
  ///
  /// In en, this message translates to:
  /// **'Venue name'**
  String get group_event_venue_name;

  /// No description provided for @group_event_venue_name_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Vajrasattva Dharma Center'**
  String get group_event_venue_name_hint;

  /// No description provided for @group_event_save_venue.
  ///
  /// In en, this message translates to:
  /// **'Save venue'**
  String get group_event_save_venue;

  /// No description provided for @group_event_live_link.
  ///
  /// In en, this message translates to:
  /// **'Live link'**
  String get group_event_live_link;

  /// No description provided for @group_event_live_link_hint.
  ///
  /// In en, this message translates to:
  /// **'youtube.com/… or a meeting link'**
  String get group_event_live_link_hint;

  /// No description provided for @group_event_use_channel_link.
  ///
  /// In en, this message translates to:
  /// **'Use channel link'**
  String get group_event_use_channel_link;

  /// No description provided for @group_event_live_link_youtube_help.
  ///
  /// In en, this message translates to:
  /// **'Your space\'s YouTube live. It plays inside WeBuddhist. Paste a different link to change it.'**
  String get group_event_live_link_youtube_help;

  /// No description provided for @group_event_live_link_custom_help.
  ///
  /// In en, this message translates to:
  /// **'Custom link. Viewers open it outside WeBuddhist.'**
  String get group_event_live_link_custom_help;

  /// No description provided for @group_event_live_link_invalid.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a link yet'**
  String get group_event_live_link_invalid;

  /// No description provided for @group_event_pick_date_hint.
  ///
  /// In en, this message translates to:
  /// **'Pick a date to continue'**
  String get group_event_pick_date_hint;

  /// No description provided for @group_event_pick_repeats_hint.
  ///
  /// In en, this message translates to:
  /// **'Choose how it repeats to continue'**
  String get group_event_pick_repeats_hint;

  /// No description provided for @group_event_end_date_hint.
  ///
  /// In en, this message translates to:
  /// **'End date must be after the start date'**
  String get group_event_end_date_hint;

  /// No description provided for @group_event_end_time_hint.
  ///
  /// In en, this message translates to:
  /// **'End time must be after the start time'**
  String get group_event_end_time_hint;

  /// No description provided for @group_event_venue_hint.
  ///
  /// In en, this message translates to:
  /// **'Choose a venue to continue'**
  String get group_event_venue_hint;

  /// No description provided for @group_event_link_required_hint.
  ///
  /// In en, this message translates to:
  /// **'Add a meeting link to continue'**
  String get group_event_link_required_hint;

  /// No description provided for @group_event_map_attribution.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap contributors'**
  String get group_event_map_attribution;

  /// No description provided for @group_event_step_practices.
  ///
  /// In en, this message translates to:
  /// **'Practices & videos'**
  String get group_event_step_practices;

  /// No description provided for @group_event_optional_note.
  ///
  /// In en, this message translates to:
  /// **'Everything here is optional. You can add these details later.'**
  String get group_event_optional_note;

  /// No description provided for @group_event_practices_section.
  ///
  /// In en, this message translates to:
  /// **'Event practices'**
  String get group_event_practices_section;

  /// No description provided for @group_event_add_practice.
  ///
  /// In en, this message translates to:
  /// **'Add practice'**
  String get group_event_add_practice;

  /// No description provided for @group_event_practice_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search your space\'s practices'**
  String get group_event_practice_search_hint;

  /// No description provided for @group_event_practice_filter_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get group_event_practice_filter_all;

  /// No description provided for @group_event_practice_filter_content.
  ///
  /// In en, this message translates to:
  /// **'Plans & series'**
  String get group_event_practice_filter_content;

  /// No description provided for @group_event_practice_filter_collections.
  ///
  /// In en, this message translates to:
  /// **'Chant collections'**
  String get group_event_practice_filter_collections;

  /// No description provided for @group_event_practice_filter_accumulators.
  ///
  /// In en, this message translates to:
  /// **'Accumulations'**
  String get group_event_practice_filter_accumulators;

  /// No description provided for @group_event_practice_rule.
  ///
  /// In en, this message translates to:
  /// **'One plan or series and one chant collection per event. Add as many accumulations as you need.'**
  String get group_event_practice_rule;

  /// No description provided for @group_event_practice_replaced.
  ///
  /// In en, this message translates to:
  /// **'Choosing {chosen} replaced {previous}.'**
  String group_event_practice_replaced(String chosen, String previous);

  /// No description provided for @group_event_practices_empty.
  ///
  /// In en, this message translates to:
  /// **'No practices in this space yet'**
  String get group_event_practices_empty;

  /// No description provided for @group_event_practices_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load practices. Please try again.'**
  String get group_event_practices_load_error;

  /// No description provided for @group_event_practices_none_match.
  ///
  /// In en, this message translates to:
  /// **'No practices match'**
  String get group_event_practices_none_match;

  /// No description provided for @group_event_add_practices_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural,\n=0 {Add practices}\n=1 {Add 1 practice}\nother {Add {count} practices}\n}'**
  String group_event_add_practices_count(int count);

  /// No description provided for @group_event_counted_by.
  ///
  /// In en, this message translates to:
  /// **'Counted by'**
  String get group_event_counted_by;

  /// No description provided for @group_event_count_mode_title.
  ///
  /// In en, this message translates to:
  /// **'Who adds the count?'**
  String get group_event_count_mode_title;

  /// No description provided for @group_event_count_mode_attendees.
  ///
  /// In en, this message translates to:
  /// **'Attendees add in app'**
  String get group_event_count_mode_attendees;

  /// No description provided for @group_event_count_mode_attendees_hint.
  ///
  /// In en, this message translates to:
  /// **'Each person adds their own recitations, during or after the event'**
  String get group_event_count_mode_attendees_hint;

  /// No description provided for @group_event_count_mode_admin.
  ///
  /// In en, this message translates to:
  /// **'Admin adds for in-person attendees'**
  String get group_event_count_mode_admin;

  /// No description provided for @group_event_count_mode_admin_hint.
  ///
  /// In en, this message translates to:
  /// **'You enter the group\'s count, i.e. people × rounds'**
  String get group_event_count_mode_admin_hint;

  /// No description provided for @group_event_count_mode_admin_short.
  ///
  /// In en, this message translates to:
  /// **'Admin adds'**
  String get group_event_count_mode_admin_short;

  /// No description provided for @group_event_count_mode_attendees_taken.
  ///
  /// In en, this message translates to:
  /// **'Another accumulation already uses this. Attendees can add counts to only one accumulation per event.'**
  String get group_event_count_mode_attendees_taken;

  /// No description provided for @group_event_remove_practice.
  ///
  /// In en, this message translates to:
  /// **'Remove {title}'**
  String group_event_remove_practice(String title);

  /// No description provided for @group_event_videos_section.
  ///
  /// In en, this message translates to:
  /// **'About videos'**
  String get group_event_videos_section;

  /// No description provided for @group_event_videos_hint.
  ///
  /// In en, this message translates to:
  /// **'Shown on the event\'s About page. Use them to introduce the event or explain what to expect.'**
  String get group_event_videos_hint;

  /// No description provided for @group_event_add_video.
  ///
  /// In en, this message translates to:
  /// **'Add video'**
  String get group_event_add_video;

  /// No description provided for @group_event_video_link.
  ///
  /// In en, this message translates to:
  /// **'YouTube link'**
  String get group_event_video_link;

  /// No description provided for @group_event_video_link_hint.
  ///
  /// In en, this message translates to:
  /// **'https://youtu.be/…'**
  String get group_event_video_link_hint;

  /// No description provided for @group_event_paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get group_event_paste;

  /// No description provided for @group_event_video_loading.
  ///
  /// In en, this message translates to:
  /// **'Getting video details…'**
  String get group_event_video_loading;

  /// No description provided for @group_event_video_invalid.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a YouTube link. Paste a link from YouTube.'**
  String get group_event_video_invalid;

  /// No description provided for @group_event_video_source.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get group_event_video_source;

  /// No description provided for @group_event_video_untitled.
  ///
  /// In en, this message translates to:
  /// **'YouTube video'**
  String get group_event_video_untitled;

  /// No description provided for @group_event_remove_video.
  ///
  /// In en, this message translates to:
  /// **'Remove video'**
  String get group_event_remove_video;

  /// No description provided for @group_event_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get group_event_skip;

  /// No description provided for @group_event_step_review.
  ///
  /// In en, this message translates to:
  /// **'Review & publish'**
  String get group_event_step_review;

  /// No description provided for @group_event_review_event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get group_event_review_event;

  /// No description provided for @group_event_review_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get group_event_review_settings;

  /// No description provided for @group_event_review_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get group_event_review_name;

  /// No description provided for @group_event_review_languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get group_event_review_languages;

  /// No description provided for @group_event_review_when.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get group_event_review_when;

  /// No description provided for @group_event_review_where.
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get group_event_review_where;

  /// No description provided for @group_event_review_live_link.
  ///
  /// In en, this message translates to:
  /// **'Live link'**
  String get group_event_review_live_link;

  /// No description provided for @group_event_review_practices.
  ///
  /// In en, this message translates to:
  /// **'Practices'**
  String get group_event_review_practices;

  /// No description provided for @group_event_review_videos.
  ///
  /// In en, this message translates to:
  /// **'About videos'**
  String get group_event_review_videos;

  /// No description provided for @group_event_review_event_settings.
  ///
  /// In en, this message translates to:
  /// **'Event settings'**
  String get group_event_review_event_settings;

  /// No description provided for @group_event_review_none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get group_event_review_none;

  /// No description provided for @group_event_review_tap_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap any row to change it.'**
  String get group_event_review_tap_hint;

  /// No description provided for @group_event_review_notify_hint.
  ///
  /// In en, this message translates to:
  /// **'Members are notified when you publish.'**
  String get group_event_review_notify_hint;

  /// No description provided for @group_event_review_more.
  ///
  /// In en, this message translates to:
  /// **'{first} + {count} more'**
  String group_event_review_more(String first, int count);

  /// No description provided for @group_event_review_recurring_from.
  ///
  /// In en, this message translates to:
  /// **'{rule} · {times} · from {date}'**
  String group_event_review_recurring_from(
    String rule,
    String times,
    String date,
  );

  /// No description provided for @group_event_review_youtube_live.
  ///
  /// In en, this message translates to:
  /// **'YouTube live'**
  String get group_event_review_youtube_live;

  /// No description provided for @group_event_review_online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get group_event_review_online;

  /// No description provided for @group_event_chat_on.
  ///
  /// In en, this message translates to:
  /// **'Chat on'**
  String get group_event_chat_on;

  /// No description provided for @group_event_chat_off.
  ///
  /// In en, this message translates to:
  /// **'Chat off'**
  String get group_event_chat_off;

  /// No description provided for @group_event_notifications_on.
  ///
  /// In en, this message translates to:
  /// **'Notifications on'**
  String get group_event_notifications_on;

  /// No description provided for @group_event_notifications_off.
  ///
  /// In en, this message translates to:
  /// **'Notifications off'**
  String get group_event_notifications_off;

  /// No description provided for @group_event_all_intentions.
  ///
  /// In en, this message translates to:
  /// **'All intentions'**
  String get group_event_all_intentions;

  /// No description provided for @group_event_intentions_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural,\n=1 {1 intention}\nother {{count} intentions}\n}'**
  String group_event_intentions_count(int count);

  /// No description provided for @group_event_publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get group_event_publish;

  /// No description provided for @group_event_publish_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to publish the event. Please try again'**
  String get group_event_publish_error;

  /// No description provided for @group_event_settings_title.
  ///
  /// In en, this message translates to:
  /// **'Event settings'**
  String get group_event_settings_title;

  /// No description provided for @group_event_settings_chat.
  ///
  /// In en, this message translates to:
  /// **'Event chat'**
  String get group_event_settings_chat;

  /// No description provided for @group_event_settings_chat_hint.
  ///
  /// In en, this message translates to:
  /// **'Gives the event its own chat, where members can talk and post prayer requests.'**
  String get group_event_settings_chat_hint;

  /// No description provided for @group_event_settings_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get group_event_settings_notifications;

  /// No description provided for @group_event_settings_notifications_hint.
  ///
  /// In en, this message translates to:
  /// **'The notice when you publish, the reminder before it starts, and any you send yourself.'**
  String get group_event_settings_notifications_hint;

  /// No description provided for @group_event_settings_intentions.
  ///
  /// In en, this message translates to:
  /// **'Prayer intentions'**
  String get group_event_settings_intentions;

  /// No description provided for @group_event_settings_intentions_hint.
  ///
  /// In en, this message translates to:
  /// **'Leave all unchecked to allow every intention.'**
  String get group_event_settings_intentions_hint;

  /// No description provided for @group_event_settings_intentions_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load intentions right now.'**
  String get group_event_settings_intentions_error;

  /// No description provided for @group_event_published_title.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get group_event_published_title;

  /// No description provided for @group_event_published_headline.
  ///
  /// In en, this message translates to:
  /// **'{name} is live'**
  String group_event_published_headline(String name);

  /// No description provided for @group_event_published_message.
  ///
  /// In en, this message translates to:
  /// **'Members of {group} have been notified. You can edit it any time from the event page.'**
  String group_event_published_message(String group);

  /// No description provided for @group_event_published_message_silent.
  ///
  /// In en, this message translates to:
  /// **'You can edit it any time from the event page.'**
  String get group_event_published_message_silent;

  /// No description provided for @group_event_view_event.
  ///
  /// In en, this message translates to:
  /// **'View event'**
  String get group_event_view_event;

  /// No description provided for @group_event_drafts_section.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get group_event_drafts_section;

  /// No description provided for @group_event_draft_label.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get group_event_draft_label;

  /// No description provided for @group_event_draft_untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled event'**
  String get group_event_draft_untitled;

  /// No description provided for @group_event_draft_menu_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue editing'**
  String get group_event_draft_menu_continue;

  /// No description provided for @group_event_draft_menu_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete draft'**
  String get group_event_draft_menu_delete;

  /// No description provided for @group_event_draft_menu_delete_hint.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone'**
  String get group_event_draft_menu_delete_hint;

  /// No description provided for @group_event_draft_saved.
  ///
  /// In en, this message translates to:
  /// **'Saved as draft'**
  String get group_event_draft_saved;

  /// No description provided for @group_event_draft_save_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to save the draft. Please try again'**
  String get group_event_draft_save_error;

  /// No description provided for @group_event_draft_deleted.
  ///
  /// In en, this message translates to:
  /// **'Draft deleted'**
  String get group_event_draft_deleted;

  /// No description provided for @group_event_draft_delete_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete the draft. Please try again'**
  String get group_event_draft_delete_error;

  /// No description provided for @group_event_draft_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete draft?'**
  String get group_event_draft_delete_title;

  /// No description provided for @group_event_draft_delete_message.
  ///
  /// In en, this message translates to:
  /// **'This draft will be permanently removed'**
  String get group_event_draft_delete_message;

  /// No description provided for @group_event_edit_draft_title.
  ///
  /// In en, this message translates to:
  /// **'Edit draft'**
  String get group_event_edit_draft_title;

  /// No description provided for @group_event_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get group_event_edit_title;

  /// No description provided for @group_event_save_changes.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get group_event_save_changes;

  /// No description provided for @group_event_changes_saved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get group_event_changes_saved;

  /// No description provided for @group_event_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage event'**
  String get group_event_manage;

  /// No description provided for @group_event_manage_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get group_event_manage_details;

  /// No description provided for @group_event_manage_counts.
  ///
  /// In en, this message translates to:
  /// **'Counts'**
  String get group_event_manage_counts;

  /// No description provided for @group_event_manage_accumulations.
  ///
  /// In en, this message translates to:
  /// **'Accumulations'**
  String get group_event_manage_accumulations;

  /// No description provided for @group_event_manage_admin_adds_pending.
  ///
  /// In en, this message translates to:
  /// **'Admin adds'**
  String get group_event_manage_admin_adds_pending;

  /// No description provided for @group_event_manage_admin_adds.
  ///
  /// In en, this message translates to:
  /// **'Admin adds · {count} so far'**
  String group_event_manage_admin_adds(String count);

  /// No description provided for @group_event_manage_attendees_add_pending.
  ///
  /// In en, this message translates to:
  /// **'Attendees add in app'**
  String get group_event_manage_attendees_add_pending;

  /// No description provided for @group_event_manage_attendees_add.
  ///
  /// In en, this message translates to:
  /// **'{people, plural,\n=1 {Attendees add in app · {count} from 1 person}\nother {Attendees add in app · {count} from {people} people}\n}'**
  String group_event_manage_attendees_add(String count, int people);

  /// No description provided for @group_event_manage_add_count.
  ///
  /// In en, this message translates to:
  /// **'Add count'**
  String get group_event_manage_add_count;

  /// No description provided for @group_event_manage_no_accumulations.
  ///
  /// In en, this message translates to:
  /// **'This event has no accumulations.'**
  String get group_event_manage_no_accumulations;

  /// No description provided for @group_event_manage_recurring_note.
  ///
  /// In en, this message translates to:
  /// **'Attendee lists aren\'t kept for recurring events. Counts add up across all sessions.'**
  String get group_event_manage_recurring_note;

  /// No description provided for @group_event_in_person_of_target.
  ///
  /// In en, this message translates to:
  /// **'{count} of {target}'**
  String group_event_in_person_of_target(String count, String target);

  /// No description provided for @group_event_in_person_in_total.
  ///
  /// In en, this message translates to:
  /// **'{count} in total'**
  String group_event_in_person_in_total(String count);

  /// No description provided for @group_event_in_person_legend_app.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get group_event_in_person_legend_app;

  /// No description provided for @group_event_in_person_legend_in_person.
  ///
  /// In en, this message translates to:
  /// **'In person'**
  String get group_event_in_person_legend_in_person;

  /// No description provided for @group_event_in_person_add_day.
  ///
  /// In en, this message translates to:
  /// **'Add day'**
  String get group_event_in_person_add_day;

  /// No description provided for @group_event_in_person_day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get group_event_in_person_day;

  /// No description provided for @group_event_in_person_count.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get group_event_in_person_count;

  /// No description provided for @group_event_in_person_empty.
  ///
  /// In en, this message translates to:
  /// **'No in-person counts yet.'**
  String get group_event_in_person_empty;

  /// No description provided for @group_event_in_person_invalid_count.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number of at least 1'**
  String get group_event_in_person_invalid_count;

  /// No description provided for @group_event_in_person_added.
  ///
  /// In en, this message translates to:
  /// **'In-person count added'**
  String get group_event_in_person_added;

  /// No description provided for @group_event_in_person_updated.
  ///
  /// In en, this message translates to:
  /// **'In-person count updated'**
  String get group_event_in_person_updated;

  /// No description provided for @group_event_in_person_deleted.
  ///
  /// In en, this message translates to:
  /// **'In-person count deleted'**
  String get group_event_in_person_deleted;

  /// No description provided for @group_event_in_person_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete in-person count?'**
  String get group_event_in_person_delete_title;

  /// No description provided for @group_event_in_person_delete_message.
  ///
  /// In en, this message translates to:
  /// **'{count} for {day} will be taken off the accumulation\'s total.'**
  String group_event_in_person_delete_message(String count, String day);

  /// No description provided for @group_event_in_person_exists.
  ///
  /// In en, this message translates to:
  /// **'That day already has a count. Edit it instead.'**
  String get group_event_in_person_exists;

  /// No description provided for @group_event_in_person_no_accumulation.
  ///
  /// In en, this message translates to:
  /// **'Link a group accumulation to this event to record in-person counts.'**
  String get group_event_in_person_no_accumulation;

  /// No description provided for @group_event_in_person_save_error.
  ///
  /// In en, this message translates to:
  /// **'Could not save the count.'**
  String get group_event_in_person_save_error;

  /// No description provided for @group_event_in_person_load_more.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get group_event_in_person_load_more;

  /// No description provided for @mala_failed_load_catalogue_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load catalogue'**
  String get mala_failed_load_catalogue_error;

  /// No description provided for @chant_collection_reload_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to reload collection to reorder'**
  String get chant_collection_reload_error;

  /// No description provided for @chant_collection_reorder_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to reorder chants'**
  String get chant_collection_reorder_error;

  /// No description provided for @timer_duration_label.
  ///
  /// In en, this message translates to:
  /// **'DURATION'**
  String get timer_duration_label;

  /// No description provided for @timer_ambient_sound_label.
  ///
  /// In en, this message translates to:
  /// **'AMBIENT SOUND'**
  String get timer_ambient_sound_label;

  /// No description provided for @timer_begin_session.
  ///
  /// In en, this message translates to:
  /// **'Begin session'**
  String get timer_begin_session;

  /// No description provided for @timer_save_changes.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get timer_save_changes;

  /// No description provided for @timer_new_title.
  ///
  /// In en, this message translates to:
  /// **'New timer'**
  String get timer_new_title;

  /// No description provided for @timer_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit timer'**
  String get timer_edit_title;

  /// No description provided for @timer_your_timers.
  ///
  /// In en, this message translates to:
  /// **'Your timers'**
  String get timer_your_timers;

  /// No description provided for @timer_custom_timer.
  ///
  /// In en, this message translates to:
  /// **'Custom timer'**
  String get timer_custom_timer;

  /// No description provided for @timer_ambient_sounds_title.
  ///
  /// In en, this message translates to:
  /// **'Ambient sounds'**
  String get timer_ambient_sounds_title;

  /// No description provided for @timer_ambient_sound_none.
  ///
  /// In en, this message translates to:
  /// **'Default (no sound)'**
  String get timer_ambient_sound_none;

  /// No description provided for @timer_ambient_sounds_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load ambient sounds'**
  String get timer_ambient_sounds_load_error;

  /// No description provided for @timer_volume_label.
  ///
  /// In en, this message translates to:
  /// **'VOLUME'**
  String get timer_volume_label;

  /// No description provided for @timer_duration_title.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get timer_duration_title;

  /// No description provided for @timer_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit timer'**
  String get timer_edit;

  /// No description provided for @timer_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete timer'**
  String get timer_delete;

  /// No description provided for @timer_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete timer?'**
  String get timer_delete_title;

  /// No description provided for @timer_delete_message.
  ///
  /// In en, this message translates to:
  /// **'This timer will be removed from your timers.'**
  String get timer_delete_message;

  /// No description provided for @timer_duration_must_be_greater_than_error.
  ///
  /// In en, this message translates to:
  /// **'Duration must be greater than 0'**
  String get timer_duration_must_be_greater_than_error;

  /// No description provided for @splash_tagline_1.
  ///
  /// In en, this message translates to:
  /// **'We Buddhists practice together'**
  String get splash_tagline_1;

  /// No description provided for @splash_tagline_2.
  ///
  /// In en, this message translates to:
  /// **'We Buddhists practice daily'**
  String get splash_tagline_2;

  /// No description provided for @timer_list_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap play to begin, or build your own.'**
  String get timer_list_subtitle;

  /// No description provided for @timer_create_custom.
  ///
  /// In en, this message translates to:
  /// **'Create a custom timer'**
  String get timer_create_custom;

  /// No description provided for @timer_create_custom_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Set duration, bells and ambient sound'**
  String get timer_create_custom_subtitle;

  /// No description provided for @timer_starting.
  ///
  /// In en, this message translates to:
  /// **'Starting...'**
  String get timer_starting;

  /// No description provided for @timer_duration_hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get timer_duration_hours;

  /// No description provided for @timer_duration_sec.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get timer_duration_sec;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bo',
    'en',
    'hi',
    'mn',
    'ne',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bo':
      return AppLocalizationsBo();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mn':
      return AppLocalizationsMn();
    case 'ne':
      return AppLocalizationsNe();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

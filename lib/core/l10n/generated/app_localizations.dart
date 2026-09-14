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
  /// **'Choose your language:'**
  String get onboarding_first_question;

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
  /// **'Here\'s what\'s ready for your practice.'**
  String get onboarding_all_set_description;

  /// No description provided for @onboarding_all_set_feature_practices.
  ///
  /// In en, this message translates to:
  /// **'Chants, accumulations, meditation, and study plans to choose from'**
  String get onboarding_all_set_feature_practices;

  /// No description provided for @onboarding_all_set_feature_reminders.
  ///
  /// In en, this message translates to:
  /// **'Gentle daily reminders, whenever you\'re ready'**
  String get onboarding_all_set_feature_reminders;

  /// No description provided for @onboarding_begin_practice.
  ///
  /// In en, this message translates to:
  /// **'Find your first practices'**
  String get onboarding_begin_practice;

  /// No description provided for @onboarding_2_title.
  ///
  /// In en, this message translates to:
  /// **'Next, here\'s how it works.'**
  String get onboarding_2_title;

  /// No description provided for @onboarding_2_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Three small steps to build the habit'**
  String get onboarding_2_subtitle;

  /// No description provided for @onboarding_2_step1_title.
  ///
  /// In en, this message translates to:
  /// **'Choose your practices'**
  String get onboarding_2_step1_title;

  /// No description provided for @onboarding_2_step1_desc.
  ///
  /// In en, this message translates to:
  /// **'Chant, count mantras, set a meditation timer, or follow a study plan from your tradition.'**
  String get onboarding_2_step1_desc;

  /// No description provided for @onboarding_2_step2_title.
  ///
  /// In en, this message translates to:
  /// **'Add them to your day'**
  String get onboarding_2_step2_title;

  /// No description provided for @onboarding_2_step2_desc.
  ///
  /// In en, this message translates to:
  /// **'Build a daily routine and we\'ll send gentle reminders to keep it going.'**
  String get onboarding_2_step2_desc;

  /// No description provided for @onboarding_2_step3_title.
  ///
  /// In en, this message translates to:
  /// **'Practice a few minutes a day'**
  String get onboarding_2_step3_title;

  /// No description provided for @onboarding_2_step3_desc.
  ///
  /// In en, this message translates to:
  /// **'Even a moment counts. Day by day, your practice grows.'**
  String get onboarding_2_step3_desc;

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
  /// **'Group accumulation'**
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
  /// **'Add the number of mala rounds you did outside this app.'**
  String get mala_add_rounds_message;

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
  /// **'Your current count will go back to zero, but your accumulations will stay in your lifetime total.'**
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

  /// No description provided for @mala_counter_semantics.
  ///
  /// In en, this message translates to:
  /// **'Count {bead} of {total}, {rounds}'**
  String mala_counter_semantics(int bead, int total, String rounds);

  /// No description provided for @mala_group_accumulations.
  ///
  /// In en, this message translates to:
  /// **'Group accumulations'**
  String get mala_group_accumulations;

  /// No description provided for @mala_groups_section.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get mala_groups_section;

  /// No description provided for @mala_group_untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled group'**
  String get mala_group_untitled;

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
  /// **'Meditation Timer'**
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

  /// No description provided for @choose_image.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get choose_image;

  /// No description provided for @choose_bg_image.
  ///
  /// In en, this message translates to:
  /// **'Choose a background image'**
  String get choose_bg_image;

  /// No description provided for @create_image.
  ///
  /// In en, this message translates to:
  /// **'Create image'**
  String get create_image;

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
  /// **'This collection will be permanently removed.'**
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
  /// **'{count, plural, =0{0 chants} =1{1 chant} other{{count} chants}}'**
  String my_recitation_collection_chant_count(int count);

  /// No description provided for @my_recitation_collection_chant_count_owner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 chants • me} =1{1 chant • me} other{{count} chants • me}}'**
  String my_recitation_collection_chant_count_owner(int count);

  /// No description provided for @bookmarks_empty_chant_collections_title.
  ///
  /// In en, this message translates to:
  /// **'No chant collections bookmarked yet.'**
  String get bookmarks_empty_chant_collections_title;

  /// No description provided for @bookmarks_empty_chant_collections_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmark a chant collection to save it here.'**
  String get bookmarks_empty_chant_collections_subtitle;

  /// No description provided for @notification_settings.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notification_settings;

  /// No description provided for @notification_allow_title.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get notification_allow_title;

  /// No description provided for @notification_allow_subtitle_enabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications are enabled for this app'**
  String get notification_allow_subtitle_enabled;

  /// No description provided for @notification_allow_subtitle_disabled.
  ///
  /// In en, this message translates to:
  /// **'Permission needed. Tap to grant in Settings.'**
  String get notification_allow_subtitle_disabled;

  /// No description provided for @notification_allow_subtitle_paused.
  ///
  /// In en, this message translates to:
  /// **'Reminders are paused. Tap to resume.'**
  String get notification_allow_subtitle_paused;

  /// No description provided for @notification_routine_title.
  ///
  /// In en, this message translates to:
  /// **'Plan reminders'**
  String get notification_routine_title;

  /// No description provided for @notification_routine_subtitle_enabled.
  ///
  /// In en, this message translates to:
  /// **'Daily reminders for your plans'**
  String get notification_routine_subtitle_enabled;

  /// No description provided for @notification_routine_subtitle_disabled.
  ///
  /// In en, this message translates to:
  /// **'Plan reminders are paused. Tap to resume'**
  String get notification_routine_subtitle_disabled;

  /// No description provided for @notification_battery_title.
  ///
  /// In en, this message translates to:
  /// **'Background reminders'**
  String get notification_battery_title;

  /// No description provided for @notification_battery_subtitle_enabled.
  ///
  /// In en, this message translates to:
  /// **'Your reminders are sent on time, even when the app is closed.'**
  String get notification_battery_subtitle_enabled;

  /// No description provided for @notification_battery_subtitle_disabled.
  ///
  /// In en, this message translates to:
  /// **'Some Android phones pause background apps to save battery, which can delay or skip your reminders. Tap to keep yours running.'**
  String get notification_battery_subtitle_disabled;

  /// No description provided for @notification_recitation_title.
  ///
  /// In en, this message translates to:
  /// **'Chant reminders'**
  String get notification_recitation_title;

  /// No description provided for @notification_recitation_subtitle_enabled.
  ///
  /// In en, this message translates to:
  /// **'Daily reminders for your chants'**
  String get notification_recitation_subtitle_enabled;

  /// No description provided for @notification_recitation_subtitle_disabled.
  ///
  /// In en, this message translates to:
  /// **'Chant reminders are paused. Tap to resume'**
  String get notification_recitation_subtitle_disabled;

  /// No description provided for @notification_practice_title.
  ///
  /// In en, this message translates to:
  /// **'Mala reminders'**
  String get notification_practice_title;

  /// No description provided for @notification_practice_subtitle_enabled.
  ///
  /// In en, this message translates to:
  /// **'Daily reminders for your mala practice'**
  String get notification_practice_subtitle_enabled;

  /// No description provided for @notification_practice_subtitle_disabled.
  ///
  /// In en, this message translates to:
  /// **'Mala reminders are paused. Tap to resume.'**
  String get notification_practice_subtitle_disabled;

  /// No description provided for @notification_timer_title.
  ///
  /// In en, this message translates to:
  /// **'Timer reminders'**
  String get notification_timer_title;

  /// No description provided for @notification_timer_subtitle_enabled.
  ///
  /// In en, this message translates to:
  /// **'Daily reminders for your timer sessions'**
  String get notification_timer_subtitle_enabled;

  /// No description provided for @notification_timer_subtitle_disabled.
  ///
  /// In en, this message translates to:
  /// **'Timer reminders are paused. Tap to resume.'**
  String get notification_timer_subtitle_disabled;

  /// No description provided for @notification_battery_info_title.
  ///
  /// In en, this message translates to:
  /// **'About background reminders'**
  String get notification_battery_info_title;

  /// No description provided for @notification_battery_info_body.
  ///
  /// In en, this message translates to:
  /// **'Some Android phones pause background apps to save battery, which can delay or cancel your scheduled reminders. Exempting the app keeps your reminders reliably on time.'**
  String get notification_battery_info_body;

  /// No description provided for @notification_snack_permission_denied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked. Turn them on in Settings'**
  String get notification_snack_permission_denied;

  /// No description provided for @notification_snack_disable_alarms_in_settings.
  ///
  /// In en, this message translates to:
  /// **'Turn off alarms & reminders in Settings.'**
  String get notification_snack_disable_alarms_in_settings;

  /// No description provided for @notification_snack_battery_reenable.
  ///
  /// In en, this message translates to:
  /// **'Restore battery optimization in Settings → Battery.'**
  String get notification_snack_battery_reenable;

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
  /// **'Continue your practice on any device, wherever you go.'**
  String get auth_drawer_subtitle;

  /// No description provided for @routine_delete_block_message.
  ///
  /// In en, this message translates to:
  /// **'The session and all its items will be removed'**
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
  /// **'How do you follow the Buddha?'**
  String get onboarding_tradition_title;

  /// No description provided for @onboarding_tradition_subtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll show you the practices and texts of your path. You can change this anytime in the app settings.'**
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

  /// No description provided for @onboarding_tradition_show_all_description.
  ///
  /// In en, this message translates to:
  /// **'Practices and texts from every path'**
  String get onboarding_tradition_show_all_description;

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
  /// **'Find your groups and practice together'**
  String get connect_subtitle;

  /// No description provided for @discover_groups.
  ///
  /// In en, this message translates to:
  /// **'Discover groups'**
  String get discover_groups;

  /// No description provided for @my_groups.
  ///
  /// In en, this message translates to:
  /// **'My groups'**
  String get my_groups;

  /// No description provided for @see_all.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get see_all;

  /// No description provided for @connect_groups_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load groups.\nCheck your connection and try again'**
  String get connect_groups_load_error;

  /// No description provided for @connect_groups_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No more groups'**
  String get connect_groups_empty_title;

  /// No description provided for @connect_groups_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Congratulations, you\'ve joined all our groups! Check back soon. New ones are on the way'**
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
  /// **'Groups'**
  String get connect_tab_groups;

  /// No description provided for @connect_segment_my.
  ///
  /// In en, this message translates to:
  /// **'For you'**
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
  /// **'No groups to discover'**
  String get connect_empty_discover_groups;

  /// No description provided for @connect_empty_discover_practices.
  ///
  /// In en, this message translates to:
  /// **'No practices to discover'**
  String get connect_empty_discover_practices;

  /// No description provided for @connect_all_groups.
  ///
  /// In en, this message translates to:
  /// **'All groups'**
  String get connect_all_groups;

  /// No description provided for @connect_my_empty_feed_title.
  ///
  /// In en, this message translates to:
  /// **'Your groups have been quiet'**
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
  /// **'No groups yet'**
  String get connect_my_empty_groups_title;

  /// No description provided for @connect_my_empty_feed_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing new from the groups you have joined. Other groups are posting today.'**
  String get connect_my_empty_feed_subtitle;

  /// No description provided for @connect_my_empty_events_subtitle.
  ///
  /// In en, this message translates to:
  /// **'None of your groups have anything scheduled. Other groups have events open to everyone.'**
  String get connect_my_empty_events_subtitle;

  /// No description provided for @connect_my_empty_posts_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your groups have not posted anything. See what other groups are sharing.'**
  String get connect_my_empty_posts_subtitle;

  /// No description provided for @connect_my_empty_groups_subtitle.
  ///
  /// In en, this message translates to:
  /// **'You have not joined any groups yet. Discover communities to practice with.'**
  String get connect_my_empty_groups_subtitle;

  /// No description provided for @connect_my_empty_feed_browse.
  ///
  /// In en, this message translates to:
  /// **'See what other groups share'**
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
  /// **'Your groups have not started any practices. See what other groups are offering.'**
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
  /// **'This comment will be permanently removed.'**
  String get connect_comment_delete_message;

  /// No description provided for @connect_comment_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete comment'**
  String get connect_comment_delete_failed;

  /// No description provided for @connect_post_comments_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 comment} other{{count} comments}}'**
  String connect_post_comments_count(int count);

  /// No description provided for @connect_post_comments_empty.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Start the conversation.'**
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

  /// No description provided for @home_group_events.
  ///
  /// In en, this message translates to:
  /// **'Group Events'**
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
  /// **'No poems yet. Check back soon.'**
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
  /// **'Group'**
  String get connect_group_fallback_title;

  /// No description provided for @connect_event_attend.
  ///
  /// In en, this message translates to:
  /// **'Attend'**
  String get connect_event_attend;

  /// No description provided for @connect_event_attending.
  ///
  /// In en, this message translates to:
  /// **'Attending'**
  String get connect_event_attending;

  /// No description provided for @connect_event_participants_attending.
  ///
  /// In en, this message translates to:
  /// **'{count} attending'**
  String connect_event_participants_attending(int count);

  /// No description provided for @connect_event_participants_empty.
  ///
  /// In en, this message translates to:
  /// **'No participants yet'**
  String get connect_event_participants_empty;

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
  /// **'More about this event'**
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
  /// **'Add the number of recitations you did with the livestream or outside this app.'**
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
  /// **'Search groups'**
  String get search_groups;

  /// No description provided for @search_for_groups.
  ///
  /// In en, this message translates to:
  /// **'Search for groups'**
  String get search_for_groups;

  /// No description provided for @no_groups_found.
  ///
  /// In en, this message translates to:
  /// **'No matching groups found'**
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
  /// **'Failed to load versions'**
  String get reader_versions_load_error;

  /// No description provided for @reader_scripts_load_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to load scripts'**
  String get reader_scripts_load_error;

  /// No description provided for @reader_languages_load_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to load languages'**
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

  /// No description provided for @image_share_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to share: {error}'**
  String image_share_error(String error);

  /// No description provided for @create_image_capture_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to create image. Please try again'**
  String get create_image_capture_error;

  /// No description provided for @create_image_share_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to share. Please try again'**
  String get create_image_share_error;

  /// No description provided for @create_image_save_success.
  ///
  /// In en, this message translates to:
  /// **'Image saved'**
  String get create_image_save_success;

  /// No description provided for @create_image_save_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to save image. Check that the app has photo access, or try again'**
  String get create_image_save_error;

  /// No description provided for @create_image_download_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to download your image. Please try again'**
  String get create_image_download_error;

  /// No description provided for @create_image_customize_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get create_image_customize_tooltip;

  /// No description provided for @create_image_text_too_long.
  ///
  /// In en, this message translates to:
  /// **'Text is too long to increase font size'**
  String get create_image_text_too_long;

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

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @plans_created.
  ///
  /// In en, this message translates to:
  /// **'Plan created'**
  String get plans_created;

  /// No description provided for @ai_chat_history.
  ///
  /// In en, this message translates to:
  /// **'Chat history'**
  String get ai_chat_history;

  /// No description provided for @ai_buddhist_assistant.
  ///
  /// In en, this message translates to:
  /// **'Build your daily rhythm. Set times, and we\'ll remind you to practice'**
  String get ai_buddhist_assistant;

  /// No description provided for @ai_new_chat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get ai_new_chat;

  /// No description provided for @ai_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get ai_retry;

  /// No description provided for @ai_dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get ai_dismiss;

  /// No description provided for @ai_sign_in_prompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use the Buddhist AI Assistant'**
  String get ai_sign_in_prompt;

  /// No description provided for @ai_explore_wisdom.
  ///
  /// In en, this message translates to:
  /// **'Explore Buddhist wisdom'**
  String get ai_explore_wisdom;

  /// No description provided for @ai_ask_question.
  ///
  /// In en, this message translates to:
  /// **'Ask a question...'**
  String get ai_ask_question;

  /// No description provided for @ai_search_chats.
  ///
  /// In en, this message translates to:
  /// **'Search for chats'**
  String get ai_search_chats;

  /// No description provided for @ai_chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get ai_chats;

  /// No description provided for @ai_chat_deleted.
  ///
  /// In en, this message translates to:
  /// **'Chat deleted'**
  String get ai_chat_deleted;

  /// No description provided for @ai_no_conversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get ai_no_conversations;

  /// No description provided for @ai_start_new_chat.
  ///
  /// In en, this message translates to:
  /// **'Start a new chat to begin.'**
  String get ai_start_new_chat;

  /// No description provided for @ai_delete_chat.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get ai_delete_chat;

  /// No description provided for @ai_delete_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this chat?'**
  String get ai_delete_confirmation;

  /// No description provided for @ai_delete_warning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get ai_delete_warning;

  /// No description provided for @ai_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get ai_confirm;

  /// No description provided for @ai_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get ai_delete;

  /// No description provided for @ai_greeting.
  ///
  /// In en, this message translates to:
  /// **'Hi {name}'**
  String ai_greeting(String name);

  /// No description provided for @ai_text_not_found.
  ///
  /// In en, this message translates to:
  /// **'Text not found.'**
  String get ai_text_not_found;

  /// No description provided for @ai_text_not_found_message.
  ///
  /// In en, this message translates to:
  /// **'We don\'t have \"{title}\" in our library yet.\n\nTry a different title, or ask another way'**
  String ai_text_not_found_message(String title);

  /// No description provided for @ai_sources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get ai_sources;

  /// No description provided for @ai_sources_count.
  ///
  /// In en, this message translates to:
  /// **'{count} sources'**
  String ai_sources_count(int count);

  /// No description provided for @search_no_results.
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{query}\"'**
  String search_no_results(String query);

  /// No description provided for @search_show_more.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get search_show_more;

  /// No description provided for @search_contents.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get search_contents;

  /// No description provided for @search_titles.
  ///
  /// In en, this message translates to:
  /// **'Titles'**
  String get search_titles;

  /// No description provided for @search_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get search_all;

  /// No description provided for @search_author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get search_author;

  /// No description provided for @search_tab_ai_mode.
  ///
  /// In en, this message translates to:
  /// **'AI mode'**
  String get search_tab_ai_mode;

  /// No description provided for @search_error.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String search_error(String message);

  /// No description provided for @search_retrying.
  ///
  /// In en, this message translates to:
  /// **'Retrying...'**
  String get search_retrying;

  /// No description provided for @search_no_titles_found.
  ///
  /// In en, this message translates to:
  /// **'No titles found for \"{query}\"'**
  String search_no_titles_found(String query);

  /// No description provided for @search_no_contents_found.
  ///
  /// In en, this message translates to:
  /// **'No contents found for \"{query}\"'**
  String search_no_contents_found(String query);

  /// No description provided for @search_no_authors_found.
  ///
  /// In en, this message translates to:
  /// **'No authors found for \"{query}\"'**
  String search_no_authors_found(String query);

  /// No description provided for @search_buddhist_texts.
  ///
  /// In en, this message translates to:
  /// **'Search Buddhist texts...'**
  String get search_buddhist_texts;

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
  /// **'Edit your practices'**
  String get routine_edit_title;

  /// No description provided for @routine_delete_block.
  ///
  /// In en, this message translates to:
  /// **'Remove session'**
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
  /// **'Remove session'**
  String get routine_empty_block_delete_singular;

  /// No description provided for @routine_empty_block_delete_plural.
  ///
  /// In en, this message translates to:
  /// **'Remove sessions'**
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
  /// **'Explore as a Guest'**
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
  /// **'This is no longer available. Edit your routine to update.'**
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
  /// **'Total plan days completed'**
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
  /// **'If you delete your account, all your information, history, and personalized settings within WeBuddhist will be permanently eliminated. Please note that this action is irreversible. To proceed, tap the button below.'**
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

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

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

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

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
  /// **'Members({count})'**
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

  /// No description provided for @group_request_to_join.
  ///
  /// In en, this message translates to:
  /// **'Request to join'**
  String get group_request_to_join;

  /// No description provided for @group_request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get group_request;

  /// No description provided for @group_request_sent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get group_request_sent;

  /// No description provided for @group_join_request_title.
  ///
  /// In en, this message translates to:
  /// **'Request to join'**
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
  /// **'Request sent — an admin will review it.'**
  String get group_join_request_sent_snackbar;

  /// No description provided for @group_join_request_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to send request. Please try again.'**
  String get group_join_request_error;

  /// No description provided for @group_members_only_title.
  ///
  /// In en, this message translates to:
  /// **'Members only'**
  String get group_members_only_title;

  /// No description provided for @group_members_only_message.
  ///
  /// In en, this message translates to:
  /// **'Join to see this group\'s chants, events and posts.'**
  String get group_members_only_message;

  /// No description provided for @group_join_request_waiting_title.
  ///
  /// In en, this message translates to:
  /// **'Waiting on an admin'**
  String get group_join_request_waiting_title;

  /// No description provided for @group_join_request_waiting_message.
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you as soon as your request is reviewed.'**
  String get group_join_request_waiting_message;

  /// No description provided for @group_members_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load members. Please try again.'**
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
  /// **'Change group practice'**
  String get group_change_practice_title;

  /// No description provided for @group_change_practice_message.
  ///
  /// In en, this message translates to:
  /// **'You are already practicing this plan with another group. Would you like to change your practice group?'**
  String get group_change_practice_message;

  /// No description provided for @group_join_to_contribute.
  ///
  /// In en, this message translates to:
  /// **'Join to contribute'**
  String get group_join_to_contribute;

  /// No description provided for @group_accumulator_join_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to join accumulation. Please try again.'**
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
  /// **'My Contributions'**
  String get group_accumulator_my_contributions;

  /// No description provided for @group_accumulator_recited.
  ///
  /// In en, this message translates to:
  /// **'Recited'**
  String get group_accumulator_recited;

  /// No description provided for @group_accumulator_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get group_accumulator_total;

  /// No description provided for @group_accumulator_contributions_empty.
  ///
  /// In en, this message translates to:
  /// **'Join this accumulation to track your contributions.'**
  String get group_accumulator_contributions_empty;

  /// No description provided for @group_accumulator_leaderboard_empty.
  ///
  /// In en, this message translates to:
  /// **'No recitations yet.'**
  String get group_accumulator_leaderboard_empty;

  /// No description provided for @group_accumulator_recite_now.
  ///
  /// In en, this message translates to:
  /// **'Recite now'**
  String get group_accumulator_recite_now;

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
  /// **'Add the number of chants you did outside this app.'**
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
  /// **'I completed {count} recitations in \"{accumulation}\", a group accumulation by {group} on WeBuddhist. Come join me!'**
  String group_accumulator_session_share_message(
    int count,
    String accumulation,
    String group,
  );

  /// No description provided for @group_accumulator_session_share_message_no_group.
  ///
  /// In en, this message translates to:
  /// **'I completed {count} recitations in the group accumulation \"{accumulation}\" on WeBuddhist. Come join me!'**
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
  /// **'By this merit, may all beings\nbe free from suffering.'**
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
  /// **'I liked this quote from WeBuddhist and wanted to share it with you. Read more such insightful quotes on the WeBuddhist App'**
  String get share_quote_message;

  /// No description provided for @share_poem_message.
  ///
  /// In en, this message translates to:
  /// **'I liked this poem from WeBuddhist and wanted to share it with you.'**
  String get share_poem_message;

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
  /// **'I\'d love for you to join our group. Let\'s practice together on WeBuddhist.'**
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
  /// **'Nothing bookmarked yet.'**
  String get bookmarks_empty_all_title;

  /// No description provided for @bookmarks_empty_all_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmark anything to save it here.'**
  String get bookmarks_empty_all_subtitle;

  /// No description provided for @bookmarks_empty_plans_title.
  ///
  /// In en, this message translates to:
  /// **'No plans bookmarked yet.'**
  String get bookmarks_empty_plans_title;

  /// No description provided for @bookmarks_empty_plans_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmark a plan to save it here.'**
  String get bookmarks_empty_plans_subtitle;

  /// No description provided for @bookmarks_empty_malas_title.
  ///
  /// In en, this message translates to:
  /// **'No malas bookmarked yet.'**
  String get bookmarks_empty_malas_title;

  /// No description provided for @bookmarks_empty_malas_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmark a mala to save it here.'**
  String get bookmarks_empty_malas_subtitle;

  /// No description provided for @bookmarks_empty_group_accumulations_title.
  ///
  /// In en, this message translates to:
  /// **'No group accumulations bookmarked yet.'**
  String get bookmarks_empty_group_accumulations_title;

  /// No description provided for @bookmarks_empty_group_accumulations_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmark a group accumulation to save it here.'**
  String get bookmarks_empty_group_accumulations_subtitle;

  /// No description provided for @bookmarks_empty_timers_title.
  ///
  /// In en, this message translates to:
  /// **'No timers bookmarked yet.'**
  String get bookmarks_empty_timers_title;

  /// No description provided for @bookmarks_empty_timers_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmark a timer to save it here.'**
  String get bookmarks_empty_timers_subtitle;

  /// No description provided for @bookmarks_empty_texts_title.
  ///
  /// In en, this message translates to:
  /// **'No texts bookmarked yet.'**
  String get bookmarks_empty_texts_title;

  /// No description provided for @bookmarks_empty_texts_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmark a text to save it here.'**
  String get bookmarks_empty_texts_subtitle;

  /// No description provided for @bookmark_removed.
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get bookmark_removed;

  /// No description provided for @bookmark_remove_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove bookmark'**
  String get bookmark_remove_failed;

  /// No description provided for @bookmark_saved.
  ///
  /// In en, this message translates to:
  /// **'Bookmark saved'**
  String get bookmark_saved;

  /// No description provided for @bookmark_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save bookmark'**
  String get bookmark_save_failed;

  /// No description provided for @bookmarks_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get bookmarks_yesterday;

  /// No description provided for @webview_timeout_error.
  ///
  /// In en, this message translates to:
  /// **'Page took too long to load. Please check your internet connection.'**
  String get webview_timeout_error;

  /// No description provided for @webview_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load page'**
  String get webview_load_failed;

  /// No description provided for @privacy_policy_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the privacy policy page.'**
  String get privacy_policy_load_error;

  /// No description provided for @terms_of_service_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the terms of service page.'**
  String get terms_of_service_load_error;

  /// No description provided for @series_enroll_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to enroll in series'**
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

  /// No description provided for @session_plans_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load plans.\nPlease try again later.'**
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

  /// No description provided for @ai_use_search_instead.
  ///
  /// In en, this message translates to:
  /// **'Use Search Instead'**
  String get ai_use_search_instead;

  /// No description provided for @ai_mode_label.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai_mode_label;

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
  /// **'Unable to load author details.\nPlease try again.'**
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
  /// **'I am taking part in \"{accumulation}\", a group accumulation by {group} on WeBuddhist. Come join me!'**
  String group_accumulator_share_message(String accumulation, String group);

  /// No description provided for @group_accumulator_share_message_no_group.
  ///
  /// In en, this message translates to:
  /// **'I am taking part in the group accumulation \"{accumulation}\" on WeBuddhist. Come join me!'**
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
  /// **'Join a community to start chatting.'**
  String get chats_empty_body;

  /// No description provided for @group_chat_inappropriate.
  ///
  /// In en, this message translates to:
  /// **'This message couldn\'t be sent because it contains language that isn\'t allowed.'**
  String get group_chat_inappropriate;

  /// No description provided for @group_chat_not_a_member.
  ///
  /// In en, this message translates to:
  /// **'Only members can open this chat.'**
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
  /// **'Join chat to send message.'**
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
  /// **'Start the conversation with your group.'**
  String get group_chat_empty_body;

  /// No description provided for @group_chat_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Messages couldn\'t be loaded.'**
  String get group_chat_load_failed;

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
  /// **'Your name stays private.'**
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
  /// **'You\'re offline — try again later'**
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

  /// No description provided for @group_chat_delete_confirm_body.
  ///
  /// In en, this message translates to:
  /// **'This message will be deleted for everyone in this chat.'**
  String get group_chat_delete_confirm_body;

  /// No description provided for @group_chat_delete_for_everyone.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get group_chat_delete_for_everyone;

  /// No description provided for @group_chat_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'The message couldn\'t be deleted.'**
  String get group_chat_delete_failed;

  /// No description provided for @group_chat_message_deleted.
  ///
  /// In en, this message translates to:
  /// **'You deleted this message'**
  String get group_chat_message_deleted;

  /// No description provided for @group_chat_message_deleted_by_sender.
  ///
  /// In en, this message translates to:
  /// **'This message was deleted'**
  String get group_chat_message_deleted_by_sender;

  /// No description provided for @group_chat_reaction_failed.
  ///
  /// In en, this message translates to:
  /// **'Your reaction couldn\'t be saved.'**
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
  /// **'That message is no longer available, so the quote was removed. Send again to post your message.'**
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
  /// **'Share your first update with your community.'**
  String get group_posts_empty_message;

  /// No description provided for @group_posts_load_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to load posts. Please try again.'**
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
  /// **'You\'ll lose what you\'ve written.'**
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
  /// **'Paste a link and we\'ll show a preview.'**
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
  /// **'You can still attach it as a link.'**
  String get group_post_preview_failed_message;

  /// No description provided for @group_post_invalid_link.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid link, for example https://example.com'**
  String get group_post_invalid_link;

  /// No description provided for @group_post_photo_limit.
  ///
  /// In en, this message translates to:
  /// **'You can add up to {count} photos.'**
  String group_post_photo_limit(int count);

  /// No description provided for @group_post_upload_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to upload photos. Please try again.'**
  String get group_post_upload_error;

  /// No description provided for @group_post_publish_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to publish your post. Please try again.'**
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
  /// **'This post will be permanently removed.'**
  String get group_post_delete_message;

  /// No description provided for @group_post_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete the post. Please try again.'**
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
  /// **'Unable to save your changes. Please try again.'**
  String get group_post_update_error;

  /// No description provided for @group_post_updated.
  ///
  /// In en, this message translates to:
  /// **'Your changes are saved.'**
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

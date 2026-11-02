// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'WeBuddhist';

  @override
  String get sign_in => '登錄';

  @override
  String get logout => '登出';

  @override
  String get onboarding_welcome => '歡迎來到';

  @override
  String get onboarding_tagline => '學習、修持、連結。每日。';

  @override
  String get onboarding_find_peace => '立即開始';

  @override
  String get onboarding_continue => '下一步';

  @override
  String get onboarding_first_question => '選擇您的語言';

  @override
  String get onboarding_language_subtitle => '這會設定應用程式的語言';

  @override
  String get onboarding_all_set => '一切就緒';

  @override
  String get onboarding_all_set_description => '以下是為您準備的內容：';

  @override
  String get onboarding_all_set_practice_title => '修持';

  @override
  String get onboarding_all_set_practice_body => '修持計畫、持誦、念珠與禪修';

  @override
  String get onboarding_all_set_connect_title => '連結';

  @override
  String get onboarding_all_set_connect_body => '社群、活動、動態與聊天';

  @override
  String get home_today => '今天';

  @override
  String get home_overall_stats => '整體統計';

  @override
  String home_plans_count(int count) {
    return '$count 計劃';
  }

  @override
  String home_recitation_count(int count) {
    return '$count 持誦';
  }

  @override
  String get home_shortcut_plans => '計劃';

  @override
  String get home_chants => '持誦';

  @override
  String get home_mala => '念珠';

  @override
  String get session_mala => '念珠';

  @override
  String get bookmark_mala => '念珠';

  @override
  String get bookmark_timers => '計時器';

  @override
  String get bookmark_texts => '經文';

  @override
  String get bookmark_group_accumulation => '共修空間總計數';

  @override
  String get mala_add_to_practice => '加入我的修持';

  @override
  String get mala_add_mala_round => '新增念珠遍數';

  @override
  String get mala_add_rounds_title => '新增念珠遍數：';

  @override
  String get mala_add_rounds_message => '新增您在此應用程式之外完成的念珠遍數';

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
  String get mala_add_to_bookmark => '書籤';

  @override
  String get mala_sound => '聲音';

  @override
  String get mala_vibration => '震動';

  @override
  String get mala_reset_count => '重設計數';

  @override
  String get mala_reset_title => '重設此念珠？';

  @override
  String get mala_reset_count_confirm => '目前的計數將歸零，但您累積的次數仍會保留在終身總數中';

  @override
  String get mala_reset_confirm => '重設';

  @override
  String get mala_action_coming_soon => '即將推出';

  @override
  String mala_rounds_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 遍',
      one: '1 遍',
      zero: '0 遍',
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
    return '計數 $bead/$total，$rounds';
  }

  @override
  String get mala_group_accumulations => '加入持誦計數';

  @override
  String get mala_groups_section => 'Groups';

  @override
  String get mala_group_untitled => '未命名社群';

  @override
  String get mala_all_time_accumulation => '我的累計總數';

  @override
  String get mala_personal_practice => '個人修持';

  @override
  String get mala_events_section => '活動';

  @override
  String mala_my_total(String count) {
    return '我的總數：$count';
  }

  @override
  String mala_group_total(String count) {
    return '群組總數：$count';
  }

  @override
  String get home_timer => '計時';

  @override
  String get preset_timers => '預設計時';

  @override
  String get meditation_timer => '禪修計時';

  @override
  String get timer_min => '分鐘';

  @override
  String get timer_finish => '完成';

  @override
  String get timer_discard_session => '放棄此次修持';

  @override
  String get home_hello_prefix => '你好，';

  @override
  String home_share_prompt(String appName) {
    return '喜歡 $appName 嗎？';
  }

  @override
  String get home_share_support => '您的支持能幫助我們的社群成長。';

  @override
  String get no_feature_content => '尚無精選內容';

  @override
  String get nav_home => '首頁';

  @override
  String get nav_explore => '探索';

  @override
  String get nav_learn => '學習';

  @override
  String get nav_practice => '修持計畫';

  @override
  String get nav_settings => '設定';

  @override
  String get nav_connect => '社群';

  @override
  String get nav_me => '個人';

  @override
  String get tab_practices => '修持計畫';

  @override
  String get text_search => '搜尋';

  @override
  String get text_commentary => '注釋';

  @override
  String get resources => '資源';

  @override
  String get no_translation => '尚無相關翻譯';

  @override
  String get show_more => '顯示更多';

  @override
  String get show_less => '顯示較少';

  @override
  String get more => '更多';

  @override
  String get less => '較少';

  @override
  String get no_content => '尚無相關內容';

  @override
  String commentary_not_available_for_language(String language) {
    return '暫無 $language 註釋';
  }

  @override
  String get loading => '加載中...';

  @override
  String get save => '儲存';

  @override
  String get done => '完成';

  @override
  String get my_plans => '我的計畫';

  @override
  String get browse_plans => '瀏覽修持計畫';

  @override
  String get plan_info => '修持計畫內容';

  @override
  String get start_reading => '立即修持';

  @override
  String get tibetan => '藏文';

  @override
  String get sanskrit => '梵文';

  @override
  String get english => '英文';

  @override
  String get chinese => '繁體中文';

  @override
  String get classicalChinese => '佛經文體';

  @override
  String get pali => '巴利文';

  @override
  String get language => '語言';

  @override
  String get plan_unenroll => '退出計畫';

  @override
  String get unenroll_confirmation => '確定要退出嗎';

  @override
  String get unenroll_message => '您的進度將被永久刪除，且無法復原';

  @override
  String get practice_plan => '建立每日修持。探索適合您的內容';

  @override
  String get search_plans => '搜尋計畫...';

  @override
  String get search_for_plans => '搜尋計畫';

  @override
  String get no_plans_found => '找不到相關計畫';

  @override
  String get no_days_available => '找不到相關天數';

  @override
  String get recitations_search => '搜索';

  @override
  String get recitations_search_for => '尋找持誦內容';

  @override
  String get recitations_no_found => '尚無相關持誦內容';

  @override
  String get recitations_no_content => '沒有可用的持誦';

  @override
  String get my_recitation_collection_new_title => '新持誦集';

  @override
  String get my_recitation_collection_next => '下一步';

  @override
  String get my_recitation_collection_create => '建立';

  @override
  String get my_recitation_collection_create_button => '建立持誦集';

  @override
  String get my_recitation_collection_change_title => '變更標題';

  @override
  String get my_recitation_collection_change => '變更';

  @override
  String get my_recitation_collection_add_chants => '新增持誦';

  @override
  String get my_recitation_collection_search_chants => '搜尋持誦';

  @override
  String get my_recitation_collection_add_to_collection => '加入持誦集';

  @override
  String get my_recitation_collection_edit => '編輯持誦集';

  @override
  String get my_recitation_collection_delete => '刪除持誦集';

  @override
  String get my_recitation_collection_delete_title => '要刪除持誦集嗎？';

  @override
  String get my_recitation_collection_delete_message => '此持誦集將被永久刪除';

  @override
  String get my_recitation_collection_fallback_title => '持誦集';

  @override
  String get my_recitation_collection_unavailable => '已無法使用';

  @override
  String my_recitation_collection_chant_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 段持誦',
      one: '1 段持誦',
      zero: '0 段持誦',
    );
    return '$_temp0';
  }

  @override
  String my_recitation_collection_chant_count_owner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 段持誦 • 我',
      one: '1 段持誦 • 我',
      zero: '0 段持誦 • 我',
    );
    return '$_temp0';
  }

  @override
  String get bookmarks_empty_chant_collections_title => '尚無加入書籤的法本';

  @override
  String get bookmarks_empty_chant_collections_subtitle => '將法本加入書籤，，即可收藏於此';

  @override
  String get notification_allow_title => '允許通知';

  @override
  String get notification_allow_subtitle_disabled => '需要權限。請點此前往「設定」授權';

  @override
  String get notification_snack_permission_denied => '通知已被封鎖。請在「設定」中開啟';

  @override
  String get notification_snack_disable_alarms_in_settings => '在「設定」中關閉鬧鐘與提醒';

  @override
  String get notification_allow_subtitle_on => '來自 WeBuddhist 的提醒與更新';

  @override
  String get notification_allow_subtitle_off => '已關閉。開啟後即可收到提醒與更新。';

  @override
  String get notification_section_practice => '修持';

  @override
  String get notification_section_connect => '社群';

  @override
  String get notification_row_plans => '修持計畫';

  @override
  String get notification_row_chants => '持誦';

  @override
  String get notification_row_mala => '念珠與總計數';

  @override
  String get notification_row_timer => '計時器';

  @override
  String get notification_row_group_posts => '社群貼文';

  @override
  String get notification_row_group_chats => '社群聊天室';

  @override
  String get notification_row_my_prayer_requests => '我的迴向與祈願';

  @override
  String get notification_row_others_prayer_requests => '他人的迴向與祈願';

  @override
  String get profile_default_bio => '歡迎來到 WeBuddhist';

  @override
  String get profile_guest_title => '訪客';

  @override
  String get profile_guest_subtitle => '您正以訪客身分瀏覽';

  @override
  String get profile_guest_benefits_header => '登入以解鎖：';

  @override
  String get profile_guest_benefit_save_progress => '儲存您的進度';

  @override
  String get profile_guest_benefit_personalized => '個人化內容';

  @override
  String get profile_guest_benefit_notifications => '自訂通知';

  @override
  String get auth_drawer_title => '請登入帳號後再繼續';

  @override
  String get auth_drawer_subtitle => '隨時隨地，在任何裝置上繼續您的修持';

  @override
  String get routine_delete_block_message => '這將刪除該時段及其中所有內容';

  @override
  String get something_went_wrong => '出了點問題。請再試一次';

  @override
  String get onboarding_tradition_title => '您如何依循佛陀的教法？';

  @override
  String get onboarding_tradition_subtitle => '為您的內容選擇一個或多個傳承。您隨時可以在「設定」中變更。';

  @override
  String get onboarding_tradition_show_all_title => '顯示所有內容';

  @override
  String get plan_go_to_practice => '前往修持計畫';

  @override
  String get plan_starts_soon_title => '計畫即將開始';

  @override
  String get plan_joining_late_title => '在開始日期後加入';

  @override
  String get got_it => '明白了';

  @override
  String get plan_no_tasks_error => '無法載入任務';

  @override
  String get plan_day_tasks_load_error => '無法載入當日任務';

  @override
  String get plans_empty_title => '更多內容即將推出';

  @override
  String get plans_empty_subtitle => '我們將持續添增修持課程，歡迎隨時回來瀏覽。';

  @override
  String get find_plans_load_error => '無法載入計畫，\n請檢查你的網路連線後再試。';

  @override
  String get connect_subtitle => '尋找你的社群，一起修持';

  @override
  String get discover_groups => '探索社群';

  @override
  String get my_groups => '我的社群';

  @override
  String get see_all => '查看全部';

  @override
  String get connect_groups_load_error => '無法載入社群，\n請檢查網路連線後重試';

  @override
  String get connect_groups_empty_title => '尚無社群';

  @override
  String get connect_tab_feed => '動態';

  @override
  String get connect_tab_events => '活動';

  @override
  String get connect_tab_practices => '修持計畫';

  @override
  String get connect_tab_groups => '社群';

  @override
  String get connect_segment_my => '您的社群';

  @override
  String get connect_segment_discover => '探索';

  @override
  String get connect_empty_discover_events => '沒有可探索的活動';

  @override
  String get connect_empty_discover_feed => '沒有可探索的內容';

  @override
  String get connect_empty_discover_groups => '沒有可探索的共修空間';

  @override
  String get connect_all_groups => '所有共修空間';

  @override
  String get connect_my_empty_feed_title => '您的共修空間最近很安靜';

  @override
  String get connect_my_empty_events_title => '沒有即將舉行的活動';

  @override
  String get connect_my_empty_groups_title => '尚未加入社群';

  @override
  String get connect_my_empty_feed_subtitle => '您的社群還沒有分享新內容';

  @override
  String get connect_my_empty_events_subtitle => '您的社群還沒有安排任何活動';

  @override
  String get connect_my_empty_groups_subtitle => '你還沒有加入任何社群。探索可以一起修持的社群。';

  @override
  String get connect_my_empty_feed_browse => '看看其他共修空間在分享什麼';

  @override
  String get connect_my_empty_events_browse => '瀏覽開放活動';

  @override
  String connect_comment_replying_to(String handle) {
    return '回覆 @$handle';
  }

  @override
  String get connect_comment_hint => '請問您對這則貼文有什麼想法？';

  @override
  String get connect_comment_reply_hint => '撰寫回覆…';

  @override
  String get connect_comment_reply => '回覆';

  @override
  String get connect_comment_delete_title => '刪除留言？';

  @override
  String get connect_comment_delete_message => '這則留言將被永久刪除';

  @override
  String get connect_comment_delete_failed => '無法刪除留言';

  @override
  String connect_post_comments_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 則留言',
    );
    return '$_temp0';
  }

  @override
  String get connect_post_comments_empty => '還沒有留言。開始討論吧';

  @override
  String get connect_online => '線上';

  @override
  String get connect_ended => 'Ended';

  @override
  String connect_ended_on(String date) {
    return 'Ended $date';
  }

  @override
  String get home_group_events => '精選活動';

  @override
  String get home_poems => '詩偈';

  @override
  String get poems_load_error => '無法載入詩歌。\n請檢查您的連線並再試一次';

  @override
  String get poems_empty => '尚無詩歌，請稍後再來。';

  @override
  String get connect_events_filter_all => '全部';

  @override
  String get connect_events_filter_in_person => '現場';

  @override
  String get connect_events_filter_empty_online => '尚無線上活動';

  @override
  String get connect_events_filter_empty_in_person => '尚無現場活動';

  @override
  String get connect_events_filter_hybrid => '混合型';

  @override
  String get connect_events_filter_empty_hybrid => '沒有混合型的活動';

  @override
  String get connect_event_fallback_title => '活動';

  @override
  String get connect_group_fallback_title => '共修空間';

  @override
  String get connect_event_participation_prompt => '您會怎麼參加?';

  @override
  String get connect_event_practice_in_person => '現場修持';

  @override
  String get connect_event_practice_online => '線上修持';

  @override
  String get connect_event_view_in_person => '現場檢視';

  @override
  String get connect_event_view_online => '線上檢視';

  @override
  String get connect_event_accumulation_online => 'Online';

  @override
  String get connect_event_accumulation_in_person => 'In-person';

  @override
  String get connect_event_has_ended => 'This event has ended';

  @override
  String get connect_event_join_to_practice => '參加活動即可修持';

  @override
  String get connect_event_leave => '退出活動';

  @override
  String get connect_event_leave_confirm_title => '要退出此活動嗎？';

  @override
  String connect_event_leave_confirm_message(String title) {
    return '您將不再參加$title。您仍可查看此活動，並隨時再次參加。';
  }

  @override
  String connect_event_participants_attending(int count) {
    return '$count 位參與者';
  }

  @override
  String connect_event_participants_attended(int count) {
    return '$count attended';
  }

  @override
  String get connect_event_participants_empty => '尚無人參加';

  @override
  String get connect_event_organizer => '主辦單位';

  @override
  String get connect_event_tab_videos => '影片';

  @override
  String get connect_event_tab_about => '活動介紹';

  @override
  String get connect_event_links_title => '更多活動介紹';

  @override
  String get connect_event_date_tba => '日期尚待公告';

  @override
  String get connect_event_when => '時間';

  @override
  String get connect_event_where => '地點';

  @override
  String get connect_event_tab_accumulations => '計數統計';

  @override
  String get connect_event_add_recitations => '填入您的持誦次數';

  @override
  String get connect_event_add_recitations_message =>
      '新增您在線上直播，或在此應用程式之外已完成的持誦次數';

  @override
  String get connect_event_every_day => '每天';

  @override
  String connect_event_every_weekday(String weekday) {
    return '每個$weekday';
  }

  @override
  String get connect_event_every_month => '每個月';

  @override
  String connect_event_every_date(String date) {
    return '輸入$date';
  }

  @override
  String get connect_event_about_empty => '尚無活動資訊';

  @override
  String get search_groups => '搜尋社群';

  @override
  String get search_for_groups => '搜尋社群';

  @override
  String get no_groups_found => '找不到符合的社群';

  @override
  String get explore_coming_soon_subtitle => '探索修持、教法與社群活動的精選空間。';

  @override
  String get learn_coming_soon_subtitle => '專為您日常生活設計的個人學習計畫';

  @override
  String get creator_featured_plan => '精選計畫';

  @override
  String get home_no_series_found => '未找到系列';

  @override
  String get home_no_tags_found => '找不到該標籤';

  @override
  String get home_celebrated_by => '慶祝者：';

  @override
  String get reader_font_size_tooltip => '字體大小';

  @override
  String get reader_versions_load_error => '無法載入版本';

  @override
  String get reader_languages_load_error => '無法載入語言';

  @override
  String reader_no_versions_in_language(String language) {
    return '$language 尚無可用的版本。';
  }

  @override
  String get reader_no_languages => '此文本尚無可用的語言。';

  @override
  String get reader_license => '授權';

  @override
  String get text_search_hint => '輸入以搜尋';

  @override
  String get text_search_press_button => '按下搜尋按鈕以搜尋';

  @override
  String get text_search_error => '無法執行搜尋，請再試一次';

  @override
  String get create_image_share_error => '無法分享，請再試一次';

  @override
  String get my_plans_sign_in_prompt => '登入以查看您的計畫';

  @override
  String plan_starts_soon_message(String date) {
    return '此計畫將於 $date 開始。您可以先瀏覽內容。';
  }

  @override
  String plan_joining_late_message(String date) {
    return '此計畫已於 $date 開始。您可以完成過去幾天的任務。';
  }

  @override
  String get select_language => '語言設定';

  @override
  String get logout_confirmation => '您確定要登出嗎？';

  @override
  String get cancel => '取消';

  @override
  String get copy => '複製';

  @override
  String get copied => '已複製';

  @override
  String get share => '分享';

  @override
  String get bookmark => '書籤';

  @override
  String get collection_audio_versions => 'Audio versions';

  @override
  String get playback_speed => 'Playback speed';

  @override
  String get author => '作者';

  @override
  String get plans_created => '建立的修持計畫';

  @override
  String get ai_confirm => '確認';

  @override
  String search_no_results(String query) {
    return '找不到「$query」的結果';
  }

  @override
  String get search_all => '全部';

  @override
  String get common_ok => '確定';

  @override
  String get comingSoonHeadline => '即將推出';

  @override
  String get routine_title => '日常修持';

  @override
  String get bookmarks => '書籤';

  @override
  String get routine_empty_title => '日常修持';

  @override
  String get routine_edit => '編輯';

  @override
  String get routine_empty_description => '探索更多課程與修持計畫，加入學習選單或新增至您的修持安排';

  @override
  String get routine_build => '建立日常修持';

  @override
  String get routine_add_session => '添加課程';

  @override
  String get routine_edit_title => '編輯日常修持';

  @override
  String get routine_delete_block => '刪除時段';

  @override
  String get routine_session_title_hint => '標題...';

  @override
  String get routine_expand_all => '全部展開';

  @override
  String get routine_collapse_all => '全部收合';

  @override
  String get routine_add_plan => '添加計畫';

  @override
  String get routine_add_recitation => '添加持誦';

  @override
  String get routine_add_plan_to_routine => '新增至日常修持';

  @override
  String get routine_load_error => '無法載入。請檢查您的網路連線，然後再試一次。';

  @override
  String get routine_empty_block_title_singular => '空白時段';

  @override
  String routine_empty_block_title_plural(int count) {
    return '空白時段 ($count)';
  }

  @override
  String get routine_empty_block_message_singular =>
      '此時段尚未新增內容。請新增或將其從您的修持安排中移除';

  @override
  String routine_empty_block_message_plural(int count) {
    return '有 $count 個時段尚未新增內容。請新增，或從您的修持安排中移除';
  }

  @override
  String get routine_empty_block_add_items => '新增清單';

  @override
  String get routine_empty_block_delete_singular => '刪除時段';

  @override
  String get routine_empty_block_delete_plural => '刪除空白時段';

  @override
  String get routine_notification_title => '讓修持成為習慣';

  @override
  String get routine_notification_description => '請開啟通知權限，以便我們提醒您進行修持。';

  @override
  String get routine_notification_enable => '啟用通知';

  @override
  String get routine_notification_skip => '跳過';

  @override
  String routine_time_adjusted(String time, int gap) {
    return '已調整為 $time（最少 $gap 分鐘的間隔）';
  }

  @override
  String get routine_add_block_label => '時段';

  @override
  String get continueWithGoogle => '使用 Google 繼續';

  @override
  String get continueWithApple => '使用 Apple 繼續';

  @override
  String get continueWithPhone => '使用電話繼續';

  @override
  String get exploreAsGuest => '以訪客身份探索';

  @override
  String get signIn => '登入';

  @override
  String get profileError => '加載個人資料時出錯';

  @override
  String get profileTitle => '個人資料';

  @override
  String get notLoggedIn => '尚未登入';

  @override
  String get retry => '重試';

  @override
  String get back => '返回';

  @override
  String get delete => '刪除';

  @override
  String get close => '關閉';

  @override
  String get tryAgain => '再試一次';

  @override
  String get pleaseTryAgain => '請再試一次';

  @override
  String get error => '錯誤';

  @override
  String get anonymous => '匿名';

  @override
  String get noContentAvailable => '沒有可用內容';

  @override
  String get unableToLoad => '無法載入，請再試一次';

  @override
  String get somethingWrong => '出了點問題，請檢查您的連接並重試';

  @override
  String get source => '來源';

  @override
  String get noTasks => '沒有可用任務';

  @override
  String get taskNotFound => '找不到任務';

  @override
  String get updateTaskError => '無法更新任務狀態';

  @override
  String get enrollError => '無法完成註冊。請檢查您的網路連線，然後再試一次。';

  @override
  String unenrollSuccess(String planTitle) {
    return '您已退出 $planTitle';
  }

  @override
  String get unenrollError => '無法取消註冊。請檢查您的網路連線，然後再試一次';

  @override
  String get unenrollGenericError => '發生錯誤。請檢查您的網路連線，然後再試一次';

  @override
  String get notFound => '此內容已無法使用。請編輯您的修持安排以進行更新';

  @override
  String get noTimeSlot => '沒有可用的時間段，請先移除一個區塊';

  @override
  String maxBlocks(int max) {
    return '已達最多 $max 個可選時間區段上限。';
  }

  @override
  String get duplicateItem => '此項目已在本時間區塊';

  @override
  String get removeItem => '移除項目';

  @override
  String removeConfirmation(String itemName) {
    return '要從此時段中移除「$itemName」嗎？';
  }

  @override
  String shareError(String error) {
    return '無法分享。請再試一次';
  }

  @override
  String get captureError => 'QR code 掃描失敗，請再試一次';

  @override
  String get qrShareError => '無法分享QRcode，請稍後再試';

  @override
  String errorDetail(String error) {
    return '錯誤：$error';
  }

  @override
  String missedDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '錯過$count天',
      one: '錯過1天',
      zero: '未錯過天數',
    );
    return '$_temp0';
  }

  @override
  String get plan_status_on_track => '進度正常！';

  @override
  String get start_now => '立即開始';

  @override
  String get plan_enroll => '加入';

  @override
  String get root_text => '根本文';

  @override
  String get version => '所有版本';

  @override
  String get reader_languages_title => '語言';

  @override
  String get reader_sections_title => '章節';

  @override
  String get reader_original_label => '原文';

  @override
  String get reader_translation_label => '譯文';

  @override
  String get version_not_available => '無可用版本';

  @override
  String series_stats(int planCount, int totalDays) {
    return '$planCount 個章節 · $totalDays 天';
  }

  @override
  String get force_update_title => '需要更新';

  @override
  String get force_update_message => '新版本已上線，請更新後再繼續使用。';

  @override
  String get force_update_button => '立即更新';

  @override
  String get settings_section_personalisation => '個人化';

  @override
  String get settings_section_more => '更多';

  @override
  String get settings_section_account => '帳號';

  @override
  String get settings_edit_profile => '編輯個人檔案';

  @override
  String get settings_theme => '主題';

  @override
  String get settings_notification_row => '通知';

  @override
  String get settings_feedback_row => '意見回饋';

  @override
  String get edit_profile_title => '編輯個人檔案';

  @override
  String get edit_profile_save => '儲存';

  @override
  String get edit_profile_display_name => '顯示名稱';

  @override
  String get edit_profile_bio => '自我介紹';

  @override
  String get edit_profile_bio_hint => '向大家介紹一下自己';

  @override
  String get edit_profile_delete_account => '刪除帳號';

  @override
  String get edit_profile_photo_not_uploaded => '相片尚未上傳';

  @override
  String get edit_profile_photo_too_large => '圖片過大，請選擇 1 MB 以下的相片後再試一次';

  @override
  String get edit_profile_photo_upload_failed => '無法上傳您的相片，請再試一次';

  @override
  String get edit_profile_choose_from_library => '從相簿選擇';

  @override
  String get edit_profile_take_photo => '拍照';

  @override
  String get edit_profile_offline => '您目前離線中，請連接網路後再試一次';

  @override
  String get edit_profile_save_failed => '無法儲存您的變更，請再試一次';

  @override
  String get edit_profile_traditions => '傳承';

  @override
  String get edit_profile_choose_traditions => '選擇您的傳承';

  @override
  String get edit_profile_tradition_remove_failed => '無法移除傳承，請再試一次';

  @override
  String get edit_profile_tradition_save_failed => '無法儲存傳承，請再試一次';

  @override
  String get username_label => '使用者名稱';

  @override
  String get username_taken => '這個名稱已被使用';

  @override
  String get username_available_label => '可使用：';

  @override
  String get username_check_error => '無法檢查使用者名稱，請再試一次';

  @override
  String get username_invalid_format => '使用者名稱格式無效';

  @override
  String get username_min_length => '使用者名稱至少需 3 個字元';

  @override
  String get username_max_length => '使用者名稱不可超過 30 個字元';

  @override
  String get username_no_spaces => '使用者名稱不可包含空格';

  @override
  String get username_invalid_chars => '僅允許字母、數字、_ . -';

  @override
  String get username_must_start_alphanumeric => '使用者名稱須以字母或數字開頭';

  @override
  String get username_must_end_alphanumeric => '使用者名稱須以字母或數字結尾';

  @override
  String get person_name_min_length => '至少需要 1 個字元';

  @override
  String get person_name_max_length => '不得超過 50 個字元';

  @override
  String get person_name_invalid_chars => '僅允許字母、空格、連字號和撇號';

  @override
  String get about_title => '關於';

  @override
  String get about_connect_with_us => '聯繫我們';

  @override
  String get about_description =>
      '我們協助佛教徒透過每日的學習、修持與交流，能多一些善舉，少一些惡行，並更深入了解自己的心。';

  @override
  String get about_social_website => '官網';

  @override
  String get me_guest_headline => '體驗完整功能';

  @override
  String get me_guest_subtitle => '建立免費帳號以儲存您的進度';

  @override
  String get me_my_stats => '我的統計';

  @override
  String me_day_streak(int count) {
    return '連續 $count 天';
  }

  @override
  String me_best_streak(int count) {
    return '最長連續：$count 天';
  }

  @override
  String get accumulations => '持誦計數';

  @override
  String get accumulations_search => '查詢計數結果';

  @override
  String get accumulations_search_for => '尋找計數內容';

  @override
  String get accumulations_no_found => '尚無持誦計數紀錄';

  @override
  String get me_accumulation => '累積總數';

  @override
  String get me_minutes => '分鐘';

  @override
  String get me_hours => '小時';

  @override
  String get me_total_meditation_time => '禪修總時間';

  @override
  String get me_days_plan_practiced_suffix => '天計畫已完成';

  @override
  String get me_streak_share_quote => '我在 WeBuddhist 的連續紀錄！';

  @override
  String me_streak_days_count(int count) {
    return '$count 天';
  }

  @override
  String get share_this_streak => '分享我的連續紀錄';

  @override
  String get me_streak_share_error => '無法分享連續紀錄，請重試';

  @override
  String get delete_account_title => '刪除帳號';

  @override
  String get delete_account_description =>
      '若您刪除帳號，您在 WeBuddhist 中的所有資料、紀錄與個人化設定將被永久刪除。請注意，此操作無法復原。如欲繼續，請點按下方按鈕。';

  @override
  String get delete_account_button => '刪除帳號';

  @override
  String get delete_account_confirm_message => '您確定要刪除您的 WeBuddhist 帳號嗎？';

  @override
  String get legal_title => '法律資訊';

  @override
  String get legal_terms_of_service => '使用條款';

  @override
  String get legal_privacy_policy => '隱私政策';

  @override
  String get follow => '追蹤';

  @override
  String get calendar_title => '日曆';

  @override
  String get calendar_upcoming_events => '近期活動';

  @override
  String get calendar_day_short => '日';

  @override
  String get calendar_day_label => '日';

  @override
  String calendar_lunar_month(String ordinal) {
    return '藏曆$ordinal月';
  }

  @override
  String get moon_phase_new_moon => '新月';

  @override
  String get moon_phase_first_quarter => '上弦月';

  @override
  String get moon_phase_full_moon => '满月';

  @override
  String get join => '加入';

  @override
  String get group_member => '位成員';

  @override
  String get group_members => '位成員';

  @override
  String get group_tab_members => '成員';

  @override
  String get group_tab_followers => '追蹤者';

  @override
  String group_members_heading(int count) {
    return '成員 ($count)';
  }

  @override
  String group_followers_heading(int count) {
    return '追蹤者($count)';
  }

  @override
  String get group_invite => '邀請';

  @override
  String get group_notifications_title => '通知';

  @override
  String get group_notifications_chat => '社群聊天室';

  @override
  String get group_notifications_content => '社群內容';

  @override
  String get group_notifications_master_off => '此應用程式的通知已關閉';

  @override
  String get group_notifications_open_settings => '開啟';

  @override
  String get group_notifications_update_failed => '無法更新通知設定，請再試一次';

  @override
  String get group_notifications_load_failed => '無法載入通知設定';

  @override
  String get group_chat_mute_notifications => '將聊天室通知設為靜音';

  @override
  String get group_chat_unmute_notifications => '取消聊天室通知靜音';

  @override
  String get group_chat_notifications_muted => '已將聊天室通知設為靜音';

  @override
  String get group_chat_notifications_unmuted => '聊天室通知已開啟';

  @override
  String get group_leave_confirm_message => '您將不再收到此社群的訊息和動態';

  @override
  String get group_leave_space => '退出社群';

  @override
  String get group_leave_space_confirm_title => '要退出此社群嗎？';

  @override
  String get group_leave_space_failed => '無法退出社群，請再試一次';

  @override
  String get group_request_to_join => '申請加入';

  @override
  String get group_request => '申請加入';

  @override
  String get group_request_sent => '已送出申請';

  @override
  String get group_join_request_title => '申請加入';

  @override
  String get group_join_request_message_label => '訊息（選填）';

  @override
  String get group_join_request_message_hint => '您如何修持，或是誰邀請您的？';

  @override
  String get group_join_request_send => '送出申請';

  @override
  String get group_join_request_sent_snackbar => '已送出申請。管理員將進行審核';

  @override
  String get group_join_request_error => '無法送出申請，請再試一次';

  @override
  String get group_join_requests_title => '加入申請';

  @override
  String get group_join_requests_admit => '接受';

  @override
  String get group_join_requests_deny => '拒絕';

  @override
  String get group_join_requests_empty => '沒有待審核的申請';

  @override
  String get group_join_requests_load_error => '無法載入加入申請，請再試一次';

  @override
  String get group_join_requests_admit_error => '無法接受此申請，請再試一次';

  @override
  String get group_join_requests_deny_error => '無法拒絕此申請，請再試一次';

  @override
  String get group_reports_title => '檢舉';

  @override
  String get group_reports_section_posts => '貼文';

  @override
  String get group_reports_section_comments => '留言';

  @override
  String get group_reports_section_messages => '訊息';

  @override
  String group_reports_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 則檢舉',
    );
    return '$_temp0';
  }

  @override
  String get group_reports_view_post => '查看貼文';

  @override
  String get group_reports_view_message => '查看訊息';

  @override
  String get group_reports_delete_post => '刪除貼文';

  @override
  String get group_reports_delete_comment => '刪除留言';

  @override
  String get group_reports_delete_message => '刪除訊息';

  @override
  String get group_reports_empty => '沒有待審核的檢舉';

  @override
  String get group_reports_load_error => '無法載入檢舉，請再試一次。';

  @override
  String get group_reports_delete_confirm_title => '你確定嗎？';

  @override
  String get group_reports_delete_message_confirm => '這則訊息將被永久刪除。';

  @override
  String get group_reports_message_removed => '訊息已移除';

  @override
  String get group_reports_delete_message_error => '無法刪除訊息，請再試一次。';

  @override
  String get group_members_only_title => '僅限成員';

  @override
  String get group_members_only_message => '加入此社群即可查看內容';

  @override
  String get group_join_request_waiting_title => '等待管理員審核';

  @override
  String get group_join_request_waiting_message => '申請審核完成後，我們會通知您';

  @override
  String get group_members_load_error => '無法載入成員，請再試一次';

  @override
  String get group_followers_load_error => '無法載入追蹤者，請再試一次。';

  @override
  String get group_members_empty => '尚無成員';

  @override
  String get group_member_admin => '管理員';

  @override
  String get group_member_owner => '擁有者';

  @override
  String group_remove_member(String name) {
    return '移除 $name';
  }

  @override
  String get group_remove_member_title => '要從社群中移除嗎？';

  @override
  String group_remove_member_message(String name) {
    return '$name 將被移出此社群，且在禁令解除前無法重新加入';
  }

  @override
  String get group_remove_member_blocked_for => '封鎖期間：';

  @override
  String get group_remove_member_duration_day => '1 天';

  @override
  String group_remove_member_duration_days(int count) {
    return '$count 天';
  }

  @override
  String get group_remove_member_duration_year => '1 年';

  @override
  String get group_remove_member_reason_label => '原因（選填）';

  @override
  String get group_remove_member_reason_hint => '其他...';

  @override
  String get group_remove_member_action => '移除';

  @override
  String group_remove_member_success(String name) {
    return '已將 $name 移出社群';
  }

  @override
  String get group_remove_member_error => '無法移除此成員，請再試一次';

  @override
  String group_join_banned_until(String date) {
    return '您已被移出此社群，在 $date 之前無法重新加入';
  }

  @override
  String get group_join_banned => '您已被移出此社群，在禁令解除前無法重新加入';

  @override
  String get group_removed_title => '您已被移出此社群';

  @override
  String group_removed_message(String group, String duration) {
    return '$group 的管理員已將您移出此社群。您將無法查看其中的貼文、活動和修持，也無法在 $duration 內要求重新加入。';
  }

  @override
  String group_removed_message_no_date(String group) {
    return '$group 的管理員已將您移出此社群。您將無法查看其中的貼文、活動和修持，也無法要求重新加入';
  }

  @override
  String get group_removed_rejoin_label => '您可以在以下日期申請加入此社群';

  @override
  String group_removed_rejoin_value(String date, String remaining) {
    return '$date · $remaining';
  }

  @override
  String get group_removed_day_left => '剩 1 天';

  @override
  String group_removed_days_left(int count) {
    return '剩 $count 天';
  }

  @override
  String get group_removed_last_day => '剩不到一天';

  @override
  String get group_followers_empty => '尚無追蹤者';

  @override
  String get group_follower => '位追蹤者';

  @override
  String get group_followers => '位追蹤者';

  @override
  String get group_links_title => '連結';

  @override
  String get group_about_description => '社群介紹';

  @override
  String get group_about_empty => '尚無相關資訊';

  @override
  String group_and_more_links(int count) {
    return '及另外 $count 個連結';
  }

  @override
  String get group_practice_with_us => '與我們一起修行';

  @override
  String series_practicing_with_group(String groupName) {
    return '與 $groupName 一起修行';
  }

  @override
  String get group_change_practice_title => '更換修持社群';

  @override
  String get group_change_practice_message => '您目前已在另一個社群修持此計畫。您想更換修持社群嗎？';

  @override
  String get group_join_to_contribute => '加入以參與計數';

  @override
  String get group_accumulator_join_error => '無法加入計數統計，請再試一次';

  @override
  String get group_accumulator_join_before_practice => '先加入本共修計數活動，再將它加入您的修持計畫';

  @override
  String group_accumulator_participants(int count) {
    return '$count 位參與者';
  }

  @override
  String get group_accumulator_leaderboard => '排行榜';

  @override
  String get group_accumulator_everyone => '所有人';

  @override
  String get group_accumulator_me => '我';

  @override
  String get group_accumulator_my_contributions => '我的貢獻';

  @override
  String get group_accumulator_recited => '已持誦';

  @override
  String get group_accumulator_total => '總數';

  @override
  String get group_accumulator_contributions_empty => '加入共修計數以追蹤您的貢獻';

  @override
  String get group_accumulator_leaderboard_empty => '尚無持誦紀錄';

  @override
  String get group_accumulator_recite_now => '立即持誦';

  @override
  String get group_accumulator_view_practice => 'View practice';

  @override
  String get group_accumulator_chant_again => '再次持誦';

  @override
  String get group_accumulator_finish_session => '結束此次持誦';

  @override
  String get group_accumulator_offline_recitation => '線下持誦';

  @override
  String get group_accumulator_add_offline_chants_title => '新增離線持誦次數：';

  @override
  String get group_accumulator_add_offline_chants_message =>
      '新增您在此應用程式之外完成的持誦次數';

  @override
  String get group_accumulator_session_complete => '課誦完成！';

  @override
  String group_accumulator_session_recitations(int count) {
    return '您這次完成了 $count 遍';
  }

  @override
  String group_accumulator_session_share_message(
    int count,
    String accumulation,
    String group,
  ) {
    return '我在 WeBuddhist 上 $group 社群的共修計數「$accumulation」中完成了 $count 遍持誦，快來加入我吧！';
  }

  @override
  String group_accumulator_session_share_message_no_group(
    int count,
    String accumulation,
  ) {
    return '我在 WeBuddhist 上的共修計數活動「$accumulation」中完成了 $count 遍的持誦，快來加入我吧！';
  }

  @override
  String get group_accumulator_session_share_error => '無法分享課誦，請重試';

  @override
  String group_recitation_collection_share_message(
    String collection,
    String group,
  ) {
    return '來看看 WeBuddhist 上 $group 社群的持誦集「$collection」。和我們一起修持吧！';
  }

  @override
  String group_recitation_collection_share_message_no_group(String collection) {
    return '來看看 WeBuddhist 上的持誦集「$collection」。和我們一起修持吧！';
  }

  @override
  String group_recitation_collection_completed_title(String collection) {
    return '$collection completed';
  }

  @override
  String get group_recitation_collection_dedication =>
      'By this merit, may all beings\nbe free from suffering';

  @override
  String get share_this_quote => '分享這句話';

  @override
  String get shared_from => '分享自';

  @override
  String get verse_share_error => '無法分享引文，請再試一次';

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
  String get share_app_message => '我一直在用這個應用程式培養每日佛法修持的習慣，覺得您也會喜歡。';

  @override
  String get share_streak_message =>
      '我一直在養成每日修持的好習慣，想和您分享。有朋友一起堅持會更容易。來 WeBuddhist 和我一起吧。';

  @override
  String get share_chant_message =>
      '我想和您分享這段持誦。您可以在 WeBuddhist 上修持它，還能找到完整的持誦與經典文庫。';

  @override
  String get share_quote_message =>
      '我喜歡 WeBuddhist 上的這段引文，想和您分享。在 WeBuddhist 應用程式上閱讀更多富有洞見的引文。';

  @override
  String get share_poem_message => '我喜欢WeBuddhist上的这首诗，想和你分享。';

  @override
  String share_poem_title(String title) {
    return '「$title」';
  }

  @override
  String get share_mala_message =>
      '我一直在 WeBuddhist 上使用這串電子念珠，想和您分享。這是隨時隨地修持的便利方式。';

  @override
  String get share_passage_message =>
      '我喜歡這段經文，想和您分享。您可以在 WeBuddhist 上閱讀完整的上下文。';

  @override
  String get share_timer_message =>
      '我想和您分享 WeBuddhist 上的這個禪修計時器。它讓建立禪修習慣變得更輕鬆。';

  @override
  String get share_plan_message =>
      '我正在跟隨這個佛法修持計畫，想和您分享。您可以在 WeBuddhist 上免費和我一起修持。';

  @override
  String get share_plan_subject => '在WeBuddhist上和我一起吧';

  @override
  String get share_group_invite_message => '來這個社群和我一起吧。讓我們在 WeBuddhist 上一起修持！';

  @override
  String get weekday_monday => '週一';

  @override
  String get weekday_tuesday => '週二';

  @override
  String get weekday_wednesday => '週三';

  @override
  String get weekday_thursday => '週四';

  @override
  String get weekday_friday => '週五';

  @override
  String get weekday_saturday => '週六';

  @override
  String get weekday_sunday => '週日';

  @override
  String get reader_search_failed => '搜尋失敗。\n請重試';

  @override
  String get reader_swipe_up_for_more => '向上滑動查看更多';

  @override
  String get reader_videos => '影片';

  @override
  String get mala_no_mantras => '暫無咒語';

  @override
  String get mala_count_load_error => '無法載入您的計數';

  @override
  String get bookmarks_empty_all_title => '尚無書籤';

  @override
  String get bookmarks_empty_all_subtitle => '加入書籤，即可將任何內容儲存於此。';

  @override
  String get bookmarks_empty_plans_title => '尚無加入書籤的修持計畫';

  @override
  String get bookmarks_empty_plans_subtitle => '將修持計畫加入書籤，即可收藏於此';

  @override
  String get bookmarks_empty_malas_title => '尚無加入書籤的念珠';

  @override
  String get bookmarks_empty_malas_subtitle => '將念珠加入書籤，即可收藏於此';

  @override
  String get bookmarks_empty_group_accumulations_title => '尚無加入書籤的共修計數';

  @override
  String get bookmarks_empty_group_accumulations_subtitle => '將共修計數加入書籤，即可收藏於此';

  @override
  String get bookmarks_empty_timers_title => '尚無加入書籤的計時器';

  @override
  String get bookmarks_empty_timers_subtitle => '將計時器加入書籤，即可收藏於此';

  @override
  String get bookmarks_empty_texts_title => '尚無加入書籤的文本';

  @override
  String get bookmarks_empty_texts_subtitle => '將文本加入書籤，即可收藏於此';

  @override
  String get bookmark_removed => '已移除書籤';

  @override
  String get bookmark_remove_failed => '無法移除書籤';

  @override
  String get bookmark_saved => '書籤已儲存';

  @override
  String get bookmark_save_failed => '無法儲存書籤';

  @override
  String get bookmarks_yesterday => '昨天';

  @override
  String get webview_timeout_error => '頁面載入時間過長。請檢查您的網路連線';

  @override
  String get webview_load_failed => '無法載入頁面';

  @override
  String get privacy_policy_load_error => '無法載入隱私政策頁面';

  @override
  String get terms_of_service_load_error => '無法載入服務條款頁面';

  @override
  String get series_enroll_error => '無法加入系列';

  @override
  String series_share_message(String title, String url) {
    return '和我一起在 WeBuddhist 上修習 $title。\n\n$url';
  }

  @override
  String get player_back_10 => '後退 10 秒';

  @override
  String get player_pause => '暫停';

  @override
  String get player_play => '播放';

  @override
  String get player_forward_10 => '快進 10 秒';

  @override
  String get player_fullscreen => '全螢幕';

  @override
  String get player_exit_fullscreen => '退出全螢幕';

  @override
  String get session_plans_load_error => '無法載入計畫。\n請稍後再試';

  @override
  String get session_chants_load_error => '無法載入課誦';

  @override
  String get session_no_chants => '未找到課誦';

  @override
  String get session_malas_load_error => '無法載入念珠';

  @override
  String get session_no_malas => '未找到念珠';

  @override
  String get session_timers_load_error => '無法載入計時器';

  @override
  String get session_no_timers => '未找到計時器';

  @override
  String days_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天',
    );
    return '$_temp0';
  }

  @override
  String timer_minute_session(int minutes) {
    return '$minutes 分鐘練習';
  }

  @override
  String get timer_notification_in_progress => '禪修進行中';

  @override
  String timer_notification_paused(String time) {
    return '已暫停 · 剩餘 $time';
  }

  @override
  String get timer_notification_complete => '你的課程已完成';

  @override
  String plan_day_of(int day, int total) {
    return '第 $day 天，共 $total 天';
  }

  @override
  String pagination_position(int current, int total) {
    return '$current / $total';
  }

  @override
  String get plan_shorts_title => '社群短片';

  @override
  String get author_details_load_error => '無法載入作者資料\n請重試';

  @override
  String get link_cannot_open => '無法開啟此連結';

  @override
  String get link_invalid => '無效的網址';

  @override
  String get author_no_plans => '尚未建立修持計畫';

  @override
  String get author_plans_load_error => '無法載入修持計畫';

  @override
  String get drag_to_resize => '拖動以調整大小';

  @override
  String get day_completion_share_message =>
      '我剛在 WeBuddhist 上完成了今天的修持。加入我，一起培養每日修持的好習慣。';

  @override
  String group_accumulator_share_message(String accumulation, String group) {
    return '我正在參加 WeBuddhist 上 $group 社群的共修計數「$accumulation」，快來加入我吧！';
  }

  @override
  String group_accumulator_share_message_no_group(String accumulation) {
    return '我正在參加 WeBuddhist 上的共修計數「$accumulation」，快來加入我吧！';
  }

  @override
  String get chats_title => '聊天室';

  @override
  String get chats_empty_title => '尚無聊天室';

  @override
  String get chats_empty_body => '加入共修空間，即可開始聊天';

  @override
  String get group_chat_inappropriate => '此訊息包含不允許的用語，因此無法傳送';

  @override
  String get group_chat_not_a_member => '只有成員可以開啟此聊天室';

  @override
  String get group_chat_open => '聊天';

  @override
  String get group_chat_message_hint => '訊息';

  @override
  String get group_chat_today => '今天';

  @override
  String get group_chat_yesterday => '昨天';

  @override
  String get group_chat_empty_title => '尚無訊息';

  @override
  String get group_chat_empty_body => '和您的社群開始聊天吧';

  @override
  String get group_chat_load_failed => '無法載入訊息';

  @override
  String get chat_room_closed => 'This chat has been closed.';

  @override
  String get group_chat_message_not_found => '此訊息已不在聊天中';

  @override
  String get group_chat_message_too_far_back =>
      'This message is further back in the chat';

  @override
  String get group_chat_keep_looking => 'Keep looking';

  @override
  String get group_chat_retry => '重試';

  @override
  String get group_chat_unknown_sender => '成員';

  @override
  String get group_chat_reactions_all => '全部';

  @override
  String get group_chat_reacted => '已回應';

  @override
  String get group_chat_reply => '回覆';

  @override
  String get group_chat_copy => '複製';

  @override
  String get group_chat_copied => '訊息已複製';

  @override
  String get group_chat_report => '檢舉';

  @override
  String get group_chat_report_title => '您為什麼要檢舉此內容？';

  @override
  String get group_chat_report_privacy => '您的姓名將保密';

  @override
  String get group_chat_report_reason_harassment => '騷擾或霸凌';

  @override
  String get group_chat_report_reason_hate => '仇恨或有害言論';

  @override
  String get group_chat_report_reason_sexual => '色情或露骨內容';

  @override
  String get group_chat_report_reason_spam => '垃圾訊息或詐騙';

  @override
  String get group_chat_report_reason_off_topic => '離題或干擾';

  @override
  String get group_chat_report_reason_other => '其他';

  @override
  String get group_chat_report_note_title => '新增備註';

  @override
  String get group_chat_report_note_hint => '其他...';

  @override
  String get group_chat_report_submit => '送出檢舉';

  @override
  String get group_chat_report_thanks => '感謝您的回饋';

  @override
  String get group_chat_report_offline => '您目前離線。請稍後再試';

  @override
  String get group_chat_report_failed => '無法送出檢舉';

  @override
  String get group_chat_report_retry => '重試';

  @override
  String get group_chat_delete => '刪除';

  @override
  String get group_chat_delete_title => '要刪除訊息嗎？';

  @override
  String group_chat_delete_title_many(int count) {
    return '要刪除 $count 則訊息嗎？';
  }

  @override
  String group_chat_delete_confirm_body(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '這些訊息將從聊天室中對所有人移除',
      one: '此訊息將從聊天室中對所有人移除',
    );
    return '$_temp0';
  }

  @override
  String group_chat_delete_failed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '無法刪除 $count 則訊息',
      one: '無法刪除訊息',
    );
    return '$_temp0';
  }

  @override
  String group_chat_selection_limit(int count) {
    return '最多可選取 $count 則訊息';
  }

  @override
  String get group_chat_message_deleted_by_sender => '此訊息已被刪除';

  @override
  String get group_chat_reaction_failed => '無法儲存您的回應';

  @override
  String group_chat_reactions_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個回應',
      one: '1 個回應',
    );
    return '$_temp0';
  }

  @override
  String get group_chat_you => '您';

  @override
  String get group_chat_tap_to_remove => '點一下即可移除';

  @override
  String get group_chat_reply_parent_gone => '該訊息已無法使用，因此已移除引用。請重新傳送以發布您的訊息';

  @override
  String get group_tab_posts => '貼文';

  @override
  String get group_tab_events => '活動';

  @override
  String get group_posts_empty_title => '尚無貼文';

  @override
  String get group_posts_empty_message => '分享您社群的第一則動態';

  @override
  String get group_posts_load_error => '無法載入貼文，請再試一次';

  @override
  String get group_post_button => '發布';

  @override
  String get group_post_new_title => '新貼文';

  @override
  String get group_post_posting_to => '發布至：';

  @override
  String get group_post_caption_hint => '有什麼新消息？';

  @override
  String get group_post_photos => '相片';

  @override
  String get group_post_link => '連結';

  @override
  String get group_post_discard_title => '要捨棄貼文嗎？';

  @override
  String get group_post_discard_message => '您撰寫的內容將會遺失';

  @override
  String get group_post_keep_editing => '繼續編輯';

  @override
  String get group_post_discard => '捨棄';

  @override
  String get group_post_add_link_title => '新增連結';

  @override
  String get group_post_add_link_hint => '貼上連結，我們會顯示預覽';

  @override
  String get group_post_link_field_hint => '連結';

  @override
  String get group_post_attach => '附加';

  @override
  String get group_post_attach_as_link => '以連結形式附加';

  @override
  String get group_post_preview_failed_title => '無法載入預覽';

  @override
  String get group_post_preview_failed_message => '您仍可以連結形式附加';

  @override
  String get group_post_invalid_link => '請輸入有效的連結，例如：https://example.com';

  @override
  String get group_post_in_app_content => 'In-app content';

  @override
  String get group_post_add_in_app_content_title => 'Add in-app content';

  @override
  String get group_post_in_app_content_empty => 'Nothing to add yet';

  @override
  String group_post_photo_limit(int count) {
    return '最多可新增 $count 張相片';
  }

  @override
  String get group_post_upload_error => '無法上傳相片，請再試一次';

  @override
  String get group_post_publish_error => '無法發布您的貼文，請再試一次';

  @override
  String get group_post_published => '您的貼文已發布。';

  @override
  String get group_post_delete_title => '要刪除貼文嗎？';

  @override
  String get group_post_delete_message => '此貼文將被永久刪除';

  @override
  String get group_post_delete_failed => '無法刪除貼文，請再試一次';

  @override
  String get edit => '編輯';

  @override
  String get group_post_edit_title => '編輯貼文';

  @override
  String get group_post_update_error => '無法儲存您的變更，請再試一次';

  @override
  String get group_post_updated => '您的變更已儲存';

  @override
  String get practice_collection_already_added => '此持誦集已在您的修持中';

  @override
  String get practice_group_accumulator_already_added => '此共修計數已在您的修持中';

  @override
  String get event_live_badge => '直播中';

  @override
  String get event_live_video_mode => '影片';

  @override
  String get event_live_audio_mode => '音訊';

  @override
  String get event_live_go_live => '直播中';

  @override
  String get event_replays => '回放';

  @override
  String event_replay_session(String day, String session) {
    return '第 $day 天 · 第 $session 場';
  }

  @override
  String get event_replay_recording => '錄影';

  @override
  String get event_replay_back_to_live => '返回直播';

  @override
  String get event_replays_empty => '尚無錄影';

  @override
  String get event_puja_starts_in => '法會開始於';

  @override
  String get event_puja_not_started => '法會尚未開始';

  @override
  String get event_prayer_requests => '迴向與祈願';

  @override
  String event_prayer_request_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      one: '1 個迴向祈願',
      other: '$count 個迴向祈願',
    );
    return '$_temp0';
  }

  @override
  String get event_prayer_empty_title => '尚無迴向祈願名單';

  @override
  String get event_prayer_empty_body => '您的迴向祈願與您社群的迴向祈願會出現在這裡';

  @override
  String get event_prayer_add => '加入迴向名單';

  @override
  String get event_prayer_hint => '今天我們可以為您祈願什麼呢？';

  @override
  String event_prayer_hint_intention(String topics) {
    return 'Request a prayer for: $topics';
  }

  @override
  String get event_prayer_load_failed => '無法載入迴向祈願';

  @override
  String get event_prayer_closed => '本活動的迴向名單已關閉';

  @override
  String get group_prayer_closed => 'Prayer requests are closed for this space';

  @override
  String get group_prayer_delete_body =>
      'It will be removed for everyone in this space.';

  @override
  String get event_prayer_pray => '迴向祈願';

  @override
  String event_prayer_my_count(int count) {
    return '+$count';
  }

  @override
  String get event_prayer_new_request => '新增迴向祈願';

  @override
  String get event_prayer_edit_request => '編輯迴向祈願內容';

  @override
  String get event_prayer_delete_title => '要刪除此迴向祈願?';

  @override
  String get event_prayer_delete_body => '此則迴向祈願將從本活動刪除';

  @override
  String get event_prayer_delete_failed => '無法刪除此迴向祈願';

  @override
  String get event_prayer_choose_intention => '選擇一種願望';

  @override
  String get event_prayer_intentions_failed => '無法載入祈願意向';

  @override
  String get event_prayer_request_button => '申請迴向祈願';

  @override
  String get event_prayer_you => '你';

  @override
  String get event_prayer_waiting_first => '正在等待第一個迴向祈願⋯⋯';

  @override
  String event_prayer_more_praying(int count) {
    return '+$count 人已迴向';
  }

  @override
  String event_prayer_people_praying(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 人已迴向',
      one: '1 人已迴向',
    );
    return '$_temp0';
  }

  @override
  String get event_prayer_praying_for_you => '已為您迴向';

  @override
  String get event_prayer_your_request => '您的迴向祈願';

  @override
  String get event_prayer_supporters_failed => '無法載入正在迴向祈願的人';

  @override
  String get event_prayer_no_supporters => '目前還沒有人迴向';

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
  String get recitation_live_sync => '同步';

  @override
  String get recitation_live_label => '直播中';

  @override
  String get recitation_live_session_ended => '直播已結束';

  @override
  String get feedback_add_image => '新增圖片';

  @override
  String feedback_image_limit(int count) {
    return '最多可附加 $count 張圖片';
  }

  @override
  String get feedback_send => '傳送';

  @override
  String get feedback_error_offline => '您目前離線。請稍後再試';

  @override
  String get feedback_error_rate_limited => '請求次數過多。請稍候再試';

  @override
  String get feedback_error_too_large => '圖片太大。請移除一張後再試';

  @override
  String get feedback_error_failed => '無法送出意見回饋，請再試一次';

  @override
  String get feedback_error_unavailable => '目前無法使用意見回饋';

  @override
  String get settings_help_contact_row => '協助與聯絡';

  @override
  String get help_contact_title => '協助與聯絡';

  @override
  String get help_contact_intro => '回報問題、分享想法，或提供協助與合作。我們會閱讀每一則訊息。';

  @override
  String get help_contact_message => '訊息';

  @override
  String get help_contact_photos => '照片或螢幕截圖（選填）';

  @override
  String get help_contact_topic => '這是關於什麼？（選填）';

  @override
  String get help_contact_hint_default => '您想告訴我們什麼？';

  @override
  String get help_contact_hint_report_problem => '發生了什麼事？您在那之前正在做什麼？附上截圖會很有幫助。';

  @override
  String get help_contact_hint_idea_feedback => '怎樣能讓 WeBuddhist 對您的修行更有幫助？';

  @override
  String get help_contact_hint_suggest_content => '您希望在這裡看到哪些教法、經文或老師？歡迎附上連結。';

  @override
  String get help_contact_hint_help_collaborate =>
      '您想如何協助？請分享您的技能、語言能力，或能提供的時間。';

  @override
  String get help_topic_report_problem => '回報問題';

  @override
  String get help_topic_idea_feedback => '想法或意見';

  @override
  String get help_topic_suggest_content => '建議內容';

  @override
  String get help_topic_help_collaborate => '協助或合作';

  @override
  String get help_contact_footer => '回覆會由 WeBuddhist 團隊傳送到您的聊天室。';

  @override
  String get help_contact_sent_title => '訊息已送出';

  @override
  String get help_contact_sent_body =>
      '謝謝。我們通常會在 1 天內回覆。您可以在聊天室中看到 WeBuddhist 團隊的回覆。';

  @override
  String help_contact_sent_body_named(String name) {
    return '謝謝，$name。我們通常會在 1 天內回覆。您可以在聊天室中看到 WeBuddhist 團隊的回覆。';
  }

  @override
  String get help_contact_your_request => '您的請求';

  @override
  String get help_contact_open_chat => '開啟聊天室';

  @override
  String get help_context_sent_from => '來自協助與聯絡';

  @override
  String help_context_photos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 張照片',
    );
    return '$_temp0';
  }

  @override
  String get chat_official_badge => '官方';

  @override
  String get chat_team_reply_time => '通常在 1 天內回覆';

  @override
  String get connect_failed_load_discover_groups_error => '無法下載社群清單';

  @override
  String get connect_failed_like_post_error => '無法幫貼文點讚';

  @override
  String get connect_failed_unlike_post_error => '無法刪除貼文點讚';

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
  String get reader_display_title => '顯示';

  @override
  String get text_size => '文字大小';

  @override
  String get reader_more_settings => '更多設定';

  @override
  String get reader_spacing => '間距';

  @override
  String get reader_spacing_compact => '緊湊';

  @override
  String get reader_spacing_normal => '標準';

  @override
  String get reader_spacing_relaxed => '寬鬆';

  @override
  String get reader_background => '背景';

  @override
  String get reader_background_rice_paper => '宣紙';

  @override
  String get reader_background_gold => '金色';

  @override
  String get reader_background_sky => '天藍';

  @override
  String get reader_background_white => '白色';

  @override
  String get reader_background_plum => '梅紫';

  @override
  String get reader_background_temple_red => '寺院紅';

  @override
  String get reader_background_robe_saffron => '袈裟橙';

  @override
  String get reader_in_the_text => '文中';

  @override
  String get reader_ritual_instructions => '儀軌說明';

  @override
  String get reader_verse_numbers => '偈頌編號';

  @override
  String get reader_change_languages => '更改語言';

  @override
  String get reader_live_paused => '已暫停';

  @override
  String get reader_text_smaller => '縮小文字';

  @override
  String get reader_text_larger => '放大文字';

  @override
  String reader_section_position(String current, String total) {
    return '第 $current / $total 節';
  }

  @override
  String reader_round_position(String current, String total) {
    return '第 $current / $total 輪';
  }

  @override
  String reader_round_number(String current) {
    return '第 $current 輪';
  }

  @override
  String reader_count_position(String current, String total) {
    return '$current / $total';
  }

  @override
  String reader_show_script_in(String language) {
    return '$language顯示方式';
  }

  @override
  String reader_verse_label(String number) {
    return '偈頌 $number';
  }

  @override
  String get reader_tab_commentary => '注釋';

  @override
  String get reader_tab_versions => '版本';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get appTitle => 'WeBuddhist';

  @override
  String get sign_in => '登录';

  @override
  String get logout => '退出登录';

  @override
  String get onboarding_welcome => '欢迎来到';

  @override
  String get onboarding_tagline => '学习、修持、连结。每日。';

  @override
  String get onboarding_find_peace => '立即开始';

  @override
  String get onboarding_continue => '下一步';

  @override
  String get onboarding_first_question => '选择您的语言';

  @override
  String get onboarding_language_subtitle => '这会设置应用程序的语言';

  @override
  String get onboarding_all_set => '一切就绪';

  @override
  String get onboarding_all_set_description => '以下是为您准备的内容：';

  @override
  String get onboarding_all_set_practice_title => '修持';

  @override
  String get onboarding_all_set_practice_body => '修持计划、持诵、念珠与禅修';

  @override
  String get onboarding_all_set_connect_title => '连结';

  @override
  String get onboarding_all_set_connect_body => '社群、活动、动态与聊天';

  @override
  String get home_today => '今天';

  @override
  String get home_overall_stats => '整体统计';

  @override
  String home_plans_count(int count) {
    return '$count 计划';
  }

  @override
  String home_recitation_count(int count) {
    return '$count 持诵';
  }

  @override
  String get home_shortcut_plans => '计划';

  @override
  String get home_chants => '持诵';

  @override
  String get home_mala => '念珠';

  @override
  String get session_mala => '念珠';

  @override
  String get bookmark_mala => '念珠';

  @override
  String get bookmark_timers => '计时器';

  @override
  String get bookmark_texts => '经文';

  @override
  String get bookmark_group_accumulation => '共修空间总计数';

  @override
  String get mala_add_to_practice => '加入我的修持';

  @override
  String get mala_add_mala_round => '添加念珠遍数';

  @override
  String get mala_add_rounds_title => '添加念珠遍数：';

  @override
  String get mala_add_rounds_message => '添加您在此应用程序之外完成的念珠遍数';

  @override
  String mala_rounds_unit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '遍',
      one: '遍',
    );
    return '$_temp0';
  }

  @override
  String get mala_add_to_bookmark => '书签';

  @override
  String get mala_sound => '声音';

  @override
  String get mala_vibration => '震动';

  @override
  String get mala_reset_count => '重设计数';

  @override
  String get mala_reset_title => '重设此念珠？';

  @override
  String get mala_reset_count_confirm => '目前的计数将归零，但您累积的次数仍会保留在终身总数中';

  @override
  String get mala_reset_confirm => '重设';

  @override
  String get mala_action_coming_soon => '即将推出';

  @override
  String mala_rounds_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 遍',
      one: '1 遍',
      zero: '0 遍',
    );
    return '$_temp0';
  }

  @override
  String get mala_hand_layout_tooltip => '切换左右手布局';

  @override
  String get mala_settings_section => '念珠设置';

  @override
  String get mala_others_section => '其他';

  @override
  String get mala_mantra_speed => '咒语速度';

  @override
  String get mala_speed_normal => '正常';

  @override
  String get mala_show_full_mantra => '显示完整咒语';

  @override
  String mala_counter_semantics(int bead, int total, String rounds) {
    return '计数 $bead/$total，$rounds';
  }

  @override
  String get mala_group_accumulations => '加入持诵计数';

  @override
  String get mala_groups_section => '社群';

  @override
  String get mala_group_untitled => '未命名社群';

  @override
  String get mala_all_time_accumulation => '我的累计总数';

  @override
  String get mala_personal_practice => '个人修持';

  @override
  String get mala_events_section => '活动';

  @override
  String mala_my_total(String count) {
    return '我的总数：$count';
  }

  @override
  String mala_group_total(String count) {
    return '群组总数：$count';
  }

  @override
  String get home_timer => '计时';

  @override
  String get preset_timers => '预设计时';

  @override
  String get meditation_timer => '禅修计时';

  @override
  String get timer_min => '分钟';

  @override
  String get timer_finish => '完成';

  @override
  String get timer_discard_session => '放弃此次修持';

  @override
  String get home_hello_prefix => '你好，';

  @override
  String home_share_prompt(String appName) {
    return '喜欢 $appName 吗？';
  }

  @override
  String get home_share_support => '您的支持能帮助我们的社群成长。';

  @override
  String get no_feature_content => '尚无精选内容';

  @override
  String get nav_home => '首页';

  @override
  String get nav_explore => '探索';

  @override
  String get nav_learn => '学习';

  @override
  String get nav_practice => '修持计划';

  @override
  String get nav_settings => '设置';

  @override
  String get nav_connect => '社群';

  @override
  String get nav_me => '个人';

  @override
  String get tab_practices => '修持计划';

  @override
  String get text_search => '搜索';

  @override
  String get text_commentary => '注释';

  @override
  String get resources => '资源';

  @override
  String get no_translation => '尚无相关翻译';

  @override
  String get show_more => '显示更多';

  @override
  String get show_less => '显示较少';

  @override
  String get more => '更多';

  @override
  String get less => '较少';

  @override
  String get no_content => '尚无相关内容';

  @override
  String commentary_not_available_for_language(String language) {
    return '暂无 $language 注释';
  }

  @override
  String get loading => '加载中...';

  @override
  String get save => '保存';

  @override
  String get done => '完成';

  @override
  String get my_plans => '我的计划';

  @override
  String get browse_plans => '浏览修持计划';

  @override
  String get plan_info => '修持计划内容';

  @override
  String get start_reading => '立即修持';

  @override
  String get tibetan => '藏文';

  @override
  String get sanskrit => '梵文';

  @override
  String get english => '英文';

  @override
  String get chinese => '繁体中文';

  @override
  String get classicalChinese => '佛经文体';

  @override
  String get pali => '巴利文';

  @override
  String get language => '语言';

  @override
  String get plan_unenroll => '退出计划';

  @override
  String get unenroll_confirmation => '确定要退出吗';

  @override
  String get unenroll_message => '您的进度将被永久删除，且无法复原';

  @override
  String get practice_plan => '创建每日修持。探索适合您的内容';

  @override
  String get search_plans => '搜索计划...';

  @override
  String get search_for_plans => '搜索计划';

  @override
  String get no_plans_found => '找不到相关计划';

  @override
  String get no_days_available => '找不到相关天数';

  @override
  String get recitations_search => '搜索';

  @override
  String get recitations_search_for => '寻找持诵内容';

  @override
  String get recitations_no_found => '尚无相关持诵内容';

  @override
  String get recitations_no_content => '没有可用的持诵';

  @override
  String get my_recitation_collection_new_title => '新持诵集';

  @override
  String get my_recitation_collection_next => '下一步';

  @override
  String get my_recitation_collection_create => '创建';

  @override
  String get my_recitation_collection_create_button => '创建持诵集';

  @override
  String get my_recitation_collection_change_title => '变更标题';

  @override
  String get my_recitation_collection_change => '变更';

  @override
  String get my_recitation_collection_add_chants => '添加持诵';

  @override
  String get my_recitation_collection_search_chants => '搜索持诵';

  @override
  String get my_recitation_collection_add_to_collection => '加入持诵集';

  @override
  String get my_recitation_collection_edit => '编辑持诵集';

  @override
  String get my_recitation_collection_delete => '删除持诵集';

  @override
  String get my_recitation_collection_delete_title => '要删除持诵集吗？';

  @override
  String get my_recitation_collection_delete_message => '此持诵集将被永久删除';

  @override
  String get my_recitation_collection_fallback_title => '持诵集';

  @override
  String get my_recitation_collection_unavailable => '已无法使用';

  @override
  String my_recitation_collection_chant_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 段持诵',
      one: '1 段持诵',
      zero: '0 段持诵',
    );
    return '$_temp0';
  }

  @override
  String my_recitation_collection_chant_count_owner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 段持诵 • 我',
      one: '1 段持诵 • 我',
      zero: '0 段持诵 • 我',
    );
    return '$_temp0';
  }

  @override
  String get bookmarks_empty_chant_collections_title => '尚无加入书签的法本';

  @override
  String get bookmarks_empty_chant_collections_subtitle => '将法本加入书签，即可收藏于此';

  @override
  String get notification_allow_title => '允许通知';

  @override
  String get notification_allow_subtitle_disabled => '需要权限。请点此前往「设置」授权';

  @override
  String get notification_snack_permission_denied => '通知已被封锁。请在「设置」中打开';

  @override
  String get notification_snack_disable_alarms_in_settings => '在「设置」中关闭闹钟与提醒';

  @override
  String get notification_allow_subtitle_on => '来自 WeBuddhist 的提醒与更新';

  @override
  String get notification_allow_subtitle_off => '已关闭。打开后即可收到提醒与更新。';

  @override
  String get notification_section_practice => '修持';

  @override
  String get notification_section_connect => '社群';

  @override
  String get notification_row_plans => '修持计划';

  @override
  String get notification_row_chants => '持诵';

  @override
  String get notification_row_mala => '念珠与总计数';

  @override
  String get notification_row_timer => '计时器';

  @override
  String get notification_row_group_posts => '社群贴文';

  @override
  String get notification_row_group_chats => '社群聊天室';

  @override
  String get notification_row_my_prayer_requests => '我的回向与祈愿';

  @override
  String get notification_row_others_prayer_requests => '他人的回向与祈愿';

  @override
  String get profile_default_bio => '欢迎来到 WeBuddhist';

  @override
  String get profile_guest_title => '访客';

  @override
  String get profile_guest_subtitle => '您正以访客身分浏览';

  @override
  String get profile_guest_benefits_header => '登录以解锁：';

  @override
  String get profile_guest_benefit_save_progress => '保存您的进度';

  @override
  String get profile_guest_benefit_personalized => '个人化内容';

  @override
  String get profile_guest_benefit_notifications => '自订通知';

  @override
  String get auth_drawer_title => '请登录帐号后再继续';

  @override
  String get auth_drawer_subtitle => '随时随地，在任何设备上继续您的修持';

  @override
  String get routine_delete_block_message => '这将删除该时段及其中所有内容';

  @override
  String get something_went_wrong => '出了点问题。请再试一次';

  @override
  String get onboarding_tradition_title => '您如何依循佛陀的教法？';

  @override
  String get onboarding_tradition_subtitle => '为您的内容选择一个或多个传承。您随时可以在「设置」中变更。';

  @override
  String get onboarding_tradition_show_all_title => '显示所有内容';

  @override
  String get plan_go_to_practice => '前往修持计划';

  @override
  String get plan_starts_soon_title => '计划即将开始';

  @override
  String get plan_joining_late_title => '在开始日期后加入';

  @override
  String get got_it => '明白了';

  @override
  String get plan_no_tasks_error => '无法加载任务';

  @override
  String get plan_day_tasks_load_error => '无法加载当日任务';

  @override
  String get plans_empty_title => '更多内容即将推出';

  @override
  String get plans_empty_subtitle => '我们将持续添增修持课程，欢迎随时回来浏览。';

  @override
  String get find_plans_load_error => '无法加载计划，\n请检查你的网络连接后再试。';

  @override
  String get connect_subtitle => '寻找你的社群，一起修持';

  @override
  String get discover_groups => '探索社群';

  @override
  String get my_groups => '我的社群';

  @override
  String get see_all => '查看全部';

  @override
  String get connect_groups_load_error => '无法加载社群，\n请检查网络连接后重试';

  @override
  String get connect_groups_empty_title => '尚无社群';

  @override
  String get connect_tab_feed => '动态';

  @override
  String get connect_tab_events => '活动';

  @override
  String get connect_tab_practices => '修持计划';

  @override
  String get connect_tab_groups => '社群';

  @override
  String get connect_segment_my => '您的社群';

  @override
  String get connect_segment_discover => '探索';

  @override
  String get connect_empty_discover_events => '没有可探索的活动';

  @override
  String get connect_empty_discover_feed => '没有可探索的内容';

  @override
  String get connect_empty_discover_groups => '没有可探索的共修空间';

  @override
  String get connect_all_groups => '所有共修空间';

  @override
  String get connect_my_empty_feed_title => '您的共修空间最近很安静';

  @override
  String get connect_my_empty_events_title => '没有即将举行的活动';

  @override
  String get connect_my_empty_groups_title => '尚未加入社群';

  @override
  String get connect_my_empty_feed_subtitle => '您的社群还没有分享新内容';

  @override
  String get connect_my_empty_events_subtitle => '您的社群还没有安排任何活动';

  @override
  String get connect_my_empty_groups_subtitle => '你还没有加入任何社群。探索可以一起修持的社群。';

  @override
  String get connect_my_empty_feed_browse => '看看其他共修空间在分享什么';

  @override
  String get connect_my_empty_events_browse => '浏览开放活动';

  @override
  String connect_comment_replying_to(String handle) {
    return '回复 @$handle';
  }

  @override
  String get connect_comment_hint => '请问您对这则贴文有什么想法？';

  @override
  String get connect_comment_reply_hint => '撰写回复…';

  @override
  String get connect_comment_reply => '回复';

  @override
  String get connect_comment_delete_title => '删除留言？';

  @override
  String get connect_comment_delete_message => '这则留言将被永久删除';

  @override
  String get connect_comment_delete_failed => '无法删除留言';

  @override
  String connect_post_comments_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 则留言',
    );
    return '$_temp0';
  }

  @override
  String get connect_post_comments_empty => '还没有留言。开始讨论吧';

  @override
  String get connect_online => '在线';

  @override
  String get connect_ended => '已结束';

  @override
  String connect_ended_on(String date) {
    return '已于 $date 结束';
  }

  @override
  String get home_group_events => '精选活动';

  @override
  String get home_poems => '诗偈';

  @override
  String get poems_load_error => '无法加载诗歌。\n请检查您的连接并再试一次';

  @override
  String get poems_empty => '尚无诗歌，请稍后再来。';

  @override
  String get connect_events_filter_all => '全部';

  @override
  String get connect_events_filter_in_person => '现场';

  @override
  String get connect_events_filter_empty_online => '尚无在线活动';

  @override
  String get connect_events_filter_empty_in_person => '尚无现场活动';

  @override
  String get connect_events_filter_hybrid => '混合型';

  @override
  String get connect_events_filter_empty_hybrid => '没有混合型的活动';

  @override
  String get connect_event_fallback_title => '活动';

  @override
  String get connect_group_fallback_title => '共修空间';

  @override
  String get connect_event_participation_prompt => '您会怎么参加?';

  @override
  String get connect_event_practice_in_person => '现场修持';

  @override
  String get connect_event_practice_online => '在线修持';

  @override
  String get connect_event_view_in_person => '现场查看';

  @override
  String get connect_event_view_online => '在线查看';

  @override
  String get connect_event_accumulation_online => '线上';

  @override
  String get connect_event_accumulation_in_person => '现场';

  @override
  String get connect_event_has_ended => '此活动已结束';

  @override
  String get connect_event_join_to_practice => '参加活动即可修持';

  @override
  String get connect_event_leave => '退出活动';

  @override
  String get connect_event_leave_confirm_title => '要退出此活动吗？';

  @override
  String connect_event_leave_confirm_message(String title) {
    return '您将不再参加$title。您仍可查看此活动，并随时再次参加。';
  }

  @override
  String connect_event_participants_attending(int count) {
    return '$count 位参与者';
  }

  @override
  String connect_event_participants_attended(int count) {
    return '$count 人参加';
  }

  @override
  String get connect_event_participants_empty => '尚无人参加';

  @override
  String get connect_event_organizer => '主办单位';

  @override
  String get connect_event_tab_videos => '视频';

  @override
  String get connect_event_tab_about => '活动介绍';

  @override
  String get connect_event_links_title => '更多活动介绍';

  @override
  String get connect_event_date_tba => '日期尚待公告';

  @override
  String get connect_event_when => '时间';

  @override
  String get connect_event_where => '地点';

  @override
  String get connect_event_tab_accumulations => '计数统计';

  @override
  String get connect_event_add_recitations => '填入您的持诵次数';

  @override
  String get connect_event_add_recitations_message =>
      '添加您在线直播，或在此应用程序之外已完成的持诵次数';

  @override
  String get connect_event_every_day => '每天';

  @override
  String connect_event_every_weekday(String weekday) {
    return '每个$weekday';
  }

  @override
  String get connect_event_every_month => '每个月';

  @override
  String connect_event_every_date(String date) {
    return '输入$date';
  }

  @override
  String get connect_event_about_empty => '尚无活动信息';

  @override
  String get search_groups => '搜索社群';

  @override
  String get search_for_groups => '搜索社群';

  @override
  String get no_groups_found => '找不到符合的社群';

  @override
  String get explore_coming_soon_subtitle => '探索修持、教法与社群活动的精选空间。';

  @override
  String get learn_coming_soon_subtitle => '专为您日常生活设计的个人学习计划';

  @override
  String get creator_featured_plan => '精选计划';

  @override
  String get home_no_series_found => '未找到系列';

  @override
  String get home_no_tags_found => '找不到该标签';

  @override
  String get home_celebrated_by => '庆祝者：';

  @override
  String get reader_font_size_tooltip => '字体大小';

  @override
  String get reader_versions_load_error => '无法加载版本';

  @override
  String get reader_languages_load_error => '无法加载语言';

  @override
  String reader_no_versions_in_language(String language) {
    return '$language 尚无可用的版本。';
  }

  @override
  String get reader_no_languages => '此文本尚无可用的语言。';

  @override
  String get reader_license => '授权';

  @override
  String get text_search_hint => '输入以搜索';

  @override
  String get text_search_press_button => '按下搜索按钮以搜索';

  @override
  String get text_search_error => '无法执行搜索，请再试一次';

  @override
  String get create_image_share_error => '无法分享，请再试一次';

  @override
  String get my_plans_sign_in_prompt => '登录以查看您的计划';

  @override
  String plan_starts_soon_message(String date) {
    return '此计划将于 $date 开始。您可以先浏览内容。';
  }

  @override
  String plan_joining_late_message(String date) {
    return '此计划已于 $date 开始。您可以完成过去几天的任务。';
  }

  @override
  String get select_language => '语言设置';

  @override
  String get logout_confirmation => '您确定要退出登录吗？';

  @override
  String get cancel => '取消';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制';

  @override
  String get share => '分享';

  @override
  String get bookmark => '书签';

  @override
  String get collection_audio_versions => '音频版本';

  @override
  String get author => '作者';

  @override
  String get plans_created => '创建的修持计划';

  @override
  String get ai_confirm => '确认';

  @override
  String search_no_results(String query) {
    return '找不到「$query」的结果';
  }

  @override
  String get search_all => '全部';

  @override
  String get common_ok => '确定';

  @override
  String get comingSoonHeadline => '即将推出';

  @override
  String get routine_title => '日常修持';

  @override
  String get bookmarks => '书签';

  @override
  String get routine_empty_title => '日常修持';

  @override
  String get routine_edit => '编辑';

  @override
  String get routine_empty_description => '探索更多课程与修持计划，加入学习菜单或添加至您的修持安排';

  @override
  String get routine_build => '创建日常修持';

  @override
  String get routine_add_session => '添加课程';

  @override
  String get routine_edit_title => '编辑日常修持';

  @override
  String get routine_delete_block => '删除时段';

  @override
  String get routine_session_title_hint => '标题...';

  @override
  String get routine_expand_all => '全部展开';

  @override
  String get routine_collapse_all => '全部收合';

  @override
  String get routine_add_plan => '添加计划';

  @override
  String get routine_add_recitation => '添加持诵';

  @override
  String get routine_add_plan_to_routine => '添加至日常修持';

  @override
  String get routine_load_error => '无法加载。请检查您的网络连接，然后再试一次。';

  @override
  String get routine_empty_block_title_singular => '空白时段';

  @override
  String routine_empty_block_title_plural(int count) {
    return '空白时段 ($count)';
  }

  @override
  String get routine_empty_block_message_singular =>
      '此时段尚未添加内容。请添加或将其从您的修持安排中移除';

  @override
  String routine_empty_block_message_plural(int count) {
    return '有 $count 个时段尚未添加内容。请添加，或从您的修持安排中移除';
  }

  @override
  String get routine_empty_block_add_items => '添加清单';

  @override
  String get routine_empty_block_delete_singular => '删除时段';

  @override
  String get routine_empty_block_delete_plural => '删除空白时段';

  @override
  String get routine_notification_title => '让修持成为习惯';

  @override
  String get routine_notification_description => '请打开通知权限，以便我们提醒您进行修持。';

  @override
  String get routine_notification_enable => '启用通知';

  @override
  String get routine_notification_skip => '跳过';

  @override
  String routine_time_adjusted(String time, int gap) {
    return '已调整为 $time（最少 $gap 分钟的间隔）';
  }

  @override
  String get routine_add_block_label => '时段';

  @override
  String get continueWithGoogle => '使用 Google 继续';

  @override
  String get continueWithApple => '使用 Apple 继续';

  @override
  String get continueWithPhone => '使用电话继续';

  @override
  String get exploreAsGuest => '以访客身份探索';

  @override
  String get signIn => '登录';

  @override
  String get profileError => '加载个人资料时出错';

  @override
  String get profileTitle => '个人资料';

  @override
  String get notLoggedIn => '尚未登录';

  @override
  String get retry => '重试';

  @override
  String get back => '返回';

  @override
  String get delete => '删除';

  @override
  String get close => '关闭';

  @override
  String get tryAgain => '再试一次';

  @override
  String get pleaseTryAgain => '请再试一次';

  @override
  String get error => '错误';

  @override
  String get anonymous => '匿名';

  @override
  String get noContentAvailable => '没有可用内容';

  @override
  String get unableToLoad => '无法加载，请再试一次';

  @override
  String get somethingWrong => '出了点问题，请检查您的连接并重试';

  @override
  String get source => '来源';

  @override
  String get noTasks => '没有可用任务';

  @override
  String get taskNotFound => '找不到任务';

  @override
  String get updateTaskError => '无法更新任务状态';

  @override
  String get enrollError => '无法完成注册。请检查您的网络连接，然后再试一次。';

  @override
  String unenrollSuccess(String planTitle) {
    return '您已退出 $planTitle';
  }

  @override
  String get unenrollError => '无法取消注册。请检查您的网络连接，然后再试一次';

  @override
  String get unenrollGenericError => '发生错误。请检查您的网络连接，然后再试一次';

  @override
  String get notFound => '此内容已无法使用。请编辑您的修持安排以进行更新';

  @override
  String get noTimeSlot => '没有可用的时间段，请先移除一个区块';

  @override
  String maxBlocks(int max) {
    return '已达最多 $max 个可选时间区段上限。';
  }

  @override
  String get duplicateItem => '此项目已在本时间区块';

  @override
  String get removeItem => '移除项目';

  @override
  String removeConfirmation(String itemName) {
    return '要从此时段中移除「$itemName」吗？';
  }

  @override
  String shareError(String error) {
    return '无法分享。请再试一次';
  }

  @override
  String get captureError => 'QR code 扫描失败，请再试一次';

  @override
  String get qrShareError => '无法分享QRcode，请稍后再试';

  @override
  String errorDetail(String error) {
    return '错误：$error';
  }

  @override
  String missedDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '错过$count天',
      one: '错过1天',
      zero: '未错过天数',
    );
    return '$_temp0';
  }

  @override
  String get plan_status_on_track => '进度正常！';

  @override
  String get start_now => '立即开始';

  @override
  String get plan_enroll => '加入';

  @override
  String get root_text => '根本文';

  @override
  String get version => '所有版本';

  @override
  String get reader_languages_title => '语言';

  @override
  String get reader_sections_title => '章节';

  @override
  String get reader_original_label => '原文';

  @override
  String get reader_translation_label => '译文';

  @override
  String get version_not_available => '无可用版本';

  @override
  String series_stats(int planCount, int totalDays) {
    return '$planCount 个章节 · $totalDays 天';
  }

  @override
  String get force_update_title => '需要更新';

  @override
  String get force_update_message => '新版本已上线，请更新后再继续使用。';

  @override
  String get force_update_button => '立即更新';

  @override
  String get settings_section_personalisation => '个人化';

  @override
  String get settings_section_more => '更多';

  @override
  String get settings_section_account => '帐号';

  @override
  String get settings_edit_profile => '编辑个人资料';

  @override
  String get settings_theme => '主题';

  @override
  String get settings_notification_row => '通知';

  @override
  String get settings_feedback_row => '意见回馈';

  @override
  String get edit_profile_title => '编辑个人资料';

  @override
  String get edit_profile_save => '保存';

  @override
  String get edit_profile_bio => '自我介绍';

  @override
  String get edit_profile_bio_hint => '向大家介绍一下自己';

  @override
  String get edit_profile_delete_account => '删除帐号';

  @override
  String get edit_profile_photo_not_uploaded => '相片尚未上传';

  @override
  String get edit_profile_photo_too_large => '图片过大，请选择 1 MB 以下的相片后再试一次';

  @override
  String get edit_profile_photo_upload_failed => '无法上传您的相片，请再试一次';

  @override
  String get edit_profile_choose_from_library => '从相册选择';

  @override
  String get edit_profile_take_photo => '拍照';

  @override
  String get edit_profile_offline => '您目前离线中，请连接网络后再试一次';

  @override
  String get edit_profile_save_failed => '无法保存您的变更，请再试一次';

  @override
  String get edit_profile_traditions => '传承';

  @override
  String get edit_profile_choose_traditions => '选择您的传承';

  @override
  String get edit_profile_tradition_remove_failed => '无法移除传承，请再试一次';

  @override
  String get edit_profile_tradition_save_failed => '无法保存传承，请再试一次';

  @override
  String get username_label => '用户名';

  @override
  String get username_taken => '这个名称已被使用';

  @override
  String get username_available_label => '可使用：';

  @override
  String get username_check_error => '无法检查用户名，请再试一次';

  @override
  String get username_invalid_format => '用户名格式无效';

  @override
  String get username_min_length => '用户名至少需 3 个字符';

  @override
  String get username_max_length => '用户名不可超过 30 个字符';

  @override
  String get username_no_spaces => '用户名不可包含空格';

  @override
  String get username_invalid_chars => '仅允许字母、数字、_ . -';

  @override
  String get username_must_start_alphanumeric => '用户名须以字母或数字开头';

  @override
  String get username_must_end_alphanumeric => '用户名须以字母或数字结尾';

  @override
  String get person_name_min_length => '至少需要 1 个字符';

  @override
  String get person_name_max_length => '不得超过 50 个字符';

  @override
  String get person_name_invalid_chars => '仅允许字母、空格、连字号和撇号';

  @override
  String get about_title => '关于';

  @override
  String get about_connect_with_us => '与我们联系...';

  @override
  String get about_description =>
      '我们协助佛教徒透过每日的学习、修持与交流，能多一些善举，少一些恶行，并更深入了解自己的心。';

  @override
  String get about_social_website => '网站';

  @override
  String get me_guest_headline => '体验完整功能';

  @override
  String get me_guest_subtitle => '创建免费帐号以保存您的进度';

  @override
  String get me_my_stats => '我的统计';

  @override
  String me_day_streak(int count) {
    return '连续 $count 天';
  }

  @override
  String me_best_streak(int count) {
    return '最长连续：$count 天';
  }

  @override
  String get accumulations => '持诵计数';

  @override
  String get accumulations_search => '查找计数结果';

  @override
  String get accumulations_search_for => '寻找计数内容';

  @override
  String get accumulations_no_found => '尚无持诵计数纪录';

  @override
  String get me_accumulation => '累积总数';

  @override
  String get me_minutes => '分钟';

  @override
  String get me_hours => '小时';

  @override
  String get me_total_meditation_time => '禅修总时间';

  @override
  String get me_days_plan_practiced_suffix => '天计划已完成';

  @override
  String get me_streak_share_quote => '我在 WeBuddhist 的连续纪录！';

  @override
  String me_streak_days_count(int count) {
    return '$count 天';
  }

  @override
  String get share_this_streak => '分享我的连续纪录';

  @override
  String get me_streak_share_error => '无法分享连续纪录，请重试';

  @override
  String get delete_account_title => '删除帐号';

  @override
  String get delete_account_description =>
      '若您删除帐号，您在 WeBuddhist 中的所有数据、纪录与个人化设置将被永久删除。请注意，此操作无法复原。如欲继续，请点按下方按钮。';

  @override
  String get delete_account_button => '删除帐号';

  @override
  String get delete_account_confirm_message => '您确定要删除您的 WeBuddhist 帐号吗？';

  @override
  String get legal_title => '法律信息';

  @override
  String get legal_terms_of_service => '使用条款';

  @override
  String get legal_privacy_policy => '隐私政策';

  @override
  String get follow => '追踪';

  @override
  String get calendar_title => '日历';

  @override
  String get calendar_upcoming_events => '近期活动';

  @override
  String get calendar_day_short => '日';

  @override
  String get calendar_day_label => '日';

  @override
  String calendar_lunar_month(String ordinal) {
    return '藏历$ordinal月';
  }

  @override
  String get moon_phase_new_moon => '新月';

  @override
  String get moon_phase_first_quarter => '上弦月';

  @override
  String get moon_phase_full_moon => '满月';

  @override
  String get join => '加入';

  @override
  String get group_member => '位成员';

  @override
  String get group_members => '位成员';

  @override
  String get group_tab_members => '成员';

  @override
  String get group_tab_followers => '追踪者';

  @override
  String group_members_heading(int count) {
    return '成员 ($count)';
  }

  @override
  String group_followers_heading(int count) {
    return '追踪者($count)';
  }

  @override
  String get group_invite => '邀请';

  @override
  String get group_notifications_title => '通知';

  @override
  String get group_notifications_chat => '社群聊天室';

  @override
  String get group_notifications_content => '社群内容';

  @override
  String get group_notifications_master_off => '此应用程序的通知已关闭';

  @override
  String get group_notifications_open_settings => '打开';

  @override
  String get group_notifications_update_failed => '无法更新通知设置，请再试一次';

  @override
  String get group_notifications_load_failed => '无法加载通知设置';

  @override
  String get group_chat_mute_notifications => '将聊天室通知设为静音';

  @override
  String get group_chat_unmute_notifications => '取消聊天室通知静音';

  @override
  String get group_chat_notifications_muted => '已将聊天室通知设为静音';

  @override
  String get group_chat_notifications_unmuted => '聊天室通知已开启';

  @override
  String get group_leave_confirm_message => '您将不再收到此社群的消息和动态';

  @override
  String get group_leave_space => '退出社群';

  @override
  String get group_leave_space_confirm_title => '要退出此社群吗？';

  @override
  String get group_leave_space_failed => '无法退出社群，请再试一次';

  @override
  String get group_request_to_join => '申请加入';

  @override
  String get group_request => '申请加入';

  @override
  String get group_request_sent => '已送出申请';

  @override
  String get group_join_request_title => '申请加入';

  @override
  String get group_join_request_message_label => '消息（选填）';

  @override
  String get group_join_request_message_hint => '您如何修持，或是谁邀请您的？';

  @override
  String get group_join_request_send => '送出申请';

  @override
  String get group_join_request_sent_snackbar => '已送出申请。管理员将进行审核';

  @override
  String get group_join_request_error => '无法送出申请，请再试一次';

  @override
  String get group_join_requests_title => '加入申请';

  @override
  String get group_join_requests_admit => '接受';

  @override
  String get group_join_requests_deny => '拒绝';

  @override
  String get group_join_requests_empty => '没有待审核的申请';

  @override
  String get group_join_requests_load_error => '无法加载加入申请，请再试一次';

  @override
  String get group_join_requests_admit_error => '无法接受此申请，请再试一次';

  @override
  String get group_join_requests_deny_error => '无法拒绝此申请，请再试一次';

  @override
  String get group_reports_title => '检举';

  @override
  String get group_reports_section_posts => '贴文';

  @override
  String get group_reports_section_comments => '留言';

  @override
  String get group_reports_section_messages => '消息';

  @override
  String group_reports_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 则检举',
    );
    return '$_temp0';
  }

  @override
  String get group_reports_view_post => '查看贴文';

  @override
  String get group_reports_view_message => '查看消息';

  @override
  String get group_reports_delete_post => '删除贴文';

  @override
  String get group_reports_delete_comment => '删除留言';

  @override
  String get group_reports_delete_message => '删除消息';

  @override
  String get group_reports_empty => '没有待审核的检举';

  @override
  String get group_reports_load_error => '无法加载检举，请再试一次。';

  @override
  String get group_reports_delete_confirm_title => '你确定吗？';

  @override
  String get group_reports_delete_message_confirm => '这则消息将被永久删除。';

  @override
  String get group_reports_message_removed => '消息已移除';

  @override
  String get group_reports_delete_message_error => '无法删除消息，请再试一次。';

  @override
  String get group_members_only_title => '仅限成员';

  @override
  String get group_members_only_message => '加入此社群即可查看内容';

  @override
  String get group_join_request_waiting_title => '等待管理员审核';

  @override
  String get group_join_request_waiting_message => '申请审核完成后，我们会通知您';

  @override
  String get group_members_load_error => '无法加载成员，请再试一次';

  @override
  String get group_followers_load_error => '无法加载追踪者，请再试一次。';

  @override
  String get group_members_empty => '尚无成员';

  @override
  String get group_member_admin => '管理员';

  @override
  String get group_member_owner => '拥有者';

  @override
  String group_remove_member(String name) {
    return '移除 $name';
  }

  @override
  String get group_remove_member_title => '要从社群中移除吗？';

  @override
  String group_remove_member_message(String name) {
    return '$name 将被移出此社群，且在禁令解除前无法重新加入';
  }

  @override
  String get group_remove_member_blocked_for => '封锁期间：';

  @override
  String get group_remove_member_duration_day => '1 天';

  @override
  String group_remove_member_duration_days(int count) {
    return '$count 天';
  }

  @override
  String get group_remove_member_duration_year => '1 年';

  @override
  String get group_remove_member_reason_label => '原因（选填）';

  @override
  String get group_remove_member_reason_hint => '其他...';

  @override
  String get group_remove_member_action => '移除';

  @override
  String group_remove_member_success(String name) {
    return '已将 $name 移出社群';
  }

  @override
  String get group_remove_member_error => '无法移除此成员，请再试一次';

  @override
  String group_join_banned_until(String date) {
    return '您已被移出此社群，在 $date 之前无法重新加入';
  }

  @override
  String get group_join_banned => '您已被移出此社群，在禁令解除前无法重新加入';

  @override
  String get group_removed_title => '您已被移出此社群';

  @override
  String group_removed_message(String group, String duration) {
    return '$group 的管理员已将您移出此社群。您将无法查看其中的贴文、活动和修持，也无法在 $duration 内要求重新加入。';
  }

  @override
  String group_removed_message_no_date(String group) {
    return '$group 的管理员已将您移出此社群。您将无法查看其中的贴文、活动和修持，也无法要求重新加入';
  }

  @override
  String get group_removed_rejoin_label => '您可以在以下日期申请加入此社群';

  @override
  String group_removed_rejoin_value(String date, String remaining) {
    return '$date · $remaining';
  }

  @override
  String get group_removed_day_left => '剩 1 天';

  @override
  String group_removed_days_left(int count) {
    return '剩 $count 天';
  }

  @override
  String get group_removed_last_day => '剩不到一天';

  @override
  String get group_followers_empty => '尚无追踪者';

  @override
  String get group_follower => '位追踪者';

  @override
  String get group_followers => '位追踪者';

  @override
  String get group_links_title => '链接';

  @override
  String get group_about_description => '社群介绍';

  @override
  String get group_about_empty => '尚无相关信息';

  @override
  String group_and_more_links(int count) {
    return '及另外 $count 个链接';
  }

  @override
  String get group_practice_with_us => '与我们一起修行';

  @override
  String series_practicing_with_group(String groupName) {
    return '与 $groupName 一起修行';
  }

  @override
  String get group_change_practice_title => '更换修持社群';

  @override
  String get group_change_practice_message => '您目前已在另一个社群修持此计划。您想更换修持社群吗？';

  @override
  String get group_join_to_contribute => '加入以参与计数';

  @override
  String get group_accumulator_join_error => '无法加入计数统计，请再试一次';

  @override
  String get group_accumulator_join_before_practice => '先加入本共修计数活动，再将它加入您的修持计划';

  @override
  String group_accumulator_participants(int count) {
    return '$count 位参与者';
  }

  @override
  String get group_accumulator_leaderboard => '排行榜';

  @override
  String get group_accumulator_my_contributions => '我的贡献';

  @override
  String get group_accumulator_recited => '已持诵';

  @override
  String get group_accumulator_total => '总数';

  @override
  String get group_accumulator_contributions_empty => '加入共修计数以追踪您的贡献';

  @override
  String get group_accumulator_leaderboard_empty => '尚无持诵纪录';

  @override
  String get group_accumulator_recite_now => '立即持诵';

  @override
  String get group_accumulator_view_practice => '查看修持';

  @override
  String get group_accumulator_chant_again => '再次持诵';

  @override
  String get group_accumulator_finish_session => '结束此次持诵';

  @override
  String get group_accumulator_offline_recitation => '线下持诵';

  @override
  String get group_accumulator_add_offline_chants_title => '添加离线持诵次数：';

  @override
  String get group_accumulator_add_offline_chants_message =>
      '添加您在此应用程序之外完成的持诵次数';

  @override
  String get group_accumulator_session_complete => '课诵完成！';

  @override
  String group_accumulator_session_recitations(int count) {
    return '您这次完成了 $count 遍';
  }

  @override
  String group_accumulator_session_share_message(
    int count,
    String accumulation,
    String group,
  ) {
    return '我在 WeBuddhist 上 $group 社群的共修计数「$accumulation」中完成了 $count 遍持诵，快来加入我吧！';
  }

  @override
  String group_accumulator_session_share_message_no_group(
    int count,
    String accumulation,
  ) {
    return '我在 WeBuddhist 上的共修计数活动「$accumulation」中完成了 $count 遍的持诵，快来加入我吧！';
  }

  @override
  String get group_accumulator_session_share_error => '无法分享课诵，请重试';

  @override
  String group_recitation_collection_share_message(
    String collection,
    String group,
  ) {
    return '来看看 WeBuddhist 上 $group 社群的持诵集「$collection」。和我们一起修持吧！';
  }

  @override
  String group_recitation_collection_share_message_no_group(String collection) {
    return '来看看 WeBuddhist 上的持诵集「$collection」。和我们一起修持吧！';
  }

  @override
  String group_recitation_collection_completed_title(String collection) {
    return '已完成「$collection」';
  }

  @override
  String get group_recitation_collection_dedication => '愿以此功德，令一切众生\n远离痛苦';

  @override
  String get share_this_quote => '分享这句话';

  @override
  String get shared_from => '分享自';

  @override
  String get verse_share_error => '无法分享引文，请再试一次';

  @override
  String verse_comments_title(int count) {
    return '评论 · $count';
  }

  @override
  String verse_likes_title(int count) {
    return '点赞 · $count';
  }

  @override
  String get verse_like_failed => '无法更新点赞，请再试一次';

  @override
  String get verse_comment_failed => '无法发表评论，请再试一次';

  @override
  String verse_comment_replying_to(String name) {
    return '回复 $name';
  }

  @override
  String get share_app_message => '我一直在用这个应用程序培养每日佛法修持的习惯，觉得您也会喜欢。';

  @override
  String get share_streak_message =>
      '我一直在养成每日修持的好习惯，想和您分享。有朋友一起坚持会更容易。来 WeBuddhist 和我一起吧。';

  @override
  String get share_chant_message =>
      '我想和您分享这段持诵。您可以在 WeBuddhist 上修持它，还能找到完整的持诵与经典文库。';

  @override
  String get share_quote_message =>
      '我喜欢 WeBuddhist 上的这段引文，想和您分享。在 WeBuddhist 应用程序上阅读更多富有洞见的引文。';

  @override
  String get share_poem_message => '我喜欢WeBuddhist上的这首诗，想和你分享。';

  @override
  String share_poem_title(String title) {
    return '「$title」';
  }

  @override
  String get share_mala_message =>
      '我一直在 WeBuddhist 上使用这串电子念珠，想和您分享。这是随时随地修持的便利方式。';

  @override
  String get share_passage_message =>
      '我喜欢这段经文，想和您分享。您可以在 WeBuddhist 上阅读完整的上下文。';

  @override
  String get share_timer_message =>
      '我想和您分享 WeBuddhist 上的这个禅修计时器。它让创建禅修习惯变得更轻松。';

  @override
  String get share_plan_message =>
      '我正在跟随这个佛法修持计划，想和您分享。您可以在 WeBuddhist 上免费和我一起修持。';

  @override
  String get share_plan_subject => '在WeBuddhist上和我一起吧';

  @override
  String get share_group_invite_message => '来这个社群和我一起吧。让我们在 WeBuddhist 上一起修持！';

  @override
  String get weekday_monday => '周一';

  @override
  String get weekday_tuesday => '周二';

  @override
  String get weekday_wednesday => '周三';

  @override
  String get weekday_thursday => '周四';

  @override
  String get weekday_friday => '周五';

  @override
  String get weekday_saturday => '周六';

  @override
  String get weekday_sunday => '周日';

  @override
  String get reader_search_failed => '搜索失败。\n请重试';

  @override
  String get reader_swipe_up_for_more => '向上滑动查看更多';

  @override
  String get reader_videos => '视频';

  @override
  String get mala_no_mantras => '暂无咒语';

  @override
  String get mala_count_load_error => '无法加载您的计数';

  @override
  String get bookmarks_empty_all_title => '尚无书签';

  @override
  String get bookmarks_empty_all_subtitle => '加入书签，即可将任何内容保存于此。';

  @override
  String get bookmarks_empty_plans_title => '尚无加入书签的修持计划';

  @override
  String get bookmarks_empty_plans_subtitle => '将修持计划加入书签，即可收藏于此';

  @override
  String get bookmarks_empty_malas_title => '尚无加入书签的念珠';

  @override
  String get bookmarks_empty_malas_subtitle => '将念珠加入书签，即可收藏于此';

  @override
  String get bookmarks_empty_group_accumulations_title => '尚无加入书签的共修计数';

  @override
  String get bookmarks_empty_group_accumulations_subtitle => '将共修计数加入书签，即可收藏于此';

  @override
  String get bookmarks_empty_timers_title => '尚无加入书签的计时器';

  @override
  String get bookmarks_empty_timers_subtitle => '将计时器加入书签，即可收藏于此';

  @override
  String get bookmarks_empty_texts_title => '尚无加入书签的文本';

  @override
  String get bookmarks_empty_texts_subtitle => '将文本加入书签，即可收藏于此';

  @override
  String get bookmark_removed => '已移除书签';

  @override
  String get bookmark_remove_failed => '无法移除书签';

  @override
  String get bookmark_saved => '书签已保存';

  @override
  String get bookmark_save_failed => '无法保存书签';

  @override
  String get bookmarks_yesterday => '昨天';

  @override
  String get webview_timeout_error => '页面加载时间过长。请检查您的网络连接';

  @override
  String get webview_load_failed => '无法加载页面';

  @override
  String get privacy_policy_load_error => '无法加载隐私政策页面';

  @override
  String get terms_of_service_load_error => '无法加载服务条款页面';

  @override
  String get series_enroll_error => '无法加入系列';

  @override
  String series_share_message(String title, String url) {
    return '和我一起在 WeBuddhist 上修习 $title。\n\n$url';
  }

  @override
  String get player_back_10 => '后退 10 秒';

  @override
  String get player_pause => '暂停';

  @override
  String get player_play => '播放';

  @override
  String get player_forward_10 => '快进 10 秒';

  @override
  String get player_fullscreen => '全屏幕';

  @override
  String get player_exit_fullscreen => '退出全屏幕';

  @override
  String get session_plans_load_error => '无法加载计划。\n请稍后再试';

  @override
  String get session_chants_load_error => '无法加载课诵';

  @override
  String get session_no_chants => '未找到课诵';

  @override
  String get session_malas_load_error => '无法加载念珠';

  @override
  String get session_no_malas => '未找到念珠';

  @override
  String get session_timers_load_error => '无法加载计时器';

  @override
  String get session_no_timers => '未找到计时器';

  @override
  String days_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天',
    );
    return '$_temp0';
  }

  @override
  String timer_minute_session(int minutes) {
    return '$minutes 分钟练习';
  }

  @override
  String get timer_notification_in_progress => '禅修进行中';

  @override
  String timer_notification_paused(String time) {
    return '已暂停 · 剩余 $time';
  }

  @override
  String get timer_notification_complete => '你的课程已完成';

  @override
  String plan_day_of(int day, int total) {
    return '第 $day 天，共 $total 天';
  }

  @override
  String pagination_position(int current, int total) {
    return '$current / $total';
  }

  @override
  String get plan_shorts_title => '社群短片';

  @override
  String get author_details_load_error => '无法加载作者资料\n请重试';

  @override
  String get link_cannot_open => '无法打开此链接';

  @override
  String get link_invalid => '无效的网址';

  @override
  String get author_no_plans => '尚未创建修持计划';

  @override
  String get author_plans_load_error => '无法加载修持计划';

  @override
  String get drag_to_resize => '拖动以调整大小';

  @override
  String get day_completion_share_message =>
      '我刚在 WeBuddhist 上完成了今天的修持。加入我，一起培养每日修持的好习惯。';

  @override
  String group_accumulator_share_message(String accumulation, String group) {
    return '我正在参加 WeBuddhist 上 $group 社群的共修计数「$accumulation」，快来加入我吧！';
  }

  @override
  String group_accumulator_share_message_no_group(String accumulation) {
    return '我正在参加 WeBuddhist 上的共修计数「$accumulation」，快来加入我吧！';
  }

  @override
  String get chats_title => '聊天室';

  @override
  String get chats_empty_title => '尚无聊天室';

  @override
  String get chats_empty_body => '加入共修空间，即可开始聊天';

  @override
  String get group_chat_inappropriate => '此消息包含不允许的用语，因此无法发送';

  @override
  String get group_chat_not_a_member => '只有成员可以打开此聊天室';

  @override
  String get group_chat_open => '聊天';

  @override
  String get group_chat_message_hint => '消息';

  @override
  String get group_chat_today => '今天';

  @override
  String get group_chat_yesterday => '昨天';

  @override
  String get group_chat_empty_title => '尚无消息';

  @override
  String get group_chat_empty_body => '和您的社群开始聊天吧';

  @override
  String get group_chat_load_failed => '无法加载消息';

  @override
  String get group_chat_message_not_found => '此消息已不在聊天中';

  @override
  String get group_chat_message_too_far_back => '这则消息在聊天记录中较早的位置';

  @override
  String get group_chat_keep_looking => '继续查找';

  @override
  String get group_chat_retry => '重试';

  @override
  String get group_chat_unknown_sender => '成员';

  @override
  String get group_chat_reactions_all => '全部';

  @override
  String get group_chat_reacted => '已回应';

  @override
  String get group_chat_reply => '回复';

  @override
  String get group_chat_copy => '复制';

  @override
  String get group_chat_copied => '消息已复制';

  @override
  String get group_chat_report => '检举';

  @override
  String get group_chat_report_title => '您为什么要检举此内容？';

  @override
  String get group_chat_report_privacy => '您的姓名将保密';

  @override
  String get group_chat_report_reason_harassment => '骚扰或霸凌';

  @override
  String get group_chat_report_reason_hate => '仇恨或有害言论';

  @override
  String get group_chat_report_reason_sexual => '色情或露骨内容';

  @override
  String get group_chat_report_reason_spam => '垃圾消息或诈骗';

  @override
  String get group_chat_report_reason_off_topic => '离题或干扰';

  @override
  String get group_chat_report_reason_other => '其他';

  @override
  String get group_chat_report_note_title => '添加备注';

  @override
  String get group_chat_report_note_hint => '其他...';

  @override
  String get group_chat_report_submit => '送出检举';

  @override
  String get group_chat_report_thanks => '感谢您的回馈';

  @override
  String get group_chat_report_offline => '您目前离线。请稍后再试';

  @override
  String get group_chat_report_failed => '无法送出检举';

  @override
  String get group_chat_report_retry => '重试';

  @override
  String get group_chat_delete => '删除';

  @override
  String get group_chat_delete_title => '要删除消息吗？';

  @override
  String group_chat_delete_title_many(int count) {
    return '要删除 $count 则消息吗？';
  }

  @override
  String group_chat_delete_confirm_body(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '这些消息将从聊天室中对所有人移除',
      one: '此消息将从聊天室中对所有人移除',
    );
    return '$_temp0';
  }

  @override
  String group_chat_delete_failed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '无法删除 $count 则消息',
      one: '无法删除消息',
    );
    return '$_temp0';
  }

  @override
  String group_chat_selection_limit(int count) {
    return '最多可选取 $count 则消息';
  }

  @override
  String get group_chat_message_deleted_by_sender => '此消息已被删除';

  @override
  String get group_chat_reaction_failed => '无法保存您的回应';

  @override
  String group_chat_reactions_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个回应',
      one: '1 个回应',
    );
    return '$_temp0';
  }

  @override
  String get group_chat_you => '您';

  @override
  String get group_chat_tap_to_remove => '点一下即可移除';

  @override
  String get group_chat_reply_parent_gone => '该消息已无法使用，因此已移除引用。请重新发送以发布您的消息';

  @override
  String get group_tab_posts => '贴文';

  @override
  String get group_tab_events => '活动';

  @override
  String get group_posts_empty_title => '尚无贴文';

  @override
  String get group_posts_empty_message => '分享您社群的第一则动态';

  @override
  String get group_posts_load_error => '无法加载贴文，请再试一次';

  @override
  String get group_post_button => '发布';

  @override
  String get group_post_new_title => '新贴文';

  @override
  String get group_post_posting_to => '发布至：';

  @override
  String get group_post_caption_hint => '有什么新消息？';

  @override
  String get group_post_photos => '相片';

  @override
  String get group_post_link => '链接';

  @override
  String get group_post_discard_title => '要舍弃贴文吗？';

  @override
  String get group_post_discard_message => '您撰写的内容将会遗失';

  @override
  String get group_post_keep_editing => '继续编辑';

  @override
  String get group_post_discard => '舍弃';

  @override
  String get group_post_add_link_title => '添加链接';

  @override
  String get group_post_add_link_hint => '粘贴链接，我们会显示预览';

  @override
  String get group_post_link_field_hint => '链接';

  @override
  String get group_post_attach => '附加';

  @override
  String get group_post_attach_as_link => '以链接形式附加';

  @override
  String get group_post_preview_failed_title => '无法加载预览';

  @override
  String get group_post_preview_failed_message => '您仍可以链接形式附加';

  @override
  String get group_post_invalid_link => '请输入有效的链接，例如：https://example.com';

  @override
  String get group_post_in_app_content => '应用内内容';

  @override
  String get group_post_add_in_app_content_title => '添加应用内内容';

  @override
  String get group_post_in_app_content_empty => '暂无可添加的内容';

  @override
  String group_post_photo_limit(int count) {
    return '最多可添加 $count 张相片';
  }

  @override
  String get group_post_upload_error => '无法上传相片，请再试一次';

  @override
  String get group_post_publish_error => '无法发布您的贴文，请再试一次';

  @override
  String get group_post_published => '您的贴文已发布。';

  @override
  String get group_post_delete_title => '要删除贴文吗？';

  @override
  String get group_post_delete_message => '此贴文将被永久删除';

  @override
  String get group_post_delete_failed => '无法删除贴文，请再试一次';

  @override
  String get edit => '编辑';

  @override
  String get group_post_edit_title => '编辑贴文';

  @override
  String get group_post_update_error => '无法保存您的变更，请再试一次';

  @override
  String get group_post_updated => '您的变更已保存';

  @override
  String get practice_collection_already_added => '此持诵集已在您的修持中';

  @override
  String get practice_group_accumulator_already_added => '此共修计数已在您的修持中';

  @override
  String get event_live_badge => '直播中';

  @override
  String get event_live_video_mode => '视频';

  @override
  String get event_live_audio_mode => '音频';

  @override
  String get event_live_go_live => '直播中';

  @override
  String get event_replays => '回放';

  @override
  String event_replay_session(String day, String session) {
    return '第 $day 天 · 第 $session 场';
  }

  @override
  String get event_replay_recording => '录像';

  @override
  String get event_replay_back_to_live => '返回直播';

  @override
  String get event_replays_empty => '尚无录像';

  @override
  String get event_puja_starts_in => '法会开始于';

  @override
  String get event_puja_not_started => '法会尚未开始';

  @override
  String get event_prayer_requests => '回向与祈愿';

  @override
  String event_prayer_request_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      one: '1 个回向祈愿',
      other: '$count 个回向祈愿',
    );
    return '$_temp0';
  }

  @override
  String get event_prayer_empty_title => '尚无回向祈愿名单';

  @override
  String get event_prayer_empty_body => '您的回向祈愿与您社群的回向祈愿会出现在这里';

  @override
  String get event_prayer_add => '加入回向名单';

  @override
  String get event_prayer_hint => '今天我们可以为您祈愿什么呢？';

  @override
  String event_prayer_hint_intention(String topics) {
    return '请求为以下事项祈愿：$topics';
  }

  @override
  String get event_prayer_load_failed => '无法加载回向祈愿';

  @override
  String get event_prayer_closed => '本活动的回向名单已关闭';

  @override
  String get event_prayer_pray => '回向祈愿';

  @override
  String event_prayer_my_count(int count) {
    return '+$count';
  }

  @override
  String get event_prayer_new_request => '添加回向祈愿';

  @override
  String get event_prayer_edit_request => '编辑回向祈愿内容';

  @override
  String get event_prayer_delete_title => '要删除此回向祈愿?';

  @override
  String get event_prayer_delete_body => '此则回向祈愿将从本活动删除';

  @override
  String get event_prayer_delete_failed => '无法删除此回向祈愿';

  @override
  String get event_prayer_choose_intention => '选择一种愿望';

  @override
  String get event_prayer_intentions_failed => '无法加载祈愿意向';

  @override
  String get event_prayer_request_button => '申请回向祈愿';

  @override
  String get event_prayer_you => '你';

  @override
  String get event_prayer_waiting_first => '正在等待第一个回向祈愿⋯⋯';

  @override
  String event_prayer_more_praying(int count) {
    return '+$count 人已回向';
  }

  @override
  String event_prayer_people_praying(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 人已回向',
      one: '1 人已回向',
    );
    return '$_temp0';
  }

  @override
  String get event_prayer_praying_for_you => '已为您回向';

  @override
  String get event_prayer_your_request => '您的回向祈愿';

  @override
  String get event_prayer_supporters_failed => '无法加载正在回向祈愿的人';

  @override
  String get event_prayer_no_supporters => '目前还没有人回向';

  @override
  String get event_prayer_sort_by => '为谁祈愿';

  @override
  String get event_prayer_sort_needs_prayers => '需要祈愿';

  @override
  String get event_prayer_sort_most_prayed => '祈愿最多';

  @override
  String get event_prayer_sort_newest => '最新';

  @override
  String get event_prayer_sort_oldest => '最早';

  @override
  String get event_prayer_sort_by_intention => '按祈愿意向';

  @override
  String get event_prayer_clear_intention => '清除祈愿意向';

  @override
  String get event_prayer_filter_empty_title => '没有符合的请求';

  @override
  String get event_prayer_filter_empty_body => '请尝试其他排序或祈愿意向';

  @override
  String get event_prayer_see_translation => '查看译文';

  @override
  String get event_prayer_see_original => '查看原文';

  @override
  String event_prayer_translated_from(String language) {
    return '译自$language';
  }

  @override
  String get event_prayer_translated => '已翻译';

  @override
  String get recitation_live_sync => '同步';

  @override
  String get recitation_live_label => '直播中';

  @override
  String get recitation_live_session_ended => '直播已结束';

  @override
  String get feedback_add_image => '添加图片';

  @override
  String feedback_image_limit(int count) {
    return '最多可附加 $count 张图片';
  }

  @override
  String get feedback_send => '发送';

  @override
  String get feedback_error_offline => '您目前离线。请稍后再试';

  @override
  String get feedback_error_rate_limited => '请求次数过多。请稍候再试';

  @override
  String get feedback_error_too_large => '图片太大。请移除一张后再试';

  @override
  String get feedback_error_failed => '无法送出意见回馈，请再试一次';

  @override
  String get feedback_error_unavailable => '目前无法使用意见回馈';

  @override
  String get settings_help_contact_row => '协助与联系';

  @override
  String get help_contact_title => '协助与联系';

  @override
  String get help_contact_intro => '回报问题、分享想法，或提供协助与合作。我们会阅读每一则消息。';

  @override
  String get help_contact_message => '消息';

  @override
  String get help_contact_photos => '照片或屏幕截屏（选填）';

  @override
  String get help_contact_topic => '这是关于什么？（选填）';

  @override
  String get help_contact_hint_default => '您想告诉我们什么？';

  @override
  String get help_contact_hint_report_problem => '发生了什么事？您在那之前正在做什么？附上截屏会很有帮助。';

  @override
  String get help_contact_hint_idea_feedback => '怎样能让 WeBuddhist 对您的修行更有帮助？';

  @override
  String get help_contact_hint_suggest_content => '您希望在这里看到哪些教法、经文或老师？欢迎附上链接。';

  @override
  String get help_contact_hint_help_collaborate =>
      '您想如何协助？请分享您的技能、语言能力，或能提供的时间。';

  @override
  String get help_topic_report_problem => '回报问题';

  @override
  String get help_topic_idea_feedback => '想法或意见';

  @override
  String get help_topic_suggest_content => '建议内容';

  @override
  String get help_topic_help_collaborate => '协助或合作';

  @override
  String get help_contact_footer => '回复会由 WeBuddhist 团队发送到您的聊天室。';

  @override
  String get help_contact_sent_title => '消息已送出';

  @override
  String get help_contact_sent_body =>
      '谢谢。我们通常会在 1 天内回复。您可以在聊天室中看到 WeBuddhist 团队的回复。';

  @override
  String help_contact_sent_body_named(String name) {
    return '谢谢，$name。我们通常会在 1 天内回复。您可以在聊天室中看到 WeBuddhist 团队的回复。';
  }

  @override
  String get help_contact_your_request => '您的请求';

  @override
  String get help_contact_open_chat => '打开聊天室';

  @override
  String get help_context_sent_from => '来自协助与联系';

  @override
  String help_context_photos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张照片',
    );
    return '$_temp0';
  }

  @override
  String get chat_official_badge => '官方';

  @override
  String get chat_team_reply_time => '通常在 1 天内回复';

  @override
  String get connect_failed_load_discover_groups_error => '无法下载社群清单';

  @override
  String get connect_failed_like_post_error => '无法帮贴文点赞';

  @override
  String get connect_failed_unlike_post_error => '无法删除贴文点赞';

  @override
  String get group_events_load_error => '无法加载活动，请再试一次。';

  @override
  String get group_events_empty => '暂无活动';

  @override
  String get group_events_empty_message => '创建您的第一场聚会，成员将会收到通知。';

  @override
  String get group_event_create_button => '创建活动';

  @override
  String get group_event_new_title => '新活动';

  @override
  String group_event_step_of(int current, int total) {
    return '第 $current 步，共 $total 步';
  }

  @override
  String get group_event_step_about => '简介';

  @override
  String get group_event_cover_image => '封面图片';

  @override
  String get group_event_add_cover_photo => '添加封面照片';

  @override
  String get group_event_change_cover => '更换';

  @override
  String get group_event_name_and_description => '名称与描述';

  @override
  String get group_event_name_label => '活动名称';

  @override
  String get group_event_name_hint => '例如：周三共修';

  @override
  String get group_event_description_label => '描述（可选）';

  @override
  String get group_event_description_hint => '你们将一起修持什么？需要带些什么吗？';

  @override
  String get group_event_write => '编辑';

  @override
  String get group_event_preview => '预览';

  @override
  String get group_event_preview_empty => '暂无可预览的内容';

  @override
  String get group_event_continue => '继续';

  @override
  String get group_event_name_required_hint => '请添加活动名称以继续';

  @override
  String get group_event_languages_title => '活动语言';

  @override
  String get group_event_languages_add => '添加语言';

  @override
  String get group_event_languages_hint =>
      '已根据您社群的语言预先选择。若有对应语言版本，读者将以其语言查看此活动。';

  @override
  String get group_event_discard_title => '要放弃此活动吗？';

  @override
  String get group_event_discard_message => '您输入的内容将会丢失';

  @override
  String get group_event_format_bold => '粗体';

  @override
  String get group_event_format_italic => '斜体';

  @override
  String get group_event_format_heading => '标题';

  @override
  String get group_event_format_bullet_list => '项目符号列表';

  @override
  String get group_event_format_numbered_list => '编号列表';

  @override
  String get group_event_format_link => '链接';

  @override
  String get group_event_link_title => '插入链接';

  @override
  String get group_event_link_text_hint => '文字';

  @override
  String get group_event_link_url_hint => 'https://';

  @override
  String get group_event_link_insert => '插入';

  @override
  String get group_event_step_when_where => '时间与地点';

  @override
  String get group_event_when => '时间';

  @override
  String get group_event_where => '地点';

  @override
  String get group_event_one_time => '单次';

  @override
  String get group_event_recurring => '重复';

  @override
  String get group_event_date => '日期';

  @override
  String get group_event_start_date => '开始日期';

  @override
  String get group_event_end_date => '结束日期';

  @override
  String get group_event_first_date => '首次日期';

  @override
  String get group_event_choose_date => '选择日期';

  @override
  String get group_event_multi_day => '多日活动';

  @override
  String get group_event_all_day => '全天';

  @override
  String get group_event_all_day_hint => '在活动页面上显示为全天。';

  @override
  String get group_event_start_time => '开始时间';

  @override
  String get group_event_end_time => '结束时间';

  @override
  String get group_event_add_start_time => '添加开始时间';

  @override
  String get group_event_add_end_time => '添加结束时间';

  @override
  String group_event_time_starts(String time) {
    return '$time 开始';
  }

  @override
  String group_event_time_ends(String time) {
    return '$time 结束';
  }

  @override
  String get group_event_timezone => '时区';

  @override
  String get group_event_repeats => '重复';

  @override
  String get group_event_choose_repeats => '选择重复方式';

  @override
  String get group_event_duration => '时长';

  @override
  String get group_event_duration_decrease => '减少时长';

  @override
  String get group_event_duration_increase => '增加时长';

  @override
  String group_event_duration_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天',
      one: '1 天',
    );
    return '$_temp0';
  }

  @override
  String group_event_repeats_weekly(String weekday) {
    return '每周$weekday';
  }

  @override
  String group_event_repeats_monthly(String day) {
    return '每月 $day 日';
  }

  @override
  String group_event_repeats_monthly_lunar(String day) {
    return '每月藏历 $day 日';
  }

  @override
  String group_event_repeats_yearly(String date) {
    return '每年 $date';
  }

  @override
  String get group_event_repeats_yearly_lunar => '每年此藏历日期';

  @override
  String get group_event_full_moon => '满月';

  @override
  String get group_event_new_moon => '新月';

  @override
  String get group_event_gregorian => '公历';

  @override
  String get group_event_tibetan_lunar => '藏历';

  @override
  String get group_event_next_dates => '接下来的日期';

  @override
  String get group_event_repeats_hint => '选项根据首次日期而定。';

  @override
  String get group_event_in_person => '现场';

  @override
  String get group_event_live => '直播';

  @override
  String get group_event_both => '两者皆有';

  @override
  String get group_event_venue => '场地';

  @override
  String get group_event_add_venue => '添加场地位置';

  @override
  String get group_event_venue_search_hint => '搜索区域、街道或地标';

  @override
  String get group_event_venue_no_results => '未找到地点';

  @override
  String get group_event_venue_search_error => '搜索功能目前无法使用';

  @override
  String get group_event_drop_pin => '放置图钉';

  @override
  String get group_event_drop_pin_hint => '在地图上选择位置';

  @override
  String get group_event_pin_marker => '活动场地';

  @override
  String get group_event_selected_location => '已选位置';

  @override
  String get group_event_pin_unnamed => '已标记的位置';

  @override
  String get group_event_confirm_location => '确认位置';

  @override
  String get group_event_name_location => '为此位置命名';

  @override
  String get group_event_venue_name => '场地名称';

  @override
  String get group_event_venue_name_hint => '例如：金刚萨埵佛法中心';

  @override
  String get group_event_save_venue => '保存场地';

  @override
  String get group_event_live_link => '直播链接';

  @override
  String get group_event_live_link_hint => 'youtube.com/… 或会议链接';

  @override
  String get group_event_use_channel_link => '使用频道链接';

  @override
  String get group_event_live_link_youtube_help =>
      '您社群的 YouTube 直播，会在 WeBuddhist 内播放。粘贴其他链接即可更换。';

  @override
  String get group_event_live_link_custom_help => '自定义链接，观众将在 WeBuddhist 之外打开。';

  @override
  String get group_event_live_link_invalid => '这看起来还不是有效的链接';

  @override
  String get group_event_pick_date_hint => '请选择日期以继续';

  @override
  String get group_event_pick_repeats_hint => '请选择重复方式以继续';

  @override
  String get group_event_end_date_hint => '结束日期必须晚于开始日期';

  @override
  String get group_event_end_time_hint => '结束时间必须晚于开始时间';

  @override
  String get group_event_venue_hint => '请选择场地以继续';

  @override
  String get group_event_link_required_hint => '请添加会议链接以继续';

  @override
  String get group_event_map_attribution => '© OpenStreetMap 贡献者';

  @override
  String get group_event_step_practices => '修持与视频';

  @override
  String get group_event_optional_note => '此处所有内容均为可选，您可以稍后再添加这些详情。';

  @override
  String get group_event_practices_section => '活动修持';

  @override
  String get group_event_add_practice => '添加修持';

  @override
  String get group_event_practice_search_hint => '搜索您社群的修持';

  @override
  String get group_event_practice_filter_all => '全部';

  @override
  String get group_event_practice_filter_content => '计划与系列';

  @override
  String get group_event_practice_filter_collections => '持诵集';

  @override
  String get group_event_practice_filter_accumulators => '共修计数';

  @override
  String get group_event_practice_rule => '每个活动可包含一个计划或系列及一个持诵集，共修计数则可按需添加。';

  @override
  String group_event_practice_replaced(String chosen, String previous) {
    return '已选择「$chosen」，替换了「$previous」。';
  }

  @override
  String get group_event_practices_empty => '此社群尚无修持';

  @override
  String get group_event_practices_load_error => '无法加载修持，请再试一次。';

  @override
  String get group_event_practices_none_match => '没有符合的修持';

  @override
  String group_event_add_practices_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '添加 $count 项修持',
      one: '添加 1 项修持',
      zero: '添加修持',
    );
    return '$_temp0';
  }

  @override
  String get group_event_counted_by => '计数方式';

  @override
  String get group_event_count_mode_title => '由谁添加计数？';

  @override
  String get group_event_count_mode_attendees => '参加者在应用内添加';

  @override
  String get group_event_count_mode_attendees_hint => '每人在活动期间或结束后添加自己的持诵次数';

  @override
  String get group_event_count_mode_admin => '管理员为现场参加者添加';

  @override
  String get group_event_count_mode_admin_hint => '由您输入团体的计数，即人数 × 遍数';

  @override
  String get group_event_count_mode_admin_short => '管理员添加';

  @override
  String get group_event_count_mode_attendees_taken =>
      '另一个共修计数已使用此方式。每个活动中，参加者只能为一个共修计数添加次数。';

  @override
  String group_event_remove_practice(String title) {
    return '移除「$title」';
  }

  @override
  String get group_event_videos_section => '介绍视频';

  @override
  String get group_event_videos_hint => '显示在活动的简介页面上，可用来介绍活动或说明活动内容。';

  @override
  String get group_event_add_video => '添加视频';

  @override
  String get group_event_video_link => 'YouTube 链接';

  @override
  String get group_event_video_link_hint => 'https://youtu.be/…';

  @override
  String get group_event_paste => '粘贴';

  @override
  String get group_event_video_loading => '正在获取视频详情…';

  @override
  String get group_event_video_invalid =>
      '这看起来不是 YouTube 链接，请粘贴来自 YouTube 的链接。';

  @override
  String get group_event_video_source => 'YouTube';

  @override
  String get group_event_video_untitled => 'YouTube 视频';

  @override
  String get group_event_remove_video => '移除视频';

  @override
  String get group_event_skip => '跳过';

  @override
  String get group_event_step_review => '检查并发布';

  @override
  String get group_event_review_event => '活动';

  @override
  String get group_event_review_settings => '设置';

  @override
  String get group_event_review_name => '名称';

  @override
  String get group_event_review_languages => '语言';

  @override
  String get group_event_review_when => '时间';

  @override
  String get group_event_review_where => '地点';

  @override
  String get group_event_review_live_link => '直播链接';

  @override
  String get group_event_review_practices => '修持';

  @override
  String get group_event_review_videos => '介绍视频';

  @override
  String get group_event_review_event_settings => '活动设置';

  @override
  String get group_event_review_none => '无';

  @override
  String get group_event_review_tap_hint => '点按任意一行即可更改。';

  @override
  String get group_event_review_notify_hint => '发布后，成员将收到通知。';

  @override
  String group_event_review_more(String first, int count) {
    return '$first 等另外 $count 项';
  }

  @override
  String group_event_review_recurring_from(
    String rule,
    String times,
    String date,
  ) {
    return '$rule · $times · 自 $date 起';
  }

  @override
  String get group_event_review_youtube_live => 'YouTube 直播';

  @override
  String get group_event_review_online => '线上';

  @override
  String get group_event_chat_on => '聊天已开启';

  @override
  String get group_event_chat_off => '聊天已关闭';

  @override
  String get group_event_notifications_on => '通知已开启';

  @override
  String get group_event_notifications_off => '通知已关闭';

  @override
  String get group_event_all_intentions => '所有祈愿意向';

  @override
  String group_event_intentions_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 项祈愿意向',
      one: '1 项祈愿意向',
    );
    return '$_temp0';
  }

  @override
  String get group_event_publish => '发布';

  @override
  String get group_event_publish_error => '无法发布活动，请再试一次';

  @override
  String get group_event_settings_title => '活动设置';

  @override
  String get group_event_settings_chat => '活动聊天室';

  @override
  String get group_event_settings_chat_hint => '为活动开设专属聊天室，成员可在其中交流并发布回向与祈愿。';

  @override
  String get group_event_settings_notifications => '通知';

  @override
  String get group_event_settings_notifications_hint =>
      '包括发布时的通知、活动开始前的提醒，以及您自行发送的通知。';

  @override
  String get group_event_settings_intentions => '祈愿意向';

  @override
  String get group_event_settings_intentions_hint => '全部不勾选即允许所有祈愿意向。';

  @override
  String get group_event_settings_intentions_error => '目前无法加载祈愿意向。';

  @override
  String get group_event_published_title => '已发布';

  @override
  String group_event_published_headline(String name) {
    return '「$name」已上线';
  }

  @override
  String group_event_published_message(String group) {
    return '$group 的成员已收到通知。您可以随时在活动页面中进行编辑。';
  }

  @override
  String get group_event_published_message_silent => '您可以随时在活动页面中进行编辑。';

  @override
  String get group_event_view_event => '查看活动';

  @override
  String get group_event_drafts_section => '草稿';

  @override
  String get group_event_draft_label => '草稿';

  @override
  String get group_event_draft_untitled => '未命名活动';

  @override
  String get group_event_draft_menu_continue => '继续编辑';

  @override
  String get group_event_draft_menu_delete => '删除草稿';

  @override
  String get group_event_draft_menu_delete_hint => '此操作无法撤销';

  @override
  String get group_event_draft_saved => '已保存为草稿';

  @override
  String get group_event_draft_save_error => '无法保存草稿，请再试一次';

  @override
  String get group_event_draft_deleted => '草稿已删除';

  @override
  String get group_event_draft_delete_error => '无法删除草稿，请再试一次';

  @override
  String get group_event_draft_delete_title => '要删除草稿吗？';

  @override
  String get group_event_draft_delete_message => '此草稿将被永久删除';

  @override
  String get group_event_edit_draft_title => '编辑草稿';

  @override
  String get group_event_edit_title => '编辑活动';

  @override
  String get group_event_save_changes => '保存更改';

  @override
  String get group_event_changes_saved => '更改已保存';

  @override
  String get group_event_manage => '管理活动';

  @override
  String get group_event_manage_details => '详情';

  @override
  String get group_event_manage_counts => '计数';

  @override
  String get group_event_manage_accumulations => '共修计数';

  @override
  String get group_event_manage_admin_adds_pending => '管理员添加';

  @override
  String group_event_manage_admin_adds(String count) {
    return '管理员添加 · 目前 $count';
  }

  @override
  String get group_event_manage_attendees_add_pending => '参加者在应用内添加';

  @override
  String group_event_manage_attendees_add(String count, int people) {
    String _temp0 = intl.Intl.pluralLogic(
      people,
      locale: localeName,
      other: '参加者在应用内添加 · $people 人共 $count',
      one: '参加者在应用内添加 · 1 人共 $count',
    );
    return '$_temp0';
  }

  @override
  String get group_event_manage_add_count => '添加计数';

  @override
  String get group_event_manage_no_accumulations => '此活动没有共修计数。';

  @override
  String get group_event_manage_recurring_note => '重复活动不保留参加者名单，各场次的计数会累计相加。';

  @override
  String group_event_in_person_of_target(String count, String target) {
    return '$count / $target';
  }

  @override
  String group_event_in_person_in_total(String count) {
    return '共 $count';
  }

  @override
  String get group_event_in_person_legend_app => '应用';

  @override
  String get group_event_in_person_legend_in_person => '现场';

  @override
  String get group_event_in_person_add_day => '添加日期';

  @override
  String get group_event_in_person_day => '日期';

  @override
  String get group_event_in_person_count => '计数';

  @override
  String get group_event_in_person_empty => '暂无现场计数。';

  @override
  String get group_event_in_person_invalid_count => '请输入至少为 1 的整数';

  @override
  String get group_event_in_person_added => '已添加现场计数';

  @override
  String get group_event_in_person_updated => '已更新现场计数';

  @override
  String get group_event_in_person_deleted => '已删除现场计数';

  @override
  String get group_event_in_person_delete_title => '要删除现场计数吗？';

  @override
  String group_event_in_person_delete_message(String count, String day) {
    return '$day 的 $count 将从共修计数总数中扣除。';
  }

  @override
  String get group_event_in_person_exists => '该日期已有计数，请改为编辑。';

  @override
  String get group_event_in_person_no_accumulation =>
      '请为此活动关联一个社群共修计数，以记录现场计数。';

  @override
  String get group_event_in_person_save_error => '无法保存计数。';

  @override
  String get group_event_in_person_load_more => '加载更多';

  @override
  String get mala_failed_load_catalogue_error => '无法加载目录';

  @override
  String get chant_collection_reload_error => '无法重新加载持诵集以调整顺序';

  @override
  String get chant_collection_reorder_error => '无法调整持诵顺序';

  @override
  String get timer_duration_label => '时长';

  @override
  String get timer_ambient_sound_label => '环境音';

  @override
  String get timer_begin_session => '开始禅修';

  @override
  String get timer_save_changes => '保存更改';

  @override
  String get timer_new_title => '新计时器';

  @override
  String get timer_edit_title => '编辑计时器';

  @override
  String get timer_your_timers => '您的计时器';

  @override
  String get timer_ambient_sounds_title => '环境音';

  @override
  String get timer_ambient_sound_none => '默认（无声音）';

  @override
  String get timer_ambient_sounds_load_error => '无法加载环境音';

  @override
  String get timer_volume_label => '音量';

  @override
  String get timer_duration_title => '时长';

  @override
  String get timer_edit => '编辑计时器';

  @override
  String get timer_delete => '删除计时器';

  @override
  String get timer_delete_title => '要删除计时器吗？';

  @override
  String get timer_delete_message => '此计时器将从您的计时器中移除。';

  @override
  String get timer_duration_must_be_greater_than_error => '时长必须大于 0';

  @override
  String get splash_tagline_1 => '我们佛弟子一起修持';

  @override
  String get splash_tagline_2 => '我们佛弟子每日修持';

  @override
  String get timer_create_custom => '创建自定义计时器';

  @override
  String get timer_starting => '正在开始…';

  @override
  String get timer_duration_hours => '小时';

  @override
  String get timer_duration_sec => '秒';

  @override
  String get reader_display_title => '显示';

  @override
  String get text_size => '文字大小';

  @override
  String get reader_more_settings => '更多设置';

  @override
  String get reader_spacing => '间距';

  @override
  String get reader_spacing_compact => '紧凑';

  @override
  String get reader_spacing_normal => '标准';

  @override
  String get reader_spacing_relaxed => '宽松';

  @override
  String get reader_background => '背景';

  @override
  String get reader_background_rice_paper => '宣纸';

  @override
  String get reader_background_gold => '金色';

  @override
  String get reader_background_sky => '天蓝';

  @override
  String get reader_background_white => '白色';

  @override
  String get reader_background_plum => '梅紫';

  @override
  String get reader_background_temple_red => '寺院红';

  @override
  String get reader_background_robe_saffron => '袈裟橙';

  @override
  String get reader_in_the_text => '文中';

  @override
  String get reader_ritual_instructions => '仪轨说明';

  @override
  String get reader_verse_numbers => '偈颂编号';

  @override
  String get reader_change_languages => '更改语言';

  @override
  String get reader_live_paused => '已暂停';

  @override
  String get reader_text_smaller => '缩小文字';

  @override
  String get reader_text_larger => '放大文字';

  @override
  String reader_section_position(String current, String total) {
    return '第 $current / $total 节';
  }

  @override
  String reader_round_position(String current, String total) {
    return '第 $current / $total 轮';
  }

  @override
  String reader_round_number(String current) {
    return '第 $current 轮';
  }

  @override
  String reader_count_position(String current, String total) {
    return '$current / $total';
  }

  @override
  String reader_show_script_in(String language) {
    return '$language显示方式';
  }

  @override
  String reader_verse_label(String number) {
    return '偈颂 $number';
  }

  @override
  String get reader_tab_commentary => '注释';

  @override
  String get reader_tab_versions => '版本';
}

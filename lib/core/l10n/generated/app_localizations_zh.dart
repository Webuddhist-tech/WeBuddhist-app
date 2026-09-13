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
  String get onboarding_setup_subtitle => '讓我們為您設定，只需一分鐘';

  @override
  String get onboarding_tagline => '學習、修持、連結。每日。';

  @override
  String get onboarding_quote => '滴水穿石 ‧ 聚沙成塔';

  @override
  String get onboarding_find_peace => '立即開始';

  @override
  String get onboarding_continue => '下一步';

  @override
  String get onboarding_first_question => '選擇您的語言：';

  @override
  String get onboarding_choose_option => '至少選擇一項';

  @override
  String get onboarding_all_set => '一切就緒';

  @override
  String get onboarding_all_set_description => '以下是為您的修行準備的內容。';

  @override
  String get onboarding_all_set_feature_practices => '持咒、累積、禪修和學習計畫供您選擇';

  @override
  String get onboarding_all_set_feature_reminders => '溫和的日常提醒，隨時為您準備好';

  @override
  String get onboarding_begin_practice => '尋找您的第一項修持';

  @override
  String get onboarding_2_title => '接下來，看看它是如何運作的。';

  @override
  String get onboarding_2_subtitle => '養成習慣的三個小步驟';

  @override
  String get onboarding_2_step1_title => '選擇您的修持方式';

  @override
  String get onboarding_2_step1_desc => '持咒、數念珠、設定禪坐計時器，或跟隨您傳承中的學習計畫。';

  @override
  String get onboarding_2_step2_title => '融入您的日常生活';

  @override
  String get onboarding_2_step2_desc => '建立日常日程，我們會發送溫和的提醒，幫助您堅持。';

  @override
  String get onboarding_2_step3_title => '每天修持幾分鐘';

  @override
  String get onboarding_2_step3_desc => '哪怕只是一刻也有意義。日復一日，您的修持會不斷成長。';

  @override
  String get home_recitation => '持誦';

  @override
  String get home_today => '今天';

  @override
  String get home_good_morning => '早上好';

  @override
  String get home_good_afternoon => '下午好';

  @override
  String get home_good_evening => '晚上好';

  @override
  String get home_meditationTitle => '禪修';

  @override
  String get home_prayerTitle => '今日祈願';

  @override
  String get home_scripture => '導讀經典';

  @override
  String get home_meditation => '導引禪修';

  @override
  String get home_goDeeper => '深入學習';

  @override
  String get home_intention => '我今日的意願';

  @override
  String get home_overall_stats => '整體統計';

  @override
  String get home_plans => '計劃';

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
  String get bookmark_timers => '計時';

  @override
  String get bookmark_texts => '經文';

  @override
  String get bookmark_group_accumulation => 'Group accumulation';

  @override
  String get mala_add_to_practice => '加入我的修持';

  @override
  String get mala_add_mala_round => '新增念珠遍數';

  @override
  String get mala_add_rounds_title => '新增念珠遍數：';

  @override
  String get mala_add_rounds_message => '新增你在此應用程式之外完成的念珠遍數。';

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
  String get mala_reset_count_confirm => '目前的計數將歸零，但您的累積仍會保留在終身總數中。';

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
  String mala_counter_semantics(int bead, int total, String rounds) {
    return '計數 $bead/$total，$rounds';
  }

  @override
  String get mala_group_accumulations => 'Group accumulations';

  @override
  String get mala_groups_section => 'Groups';

  @override
  String get mala_group_untitled => 'Untitled group';

  @override
  String get home_timer => '計時';

  @override
  String get preset_timers => '預設計時';

  @override
  String get meditation_timer => '禪修計時';

  @override
  String get timer_min => '分鐘';

  @override
  String get timer_start => '開始';

  @override
  String get timer_finish => '完成';

  @override
  String get timer_discard_session => '放弃练习';

  @override
  String get home_hello_prefix => '你好，';

  @override
  String get home_greeting_fallback_name => '朋友';

  @override
  String home_share_prompt(String appName) {
    return '喜歡 $appName 嗎？';
  }

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
  String get text_toc_versions => '版本';

  @override
  String get text_commentary => '注釋';

  @override
  String get resources => '資源';

  @override
  String get no_translation => '尚無相關翻譯';

  @override
  String get text_close_commentary => '關閉注釋';

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
  String get no_commentary => '尚無相關注釋';

  @override
  String commentary_not_available_for_language(String language) {
    return '暫無 $language 註釋';
  }

  @override
  String get loading => '加載中...';

  @override
  String get choose_image => '選擇圖片';

  @override
  String get choose_bg_image => '選擇背景圖片';

  @override
  String get create_image => '建立圖片';

  @override
  String get save => '儲存';

  @override
  String get done => '完成';

  @override
  String get customise_message => '點擊按鈕以調整文字樣式';

  @override
  String get download_image => '下載圖片';

  @override
  String get no_images_available => '沒有可用的圖片';

  @override
  String get customise_text => '自訂文字樣式';

  @override
  String get text_size => '文字大小';

  @override
  String get text_color => '文字顏色';

  @override
  String get text_shadow => '文字陰影';

  @override
  String get apply => '套用';

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
  String get chinese => '白話中文';

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
  String get recitations_title => '唱頌';

  @override
  String get recitations_my_recitations => '我的清單';

  @override
  String get browse_recitations => '瀏覽唱誦列表';

  @override
  String get recitations_search => '搜索';

  @override
  String get recitations_search_for => '尋找持誦內容';

  @override
  String get recitations_no_found => '尚無相關持誦內容';

  @override
  String get recitations_no_content => '沒有可用的持誦';

  @override
  String get recitations_no_saved => '沒有已保存的持誦';

  @override
  String get recitations_login_prompt => '請登錄以查看您保存的持誦';

  @override
  String get my_recitation_collection_new_title => '新收藏';

  @override
  String get my_recitation_collection_next => '下一步';

  @override
  String get my_recitation_collection_create => '建立';

  @override
  String get my_recitation_collection_create_button => '建立收藏';

  @override
  String get my_recitation_collection_change_title => '更改標題';

  @override
  String get my_recitation_collection_change => '更改';

  @override
  String get my_recitation_collection_add_chants => '加入持誦';

  @override
  String get my_recitation_collection_search_chants => '搜尋持誦';

  @override
  String get my_recitation_collection_add_to_collection => '加入收藏';

  @override
  String get my_recitation_collection_edit => '編輯收藏';

  @override
  String get my_recitation_collection_delete => '刪除收藏';

  @override
  String get my_recitation_collection_delete_title => '要刪除收藏嗎？';

  @override
  String get my_recitation_collection_delete_message => '此收藏將被永久刪除。';

  @override
  String get my_recitation_collection_fallback_title => '持誦收藏';

  @override
  String get my_recitation_collection_unavailable => '已無法使用';

  @override
  String my_recitation_collection_chant_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 項持誦',
      one: '1 項持誦',
      zero: '0 項持誦',
    );
    return '$_temp0';
  }

  @override
  String my_recitation_collection_chant_count_owner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 項持誦 • 我',
      one: '1 項持誦 • 我',
      zero: '0 項持誦 • 我',
    );
    return '$_temp0';
  }

  @override
  String get bookmarks_empty_chant_collections_title => '尚未收藏任何持誦收藏。';

  @override
  String get bookmarks_empty_chant_collections_subtitle => '收藏持誦收藏後會顯示在這裡。';

  @override
  String get notification_settings => '通知設定';

  @override
  String get notification_allow_title => '允許通知';

  @override
  String get notification_allow_subtitle_enabled => '此應用程式已啟用通知';

  @override
  String get notification_allow_subtitle_disabled => '需要權限。請點此前往「設定」授權。';

  @override
  String get notification_allow_subtitle_paused => '提醒已暫停。點此恢復。';

  @override
  String get notification_routine_title => '日常提醒';

  @override
  String get notification_routine_subtitle_enabled => '您的每日修持時段提醒';

  @override
  String get notification_routine_subtitle_disabled => '日常提醒已暫停。點此恢復。';

  @override
  String get notification_battery_title => '背景提醒通知';

  @override
  String get notification_battery_subtitle_enabled => '即使應用程式已關閉，您的提醒通知仍會準時發送。';

  @override
  String get notification_battery_subtitle_disabled =>
      '部分 Android 手機會暫停背景應用程式以節省電池使用量，這可能導致提醒通知延遲或遺漏。點此確保應用程式持續運行。';

  @override
  String get notification_recitation_title => '持誦提醒';

  @override
  String get notification_recitation_subtitle_enabled => '每日持誦提醒';

  @override
  String get notification_recitation_subtitle_disabled => '持誦提醒已暫停。點此恢復。';

  @override
  String get notification_practice_title => '念珠提醒';

  @override
  String get notification_practice_subtitle_enabled => '每日念珠修持提醒';

  @override
  String get notification_practice_subtitle_disabled => '念珠提醒已暫停。點此恢復。';

  @override
  String get notification_timer_title => '計時器提醒';

  @override
  String get notification_timer_subtitle_enabled => '每日計時修持時段提醒';

  @override
  String get notification_timer_subtitle_disabled => '計時器提醒已暫停。點此恢復。';

  @override
  String get notification_battery_info_title => '關於背景提醒';

  @override
  String get notification_battery_info_body =>
      '部分 Android 手機會暫停背景應用程式以節省電池，這可能導致已排程的提醒延遲或取消。豁免應用程式可讓您的提醒準時可靠地發送。';

  @override
  String get notification_snack_permission_denied => '通知已被封鎖。請在「設定」中開啟';

  @override
  String get notification_snack_disable_alarms_in_settings => '在「設定」中關閉鬧鐘與提醒';

  @override
  String get notification_snack_battery_reenable => '在「設定 → 電池」中還原「電池最佳化設定」';

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
  String get auth_drawer_title => '請先登入帳號再繼續';

  @override
  String get auth_drawer_subtitle => '隨時隨地，在任何裝置上繼續您的修持';

  @override
  String get routine_delete_block_message => '這將刪除該時段及其中所有內容';

  @override
  String get something_went_wrong => '出了點問題。請再試一次';

  @override
  String get onboarding_quote_citation => '— 法句經 122';

  @override
  String get onboarding_traditions_question => '您跟隨哪些傳承？';

  @override
  String get onboarding_tradition_title => '您如何追随佛陀的教导？';

  @override
  String get onboarding_tradition_subtitle =>
      '我们将为您展示您所选修行路径的实践与经典。您可以随时在应用设置中更改此设置。';

  @override
  String get onboarding_tradition_option_intro => '通過：';

  @override
  String get onboarding_tradition_show_all_title => '顯示所有內容';

  @override
  String get onboarding_tradition_show_all_description => '每條道路的實踐和經典';

  @override
  String get onboarding_skip_for_now => '暫時跳過';

  @override
  String get onboarding_add_another_tradition => '添加另一個傳承';

  @override
  String get onboarding_select_all => '全選';

  @override
  String get onboarding_event_enrollment_error => '無法完成註冊。請檢查您的網路連線，然後再試一次';

  @override
  String get onboarding_event_question => '加入即將舉辦的活動？';

  @override
  String get onboarding_event_optional => '選填 · 點擊以加入';

  @override
  String onboarding_event_duration(String description, int days) {
    return '$description · $days 天';
  }

  @override
  String get onboarding_event_reminder_note => '我們將在每天早上 7:30 提醒您。(可隨時更改。)';

  @override
  String get tradition_theravada => '上座部佛教';

  @override
  String get tradition_zen => '禪宗';

  @override
  String get tradition_tibetan_buddhism => '藏傳佛教';

  @override
  String get tradition_pure_land => '淨土宗';

  @override
  String get tradition_ambedkar_buddhism => '安貝卡佛教';

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
  String get find_plans_load_error => '無法載入計畫，\n請稍後再試';

  @override
  String get connect_coming_soon_subtitle => '在修行路上支持您前行的良師、社群、修持挑戰與相關活動';

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
  String get connect_groups_empty_subtitle => '恭喜，你已加入我們所有的社群！請稍後再來，更多社群即將推出';

  @override
  String get connect_tab_feed => '動態';

  @override
  String get connect_tab_events => '活動';

  @override
  String get connect_tab_posts => '貼文';

  @override
  String get connect_tab_practices => '修持計畫';

  @override
  String get connect_tab_groups => 'Groups';

  @override
  String get connect_segment_my => '為你';

  @override
  String get connect_segment_discover => '探索';

  @override
  String get connect_empty_discover_posts => '沒有可探索的貼文';

  @override
  String get connect_empty_discover_events => '沒有可探索的活動';

  @override
  String get connect_empty_discover_feed => '沒有可探索的內容';

  @override
  String get connect_empty_discover_groups => '沒有可探索的社群';

  @override
  String get connect_empty_discover_practices => '沒有可探索的修行';

  @override
  String get connect_all_groups => '所有社群';

  @override
  String get connect_my_empty_feed_title => '你的社群最近很安靜';

  @override
  String get connect_my_empty_events_title => '沒有即將舉行的活動';

  @override
  String get connect_my_empty_posts_title => '尚無貼文';

  @override
  String get connect_my_empty_groups_title => '尚未加入社群';

  @override
  String get connect_my_empty_feed_subtitle => '你加入的社群沒有新動態。其他社群今天有發文。';

  @override
  String get connect_my_empty_events_subtitle => '你的社群都沒有安排活動。其他社群有開放給所有人的活動。';

  @override
  String get connect_my_empty_posts_subtitle => '你的社群還沒有發文。看看其他社群在分享什麼。';

  @override
  String get connect_my_empty_groups_subtitle => '你還沒有加入任何社群。探索可以一起修持的社群。';

  @override
  String get connect_my_empty_feed_browse => '看看其他社群分享什麼';

  @override
  String get connect_my_empty_events_browse => '瀏覽開放活動';

  @override
  String get connect_my_empty_posts_browse => '瀏覽其他貼文';

  @override
  String get connect_my_empty_practices_title => '尚無修持計畫';

  @override
  String get connect_my_empty_practices_subtitle =>
      '你的社群還沒有發起任何修行活動。看看其他社群提供了什麼。';

  @override
  String get connect_my_empty_practices_browse => '瀏覽其他修行';

  @override
  String connect_comment_replying_to(String handle) {
    return '回覆 @$handle';
  }

  @override
  String get connect_comment_hint => '你對這則有什麼想法？';

  @override
  String get connect_comment_reply_hint => '撰寫回覆…';

  @override
  String get connect_comment_reply => '回覆';

  @override
  String get connect_comment_delete_title => '刪除留言？';

  @override
  String get connect_comment_delete_message => '這則留言將被永久刪除。';

  @override
  String get connect_comment_delete_failed => '刪除留言失敗';

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
  String get connect_post_comments_empty => '還沒有留言。開始討論吧。';

  @override
  String get connect_caption_more => '更多';

  @override
  String get connect_online => '線上';

  @override
  String get home_group_events => '社群活動';

  @override
  String get home_poems => '詩歌';

  @override
  String get poems_load_error => '無法載入詩歌。\n請檢查您的連線並再試一次';

  @override
  String get poems_empty => '尚無詩歌，請稍後再來。';

  @override
  String get connect_events_filter_all => '全部';

  @override
  String get connect_events_filter_in_person => '實體';

  @override
  String get connect_events_filter_empty_online => '沒有線上活動';

  @override
  String get connect_events_filter_empty_in_person => '沒有實體活動';

  @override
  String get connect_events_filter_hybrid => '混合';

  @override
  String get connect_events_filter_empty_hybrid => '沒有混合活動';

  @override
  String get connect_open => '開啟';

  @override
  String get connect_event_fallback_title => '活動';

  @override
  String get connect_group_fallback_title => '社群';

  @override
  String get connect_event_attend => '參加';

  @override
  String get connect_event_attending => '已參加';

  @override
  String connect_event_participants_attending(int count) {
    return '$count 人參加';
  }

  @override
  String get connect_event_participants_empty => '尚無參與者';

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
  String get audio_init_error => '無法初始化音訊播放器。請檢查網路連線後重試';

  @override
  String get meditation_audio_load_error => '無法載入。請檢查網路連線後重試';

  @override
  String get prayer_audio_load_error => '無法載入音訊。請檢查網路連線後重試';

  @override
  String get home_no_series_found => '未找到系列';

  @override
  String get home_no_tags_found => '找不到該標籤';

  @override
  String get home_celebrated_by => '慶祝者：';

  @override
  String get reader_settings_tooltip => '閱讀器設定';

  @override
  String get reader_translate_tooltip => '顯示譯文';

  @override
  String get reader_translate_unavailable => '此文本沒有可用譯文';

  @override
  String get reader_font_size_tooltip => '字體大小';

  @override
  String reader_version_title(String language) {
    return '版本 · $language';
  }

  @override
  String reader_script_title(String language) {
    return '字體 · $language';
  }

  @override
  String get reader_versions_load_error => '載入版本失敗。';

  @override
  String get reader_scripts_load_error => '載入字體失敗。';

  @override
  String get reader_languages_load_error => '語言載入失敗';

  @override
  String reader_no_versions_in_language(String language) {
    return '$language 尚無可用的版本。';
  }

  @override
  String reader_no_scripts_in_language(String language) {
    return '$language 尚無可用的字體。';
  }

  @override
  String get reader_no_languages => '此文本尚無可用的語言。';

  @override
  String get reader_license => '授權';

  @override
  String get reader_version_details_load_error => '無法載入版本詳情。';

  @override
  String get reader_no_version_info => '此版本沒有其他可用的資訊。';

  @override
  String get recitation_unavailable => '此唱誦內容目前無法使用。\n請稍後再試或聯絡客服。';

  @override
  String get recitation_sign_in_required => '請登入以使用此唱誦。';

  @override
  String get my_recitations_load_error => '無法載入。請檢查您的網路連線，然後再試一次。';

  @override
  String get recitations_load_error => '無法載入唱誦。\n請稍後再試。';

  @override
  String get text_search_hint => '輸入以搜尋';

  @override
  String get text_search_press_button => '按下搜尋按鈕以搜尋';

  @override
  String get text_search_error => '無法執行搜尋，請再試一次';

  @override
  String get unknown_error => '未知錯誤';

  @override
  String image_share_error(String error) {
    return '無法分享：$error';
  }

  @override
  String get create_image_capture_error => '圖片生成失敗，請再試一次';

  @override
  String get create_image_share_error => '無法分享，請再試一次';

  @override
  String get create_image_save_success => '圖片已儲存';

  @override
  String get create_image_save_error => '無法儲存圖片。請確認應用程式已獲得相片存取權限後再試一次';

  @override
  String get create_image_download_error => '無法下載您的圖片，請稍後再試';

  @override
  String get create_image_customize_tooltip => '自訂';

  @override
  String get create_image_text_too_long => '文字太長，無法放大字體';

  @override
  String version_search_no_results(String query) {
    return '找不到「$query」的版本';
  }

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
  String get bookmark => '书签';

  @override
  String get image => '圖片';

  @override
  String get feedback => '意見回饋';

  @override
  String get author => '作者';

  @override
  String get plans_created => '參與設計的計畫';

  @override
  String get ai_chat_history => '對話紀錄';

  @override
  String get ai_buddhist_assistant => '佛法AI助手';

  @override
  String get ai_new_chat => '新對話';

  @override
  String get ai_retry => '重試';

  @override
  String get ai_dismiss => '略過';

  @override
  String get ai_sign_in_prompt => '登入後即可向佛法 AI 助理提問';

  @override
  String get ai_explore_wisdom => '探索佛法的智慧';

  @override
  String get ai_ask_question => '請輸入問題．．．．．．';

  @override
  String get ai_search_chats => '搜尋對話紀錄';

  @override
  String get ai_chats => '對話紀錄';

  @override
  String get ai_chat_deleted => '對話已刪除';

  @override
  String get ai_no_conversations => '尚無任何對話';

  @override
  String get ai_start_new_chat => '開始新對話';

  @override
  String get ai_delete_chat => '刪除對話';

  @override
  String get ai_delete_confirmation => '確定要刪除此對話？';

  @override
  String get ai_delete_warning => '此操作執行後將無法復原';

  @override
  String get ai_confirm => '確認';

  @override
  String get ai_delete => '刪除';

  @override
  String ai_greeting(String name) {
    return '$name，您好！';
  }

  @override
  String get ai_text_not_found => '搜尋不到該文本';

  @override
  String ai_text_not_found_message(String title) {
    return '搜尋不到標題為《$title》的文本。\n\n請嘗試其他名稱或換一種方式搜尋。';
  }

  @override
  String get ai_sources => '來源';

  @override
  String ai_sources_count(int count) {
    return '$count 個來源';
  }

  @override
  String search_no_results(String query) {
    return '找不到「$query」的結果';
  }

  @override
  String get search_show_more => '顯示更多';

  @override
  String get search_contents => '內容';

  @override
  String get search_titles => '標題';

  @override
  String get search_all => '全部';

  @override
  String get search_author => '作者';

  @override
  String get search_tab_ai_mode => 'AI 模式';

  @override
  String search_error(String message) {
    return '錯誤：$message';
  }

  @override
  String get search_retrying => '重試中...';

  @override
  String search_no_titles_found(String query) {
    return '找不到「$query」的標題';
  }

  @override
  String search_no_contents_found(String query) {
    return '找不到「$query」的內容';
  }

  @override
  String search_no_authors_found(String query) {
    return '找不到「$query」的作者';
  }

  @override
  String get search_buddhist_texts => '搜尋佛教文本...';

  @override
  String get common_ok => '確定';

  @override
  String get comingSoonHeadline => '即将推出';

  @override
  String get routine_title => '日常修持';

  @override
  String get bookmarks => '书签';

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
  String get routine_session_title_hint => 'Title...';

  @override
  String get routine_expand_all => 'Expand all';

  @override
  String get routine_collapse_all => 'Collapse all';

  @override
  String get routine_delete_time_block => '移除時段';

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
  String get continueAsGuest => '以訪客身份繼續';

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
  String get searchResults => '搜索結果';

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
  String get notFound => '此內容已無法使用。請重新編輯您的修持安排，以進行更新。';

  @override
  String get noTimeSlot => '沒有可用的時間段，請先移除一個區塊';

  @override
  String maxBlocks(int max) {
    return '已達最多 $max 個可選時間區段上限。';
  }

  @override
  String get duplicateItem => '此項目已在區塊中';

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
  String get updateOrderError => '無法更新順序。請再試一次';

  @override
  String get loadFailed => '無法載入。請檢查您的網路連線，然後再試一次。';

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
  String get show_second_version => '顯示次要版本';

  @override
  String get enable_add_msg => '開啟以同時對讀主文的其他翻譯或音譯';

  @override
  String get main_version => '主要版本';

  @override
  String get second_version => '次要版本';

  @override
  String get second_version_msg => '次要版本將會顯示在主要版本的內文下方';

  @override
  String get version => '所有版本';

  @override
  String get parallel_version => '對讀版本';

  @override
  String get version_not_available => '無可用版本';

  @override
  String get read_full_text => '閱讀完整文本';

  @override
  String get reader_source_label => '來源';

  @override
  String get reader_license_label => '授權';

  @override
  String series_stats(int planCount, int totalDays) {
    return '$planCount 個章節 · $totalDays 天';
  }

  @override
  String get force_update_title => '需要更新';

  @override
  String get force_update_message => '有新版本可用，請更新後繼續使用。';

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
  String get edit_profile_first_name => '名字';

  @override
  String get edit_profile_last_name => '姓氏';

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
  String get edit_profile_offline => '您目前離線，請連接網路後再試一次';

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
  String get about_connect_with_us => '與我們交流';

  @override
  String get about_description =>
      '我們協助佛教徒透過每日的學習、修持與交流，減少惡行、增長善行，更深入地了解自己的心。並希望藉此，讓一切眾生皆能離苦得樂。';

  @override
  String get about_social_website => '網頁';

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
  String get accumulations => '累積';

  @override
  String get accumulations_search => '搜索累積';

  @override
  String get accumulations_search_for => '尋找累積內容';

  @override
  String get accumulations_no_found => '尚無相關累積內容';

  @override
  String get me_accumulation => '累積總數';

  @override
  String get me_counts => '次';

  @override
  String get me_minutes => '分鐘';

  @override
  String get me_hours => '小時';

  @override
  String get me_total_meditation_time => '禪修總時間';

  @override
  String get me_days_plan_practiced_suffix => '天計畫已完成';

  @override
  String me_streak_share_message(int count, String appName) {
    return '我在 $appName 已連續 $count 天！';
  }

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
  String get following => '追蹤中';

  @override
  String get calendar_title => '日历';

  @override
  String get calendar_upcoming_events => '近期活动';

  @override
  String get calendar_day_short => '日';

  @override
  String get calendar_day_label => '日';

  @override
  String calendar_day_month(int day, int month) {
    return '藏历$month月$day日';
  }

  @override
  String calendar_lunar_month(String ordinal) {
    return '藏历$ordinal月';
  }

  @override
  String get moon_phase_new_moon => '新月';

  @override
  String get moon_phase_waxing_crescent => '蛾眉月';

  @override
  String get moon_phase_first_quarter => '上弦月';

  @override
  String get moon_phase_waxing_gibbous => '盈凸月';

  @override
  String get moon_phase_full_moon => '满月';

  @override
  String get moon_phase_waning_gibbous => '亏凸月';

  @override
  String get moon_phase_last_quarter => '下弦月';

  @override
  String get moon_phase_waning_crescent => '残月';

  @override
  String get join => '加入';

  @override
  String get joined => '已加入';

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
    return '成員($count)';
  }

  @override
  String group_followers_heading(int count) {
    return '追蹤者($count)';
  }

  @override
  String get group_invite => '邀請';

  @override
  String get group_request_to_join => '申請加入';

  @override
  String get group_request => '申請';

  @override
  String get group_request_sent => '申請已送出';

  @override
  String get group_join_request_title => '申請加入';

  @override
  String get group_join_request_message_label => '訊息（選填）';

  @override
  String get group_join_request_message_hint => '您如何修行，或是誰邀請您？';

  @override
  String get group_join_request_send => '送出申請';

  @override
  String get group_join_request_sent_snackbar => '申請已送出 — 管理員將會審核。';

  @override
  String get group_join_request_error => '無法送出申請，請再試一次。';

  @override
  String get group_members_only_title => '僅限成員';

  @override
  String get group_members_only_message => '加入後即可查看此群組的誦經、活動和貼文。';

  @override
  String get group_join_request_waiting_title => '等待管理員審核';

  @override
  String get group_join_request_waiting_message => '您的申請審核完成後，我們會立即通知您。';

  @override
  String get group_members_load_error => '無法載入成員，請再試一次。';

  @override
  String get group_followers_load_error => '無法載入追蹤者，請再試一次。';

  @override
  String get group_members_empty => '尚無成員';

  @override
  String get group_followers_empty => '尚無追蹤者';

  @override
  String get group_follower => '位追蹤者';

  @override
  String get group_followers => '位追蹤者';

  @override
  String get group_links_title => '連結';

  @override
  String get group_about_description => '簡介';

  @override
  String get group_about_empty => '尚無可用資訊';

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
  String get group_change_practice_title => '改變小組實踐';

  @override
  String get group_change_practice_message => '您目前已與其他小組一起練習此計劃。您是否想更換練習小組？';

  @override
  String get group_join_to_contribute => '加入以貢獻';

  @override
  String get group_accumulator_join_error => '無法加入累積，請再試一次。';

  @override
  String get group_accumulator_join_before_practice =>
      'Join this accumulation before adding it to your practices';

  @override
  String group_accumulator_participants(int count) {
    return '$count 位參與者';
  }

  @override
  String get group_accumulator_leaderboard => '排行榜';

  @override
  String get group_accumulator_my_contributions => '我的貢獻';

  @override
  String get group_accumulator_recited => '已誦讀';

  @override
  String get group_accumulator_total => '總數';

  @override
  String get group_accumulator_contributions_empty => '加入此累積以追蹤您的貢獻。';

  @override
  String get group_accumulator_leaderboard_empty => '尚無誦念紀錄。';

  @override
  String get group_accumulator_recite_now => '立即誦念';

  @override
  String get group_accumulator_chant_again => '再次誦念';

  @override
  String get group_accumulator_finish_session => '結束此次課誦';

  @override
  String get group_accumulator_offline_recitation => '線下誦念';

  @override
  String get group_accumulator_add_offline_chants_title => '新增線下誦念：';

  @override
  String get group_accumulator_add_offline_chants_message =>
      '新增你在此應用程式之外完成的誦念次數。';

  @override
  String get group_accumulator_session_complete => '課誦完成！';

  @override
  String group_accumulator_session_recitations(int count) {
    return '你在這次課誦中完成了 $count 遍';
  }

  @override
  String group_accumulator_session_share_message(
    int count,
    String accumulation,
    String group,
  ) {
    return '我在 WeBuddhist 上 $group 的累積活動「$accumulation」中完成了 $count 遍誦念，快來加入我吧！';
  }

  @override
  String group_accumulator_session_share_message_no_group(
    int count,
    String accumulation,
  ) {
    return '我在 WeBuddhist 上的累積活動「$accumulation」中完成了 $count 遍誦念，快來加入我吧！';
  }

  @override
  String get group_accumulator_session_share_error => '無法分享課誦，請重試';

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
  String get share_this_quote => '分享这句话';

  @override
  String get shared_from => '分享自';

  @override
  String get verse_share_error => '无法分享引文，请重试';

  @override
  String get share_app_message => '我一直在用这款应用培养每日佛法修行的习惯，觉得你也会喜欢。';

  @override
  String get share_streak_message =>
      '我一直在养成每日修行的好习惯，想和你分享。有朋友一起坚持会更容易。来WeBuddhist和我一起吧。';

  @override
  String get share_chant_message =>
      '我想和你分享这段诵文。你可以在WeBuddhist上练习它，还能找到整个诵文和经典库。';

  @override
  String get share_quote_message =>
      '我喜欢WeBuddhist上的这段引语，想和你分享。在WeBuddhist应用上阅读更多深刻的引语。';

  @override
  String get share_poem_message => '我喜欢WeBuddhist上的这首诗，想和你分享。';

  @override
  String get share_mala_message =>
      '我一直在WeBuddhist上使用这串电子念珠，想和你分享。这是一个随时随地修行的便捷方式。';

  @override
  String get share_passage_message => '我喜欢这段经文，想和你分享。你可以在WeBuddhist上阅读完整的上下文。';

  @override
  String get share_timer_message => '我想和你分享WeBuddhist上的这个禅修计时器。它让建立禅修习惯变得更轻松。';

  @override
  String get share_plan_message =>
      '我正在跟随这个佛法修行计划，想和你分享。你可以在WeBuddhist上免费和我一起修行。';

  @override
  String get share_plan_subject => '在WeBuddhist上和我一起吧';

  @override
  String get share_group_invite_message => '我希望你能加入我们的群组。让我们在WeBuddhist上一起修行吧。';

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
  String get reader_about_this_version => '關於此版本';

  @override
  String reader_version_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個版本',
    );
    return '$_temp0';
  }

  @override
  String get mala_no_mantras => '暫無咒語';

  @override
  String get mala_count_load_error => '無法載入您的計數';

  @override
  String get mala_mantra_label => '咒語';

  @override
  String get bookmarks_empty_all_title => '尚無書籤。';

  @override
  String get bookmarks_empty_all_subtitle => '將任何內容加入書籤即可儲存於此。';

  @override
  String get bookmarks_empty_plans_title => '尚無已加書籤的計畫。';

  @override
  String get bookmarks_empty_plans_subtitle => '將計畫加入書籤即可儲存於此。';

  @override
  String get bookmarks_empty_malas_title => '尚無已加書籤的念珠。';

  @override
  String get bookmarks_empty_malas_subtitle => '將念珠加入書籤即可儲存於此。';

  @override
  String get bookmarks_empty_group_accumulations_title =>
      'No group accumulations bookmarked yet.';

  @override
  String get bookmarks_empty_group_accumulations_subtitle =>
      'Bookmark a group accumulation to save it here.';

  @override
  String get bookmarks_empty_timers_title => '尚無已加書籤的計時器。';

  @override
  String get bookmarks_empty_timers_subtitle => '將計時器加入書籤即可儲存於此。';

  @override
  String get bookmarks_empty_texts_title => '尚無已加書籤的文本。';

  @override
  String get bookmarks_empty_texts_subtitle => '將文本加入書籤即可儲存於此。';

  @override
  String get bookmark_removed => '已移除書籤';

  @override
  String get bookmark_remove_failed => '移除書籤失敗';

  @override
  String get bookmark_saved => '書籤已儲存';

  @override
  String get bookmark_save_failed => '儲存書籤失敗';

  @override
  String get bookmarks_yesterday => '昨天';

  @override
  String get webview_timeout_error => '頁面載入時間過長。請檢查您的網路連線。';

  @override
  String get webview_load_failed => '頁面載入失敗';

  @override
  String get privacy_policy_load_error => '無法載入隱私政策頁面。';

  @override
  String get terms_of_service_load_error => '無法載入服務條款頁面。';

  @override
  String get series_enroll_error => '加入系列失敗';

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
  String get session_plans_load_error => '無法載入計畫。\n請稍後重試。';

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
  String get ai_use_search_instead => '改用搜尋';

  @override
  String get ai_mode_label => 'AI';

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
  String get author_details_load_error => '無法載入作者資訊。\n請重試。';

  @override
  String get link_cannot_open => '無法開啟此連結';

  @override
  String get link_invalid => '無效的網址';

  @override
  String get author_no_plans => '尚未建立計畫';

  @override
  String get author_plans_load_error => '無法載入計畫';

  @override
  String source_with_value(String value) {
    return '來源：$value';
  }

  @override
  String license_with_value(String value) {
    return '授權：$value';
  }

  @override
  String loading_previous_pages(int count) {
    return '正在載入上文……（$count 頁）';
  }

  @override
  String loading_more_pages(int count) {
    return '正在載入更多……（$count 頁）';
  }

  @override
  String get drag_to_resize => '拖動以調整大小';

  @override
  String get day_completion_share_message =>
      '我刚在 WeBuddhist 上完成了一天的修行练习。加入我，一起培养每日修行的好习惯。';

  @override
  String group_accumulator_share_message(String accumulation, String group) {
    return '我正在 WeBuddhist 上參加 $group 的累積活動「$accumulation」，快來加入我吧！';
  }

  @override
  String group_accumulator_share_message_no_group(String accumulation) {
    return '我正在 WeBuddhist 上參加累積活動「$accumulation」，快來加入我吧！';
  }

  @override
  String get group_chat_title => '聊天';

  @override
  String get chats_title => '聊天';

  @override
  String get chats_empty_title => '尚無聊天';

  @override
  String get chats_empty_body => '加入社群即可開始聊天。';

  @override
  String get group_chat_inappropriate => '此訊息含有不允許的用語，因此無法發送。';

  @override
  String get group_chat_not_a_member => '僅限成員開啟此聊天。';

  @override
  String get group_chat_open => '聊天';

  @override
  String get group_chat_message_hint => '訊息';

  @override
  String get group_chat_join_to_send => '加入聊天後即可傳送訊息。';

  @override
  String get group_chat_today => '今天';

  @override
  String get group_chat_yesterday => '昨天';

  @override
  String get group_chat_empty_title => '暫無訊息';

  @override
  String get group_chat_empty_body => '與你的群組開始對話吧。';

  @override
  String get group_chat_load_failed => '無法載入訊息。';

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
  String get group_chat_copied => '已複製訊息';

  @override
  String get group_chat_report => '檢舉';

  @override
  String get group_chat_report_title => '你為什麼要檢舉這則訊息？';

  @override
  String get group_chat_report_privacy => '你的姓名不會公開。';

  @override
  String get group_chat_report_reason_harassment => '騷擾或霸凌';

  @override
  String get group_chat_report_reason_hate => '仇恨或有害言論';

  @override
  String get group_chat_report_reason_sexual => '性相關或露骨內容';

  @override
  String get group_chat_report_reason_spam => '垃圾訊息或詐騙';

  @override
  String get group_chat_report_reason_off_topic => '離題或干擾';

  @override
  String get group_chat_report_reason_other => '其他原因';

  @override
  String get group_chat_report_note_title => '新增備註';

  @override
  String get group_chat_report_note_hint => '其他原因...';

  @override
  String get group_chat_report_submit => '送出檢舉';

  @override
  String get group_chat_report_thanks => '感謝你的回報';

  @override
  String get group_chat_report_offline => '你目前離線 — 請稍後再試';

  @override
  String get group_chat_report_failed => '無法送出檢舉';

  @override
  String get group_chat_report_retry => '重試';

  @override
  String get group_chat_delete => '刪除';

  @override
  String get group_chat_delete_title => '刪除訊息？';

  @override
  String get group_chat_delete_confirm_body => '此訊息將為聊天中的所有人刪除。';

  @override
  String get group_chat_delete_for_everyone => '為所有人刪除';

  @override
  String get group_chat_delete_failed => '無法刪除訊息。';

  @override
  String get group_chat_message_deleted => '你已刪除此訊息';

  @override
  String get group_chat_message_deleted_by_sender => '此訊息已刪除';

  @override
  String get group_chat_reaction_failed => '無法儲存你的回應。';

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
  String get group_chat_you => '你';

  @override
  String get group_chat_tap_to_remove => '點按以移除';

  @override
  String get group_chat_reply_parent_gone => '該訊息已不存在，引用已移除。請再次傳送你的訊息。';

  @override
  String get group_tab_posts => '貼文';

  @override
  String get group_tab_events => '活動';

  @override
  String get group_posts_empty_title => '尚無貼文';

  @override
  String get group_posts_empty_message => '與你的社群分享第一則動態。';

  @override
  String get group_posts_load_error => '無法載入貼文，請再試一次。';

  @override
  String get group_post_button => '發佈';

  @override
  String get group_post_new_title => '新貼文';

  @override
  String get group_post_posting_to => '發佈至：';

  @override
  String get group_post_caption_hint => '有什麼新鮮事？';

  @override
  String get group_post_photos => '相片';

  @override
  String get group_post_link => '連結';

  @override
  String get group_post_discard_title => '捨棄貼文？';

  @override
  String get group_post_discard_message => '你所寫的內容將會遺失。';

  @override
  String get group_post_keep_editing => '繼續編輯';

  @override
  String get group_post_discard => '捨棄';

  @override
  String get group_post_add_link_title => '新增連結';

  @override
  String get group_post_add_link_hint => '貼上連結，我們會顯示預覽。';

  @override
  String get group_post_link_field_hint => '連結';

  @override
  String get group_post_attach => '附加';

  @override
  String get group_post_attach_as_link => '以連結附加';

  @override
  String get group_post_preview_failed_title => '無法載入預覽';

  @override
  String get group_post_preview_failed_message => '你仍可將它以連結附加。';

  @override
  String get group_post_invalid_link => '請輸入有效的連結，例如 https://example.com';

  @override
  String group_post_photo_limit(int count) {
    return '最多可新增 $count 張相片。';
  }

  @override
  String get group_post_upload_error => '無法上傳相片，請再試一次。';

  @override
  String get group_post_publish_error => '無法發佈你的貼文，請再試一次。';

  @override
  String get group_post_published => '你的貼文已發佈。';

  @override
  String get group_post_delete_title => '刪除貼文？';

  @override
  String get group_post_delete_message => '這則貼文將被永久刪除。';

  @override
  String get group_post_delete_failed => '無法刪除貼文，請再試一次。';

  @override
  String get edit => '編輯';

  @override
  String get group_post_edit_title => '編輯貼文';

  @override
  String get group_post_update_error => '無法儲存你的變更，請再試一次。';

  @override
  String get group_post_updated => '你的變更已儲存。';

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

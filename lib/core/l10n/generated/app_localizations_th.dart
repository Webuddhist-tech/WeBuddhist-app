// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'WeBuddhist';

  @override
  String get sign_in => 'เข้าสู่ระบบ';

  @override
  String get logout => 'ออกจากระบบ';

  @override
  String get onboarding_welcome => 'ยินดีต้อนรับสู่';

  @override
  String get onboarding_setup_subtitle =>
      'มาตั้งค่ากันเถอะ ใช้เวลาเพียงหนึ่งนาที';

  @override
  String get onboarding_tagline => 'เรียนรู้ ปฏิบัติ และเชื่อมโยงกัน ทุกวัน';

  @override
  String get onboarding_quote =>
      'หม้อน้ำย่อมเต็มได้ด้วยน้ำทีละหยด ฉันใด ผู้มีปัญญาสั่งสมความดีทีละน้อย ก็ย่อมเต็มเปี่ยมด้วยความดี ฉันนั้น';

  @override
  String get onboarding_find_peace => 'เริ่มต้นใช้งาน';

  @override
  String get onboarding_continue => 'ดำเนินการต่อ';

  @override
  String get onboarding_first_question => 'เลือกภาษาของคุณ';

  @override
  String get onboarding_language_subtitle => 'ภาษานี้จะใช้เป็นภาษาของแอป';

  @override
  String get onboarding_choose_option => 'เลือกอย่างน้อยหนึ่งข้อ:';

  @override
  String get onboarding_all_set => 'พร้อมแล้ว';

  @override
  String get onboarding_all_set_description => 'สิ่งที่รอคุณอยู่:';

  @override
  String get onboarding_all_set_practice_title => 'ปฏิบัติ';

  @override
  String get onboarding_all_set_practice_body =>
      'แผนการปฏิบัติ บทสวด ลูกประคำ และการทำสมาธิ';

  @override
  String get onboarding_all_set_connect_title => 'ชุมชน';

  @override
  String get onboarding_all_set_connect_body => 'กลุ่ม กิจกรรม ฟีดข่าว และแชท';

  @override
  String get home_recitation => 'บทสวด';

  @override
  String get home_today => 'วันนี้';

  @override
  String get home_good_morning => 'อรุณสวัสดิ์';

  @override
  String get home_good_afternoon => 'สวัสดีตอนบ่าย';

  @override
  String get home_good_evening => 'สวัสดีตอนเย็น';

  @override
  String get home_meditationTitle => 'การทำสมาธิ';

  @override
  String get home_prayerTitle => 'บทสวดประจำวัน';

  @override
  String get home_scripture => 'ศึกษาคัมภีร์แบบมีผู้นำ';

  @override
  String get home_meditation => 'ทำสมาธิแบบมีผู้นำ';

  @override
  String get home_goDeeper => 'ศึกษาให้ลึกซึ้ง';

  @override
  String get home_intention => 'ความตั้งใจของฉันสำหรับวันนี้';

  @override
  String get home_overall_stats => 'สถิติโดยรวม';

  @override
  String get home_plans => 'แผนการปฏิบัติ';

  @override
  String home_plans_count(int count) {
    return '$count แผนการปฏิบัติ';
  }

  @override
  String home_recitation_count(int count) {
    return '$count บทสวด';
  }

  @override
  String get home_shortcut_plans => 'แผนการปฏิบัติ';

  @override
  String get home_chants => 'บทสวด';

  @override
  String get home_mala => 'ลูกประคำ';

  @override
  String get session_mala => 'ลูกประคำ';

  @override
  String get bookmark_mala => 'ลูกประคำ';

  @override
  String get bookmark_timers => 'ตัวจับเวลา';

  @override
  String get bookmark_texts => 'คัมภีร์';

  @override
  String get bookmark_group_accumulation => 'ยอดสะสมของกลุ่ม';

  @override
  String get mala_add_to_practice => 'เพิ่มในการปฏิบัติของฉัน';

  @override
  String get mala_add_mala_round => 'เพิ่มรอบลูกประคำ';

  @override
  String get mala_add_rounds_title => 'เพิ่มรอบลูกประคำ:';

  @override
  String get mala_add_rounds_message => 'เพิ่มจำนวนรอบลูกประคำที่คุณนับนอกแอป';

  @override
  String mala_rounds_unit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'รอบ',
      one: 'รอบ',
    );
    return '$_temp0';
  }

  @override
  String get mala_add_to_bookmark => 'บุ๊กมาร์ก';

  @override
  String get mala_sound => 'เสียง';

  @override
  String get mala_vibration => 'การสั่น';

  @override
  String get mala_reset_count => 'รีเซ็ตจำนวนนับ';

  @override
  String get mala_reset_title => 'รีเซ็ตลูกประคำนี้ใช่ไหม';

  @override
  String get mala_reset_count_confirm =>
      'จำนวนนับปัจจุบันจะกลับเป็นศูนย์ แต่ยอดสะสมของคุณจะยังอยู่ในยอดรวมตลอดชีวิต';

  @override
  String get mala_reset_confirm => 'รีเซ็ต';

  @override
  String get mala_action_coming_soon => 'เร็ว ๆ นี้';

  @override
  String mala_rounds_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รอบ',
      one: '1 รอบ',
      zero: '0 รอบ',
    );
    return '$_temp0';
  }

  @override
  String get mala_hand_layout_tooltip => 'สลับรูปแบบมือ';

  @override
  String get mala_settings_section => 'การตั้งค่าลูกประคำ';

  @override
  String get mala_others_section => 'อื่น ๆ';

  @override
  String get mala_mantra_speed => 'ความเร็วมนต์';

  @override
  String get mala_speed_normal => 'ปกติ';

  @override
  String get mala_show_full_mantra => 'แสดงมนต์เต็ม';

  @override
  String mala_counter_semantics(int bead, int total, String rounds) {
    return 'นับ $bead จาก $total $rounds';
  }

  @override
  String get mala_group_accumulations => 'เพิ่มการสวดไปที่';

  @override
  String get mala_groups_section => 'กิจกรรม';

  @override
  String get mala_group_untitled => 'กลุ่มไม่มีชื่อ';

  @override
  String get mala_all_time_accumulation => 'ยอดสะสมทั้งหมดของฉัน';

  @override
  String get mala_personal_practice => 'การปฏิบัติส่วนตัว';

  @override
  String get mala_events_section => 'กิจกรรม';

  @override
  String mala_my_total(String count) {
    return 'ยอดรวมของฉัน: $count';
  }

  @override
  String mala_group_total(String count) {
    return 'ยอดรวมของกลุ่ม: $count';
  }

  @override
  String get home_timer => 'ตัวจับเวลา';

  @override
  String get preset_timers => 'ตัวจับเวลาสำเร็จรูป';

  @override
  String get meditation_timer => 'ตัวจับเวลาทำสมาธิ';

  @override
  String get timer_min => 'นาที';

  @override
  String get timer_start => 'เริ่ม';

  @override
  String get timer_finish => 'เสร็จสิ้น';

  @override
  String get timer_discard_session => 'ละทิ้งการทำสมาธินี้';

  @override
  String get home_hello_prefix => 'สวัสดี ';

  @override
  String get home_greeting_fallback_name => 'เพื่อนธรรม';

  @override
  String home_share_prompt(String appName) {
    return 'ชอบ $appName ไหม';
  }

  @override
  String get home_share_support => 'การสนับสนุนของคุณช่วยให้ชุมชนของเราเติบโต';

  @override
  String get no_feature_content => 'ไม่มีเนื้อหาแนะนำ';

  @override
  String get nav_home => 'หน้าหลัก';

  @override
  String get nav_explore => 'สำรวจ';

  @override
  String get nav_learn => 'เรียนรู้';

  @override
  String get nav_practice => 'ปฏิบัติ';

  @override
  String get nav_settings => 'การตั้งค่า';

  @override
  String get nav_connect => 'ชุมชน';

  @override
  String get nav_me => 'ฉัน';

  @override
  String get tab_practices => 'การปฏิบัติ';

  @override
  String get text_search => 'ค้นหา';

  @override
  String get text_toc_versions => 'ฉบับ';

  @override
  String get text_commentary => 'อรรถกถา';

  @override
  String get resources => 'แหล่งข้อมูล';

  @override
  String get no_translation => 'ไม่พบคำแปล';

  @override
  String get text_close_commentary => 'ปิดอรรถกถา';

  @override
  String get show_more => 'แสดงเพิ่มเติม';

  @override
  String get show_less => 'แสดงน้อยลง';

  @override
  String get more => 'เพิ่มเติม';

  @override
  String get less => 'แสดงน้อยลง';

  @override
  String get no_content => 'ไม่พบเนื้อหา';

  @override
  String get no_commentary => 'ไม่พบอรรถกถา';

  @override
  String commentary_not_available_for_language(String language) {
    return 'ไม่มีอรรถกถาสำหรับ $language';
  }

  @override
  String get loading => 'กำลังโหลด...';

  @override
  String get choose_bg_image => 'เลือกภาพพื้นหลัง';

  @override
  String get save => 'บันทึก';

  @override
  String get done => 'เสร็จสิ้น';

  @override
  String get customise_message => 'แตะไอคอนปรับแต่งเพื่อปรับรูปแบบข้อความ';

  @override
  String get download_image => 'ดาวน์โหลดภาพ';

  @override
  String get no_images_available => 'ไม่มีภาพ';

  @override
  String get customise_text => 'ปรับแต่งข้อความ';

  @override
  String get text_size => 'ขนาดตัวอักษร';

  @override
  String get text_color => 'สีตัวอักษร';

  @override
  String get text_shadow => 'เงาตัวอักษร';

  @override
  String get apply => 'ใช้';

  @override
  String get my_plans => 'แผนการปฏิบัติของฉัน';

  @override
  String get browse_plans => 'เลือกดูแผนการปฏิบัติ';

  @override
  String get plan_info => 'ข้อมูลแผนการปฏิบัติ';

  @override
  String get start_reading => 'ปฏิบัติเลย';

  @override
  String get tibetan => 'ภาษาทิเบต';

  @override
  String get sanskrit => 'ภาษาสันสกฤต';

  @override
  String get english => 'ภาษาอังกฤษ';

  @override
  String get chinese => 'ภาษาจีน';

  @override
  String get classicalChinese => 'ภาษาจีนคลาสสิก';

  @override
  String get pali => 'ภาษาบาลี';

  @override
  String get language => 'ภาษา';

  @override
  String get plan_unenroll => 'ยกเลิกการลงทะเบียน';

  @override
  String get unenroll_confirmation => 'ต้องการยกเลิกการลงทะเบียน';

  @override
  String get unenroll_message =>
      'ความคืบหน้าของคุณจะหายไปอย่างถาวรและกู้คืนไม่ได้';

  @override
  String get practice_plan => 'สร้างการปฏิบัติประจำวัน สำรวจสิ่งที่เหมาะกับคุณ';

  @override
  String get search_plans => 'ค้นหาแผนการปฏิบัติ...';

  @override
  String get search_for_plans => 'ค้นหาแผนการปฏิบัติ';

  @override
  String get no_plans_found => 'ไม่พบแผนการปฏิบัติ';

  @override
  String get no_days_available => 'ไม่พบวัน';

  @override
  String get recitations_title => 'บทสวด';

  @override
  String get recitations_my_recitations => 'บทสวดของฉัน';

  @override
  String get browse_recitations => 'เลือกดูบทสวด';

  @override
  String get recitations_search => 'ค้นหาบทสวด...';

  @override
  String get recitations_search_for => 'ค้นหาบทสวด';

  @override
  String get recitations_no_found => 'ไม่พบบทสวด';

  @override
  String get recitations_no_content => 'ไม่มีบทสวด';

  @override
  String get recitations_no_saved => 'ไม่มีบทสวดที่บันทึกไว้';

  @override
  String get recitations_login_prompt => 'เข้าสู่ระบบเพื่อดูบทสวดที่บันทึกไว้';

  @override
  String get my_recitation_collection_new_title => 'ชุดบทสวดใหม่';

  @override
  String get my_recitation_collection_next => 'ถัดไป';

  @override
  String get my_recitation_collection_create => 'สร้าง';

  @override
  String get my_recitation_collection_create_button => 'สร้างชุดบทสวด';

  @override
  String get my_recitation_collection_change_title => 'เปลี่ยนชื่อ';

  @override
  String get my_recitation_collection_change => 'เปลี่ยน';

  @override
  String get my_recitation_collection_add_chants => 'เพิ่มบทสวด';

  @override
  String get my_recitation_collection_search_chants => 'ค้นหาบทสวด';

  @override
  String get my_recitation_collection_add_to_collection => 'เพิ่มในชุดบทสวด';

  @override
  String get my_recitation_collection_edit => 'แก้ไขชุดบทสวด';

  @override
  String get my_recitation_collection_delete => 'ลบชุดบทสวด';

  @override
  String get my_recitation_collection_delete_title => 'ลบชุดบทสวดใช่ไหม';

  @override
  String get my_recitation_collection_delete_message =>
      'ชุดบทสวดนี้จะถูกลบอย่างถาวร';

  @override
  String get my_recitation_collection_fallback_title => 'ชุดบทสวด';

  @override
  String get my_recitation_collection_unavailable => 'ไม่มีให้ใช้งานแล้ว';

  @override
  String my_recitation_collection_chant_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count บทสวด',
      one: '1 บทสวด',
      zero: '0 บทสวด',
    );
    return '$_temp0';
  }

  @override
  String my_recitation_collection_chant_count_owner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count บทสวด • ฉัน',
      one: '1 บทสวด • ฉัน',
      zero: '0 บทสวด • ฉัน',
    );
    return '$_temp0';
  }

  @override
  String get bookmarks_empty_chant_collections_title =>
      'ยังไม่มีชุดบทสวดที่บุ๊กมาร์กไว้';

  @override
  String get bookmarks_empty_chant_collections_subtitle =>
      'บุ๊กมาร์กรายการที่สนใจเพื่อเก็บไว้ที่นี่';

  @override
  String get notification_allow_title => 'อนุญาตการแจ้งเตือน';

  @override
  String get notification_allow_subtitle_disabled =>
      'ต้องได้รับอนุญาต แตะเพื่ออนุญาตในการตั้งค่า';

  @override
  String get notification_snack_permission_denied =>
      'การแจ้งเตือนถูกบล็อก เปิดได้ในการตั้งค่า';

  @override
  String get notification_snack_disable_alarms_in_settings =>
      'ปิดการปลุกและการเตือนในการตั้งค่า';

  @override
  String get notification_allow_subtitle_on =>
      'การเตือนและอัปเดตจาก WeBuddhist';

  @override
  String get notification_allow_subtitle_off =>
      'ปิดอยู่ เปิดเพื่อรับการเตือนและอัปเดต';

  @override
  String get notification_section_practice => 'การปฏิบัติ';

  @override
  String get notification_section_connect => 'ชุมชน';

  @override
  String get notification_row_plans => 'แผนการปฏิบัติ';

  @override
  String get notification_row_chants => 'บทสวด';

  @override
  String get notification_row_mala => 'ลูกประคำและยอดสะสม';

  @override
  String get notification_row_timer => 'ตัวจับเวลา';

  @override
  String get notification_row_group_posts => 'โพสต์ในกลุ่ม';

  @override
  String get notification_row_group_chats => 'แชทกลุ่ม';

  @override
  String get notification_row_my_prayer_requests => 'คำขอให้ร่วมอธิษฐานของฉัน';

  @override
  String get notification_row_others_prayer_requests =>
      'คำขอให้ร่วมอธิษฐานของผู้อื่น';

  @override
  String get profile_default_bio => 'ยินดีต้อนรับสู่ WeBuddhist';

  @override
  String get profile_guest_title => 'ผู้เยี่ยมชม';

  @override
  String get profile_guest_subtitle => 'คุณกำลังใช้งานในฐานะผู้เยี่ยมชม';

  @override
  String get profile_guest_benefits_header => 'เข้าสู่ระบบเพื่อปลดล็อก:';

  @override
  String get profile_guest_benefit_save_progress => 'บันทึกความคืบหน้า';

  @override
  String get profile_guest_benefit_personalized => 'เนื้อหาเฉพาะสำหรับคุณ';

  @override
  String get profile_guest_benefit_notifications =>
      'การแจ้งเตือนที่ปรับแต่งได้';

  @override
  String get auth_drawer_title => 'เข้าสู่ระบบเพื่อดำเนินการต่อ';

  @override
  String get auth_drawer_subtitle =>
      'ปฏิบัติต่อได้บนทุกอุปกรณ์ ไม่ว่าจะอยู่ที่ไหน';

  @override
  String get routine_delete_block_message =>
      'ช่วงเวลานี้และรายการทั้งหมดในช่วงเวลาจะถูกนำออก';

  @override
  String get something_went_wrong => 'เกิดข้อผิดพลาด โปรดลองอีกครั้ง';

  @override
  String get onboarding_quote_citation => '— ธรรมบท 122';

  @override
  String get onboarding_traditions_question =>
      'คุณปฏิบัติตาม\nสายการปฏิบัติใดบ้าง';

  @override
  String get onboarding_tradition_title =>
      'คุณปฏิบัติตามคำสอนของพระพุทธเจ้าอย่างไร';

  @override
  String get onboarding_tradition_subtitle =>
      'เลือกสายการปฏิบัติอย่างน้อยหนึ่งสายสำหรับเนื้อหาของคุณ เปลี่ยนได้ทุกเมื่อในการตั้งค่า';

  @override
  String get onboarding_tradition_option_intro => 'ตามแนวทาง:';

  @override
  String get onboarding_tradition_show_all_title => 'แสดงทั้งหมด';

  @override
  String get onboarding_skip_for_now => 'ข้ามไปก่อน';

  @override
  String get onboarding_add_another_tradition => 'เพิ่มสายการปฏิบัติอื่น';

  @override
  String get onboarding_select_all => 'เลือกทั้งหมด';

  @override
  String get onboarding_event_enrollment_error =>
      'ไม่สามารถลงทะเบียนได้ ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';

  @override
  String get onboarding_event_question => 'เข้าร่วม\nกิจกรรมไหม';

  @override
  String get onboarding_event_optional => 'ไม่บังคับ · แตะเพื่อลงทะเบียน';

  @override
  String onboarding_event_duration(String description, int days) {
    return '$description · $days วัน';
  }

  @override
  String get onboarding_event_reminder_note =>
      'เราจะส่งการเตือนให้ทุกวันเวลา 07:30 น. (เปลี่ยนได้ทุกเมื่อ)';

  @override
  String get tradition_theravada => 'เถรวาท';

  @override
  String get tradition_zen => 'เซน';

  @override
  String get tradition_tibetan_buddhism => 'พุทธศาสนาแบบทิเบต';

  @override
  String get tradition_pure_land => 'สุขาวดี';

  @override
  String get tradition_ambedkar_buddhism => 'พุทธศาสนาแนวอัมเบดการ์';

  @override
  String get plan_go_to_practice => 'ไปที่การปฏิบัติ';

  @override
  String get plan_starts_soon_title => 'เริ่มเร็ว ๆ นี้';

  @override
  String get plan_joining_late_title => 'เข้าร่วมหลังวันเริ่มต้น';

  @override
  String get got_it => 'เข้าใจแล้ว';

  @override
  String get plan_no_tasks_error => 'ไม่สามารถโหลดรายการได้';

  @override
  String get plan_day_tasks_load_error => 'ไม่สามารถโหลดรายการได้';

  @override
  String get plans_empty_title => 'กำลังมีเพิ่มอีก';

  @override
  String get plans_empty_subtitle =>
      'คลังของเรากำลังเติบโต แวะกลับมาเร็ว ๆ นี้';

  @override
  String get find_plans_load_error =>
      'ไม่สามารถโหลดได้\nตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';

  @override
  String get connect_coming_soon_subtitle =>
      'ครูบาอาจารย์ ชุมชน ความท้าทาย และกิจกรรมที่จะช่วยสนับสนุนคุณบนเส้นทางธรรม';

  @override
  String get connect_subtitle => 'ค้นหากลุ่มและปฏิบัติร่วมกัน';

  @override
  String get discover_groups => 'ค้นพบกลุ่ม';

  @override
  String get my_groups => 'กลุ่มของฉัน';

  @override
  String get see_all => 'ดูทั้งหมด';

  @override
  String get connect_groups_load_error =>
      'ไม่สามารถโหลดกลุ่มได้\nตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';

  @override
  String get connect_groups_empty_title => 'ไม่มีกลุ่มเพิ่มเติม';

  @override
  String get connect_groups_empty_subtitle =>
      'ยินดีด้วย คุณเข้าร่วมทุกกลุ่มของเราแล้ว แวะกลับมาอีกนะ กลุ่มใหม่กำลังจะมา...';

  @override
  String get connect_tab_feed => 'ฟีด';

  @override
  String get connect_tab_events => 'กิจกรรม';

  @override
  String get connect_tab_posts => 'โพสต์';

  @override
  String get connect_tab_practices => 'การปฏิบัติ';

  @override
  String get connect_tab_groups => 'กลุ่ม';

  @override
  String get connect_segment_my => 'กลุ่มของคุณ';

  @override
  String get connect_segment_discover => 'ค้นพบ';

  @override
  String get connect_empty_discover_posts => 'ไม่มีโพสต์ให้ค้นพบ';

  @override
  String get connect_empty_discover_events => 'ไม่มีกิจกรรมให้ค้นพบ';

  @override
  String get connect_empty_discover_feed => 'ไม่มีอะไรให้ค้นพบ';

  @override
  String get connect_empty_discover_groups => 'ไม่มีกลุ่มให้ค้นพบ';

  @override
  String get connect_empty_discover_practices => 'ไม่มีการปฏิบัติให้ค้นพบ';

  @override
  String get connect_all_groups => 'กลุ่มทั้งหมด';

  @override
  String get connect_my_empty_feed_title => 'ไม่มีอัปเดตใหม่';

  @override
  String get connect_my_empty_events_title => 'ไม่มีกิจกรรมที่กำลังจะมาถึง';

  @override
  String get connect_my_empty_posts_title => 'ยังไม่มีโพสต์';

  @override
  String get connect_my_empty_groups_title => 'ยังไม่มีกลุ่ม';

  @override
  String get connect_my_empty_feed_subtitle =>
      'กลุ่มของคุณยังไม่ได้แชร์อะไรใหม่';

  @override
  String get connect_my_empty_events_subtitle =>
      'กลุ่มของคุณยังไม่ได้กำหนดกิจกรรมใด ๆ';

  @override
  String get connect_my_empty_posts_subtitle => 'กลุ่มของคุณยังไม่ได้โพสต์อะไร';

  @override
  String get connect_my_empty_groups_subtitle =>
      'คุณยังไม่ได้เข้าร่วมกลุ่มใด ค้นหากลุ่มเพื่อปฏิบัติร่วมกัน';

  @override
  String get connect_my_empty_feed_browse => 'ดูว่ากลุ่มอื่นแชร์อะไรบ้าง';

  @override
  String get connect_my_empty_events_browse => 'เลือกดูกิจกรรมที่เปิดอยู่';

  @override
  String get connect_my_empty_posts_browse => 'เลือกดูโพสต์อื่น ๆ';

  @override
  String get connect_my_empty_practices_title => 'ยังไม่มีการปฏิบัติ';

  @override
  String get connect_my_empty_practices_subtitle =>
      'กลุ่มของคุณยังไม่ได้เริ่มการปฏิบัติใด ๆ';

  @override
  String get connect_my_empty_practices_browse => 'เลือกดูการปฏิบัติอื่น ๆ';

  @override
  String connect_comment_replying_to(String handle) {
    return 'กำลังตอบกลับ @$handle';
  }

  @override
  String get connect_comment_hint => 'คุณคิดอย่างไรกับเรื่องนี้';

  @override
  String get connect_comment_reply_hint => 'เขียนคำตอบกลับ...';

  @override
  String get connect_comment_reply => 'ตอบกลับ';

  @override
  String get connect_comment_delete_title => 'ลบความคิดเห็นใช่ไหม';

  @override
  String get connect_comment_delete_message => 'ความคิดเห็นนี้จะถูกลบอย่างถาวร';

  @override
  String get connect_comment_delete_failed => 'ไม่สามารถลบความคิดเห็นได้';

  @override
  String connect_post_comments_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ความคิดเห็น',
      one: '1 ความคิดเห็น',
    );
    return '$_temp0';
  }

  @override
  String get connect_post_comments_empty =>
      'ยังไม่มีความคิดเห็น มาเริ่มการสนทนากัน';

  @override
  String get connect_caption_more => 'เพิ่มเติม';

  @override
  String get connect_online => 'ออนไลน์';

  @override
  String get connect_ended => 'สิ้นสุดแล้ว';

  @override
  String connect_ended_on(String date) {
    return 'สิ้นสุดเมื่อ $date';
  }

  @override
  String get home_group_events => 'กิจกรรมแนะนำ';

  @override
  String get home_poems => 'บทกวี';

  @override
  String get poems_load_error =>
      'ไม่สามารถโหลดบทกวีได้\nตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';

  @override
  String get poems_empty => 'ยังไม่มีบทกวี แวะกลับมาเร็ว ๆ นี้';

  @override
  String get connect_events_filter_all => 'ทั้งหมด';

  @override
  String get connect_events_filter_in_person => 'ออนไซต์';

  @override
  String get connect_events_filter_empty_online => 'ไม่มีกิจกรรมแบบออนไลน์';

  @override
  String get connect_events_filter_empty_in_person => 'ไม่มีกิจกรรมแบบออนไซต์';

  @override
  String get connect_events_filter_hybrid => 'ไฮบริด';

  @override
  String get connect_events_filter_empty_hybrid => 'ไม่มีกิจกรรมแบบไฮบริด';

  @override
  String get connect_open => 'เปิด';

  @override
  String get connect_event_fallback_title => 'กิจกรรม';

  @override
  String get connect_group_fallback_title => 'กลุ่ม';

  @override
  String get connect_event_enter => 'เข้าสู่กิจกรรม';

  @override
  String get connect_event_participation_prompt => 'คุณจะเข้าร่วมแบบไหน';

  @override
  String get connect_event_practice_in_person => 'ปฏิบัติแบบออนไซต์';

  @override
  String get connect_event_practice_online => 'ปฏิบัติแบบออนไลน์';

  @override
  String get connect_event_view_in_person => 'มุมมองออนไซต์';

  @override
  String get connect_event_view_online => 'มุมมองออนไลน์';

  @override
  String get connect_event_accumulation_online => 'ออนไลน์';

  @override
  String get connect_event_accumulation_in_person => 'ออนไซต์';

  @override
  String get connect_event_has_ended => 'กิจกรรมนี้สิ้นสุดแล้ว';

  @override
  String get connect_event_join_to_practice => 'เข้าร่วมกิจกรรมเพื่อปฏิบัติ';

  @override
  String get connect_event_leave => 'ออกจากกิจกรรม';

  @override
  String get connect_event_leave_confirm_title => 'ออกจากกิจกรรมนี้ใช่ไหม';

  @override
  String connect_event_leave_confirm_message(String title) {
    return 'คุณจะไม่ได้เข้าร่วม $title อีกต่อไป แต่ยังดูกิจกรรมและกลับมาเข้าร่วมใหม่ได้ทุกเมื่อ';
  }

  @override
  String connect_event_participants_attending(int count) {
    return 'ผู้เข้าร่วม $count คน';
  }

  @override
  String connect_event_participants_attended(int count) {
    return 'เข้าร่วม $count คน';
  }

  @override
  String get connect_event_participants_empty => 'ยังไม่มีผู้เข้าร่วม';

  @override
  String get connect_event_organizer => 'ผู้จัด';

  @override
  String get connect_event_tab_videos => 'วิดีโอ';

  @override
  String get connect_event_tab_links => 'ลิงก์';

  @override
  String get connect_event_tab_about => 'เกี่ยวกับ';

  @override
  String get connect_event_links_title => 'รายละเอียดกิจกรรมเพิ่มเติม';

  @override
  String get connect_event_links_empty => 'ยังไม่มีลิงก์';

  @override
  String get connect_event_link_tap_to_join => 'แตะเพื่อเข้าร่วม';

  @override
  String get connect_event_link_open => 'เปิดลิงก์';

  @override
  String get connect_event_date_tba => 'จะประกาศวันที่ภายหลัง';

  @override
  String get connect_event_when => 'เมื่อไร';

  @override
  String get connect_event_where => 'ที่ไหน';

  @override
  String get connect_event_practices => 'การปฏิบัติในกิจกรรม';

  @override
  String get connect_event_tab_accumulations => 'ยอดสะสม';

  @override
  String get connect_event_tab_recitations => 'บทสวด';

  @override
  String get connect_event_add_recitations => 'เพิ่มจำนวนการสวด';

  @override
  String get connect_event_add_recitations_message =>
      'เพิ่มจำนวนการสวดที่คุณทำร่วมกับการถ่ายทอดสดหรือนอกแอปนี้';

  @override
  String get connect_event_every_day => 'ทุกวัน';

  @override
  String connect_event_every_weekday(String weekday) {
    return 'ทุก $weekday';
  }

  @override
  String get connect_event_every_month => 'ทุกเดือน';

  @override
  String connect_event_every_date(String date) {
    return 'ทุกวันที่ $date';
  }

  @override
  String get connect_event_about_empty => 'ยังไม่มีรายละเอียดกิจกรรม';

  @override
  String get search_groups => 'ค้นหากลุ่ม';

  @override
  String get search_for_groups => 'ค้นหากลุ่ม';

  @override
  String get no_groups_found => 'ไม่พบกลุ่มที่ตรงกัน';

  @override
  String get explore_coming_soon_subtitle =>
      'พื้นที่คัดสรรสำหรับค้นพบการปฏิบัติ คำสอน และกิจกรรมของชุมชน';

  @override
  String get learn_coming_soon_subtitle =>
      'แผนการศึกษาส่วนตัวที่ออกแบบให้เข้ากับชีวิตประจำวัน';

  @override
  String get creator_featured_plan => 'แผนการปฏิบัติแนะนำ';

  @override
  String get audio_init_error =>
      'ไม่สามารถเริ่มเครื่องเล่นเสียงได้ ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';

  @override
  String get meditation_audio_load_error =>
      'ไม่สามารถโหลดได้ ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';

  @override
  String get prayer_audio_load_error =>
      'ไม่สามารถโหลดเสียงได้ ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';

  @override
  String get home_no_series_found => 'ไม่พบซีรีส์';

  @override
  String get home_no_tags_found => 'ไม่พบแท็ก';

  @override
  String get home_celebrated_by => 'เฉลิมฉลองโดย: ';

  @override
  String get reader_settings_tooltip => 'การตั้งค่าการอ่าน';

  @override
  String get reader_translate_tooltip => 'แสดงคำแปล';

  @override
  String get reader_translate_unavailable => 'ไม่มีคำแปลสำหรับคัมภีร์นี้';

  @override
  String get reader_font_size_tooltip => 'ขนาดตัวอักษร';

  @override
  String reader_version_title(String language) {
    return 'ฉบับ · $language';
  }

  @override
  String reader_script_title(String language) {
    return 'อักษร · $language';
  }

  @override
  String get reader_versions_load_error => 'ไม่สามารถโหลดฉบับต่าง ๆ ได้';

  @override
  String get reader_scripts_load_error => 'โหลดอักษรไม่สำเร็จ';

  @override
  String get reader_languages_load_error => 'ไม่สามารถโหลดภาษาได้';

  @override
  String reader_no_versions_in_language(String language) {
    return 'ไม่มีฉบับสำหรับ $language';
  }

  @override
  String reader_no_scripts_in_language(String language) {
    return 'ไม่มีอักษรให้เลือกสำหรับ $language';
  }

  @override
  String get reader_no_languages => 'ไม่มีภาษาให้เลือกสำหรับคัมภีร์นี้';

  @override
  String get reader_license => 'สัญญาอนุญาต';

  @override
  String get reader_version_details_load_error =>
      'ไม่สามารถโหลดรายละเอียดฉบับได้';

  @override
  String get reader_no_version_info => 'ไม่มีข้อมูลเพิ่มเติมสำหรับฉบับนี้';

  @override
  String get recitation_unavailable =>
      'ขณะนี้ไม่มีเนื้อหาบทสวด\nลองอีกครั้งในภายหลังหรือติดต่อฝ่ายสนับสนุน';

  @override
  String get recitation_sign_in_required => 'เข้าสู่ระบบเพื่อเข้าถึงบทสวดนี้';

  @override
  String get my_recitations_load_error =>
      'ไม่สามารถโหลดได้\nตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';

  @override
  String get recitations_load_error =>
      'ไม่สามารถโหลดบทสวดได้\nลองอีกครั้งในภายหลัง';

  @override
  String get text_search_hint => 'พิมพ์เพื่อค้นหา';

  @override
  String get text_search_press_button => 'กดปุ่มค้นหาเพื่อเริ่มค้นหา';

  @override
  String get text_search_error => 'ไม่สามารถค้นหาได้\nโปรดลองอีกครั้ง';

  @override
  String get unknown_error => 'ข้อผิดพลาดที่ไม่ทราบสาเหตุ';

  @override
  String get create_image_share_error => 'ไม่สามารถแชร์ได้ โปรดลองอีกครั้ง';

  @override
  String version_search_no_results(String query) {
    return 'ไม่พบฉบับสำหรับ \"$query\"';
  }

  @override
  String get my_plans_sign_in_prompt => 'เข้าสู่ระบบเพื่อดูแผนการปฏิบัติของคุณ';

  @override
  String plan_starts_soon_message(String date) {
    return 'เริ่มวันที่ $date คุณดูเนื้อหาได้แล้วตอนนี้';
  }

  @override
  String plan_joining_late_message(String date) {
    return 'เริ่มเมื่อ $date คุณทำรายการของวันก่อนหน้าย้อนหลังได้';
  }

  @override
  String get select_language => 'เลือกภาษา';

  @override
  String get logout_confirmation => 'ต้องการออกจากระบบใช่ไหม';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get copy => 'คัดลอก';

  @override
  String get copied => 'คัดลอกแล้ว';

  @override
  String get share => 'แชร์';

  @override
  String get bookmark => 'บุ๊กมาร์ก';

  @override
  String get collection_audio_versions => 'ฉบับเสียง';

  @override
  String get image => 'ภาพ';

  @override
  String get feedback => 'ส่งข้อเสนอแนะ';

  @override
  String get author => 'ผู้เขียน';

  @override
  String get plans_created => 'แผนการปฏิบัติที่สร้าง';

  @override
  String get ai_confirm => 'ยืนยัน';

  @override
  String search_no_results(String query) {
    return 'ไม่พบผลลัพธ์สำหรับ \"$query\"';
  }

  @override
  String get search_all => 'ทั้งหมด';

  @override
  String get common_ok => 'ตกลง';

  @override
  String get comingSoonHeadline => 'เร็ว ๆ นี้';

  @override
  String get routine_title => 'การปฏิบัติของฉัน';

  @override
  String get bookmarks => 'บุ๊กมาร์ก';

  @override
  String get routine_empty_title => 'การปฏิบัติ';

  @override
  String get routine_edit => 'แก้ไข';

  @override
  String get routine_empty_description =>
      'สำรวจคำสอนและการปฏิบัติเพิ่มเติมเพื่อเพิ่มในกิจวัตรของคุณ';

  @override
  String get routine_build => 'สร้างกิจวัตรของคุณ';

  @override
  String get routine_add_session => 'เพิ่มในช่วงเวลา';

  @override
  String get routine_edit_title => 'แก้ไขกิจวัตรของคุณ';

  @override
  String get routine_delete_block => 'นำช่วงเวลาออก';

  @override
  String get routine_session_title_hint => 'ชื่อ...';

  @override
  String get routine_expand_all => 'ขยายทั้งหมด';

  @override
  String get routine_collapse_all => 'ยุบทั้งหมด';

  @override
  String get routine_delete_time_block => 'นำช่วงเวลาออก';

  @override
  String get routine_add_plan => 'เพิ่มแผนการปฏิบัติ';

  @override
  String get routine_add_recitation => 'เพิ่มบทสวด';

  @override
  String get routine_add_plan_to_routine => 'เพิ่มในกิจวัตร';

  @override
  String get routine_load_error =>
      'ไม่สามารถโหลดได้ ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';

  @override
  String get routine_empty_block_title_singular => 'ช่วงเวลาว่าง';

  @override
  String routine_empty_block_title_plural(int count) {
    return 'ช่วงเวลาว่าง ($count)';
  }

  @override
  String get routine_empty_block_message_singular =>
      'ช่วงเวลานี้ว่างอยู่ จะเพิ่มรายการ หรือนำออกจากกิจวัตรของคุณ';

  @override
  String routine_empty_block_message_plural(int count) {
    return 'มีช่วงเวลาว่าง $count ช่วง จะเพิ่มรายการ หรือนำออกจากกิจวัตรของคุณ';
  }

  @override
  String get routine_empty_block_add_items => 'เพิ่มรายการ';

  @override
  String get routine_empty_block_delete_singular => 'นำช่วงเวลาออก';

  @override
  String get routine_empty_block_delete_plural => 'นำช่วงเวลาออก';

  @override
  String get routine_notification_title => 'ทำให้การปฏิบัติเป็นนิสัย';

  @override
  String get routine_notification_description =>
      'อนุญาตการแจ้งเตือนเพื่อให้เราเตือนคุณให้ปฏิบัติ';

  @override
  String get routine_notification_enable => 'เปิดการแจ้งเตือน';

  @override
  String get routine_notification_skip => 'ข้าม';

  @override
  String routine_time_adjusted(String time, int gap) {
    return 'ปรับเป็น $time แล้ว (ต้องห่างกันอย่างน้อย $gap นาที)';
  }

  @override
  String get routine_add_block_label => 'ช่วงเวลา';

  @override
  String get continueWithGoogle => 'ดำเนินการต่อด้วย Google';

  @override
  String get continueWithApple => 'ดำเนินการต่อด้วย Apple';

  @override
  String get continueWithPhone => 'ดำเนินการต่อด้วยเบอร์โทรศัพท์';

  @override
  String get continueAsGuest => 'ดำเนินการต่อในฐานะผู้เยี่ยมชม';

  @override
  String get exploreAsGuest => 'สำรวจในฐานะผู้เยี่ยมชม';

  @override
  String get signIn => 'เข้าสู่ระบบ';

  @override
  String get profileError => 'โหลดโปรไฟล์ไม่สำเร็จ';

  @override
  String get profileTitle => 'โปรไฟล์';

  @override
  String get notLoggedIn => 'ยังไม่ได้เข้าสู่ระบบ';

  @override
  String get retry => 'ลองอีกครั้ง';

  @override
  String get back => 'กลับ';

  @override
  String get delete => 'ลบ';

  @override
  String get close => 'ปิด';

  @override
  String get tryAgain => 'ลองอีกครั้ง';

  @override
  String get pleaseTryAgain => 'โปรดลองอีกครั้ง';

  @override
  String get error => 'ข้อผิดพลาด';

  @override
  String get anonymous => 'ไม่ระบุชื่อ';

  @override
  String get noContentAvailable => 'ไม่มีเนื้อหา';

  @override
  String get unableToLoad =>
      'ไม่สามารถโหลดได้ ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';

  @override
  String get somethingWrong =>
      'เกิดข้อผิดพลาด ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';

  @override
  String get source => 'แหล่งที่มา';

  @override
  String get searchResults => 'ผลการค้นหา';

  @override
  String get noTasks => 'ไม่มีรายการที่ต้องทำ';

  @override
  String get taskNotFound => 'ไม่พบรายการ';

  @override
  String get updateTaskError => 'ไม่สามารถอัปเดตสถานะรายการได้';

  @override
  String get enrollError =>
      'ไม่สามารถลงทะเบียนได้ ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';

  @override
  String unenrollSuccess(String planTitle) {
    return 'ยกเลิกการลงทะเบียน $planTitle แล้ว';
  }

  @override
  String get unenrollError =>
      'ไม่สามารถยกเลิกการลงทะเบียนได้ ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';

  @override
  String get unenrollGenericError =>
      'เกิดข้อผิดพลาด ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';

  @override
  String get notFound => 'รายการนี้ไม่มีอยู่แล้ว แก้ไขกิจวัตรของคุณเพื่ออัปเดต';

  @override
  String get noTimeSlot => 'ไม่มีช่วงเวลาว่าง ลองนำช่วงเวลาบางช่วงออกก่อน';

  @override
  String maxBlocks(int max) {
    return 'ถึงจำนวนช่วงเวลาสูงสุด $max ช่วงแล้ว';
  }

  @override
  String get duplicateItem => 'รายการนี้อยู่ในช่วงเวลานี้แล้ว';

  @override
  String get removeItem => 'นำรายการออกใช่ไหม';

  @override
  String removeConfirmation(String itemName) {
    return '\"$itemName\" จะถูกนำออกจากช่วงเวลานี้';
  }

  @override
  String shareError(String error) {
    return 'ไม่สามารถแชร์ได้ โปรดลองอีกครั้ง';
  }

  @override
  String get updateOrderError => 'ไม่สามารถอัปเดตลำดับได้ โปรดลองอีกครั้ง';

  @override
  String get loadFailed =>
      'ไม่สามารถโหลดได้ ตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';

  @override
  String get captureError => 'บันทึกภาพคิวอาร์โค้ดไม่สำเร็จ โปรดลองอีกครั้ง';

  @override
  String get qrShareError => 'ไม่สามารถแชร์คิวอาร์โค้ดได้ ลองอีกครั้งในภายหลัง';

  @override
  String errorDetail(String error) {
    return 'ข้อผิดพลาด: $error';
  }

  @override
  String missedDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ขาด $count วัน',
      one: 'ขาด 1 วัน',
      zero: 'ขาด 0 วัน',
    );
    return '$_temp0';
  }

  @override
  String get plan_status_on_track => 'เป็นไปตามแผน!';

  @override
  String get start_now => 'เริ่มเลย';

  @override
  String get plan_enroll => 'ลงทะเบียน';

  @override
  String get show_second_version => 'แสดงฉบับที่สอง';

  @override
  String get enable_add_msg =>
      'เปิดเพื่อเพิ่มคำแปลหรือคำถอดเสียงคู่กับข้อความหลัก';

  @override
  String get main_version => 'ฉบับหลัก';

  @override
  String get second_version => 'ฉบับที่สอง';

  @override
  String get second_version_msg => 'ฉบับที่สองจะแสดงใต้แต่ละบทของข้อความหลัก';

  @override
  String get root_text => 'คัมภีร์หลัก';

  @override
  String get version => 'ฉบับ';

  @override
  String get parallel_version => 'ฉบับคู่ขนาน';

  @override
  String get reader_languages_title => 'ภาษา';

  @override
  String get reader_sections_title => 'หัวข้อ';

  @override
  String get reader_original_label => 'ต้นฉบับ';

  @override
  String get reader_translation_label => 'คำแปล';

  @override
  String get version_not_available => 'ไม่มีให้ใช้งาน';

  @override
  String get read_full_text => 'อ่านฉบับเต็ม';

  @override
  String get reader_source_label => 'แหล่งที่มา';

  @override
  String get reader_license_label => 'สัญญาอนุญาต';

  @override
  String series_stats(int planCount, int totalDays) {
    return '$planCount บท · $totalDays วัน';
  }

  @override
  String get force_update_title => 'จำเป็นต้องอัปเดต';

  @override
  String get force_update_message =>
      'แอปมีเวอร์ชันใหม่แล้ว โปรดอัปเดตเพื่อใช้งานต่อ';

  @override
  String get force_update_button => 'อัปเดตเลย';

  @override
  String get settings_section_personalisation => 'การปรับแต่ง';

  @override
  String get settings_section_more => 'เพิ่มเติม';

  @override
  String get settings_section_account => 'บัญชี';

  @override
  String get settings_edit_profile => 'แก้ไขโปรไฟล์';

  @override
  String get settings_theme => 'ธีม';

  @override
  String get settings_notification_row => 'การแจ้งเตือน';

  @override
  String get settings_feedback_row => 'ข้อเสนอแนะ';

  @override
  String get edit_profile_title => 'แก้ไขโปรไฟล์';

  @override
  String get edit_profile_save => 'บันทึก';

  @override
  String get edit_profile_first_name => 'ชื่อ';

  @override
  String get edit_profile_last_name => 'นามสกุล';

  @override
  String get edit_profile_display_name => 'ชื่อที่แสดง';

  @override
  String get edit_profile_bio => 'แนะนำตัว';

  @override
  String get edit_profile_bio_hint => 'เล่าเกี่ยวกับตัวคุณสักเล็กน้อย';

  @override
  String get edit_profile_delete_account => 'ลบบัญชี';

  @override
  String get edit_profile_photo_not_uploaded => 'ยังไม่ได้อัปโหลดรูปภาพ';

  @override
  String get edit_profile_photo_too_large =>
      'รูปภาพมีขนาดใหญ่เกินไป โปรดเลือกรูปที่มีขนาดไม่เกิน 1 MB แล้วลองอีกครั้ง';

  @override
  String get edit_profile_photo_upload_failed =>
      'อัปโหลดรูปภาพไม่สำเร็จ โปรดลองอีกครั้ง';

  @override
  String get edit_profile_choose_from_library => 'เลือกจากคลังภาพ';

  @override
  String get edit_profile_take_photo => 'ถ่ายรูป';

  @override
  String get edit_profile_offline =>
      'คุณออฟไลน์อยู่ เชื่อมต่ออินเทอร์เน็ตแล้วลองอีกครั้ง';

  @override
  String get edit_profile_save_failed =>
      'บันทึกการเปลี่ยนแปลงไม่สำเร็จ โปรดลองอีกครั้ง';

  @override
  String get edit_profile_traditions => 'สายการปฏิบัติ';

  @override
  String get edit_profile_choose_traditions => 'เลือกสายการปฏิบัติของคุณ';

  @override
  String get edit_profile_tradition_remove_failed =>
      'ลบสายการปฏิบัติไม่สำเร็จ โปรดลองอีกครั้ง';

  @override
  String get edit_profile_tradition_save_failed =>
      'บันทึกสายการปฏิบัติไม่สำเร็จ โปรดลองอีกครั้ง';

  @override
  String get username_label => 'ชื่อผู้ใช้';

  @override
  String get username_taken => 'ชื่อนี้มีผู้ใช้แล้ว';

  @override
  String get username_available_label => 'ใช้ได้:';

  @override
  String get username_check_error =>
      'ไม่สามารถตรวจสอบชื่อผู้ใช้ได้ ลองอีกครั้ง';

  @override
  String get username_invalid_format => 'รูปแบบชื่อผู้ใช้ไม่ถูกต้อง';

  @override
  String get username_min_length => 'ชื่อผู้ใช้ต้องมีอย่างน้อย 3 ตัวอักษร';

  @override
  String get username_max_length => 'ชื่อผู้ใช้ต้องไม่เกิน 30 ตัวอักษร';

  @override
  String get username_no_spaces => 'ชื่อผู้ใช้ต้องไม่มีช่องว่าง';

  @override
  String get username_invalid_chars => 'ใช้ได้เฉพาะตัวอักษร ตัวเลข และ _ . -';

  @override
  String get username_must_start_alphanumeric =>
      'ชื่อผู้ใช้ต้องขึ้นต้นด้วยตัวอักษรหรือตัวเลข';

  @override
  String get username_must_end_alphanumeric =>
      'ชื่อผู้ใช้ต้องลงท้ายด้วยตัวอักษรหรือตัวเลข';

  @override
  String get person_name_min_length => 'ต้องมีอย่างน้อย 1 ตัวอักษร';

  @override
  String get person_name_max_length => 'ต้องไม่เกิน 50 ตัวอักษร';

  @override
  String get person_name_invalid_chars =>
      'ใช้ได้เฉพาะตัวอักษร ช่องว่าง ขีดกลาง และอะพอสทรอฟี';

  @override
  String get about_title => 'เกี่ยวกับ';

  @override
  String get about_connect_with_us => 'ติดตามเราได้ที่...';

  @override
  String get about_description =>
      'เราช่วยให้ชาวพุทธเบียดเบียนน้อยลง ทำความดีมากขึ้น และรู้จักจิตใจของตนเองดียิ่งขึ้น ผ่านการเรียนรู้ การปฏิบัติ และการเชื่อมโยงกันทุกวัน';

  @override
  String get about_social_website => 'เว็บไซต์';

  @override
  String get me_guest_headline => 'ใช้งานได้เต็มรูปแบบ';

  @override
  String get me_guest_subtitle => 'สร้างบัญชีฟรีเพื่อบันทึกความคืบหน้า';

  @override
  String get me_my_stats => 'สถิติของฉัน';

  @override
  String me_day_streak(int count) {
    return 'ต่อเนื่อง $count วัน';
  }

  @override
  String me_best_streak(int count) {
    return 'ต่อเนื่องนานที่สุด: $count วัน';
  }

  @override
  String get accumulations => 'ยอดสะสม';

  @override
  String get accumulations_search => 'ค้นหายอดสะสม...';

  @override
  String get accumulations_search_for => 'ค้นหายอดสะสม';

  @override
  String get accumulations_no_found => 'ไม่พบยอดสะสม';

  @override
  String get me_accumulation => 'ยอดสะสมทั้งหมด';

  @override
  String get me_counts => 'ครั้ง';

  @override
  String get me_minutes => 'นาที';

  @override
  String get me_hours => 'ชั่วโมง';

  @override
  String get me_total_meditation_time => 'เวลาทำสมาธิทั้งหมด';

  @override
  String get me_days_plan_practiced_suffix => 'วันที่ทำตามแผนการปฏิบัติครบ';

  @override
  String me_streak_share_message(int count, String appName) {
    return 'ฉันปฏิบัติต่อเนื่องมา $count วันแล้วบน $appName!';
  }

  @override
  String get me_streak_share_quote =>
      'สถิติต่อเนื่องปัจจุบันของฉันบน WeBuddhist!';

  @override
  String me_streak_days_count(int count) {
    return '$count วัน';
  }

  @override
  String get share_this_streak => 'แชร์สถิติต่อเนื่องของฉัน';

  @override
  String get me_streak_share_error =>
      'ไม่สามารถแชร์สถิติต่อเนื่องได้ โปรดลองอีกครั้ง';

  @override
  String get delete_account_title => 'ลบบัญชี';

  @override
  String get delete_account_description =>
      'หากลบบัญชี ข้อมูล ประวัติ และการตั้งค่าส่วนตัวทั้งหมดของคุณบน WeBuddhist จะถูกลบอย่างถาวร โปรดทราบว่าการดำเนินการนี้ไม่สามารถย้อนกลับได้ หากต้องการดำเนินการต่อ ให้แตะปุ่มด้านล่าง';

  @override
  String get delete_account_button => 'ลบบัญชี';

  @override
  String get delete_account_confirm_message =>
      'ต้องการลบบัญชี WeBuddhist ของคุณใช่ไหม';

  @override
  String get legal_title => 'ข้อกฎหมาย';

  @override
  String get legal_terms_of_service => 'ข้อกำหนดในการให้บริการ';

  @override
  String get legal_privacy_policy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get follow => 'ติดตาม';

  @override
  String get calendar_title => 'ปฏิทิน';

  @override
  String get calendar_upcoming_events => 'กิจกรรมที่กำลังจะมาถึง';

  @override
  String get calendar_day_short => 'วัน';

  @override
  String get calendar_day_label => 'วัน';

  @override
  String calendar_day_month(int day, int month) {
    return 'วันที่ $day · เดือน $month';
  }

  @override
  String calendar_lunar_month(String ordinal) {
    return 'เดือน $ordinal ตามจันทรคติ';
  }

  @override
  String get moon_phase_new_moon => 'จันทร์ดับ';

  @override
  String get moon_phase_waxing_crescent => 'จันทร์เสี้ยวข้างขึ้น';

  @override
  String get moon_phase_first_quarter => 'จันทร์ครึ่งดวงข้างขึ้น';

  @override
  String get moon_phase_waxing_gibbous => 'จันทร์ค่อนดวงข้างขึ้น';

  @override
  String get moon_phase_full_moon => 'จันทร์เพ็ญ';

  @override
  String get moon_phase_waning_gibbous => 'จันทร์ค่อนดวงข้างแรม';

  @override
  String get moon_phase_last_quarter => 'จันทร์ครึ่งดวงข้างแรม';

  @override
  String get moon_phase_waning_crescent => 'จันทร์เสี้ยวข้างแรม';

  @override
  String get join => 'เข้าร่วม';

  @override
  String get group_member => 'สมาชิก';

  @override
  String get group_members => 'สมาชิก';

  @override
  String get group_tab_members => 'สมาชิก';

  @override
  String get group_tab_followers => 'ผู้ติดตาม';

  @override
  String group_members_heading(int count) {
    return 'สมาชิก ($count)';
  }

  @override
  String group_followers_heading(int count) {
    return 'ผู้ติดตาม ($count)';
  }

  @override
  String get group_invite => 'เชิญ';

  @override
  String get group_notifications_title => 'การแจ้งเตือน';

  @override
  String get group_notifications_chat => 'แชทของกลุ่ม';

  @override
  String get group_notifications_content => 'เนื้อหาของกลุ่ม';

  @override
  String get group_notifications_master_off => 'การแจ้งเตือนของแอปปิดอยู่';

  @override
  String get group_notifications_open_settings => 'เปิด';

  @override
  String get group_notifications_update_failed =>
      'อัปเดตการตั้งค่าการแจ้งเตือนไม่สำเร็จ ลองอีกครั้ง';

  @override
  String get group_notifications_load_failed =>
      'โหลดการตั้งค่าการแจ้งเตือนไม่สำเร็จ';

  @override
  String get group_chat_mute_notifications => 'ปิดเสียงการแจ้งเตือนแชท';

  @override
  String get group_chat_unmute_notifications => 'เปิดเสียงการแจ้งเตือนแชท';

  @override
  String get group_chat_notifications_muted => 'ปิดเสียงการแจ้งเตือนแชทแล้ว';

  @override
  String get group_chat_notifications_unmuted => 'เปิดการแจ้งเตือนแชทแล้ว';

  @override
  String get group_leave_confirm_message =>
      'คุณจะไม่ได้รับข้อความและอัปเดตจากกลุ่มนี้อีก';

  @override
  String get group_leave_space => 'ออกจากกลุ่ม';

  @override
  String get group_leave_space_confirm_title => 'ออกจากกลุ่มนี้ใช่ไหม';

  @override
  String get group_leave_space_failed => 'ออกจากกลุ่มไม่สำเร็จ ลองอีกครั้ง';

  @override
  String get group_request_to_join => 'ขอเข้าร่วม';

  @override
  String get group_request => 'ขอเข้าร่วม';

  @override
  String get group_request_sent => 'ส่งคำขอแล้ว';

  @override
  String get group_join_request_title => 'ขอเข้าร่วม';

  @override
  String get group_join_request_message_label => 'ข้อความ (ไม่บังคับ)';

  @override
  String get group_join_request_message_hint =>
      'คุณปฏิบัติอย่างไร หรือใครเป็นผู้เชิญคุณ';

  @override
  String get group_join_request_send => 'ส่งคำขอ';

  @override
  String get group_join_request_sent_snackbar =>
      'ส่งคำขอแล้ว ผู้ดูแลจะพิจารณาคำขอของคุณ';

  @override
  String get group_join_request_error => 'ไม่สามารถส่งคำขอได้ โปรดลองอีกครั้ง';

  @override
  String get group_join_requests_title => 'คำขอเข้าร่วม';

  @override
  String get group_join_requests_admit => 'รับเข้า';

  @override
  String get group_join_requests_deny => 'ปฏิเสธ';

  @override
  String get group_join_requests_empty => 'ไม่มีคำขอที่รอดำเนินการ';

  @override
  String get group_join_requests_load_error =>
      'ไม่สามารถโหลดคำขอเข้าร่วมได้ โปรดลองอีกครั้ง';

  @override
  String get group_join_requests_admit_error =>
      'ไม่สามารถรับคำขอนี้ได้ โปรดลองอีกครั้ง';

  @override
  String get group_join_requests_deny_error =>
      'ไม่สามารถปฏิเสธคำขอนี้ได้ โปรดลองอีกครั้ง';

  @override
  String get group_reports_title => 'รายงาน';

  @override
  String get group_reports_section_posts => 'โพสต์';

  @override
  String get group_reports_section_comments => 'ความคิดเห็น';

  @override
  String get group_reports_section_messages => 'ข้อความ';

  @override
  String group_reports_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รายงาน',
      one: '1 รายงาน',
    );
    return '$_temp0';
  }

  @override
  String get group_reports_view_post => 'ดูโพสต์';

  @override
  String get group_reports_view_message => 'ดูข้อความ';

  @override
  String get group_reports_delete_post => 'ลบโพสต์';

  @override
  String get group_reports_delete_comment => 'ลบความคิดเห็น';

  @override
  String get group_reports_delete_message => 'ลบข้อความ';

  @override
  String get group_reports_empty => 'ไม่มีรายงานให้ตรวจสอบ';

  @override
  String get group_reports_load_error =>
      'ไม่สามารถโหลดรายงานได้ โปรดลองอีกครั้ง';

  @override
  String get group_reports_delete_confirm_title => 'แน่ใจหรือไม่';

  @override
  String get group_reports_delete_message_confirm =>
      'ข้อความนี้จะถูกลบอย่างถาวร';

  @override
  String get group_reports_message_removed => 'นำข้อความออกแล้ว';

  @override
  String get group_reports_delete_message_error =>
      'ไม่สามารถลบข้อความได้ โปรดลองอีกครั้ง';

  @override
  String get group_members_only_title => 'เฉพาะสมาชิก';

  @override
  String get group_members_only_message => 'เข้าร่วมกลุ่มนี้เพื่อดูเนื้อหา';

  @override
  String get group_join_request_waiting_title => 'รอผู้ดูแลพิจารณา';

  @override
  String get group_join_request_waiting_message =>
      'เราจะแจ้งให้ทราบเมื่อคำขอของคุณได้รับการพิจารณา';

  @override
  String get group_members_load_error =>
      'ไม่สามารถโหลดสมาชิกได้ โปรดลองอีกครั้ง';

  @override
  String get group_followers_load_error =>
      'ไม่สามารถโหลดผู้ติดตามได้ โปรดลองอีกครั้ง';

  @override
  String get group_members_empty => 'ยังไม่มีสมาชิก';

  @override
  String get group_member_admin => 'ผู้ดูแล';

  @override
  String get group_member_owner => 'เจ้าของ';

  @override
  String group_remove_member(String name) {
    return 'นำ $name ออก';
  }

  @override
  String get group_remove_member_title => 'นำออกจากกลุ่มใช่ไหม';

  @override
  String group_remove_member_message(String name) {
    return '$name จะถูกนำออกจากกลุ่มนี้ และเข้าร่วมใหม่ไม่ได้จนกว่าการระงับจะสิ้นสุด';
  }

  @override
  String get group_remove_member_blocked_for => 'ระงับเป็นเวลา:';

  @override
  String get group_remove_member_duration_day => '1 วัน';

  @override
  String group_remove_member_duration_days(int count) {
    return '$count วัน';
  }

  @override
  String get group_remove_member_duration_year => '1 ปี';

  @override
  String get group_remove_member_reason_label => 'เหตุผล (ไม่บังคับ)';

  @override
  String get group_remove_member_reason_hint => 'อื่น ๆ...';

  @override
  String get group_remove_member_action => 'นำออก';

  @override
  String group_remove_member_success(String name) {
    return 'นำ $name ออกจากกลุ่มแล้ว';
  }

  @override
  String get group_remove_member_error =>
      'นำสมาชิกคนนี้ออกไม่สำเร็จ ลองอีกครั้ง';

  @override
  String group_join_banned_until(String date) {
    return 'คุณถูกนำออกจากกลุ่มนี้ และเข้าร่วมใหม่ไม่ได้จนถึง $date';
  }

  @override
  String get group_join_banned =>
      'คุณถูกนำออกจากกลุ่มนี้ และเข้าร่วมใหม่ไม่ได้จนกว่าการระงับจะสิ้นสุด';

  @override
  String get group_removed_title => 'คุณถูกนำออกจากกลุ่มนี้';

  @override
  String group_removed_message(String group, String duration) {
    return 'ผู้ดูแลจาก $group ได้นำคุณออกจากกลุ่มนี้ คุณจะไม่สามารถดูโพสต์ กิจกรรม และการปฏิบัติของกลุ่ม หรือขอเข้าร่วมใหม่ได้เป็นเวลา $duration';
  }

  @override
  String group_removed_message_no_date(String group) {
    return 'ผู้ดูแลจาก $group ได้นำคุณออกจากกลุ่มนี้ คุณจะไม่สามารถดูโพสต์ กิจกรรม และการปฏิบัติของกลุ่ม หรือขอเข้าร่วมใหม่ได้';
  }

  @override
  String get group_removed_rejoin_label =>
      'คุณขอเข้าร่วมกลุ่มนี้ได้อีกครั้งในวันที่';

  @override
  String group_removed_rejoin_value(String date, String remaining) {
    return '$date · $remaining';
  }

  @override
  String get group_removed_day_left => 'เหลืออีก 1 วัน';

  @override
  String group_removed_days_left(int count) {
    return 'เหลืออีก $count วัน';
  }

  @override
  String get group_removed_last_day => 'เหลือไม่ถึง 1 วัน';

  @override
  String get group_followers_empty => 'ยังไม่มีผู้ติดตาม';

  @override
  String get group_follower => 'ผู้ติดตาม';

  @override
  String get group_followers => 'ผู้ติดตาม';

  @override
  String get group_links_title => 'ลิงก์';

  @override
  String get group_about_description => 'คำอธิบาย';

  @override
  String get group_about_empty => 'ยังไม่มีข้อมูล';

  @override
  String group_and_more_links(int count) {
    return 'และอีก $count ลิงก์';
  }

  @override
  String get group_practice_with_us => 'มาปฏิบัติร่วมกับเรา';

  @override
  String series_practicing_with_group(String groupName) {
    return 'ปฏิบัติร่วมกับ $groupName';
  }

  @override
  String get group_change_practice_title => 'เปลี่ยนกลุ่มปฏิบัติ';

  @override
  String get group_change_practice_message =>
      'คุณกำลังปฏิบัติแผนนี้กับกลุ่มอื่นอยู่แล้ว ต้องการเปลี่ยนกลุ่มที่ปฏิบัติด้วยไหม';

  @override
  String get group_join_to_contribute => 'เข้าร่วมเพื่อมีส่วนร่วม';

  @override
  String get group_accumulator_join_error =>
      'ไม่สามารถเข้าร่วมยอดสะสมได้ โปรดลองอีกครั้ง';

  @override
  String get group_accumulator_join_before_practice =>
      'เข้าร่วมยอดสะสมนี้ก่อนเพิ่มลงในการปฏิบัติของคุณ';

  @override
  String group_accumulator_participants(int count) {
    return 'ผู้เข้าร่วม $count คน';
  }

  @override
  String get group_accumulator_leaderboard => 'อันดับ';

  @override
  String get group_accumulator_my_contributions => 'ยอดที่ฉันร่วมสวด';

  @override
  String get group_accumulator_recited => 'จำนวนที่สวด';

  @override
  String get group_accumulator_total => 'รวม';

  @override
  String get group_accumulator_contributions_empty =>
      'เข้าร่วมยอดสะสมนี้เพื่อติดตามยอดที่คุณร่วมสวด';

  @override
  String get group_accumulator_leaderboard_empty => 'ยังไม่มีการสวด';

  @override
  String get group_accumulator_recite_now => 'สวดเลย';

  @override
  String get group_accumulator_view_practice => 'ดูการปฏิบัติ';

  @override
  String get group_accumulator_chant_again => 'สวดอีกครั้ง';

  @override
  String get group_accumulator_finish_session => 'จบการสวดครั้งนี้';

  @override
  String get group_accumulator_offline_recitation => 'การสวดนอกแอป';

  @override
  String get group_accumulator_add_offline_chants_title => 'เพิ่มการสวดนอกแอป:';

  @override
  String get group_accumulator_add_offline_chants_message =>
      'เพิ่มจำนวนการสวดที่คุณทำนอกแอป';

  @override
  String get group_accumulator_session_complete => 'สวดเสร็จแล้ว!';

  @override
  String group_accumulator_session_recitations(int count) {
    return 'ครั้งนี้คุณสวดได้ $count จบ';
  }

  @override
  String group_accumulator_session_share_message(
    int count,
    String accumulation,
    String group,
  ) {
    return 'ฉันสวดได้ $count จบใน \"$accumulation\" ยอดสะสมของ $group บน WeBuddhist มาร่วมกันเถอะ!';
  }

  @override
  String group_accumulator_session_share_message_no_group(
    int count,
    String accumulation,
  ) {
    return 'ฉันสวดได้ $count จบในยอดสะสม \"$accumulation\" บน WeBuddhist มาร่วมกันเถอะ!';
  }

  @override
  String get group_accumulator_session_share_error =>
      'ไม่สามารถแชร์ได้ โปรดลองอีกครั้ง';

  @override
  String group_recitation_collection_share_message(
    String collection,
    String group,
  ) {
    return 'มาดู \"$collection\" ชุดบทสวดของ $group บน WeBuddhist แล้วมาปฏิบัติร่วมกับเรา!';
  }

  @override
  String group_recitation_collection_share_message_no_group(String collection) {
    return 'มาดูชุดบทสวด \"$collection\" บน WeBuddhist แล้วมาปฏิบัติร่วมกับเรา!';
  }

  @override
  String group_recitation_collection_completed_title(String collection) {
    return 'สวด $collection จบแล้ว';
  }

  @override
  String get group_recitation_collection_dedication =>
      'ด้วยบุญกุศลนี้ ขอสรรพสัตว์ทั้งหลาย\nจงพ้นจากความทุกข์';

  @override
  String get share_this_quote => 'แชร์คำคมนี้';

  @override
  String get shared_from => 'แชร์จาก';

  @override
  String get verse_share_error => 'ไม่สามารถแชร์คำคมได้ โปรดลองอีกครั้ง';

  @override
  String verse_comments_title(int count) {
    return 'ความคิดเห็น · $count';
  }

  @override
  String verse_likes_title(int count) {
    return 'ถูกใจ · $count';
  }

  @override
  String get verse_like_failed => 'ไม่สามารถอัปเดตการถูกใจได้ โปรดลองอีกครั้ง';

  @override
  String get verse_comment_failed =>
      'ไม่สามารถโพสต์ความคิดเห็นได้ โปรดลองอีกครั้ง';

  @override
  String verse_comment_replying_to(String name) {
    return 'กำลังตอบกลับ $name';
  }

  @override
  String get share_app_message =>
      'ฉันใช้แอปนี้เพื่อสร้างการปฏิบัติธรรมประจำวัน และคิดว่าคุณน่าจะชอบ';

  @override
  String get share_streak_message =>
      'ฉันกำลังสร้างนิสัยการปฏิบัติทุกวันและอยากแชร์ให้คุณ การทำต่อเนื่องจะง่ายขึ้นเมื่อมีเพื่อน มาร่วมกับฉันบน WeBuddhist';

  @override
  String get share_chant_message =>
      'อยากแชร์บทสวดนี้ให้คุณ คุณสวดบทนี้และพบคลังบทสวดและคัมภีร์อื่น ๆ อีกมากมายได้บน WeBuddhist';

  @override
  String get share_quote_message =>
      'ฉันชอบคำคมนี้จาก WeBuddhist และอยากแชร์ให้คุณ อ่านคำคมที่ให้แง่คิดดี ๆ เช่นนี้ได้อีกมากในแอป WeBuddhist';

  @override
  String get share_poem_message =>
      'ฉันชอบบทกวีนี้จาก WeBuddhist และอยากแชร์ให้คุณ';

  @override
  String share_poem_title(String title) {
    return '“$title”';
  }

  @override
  String get share_mala_message =>
      'ฉันใช้ลูกประคำดิจิทัลนี้บน WeBuddhist และอยากแชร์ให้คุณ เป็นวิธีง่าย ๆ ในการปฏิบัติได้ทุกที่';

  @override
  String get share_passage_message =>
      'ฉันชอบข้อความตอนนี้และอยากแชร์ให้คุณ อ่านข้อความเต็มพร้อมบริบทได้บน WeBuddhist';

  @override
  String get share_timer_message =>
      'อยากแชร์ตัวจับเวลาทำสมาธินี้จาก WeBuddhist ให้คุณ ช่วยให้สร้างนิสัยการทำสมาธิได้ง่ายขึ้น';

  @override
  String get share_plan_message =>
      'ฉันกำลังปฏิบัติตามแผนการปฏิบัติทางพุทธศาสนานี้และอยากแชร์ให้คุณ มาร่วมกับฉันได้ฟรีบน WeBuddhist';

  @override
  String get share_plan_subject => 'มาร่วมกับฉันบน WeBuddhist';

  @override
  String get share_group_invite_message =>
      'มาเข้าร่วมกลุ่มนี้กับฉัน แล้วมาปฏิบัติร่วมกันบน WeBuddhist!';

  @override
  String get weekday_monday => 'จ.';

  @override
  String get weekday_tuesday => 'อ.';

  @override
  String get weekday_wednesday => 'พ.';

  @override
  String get weekday_thursday => 'พฤ.';

  @override
  String get weekday_friday => 'ศ.';

  @override
  String get weekday_saturday => 'ส.';

  @override
  String get weekday_sunday => 'อา.';

  @override
  String get reader_search_failed => 'ค้นหาไม่สำเร็จ\nโปรดลองอีกครั้ง';

  @override
  String get reader_swipe_up_for_more => 'ปัดขึ้นเพื่อดูเพิ่มเติม';

  @override
  String get reader_videos => 'วิดีโอ';

  @override
  String get reader_about_this_version => 'เกี่ยวกับฉบับนี้';

  @override
  String reader_version_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ฉบับ',
      one: '1 ฉบับ',
    );
    return '$_temp0';
  }

  @override
  String get mala_no_mantras => 'ไม่มีมนต์ให้เลือก';

  @override
  String get mala_count_load_error => 'โหลดจำนวนนับของคุณไม่สำเร็จ';

  @override
  String get mala_mantra_label => 'มนต์';

  @override
  String get bookmarks_empty_all_title => 'ยังไม่มีบุ๊กมาร์ก';

  @override
  String get bookmarks_empty_all_subtitle =>
      'บุ๊กมาร์กสิ่งที่สนใจเพื่อเก็บไว้ที่นี่';

  @override
  String get bookmarks_empty_plans_title =>
      'ยังไม่มีแผนการปฏิบัติที่บุ๊กมาร์กไว้';

  @override
  String get bookmarks_empty_plans_subtitle =>
      'บุ๊กมาร์กรายการที่สนใจเพื่อเก็บไว้ที่นี่';

  @override
  String get bookmarks_empty_malas_title => 'ยังไม่มีลูกประคำที่บุ๊กมาร์กไว้';

  @override
  String get bookmarks_empty_malas_subtitle =>
      'บุ๊กมาร์กรายการที่สนใจเพื่อเก็บไว้ที่นี่';

  @override
  String get bookmarks_empty_group_accumulations_title =>
      'ยังไม่มียอดสะสมของกลุ่มที่บุ๊กมาร์กไว้';

  @override
  String get bookmarks_empty_group_accumulations_subtitle =>
      'บุ๊กมาร์กรายการที่สนใจเพื่อเก็บไว้ที่นี่';

  @override
  String get bookmarks_empty_timers_title =>
      'ยังไม่มีตัวจับเวลาที่บุ๊กมาร์กไว้';

  @override
  String get bookmarks_empty_timers_subtitle =>
      'บุ๊กมาร์กรายการที่สนใจเพื่อเก็บไว้ที่นี่';

  @override
  String get bookmarks_empty_texts_title => 'ยังไม่มีคัมภีร์ที่บุ๊กมาร์กไว้';

  @override
  String get bookmarks_empty_texts_subtitle =>
      'บุ๊กมาร์กรายการที่สนใจเพื่อเก็บไว้ที่นี่';

  @override
  String get bookmark_removed => 'ลบบุ๊กมาร์กแล้ว';

  @override
  String get bookmark_remove_failed => 'ไม่สามารถลบบุ๊กมาร์กได้';

  @override
  String get bookmark_saved => 'บันทึกบุ๊กมาร์กแล้ว';

  @override
  String get bookmark_save_failed => 'ไม่สามารถบันทึกบุ๊กมาร์กได้';

  @override
  String get bookmarks_yesterday => 'เมื่อวาน';

  @override
  String get webview_timeout_error =>
      'หน้าใช้เวลาโหลดนานเกินไป โปรดตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';

  @override
  String get webview_load_failed => 'ไม่สามารถโหลดหน้าได้';

  @override
  String get privacy_policy_load_error =>
      'ไม่สามารถโหลดหน้านโยบายความเป็นส่วนตัวได้';

  @override
  String get terms_of_service_load_error =>
      'ไม่สามารถโหลดหน้าข้อกำหนดในการให้บริการได้';

  @override
  String get series_enroll_error => 'ไม่สามารถลงทะเบียนซีรีส์ได้';

  @override
  String series_share_message(String title, String url) {
    return 'มาร่วมปฏิบัติ $title กับฉันบน WeBuddhist\n\n$url';
  }

  @override
  String get player_back_10 => 'ย้อนกลับ 10 วินาที';

  @override
  String get player_pause => 'หยุดชั่วคราว';

  @override
  String get player_play => 'เล่น';

  @override
  String get player_forward_10 => 'ไปข้างหน้า 10 วินาที';

  @override
  String get player_fullscreen => 'เต็มจอ';

  @override
  String get player_exit_fullscreen => 'ออกจากโหมดเต็มจอ';

  @override
  String get session_plans_load_error =>
      'ไม่สามารถโหลดแผนการปฏิบัติได้\nโปรดลองอีกครั้งในภายหลัง';

  @override
  String get session_chants_load_error => 'ไม่สามารถโหลดบทสวดได้';

  @override
  String get session_no_chants => 'ไม่พบบทสวด';

  @override
  String get session_malas_load_error => 'ไม่สามารถโหลดลูกประคำได้';

  @override
  String get session_no_malas => 'ไม่พบลูกประคำ';

  @override
  String get session_timers_load_error => 'ไม่สามารถโหลดตัวจับเวลาได้';

  @override
  String get session_no_timers => 'ไม่พบตัวจับเวลา';

  @override
  String days_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count วัน',
      one: '1 วัน',
    );
    return '$_temp0';
  }

  @override
  String timer_minute_session(int minutes) {
    return 'ทำสมาธิ $minutes นาที';
  }

  @override
  String get timer_notification_in_progress => 'กำลังทำสมาธิ';

  @override
  String timer_notification_paused(String time) {
    return 'หยุดชั่วคราว · เหลือ $time';
  }

  @override
  String get timer_notification_complete => 'การทำสมาธิเสร็จสิ้นแล้ว';

  @override
  String plan_day_of(int day, int total) {
    return 'วันที่ $day จาก $total';
  }

  @override
  String pagination_position(int current, int total) {
    return '$current จาก $total';
  }

  @override
  String get plan_shorts_title => 'คลิปสั้นจากชุมชน';

  @override
  String get author_details_load_error =>
      'ไม่สามารถโหลดข้อมูลผู้เขียนได้\nโปรดลองอีกครั้ง';

  @override
  String get link_cannot_open => 'ไม่สามารถเปิดลิงก์นี้ได้';

  @override
  String get link_invalid => 'ลิงก์ไม่ถูกต้อง';

  @override
  String get author_no_plans => 'ยังไม่ได้สร้างแผนการปฏิบัติ';

  @override
  String get author_plans_load_error => 'ไม่สามารถโหลดแผนการปฏิบัติได้';

  @override
  String source_with_value(String value) {
    return 'แหล่งที่มา: $value';
  }

  @override
  String license_with_value(String value) {
    return 'สัญญาอนุญาต: $value';
  }

  @override
  String loading_previous_pages(int count) {
    return 'กำลังโหลดก่อนหน้า... ($count หน้า)';
  }

  @override
  String loading_more_pages(int count) {
    return 'กำลังโหลดเพิ่ม... ($count หน้า)';
  }

  @override
  String get drag_to_resize => 'ลากเพื่อปรับขนาด';

  @override
  String get day_completion_share_message =>
      'ฉันเพิ่งปฏิบัติครบอีกหนึ่งวันบน WeBuddhist มาร่วมกันสร้างนิสัยการปฏิบัติทุกวันกันเถอะ';

  @override
  String group_accumulator_share_message(String accumulation, String group) {
    return 'ฉันกำลังร่วม \"$accumulation\" ยอดสะสมของ $group บน WeBuddhist มาร่วมกันเถอะ!';
  }

  @override
  String group_accumulator_share_message_no_group(String accumulation) {
    return 'ฉันกำลังร่วมยอดสะสม \"$accumulation\" บน WeBuddhist มาร่วมกันเถอะ!';
  }

  @override
  String get group_chat_title => 'แชท';

  @override
  String get chats_title => 'แชท';

  @override
  String get chats_empty_title => 'ยังไม่มีแชท';

  @override
  String get chats_empty_body => 'เข้าร่วมกลุ่มเพื่อเริ่มแชท';

  @override
  String get group_chat_inappropriate =>
      'ส่งข้อความนี้ไม่ได้ เนื่องจากมีถ้อยคำที่ไม่อนุญาต';

  @override
  String get group_chat_not_a_member => 'เฉพาะสมาชิกเท่านั้นที่เปิดแชทนี้ได้';

  @override
  String get group_chat_open => 'แชท';

  @override
  String get group_chat_message_hint => 'ข้อความ';

  @override
  String get group_chat_join_to_send => 'เข้าร่วมแชทเพื่อส่งข้อความ';

  @override
  String get group_chat_today => 'วันนี้';

  @override
  String get group_chat_yesterday => 'เมื่อวาน';

  @override
  String get group_chat_empty_title => 'ยังไม่มีข้อความ';

  @override
  String get group_chat_empty_body => 'เริ่มการสนทนากับกลุ่มของคุณ';

  @override
  String get group_chat_load_failed => 'ไม่สามารถโหลดข้อความได้';

  @override
  String get group_chat_message_not_found => 'ข้อความนี้ไม่อยู่ในแชทแล้ว';

  @override
  String get group_chat_message_too_far_back =>
      'ข้อความนี้อยู่ย้อนหลังไปไกลในแชท';

  @override
  String get group_chat_keep_looking => 'ค้นหาต่อ';

  @override
  String get group_chat_retry => 'ลองอีกครั้ง';

  @override
  String get group_chat_unknown_sender => 'สมาชิก';

  @override
  String get group_chat_reactions_all => 'ทั้งหมด';

  @override
  String get group_chat_reacted => 'แสดงความรู้สึกแล้ว';

  @override
  String get group_chat_reply => 'ตอบกลับ';

  @override
  String get group_chat_copy => 'คัดลอก';

  @override
  String get group_chat_copied => 'คัดลอกข้อความแล้ว';

  @override
  String get group_chat_report => 'รายงาน';

  @override
  String get group_chat_report_title => 'คุณรายงานด้วยเหตุผลใด';

  @override
  String get group_chat_report_privacy => 'ชื่อของคุณจะถูกเก็บเป็นความลับ';

  @override
  String get group_chat_report_reason_harassment => 'การคุกคามหรือกลั่นแกล้ง';

  @override
  String get group_chat_report_reason_hate =>
      'ถ้อยคำแสดงความเกลียดชังหรือเป็นอันตราย';

  @override
  String get group_chat_report_reason_sexual => 'เนื้อหาทางเพศหรือโจ่งแจ้ง';

  @override
  String get group_chat_report_reason_spam => 'สแปมหรือหลอกลวง';

  @override
  String get group_chat_report_reason_off_topic => 'นอกเรื่องหรือก่อกวน';

  @override
  String get group_chat_report_reason_other => 'อื่น ๆ';

  @override
  String get group_chat_report_note_title => 'เพิ่มหมายเหตุ';

  @override
  String get group_chat_report_note_hint => 'อื่น ๆ...';

  @override
  String get group_chat_report_submit => 'ส่งรายงาน';

  @override
  String get group_chat_report_thanks => 'ขอบคุณที่แจ้งให้เราทราบ';

  @override
  String get group_chat_report_offline => 'คุณออฟไลน์อยู่ ลองอีกครั้งในภายหลัง';

  @override
  String get group_chat_report_failed => 'ส่งรายงานไม่สำเร็จ';

  @override
  String get group_chat_report_retry => 'ลองอีกครั้ง';

  @override
  String get group_chat_delete => 'ลบ';

  @override
  String get group_chat_delete_title => 'ลบข้อความใช่ไหม';

  @override
  String group_chat_delete_title_many(int count) {
    return 'ลบ $count ข้อความใช่ไหม';
  }

  @override
  String group_chat_delete_confirm_body(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ข้อความเหล่านี้จะถูกลบออกจากแชทสำหรับทุกคน',
      one: 'ข้อความนี้จะถูกลบออกจากแชทสำหรับทุกคน',
    );
    return '$_temp0';
  }

  @override
  String group_chat_delete_failed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ไม่สามารถลบข้อความ $count รายการได้',
      one: 'ไม่สามารถลบข้อความได้',
    );
    return '$_temp0';
  }

  @override
  String group_chat_selection_limit(int count) {
    return 'เลือกได้สูงสุด $count ข้อความ';
  }

  @override
  String get group_chat_message_deleted_by_sender => 'ข้อความนี้ถูกลบแล้ว';

  @override
  String get group_chat_reaction_failed => 'ไม่สามารถบันทึกรีแอ็กชันของคุณได้';

  @override
  String group_chat_reactions_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รีแอ็กชัน',
      one: '1 รีแอ็กชัน',
    );
    return '$_temp0';
  }

  @override
  String get group_chat_you => 'คุณ';

  @override
  String get group_chat_tap_to_remove => 'แตะเพื่อนำออก';

  @override
  String get group_chat_reply_parent_gone =>
      'ข้อความนั้นไม่มีอยู่แล้ว จึงนำข้อความที่อ้างถึงออก ส่งอีกครั้งเพื่อโพสต์ข้อความของคุณ';

  @override
  String get group_tab_posts => 'โพสต์';

  @override
  String get group_tab_events => 'กิจกรรม';

  @override
  String get group_posts_empty_title => 'ยังไม่มีโพสต์';

  @override
  String get group_posts_empty_message => 'แชร์อัปเดตแรกของกลุ่มคุณ';

  @override
  String get group_posts_load_error => 'ไม่สามารถโหลดโพสต์ได้ โปรดลองอีกครั้ง';

  @override
  String get group_post_button => 'โพสต์';

  @override
  String get group_post_new_title => 'โพสต์ใหม่';

  @override
  String get group_post_posting_to => 'โพสต์ไปที่:';

  @override
  String get group_post_caption_hint => 'มีอะไรใหม่บ้าง';

  @override
  String get group_post_photos => 'รูปภาพ';

  @override
  String get group_post_link => 'ลิงก์';

  @override
  String get group_post_discard_title => 'ทิ้งโพสต์นี้ใช่ไหม';

  @override
  String get group_post_discard_message => 'ข้อความที่คุณเขียนไว้จะหายไป';

  @override
  String get group_post_keep_editing => 'แก้ไขต่อ';

  @override
  String get group_post_discard => 'ทิ้ง';

  @override
  String get group_post_add_link_title => 'เพิ่มลิงก์';

  @override
  String get group_post_add_link_hint => 'วางลิงก์ แล้วเราจะแสดงตัวอย่างให้';

  @override
  String get group_post_link_field_hint => 'ลิงก์';

  @override
  String get group_post_attach => 'แนบ';

  @override
  String get group_post_attach_as_link => 'แนบเป็นลิงก์';

  @override
  String get group_post_preview_failed_title => 'โหลดตัวอย่างไม่สำเร็จ';

  @override
  String get group_post_preview_failed_message => 'คุณยังแนบเป็นลิงก์ได้';

  @override
  String get group_post_invalid_link =>
      'กรอกลิงก์ที่ถูกต้อง เช่น https://example.com';

  @override
  String get group_post_in_app_content => 'เนื้อหาในแอป';

  @override
  String get group_post_add_in_app_content_title => 'เพิ่มเนื้อหาในแอป';

  @override
  String get group_post_in_app_content_empty => 'ยังไม่มีอะไรให้เพิ่ม';

  @override
  String group_post_photo_limit(int count) {
    return 'เพิ่มรูปภาพได้สูงสุด $count รูป';
  }

  @override
  String get group_post_upload_error =>
      'ไม่สามารถอัปโหลดรูปภาพได้ โปรดลองอีกครั้ง';

  @override
  String get group_post_publish_error =>
      'ไม่สามารถเผยแพร่โพสต์ได้ โปรดลองอีกครั้ง';

  @override
  String get group_post_published => 'โพสต์ของคุณเผยแพร่แล้ว';

  @override
  String get group_post_delete_title => 'ลบโพสต์ใช่ไหม';

  @override
  String get group_post_delete_message => 'โพสต์นี้จะถูกลบอย่างถาวร';

  @override
  String get group_post_delete_failed => 'ไม่สามารถลบโพสต์ได้ โปรดลองอีกครั้ง';

  @override
  String get edit => 'แก้ไข';

  @override
  String get group_post_edit_title => 'แก้ไขโพสต์';

  @override
  String get group_post_update_error =>
      'ไม่สามารถบันทึกการเปลี่ยนแปลงได้ โปรดลองอีกครั้ง';

  @override
  String get group_post_updated => 'บันทึกการเปลี่ยนแปลงแล้ว';

  @override
  String get practice_collection_already_added =>
      'ชุดบทสวดนี้อยู่ในการปฏิบัติของคุณแล้ว';

  @override
  String get practice_group_accumulator_already_added =>
      'ยอดสะสมนี้อยู่ในการปฏิบัติของคุณแล้ว';

  @override
  String get event_live_badge => 'สด';

  @override
  String get event_live_audio => 'เสียงถ่ายทอดสด';

  @override
  String get event_live_video_mode => 'วิดีโอ';

  @override
  String get event_live_audio_mode => 'เสียง';

  @override
  String get event_live_go_live => 'ถ่ายทอดสด';

  @override
  String get event_replays => 'ดูย้อนหลัง';

  @override
  String event_replay_session(String day, String session) {
    return 'วันที่ $day · ช่วงที่ $session';
  }

  @override
  String get event_replay_recording => 'บันทึกย้อนหลัง';

  @override
  String get event_replay_back_to_live => 'กลับไปดูสด';

  @override
  String get event_replays_empty => 'ยังไม่มีวิดีโอย้อนหลัง';

  @override
  String get event_puja_starts_in => 'พิธีบูชาจะเริ่มใน';

  @override
  String get event_puja_not_started => 'พิธีบูชายังไม่เริ่ม';

  @override
  String get event_prayer_requests => 'คำขอให้ร่วมอธิษฐาน';

  @override
  String event_prayer_request_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count คำขอ',
      one: '1 คำขอ',
    );
    return '$_temp0';
  }

  @override
  String get event_prayer_empty_title => 'ยังไม่มีคำขอให้ร่วมอธิษฐาน';

  @override
  String get event_prayer_empty_body => 'คำขอของคุณและของกลุ่มจะแสดงที่นี่';

  @override
  String get event_prayer_add => 'เพิ่มคำขอให้ร่วมอธิษฐาน';

  @override
  String get event_prayer_hint => 'แชร์คำขอให้ร่วมอธิษฐาน';

  @override
  String event_prayer_hint_intention(String topics) {
    return 'ขอให้ร่วมอธิษฐานเรื่อง: $topics';
  }

  @override
  String get event_prayer_load_failed => 'ไม่สามารถโหลดคำขอให้ร่วมอธิษฐานได้';

  @override
  String get event_prayer_closed => 'กิจกรรมนี้ปิดรับคำขอให้ร่วมอธิษฐานแล้ว';

  @override
  String get group_prayer_closed => 'กลุ่มนี้ปิดรับคำขอให้ร่วมอธิษฐานแล้ว';

  @override
  String get group_prayer_delete_body => 'คำขอนี้จะถูกลบสำหรับทุกคนในกลุ่มนี้';

  @override
  String get event_prayer_pray => 'อธิษฐาน';

  @override
  String get event_prayer_praying => 'อธิษฐานแล้ว';

  @override
  String event_prayer_my_count(int count) {
    return '+$count';
  }

  @override
  String get event_prayer_new_request => 'คำขอให้ร่วมอธิษฐานใหม่';

  @override
  String get event_prayer_edit_request => 'แก้ไขคำขอให้ร่วมอธิษฐาน';

  @override
  String get event_prayer_delete_title => 'ลบคำขอให้ร่วมอธิษฐานใช่ไหม';

  @override
  String get event_prayer_delete_body =>
      'คำขอนี้จะถูกลบสำหรับทุกคนในกิจกรรมนี้';

  @override
  String get event_prayer_delete_failed => 'ไม่สามารถลบคำขอให้ร่วมอธิษฐานได้';

  @override
  String get event_prayer_choose_intention => 'เลือกหัวข้ออธิษฐาน';

  @override
  String get event_prayer_intentions_failed => 'ไม่สามารถโหลดหัวข้ออธิษฐานได้';

  @override
  String get event_prayer_request_button => 'ขอให้ร่วมอธิษฐาน';

  @override
  String get event_prayer_you => 'คุณ';

  @override
  String get event_prayer_waiting_first => 'รอผู้ร่วมอธิษฐานคนแรก...';

  @override
  String event_prayer_more_praying(int count) {
    return '+$count คนร่วมอธิษฐานแล้ว';
  }

  @override
  String event_prayer_people_praying(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count คนร่วมอธิษฐานแล้ว',
      one: '$count คนร่วมอธิษฐานแล้ว',
    );
    return '$_temp0';
  }

  @override
  String get event_prayer_praying_for_you => 'อธิษฐานให้คุณแล้ว';

  @override
  String event_prayer_praying_for(String name) {
    return 'อธิษฐานให้ $name แล้ว';
  }

  @override
  String get event_prayer_your_request => 'คำขอของคุณ';

  @override
  String get event_prayer_supporters_failed =>
      'ไม่สามารถโหลดรายชื่อผู้ร่วมอธิษฐานได้';

  @override
  String get event_prayer_no_supporters => 'ยังไม่มีใครร่วมอธิษฐาน';

  @override
  String get event_prayer_sort_by => 'อธิษฐานให้';

  @override
  String get event_prayer_sort_needs_prayers => 'ต้องการแรงอธิษฐาน';

  @override
  String get event_prayer_sort_most_prayed => 'ร่วมอธิษฐานมากที่สุด';

  @override
  String get event_prayer_sort_newest => 'ใหม่ที่สุด';

  @override
  String get event_prayer_sort_oldest => 'เก่าที่สุด';

  @override
  String get event_prayer_sort_by_intention => 'ตามหัวข้ออธิษฐาน';

  @override
  String get event_prayer_clear_intention => 'ล้างหัวข้ออธิษฐาน';

  @override
  String get event_prayer_filter_empty_title => 'ไม่มีคำขอที่ตรงกัน';

  @override
  String get event_prayer_filter_empty_body =>
      'ลองเรียงลำดับแบบอื่นหรือเลือกหัวข้ออธิษฐานอื่น';

  @override
  String get event_prayer_see_translation => 'ดูคำแปล';

  @override
  String get event_prayer_see_original => 'ดูต้นฉบับ';

  @override
  String event_prayer_translated_from(String language) {
    return 'แปลจาก $language';
  }

  @override
  String get event_prayer_translated => 'แปลแล้ว';

  @override
  String get event_prayer_sort_mine => 'คำอธิษฐานของฉัน';

  @override
  String get event_prayer_section_active => 'ยังเปิดอยู่';

  @override
  String get event_prayer_section_accomplished => 'สมหวังแล้ว';

  @override
  String get event_prayer_mark_accomplished => 'สมหวังแล้ว';

  @override
  String get event_prayer_mark_active => 'ทำเครื่องหมายว่ายังเปิดอยู่';

  @override
  String get event_prayer_mine_empty_title => 'คุณยังไม่มีคำขอให้ร่วมอธิษฐาน';

  @override
  String get event_prayer_mine_empty_body =>
      'คำขอที่คุณโพสต์ที่นี่จะแสดงในรายการนี้';

  @override
  String get event_prayer_update_failed =>
      'ไม่สามารถอัปเดตคำขอให้ร่วมอธิษฐานได้';

  @override
  String get event_prayer_find => 'ค้นหาคำอธิษฐานสำหรับคุณ';

  @override
  String get event_prayer_random => 'สุ่ม';

  @override
  String get event_prayer_finding => 'กำลังค้นหาคำอธิษฐาน...';

  @override
  String get event_prayer_found => 'คำอธิษฐานสำหรับคุณ';

  @override
  String get event_prayer_skip => 'ข้าม';

  @override
  String get event_prayer_next => 'คำอธิษฐานถัดไป';

  @override
  String get event_prayer_be_first => 'ร่วมอธิษฐานเป็นคนแรก';

  @override
  String get event_prayer_random_empty_title => 'ยังไม่มีคำอธิษฐานให้ค้นหา';

  @override
  String get event_prayer_random_empty_body => 'ยังไม่มีผู้อื่นโพสต์คำขอที่นี่';

  @override
  String get event_prayer_random_failed => 'ไม่พบคำอธิษฐาน';

  @override
  String event_prayer_people_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count คน',
      one: '1 คน',
    );
    return '$_temp0';
  }

  @override
  String event_prayer_prayers_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'อธิษฐาน $count ครั้ง',
      one: 'อธิษฐาน 1 ครั้ง',
    );
    return '$_temp0';
  }

  @override
  String get me_prayer_requests => 'คำขอให้ร่วมอธิษฐานของฉัน';

  @override
  String get me_prayer_requests_empty_title => 'ยังไม่มีคำขอให้ร่วมอธิษฐาน';

  @override
  String get me_prayer_requests_empty_body =>
      'คำขอที่คุณโพสต์ในกลุ่มและกิจกรรมจะแสดงที่นี่';

  @override
  String get me_prayer_delete_body =>
      'คำขอนี้จะถูกลบสำหรับทุกคนในกลุ่มหรือกิจกรรมนั้น';

  @override
  String get recitation_live_sync => 'ซิงค์';

  @override
  String get recitation_live_label => 'สด';

  @override
  String get recitation_live_session_ended => 'การถ่ายทอดสดสิ้นสุดแล้ว';

  @override
  String get feedback_add_image => 'เพิ่มภาพ';

  @override
  String feedback_image_limit(int count) {
    return 'แนบภาพได้สูงสุด $count ภาพ';
  }

  @override
  String get feedback_send => 'ส่ง';

  @override
  String get feedback_error_offline =>
      'คุณออฟไลน์อยู่ โปรดลองอีกครั้งในภายหลัง';

  @override
  String get feedback_error_rate_limited =>
      'มีคำขอมากเกินไป รอสักครู่แล้วลองอีกครั้ง';

  @override
  String get feedback_error_too_large =>
      'ภาพมีขนาดใหญ่เกินไป นำออกหนึ่งภาพแล้วลองอีกครั้ง';

  @override
  String get feedback_error_failed => 'ส่งข้อเสนอแนะไม่สำเร็จ โปรดลองอีกครั้ง';

  @override
  String get feedback_error_unavailable => 'ขณะนี้ยังส่งข้อเสนอแนะไม่ได้';

  @override
  String get settings_help_contact_row => 'ความช่วยเหลือและติดต่อ';

  @override
  String get help_contact_title => 'ความช่วยเหลือและติดต่อ';

  @override
  String get help_contact_intro =>
      'แจ้งปัญหา แชร์ไอเดีย หรือเสนอความช่วยเหลือและร่วมมือกับเรา เราอ่านทุกข้อความ';

  @override
  String get help_contact_message => 'ข้อความ';

  @override
  String get help_contact_photos => 'รูปภาพหรือภาพหน้าจอ (ไม่บังคับ)';

  @override
  String get help_contact_topic => 'เรื่องนี้เกี่ยวกับอะไร (ไม่บังคับ)';

  @override
  String get help_contact_hint_default => 'มีอะไรอยากบอกเรา';

  @override
  String get help_contact_hint_report_problem =>
      'เกิดอะไรขึ้น และก่อนหน้านั้นคุณกำลังทำอะไรอยู่ ภาพหน้าจอจะช่วยได้มาก';

  @override
  String get help_contact_hint_idea_feedback =>
      'อะไรจะทำให้ WeBuddhist เป็นประโยชน์ต่อการปฏิบัติของคุณมากขึ้น';

  @override
  String get help_contact_hint_suggest_content =>
      'คุณอยากเห็นคำสอน คัมภีร์ หรืออาจารย์ท่านใดที่นี่ แนบลิงก์มาได้เลย';

  @override
  String get help_contact_hint_help_collaborate =>
      'คุณอยากช่วยด้านใด แชร์ทักษะ ภาษา หรือเวลาที่คุณสละได้';

  @override
  String get help_topic_report_problem => 'แจ้งปัญหา';

  @override
  String get help_topic_idea_feedback => 'ไอเดียหรือข้อเสนอแนะ';

  @override
  String get help_topic_suggest_content => 'แนะนำเนื้อหา';

  @override
  String get help_topic_help_collaborate => 'ช่วยเหลือหรือร่วมมือ';

  @override
  String get help_contact_footer => 'ทีมงาน WeBuddhist จะตอบกลับในแชทของคุณ';

  @override
  String get help_contact_sent_title => 'ส่งข้อความแล้ว';

  @override
  String get help_contact_sent_body =>
      'ขอบคุณ เรามักตอบกลับภายใน 1 วัน คุณจะพบคำตอบจากทีมงาน WeBuddhist ในแชทของคุณ';

  @override
  String help_contact_sent_body_named(String name) {
    return 'ขอบคุณ $name เรามักตอบกลับภายใน 1 วัน คุณจะพบคำตอบจากทีมงาน WeBuddhist ในแชทของคุณ';
  }

  @override
  String get help_contact_your_request => 'คำขอของคุณ';

  @override
  String get help_contact_open_chat => 'เปิดแชท';

  @override
  String get help_context_sent_from => 'ส่งจากความช่วยเหลือและติดต่อ';

  @override
  String help_context_photos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รูป',
      one: '1 รูป',
    );
    return '$_temp0';
  }

  @override
  String get chat_official_badge => 'ทางการ';

  @override
  String get chat_team_reply_time => 'มักตอบกลับภายใน 1 วัน';

  @override
  String get connect_failed_load_discover_groups_error =>
      'ไม่สามารถโหลดกลุ่มได้';

  @override
  String get connect_failed_like_post_error => 'ไม่สามารถกดถูกใจโพสต์ได้';

  @override
  String get connect_failed_unlike_post_error => 'ไม่สามารถเลิกถูกใจโพสต์ได้';

  @override
  String get connect_failed_like_comment_error =>
      'ไม่สามารถกดถูกใจความคิดเห็นได้';

  @override
  String get connect_failed_unlike_comment_error =>
      'ไม่สามารถเลิกถูกใจความคิดเห็นได้';

  @override
  String get group_events_load_error =>
      'ไม่สามารถโหลดกิจกรรมได้ โปรดลองอีกครั้ง';

  @override
  String get group_events_empty => 'ยังไม่มีกิจกรรม';

  @override
  String get group_events_empty_message =>
      'สร้างกิจกรรมแรกของคุณ สมาชิกจะได้รับการแจ้งเตือน';

  @override
  String get group_event_create_button => 'สร้างกิจกรรม';

  @override
  String get group_event_new_title => 'กิจกรรมใหม่';

  @override
  String group_event_step_of(int current, int total) {
    return 'ขั้นตอนที่ $current จาก $total';
  }

  @override
  String get group_event_step_about => 'เกี่ยวกับ';

  @override
  String get group_event_cover_image => 'ภาพปก';

  @override
  String get group_event_add_cover_photo => 'เพิ่มภาพปก';

  @override
  String get group_event_change_cover => 'เปลี่ยน';

  @override
  String get group_event_name_and_description => 'ชื่อและคำอธิบาย';

  @override
  String get group_event_name_label => 'ชื่อกิจกรรม';

  @override
  String get group_event_name_hint => 'เช่น ปฏิบัติธรรมร่วมกันวันพุธ';

  @override
  String get group_event_description_label => 'คำอธิบาย (ไม่บังคับ)';

  @override
  String get group_event_description_hint =>
      'จะปฏิบัติอะไรร่วมกัน ต้องเตรียมอะไรมาบ้างไหม';

  @override
  String get group_event_write => 'เขียน';

  @override
  String get group_event_preview => 'ตัวอย่าง';

  @override
  String get group_event_preview_empty => 'ยังไม่มีอะไรให้แสดงตัวอย่าง';

  @override
  String get group_event_continue => 'ดำเนินการต่อ';

  @override
  String get group_event_name_required_hint =>
      'เพิ่มชื่อกิจกรรมเพื่อดำเนินการต่อ';

  @override
  String get group_event_languages_title => 'ภาษาของกิจกรรม';

  @override
  String get group_event_languages_add => 'เพิ่มภาษา';

  @override
  String get group_event_languages_hint =>
      'เลือกไว้ล่วงหน้าตามภาษาของกลุ่มคุณ ผู้อ่านจะเห็นกิจกรรมในภาษาของตนเมื่อมีให้';

  @override
  String get group_event_discard_title => 'ทิ้งกิจกรรมนี้ใช่ไหม';

  @override
  String get group_event_discard_message => 'ข้อมูลที่คุณกรอกไว้จะหายไป';

  @override
  String get group_event_format_bold => 'ตัวหนา';

  @override
  String get group_event_format_italic => 'ตัวเอียง';

  @override
  String get group_event_format_heading => 'หัวเรื่อง';

  @override
  String get group_event_format_bullet_list => 'รายการแบบจุด';

  @override
  String get group_event_format_numbered_list => 'รายการแบบตัวเลข';

  @override
  String get group_event_format_link => 'ลิงก์';

  @override
  String get group_event_link_title => 'แทรกลิงก์';

  @override
  String get group_event_link_text_hint => 'ข้อความ';

  @override
  String get group_event_link_url_hint => 'https://';

  @override
  String get group_event_link_insert => 'แทรก';

  @override
  String get group_event_step_when_where => 'เวลาและสถานที่';

  @override
  String get group_event_when => 'เมื่อไร';

  @override
  String get group_event_where => 'ที่ไหน';

  @override
  String get group_event_one_time => 'ครั้งเดียว';

  @override
  String get group_event_recurring => 'จัดซ้ำ';

  @override
  String get group_event_date => 'วันที่';

  @override
  String get group_event_start_date => 'วันที่เริ่มต้น';

  @override
  String get group_event_end_date => 'วันที่สิ้นสุด';

  @override
  String get group_event_first_date => 'วันที่ครั้งแรก';

  @override
  String get group_event_choose_date => 'เลือกวันที่';

  @override
  String get group_event_multi_day => 'กิจกรรมหลายวัน';

  @override
  String get group_event_all_day => 'ทั้งวัน';

  @override
  String get group_event_all_day_hint => 'แสดงเป็นทั้งวันในหน้ากิจกรรม';

  @override
  String get group_event_start_time => 'เวลาเริ่มต้น';

  @override
  String get group_event_end_time => 'เวลาสิ้นสุด';

  @override
  String get group_event_add_start_time => 'เพิ่มเวลาเริ่มต้น';

  @override
  String get group_event_add_end_time => 'เพิ่มเวลาสิ้นสุด';

  @override
  String group_event_time_starts(String time) {
    return 'เริ่ม $time';
  }

  @override
  String group_event_time_ends(String time) {
    return 'สิ้นสุด $time';
  }

  @override
  String get group_event_timezone => 'เขตเวลา';

  @override
  String get group_event_repeats => 'การจัดซ้ำ';

  @override
  String get group_event_choose_repeats => 'เลือกรูปแบบการจัดซ้ำ';

  @override
  String get group_event_duration => 'ระยะเวลา';

  @override
  String get group_event_duration_decrease => 'ลดระยะเวลา';

  @override
  String get group_event_duration_increase => 'เพิ่มระยะเวลา';

  @override
  String group_event_duration_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count วัน',
      one: '1 วัน',
    );
    return '$_temp0';
  }

  @override
  String group_event_repeats_weekly(String weekday) {
    return 'ทุกสัปดาห์ใน $weekday';
  }

  @override
  String group_event_repeats_monthly(String day) {
    return 'ทุกเดือนในวันที่ $day';
  }

  @override
  String group_event_repeats_monthly_lunar(String day) {
    return 'ทุกเดือนในวันที่ $day ตามจันทรคติ';
  }

  @override
  String group_event_repeats_yearly(String date) {
    return 'ทุกปีใน $date';
  }

  @override
  String get group_event_repeats_yearly_lunar => 'ทุกปีตรงกับวันนี้ตามจันทรคติ';

  @override
  String get group_event_full_moon => 'วันเพ็ญ';

  @override
  String get group_event_new_moon => 'วันเดือนดับ';

  @override
  String get group_event_gregorian => 'สุริยคติ';

  @override
  String get group_event_tibetan_lunar => 'จันทรคติทิเบต';

  @override
  String get group_event_next_dates => 'วันที่ครั้งถัดไป';

  @override
  String get group_event_repeats_hint => 'ตัวเลือกอิงตามวันที่ครั้งแรก';

  @override
  String get group_event_in_person => 'ออนไซต์';

  @override
  String get group_event_live => 'ถ่ายทอดสด';

  @override
  String get group_event_both => 'ทั้งสองแบบ';

  @override
  String get group_event_venue => 'สถานที่จัดงาน';

  @override
  String get group_event_add_venue => 'เพิ่มสถานที่จัดงาน';

  @override
  String get group_event_venue_search_hint => 'ค้นหาย่าน ถนน หรือสถานที่สำคัญ';

  @override
  String get group_event_venue_no_results => 'ไม่พบสถานที่';

  @override
  String get group_event_venue_search_error => 'ขณะนี้ใช้การค้นหาไม่ได้';

  @override
  String get group_event_drop_pin => 'ปักหมุด';

  @override
  String get group_event_drop_pin_hint => 'เลือกตำแหน่งบนแผนที่';

  @override
  String get group_event_pin_marker => 'สถานที่จัดกิจกรรม';

  @override
  String get group_event_selected_location => 'สถานที่ที่เลือก';

  @override
  String get group_event_pin_unnamed => 'ตำแหน่งที่ปักหมุด';

  @override
  String get group_event_confirm_location => 'ยืนยันสถานที่';

  @override
  String get group_event_name_location => 'ตั้งชื่อสถานที่';

  @override
  String get group_event_venue_name => 'ชื่อสถานที่จัดงาน';

  @override
  String get group_event_venue_name_hint => 'เช่น ศูนย์ธรรมะวัชรสัตว์';

  @override
  String get group_event_save_venue => 'บันทึกสถานที่';

  @override
  String get group_event_live_link => 'ลิงก์ถ่ายทอดสด';

  @override
  String get group_event_live_link_hint => 'youtube.com/… หรือลิงก์การประชุม';

  @override
  String get group_event_use_channel_link => 'ใช้ลิงก์ช่อง';

  @override
  String get group_event_live_link_youtube_help =>
      'ถ่ายทอดสดทาง YouTube ของกลุ่มคุณ ซึ่งจะเล่นภายใน WeBuddhist วางลิงก์อื่นหากต้องการเปลี่ยน';

  @override
  String get group_event_live_link_custom_help =>
      'ลิงก์ที่กำหนดเอง ผู้ชมจะเปิดลิงก์นี้นอก WeBuddhist';

  @override
  String get group_event_live_link_invalid => 'ดูเหมือนยังไม่ใช่ลิงก์';

  @override
  String get group_event_pick_date_hint => 'เลือกวันที่เพื่อดำเนินการต่อ';

  @override
  String get group_event_pick_repeats_hint =>
      'เลือกรูปแบบการจัดซ้ำเพื่อดำเนินการต่อ';

  @override
  String get group_event_end_date_hint =>
      'วันที่สิ้นสุดต้องอยู่หลังวันที่เริ่มต้น';

  @override
  String get group_event_end_time_hint => 'เวลาสิ้นสุดต้องอยู่หลังเวลาเริ่มต้น';

  @override
  String get group_event_venue_hint => 'เลือกสถานที่จัดงานเพื่อดำเนินการต่อ';

  @override
  String get group_event_link_required_hint =>
      'เพิ่มลิงก์การประชุมเพื่อดำเนินการต่อ';

  @override
  String get group_event_map_attribution => '© ผู้ร่วมพัฒนา OpenStreetMap';

  @override
  String get group_event_step_practices => 'การปฏิบัติและวิดีโอ';

  @override
  String get group_event_optional_note =>
      'ทุกอย่างในส่วนนี้ไม่บังคับ คุณเพิ่มรายละเอียดเหล่านี้ภายหลังได้';

  @override
  String get group_event_practices_section => 'การปฏิบัติในกิจกรรม';

  @override
  String get group_event_add_practice => 'เพิ่มการปฏิบัติ';

  @override
  String get group_event_practice_search_hint => 'ค้นหาการปฏิบัติของกลุ่มคุณ';

  @override
  String get group_event_practice_filter_all => 'ทั้งหมด';

  @override
  String get group_event_practice_filter_content => 'แผนการปฏิบัติและซีรีส์';

  @override
  String get group_event_practice_filter_collections => 'ชุดบทสวด';

  @override
  String get group_event_practice_filter_accumulators => 'ยอดสะสม';

  @override
  String get group_event_practice_rule =>
      'แต่ละกิจกรรมมีแผนการปฏิบัติหรือซีรีส์ได้ 1 รายการ และชุดบทสวดได้ 1 ชุด ส่วนยอดสะสมเพิ่มได้ตามต้องการ';

  @override
  String group_event_practice_replaced(String chosen, String previous) {
    return 'เลือก $chosen แทน $previous แล้ว';
  }

  @override
  String get group_event_practices_empty => 'กลุ่มนี้ยังไม่มีการปฏิบัติ';

  @override
  String get group_event_practices_load_error =>
      'ไม่สามารถโหลดการปฏิบัติได้ โปรดลองอีกครั้ง';

  @override
  String get group_event_practices_none_match => 'ไม่มีการปฏิบัติที่ตรงกัน';

  @override
  String group_event_add_practices_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เพิ่มการปฏิบัติ $count รายการ',
      one: 'เพิ่มการปฏิบัติ 1 รายการ',
      zero: 'เพิ่มการปฏิบัติ',
    );
    return '$_temp0';
  }

  @override
  String get group_event_counted_by => 'นับโดย';

  @override
  String get group_event_count_mode_title => 'ใครเป็นผู้เพิ่มยอด';

  @override
  String get group_event_count_mode_attendees => 'ผู้เข้าร่วมเพิ่มยอดในแอป';

  @override
  String get group_event_count_mode_attendees_hint =>
      'แต่ละคนเพิ่มจำนวนการสวดของตนเองระหว่างหรือหลังกิจกรรม';

  @override
  String get group_event_count_mode_admin =>
      'ผู้ดูแลเพิ่มยอดให้ผู้เข้าร่วมแบบออนไซต์';

  @override
  String get group_event_count_mode_admin_hint =>
      'คุณกรอกยอดของทั้งกลุ่ม เช่น จำนวนคน × จำนวนรอบ';

  @override
  String get group_event_count_mode_admin_short => 'ผู้ดูแลเพิ่มยอด';

  @override
  String get group_event_count_mode_attendees_taken =>
      'มียอดสะสมอื่นใช้ตัวเลือกนี้แล้ว ในแต่ละกิจกรรม ผู้เข้าร่วมเพิ่มยอดได้ในยอดสะสมเดียวเท่านั้น';

  @override
  String group_event_remove_practice(String title) {
    return 'นำ $title ออก';
  }

  @override
  String get group_event_videos_section => 'วิดีโอแนะนำ';

  @override
  String get group_event_videos_hint =>
      'แสดงในหน้าเกี่ยวกับของกิจกรรม ใช้เพื่อแนะนำกิจกรรมหรืออธิบายว่าจะมีอะไรบ้าง';

  @override
  String get group_event_add_video => 'เพิ่มวิดีโอ';

  @override
  String get group_event_video_link => 'ลิงก์ YouTube';

  @override
  String get group_event_video_link_hint => 'https://youtu.be/…';

  @override
  String get group_event_paste => 'วาง';

  @override
  String get group_event_video_loading => 'กำลังดึงรายละเอียดวิดีโอ…';

  @override
  String get group_event_video_invalid =>
      'ดูเหมือนไม่ใช่ลิงก์ YouTube โปรดวางลิงก์จาก YouTube';

  @override
  String get group_event_video_source => 'YouTube';

  @override
  String get group_event_video_untitled => 'วิดีโอ YouTube';

  @override
  String get group_event_remove_video => 'นำวิดีโอออก';

  @override
  String get group_event_skip => 'ข้าม';

  @override
  String get group_event_step_review => 'ตรวจทานและเผยแพร่';

  @override
  String get group_event_review_event => 'กิจกรรม';

  @override
  String get group_event_review_settings => 'การตั้งค่า';

  @override
  String get group_event_review_name => 'ชื่อ';

  @override
  String get group_event_review_languages => 'ภาษา';

  @override
  String get group_event_review_when => 'เมื่อไร';

  @override
  String get group_event_review_where => 'ที่ไหน';

  @override
  String get group_event_review_live_link => 'ลิงก์ถ่ายทอดสด';

  @override
  String get group_event_review_practices => 'การปฏิบัติ';

  @override
  String get group_event_review_videos => 'วิดีโอแนะนำ';

  @override
  String get group_event_review_event_settings => 'การตั้งค่ากิจกรรม';

  @override
  String get group_event_review_none => 'ไม่มี';

  @override
  String get group_event_review_tap_hint => 'แตะแถวใดก็ได้เพื่อเปลี่ยน';

  @override
  String get group_event_review_notify_hint =>
      'สมาชิกจะได้รับการแจ้งเตือนเมื่อคุณเผยแพร่';

  @override
  String group_event_review_more(String first, int count) {
    return '$first + อีก $count';
  }

  @override
  String group_event_review_recurring_from(
    String rule,
    String times,
    String date,
  ) {
    return '$rule · $times · ตั้งแต่ $date';
  }

  @override
  String get group_event_review_youtube_live => 'ถ่ายทอดสดทาง YouTube';

  @override
  String get group_event_review_online => 'ออนไลน์';

  @override
  String get group_event_chat_on => 'เปิดแชท';

  @override
  String get group_event_chat_off => 'ปิดแชท';

  @override
  String get group_event_notifications_on => 'เปิดการแจ้งเตือน';

  @override
  String get group_event_notifications_off => 'ปิดการแจ้งเตือน';

  @override
  String get group_event_all_intentions => 'หัวข้ออธิษฐานทั้งหมด';

  @override
  String group_event_intentions_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count หัวข้ออธิษฐาน',
      one: '1 หัวข้ออธิษฐาน',
    );
    return '$_temp0';
  }

  @override
  String get group_event_publish => 'เผยแพร่';

  @override
  String get group_event_publish_error =>
      'ไม่สามารถเผยแพร่กิจกรรมได้ โปรดลองอีกครั้ง';

  @override
  String get group_event_settings_title => 'การตั้งค่ากิจกรรม';

  @override
  String get group_event_settings_chat => 'แชทของกิจกรรม';

  @override
  String get group_event_settings_chat_hint =>
      'เปิดแชทเฉพาะของกิจกรรม ให้สมาชิกได้พูดคุยและโพสต์คำขอให้ร่วมอธิษฐาน';

  @override
  String get group_event_settings_notifications => 'การแจ้งเตือน';

  @override
  String get group_event_settings_notifications_hint =>
      'ประกาศเมื่อคุณเผยแพร่ การเตือนก่อนเริ่ม และการแจ้งเตือนที่คุณส่งเอง';

  @override
  String get group_event_settings_intentions => 'หัวข้ออธิษฐาน';

  @override
  String get group_event_settings_intentions_hint =>
      'หากไม่เลือกเลย จะอนุญาตทุกหัวข้ออธิษฐาน';

  @override
  String get group_event_settings_intentions_error =>
      'ขณะนี้ไม่สามารถโหลดหัวข้ออธิษฐานได้';

  @override
  String get group_event_published_title => 'เผยแพร่แล้ว';

  @override
  String group_event_published_headline(String name) {
    return '$name เผยแพร่แล้ว';
  }

  @override
  String group_event_published_message(String group) {
    return 'แจ้งสมาชิกของ $group แล้ว คุณแก้ไขได้ทุกเมื่อจากหน้ากิจกรรม';
  }

  @override
  String get group_event_published_message_silent =>
      'คุณแก้ไขได้ทุกเมื่อจากหน้ากิจกรรม';

  @override
  String get group_event_view_event => 'ดูกิจกรรม';

  @override
  String get group_event_drafts_section => 'ฉบับร่าง';

  @override
  String get group_event_draft_label => 'ฉบับร่าง';

  @override
  String get group_event_draft_untitled => 'กิจกรรมไม่มีชื่อ';

  @override
  String get group_event_draft_menu_continue => 'แก้ไขต่อ';

  @override
  String get group_event_draft_menu_delete => 'ลบฉบับร่าง';

  @override
  String get group_event_draft_menu_delete_hint =>
      'การดำเนินการนี้ไม่สามารถย้อนกลับได้';

  @override
  String get group_event_draft_saved => 'บันทึกเป็นฉบับร่างแล้ว';

  @override
  String get group_event_draft_save_error =>
      'ไม่สามารถบันทึกฉบับร่างได้ โปรดลองอีกครั้ง';

  @override
  String get group_event_draft_deleted => 'ลบฉบับร่างแล้ว';

  @override
  String get group_event_draft_delete_error =>
      'ไม่สามารถลบฉบับร่างได้ โปรดลองอีกครั้ง';

  @override
  String get group_event_draft_delete_title => 'ลบฉบับร่างใช่ไหม';

  @override
  String get group_event_draft_delete_message => 'ฉบับร่างนี้จะถูกลบอย่างถาวร';

  @override
  String get group_event_edit_draft_title => 'แก้ไขฉบับร่าง';

  @override
  String get group_event_edit_title => 'แก้ไขกิจกรรม';

  @override
  String get group_event_save_changes => 'บันทึกการเปลี่ยนแปลง';

  @override
  String get group_event_changes_saved => 'บันทึกการเปลี่ยนแปลงแล้ว';

  @override
  String get group_event_manage => 'จัดการกิจกรรม';

  @override
  String get group_event_manage_details => 'รายละเอียด';

  @override
  String get group_event_manage_counts => 'ยอด';

  @override
  String get group_event_manage_accumulations => 'ยอดสะสม';

  @override
  String get group_event_manage_admin_adds_pending => 'ผู้ดูแลเพิ่มยอด';

  @override
  String group_event_manage_admin_adds(String count) {
    return 'ผู้ดูแลเพิ่มยอด · ขณะนี้ $count';
  }

  @override
  String get group_event_manage_attendees_add_pending =>
      'ผู้เข้าร่วมเพิ่มยอดในแอป';

  @override
  String group_event_manage_attendees_add(String count, int people) {
    String _temp0 = intl.Intl.pluralLogic(
      people,
      locale: localeName,
      other: 'ผู้เข้าร่วมเพิ่มยอดในแอป · $count จาก $people คน',
      one: 'ผู้เข้าร่วมเพิ่มยอดในแอป · $count จาก 1 คน',
    );
    return '$_temp0';
  }

  @override
  String get group_event_manage_add_count => 'เพิ่มยอด';

  @override
  String get group_event_manage_no_accumulations => 'กิจกรรมนี้ไม่มียอดสะสม';

  @override
  String get group_event_manage_recurring_note =>
      'กิจกรรมที่จัดซ้ำจะไม่เก็บรายชื่อผู้เข้าร่วม ยอดจะรวมจากทุกครั้งที่จัด';

  @override
  String group_event_in_person_of_target(String count, String target) {
    return '$count จาก $target';
  }

  @override
  String group_event_in_person_in_total(String count) {
    return 'รวม $count';
  }

  @override
  String get group_event_in_person_legend_app => 'แอป';

  @override
  String get group_event_in_person_legend_in_person => 'ออนไซต์';

  @override
  String get group_event_in_person_add_day => 'เพิ่มวัน';

  @override
  String get group_event_in_person_day => 'วัน';

  @override
  String get group_event_in_person_count => 'ยอด';

  @override
  String get group_event_in_person_empty => 'ยังไม่มียอดออนไซต์';

  @override
  String get group_event_in_person_invalid_count =>
      'กรอกจำนวนเต็มตั้งแต่ 1 ขึ้นไป';

  @override
  String get group_event_in_person_added => 'เพิ่มยอดออนไซต์แล้ว';

  @override
  String get group_event_in_person_updated => 'อัปเดตยอดออนไซต์แล้ว';

  @override
  String get group_event_in_person_deleted => 'ลบยอดออนไซต์แล้ว';

  @override
  String get group_event_in_person_delete_title => 'ลบยอดออนไซต์ใช่ไหม';

  @override
  String group_event_in_person_delete_message(String count, String day) {
    return 'ยอด $count ของ $day จะถูกหักออกจากยอดรวมของยอดสะสมนี้';
  }

  @override
  String get group_event_in_person_exists =>
      'วันนั้นมียอดอยู่แล้ว โปรดแก้ไขยอดเดิมแทน';

  @override
  String get group_event_in_person_no_accumulation =>
      'เชื่อมโยงยอดสะสมของกลุ่มกับกิจกรรมนี้เพื่อบันทึกยอดออนไซต์';

  @override
  String get group_event_in_person_save_error => 'บันทึกยอดไม่สำเร็จ';

  @override
  String get group_event_in_person_load_more => 'โหลดเพิ่ม';

  @override
  String get mala_failed_load_catalogue_error => 'ไม่สามารถโหลดรายการได้';

  @override
  String get chant_collection_reload_error =>
      'ไม่สามารถโหลดชุดบทสวดใหม่เพื่อจัดเรียงได้';

  @override
  String get chant_collection_reorder_error => 'ไม่สามารถจัดเรียงบทสวดได้';

  @override
  String get timer_duration_label => 'ระยะเวลา';

  @override
  String get timer_ambient_sound_label => 'เสียงบรรยากาศ';

  @override
  String get timer_begin_session => 'เริ่มทำสมาธิ';

  @override
  String get timer_save_changes => 'บันทึกการเปลี่ยนแปลง';

  @override
  String get timer_new_title => 'ตัวจับเวลาใหม่';

  @override
  String get timer_title_hint => 'ชื่อ...';

  @override
  String get timer_edit_title => 'แก้ไขตัวจับเวลา';

  @override
  String get timer_your_timers => 'ตัวจับเวลาของคุณ';

  @override
  String get timer_custom_timer => 'ตัวจับเวลาที่กำหนดเอง';

  @override
  String get timer_ambient_sounds_title => 'เสียงบรรยากาศ';

  @override
  String get timer_ambient_sound_none => 'ค่าเริ่มต้น (ไม่มีเสียง)';

  @override
  String get timer_ambient_sounds_load_error => 'ไม่สามารถโหลดเสียงบรรยากาศได้';

  @override
  String get timer_volume_label => 'ระดับเสียง';

  @override
  String get timer_duration_title => 'ระยะเวลา';

  @override
  String get timer_edit => 'แก้ไขตัวจับเวลา';

  @override
  String get timer_delete => 'ลบตัวจับเวลา';

  @override
  String get timer_delete_title => 'ลบตัวจับเวลาใช่ไหม';

  @override
  String get timer_delete_message =>
      'ตัวจับเวลานี้จะถูกนำออกจากรายการตัวจับเวลาของคุณ';

  @override
  String get timer_duration_must_be_greater_than_error =>
      'ระยะเวลาต้องมากกว่า 0';

  @override
  String get splash_tagline_1 => 'พวกเราชาวพุทธปฏิบัติร่วมกัน';

  @override
  String get splash_tagline_2 => 'พวกเราชาวพุทธปฏิบัติทุกวัน';

  @override
  String get timer_list_subtitle =>
      'แตะเล่นเพื่อเริ่ม หรือสร้างตัวจับเวลาของคุณเอง';

  @override
  String get timer_create_custom => 'สร้างตัวจับเวลาเอง';

  @override
  String get timer_create_custom_subtitle =>
      'เลือกระยะเวลาและเสียงพื้นหลัง (ไม่บังคับ)';

  @override
  String get timer_starting => 'กำลังเริ่ม...';

  @override
  String get timer_duration_hours => 'ชั่วโมง';

  @override
  String get timer_duration_sec => 'วินาที';
}

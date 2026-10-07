// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Mongolian (`mn`).
class AppLocalizationsMn extends AppLocalizations {
  AppLocalizationsMn([String locale = 'mn']) : super(locale);

  @override
  String get appTitle => 'WeBuddhist';

  @override
  String get sign_in => 'Нэвтрэх';

  @override
  String get logout => 'Гарах';

  @override
  String get onboarding_welcome => 'Тавтай морил';

  @override
  String get onboarding_setup_subtitle =>
      'Танд тохируулъя, ердөө нэг минут л хангалттай';

  @override
  String get onboarding_tagline =>
      'Сурч, дадлага хийж, холбогдоорой. Өдөр бүр.';

  @override
  String get onboarding_quote =>
      'Дусал дуслаар ус сав дүүрдэгийн адил, ухаант хүн ч багаахан багаахнаар хуримтлуулж, өөрийгөө буянаар дүүргэдэг.';

  @override
  String get onboarding_find_peace => 'Эхлэх';

  @override
  String get onboarding_continue => 'Үргэлжлүүлэх';

  @override
  String get onboarding_first_question => 'Хэлээ сонгоно уу';

  @override
  String get onboarding_language_subtitle => 'Энэ нь аппын хэлийг тохируулна';

  @override
  String get onboarding_choose_option => 'Дор хаяж нэгийг сонгоно уу:';

  @override
  String get onboarding_all_set => 'Бүх зүйл бэлэн боллоо';

  @override
  String get onboarding_all_set_description => 'Таныг хүлээж буй зүйлс:';

  @override
  String get onboarding_all_set_practice_title => 'Дадлага';

  @override
  String get onboarding_all_set_practice_body =>
      'Төлөвлөгөө, уншлага, эрх болон бясалгал';

  @override
  String get onboarding_all_set_connect_title => 'Холбогдох';

  @override
  String get onboarding_all_set_connect_body =>
      'Орон зай, арга хэмжээ, мэдээ болон чат';

  @override
  String get home_recitation => 'Уншлага';

  @override
  String get home_today => 'Өнөөдөр';

  @override
  String get home_good_morning => 'Өглөөний мэнд';

  @override
  String get home_good_afternoon => 'Өдрийн мэнд';

  @override
  String get home_good_evening => 'Оройн мэнд';

  @override
  String get home_meditationTitle => 'Бясалгал';

  @override
  String get home_prayerTitle => 'Өнөөдрийн залбирал';

  @override
  String get home_scripture => 'Удирдамжтай бичиг';

  @override
  String get home_meditation => 'Удирдамжтай бясалгал';

  @override
  String get home_goDeeper => 'Илүү гүнзгий орно уу';

  @override
  String get home_intention => 'Өнөөдрийн миний зорилго';

  @override
  String get home_overall_stats => 'Нийт статистик';

  @override
  String get home_plans => 'Төлөвлөгөө';

  @override
  String home_plans_count(int count) {
    return '$count Төлөвлөгөө';
  }

  @override
  String home_recitation_count(int count) {
    return '$count уншлага';
  }

  @override
  String get home_shortcut_plans => 'Төлөвлөгөө';

  @override
  String get home_chants => 'Магтаал';

  @override
  String get home_mala => 'Эрх';

  @override
  String get session_mala => 'Эрхүүд';

  @override
  String get bookmark_mala => 'Эрхүүд';

  @override
  String get bookmark_timers => 'Цаг хэмжигчид';

  @override
  String get bookmark_texts => 'Бичвэрүүд';

  @override
  String get bookmark_group_accumulation => 'Орон зайн хуримтлал';

  @override
  String get mala_add_to_practice => 'Миний дадлагад нэмэх';

  @override
  String get mala_add_mala_round => 'Эрхийн ээлж нэмэх';

  @override
  String get mala_add_rounds_title => 'Эрхийн ээлж нэмэх:';

  @override
  String get mala_add_rounds_message =>
      'Энэ аппаас гадуур хийсэн эрхийн ээлжийнхээ тоог нэмнэ үү';

  @override
  String get mala_add_to_bookmark => 'Хавчуурга';

  @override
  String get mala_sound => 'Дуу';

  @override
  String get mala_vibration => 'Чичиргээ';

  @override
  String get mala_reset_count => 'Тооллогыг дахин тохируулах';

  @override
  String get mala_reset_title => 'Энэ эрхийг дахин тохируулах уу?';

  @override
  String get mala_reset_count_confirm =>
      'Одоогийн тооллого тэг болно, гэхдээ таны хуримтлал амьдралын нийт тоонд хадгалагдана';

  @override
  String get mala_reset_confirm => 'Дахин тохируулах';

  @override
  String get mala_action_coming_soon => 'Удахгүй';

  @override
  String mala_rounds_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ээлж',
      one: '1 ээлж',
      zero: '0 ээлж',
    );
    return '$_temp0';
  }

  @override
  String mala_counter_semantics(int bead, int total, String rounds) {
    return 'Тоол $bead/$total, $rounds';
  }

  @override
  String get mala_group_accumulations => 'Уншлага нэмэх';

  @override
  String get mala_groups_section => 'Groups';

  @override
  String get mala_group_untitled => 'Нэргүй орон зай';

  @override
  String get home_timer => 'Цаг хэмжигч';

  @override
  String get preset_timers => 'Бэлэн тохируулсан цаг';

  @override
  String get meditation_timer => 'Бясалгалын цаг хэмжигч';

  @override
  String get timer_min => 'мин';

  @override
  String get timer_start => 'Эхлэх';

  @override
  String get timer_finish => 'Дуусгах';

  @override
  String get timer_discard_session => 'Хичээл цуцлах';

  @override
  String get home_hello_prefix => 'Сайн байна уу, ';

  @override
  String get home_greeting_fallback_name => 'найз минь';

  @override
  String home_share_prompt(String appName) {
    return '$appName танд таалагдаж байна уу?';
  }

  @override
  String get home_share_support =>
      'Таны дэмжлэг манай нийгэмлэгийг өсгөхөд тусалдаг.';

  @override
  String get no_feature_content => 'Онцлох агуулга байхгүй байна';

  @override
  String get nav_home => 'Нүүр';

  @override
  String get nav_explore => 'Судлах';

  @override
  String get nav_learn => 'Суралцах';

  @override
  String get nav_practice => 'Дадлага';

  @override
  String get nav_settings => 'Тохиргоо';

  @override
  String get nav_connect => 'Холбогдох';

  @override
  String get nav_me => 'Би';

  @override
  String get tab_practices => 'Дадлага';

  @override
  String get text_search => 'Хайх';

  @override
  String get text_toc_versions => 'Хувилбарууд';

  @override
  String get text_commentary => 'Тайлбар';

  @override
  String get resources => 'Нөөц';

  @override
  String get no_translation => 'Орчуулга олдсонгүй';

  @override
  String get text_close_commentary => 'Тайлбар хаах';

  @override
  String get show_more => 'Илүү ихийг харах';

  @override
  String get show_less => 'Хураах';

  @override
  String get more => 'Илүү';

  @override
  String get less => 'Бага';

  @override
  String get no_content => 'Агуулга олдсонгүй';

  @override
  String get no_commentary => 'Тайлбар олдсонгүй';

  @override
  String commentary_not_available_for_language(String language) {
    return '$language хэл дээрх тайлбар байхгүй';
  }

  @override
  String get loading => 'Ачааллаж байна...';

  @override
  String get choose_bg_image => 'Дэвсгэр зураг сонгох';

  @override
  String get save => 'Хадгалах';

  @override
  String get done => 'Болсон';

  @override
  String get customise_message =>
      'Бичвэрийн загварыг тохируулахын тулд тохируулах дүрс дээр дарна уу';

  @override
  String get download_image => 'Зураг татах';

  @override
  String get no_images_available => 'Зураг байхгүй байна';

  @override
  String get customise_text => 'Бичвэр тохируулах';

  @override
  String get text_size => 'Бичвэрийн хэмжээ';

  @override
  String get text_color => 'Бичвэрийн өнгө';

  @override
  String get text_shadow => 'Бичвэрийн сүүдэр';

  @override
  String get apply => 'Хэрэглэх';

  @override
  String get my_plans => 'Миний төлөвлөгөө';

  @override
  String get browse_plans => 'Төлөвлөгөө үзэх';

  @override
  String get plan_info => 'Төлөвлөгөөний мэдээлэл';

  @override
  String get start_reading => 'Одоо дадлага хийх';

  @override
  String get tibetan => 'Төвд';

  @override
  String get sanskrit => 'Санскрит';

  @override
  String get english => 'Англи';

  @override
  String get chinese => 'Хятад';

  @override
  String get classicalChinese => 'Сонгодог хятад';

  @override
  String get pali => 'Пали';

  @override
  String get language => 'Хэл';

  @override
  String get plan_unenroll => 'Бүртгэл цуцлах';

  @override
  String get unenroll_confirmation =>
      'Та дараахаас бүртгэлээ цуцлахдаа итгэлтэй байна уу';

  @override
  String get unenroll_message =>
      'Таны ахиц бүрмөсөн устах бөгөөд сэргээх боломжгүй';

  @override
  String get practice_plan =>
      'Өдөр тутмын дадлага бий болго. Өөрт тохирохыг олж судал.';

  @override
  String get search_plans => 'Төлөвлөгөө хайх...';

  @override
  String get search_for_plans => 'Төлөвлөгөө хайх';

  @override
  String get no_plans_found => 'Төлөвлөгөө олдсонгүй';

  @override
  String get no_days_available => 'Өдөр олдсонгүй';

  @override
  String get recitations_title => 'Уншлагууд';

  @override
  String get recitations_my_recitations => 'Миний уншлага';

  @override
  String get browse_recitations => 'Уншлага үзэх';

  @override
  String get recitations_search => 'Уншлага хайх...';

  @override
  String get recitations_search_for => 'Уншлага хайх';

  @override
  String get recitations_no_found => 'Уншлага олдсонгүй';

  @override
  String get recitations_no_content => 'Уншлага байхгүй байна';

  @override
  String get recitations_no_saved => 'Хадгалсан уншлага байхгүй';

  @override
  String get recitations_login_prompt =>
      'Хадгалсан уншлагаа харахын тулд нэвтэрнэ үү';

  @override
  String get my_recitation_collection_new_title => 'Шинэ цуглуулга';

  @override
  String get my_recitation_collection_next => 'Дараах';

  @override
  String get my_recitation_collection_create => 'Үүсгэх';

  @override
  String get my_recitation_collection_create_button => 'Цуглуулга үүсгэх';

  @override
  String get my_recitation_collection_change_title => 'Гарчиг өөрчлөх';

  @override
  String get my_recitation_collection_change => 'Өөрчлөх';

  @override
  String get my_recitation_collection_add_chants => 'Уншлага нэмэх';

  @override
  String get my_recitation_collection_search_chants => 'Уншлага хайх';

  @override
  String get my_recitation_collection_add_to_collection => 'Цуглуулгад нэмэх';

  @override
  String get my_recitation_collection_edit => 'Цуглуулга засах';

  @override
  String get my_recitation_collection_delete => 'Цуглуулга устгах';

  @override
  String get my_recitation_collection_delete_title => 'Цуглуулгыг устгах уу?';

  @override
  String get my_recitation_collection_delete_message =>
      'Энэ цуглуулга бүрмөсөн устгагдана';

  @override
  String get my_recitation_collection_fallback_title => 'Уншлагын цуглуулга';

  @override
  String get my_recitation_collection_unavailable => 'Цаашид боломжгүй';

  @override
  String my_recitation_collection_chant_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count уншлага',
      one: '1 уншлага',
      zero: '0 уншлага',
    );
    return '$_temp0';
  }

  @override
  String my_recitation_collection_chant_count_owner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count уншлага • би',
      one: '1 уншлага • би',
      zero: '0 уншлага • би',
    );
    return '$_temp0';
  }

  @override
  String get bookmarks_empty_chant_collections_title =>
      'Хараахан уншлагын цуглуулга хавчуургалаагүй байна';

  @override
  String get bookmarks_empty_chant_collections_subtitle =>
      'Энд хадгалахын тулд цуглуулга хавчуургалаарай';

  @override
  String get notification_settings => 'Мэдэгдлийн тохиргоо';

  @override
  String get notification_allow_title => 'Мэдэгдэл зөвшөөрөх';

  @override
  String get notification_allow_subtitle_enabled =>
      'Энэ аппликейшнд мэдэгдэл идэвхжсэн байна';

  @override
  String get notification_allow_subtitle_disabled =>
      'Зөвшөөрөл шаардлагатай. Тохиргоо хэсэгт олгохын тулд дарна уу';

  @override
  String get notification_allow_subtitle_paused =>
      'Сануулга түр зогссон. Үргэлжлүүлэхийн тулд дарна уу';

  @override
  String get notification_routine_title => 'Төлөвлөгөөний сануулга';

  @override
  String get notification_routine_subtitle_enabled =>
      'Таны төлөвлөгөөний өдөр тутмын сануулга';

  @override
  String get notification_routine_subtitle_disabled =>
      'Төлөвлөгөөний сануулга түр зогссон. Үргэлжлүүлэхийн тулд дарна уу';

  @override
  String get notification_battery_title => 'Дэвсгэр сануулга';

  @override
  String get notification_battery_subtitle_enabled =>
      'Апп хаалттай байсан ч таны сануулга цагтаа илгээгдэнэ';

  @override
  String get notification_battery_subtitle_disabled =>
      'Зарим Android утас батерей хэмнэхийн тулд дэвсгэр аппуудыг түр зогсоодог нь таны сануулгыг хойшлуулах буюу алгасах магадлалтай. Үргэлжлүүлэн ажиллуулахын тулд дарна уу.';

  @override
  String get notification_recitation_title => 'Уншлагын сануулга';

  @override
  String get notification_recitation_subtitle_enabled =>
      'Таны уншлагын өдөр тутмын сануулга';

  @override
  String get notification_recitation_subtitle_disabled =>
      'Уншлагын сануулга түр зогссон. Үргэлжлүүлэхийн тулд дарна уу';

  @override
  String get notification_practice_title => 'Эрхи тоолох сануулга';

  @override
  String get notification_practice_subtitle_enabled =>
      'Таны эрхиний дадлагын өдөр тутмын сануулга';

  @override
  String get notification_practice_subtitle_disabled =>
      'Эрхийн сануулга түр зогссон. Үргэлжлүүлэхийн тулд дарна уу';

  @override
  String get notification_timer_title => 'Таймерын сануулга';

  @override
  String get notification_timer_subtitle_enabled =>
      'Таны цаг хэмжигчийн өдөр тутмын сануулга';

  @override
  String get notification_timer_subtitle_disabled =>
      'Цаг хэмжигчийн сануулга түр зогссон. Үргэлжлүүлэхийн тулд дарна уу';

  @override
  String get notification_battery_info_title => 'Дэвсгэр сануулгын тухай';

  @override
  String get notification_battery_info_body =>
      'Зарим Android утас батерей хэмнэхийн тулд дэвсгэр аппуудыг түр зогсоодог нь таны товлосон сануулгыг хойшлуулах буюу цуцлах магадлалтай. Энэ аппыг чөлөөлснөөр таны сануулга цагтаа найдвартай ирнэ.';

  @override
  String get notification_snack_permission_denied =>
      'Мэдэгдэл хаагдсан байна. Тохиргоо хэсэгт идэвхжүүлнэ үү';

  @override
  String get notification_snack_disable_alarms_in_settings =>
      'Тохиргоо хэсэгт сэрүүлэг ба сануулгыг унтраана уу';

  @override
  String get notification_snack_battery_reenable =>
      'Тохиргоо → Батерей хэсэгт батерей оновчлолыг сэргээнэ үү';

  @override
  String get profile_default_bio => 'WeBuddhist-д тавтай морил';

  @override
  String get profile_guest_title => 'Зочин хэрэглэгч';

  @override
  String get profile_guest_subtitle => 'Та зочноор үзэж байна';

  @override
  String get profile_guest_benefits_header => 'Нээхийн тулд нэвтэрнэ үү:';

  @override
  String get profile_guest_benefit_save_progress => 'Ахицаа хадгалах';

  @override
  String get profile_guest_benefit_personalized => 'Хувийн тохируулсан агуулга';

  @override
  String get profile_guest_benefit_notifications => 'Тусгай мэдэгдэл';

  @override
  String get auth_drawer_title => 'Үргэлжлүүлэхийн тулд нэвтэрнэ үү';

  @override
  String get auth_drawer_subtitle =>
      'Хаана ч явсан, аль ч төхөөрөмж дээр дадлагаа үргэлжлүүл';

  @override
  String get routine_delete_block_message =>
      'Цагийн блок болон доторх бүх зүйл устгагдана';

  @override
  String get something_went_wrong => 'Алдаа гарлаа. Дахин оролдоно уу';

  @override
  String get onboarding_quote_citation => '— Дхаммапада 122';

  @override
  String get onboarding_traditions_question => 'Та ямар уламжлал\nдагадаг вэ?';

  @override
  String get onboarding_tradition_title =>
      'Та Бурхан багшийн сургаалийг хэрхэн дагадаг вэ?';

  @override
  String get onboarding_tradition_subtitle =>
      'Агуулгадаа нэг буюу хэд хэдэн уламжлал сонгоно уу. Та үүнийг хүссэн үедээ Тохиргоо хэсэгт өөрчилж болно.';

  @override
  String get onboarding_tradition_option_intro => 'Дараах:';

  @override
  String get onboarding_tradition_show_all_title => 'Бүгдийг харуулах';

  @override
  String get onboarding_skip_for_now => 'Одоохондоо алгасах';

  @override
  String get onboarding_add_another_tradition => 'Өөр уламжлал нэмэх';

  @override
  String get onboarding_select_all => 'Бүгдийг сонгох';

  @override
  String get onboarding_event_enrollment_error =>
      'Бүртгэх боломжгүй байна. Холболтоо шалгаад дахин оролдоно уу';

  @override
  String get onboarding_event_question => 'Арга хэмжээнд\nнэгдэх үү?';

  @override
  String get onboarding_event_optional =>
      'Сонголтоор · Бүртгүүлэхийн тулд дарна уу';

  @override
  String onboarding_event_duration(String description, int days) {
    return '$description · $days өдөр';
  }

  @override
  String get onboarding_event_reminder_note =>
      'Бид өглөөний 7:30 цагт өдөр тутмын сануулга илгээнэ. (Хүссэн үедээ өөрчилж болно.)';

  @override
  String get tradition_theravada => 'Теравада';

  @override
  String get tradition_zen => 'Зэн';

  @override
  String get tradition_tibetan_buddhism => 'Төвдийн бурханы шашин';

  @override
  String get tradition_pure_land => 'Цэвэр газар';

  @override
  String get tradition_ambedkar_buddhism => 'Амбедкарын бурханы шашин';

  @override
  String get plan_go_to_practice => 'Дадлага руу очих';

  @override
  String get plan_starts_soon_title => 'Удахгүй эхэлнэ';

  @override
  String get plan_joining_late_title => 'Эхлэх огнооны дараа нэгдэж байна';

  @override
  String get got_it => 'Ойлголоо';

  @override
  String get plan_no_tasks_error => 'Даалгавруудыг ачаалах боломжгүй';

  @override
  String get plan_day_tasks_load_error => 'Даалгавруудыг ачаалах боломжгүй';

  @override
  String get plans_empty_title => 'Удахгүй илүү ихийг нэмнэ';

  @override
  String get plans_empty_subtitle =>
      'Манай сан өргөжиж байна. Удахгүй дахин шалгаарай.';

  @override
  String get find_plans_load_error =>
      'Ачаалах боломжгүй.\nХолболтоо шалгаад дахин оролдоно уу';

  @override
  String get connect_coming_soon_subtitle =>
      'Замд тань туслах багш нар, нийгэмлэгүүд, сорилт болон арга хэмжээнүүд';

  @override
  String get connect_subtitle => 'Бүлгээ олж, хамтдаа дадлага хийгээрэй';

  @override
  String get discover_groups => 'Бүлэг хайх';

  @override
  String get my_groups => 'Миний орон зайнууд';

  @override
  String get see_all => 'Бүгдийг харах';

  @override
  String get connect_groups_load_error =>
      'Бүлгүүдийг ачаалах боломжгүй.\nХолболтоо шалгаад дахин оролдоно уу';

  @override
  String get connect_groups_empty_title => 'Одоогоор бүлэг алга';

  @override
  String get connect_groups_empty_subtitle =>
      'Баяр хүргэе, та манай бүх орон зайд нэгдсэн байна! Удахгүй дахин шалгаарай. Шинэ орон зайнууд удахгүй нэмэгдэнэ...';

  @override
  String get connect_tab_feed => 'Мэдээ';

  @override
  String get connect_tab_events => 'Арга хэмжээ';

  @override
  String get connect_tab_posts => 'Нийтлэл';

  @override
  String get connect_tab_practices => 'Дадлага';

  @override
  String get connect_tab_groups => 'Орон зай';

  @override
  String get connect_segment_my => 'Таны орон зай';

  @override
  String get connect_segment_discover => 'Судлах';

  @override
  String get connect_empty_discover_posts => 'Судлах нийтлэл алга';

  @override
  String get connect_empty_discover_events => 'Судлах арга хэмжээ алга';

  @override
  String get connect_empty_discover_feed => 'Судлах зүйл алга';

  @override
  String get connect_empty_discover_groups => 'Судлах орон зай алга';

  @override
  String get connect_empty_discover_practices => 'Судлах бясалгал алга';

  @override
  String get connect_all_groups => 'Бүх орон зай';

  @override
  String get connect_my_empty_feed_title => 'Таны орон зайнууд чимээгүй байна';

  @override
  String get connect_my_empty_events_title => 'Товлосон арга хэмжээ алга';

  @override
  String get connect_my_empty_posts_title => 'Одоогоор нийтлэл алга';

  @override
  String get connect_my_empty_groups_title => 'Одоогоор бүлэг алга';

  @override
  String get connect_my_empty_feed_subtitle =>
      'Таны орон зайнуудаас шинэ зүйл алга. Бусад нь өнөөдөр нийтэлж байна';

  @override
  String get connect_my_empty_events_subtitle =>
      'Таны орон зайнуудад одоогоор товлосон зүйл алга. Бусад орон зайнуудад бүх нийтэд нээлттэй арга хэмжээ бий';

  @override
  String get connect_my_empty_posts_subtitle =>
      'Таны орон зайнууд юу ч нийтлээгүй байна. Бусад юу хуваалцаж байгааг үзээрэй';

  @override
  String get connect_my_empty_groups_subtitle =>
      'Та одоогоор ямар ч бүлэгт нэгдээгүй байна. Хамтдаа дадлага хийх нийгэмлэгүүдийг судлаарай.';

  @override
  String get connect_my_empty_feed_browse =>
      'Бусад орон зайн хуваалцсаныг үзэх';

  @override
  String get connect_my_empty_events_browse => 'Нээлттэй арга хэмжээг үзэх';

  @override
  String get connect_my_empty_posts_browse => 'Бусад нийтлэлийг үзэх';

  @override
  String get connect_my_empty_practices_title => 'Одоогоор дадлага алга';

  @override
  String get connect_my_empty_practices_subtitle =>
      'Таны орон зайнууд ямар ч дадлага эхлүүлээгүй байна. Бусад юу санал болгож байгааг үзээрэй';

  @override
  String get connect_my_empty_practices_browse => 'Бусад бясалгалыг үзэх';

  @override
  String connect_comment_replying_to(String handle) {
    return '@$handle-д хариулж байна';
  }

  @override
  String get connect_comment_hint => 'Та үүнийг юу гэж бодож байна?';

  @override
  String get connect_comment_reply_hint => 'Хариу бичих...';

  @override
  String get connect_comment_reply => 'Хариулах';

  @override
  String get connect_comment_delete_title => 'Сэтгэгдлийг устгах уу?';

  @override
  String get connect_comment_delete_message =>
      'Энэ сэтгэгдэл бүрмөсөн устгагдана';

  @override
  String get connect_comment_delete_failed => 'Сэтгэгдлийг устгаж чадсангүй';

  @override
  String connect_post_comments_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сэтгэгдэл',
      one: '1 сэтгэгдэл',
    );
    return '$_temp0';
  }

  @override
  String get connect_post_comments_empty =>
      'Одоогоор сэтгэгдэл алга. Яриаг эхлүүлээрэй';

  @override
  String get connect_caption_more => 'Илүү';

  @override
  String get connect_online => 'Онлайн';

  @override
  String get home_group_events => 'Онцлох арга хэмжээ';

  @override
  String get home_poems => 'Шүлэг';

  @override
  String get poems_load_error =>
      'Шүлгүүдийг ачаалах боломжгүй.\nХолболтоо шалгаад дахин оролдоно уу';

  @override
  String get poems_empty => 'Одоогоор шүлэг байхгүй. Удахгүй дахин шалгаарай.';

  @override
  String get connect_events_filter_all => 'Бүгд';

  @override
  String get connect_events_filter_in_person => 'Биечлэн';

  @override
  String get connect_events_filter_empty_online => 'Онлайн арга хэмжээ алга';

  @override
  String get connect_events_filter_empty_in_person =>
      'Биечлэн оролцох арга хэмжээ байхгүй';

  @override
  String get connect_events_filter_hybrid => 'Хосолсон';

  @override
  String get connect_events_filter_empty_hybrid =>
      'Хосолмол арга хэмжээ байхгүй';

  @override
  String get connect_open => 'Нээх';

  @override
  String get connect_event_fallback_title => 'Арга хэмжээ';

  @override
  String get connect_group_fallback_title => 'Орон зай';

  @override
  String get connect_event_attend => 'Оролцох';

  @override
  String get connect_event_attending => 'Оролцож байна';

  @override
  String get connect_event_join_in_person => 'Биечлэн оролцох';

  @override
  String get connect_event_join_online => 'Онлайнаар нэгдэх';

  @override
  String get connect_event_enter => 'Орох';

  @override
  String get connect_event_participation_prompt =>
      'Та хэрхэн оролцож байна вэ?';

  @override
  String get connect_event_joining_in_person => 'Биечлэн оролцож байна';

  @override
  String get connect_event_joining_online => 'Онлайнаар нэгдэж байна';

  @override
  String connect_event_participants_attending(int count) {
    return '$count оролцогч';
  }

  @override
  String get connect_event_participants_empty => 'Одоогоор оролцогч алга';

  @override
  String get connect_event_organizer => 'Зохион байгуулагч';

  @override
  String get connect_event_tab_videos => 'Бичлэгүүд';

  @override
  String get connect_event_tab_links => 'Холбоосууд';

  @override
  String get connect_event_tab_about => 'Тухай';

  @override
  String get connect_event_links_title => 'Үйл явдлын дэлгэрэнгүй мэдээлэл';

  @override
  String get connect_event_links_empty => 'Одоогоор холбоос алга';

  @override
  String get connect_event_link_tap_to_join => 'Нэгдэхийн тулд товшино уу';

  @override
  String get connect_event_link_open => 'Холбоос нээх';

  @override
  String get connect_event_date_tba => 'Огноог дараа зарлана';

  @override
  String get connect_event_when => 'Хэзээ';

  @override
  String get connect_event_where => 'Хаана';

  @override
  String get connect_event_practices => 'Үйл явдлын дадлагууд';

  @override
  String get connect_event_tab_accumulations => 'Хуримтлал';

  @override
  String get connect_event_tab_recitations => 'Уншлагууд';

  @override
  String get connect_event_add_recitations => 'Уншлага нэмэх';

  @override
  String get connect_event_add_recitations_message =>
      'Шууд дамжуулалттай хамт эсвэл энэ аппын гадуур хийсэн уншлагуудаа нэмэх';

  @override
  String get connect_event_every_day => 'Өдөр бүр';

  @override
  String connect_event_every_weekday(String weekday) {
    return '$weekday бүр';
  }

  @override
  String get connect_event_every_month => 'Сар бүр';

  @override
  String connect_event_every_date(String date) {
    return '$date бүр';
  }

  @override
  String get connect_event_about_empty =>
      'Арга хэмжээний мэдээлэл одоогоор алга';

  @override
  String get search_groups => 'Орон зай хайх';

  @override
  String get search_for_groups => 'Орон зай хайх';

  @override
  String get no_groups_found => 'Тохирох орон зай олдсонгүй';

  @override
  String get explore_coming_soon_subtitle =>
      'Дадлага, сургаал, нийгэмлэгийн арга хэмжээг нээх онцгой орчин';

  @override
  String get learn_coming_soon_subtitle =>
      'Өдөр тутмын амьдралд тохируулан зохиосон таны хувийн судлах төлөвлөгөө';

  @override
  String get creator_featured_plan => 'Онцлох төлөвлөгөө';

  @override
  String get audio_init_error =>
      'Дуу тоглуулагчийг эхлүүлэх боломжгүй. Холболтоо шалгаад дахин оролдоно уу';

  @override
  String get meditation_audio_load_error =>
      'Ачаалах боломжгүй. Холболтоо шалгаад дахин оролдоно уу';

  @override
  String get prayer_audio_load_error =>
      'Дуу ачаалах боломжгүй. Холболтоо шалгаад дахин оролдоно уу';

  @override
  String get home_no_series_found => 'Цуврал олдсонгүй';

  @override
  String get home_no_tags_found => 'Шошго олдсонгүй';

  @override
  String get home_celebrated_by => 'Тэмдэглэдэг:';

  @override
  String get reader_settings_tooltip => 'Уншигчийн тохиргоо';

  @override
  String get reader_translate_tooltip => 'Орчуулга харуулах';

  @override
  String get reader_translate_unavailable => 'Энэ текстэд орчуулга байхгүй';

  @override
  String get reader_font_size_tooltip => 'Үсгийн хэмжээ';

  @override
  String reader_version_title(String language) {
    return 'Хувилбар · $language';
  }

  @override
  String reader_script_title(String language) {
    return 'Бичиг · $language';
  }

  @override
  String get reader_versions_load_error => 'Хувилбаруудыг ачаалж чадсангүй';

  @override
  String get reader_scripts_load_error => 'Бичгүүдийг ачаалж чадсангүй';

  @override
  String get reader_languages_load_error => 'Хэлүүдийг ачаалж чадсангүй';

  @override
  String reader_no_versions_in_language(String language) {
    return '$language хэл дээр хувилбар байхгүй';
  }

  @override
  String reader_no_scripts_in_language(String language) {
    return '$language хэл дээр бичиг байхгүй';
  }

  @override
  String get reader_no_languages => 'Энэ бичвэрт хэл байхгүй';

  @override
  String get reader_license => 'Лиценз';

  @override
  String get reader_version_details_load_error =>
      'Хувилбарын дэлгэрэнгүйг ачаалах боломжгүй';

  @override
  String get reader_no_version_info => 'Энэ хувилбарт нэмэлт мэдээлэл байхгүй';

  @override
  String get recitation_unavailable =>
      'Уншлагын агуулга одоогоор байхгүй байна.\nДараа дахин оролдох эсвэл дэмжлэгтэй холбогдоно уу';

  @override
  String get recitation_sign_in_required =>
      'Энэ уншлагыг үзэхийн тулд нэвтэрнэ үү';

  @override
  String get my_recitations_load_error =>
      'Ачаалах боломжгүй.\nХолболтоо шалгаад дахин оролдоно уу';

  @override
  String get recitations_load_error =>
      'Уншлагуудыг ачаалах боломжгүй.\nДараа дахин оролдоно уу';

  @override
  String get text_search_hint => 'Хайхын тулд бичнэ үү';

  @override
  String get text_search_press_button => 'Хайхын тулд хайх товчийг дарна уу';

  @override
  String get text_search_error => 'Хайлт хийх боломжгүй.\nДахин оролдоно уу';

  @override
  String get unknown_error => 'Тодорхойгүй алдаа';

  @override
  String get create_image_share_error =>
      'Хуваалцах боломжгүй. Дахин оролдоно уу';

  @override
  String version_search_no_results(String query) {
    return '\"$query\"-д тохирох хувилбар олдсонгүй';
  }

  @override
  String get my_plans_sign_in_prompt =>
      'Төлөвлөгөөгөө харахын тулд нэвтэрнэ үү';

  @override
  String plan_starts_soon_message(String date) {
    return '$date-нд эхэлнэ. Та одоо агуулгыг үзэж болно';
  }

  @override
  String plan_joining_late_message(String date) {
    return '$date-нд эхэлсэн. Өмнөх өдрүүдийн даалгавруудыг чөлөөтэй гүйцэтгэж болно';
  }

  @override
  String get select_language => 'Хэл сонгох';

  @override
  String get logout_confirmation => 'Та гарахдаа итгэлтэй байна уу?';

  @override
  String get cancel => 'Цуцлах';

  @override
  String get copy => 'Хуулах';

  @override
  String get copied => 'Хууллаа';

  @override
  String get share => 'Хуваалцах';

  @override
  String get bookmark => 'Хавчууруулга';

  @override
  String get image => 'Зураг';

  @override
  String get feedback => 'Санал хүсэлт';

  @override
  String get author => 'Зохиогч';

  @override
  String get plans_created => 'Төлөвлөгөө үүсгэсэн';

  @override
  String get ai_confirm => 'Баталгаажуулах';

  @override
  String search_no_results(String query) {
    return '\"$query\"-д тохирох үр дүн олдсонгүй';
  }

  @override
  String get search_all => 'Бүгд';

  @override
  String get common_ok => 'За';

  @override
  String get comingSoonHeadline => 'Удахгүй';

  @override
  String get routine_title => 'Миний дадлагууд';

  @override
  String get bookmarks => 'Хавчуурга';

  @override
  String get routine_empty_title => 'Дадлагууд';

  @override
  String get routine_edit => 'Засах';

  @override
  String get routine_empty_description =>
      'Хэвшилдээ нэмэхийн тулд илүү олон сургаал, дадлагыг судал';

  @override
  String get routine_build => 'Хэвшлээ бий болго';

  @override
  String get routine_add_session => 'Дадлагад нэмэх';

  @override
  String get routine_edit_title => 'Хэвшлээ засах';

  @override
  String get routine_delete_block => 'Блок хасах';

  @override
  String get routine_session_title_hint => 'Гарчиг...';

  @override
  String get routine_expand_all => 'Бүгдийг дэлгэх';

  @override
  String get routine_collapse_all => 'Бүгдийг хураах';

  @override
  String get routine_delete_time_block => 'Цагийн блокыг устгах';

  @override
  String get routine_add_plan => 'Төлөвлөгөө нэмэх';

  @override
  String get routine_add_recitation => 'Уншлага нэмэх';

  @override
  String get routine_add_plan_to_routine => 'Хэвшилд нэмэх';

  @override
  String get routine_load_error =>
      'Ачаалах боломжгүй. Холболтоо шалгаад дахин оролдоно уу';

  @override
  String get routine_empty_block_title_singular => 'Хоосон цагийн блок';

  @override
  String routine_empty_block_title_plural(int count) {
    return 'Хоосон цагийн блокууд ($count)';
  }

  @override
  String get routine_empty_block_message_singular =>
      'Энэ цагийн блок хоосон байна. Зүйл нэмэх үү, эсвэл хэвшлээсээ хасах уу?';

  @override
  String routine_empty_block_message_plural(int count) {
    return '$count цагийн блок хоосон байна. Зүйл нэмэх үү, эсвэл хэвшлээсээ хасах уу?';
  }

  @override
  String get routine_empty_block_add_items => 'Зүйл нэмэх';

  @override
  String get routine_empty_block_delete_singular => 'Блок хасах';

  @override
  String get routine_empty_block_delete_plural => 'Блокууд хасах';

  @override
  String get routine_notification_title => 'Дадлагыг зуршил болго';

  @override
  String get routine_notification_description =>
      'Бид танд дадлага хийхийг сануулахын тулд мэдэгдэл зөвшөөрнө үү';

  @override
  String get routine_notification_enable => 'Мэдэгдэл идэвхжүүлэх';

  @override
  String get routine_notification_skip => 'Алгасах';

  @override
  String routine_time_adjusted(String time, int gap) {
    return '$time болгон тохируулсан ($gap мин доод зай)';
  }

  @override
  String get routine_add_block_label => 'Цагийн блок';

  @override
  String get continueWithGoogle => 'Google-ээр үргэлжлүүлэх';

  @override
  String get continueWithApple => 'Apple-ээр үргэлжлүүлэх';

  @override
  String get continueWithPhone => 'Утсаар үргэлжлүүлэх';

  @override
  String get continueAsGuest => 'Зочноор үргэлжлүүлэх';

  @override
  String get exploreAsGuest => 'Зочноор судлах';

  @override
  String get signIn => 'Нэвтрэх';

  @override
  String get profileError => 'Профайл ачаалахад алдаа гарлаа';

  @override
  String get profileTitle => 'Профайл';

  @override
  String get notLoggedIn => 'Нэвтрээгүй байна';

  @override
  String get retry => 'Дахин оролдох';

  @override
  String get back => 'Буцах';

  @override
  String get delete => 'Устгах';

  @override
  String get close => 'Хаах';

  @override
  String get tryAgain => 'Дахин оролдох';

  @override
  String get pleaseTryAgain => 'Дахин оролдоно уу';

  @override
  String get error => 'Алдаа';

  @override
  String get anonymous => 'Нэргүй';

  @override
  String get noContentAvailable => 'Агуулга байхгүй байна';

  @override
  String get unableToLoad =>
      'Ачаалах боломжгүй. Холболтоо шалгаад дахин оролдоно уу';

  @override
  String get somethingWrong =>
      'Алдаа гарлаа. Холболтоо шалгаад дахин оролдоно уу';

  @override
  String get source => 'Эх сурвалж';

  @override
  String get searchResults => 'Хайлтын үр дүн';

  @override
  String get noTasks => 'Даалгавар байхгүй байна';

  @override
  String get taskNotFound => 'Даалгавар олдсонгүй';

  @override
  String get updateTaskError => 'Даалгаврын төлөвийг шинэчлэх боломжгүй';

  @override
  String get enrollError =>
      'Бүртгэх боломжгүй байна. Холболтоо шалгаад дахин оролдоно уу';

  @override
  String unenrollSuccess(String planTitle) {
    return 'Та $planTitle-аас бүртгэлээ цуцаллаа';
  }

  @override
  String get unenrollError =>
      'Бүртгэл цуцлах боломжгүй байна. Холболтоо шалгаад дахин оролдоно уу';

  @override
  String get unenrollGenericError =>
      'Алдаа гарлаа. Холболтоо шалгаад дахин оролдоно уу';

  @override
  String get notFound =>
      'Энэ нь цаашид байхгүй болсон. Шинэчлэхийн тулд хэвшлээ засна уу';

  @override
  String get noTimeSlot => 'Сул цагийн зай байхгүй. Эхлээд блок хасаж үзнэ үү';

  @override
  String maxBlocks(int max) {
    return 'Дээд тал нь $max цагийн блокт хүрсэн';
  }

  @override
  String get duplicateItem => 'Энэ зүйл аль хэдийн блокт байна';

  @override
  String get removeItem => 'Зүйл хасах уу?';

  @override
  String removeConfirmation(String itemName) {
    return '\"$itemName\" энэ блокоос хасагдана';
  }

  @override
  String shareError(String error) {
    return 'Хуваалцах боломжгүй. Дахин оролдоно уу';
  }

  @override
  String get updateOrderError =>
      'Дарааллыг шинэчлэх боломжгүй. Дахин оролдоно уу';

  @override
  String get loadFailed =>
      'Ачаалах боломжгүй. Холболтоо шалгаад дахин оролдоно уу';

  @override
  String get captureError => 'QR кодыг авч чадсангүй. Дахин оролдоно уу';

  @override
  String get qrShareError =>
      'QR кодыг хуваалцах боломжгүй. Дараа дахин оролдоно уу';

  @override
  String errorDetail(String error) {
    return 'Алдаа: $error';
  }

  @override
  String missedDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count өдөр алгассан',
      one: '1 өдөр алгассан',
      zero: '0 өдөр алгассан',
    );
    return '$_temp0';
  }

  @override
  String get plan_status_on_track => 'Хэвийн явж байна!';

  @override
  String get start_now => 'Одоо эхлэх';

  @override
  String get plan_enroll => 'Бүртгүүлэх';

  @override
  String get show_second_version => 'Хоёр дахь хувилбарыг харах';

  @override
  String get enable_add_msg =>
      'Үндсэн бичвэрийн хажууд орчуулга эсвэл галиглал нэмэхийн тулд идэвхжүүлнэ үү';

  @override
  String get main_version => 'Үндсэн хувилбар';

  @override
  String get second_version => 'Хоёр дахь хувилбар';

  @override
  String get second_version_msg =>
      'Хоёр дахь хувилбар нь үндсэн бичвэрийн бадаг бүрийн доор гарч ирнэ';

  @override
  String get root_text => 'Үндсэн бичвэр';

  @override
  String get version => 'Хувилбарууд';

  @override
  String get parallel_version => 'Зэрэгцээ хувилбар';

  @override
  String get reader_languages_title => 'Хэлүүд';

  @override
  String get reader_original_label => 'Эх';

  @override
  String get reader_translation_label => 'Орчуулга';

  @override
  String get version_not_available => 'Байхгүй';

  @override
  String get read_full_text => 'Бүтэн бичвэрийг унших';

  @override
  String get reader_source_label => 'Эх сурвалж';

  @override
  String get reader_license_label => 'Лиценз';

  @override
  String series_stats(int planCount, int totalDays) {
    return '$planCount БҮЛЭГ · $totalDays ӨДӨР';
  }

  @override
  String get force_update_title => 'Шинэчлэл шаардлагатай';

  @override
  String get force_update_message =>
      'Аппын шинэ хувилбар гарсан. Үргэлжлүүлэхийн тулд шинэчлэнэ үү';

  @override
  String get force_update_button => 'Одоо шинэчлэх';

  @override
  String get settings_section_personalisation => 'ХУВИЙН ТОХИРГОО';

  @override
  String get settings_section_more => 'БУСАД';

  @override
  String get settings_section_account => 'БҮРТГЭЛ';

  @override
  String get settings_edit_profile => 'Профайл засах';

  @override
  String get settings_theme => 'Загвар';

  @override
  String get settings_notification_row => 'Мэдэгдэл';

  @override
  String get settings_feedback_row => 'Санал хүсэлт';

  @override
  String get edit_profile_title => 'Профайл засах';

  @override
  String get edit_profile_save => 'Хадгалах';

  @override
  String get edit_profile_first_name => 'Нэр';

  @override
  String get edit_profile_last_name => 'Овог';

  @override
  String get edit_profile_bio => 'Танилцуулга';

  @override
  String get edit_profile_bio_hint =>
      'Өөрийнхөө тухай бага зэрэг хуваалцана уу';

  @override
  String get edit_profile_delete_account => 'Бүртгэл устгах';

  @override
  String get edit_profile_photo_not_uploaded => 'Зураг байршуулаагүй';

  @override
  String get edit_profile_photo_too_large =>
      'Зураг хэт том байна. 1 МБ-аас бага зураг сонгоод дахин оролдоно уу';

  @override
  String get edit_profile_photo_upload_failed =>
      'Зургийг тань байршуулж чадсангүй. Дахин оролдоно уу';

  @override
  String get edit_profile_choose_from_library => 'Сангаас сонгох';

  @override
  String get edit_profile_take_photo => 'Зураг авах';

  @override
  String get edit_profile_offline =>
      'Та офлайн байна. Интернэтэд холбогдоод дахин оролдоно уу';

  @override
  String get edit_profile_save_failed =>
      'Таны өөрчлөлтийг хадгалж чадсангүй. Дахин оролдоно уу';

  @override
  String get edit_profile_traditions => 'Уламжлал';

  @override
  String get edit_profile_choose_traditions => 'Уламжлалаа сонгоно уу';

  @override
  String get edit_profile_tradition_remove_failed =>
      'Уламжлалыг устгаж чадсангүй. Дахин оролдоно уу';

  @override
  String get edit_profile_tradition_save_failed =>
      'Уламжлалыг хадгалж чадсангүй. Дахин оролдоно уу';

  @override
  String get username_label => 'Хэрэглэгчийн нэр';

  @override
  String get username_taken =>
      'Энэ нэрийг хэн нэгэн аль хэдийн ашигласан байна';

  @override
  String get username_available_label => 'Боломжтой:';

  @override
  String get username_check_error =>
      'Хэрэглэгчийн нэрийг шалгах боломжгүй. Дахин оролдоно уу';

  @override
  String get username_invalid_format => 'Хэрэглэгчийн нэрийн формат буруу';

  @override
  String get username_min_length =>
      'Хэрэглэгчийн нэр дор хаяж 3 тэмдэгт байх ёстой';

  @override
  String get username_max_length =>
      'Хэрэглэгчийн нэр 30 тэмдэгт буюу түүнээс бага байх ёстой';

  @override
  String get username_no_spaces => 'Хэрэглэгчийн нэр зай агуулж болохгүй';

  @override
  String get username_invalid_chars => 'Зөвхөн үсэг, тоо, _ . - зөвшөөрөгдөнө';

  @override
  String get username_must_start_alphanumeric =>
      'Хэрэглэгчийн нэр үсэг эсвэл тоогоор эхлэх ёстой';

  @override
  String get username_must_end_alphanumeric =>
      'Хэрэглэгчийн нэр үсэг эсвэл тоогоор төгсөх ёстой';

  @override
  String get person_name_min_length => 'Дор хаяж 1 тэмдэгт байх ёстой';

  @override
  String get person_name_max_length =>
      '50 тэмдэгт эсвэл түүнээс бага байх ёстой';

  @override
  String get person_name_invalid_chars =>
      'Зөвхөн үсэг, зай, зурааст (-) ба апостроф (\') зөвшөөрнө';

  @override
  String get about_title => 'Тухай';

  @override
  String get about_connect_with_us => 'Бидэнтэй холбогдох...';

  @override
  String get about_description =>
      'Бид буддистуудад өдөр бүр суралцаж, дадлага хийж, бусадтай холбогдох замаар хор хөнөөлийг багасгаж, сайн үйлийг арвижуулж, өөрийн сэтгэлээ илүү сайн таньж мэдэхэд тусалдаг.';

  @override
  String get about_social_website => 'Вэбсайт';

  @override
  String get me_guest_headline => 'Бүрэн боломжийг нээ';

  @override
  String get me_guest_subtitle =>
      'Ахицаа хадгалахын тулд үнэгүй бүртгэл үүсгэнэ үү';

  @override
  String get me_my_stats => 'Миний статистик';

  @override
  String me_day_streak(int count) {
    return '$count өдрийн дараалал';
  }

  @override
  String me_best_streak(int count) {
    return 'Хамгийн урт дараалал: $count өдөр';
  }

  @override
  String get accumulations => 'Хуримтлал';

  @override
  String get accumulations_search => 'Хуримтлал хайх...';

  @override
  String get accumulations_search_for => 'Хуримтлал хайх';

  @override
  String get accumulations_no_found => 'Хуримтлал олдсонгүй';

  @override
  String get me_accumulation => 'Нийт хуримтлал';

  @override
  String get me_counts => 'удаа';

  @override
  String get me_minutes => 'минут';

  @override
  String get me_hours => 'цаг';

  @override
  String get me_total_meditation_time => 'Нийт бясалгалын хугацаа';

  @override
  String get me_days_plan_practiced_suffix => 'Нийт дуусгасан төлөвлөгөөт өдөр';

  @override
  String me_streak_share_message(int count, String appName) {
    return 'Би $appName дээр $count өдрийн дараалалтай байна!';
  }

  @override
  String get me_streak_share_quote =>
      'WeBuddhist дээрх миний одоогийн дараалал!';

  @override
  String me_streak_days_count(int count) {
    return '$count өдөр';
  }

  @override
  String get share_this_streak => 'Дарааллаа хуваалцах';

  @override
  String get me_streak_share_error =>
      'Дарааллыг хуваалцах боломжгүй. Дахин оролдоно уу';

  @override
  String get delete_account_title => 'Бүртгэл устгах';

  @override
  String get delete_account_description =>
      'Хэрэв та бүртгэлээ устгавал WeBuddhist доторх таны бүх мэдээлэл, түүх, хувийн тохиргоо бүрмөсөн устгагдана. Энэ үйлдлийг буцаах боломжгүйг анхаарна уу. Үргэлжлүүлэхийн тулд доорх товчийг дарна уу.';

  @override
  String get delete_account_button => 'Бүртгэл устгах';

  @override
  String get delete_account_confirm_message =>
      'Та WeBuddhist бүртгэлээ устгахдаа итгэлтэй байна уу?';

  @override
  String get legal_title => 'Хууль эрх зүй';

  @override
  String get legal_terms_of_service => 'Үйлчилгээний нөхцөл';

  @override
  String get legal_privacy_policy => 'Нууцлалын бодлого';

  @override
  String get follow => 'Дагах';

  @override
  String get following => 'Дагаж байна';

  @override
  String get calendar_title => 'Хуанли';

  @override
  String get calendar_upcoming_events => 'Удахгүй болох арга хэмжээ';

  @override
  String get calendar_day_short => 'ӨДӨР';

  @override
  String get calendar_day_label => 'Өдөр';

  @override
  String calendar_day_month(int day, int month) {
    return '$day-р өдөр · $month-р сар';
  }

  @override
  String calendar_lunar_month(String ordinal) {
    return '$ordinal билгийн сар';
  }

  @override
  String get moon_phase_new_moon => 'Шинэ сар';

  @override
  String get moon_phase_waxing_crescent => 'Өсөх хавирган сар';

  @override
  String get moon_phase_first_quarter => 'Тэргүүн улирал';

  @override
  String get moon_phase_waxing_gibbous => 'Өсөх дугуйвтар сар';

  @override
  String get moon_phase_full_moon => 'Тэргэл сар';

  @override
  String get moon_phase_waning_gibbous => 'Хорогдох дугуйвтар сар';

  @override
  String get moon_phase_last_quarter => 'Эцсийн улирал';

  @override
  String get moon_phase_waning_crescent => 'Хорогдох хавирган сар';

  @override
  String get join => 'Нэгдэх';

  @override
  String get joined => 'Нэгдсэн';

  @override
  String get group_member => 'гишүүн';

  @override
  String get group_members => 'гишүүд';

  @override
  String get group_tab_members => 'Гишүүд';

  @override
  String get group_tab_followers => 'Дагагчид';

  @override
  String group_members_heading(int count) {
    return 'Гишүүд ($count)';
  }

  @override
  String group_followers_heading(int count) {
    return 'Дагагчид($count)';
  }

  @override
  String get group_invite => 'Урих';

  @override
  String get group_notifications_title => 'Мэдэгдэл';

  @override
  String get group_notifications_chat => 'Орон зайн чат';

  @override
  String get group_notifications_content => 'Орон зайн агуулга';

  @override
  String get group_notifications_master_off =>
      'Аппын мэдэгдэл унтраалттай байна';

  @override
  String get group_notifications_open_settings => 'Асаах';

  @override
  String get group_notifications_update_failed =>
      'Мэдэгдлийн тохиргоог шинэчилж чадсангүй. Дахин оролдоно уу';

  @override
  String get group_notifications_load_failed =>
      'Мэдэгдлийн тохиргоог ачаалж чадсангүй';

  @override
  String get group_chat_mute_notifications => 'Чатын мэдэгдлийг хаах';

  @override
  String get group_chat_unmute_notifications => 'Чатын мэдэгдлийг нээх';

  @override
  String get group_chat_notifications_muted => 'Чатын мэдэгдэл хаагдлаа';

  @override
  String get group_chat_notifications_unmuted => 'Чатын мэдэгдэл асаалттай';

  @override
  String get group_leave => 'Гарах';

  @override
  String get group_leave_confirm_title => 'Гарах уу?';

  @override
  String get group_leave_confirm_message =>
      'Та энэ орон зайгаас зурвас, мэдээ авахаа болино';

  @override
  String get group_leave_failed => 'Гарч чадсангүй. Дахин оролдоно уу';

  @override
  String get group_request_to_join => 'Нэгдэх хүсэлт';

  @override
  String get group_request => 'Нэгдэх хүсэлт';

  @override
  String get group_request_sent => 'Хүсэлт илгээсэн';

  @override
  String get group_join_request_title => 'Нэгдэх хүсэлт';

  @override
  String get group_join_request_message_label => 'Зурвас (заавал биш)';

  @override
  String get group_join_request_message_hint =>
      'Та хэрхэн дадлага хийдэг вэ, эсвэл хэн таныг урьсан бэ?';

  @override
  String get group_join_request_send => 'Хүсэлт илгээх';

  @override
  String get group_join_request_sent_snackbar =>
      'Хүсэлт илгээгдлээ. Админ үүнийг хянана';

  @override
  String get group_join_request_error =>
      'Хүсэлт илгээх боломжгүй байна. Дахин оролдоно уу';

  @override
  String get group_join_requests_title => 'Нэгдэх хүсэлтүүд';

  @override
  String get group_join_requests_admit => 'Зөвшөөрөх';

  @override
  String get group_join_requests_deny => 'Татгалзах';

  @override
  String get group_join_requests_empty => 'Хүлээгдэж буй хүсэлт алга';

  @override
  String get group_join_requests_load_error =>
      'Нэгдэх хүсэлтүүдийг ачаалж чадсангүй. Дахин оролдоно уу';

  @override
  String get group_join_requests_admit_error =>
      'Энэ хүсэлтийг зөвшөөрч чадсангүй. Дахин оролдоно уу';

  @override
  String get group_join_requests_deny_error =>
      'Энэ хүсэлтээс татгалзаж чадсангүй. Дахин оролдоно уу';

  @override
  String get group_reports_title => 'Гомдол';

  @override
  String get group_reports_section_posts => 'Нийтлэлүүд';

  @override
  String get group_reports_section_comments => 'Сэтгэгдлүүд';

  @override
  String get group_reports_section_messages => 'Мессежүүд';

  @override
  String group_reports_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count гомдол',
    );
    return '$_temp0';
  }

  @override
  String get group_reports_view_post => 'Нийтлэл харах';

  @override
  String get group_reports_view_message => 'Мессеж харах';

  @override
  String get group_reports_delete_post => 'Нийтлэл устгах';

  @override
  String get group_reports_delete_comment => 'Сэтгэгдэл устгах';

  @override
  String get group_reports_delete_message => 'Мессеж устгах';

  @override
  String get group_reports_empty => 'Хянах гомдол алга';

  @override
  String get group_reports_load_error =>
      'Гомдлуудыг ачаалж чадсангүй. Дахин оролдоно уу';

  @override
  String get group_reports_delete_confirm_title => 'Та итгэлтэй байна уу?';

  @override
  String get group_reports_delete_message_confirm =>
      'Энэ мессеж бүрмөсөн устгагдана';

  @override
  String get group_reports_message_removed => 'Мессежийг устгалаа';

  @override
  String get group_reports_delete_message_error =>
      'Мессежийг устгаж чадсангүй. Дахин оролдоно уу';

  @override
  String get group_members_only_title => 'Зөвхөн гишүүдэд';

  @override
  String get group_members_only_message =>
      'Агуулгыг үзэхийн тулд энэ орон зайд нэгдээрэй';

  @override
  String get group_join_request_waiting_title => 'Админы хариуг хүлээж байна';

  @override
  String get group_join_request_waiting_message =>
      'Таны хүсэлтийг хянасны дараа бид танд мэдэгдэнэ';

  @override
  String get group_members_load_error =>
      'Гишүүдийг ачаалж чадсангүй. Дахин оролдоно уу';

  @override
  String get group_followers_load_error =>
      'Дагагчдыг ачаалж чадсангүй. Дахин оролдоно уу.';

  @override
  String get group_members_empty => 'Одоогоор гишүүн байхгүй';

  @override
  String get group_member_admin => 'Админ';

  @override
  String get group_member_owner => 'Owner';

  @override
  String group_remove_member(String name) {
    return '$name-г хасах';
  }

  @override
  String get group_remove_member_title => 'Орон зайгаас хасах уу?';

  @override
  String group_remove_member_message(String name) {
    return '$name энэ орон зайгаас хасагдах бөгөөд хориг цуцлагдах хүртэл дахин нэгдэх боломжгүй';
  }

  @override
  String get group_remove_member_blocked_for => 'Хоригийн хугацаа:';

  @override
  String get group_remove_member_duration_day => '1 өдөр';

  @override
  String group_remove_member_duration_days(int count) {
    return '$count өдөр';
  }

  @override
  String get group_remove_member_duration_year => '1 жил';

  @override
  String get group_remove_member_reason_label => 'Шалтгаан (заавал биш)';

  @override
  String get group_remove_member_reason_hint => 'Бусад...';

  @override
  String get group_remove_member_action => 'Хасах';

  @override
  String group_remove_member_success(String name) {
    return '$name орон зайгаас хасагдлаа';
  }

  @override
  String get group_remove_member_error =>
      'Энэ гишүүнийг хасаж чадсангүй. Дахин оролдоно уу';

  @override
  String group_join_banned_until(String date) {
    return 'Та энэ орон зайгаас хасагдсан тул $date хүртэл дахин нэгдэх боломжгүй';
  }

  @override
  String get group_join_banned =>
      'Та энэ орон зайгаас хасагдсан тул хориг цуцлагдах хүртэл дахин нэгдэх боломжгүй';

  @override
  String get group_removed_title => 'Та энэ орон зайгаас хасагдсан байна';

  @override
  String group_removed_message(String group, String duration) {
    return '$group-ийн админ таныг энэ орон зайгаас хаслаа. Та $duration-ийн турш түүний нийтлэл, арга хэмжээ, дадлагыг үзэх эсвэл дахин нэгдэх хүсэлт гаргах боломжгүй.';
  }

  @override
  String group_removed_message_no_date(String group) {
    return '$group-ийн админ таныг энэ орон зайгаас хаслаа. Та түүний нийтлэл, арга хэмжээ, дадлагыг үзэх эсвэл дахин нэгдэх хүсэлт гаргах боломжгүй';
  }

  @override
  String get group_removed_rejoin_label =>
      'Та энэ орон зайд нэгдэх хүсэлтийг дараах өдөр гаргах боломжтой';

  @override
  String group_removed_rejoin_value(String date, String remaining) {
    return '$date · $remaining';
  }

  @override
  String get group_removed_day_left => '1 өдөр үлдсэн';

  @override
  String group_removed_days_left(int count) {
    return '$count өдөр үлдсэн';
  }

  @override
  String get group_removed_last_day => 'Нэг өдөр хүрэхгүй хугацаа үлдсэн';

  @override
  String get group_followers_empty => 'Одоогоор дагагч байхгүй';

  @override
  String get group_follower => 'дагагч';

  @override
  String get group_followers => 'дагагчид';

  @override
  String get group_links_title => 'Холбоосууд';

  @override
  String get group_about_description => 'Тайлбар';

  @override
  String get group_about_empty => 'Одоогоор мэдээлэл алга';

  @override
  String group_and_more_links(int count) {
    return 'болон дахиад $count холбоос';
  }

  @override
  String get group_practice_with_us => 'Бидэнтэй хамт дадлага хий';

  @override
  String series_practicing_with_group(String groupName) {
    return '$groupName-тай хамт дадлага хийж байна';
  }

  @override
  String get group_change_practice_title => 'Дадлагын орон зайг өөрчлөх';

  @override
  String get group_change_practice_message =>
      'Та энэ төлөвлөгөөг өөр орон зайтай хамт аль хэдийн дадлага хийж байна. Дадлагын орон зайгаа өөрчлөх үү?';

  @override
  String get group_join_to_contribute => 'Хувь нэмэр оруулахын тулд нэгдэх';

  @override
  String get group_accumulator_join_error =>
      'Хуримтлалд нэгдэх боломжгүй байна. Дахин оролдоно уу';

  @override
  String get group_accumulator_join_before_practice =>
      'Дадлагадаа нэмэхээсээ өмнө энэ хуримтлалд нэгдээрэй';

  @override
  String group_accumulator_participants(int count) {
    return '$count оролцогч';
  }

  @override
  String get group_accumulator_leaderboard => 'Тэргүүлэгчдийн самбар';

  @override
  String get group_accumulator_my_contributions => 'Миний хувь нэмэр';

  @override
  String get group_accumulator_recited => 'Уншсан';

  @override
  String get group_accumulator_total => 'Нийт';

  @override
  String get group_accumulator_contributions_empty =>
      'Хувь нэмрээ хянахын тулд энэ хуримтлалд нэгдэнэ үү';

  @override
  String get group_accumulator_leaderboard_empty => 'Одоогоор уншлага алга';

  @override
  String get group_accumulator_recite_now => 'Одоо уншина уу';

  @override
  String get group_accumulator_chant_again => 'Дахин унших';

  @override
  String get group_accumulator_finish_session => 'Хуралдааныг дуусгах';

  @override
  String get group_accumulator_offline_recitation => 'Офлайн уншлага';

  @override
  String get group_accumulator_add_offline_chants_title =>
      'Офлайн уншлага нэмэх:';

  @override
  String get group_accumulator_add_offline_chants_message =>
      'Энэ аппаас гадуур хийсэн уншлагынхаа тоог нэмнэ үү';

  @override
  String get group_accumulator_session_complete => 'Хуралдаан дууслаа!';

  @override
  String group_accumulator_session_recitations(int count) {
    return 'Та энэ хуралдаанд $count уншлага гүйцэтгэлээ';
  }

  @override
  String group_accumulator_session_share_message(
    int count,
    String accumulation,
    String group,
  ) {
    return 'Би WeBuddhist дээрх $group орон зайн \"$accumulation\" хуримтлалд $count уншлага гүйцэтгэлээ. Та ч бас надтай нэгдээрэй!';
  }

  @override
  String group_accumulator_session_share_message_no_group(
    int count,
    String accumulation,
  ) {
    return 'Би WeBuddhist дээр \"$accumulation\" хуримтлалд $count уншлага гүйцэтгэлээ. Та ч бас надтай нэгдээрэй!';
  }

  @override
  String get group_accumulator_session_share_error =>
      'Хуралдааныг хуваалцаж чадсангүй. Дахин оролдоно уу';

  @override
  String group_recitation_collection_share_message(
    String collection,
    String group,
  ) {
    return 'WeBuddhist дээрх $group орон зайн \"$collection\" уншлагын цуглуулгыг үзээрэй. Бидэнтэй хамт дадлага хийцгээе!';
  }

  @override
  String group_recitation_collection_share_message_no_group(String collection) {
    return 'WeBuddhist дээрх \"$collection\" уншлагын цуглуулгыг үзээрэй. Бидэнтэй хамт дадлага хийцгээе!';
  }

  @override
  String group_recitation_collection_completed_title(String collection) {
    return '$collection completed';
  }

  @override
  String get group_recitation_collection_dedication =>
      'By this merit, may all beings\nbe free from suffering';

  @override
  String get share_this_quote => 'Энэ ишлэлийг хуваалцах';

  @override
  String get shared_from => 'Хуваалцсан:';

  @override
  String get verse_share_error =>
      'Ишлэлийг хуваалцах боломжгүй. Дахин оролдоно уу';

  @override
  String get share_app_message =>
      'Би өдөр тутмын Буддын дадлага хийхийн тулд энэ аппыг ашиглаж байна, та ч дуртай болно гэж бодлоо.';

  @override
  String get share_streak_message =>
      'Би өдөр тутмын дадлагын зуршил хэлбэрийг бүрдүүлж байгаа бөгөөд үүнийгээ танд хуваалцахыг хүссэн. Найзтайгаа хамт хэвшлээ хадгалахад илүү хялбар байдаг. WeBuddhist дээр надтай нэгдээрэй.';

  @override
  String get share_chant_message =>
      'Би энэ дуулалыг тантай хуваалцахыг хүссэн. Та үүнийг дадлагажуулж, WeBuddhist дээр бусад дуулал болон судруудын бүтэн номын санг олж болно.';

  @override
  String get share_quote_message =>
      'Надад WeBuddhist дээрх энэ ишлэл таалагдсан тул тантай хуваалцахыг хүссэн. WeBuddhist аппликейшн дээр ийм мэдлэгтэй ишлэлүүдийг уншаарай.';

  @override
  String get share_poem_message =>
      'Надад WeBuddhist дээрх энэ шүлэг таалагдсан тул тантай хуваалцахыг хүссэн.';

  @override
  String share_poem_title(String title) {
    return '“$title”';
  }

  @override
  String get share_mala_message =>
      'Би WeBuddhist дээрх энэ тоолуурыг ашиглаж байгаа бөгөөд тантай хуваалцахыг хүссэн. Хаана ч байсан дадлагажуулахад хялбар арга юм.';

  @override
  String get share_passage_message =>
      'Надад энэ хэсэг таалагдсан тул тантай хуваалцахыг хүссэн. WeBuddhist дээр бүтэн ишлэлийг уншиж болно.';

  @override
  String get share_timer_message =>
      'Би WeBuddhist дээрх энэ бясалгалын таймерыг тантай хуваалцахыг хүссэн. Бясалгалын дадлага хийхэд хялбар болгодог.';

  @override
  String get share_plan_message =>
      'Би энэ Буддын дадлагын төлөвлөгөөг дагаж байгаа бөгөөд тантай хуваалцахыг хүссэн. WeBuddhist дээр надтай үнэгүй нэгдэж болно.';

  @override
  String get share_plan_subject => 'WeBuddhist дээр надтай нэгдээрэй';

  @override
  String get share_group_invite_message =>
      'Энэ орон зайд надтай нэгдээрэй. WeBuddhist дээр хамтдаа дадлага хийцгээе!';

  @override
  String get weekday_monday => 'Дав';

  @override
  String get weekday_tuesday => 'Мяг';

  @override
  String get weekday_wednesday => 'Лха';

  @override
  String get weekday_thursday => 'Пүр';

  @override
  String get weekday_friday => 'Баа';

  @override
  String get weekday_saturday => 'Бям';

  @override
  String get weekday_sunday => 'Ням';

  @override
  String get reader_search_failed =>
      'Хайлт амжилтгүй боллоо.\nДахин оролдоно уу';

  @override
  String get reader_swipe_up_for_more =>
      'Илүү ихийг үзэхийн тулд дээш шудрана уу';

  @override
  String get reader_videos => 'Бичлэгүүд';

  @override
  String get reader_about_this_version => 'Энэ хувилбарын тухай';

  @override
  String reader_version_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count хувилбар',
      one: '1 хувилбар',
    );
    return '$_temp0';
  }

  @override
  String get mala_no_mantras => 'Тарни алга байна';

  @override
  String get mala_count_load_error => 'Таны тоог ачаалж чадсангүй';

  @override
  String get mala_mantra_label => 'Тарни';

  @override
  String get bookmarks_empty_all_title => 'Хараахан хавчуургалаагүй байна';

  @override
  String get bookmarks_empty_all_subtitle =>
      'Энд хадгалахын тулд юуг ч хавчуургалаарай';

  @override
  String get bookmarks_empty_plans_title =>
      'Хараахан төлөвлөгөө хавчуургалаагүй байна';

  @override
  String get bookmarks_empty_plans_subtitle =>
      'Энд хадгалахын тулд төлөвлөгөө хавчуургалаарай';

  @override
  String get bookmarks_empty_malas_title =>
      'Хараахан эрх хавчуургалаагүй байна';

  @override
  String get bookmarks_empty_malas_subtitle =>
      'Энд хадгалахын тулд эрх хавчуургалаарай';

  @override
  String get bookmarks_empty_group_accumulations_title =>
      'Хараахан орон зайн хуримтлал хавчуургалаагүй байна';

  @override
  String get bookmarks_empty_group_accumulations_subtitle =>
      'Энд хадгалахын тулд хуримтлал хавчуургалаарай';

  @override
  String get bookmarks_empty_timers_title =>
      'Хараахан цаг хэмжигч хавчуургалаагүй байна';

  @override
  String get bookmarks_empty_timers_subtitle =>
      'Энд хадгалахын тулд цаг хэмжигч хавчуургалаарай';

  @override
  String get bookmarks_empty_texts_title =>
      'Хараахан бичвэр хавчуургалаагүй байна';

  @override
  String get bookmarks_empty_texts_subtitle =>
      'Энд хадгалахын тулд бичвэр хавчуургалаарай';

  @override
  String get bookmark_removed => 'Хавчуургыг устгалаа';

  @override
  String get bookmark_remove_failed => 'Хавчуургыг устгаж чадсангүй';

  @override
  String get bookmark_saved => 'Хавчуургыг хадгаллаа';

  @override
  String get bookmark_save_failed => 'Хавчуургыг хадгалж чадсангүй';

  @override
  String get bookmarks_yesterday => 'Өчигдөр';

  @override
  String get webview_timeout_error =>
      'Хуудас ачаалахад хэт удлаа. Интернэт холболтоо шалгана уу';

  @override
  String get webview_load_failed => 'Хуудсыг ачаалж чадсангүй';

  @override
  String get privacy_policy_load_error =>
      'Нууцлалын бодлогын хуудсыг ачаалж чадсангүй';

  @override
  String get terms_of_service_load_error =>
      'Үйлчилгээний нөхцлийн хуудсыг ачаалж чадсангүй';

  @override
  String get series_enroll_error => 'Цувралд бүртгүүлж чадсангүй';

  @override
  String series_share_message(String title, String url) {
    return 'WeBuddhist дээр $title-г надтай хамт дадлагажаарай.\n\n$url';
  }

  @override
  String get player_back_10 => '10 секунд ухраах';

  @override
  String get player_pause => 'Түр зогсоох';

  @override
  String get player_play => 'Тоглуулах';

  @override
  String get player_forward_10 => '10 секунд урагшлуулах';

  @override
  String get player_fullscreen => 'Бүтэн дэлгэц';

  @override
  String get player_exit_fullscreen => 'Бүтэн дэлгэцээс гарах';

  @override
  String get session_plans_load_error =>
      'Төлөвлөгөөг ачаалж чадсангүй.\nДараа дахин оролдоно уу';

  @override
  String get session_chants_load_error => 'Уншлагыг ачаалж чадсангүй';

  @override
  String get session_no_chants => 'Уншлага олдсонгүй';

  @override
  String get session_malas_load_error => 'Малаг ачаалж чадсангүй';

  @override
  String get session_no_malas => 'Мала олдсонгүй';

  @override
  String get session_timers_load_error => 'Цаг хэмжигчийг ачаалж чадсангүй';

  @override
  String get session_no_timers => 'Цаг хэмжигч олдсонгүй';

  @override
  String days_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count өдөр',
      one: '1 өдөр',
    );
    return '$_temp0';
  }

  @override
  String timer_minute_session(int minutes) {
    return '$minutes минутын дасгал';
  }

  @override
  String get timer_notification_in_progress => 'Бясалгал үргэлжилж байна';

  @override
  String timer_notification_paused(String time) {
    return 'Түр зогссон · $time үлдсэн';
  }

  @override
  String get timer_notification_complete => 'Таны хуралдаан дууслаа';

  @override
  String plan_day_of(int day, int total) {
    return '$total өдрийн $day-р өдөр';
  }

  @override
  String pagination_position(int current, int total) {
    return '$total-аас $current';
  }

  @override
  String get plan_shorts_title => 'Хамт олны богино бичлэгүүд';

  @override
  String get author_details_load_error =>
      'Зохиогчийн мэдээллийг ачаалж чадсангүй.\nДахин оролдоно уу';

  @override
  String get link_cannot_open => 'Энэ холбоосыг нээж чадсангүй';

  @override
  String get link_invalid => 'Буруу URL';

  @override
  String get author_no_plans => 'Одоогоор төлөвлөгөө үүсгээгүй байна';

  @override
  String get author_plans_load_error => 'Төлөвлөгөөг ачаалж чадсангүй';

  @override
  String source_with_value(String value) {
    return 'Эх сурвалж: $value';
  }

  @override
  String license_with_value(String value) {
    return 'Лиценз: $value';
  }

  @override
  String loading_previous_pages(int count) {
    return 'Өмнөхийг ачаалж байна... ($count хуудас)';
  }

  @override
  String loading_more_pages(int count) {
    return 'Илүү ихийг ачаалж байна... ($count хуудас)';
  }

  @override
  String get drag_to_resize => 'Хэмжээг өөрчлөхийн тулд чирнэ үү';

  @override
  String get day_completion_share_message =>
      'Би WeBuddhist дээр өөрийн дадлагын нэг өдрийг дуусгалаа. Надтай нэгдэж, хамтдаа өдөр тутмын дадлагын зуршил бий болгоцгооё.';

  @override
  String group_accumulator_share_message(String accumulation, String group) {
    return 'Би WeBuddhist дээрх $group орон зайн \"$accumulation\" хуримтлалд оролцож байна. Та ч бас надтай нэгдээрэй!';
  }

  @override
  String group_accumulator_share_message_no_group(String accumulation) {
    return 'Би WeBuddhist дээр \"$accumulation\" хуримтлалд оролцож байна. Та ч бас надтай нэгдээрэй!';
  }

  @override
  String get group_chat_title => 'Чат';

  @override
  String get chats_title => 'Чатууд';

  @override
  String get chats_empty_title => 'Одоогоор чат алга';

  @override
  String get chats_empty_body => 'Чатлаж эхлэхийн тулд орон зайд нэгдээрэй';

  @override
  String get group_chat_inappropriate =>
      'Энэ зурвас зөвшөөрөгдөөгүй үг хэллэг агуулсан тул илгээгдсэнгүй';

  @override
  String get group_chat_not_a_member =>
      'Зөвхөн гишүүд энэ чатыг нээх боломжтой';

  @override
  String get group_chat_open => 'Чат';

  @override
  String get group_chat_message_hint => 'Зурвас';

  @override
  String get group_chat_join_to_send =>
      'Мессеж илгээхийн тулд чатад нэгдээрэй.';

  @override
  String get group_chat_today => 'Өнөөдөр';

  @override
  String get group_chat_yesterday => 'Өчигдөр';

  @override
  String get group_chat_empty_title => 'Одоогоор зурвас алга';

  @override
  String get group_chat_empty_body => 'Орон зайтайгаа яриа эхлүүлээрэй';

  @override
  String get group_chat_load_failed => 'Зурвасуудыг ачаалж чадсангүй';

  @override
  String get group_chat_message_not_found => 'Энэ зурвас чатад байхгүй болсон';

  @override
  String get group_chat_retry => 'Дахин оролдох';

  @override
  String get group_chat_unknown_sender => 'Гишүүн';

  @override
  String get group_chat_reactions_all => 'Бүгд';

  @override
  String get group_chat_reacted => 'Хариу үйлдэл үзүүлсэн';

  @override
  String get group_chat_reply => 'Хариулах';

  @override
  String get group_chat_copy => 'Хуулах';

  @override
  String get group_chat_copied => 'Зурвас хуулагдлаа';

  @override
  String get group_chat_report => 'Мэдээлэх';

  @override
  String get group_chat_report_title => 'Та яагаад үүнийг мэдээлж байна вэ?';

  @override
  String get group_chat_report_privacy => 'Таны нэр нууц хэвээр үлдэнэ';

  @override
  String get group_chat_report_reason_harassment => 'Дарамт эсвэл доромжлол';

  @override
  String get group_chat_report_reason_hate =>
      'Үзэн ядалт эсвэл хор хөнөөлтэй үг';

  @override
  String get group_chat_report_reason_sexual => 'Бэлгийн эсвэл илэрхий агуулга';

  @override
  String get group_chat_report_reason_spam => 'Спам эсвэл луйвар';

  @override
  String get group_chat_report_reason_off_topic =>
      'Сэдвээс гадуур эсвэл саад учруулсан';

  @override
  String get group_chat_report_reason_other => 'Бусад';

  @override
  String get group_chat_report_note_title => 'Тэмдэглэл нэмэх';

  @override
  String get group_chat_report_note_hint => 'Бусад...';

  @override
  String get group_chat_report_submit => 'Мэдээлэл илгээх';

  @override
  String get group_chat_report_thanks => 'Санал хүсэлтэд баярлалаа';

  @override
  String get group_chat_report_offline =>
      'Та офлайн байна. Дараа дахин оролдоно уу';

  @override
  String get group_chat_report_failed => 'Мэдээллийг илгээж чадсангүй';

  @override
  String get group_chat_report_retry => 'Дахин оролдох';

  @override
  String get group_chat_delete => 'Устгах';

  @override
  String get group_chat_delete_title => 'Зурвасыг устгах уу?';

  @override
  String group_chat_delete_title_many(int count) {
    return '$count зурвасыг устгах уу?';
  }

  @override
  String group_chat_delete_confirm_body(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Эдгээр зурвас бүх хүний хувьд чатаас устгагдана',
      one: 'Энэ зурвас бүх хүний хувьд чатаас устгагдана',
    );
    return '$_temp0';
  }

  @override
  String group_chat_delete_failed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count зурвасыг устгаж чадсангүй',
      one: 'Зурвасыг устгаж чадсангүй',
    );
    return '$_temp0';
  }

  @override
  String group_chat_selection_limit(int count) {
    return 'Та $count хүртэл зурвас сонгох боломжтой';
  }

  @override
  String get group_chat_message_deleted_by_sender => 'Энэ зурвас устгагдсан';

  @override
  String get group_chat_reaction_failed =>
      'Таны хариу үйлдлийг хадгалж чадсангүй';

  @override
  String group_chat_reactions_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count хариу үйлдэл',
      one: '1 хариу үйлдэл',
    );
    return '$_temp0';
  }

  @override
  String get group_chat_you => 'Та';

  @override
  String get group_chat_tap_to_remove => 'Арилгахын тулд дарна уу';

  @override
  String get group_chat_reply_parent_gone =>
      'Тэр зурвас байхгүй болсон тул ишлэлийг хаслаа. Зурвасаа нийтлэхийн тулд дахин илгээнэ үү';

  @override
  String get group_tab_posts => 'Нийтлэл';

  @override
  String get group_tab_events => 'Арга хэмжээ';

  @override
  String get group_posts_empty_title => 'Одоогоор нийтлэл алга';

  @override
  String get group_posts_empty_message =>
      'Орон зайныхаа анхны мэдээг хуваалцаарай';

  @override
  String get group_posts_load_error =>
      'Нийтлэлүүдийг ачаалж чадсангүй. Дахин оролдоно уу';

  @override
  String get group_post_button => 'Нийтлэх';

  @override
  String get group_post_new_title => 'Шинэ нийтлэл';

  @override
  String get group_post_posting_to => 'Нийтлэх газар:';

  @override
  String get group_post_caption_hint => 'Шинэ юу байна?';

  @override
  String get group_post_photos => 'Зураг';

  @override
  String get group_post_link => 'Холбоос';

  @override
  String get group_post_discard_title => 'Нийтлэлийг цуцлах уу?';

  @override
  String get group_post_discard_message => 'Таны бичсэн зүйл устах болно';

  @override
  String get group_post_keep_editing => 'Үргэлжлүүлэн засах';

  @override
  String get group_post_discard => 'Цуцлах';

  @override
  String get group_post_add_link_title => 'Холбоос нэмэх';

  @override
  String get group_post_add_link_hint =>
      'Холбоос буулгавал бид урьдчилан харуулна';

  @override
  String get group_post_link_field_hint => 'Холбоос';

  @override
  String get group_post_attach => 'Хавсаргах';

  @override
  String get group_post_attach_as_link => 'Холбоос болгон хавсаргах';

  @override
  String get group_post_preview_failed_title =>
      'Урьдчилан харагдацыг ачаалж чадсангүй';

  @override
  String get group_post_preview_failed_message =>
      'Та үүнийг холбоос болгон хавсаргаж болно';

  @override
  String get group_post_invalid_link =>
      'Зөв холбоос оруулна уу, жишээ нь: https://example.com';

  @override
  String group_post_photo_limit(int count) {
    return 'Та $count хүртэл зураг нэмэх боломжтой';
  }

  @override
  String get group_post_upload_error =>
      'Зургуудыг байршуулж чадсангүй. Дахин оролдоно уу';

  @override
  String get group_post_publish_error =>
      'Таны нийтлэлийг нийтэлж чадсангүй. Дахин оролдоно уу';

  @override
  String get group_post_published => 'Таны нийтлэл нийтлэгдлээ.';

  @override
  String get group_post_delete_title => 'Нийтлэлийг устгах уу?';

  @override
  String get group_post_delete_message => 'Энэ нийтлэл бүрмөсөн устгагдана';

  @override
  String get group_post_delete_failed =>
      'Нийтлэлийг устгаж чадсангүй. Дахин оролдоно уу';

  @override
  String get edit => 'Засах';

  @override
  String get group_post_edit_title => 'Нийтлэл засах';

  @override
  String get group_post_update_error =>
      'Таны өөрчлөлтийг хадгалж чадсангүй. Дахин оролдоно уу';

  @override
  String get group_post_updated => 'Таны өөрчлөлт хадгалагдлаа';

  @override
  String get practice_collection_already_added =>
      'Энэ цуглуулга таны дадлагад аль хэдийн байна';

  @override
  String get practice_group_accumulator_already_added =>
      'Энэ хуримтлал таны дадлагад аль хэдийн байна';

  @override
  String get event_live_badge => 'ШУУД';

  @override
  String get event_live_audio => 'Шууд аудио';

  @override
  String get event_live_video_mode => 'Бичлэг';

  @override
  String get event_live_audio_mode => 'Аудио';

  @override
  String get event_live_go_live => 'Шууд';

  @override
  String get event_puja_starts_in => 'Пүжа эхлэхэд';

  @override
  String get event_puja_not_started => 'Пүжа хараахан эхлээгүй байна';

  @override
  String get event_prayer_requests => 'Залбирлын хүсэлтүүд';

  @override
  String event_prayer_request_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      one: '1 хүсэлт',
      other: '$count хүсэлт',
    );
    return '$_temp0';
  }

  @override
  String get event_prayer_empty_title => 'Одоогоор залбирлын хүсэлт алга';

  @override
  String get event_prayer_empty_body =>
      'Таны болон таны орон зайн хүсэлтүүд энд харагдана';

  @override
  String get event_prayer_add => 'Залбирлын хүсэлт нэмэх';

  @override
  String get event_prayer_hint => 'Өнөөдөр бид таны төлөө хэрхэн залбирах вэ?';

  @override
  String get event_prayer_load_failed =>
      'Залбирлын хүсэлтүүдийг ачаалж чадсангүй';

  @override
  String get event_prayer_closed =>
      'Энэ арга хэмжээний залбирлын хүсэлт хаагдсан';

  @override
  String get event_prayer_pray => 'Залбирах';

  @override
  String get event_prayer_praying => 'Залбирсан';

  @override
  String event_prayer_my_count(int count) {
    return '+$count';
  }

  @override
  String get event_prayer_new_request => 'Шинэ залбирлын хүсэлт';

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
  String get event_prayer_choose_intention => 'Залбирлын зорилго сонгох';

  @override
  String get event_prayer_intentions_failed =>
      'Залбирлын зорилгуудыг ачаалж чадсангүй';

  @override
  String get event_prayer_request_button => 'Залбирал хүсэх';

  @override
  String get event_prayer_you => 'Та';

  @override
  String get event_prayer_waiting_first => 'Эхний залбирлыг хүлээж байна...';

  @override
  String event_prayer_more_praying(int count) {
    return '+$count хүн нэмж залбирсан';
  }

  @override
  String event_prayer_people_praying(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count хүн залбирсан',
      one: '1 хүн залбирсан',
    );
    return '$_temp0';
  }

  @override
  String get event_prayer_praying_for_you => 'Таны төлөө залбирсан';

  @override
  String event_prayer_praying_for(String name) {
    return '$name-ийн төлөө залбирсан';
  }

  @override
  String get event_prayer_your_request => 'Таны хүсэлт';

  @override
  String get event_prayer_supporters_failed =>
      'Хэн залбирч байгааг ачаалж чадсангүй.';

  @override
  String get event_prayer_no_supporters => 'Одоогоор хэн ч залбираагүй байна';

  @override
  String get recitation_live_sync => 'Синк хийх';

  @override
  String get recitation_live_label => 'Шууд';

  @override
  String get recitation_live_session_ended => 'Шууд хичээл дууссан';

  @override
  String get feedback_title => 'Санал хүсэлт';

  @override
  String get feedback_hint =>
      'Юу сайн ажиллаж байгаа, юу ажиллахгүй байгаа, эсвэл юуг харахыг хүсч байгаагаа бидэнд хэлээрэй...';

  @override
  String get feedback_images => 'Зургууд';

  @override
  String get feedback_add_image => 'Зураг нэмэх';

  @override
  String feedback_image_limit(int count) {
    return 'Та $count хүртэл зураг хавсаргах боломжтой';
  }

  @override
  String get feedback_send => 'Илгээх';

  @override
  String get feedback_sent => 'Баярлалаа! Таны санал хүсэлт илгээгдлээ';

  @override
  String get feedback_error_offline =>
      'Та офлайн байна. Дараа дахин оролдоно уу';

  @override
  String get feedback_error_rate_limited =>
      'Хэт олон хүсэлт илгээлээ. Түр хүлээгээд дахин оролдоно уу';

  @override
  String get feedback_error_too_large =>
      'Зургууд хэт том байна. Нэгийг хасаад дахин оролдоно уу';

  @override
  String get feedback_error_failed =>
      'Санал хүсэлтийг илгээж чадсангүй. Дахин оролдоно уу';

  @override
  String get feedback_error_unavailable =>
      'Санал хүсэлт одоогоор боломжгүй байна';
}

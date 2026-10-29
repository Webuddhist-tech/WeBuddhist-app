// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'WeBuddhist';

  @override
  String get sign_in => 'Đăng nhập';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get onboarding_welcome => 'Chào mừng bạn đến với';

  @override
  String get onboarding_tagline => 'Học hỏi, tu tập và kết nối. Mỗi ngày.';

  @override
  String get onboarding_find_peace => 'Bắt đầu';

  @override
  String get onboarding_continue => 'Tiếp tục';

  @override
  String get onboarding_first_question => 'Chọn ngôn ngữ của bạn';

  @override
  String get onboarding_language_subtitle =>
      'Đây là ngôn ngữ hiển thị của ứng dụng';

  @override
  String get onboarding_all_set => 'Bạn đã sẵn sàng';

  @override
  String get onboarding_all_set_description => 'Những gì đang chờ đón bạn:';

  @override
  String get onboarding_all_set_practice_title => 'Tu tập';

  @override
  String get onboarding_all_set_practice_body =>
      'Lộ trình, bài tụng, chuỗi hạt và thiền';

  @override
  String get onboarding_all_set_connect_title => 'Kết nối';

  @override
  String get onboarding_all_set_connect_body =>
      'Nhóm, sự kiện, bảng tin và trò chuyện';

  @override
  String get home_today => 'Hôm nay';

  @override
  String get home_overall_stats => 'Thống kê tổng quan';

  @override
  String home_plans_count(int count) {
    return '$count lộ trình';
  }

  @override
  String home_recitation_count(int count) {
    return '$count bài tụng';
  }

  @override
  String get home_shortcut_plans => 'Lộ trình';

  @override
  String get home_chants => 'Bài tụng';

  @override
  String get home_mala => 'Chuỗi hạt';

  @override
  String get session_mala => 'Chuỗi hạt';

  @override
  String get bookmark_mala => 'Chuỗi hạt';

  @override
  String get bookmark_timers => 'Hẹn giờ';

  @override
  String get bookmark_texts => 'Kinh văn';

  @override
  String get bookmark_group_accumulation => 'Tích lũy của nhóm';

  @override
  String get mala_add_to_practice => 'Thêm vào pháp tu của tôi';

  @override
  String get mala_add_mala_round => 'Thêm vòng chuỗi hạt';

  @override
  String get mala_add_rounds_title => 'Thêm vòng chuỗi hạt:';

  @override
  String get mala_add_rounds_message =>
      'Thêm số vòng chuỗi hạt bạn đã lần ngoài ứng dụng';

  @override
  String mala_rounds_unit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vòng',
      one: 'vòng',
    );
    return '$_temp0';
  }

  @override
  String get mala_add_to_bookmark => 'Đánh dấu';

  @override
  String get mala_sound => 'Âm thanh';

  @override
  String get mala_vibration => 'Rung';

  @override
  String get mala_reset_count => 'Đặt lại số đếm';

  @override
  String get mala_reset_title => 'Đặt lại chuỗi hạt này?';

  @override
  String get mala_reset_count_confirm =>
      'Số đếm hiện tại sẽ trở về 0, nhưng tích lũy của bạn vẫn được giữ trong tổng số từ trước đến nay';

  @override
  String get mala_reset_confirm => 'Đặt lại';

  @override
  String get mala_action_coming_soon => 'Sắp ra mắt';

  @override
  String mala_rounds_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vòng',
      one: '1 vòng',
      zero: '0 vòng',
    );
    return '$_temp0';
  }

  @override
  String get mala_hand_layout_tooltip => 'Đổi bố cục tay';

  @override
  String get mala_settings_section => 'Cài đặt chuỗi hạt';

  @override
  String get mala_others_section => 'Khác';

  @override
  String get mala_mantra_speed => 'Tốc độ tụng chú';

  @override
  String get mala_speed_normal => 'Bình thường';

  @override
  String get mala_show_full_mantra => 'Hiện toàn bộ thần chú';

  @override
  String mala_counter_semantics(int bead, int total, String rounds) {
    return 'Hạt thứ $bead trên $total, $rounds';
  }

  @override
  String get mala_group_accumulations => 'Thêm lượt tụng vào';

  @override
  String get mala_groups_section => 'Sự kiện';

  @override
  String get mala_group_untitled => 'Nhóm chưa đặt tên';

  @override
  String get mala_all_time_accumulation =>
      'Tổng tích lũy từ trước đến nay của tôi';

  @override
  String get mala_personal_practice => 'Tu tập cá nhân';

  @override
  String get mala_events_section => 'Sự kiện';

  @override
  String mala_my_total(String count) {
    return 'Tổng của tôi: $count';
  }

  @override
  String mala_group_total(String count) {
    return 'Tổng của nhóm: $count';
  }

  @override
  String get home_timer => 'Hẹn giờ';

  @override
  String get preset_timers => 'Hẹn giờ có sẵn';

  @override
  String get meditation_timer => 'Hẹn giờ thiền';

  @override
  String get timer_min => 'phút';

  @override
  String get timer_finish => 'Kết thúc';

  @override
  String get timer_discard_session => 'Bỏ buổi thiền';

  @override
  String get home_hello_prefix => 'Xin chào, ';

  @override
  String home_share_prompt(String appName) {
    return 'Bạn có thích $appName không?';
  }

  @override
  String get home_share_support =>
      'Sự ủng hộ của bạn giúp cộng đồng chúng ta lớn mạnh';

  @override
  String get no_feature_content => 'Không có nội dung nổi bật';

  @override
  String get nav_home => 'Trang chủ';

  @override
  String get nav_explore => 'Khám phá';

  @override
  String get nav_learn => 'Học';

  @override
  String get nav_practice => 'Tu tập';

  @override
  String get nav_settings => 'Cài đặt';

  @override
  String get nav_connect => 'Kết nối';

  @override
  String get nav_me => 'Tôi';

  @override
  String get tab_practices => 'Pháp tu';

  @override
  String get text_search => 'Tìm kiếm';

  @override
  String get text_commentary => 'Chú giải';

  @override
  String get resources => 'Tài liệu';

  @override
  String get no_translation => 'Không tìm thấy bản dịch nào';

  @override
  String get show_more => 'Xem thêm';

  @override
  String get show_less => 'Thu gọn';

  @override
  String get more => 'Thêm';

  @override
  String get less => 'Thu gọn';

  @override
  String get no_content => 'Không tìm thấy nội dung';

  @override
  String commentary_not_available_for_language(String language) {
    return 'Chưa có chú giải bằng $language';
  }

  @override
  String get loading => 'Đang tải...';

  @override
  String get save => 'Lưu';

  @override
  String get done => 'Xong';

  @override
  String get my_plans => 'Lộ trình của tôi';

  @override
  String get browse_plans => 'Xem các lộ trình';

  @override
  String get plan_info => 'Thông tin lộ trình';

  @override
  String get start_reading => 'Tu tập ngay';

  @override
  String get tibetan => 'Tiếng Tây Tạng';

  @override
  String get sanskrit => 'Tiếng Phạn';

  @override
  String get english => 'Tiếng Anh';

  @override
  String get chinese => 'Tiếng Trung';

  @override
  String get classicalChinese => 'Hán văn cổ';

  @override
  String get pali => 'Tiếng Pali';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get plan_unenroll => 'Hủy đăng ký';

  @override
  String get unenroll_confirmation => 'Bạn có chắc muốn hủy đăng ký';

  @override
  String get unenroll_message =>
      'Tiến trình của bạn sẽ bị mất vĩnh viễn và không thể khôi phục';

  @override
  String get practice_plan =>
      'Xây dựng thói quen tu tập hằng ngày. Khám phá những gì phù hợp với bạn.';

  @override
  String get search_plans => 'Tìm kiếm lộ trình...';

  @override
  String get search_for_plans => 'Tìm kiếm lộ trình';

  @override
  String get no_plans_found => 'Không tìm thấy lộ trình nào';

  @override
  String get no_days_available => 'Không tìm thấy ngày nào';

  @override
  String get recitations_search => 'Tìm kiếm bài tụng...';

  @override
  String get recitations_search_for => 'Tìm kiếm bài tụng';

  @override
  String get recitations_no_found => 'Không tìm thấy bài tụng nào';

  @override
  String get recitations_no_content => 'Không có bài tụng nào';

  @override
  String get my_recitation_collection_new_title => 'Tuyển tập mới';

  @override
  String get my_recitation_collection_next => 'Tiếp';

  @override
  String get my_recitation_collection_create => 'Tạo';

  @override
  String get my_recitation_collection_create_button => 'Tạo tuyển tập';

  @override
  String get my_recitation_collection_change_title => 'Đổi tiêu đề';

  @override
  String get my_recitation_collection_change => 'Đổi';

  @override
  String get my_recitation_collection_add_chants => 'Thêm bài tụng';

  @override
  String get my_recitation_collection_search_chants => 'Tìm kiếm bài tụng';

  @override
  String get my_recitation_collection_add_to_collection => 'Thêm vào tuyển tập';

  @override
  String get my_recitation_collection_edit => 'Chỉnh sửa tuyển tập';

  @override
  String get my_recitation_collection_delete => 'Xóa tuyển tập';

  @override
  String get my_recitation_collection_delete_title => 'Xóa tuyển tập?';

  @override
  String get my_recitation_collection_delete_message =>
      'Tuyển tập này sẽ bị xóa vĩnh viễn';

  @override
  String get my_recitation_collection_fallback_title => 'Tuyển tập bài tụng';

  @override
  String get my_recitation_collection_unavailable => 'Không còn khả dụng';

  @override
  String my_recitation_collection_chant_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bài tụng',
      one: '1 bài tụng',
      zero: '0 bài tụng',
    );
    return '$_temp0';
  }

  @override
  String my_recitation_collection_chant_count_owner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bài tụng • của tôi',
      one: '1 bài tụng • của tôi',
      zero: '0 bài tụng • của tôi',
    );
    return '$_temp0';
  }

  @override
  String get bookmarks_empty_chant_collections_title =>
      'Chưa đánh dấu tuyển tập bài tụng nào';

  @override
  String get bookmarks_empty_chant_collections_subtitle =>
      'Đánh dấu một tuyển tập để lưu vào đây';

  @override
  String get notification_allow_title => 'Cho phép thông báo';

  @override
  String get notification_allow_subtitle_disabled =>
      'Cần cấp quyền. Nhấn để cấp quyền trong Cài đặt';

  @override
  String get notification_snack_permission_denied =>
      'Thông báo đang bị chặn. Hãy bật trong Cài đặt';

  @override
  String get notification_snack_disable_alarms_in_settings =>
      'Tắt báo thức và lời nhắc trong Cài đặt';

  @override
  String get notification_allow_subtitle_on =>
      'Lời nhắc và cập nhật từ WeBuddhist';

  @override
  String get notification_allow_subtitle_off =>
      'Đang tắt. Bật để nhận lời nhắc và cập nhật.';

  @override
  String get notification_section_practice => 'Tu tập';

  @override
  String get notification_section_connect => 'Kết nối';

  @override
  String get notification_row_plans => 'Lộ trình';

  @override
  String get notification_row_chants => 'Bài tụng';

  @override
  String get notification_row_mala => 'Chuỗi hạt & tích lũy';

  @override
  String get notification_row_timer => 'Hẹn giờ';

  @override
  String get notification_row_group_posts => 'Bài đăng của nhóm';

  @override
  String get notification_row_group_chats => 'Trò chuyện nhóm';

  @override
  String get notification_row_my_prayer_requests =>
      'Lời nhờ cầu nguyện của tôi';

  @override
  String get notification_row_others_prayer_requests =>
      'Lời nhờ cầu nguyện của người khác';

  @override
  String get profile_default_bio => 'Chào mừng đến với WeBuddhist';

  @override
  String get profile_guest_title => 'Khách';

  @override
  String get profile_guest_subtitle => 'Bạn đang xem với tư cách khách';

  @override
  String get profile_guest_benefits_header => 'Đăng nhập để mở khóa:';

  @override
  String get profile_guest_benefit_save_progress => 'Lưu tiến trình của bạn';

  @override
  String get profile_guest_benefit_personalized => 'Nội dung cá nhân hóa';

  @override
  String get profile_guest_benefit_notifications => 'Thông báo tùy chỉnh';

  @override
  String get auth_drawer_title => 'Đăng nhập để tiếp tục';

  @override
  String get auth_drawer_subtitle =>
      'Tiếp tục tu tập trên mọi thiết bị, dù bạn ở đâu';

  @override
  String get routine_delete_block_message =>
      'Khung giờ này và mọi mục trong đó sẽ bị xóa';

  @override
  String get something_went_wrong => 'Đã xảy ra lỗi. Vui lòng thử lại';

  @override
  String get onboarding_tradition_title =>
      'Bạn theo lời dạy của Đức Phật như thế nào?';

  @override
  String get onboarding_tradition_subtitle =>
      'Chọn một hoặc nhiều truyền thống cho nội dung của bạn. Bạn có thể thay đổi bất cứ lúc nào trong Cài đặt.';

  @override
  String get onboarding_tradition_show_all_title => 'Hiển thị tất cả';

  @override
  String get plan_go_to_practice => 'Vào tu tập';

  @override
  String get plan_starts_soon_title => 'Sắp bắt đầu';

  @override
  String get plan_joining_late_title => 'Tham gia sau ngày bắt đầu';

  @override
  String get got_it => 'Đã hiểu';

  @override
  String get plan_no_tasks_error => 'Không thể tải nhiệm vụ';

  @override
  String get plan_day_tasks_load_error => 'Không thể tải nhiệm vụ';

  @override
  String get plans_empty_title => 'Sắp có thêm nội dung';

  @override
  String get plans_empty_subtitle =>
      'Thư viện của chúng tôi đang phát triển. Hãy quay lại sau nhé.';

  @override
  String get find_plans_load_error =>
      'Không thể tải.\nHãy kiểm tra kết nối và thử lại';

  @override
  String get connect_subtitle => 'Tìm nhóm và cùng nhau tu tập';

  @override
  String get discover_groups => 'Khám phá nhóm';

  @override
  String get my_groups => 'Nhóm của tôi';

  @override
  String get see_all => 'Xem tất cả';

  @override
  String get connect_groups_load_error =>
      'Không thể tải các nhóm.\nHãy kiểm tra kết nối và thử lại';

  @override
  String get connect_groups_empty_title => 'Không còn nhóm nào';

  @override
  String get connect_tab_feed => 'Bảng tin';

  @override
  String get connect_tab_events => 'Sự kiện';

  @override
  String get connect_tab_practices => 'Pháp tu';

  @override
  String get connect_tab_groups => 'Nhóm';

  @override
  String get connect_segment_my => 'Nhóm của bạn';

  @override
  String get connect_segment_discover => 'Khám phá';

  @override
  String get connect_empty_discover_events =>
      'Không có sự kiện nào để khám phá';

  @override
  String get connect_empty_discover_feed => 'Không có gì để khám phá';

  @override
  String get connect_empty_discover_groups => 'Không có nhóm nào để khám phá';

  @override
  String get connect_all_groups => 'Tất cả nhóm';

  @override
  String get connect_my_empty_feed_title => 'Không có cập nhật mới';

  @override
  String get connect_my_empty_events_title => 'Không có sự kiện sắp tới';

  @override
  String get connect_my_empty_groups_title => 'Chưa có nhóm nào';

  @override
  String get connect_my_empty_feed_subtitle =>
      'Các nhóm của bạn chưa chia sẻ gì mới';

  @override
  String get connect_my_empty_events_subtitle =>
      'Các nhóm của bạn chưa lên lịch sự kiện nào';

  @override
  String get connect_my_empty_groups_subtitle =>
      'Bạn chưa tham gia nhóm nào. Hãy khám phá vài nhóm để cùng tu tập';

  @override
  String get connect_my_empty_feed_browse =>
      'Xem các nhóm khác đang chia sẻ gì';

  @override
  String get connect_my_empty_events_browse => 'Xem các sự kiện mở';

  @override
  String connect_comment_replying_to(String handle) {
    return 'Đang trả lời @$handle';
  }

  @override
  String get connect_comment_hint => 'Bạn nghĩ gì về điều này?';

  @override
  String get connect_comment_reply_hint => 'Viết câu trả lời...';

  @override
  String get connect_comment_reply => 'Trả lời';

  @override
  String get connect_comment_delete_title => 'Xóa bình luận?';

  @override
  String get connect_comment_delete_message =>
      'Bình luận này sẽ bị xóa vĩnh viễn';

  @override
  String get connect_comment_delete_failed => 'Không thể xóa bình luận';

  @override
  String connect_post_comments_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bình luận',
      one: '1 bình luận',
    );
    return '$_temp0';
  }

  @override
  String get connect_post_comments_empty =>
      'Chưa có bình luận nào. Hãy bắt đầu cuộc trò chuyện';

  @override
  String get connect_online => 'Trực tuyến';

  @override
  String get connect_ended => 'Đã kết thúc';

  @override
  String connect_ended_on(String date) {
    return 'Đã kết thúc $date';
  }

  @override
  String get home_group_events => 'Sự kiện nổi bật';

  @override
  String get home_poems => 'Thi kệ';

  @override
  String get poems_load_error =>
      'Không thể tải thi kệ.\nHãy kiểm tra kết nối và thử lại';

  @override
  String get poems_empty => 'Chưa có thi kệ nào. Hãy quay lại sau';

  @override
  String get connect_events_filter_all => 'Tất cả';

  @override
  String get connect_events_filter_in_person => 'Trực tiếp';

  @override
  String get connect_events_filter_empty_online =>
      'Không có sự kiện trực tuyến';

  @override
  String get connect_events_filter_empty_in_person =>
      'Không có sự kiện trực tiếp';

  @override
  String get connect_events_filter_hybrid => 'Kết hợp';

  @override
  String get connect_events_filter_empty_hybrid => 'Không có sự kiện kết hợp';

  @override
  String get connect_event_fallback_title => 'Sự kiện';

  @override
  String get connect_group_fallback_title => 'Nhóm';

  @override
  String get connect_event_participation_prompt =>
      'Bạn tham dự theo hình thức nào?';

  @override
  String get connect_event_practice_in_person => 'Tu tập trực tiếp';

  @override
  String get connect_event_practice_online => 'Tu tập trực tuyến';

  @override
  String get connect_event_view_in_person => 'Chế độ trực tiếp';

  @override
  String get connect_event_view_online => 'Chế độ trực tuyến';

  @override
  String get connect_event_accumulation_online => 'Trực tuyến';

  @override
  String get connect_event_accumulation_in_person => 'Trực tiếp';

  @override
  String get connect_event_has_ended => 'Sự kiện này đã kết thúc';

  @override
  String get connect_event_join_to_practice => 'Tham gia sự kiện để tu tập';

  @override
  String get connect_event_leave => 'Rời sự kiện';

  @override
  String get connect_event_leave_confirm_title => 'Rời sự kiện này?';

  @override
  String connect_event_leave_confirm_message(String title) {
    return 'Bạn sẽ không còn tham dự $title. Bạn vẫn có thể xem sự kiện và tham dự lại bất cứ lúc nào.';
  }

  @override
  String connect_event_participants_attending(int count) {
    return '$count người tham gia';
  }

  @override
  String connect_event_participants_attended(int count) {
    return '$count người đã tham dự';
  }

  @override
  String get connect_event_participants_empty => 'Chưa có người tham gia';

  @override
  String get connect_event_organizer => 'Người tổ chức';

  @override
  String get connect_event_tab_videos => 'Video';

  @override
  String get connect_event_tab_about => 'Thông tin';

  @override
  String get connect_event_links_title => 'Thông tin thêm về sự kiện';

  @override
  String get connect_event_date_tba => 'Ngày sẽ được thông báo sau';

  @override
  String get connect_event_when => 'Thời gian';

  @override
  String get connect_event_where => 'Địa điểm';

  @override
  String get connect_event_tab_accumulations => 'Tích lũy';

  @override
  String get connect_event_add_recitations => 'Thêm lượt tụng';

  @override
  String get connect_event_add_recitations_message =>
      'Thêm số lượt tụng bạn đã thực hiện cùng buổi phát trực tiếp hoặc ngoài ứng dụng này';

  @override
  String get connect_event_every_day => 'Hằng ngày';

  @override
  String connect_event_every_weekday(String weekday) {
    return '$weekday hằng tuần';
  }

  @override
  String get connect_event_every_month => 'Hằng tháng';

  @override
  String connect_event_every_date(String date) {
    return 'Mỗi $date';
  }

  @override
  String get connect_event_about_empty => 'Chưa có thông tin về sự kiện';

  @override
  String get search_groups => 'Tìm kiếm nhóm';

  @override
  String get search_for_groups => 'Tìm kiếm nhóm';

  @override
  String get no_groups_found => 'Không tìm thấy nhóm phù hợp';

  @override
  String get explore_coming_soon_subtitle =>
      'Không gian chọn lọc để khám phá pháp tu, giáo lý và sự kiện cộng đồng';

  @override
  String get learn_coming_soon_subtitle =>
      'Lộ trình học tập riêng của bạn, được thiết kế để phù hợp với cuộc sống hằng ngày';

  @override
  String get creator_featured_plan => 'Lộ trình nổi bật';

  @override
  String get home_no_series_found => 'Không tìm thấy chuỗi lộ trình nào';

  @override
  String get home_no_tags_found => 'Không tìm thấy thẻ nào';

  @override
  String get home_celebrated_by => 'Được kỷ niệm bởi: ';

  @override
  String get reader_font_size_tooltip => 'Cỡ chữ';

  @override
  String get reader_versions_load_error => 'Không thể tải các phiên bản';

  @override
  String get reader_languages_load_error => 'Không thể tải ngôn ngữ';

  @override
  String reader_no_versions_in_language(String language) {
    return 'Không có phiên bản nào bằng $language';
  }

  @override
  String get reader_no_languages => 'Kinh văn này chưa có ngôn ngữ nào';

  @override
  String get reader_license => 'Giấy phép';

  @override
  String get text_search_hint => 'Nhập để tìm kiếm';

  @override
  String get text_search_press_button => 'Nhấn nút tìm kiếm để tìm';

  @override
  String get text_search_error => 'Không thể tìm kiếm.\nVui lòng thử lại';

  @override
  String get create_image_share_error => 'Không thể chia sẻ. Vui lòng thử lại';

  @override
  String get my_plans_sign_in_prompt => 'Đăng nhập để xem lộ trình của bạn';

  @override
  String plan_starts_soon_message(String date) {
    return 'Bắt đầu vào $date. Bạn có thể xem trước nội dung ngay bây giờ';
  }

  @override
  String plan_joining_late_message(String date) {
    return 'Đã bắt đầu từ $date. Bạn có thể hoàn thành nhiệm vụ của những ngày trước';
  }

  @override
  String get select_language => 'Chọn ngôn ngữ';

  @override
  String get logout_confirmation => 'Bạn có chắc muốn đăng xuất không?';

  @override
  String get cancel => 'Hủy';

  @override
  String get copy => 'Sao chép';

  @override
  String get copied => 'Đã sao chép';

  @override
  String get share => 'Chia sẻ';

  @override
  String get bookmark => 'Đánh dấu';

  @override
  String get collection_audio_versions => 'Bản âm thanh';

  @override
  String get author => 'Tác giả';

  @override
  String get plans_created => 'Lộ trình đã tạo';

  @override
  String get ai_confirm => 'Xác nhận';

  @override
  String search_no_results(String query) {
    return 'Không tìm thấy kết quả nào cho \"$query\"';
  }

  @override
  String get search_all => 'Tất cả';

  @override
  String get common_ok => 'OK';

  @override
  String get comingSoonHeadline => 'Sắp ra mắt';

  @override
  String get routine_title => 'Pháp tu của tôi';

  @override
  String get bookmarks => 'Dấu trang';

  @override
  String get routine_empty_title => 'Pháp tu';

  @override
  String get routine_edit => 'Chỉnh sửa';

  @override
  String get routine_empty_description =>
      'Khám phá thêm giáo lý và pháp tu để thêm vào thời khóa của bạn';

  @override
  String get routine_build => 'Xây dựng thời khóa của bạn';

  @override
  String get routine_add_session => 'Thêm vào buổi tu';

  @override
  String get routine_edit_title => 'Chỉnh sửa thời khóa';

  @override
  String get routine_delete_block => 'Xóa khung giờ';

  @override
  String get routine_session_title_hint => 'Tiêu đề...';

  @override
  String get routine_expand_all => 'Mở rộng tất cả';

  @override
  String get routine_collapse_all => 'Thu gọn tất cả';

  @override
  String get routine_add_plan => 'Thêm lộ trình';

  @override
  String get routine_add_recitation => 'Thêm bài tụng';

  @override
  String get routine_add_plan_to_routine => 'Thêm vào thời khóa';

  @override
  String get routine_load_error =>
      'Không thể tải. Hãy kiểm tra kết nối và thử lại';

  @override
  String get routine_empty_block_title_singular => 'Khung giờ trống';

  @override
  String routine_empty_block_title_plural(int count) {
    return 'Khung giờ trống ($count)';
  }

  @override
  String get routine_empty_block_message_singular =>
      'Khung giờ này đang trống. Thêm một mục, hay xóa nó khỏi thời khóa?';

  @override
  String routine_empty_block_message_plural(int count) {
    return '$count khung giờ đang trống. Thêm mục, hay xóa chúng khỏi thời khóa?';
  }

  @override
  String get routine_empty_block_add_items => 'Thêm mục';

  @override
  String get routine_empty_block_delete_singular => 'Xóa khung giờ';

  @override
  String get routine_empty_block_delete_plural => 'Xóa các khung giờ';

  @override
  String get routine_notification_title => 'Biến tu tập thành thói quen';

  @override
  String get routine_notification_description =>
      'Cho phép thông báo để chúng tôi nhắc bạn tu tập';

  @override
  String get routine_notification_enable => 'Bật thông báo';

  @override
  String get routine_notification_skip => 'Bỏ qua';

  @override
  String routine_time_adjusted(String time, int gap) {
    return 'Đã điều chỉnh thành $time (cách nhau tối thiểu $gap phút)';
  }

  @override
  String get routine_add_block_label => 'Khung giờ';

  @override
  String get continueWithGoogle => 'Tiếp tục với Google';

  @override
  String get continueWithApple => 'Tiếp tục với Apple';

  @override
  String get continueWithPhone => 'Tiếp tục bằng số điện thoại';

  @override
  String get exploreAsGuest => 'Khám phá với tư cách khách';

  @override
  String get signIn => 'Đăng nhập';

  @override
  String get profileError => 'Lỗi khi tải hồ sơ';

  @override
  String get profileTitle => 'Hồ sơ';

  @override
  String get notLoggedIn => 'Chưa đăng nhập';

  @override
  String get retry => 'Thử lại';

  @override
  String get back => 'Quay lại';

  @override
  String get delete => 'Xóa';

  @override
  String get close => 'Đóng';

  @override
  String get tryAgain => 'Thử lại';

  @override
  String get pleaseTryAgain => 'Vui lòng thử lại';

  @override
  String get error => 'Lỗi';

  @override
  String get anonymous => 'Ẩn danh';

  @override
  String get noContentAvailable => 'Không có nội dung';

  @override
  String get unableToLoad => 'Không thể tải. Hãy kiểm tra kết nối và thử lại';

  @override
  String get somethingWrong => 'Đã xảy ra lỗi. Hãy kiểm tra kết nối và thử lại';

  @override
  String get source => 'Nguồn';

  @override
  String get noTasks => 'Không có nhiệm vụ nào';

  @override
  String get taskNotFound => 'Không tìm thấy nhiệm vụ';

  @override
  String get updateTaskError => 'Không thể cập nhật trạng thái nhiệm vụ';

  @override
  String get enrollError =>
      'Không thể đăng ký cho bạn. Hãy kiểm tra kết nối và thử lại';

  @override
  String unenrollSuccess(String planTitle) {
    return 'Bạn đã hủy đăng ký $planTitle';
  }

  @override
  String get unenrollError =>
      'Không thể hủy đăng ký. Hãy kiểm tra kết nối và thử lại';

  @override
  String get unenrollGenericError =>
      'Đã xảy ra lỗi. Hãy kiểm tra kết nối và thử lại';

  @override
  String get notFound =>
      'Nội dung này không còn khả dụng. Hãy chỉnh sửa thời khóa để cập nhật';

  @override
  String get noTimeSlot =>
      'Không còn thời gian trống. Hãy thử xóa một khung giờ trước';

  @override
  String maxBlocks(int max) {
    return 'Đã đạt tối đa $max khung giờ';
  }

  @override
  String get duplicateItem => 'Mục này đã có trong khung giờ';

  @override
  String get removeItem => 'Gỡ mục này?';

  @override
  String removeConfirmation(String itemName) {
    return '\"$itemName\" sẽ bị gỡ khỏi khung giờ này';
  }

  @override
  String shareError(String error) {
    return 'Không thể chia sẻ. Vui lòng thử lại';
  }

  @override
  String get captureError => 'Không thể chụp mã QR. Vui lòng thử lại';

  @override
  String get qrShareError => 'Không thể chia sẻ mã QR. Hãy thử lại sau';

  @override
  String errorDetail(String error) {
    return 'Lỗi: $error';
  }

  @override
  String missedDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày bỏ lỡ',
      one: '1 ngày bỏ lỡ',
      zero: '0 ngày bỏ lỡ',
    );
    return '$_temp0';
  }

  @override
  String get plan_status_on_track => 'Đúng tiến độ!';

  @override
  String get start_now => 'Bắt đầu ngay';

  @override
  String get plan_enroll => 'Đăng ký';

  @override
  String get root_text => 'Chánh văn';

  @override
  String get version => 'Phiên bản';

  @override
  String get reader_languages_title => 'Ngôn ngữ';

  @override
  String get reader_sections_title => 'Các phần';

  @override
  String get reader_original_label => 'Bản gốc';

  @override
  String get reader_translation_label => 'Bản dịch';

  @override
  String get version_not_available => 'Không khả dụng';

  @override
  String series_stats(int planCount, int totalDays) {
    return '$planCount CHƯƠNG · $totalDays NGÀY';
  }

  @override
  String get force_update_title => 'Cần cập nhật';

  @override
  String get force_update_message =>
      'Đã có phiên bản mới của ứng dụng. Vui lòng cập nhật để tiếp tục';

  @override
  String get force_update_button => 'Cập nhật ngay';

  @override
  String get settings_section_personalisation => 'CÁ NHÂN HÓA';

  @override
  String get settings_section_more => 'KHÁC';

  @override
  String get settings_section_account => 'TÀI KHOẢN';

  @override
  String get settings_edit_profile => 'Chỉnh sửa hồ sơ';

  @override
  String get settings_theme => 'Giao diện';

  @override
  String get settings_notification_row => 'Thông báo';

  @override
  String get settings_feedback_row => 'Góp ý';

  @override
  String get edit_profile_title => 'Chỉnh sửa hồ sơ';

  @override
  String get edit_profile_save => 'Lưu';

  @override
  String get edit_profile_display_name => 'Tên hiển thị';

  @override
  String get edit_profile_bio => 'Tiểu sử';

  @override
  String get edit_profile_bio_hint => 'Chia sẻ đôi điều về bản thân bạn';

  @override
  String get edit_profile_delete_account => 'Xóa tài khoản';

  @override
  String get edit_profile_photo_not_uploaded => 'Chưa tải ảnh lên';

  @override
  String get edit_profile_photo_too_large =>
      'Ảnh quá lớn. Vui lòng chọn ảnh dưới 1 MB và thử lại';

  @override
  String get edit_profile_photo_upload_failed =>
      'Không thể tải ảnh của bạn lên. Vui lòng thử lại';

  @override
  String get edit_profile_choose_from_library => 'Chọn từ thư viện';

  @override
  String get edit_profile_take_photo => 'Chụp ảnh';

  @override
  String get edit_profile_offline =>
      'Bạn đang ngoại tuyến. Hãy kết nối internet và thử lại';

  @override
  String get edit_profile_save_failed =>
      'Không thể lưu thay đổi. Vui lòng thử lại';

  @override
  String get edit_profile_traditions => 'Truyền thống';

  @override
  String get edit_profile_choose_traditions => 'Chọn truyền thống của bạn';

  @override
  String get edit_profile_tradition_remove_failed =>
      'Không thể xóa truyền thống. Vui lòng thử lại';

  @override
  String get edit_profile_tradition_save_failed =>
      'Không thể lưu truyền thống. Vui lòng thử lại';

  @override
  String get username_label => 'Tên người dùng';

  @override
  String get username_taken => 'Tên này đã có người dùng';

  @override
  String get username_available_label => 'Có thể dùng:';

  @override
  String get username_check_error =>
      'Không thể kiểm tra tên người dùng. Hãy thử lại';

  @override
  String get username_invalid_format => 'Tên người dùng không đúng định dạng';

  @override
  String get username_min_length => 'Tên người dùng phải có ít nhất 3 ký tự';

  @override
  String get username_max_length => 'Tên người dùng tối đa 30 ký tự';

  @override
  String get username_no_spaces => 'Tên người dùng không được chứa dấu cách';

  @override
  String get username_invalid_chars =>
      'Chỉ được dùng chữ cái, chữ số và các ký tự _ . -';

  @override
  String get username_must_start_alphanumeric =>
      'Tên người dùng phải bắt đầu bằng chữ cái hoặc chữ số';

  @override
  String get username_must_end_alphanumeric =>
      'Tên người dùng phải kết thúc bằng chữ cái hoặc chữ số';

  @override
  String get person_name_min_length => 'Phải có ít nhất 1 ký tự';

  @override
  String get person_name_max_length => 'Tối đa 50 ký tự';

  @override
  String get person_name_invalid_chars =>
      'Chỉ được dùng chữ cái, dấu cách, dấu gạch nối và dấu nháy đơn';

  @override
  String get about_title => 'Giới thiệu';

  @override
  String get about_connect_with_us => 'Kết nối với chúng tôi...';

  @override
  String get about_description =>
      'Chúng tôi giúp Phật tử bớt điều ác, thêm điều lành và hiểu rõ tâm mình hơn qua việc học hỏi, tu tập và kết nối mỗi ngày.';

  @override
  String get about_social_website => 'Trang web';

  @override
  String get me_guest_headline => 'Trải nghiệm đầy đủ tính năng';

  @override
  String get me_guest_subtitle =>
      'Tạo tài khoản miễn phí để lưu tiến trình của bạn';

  @override
  String get me_my_stats => 'Thống kê của tôi';

  @override
  String me_day_streak(int count) {
    return '$count ngày liên tiếp';
  }

  @override
  String me_best_streak(int count) {
    return 'Chuỗi ngày dài nhất: $count ngày';
  }

  @override
  String get accumulations => 'Tích lũy';

  @override
  String get accumulations_search => 'Tìm kiếm tích lũy...';

  @override
  String get accumulations_search_for => 'Tìm kiếm tích lũy';

  @override
  String get accumulations_no_found => 'Không tìm thấy tích lũy nào';

  @override
  String get me_accumulation => 'Tổng tích lũy';

  @override
  String get me_minutes => 'phút';

  @override
  String get me_hours => 'giờ';

  @override
  String get me_total_meditation_time => 'Tổng thời gian thiền';

  @override
  String get me_days_plan_practiced_suffix =>
      'tổng số ngày lộ trình đã hoàn thành';

  @override
  String get me_streak_share_quote =>
      'Chuỗi ngày tu tập hiện tại của tôi trên WeBuddhist!';

  @override
  String me_streak_days_count(int count) {
    return '$count ngày';
  }

  @override
  String get share_this_streak => 'Chia sẻ chuỗi ngày của tôi';

  @override
  String get me_streak_share_error =>
      'Không thể chia sẻ chuỗi ngày. Vui lòng thử lại';

  @override
  String get delete_account_title => 'Xóa tài khoản';

  @override
  String get delete_account_description =>
      'Nếu bạn xóa tài khoản, toàn bộ thông tin, lịch sử và cài đặt cá nhân của bạn trên WeBuddhist sẽ bị xóa vĩnh viễn. Lưu ý rằng thao tác này không thể hoàn tác. Để tiếp tục, hãy nhấn nút bên dưới.';

  @override
  String get delete_account_button => 'Xóa tài khoản';

  @override
  String get delete_account_confirm_message =>
      'Bạn có chắc muốn xóa tài khoản WeBuddhist của mình không?';

  @override
  String get legal_title => 'Pháp lý';

  @override
  String get legal_terms_of_service => 'Điều khoản dịch vụ';

  @override
  String get legal_privacy_policy => 'Chính sách quyền riêng tư';

  @override
  String get follow => 'Theo dõi';

  @override
  String get calendar_title => 'Lịch';

  @override
  String get calendar_upcoming_events => 'Sự kiện sắp tới';

  @override
  String get calendar_day_short => 'NGÀY';

  @override
  String get calendar_day_label => 'Ngày';

  @override
  String calendar_lunar_month(String ordinal) {
    return 'Tháng $ordinal âm lịch';
  }

  @override
  String get moon_phase_new_moon => 'Trăng mới';

  @override
  String get moon_phase_first_quarter => 'Trăng thượng huyền';

  @override
  String get moon_phase_full_moon => 'Trăng tròn';

  @override
  String get join => 'Tham gia';

  @override
  String get group_member => 'thành viên';

  @override
  String get group_members => 'thành viên';

  @override
  String get group_tab_members => 'Thành viên';

  @override
  String get group_tab_followers => 'Người theo dõi';

  @override
  String group_members_heading(int count) {
    return 'Thành viên ($count)';
  }

  @override
  String group_followers_heading(int count) {
    return 'Người theo dõi ($count)';
  }

  @override
  String get group_invite => 'Mời';

  @override
  String get group_notifications_title => 'Thông báo';

  @override
  String get group_notifications_chat => 'Trò chuyện nhóm';

  @override
  String get group_notifications_content => 'Nội dung nhóm';

  @override
  String get group_notifications_master_off =>
      'Thông báo của ứng dụng đang tắt';

  @override
  String get group_notifications_open_settings => 'Bật';

  @override
  String get group_notifications_update_failed =>
      'Không thể cập nhật cài đặt thông báo. Hãy thử lại';

  @override
  String get group_notifications_load_failed =>
      'Không thể tải cài đặt thông báo';

  @override
  String get group_chat_mute_notifications => 'Tắt thông báo trò chuyện';

  @override
  String get group_chat_unmute_notifications => 'Bật thông báo trò chuyện';

  @override
  String get group_chat_notifications_muted => 'Đã tắt thông báo trò chuyện';

  @override
  String get group_chat_notifications_unmuted => 'Đã bật thông báo trò chuyện';

  @override
  String get group_leave_confirm_message =>
      'Bạn sẽ không còn nhận tin nhắn và cập nhật từ nhóm này';

  @override
  String get group_leave_space => 'Rời nhóm';

  @override
  String get group_leave_space_confirm_title => 'Rời nhóm này?';

  @override
  String get group_leave_space_failed => 'Không thể rời nhóm. Hãy thử lại';

  @override
  String get group_request_to_join => 'Xin tham gia';

  @override
  String get group_request => 'Xin tham gia';

  @override
  String get group_request_sent => 'Đã gửi yêu cầu';

  @override
  String get group_join_request_title => 'Xin tham gia';

  @override
  String get group_join_request_message_label => 'Lời nhắn (không bắt buộc)';

  @override
  String get group_join_request_message_hint =>
      'Bạn tu tập như thế nào, hoặc ai đã mời bạn?';

  @override
  String get group_join_request_send => 'Gửi yêu cầu';

  @override
  String get group_join_request_sent_snackbar =>
      'Đã gửi yêu cầu. Quản trị viên sẽ xem xét';

  @override
  String get group_join_request_error =>
      'Không thể gửi yêu cầu. Vui lòng thử lại';

  @override
  String get group_join_requests_title => 'Yêu cầu tham gia';

  @override
  String get group_join_requests_admit => 'Chấp nhận';

  @override
  String get group_join_requests_deny => 'Từ chối';

  @override
  String get group_join_requests_empty => 'Không có yêu cầu nào đang chờ';

  @override
  String get group_join_requests_load_error =>
      'Không thể tải yêu cầu tham gia. Vui lòng thử lại';

  @override
  String get group_join_requests_admit_error =>
      'Không thể chấp nhận yêu cầu này. Vui lòng thử lại';

  @override
  String get group_join_requests_deny_error =>
      'Không thể từ chối yêu cầu này. Vui lòng thử lại';

  @override
  String get group_reports_title => 'Báo cáo';

  @override
  String get group_reports_section_posts => 'Bài đăng';

  @override
  String get group_reports_section_comments => 'Bình luận';

  @override
  String get group_reports_section_messages => 'Tin nhắn';

  @override
  String group_reports_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count báo cáo',
      one: '1 báo cáo',
    );
    return '$_temp0';
  }

  @override
  String get group_reports_view_post => 'Xem bài đăng';

  @override
  String get group_reports_view_message => 'Xem tin nhắn';

  @override
  String get group_reports_delete_post => 'Xóa bài đăng';

  @override
  String get group_reports_delete_comment => 'Xóa bình luận';

  @override
  String get group_reports_delete_message => 'Xóa tin nhắn';

  @override
  String get group_reports_empty => 'Không có báo cáo nào cần xem xét';

  @override
  String get group_reports_load_error =>
      'Không thể tải báo cáo. Vui lòng thử lại';

  @override
  String get group_reports_delete_confirm_title => 'Bạn có chắc không?';

  @override
  String get group_reports_delete_message_confirm =>
      'Tin nhắn này sẽ bị xóa vĩnh viễn';

  @override
  String get group_reports_message_removed => 'Tin nhắn đã bị xóa';

  @override
  String get group_reports_delete_message_error =>
      'Không thể xóa tin nhắn. Vui lòng thử lại';

  @override
  String get group_members_only_title => 'Chỉ dành cho thành viên';

  @override
  String get group_members_only_message => 'Tham gia nhóm này để xem nội dung';

  @override
  String get group_join_request_waiting_title => 'Đang chờ quản trị viên';

  @override
  String get group_join_request_waiting_message =>
      'Chúng tôi sẽ thông báo cho bạn khi yêu cầu được xem xét';

  @override
  String get group_members_load_error =>
      'Không thể tải danh sách thành viên. Vui lòng thử lại';

  @override
  String get group_followers_load_error =>
      'Không thể tải người theo dõi. Vui lòng thử lại.';

  @override
  String get group_members_empty => 'Chưa có thành viên nào';

  @override
  String get group_member_admin => 'Quản trị viên';

  @override
  String get group_member_owner => 'Chủ nhóm';

  @override
  String group_remove_member(String name) {
    return 'Xóa $name';
  }

  @override
  String get group_remove_member_title => 'Xóa khỏi nhóm?';

  @override
  String group_remove_member_message(String name) {
    return '$name sẽ bị xóa khỏi nhóm này và không thể tham gia lại cho đến khi lệnh cấm được gỡ bỏ';
  }

  @override
  String get group_remove_member_blocked_for => 'Chặn trong:';

  @override
  String get group_remove_member_duration_day => '1 ngày';

  @override
  String group_remove_member_duration_days(int count) {
    return '$count ngày';
  }

  @override
  String get group_remove_member_duration_year => '1 năm';

  @override
  String get group_remove_member_reason_label => 'Lý do (không bắt buộc)';

  @override
  String get group_remove_member_reason_hint => 'Lý do khác...';

  @override
  String get group_remove_member_action => 'Xóa';

  @override
  String group_remove_member_success(String name) {
    return 'Đã xóa $name khỏi nhóm';
  }

  @override
  String get group_remove_member_error =>
      'Không thể xóa thành viên này. Hãy thử lại';

  @override
  String group_join_banned_until(String date) {
    return 'Bạn đã bị xóa khỏi nhóm này và không thể tham gia lại cho đến $date';
  }

  @override
  String get group_join_banned =>
      'Bạn đã bị xóa khỏi nhóm này và không thể tham gia lại cho đến khi lệnh cấm được gỡ bỏ';

  @override
  String get group_removed_title => 'Bạn đã bị xóa khỏi nhóm này';

  @override
  String group_removed_message(String group, String duration) {
    return 'Quản trị viên của $group đã xóa bạn khỏi nhóm này. Bạn sẽ không thể xem bài đăng, sự kiện và pháp tu của nhóm, cũng như không thể xin tham gia lại trong $duration.';
  }

  @override
  String group_removed_message_no_date(String group) {
    return 'Quản trị viên của $group đã xóa bạn khỏi nhóm này. Bạn sẽ không thể xem bài đăng, sự kiện và pháp tu của nhóm, cũng như không thể xin tham gia lại';
  }

  @override
  String get group_removed_rejoin_label =>
      'Bạn có thể xin tham gia lại nhóm này vào';

  @override
  String group_removed_rejoin_value(String date, String remaining) {
    return '$date · $remaining';
  }

  @override
  String get group_removed_day_left => 'Còn 1 ngày';

  @override
  String group_removed_days_left(int count) {
    return 'Còn $count ngày';
  }

  @override
  String get group_removed_last_day => 'Còn chưa đầy một ngày';

  @override
  String get group_followers_empty => 'Chưa có người theo dõi';

  @override
  String get group_follower => 'người theo dõi';

  @override
  String get group_followers => 'người theo dõi';

  @override
  String get group_links_title => 'Liên kết';

  @override
  String get group_about_description => 'Mô tả';

  @override
  String get group_about_empty => 'Chưa có thông tin';

  @override
  String group_and_more_links(int count) {
    return 'và $count liên kết khác';
  }

  @override
  String get group_practice_with_us => 'Tu tập cùng chúng tôi';

  @override
  String series_practicing_with_group(String groupName) {
    return 'Đang tu tập cùng $groupName';
  }

  @override
  String get group_change_practice_title => 'Đổi nhóm tu tập';

  @override
  String get group_change_practice_message =>
      'Bạn đang tu tập lộ trình này cùng một nhóm khác. Bạn có muốn đổi nhóm tu tập không?';

  @override
  String get group_join_to_contribute => 'Tham gia để đóng góp';

  @override
  String get group_accumulator_join_error =>
      'Không thể tham gia tích lũy. Vui lòng thử lại';

  @override
  String get group_accumulator_join_before_practice =>
      'Hãy tham gia tích lũy này trước khi thêm vào pháp tu của bạn';

  @override
  String group_accumulator_participants(int count) {
    return '$count người tham gia';
  }

  @override
  String get group_accumulator_leaderboard => 'Bảng xếp hạng';

  @override
  String get group_accumulator_everyone => 'Mọi người';

  @override
  String get group_accumulator_me => 'Tôi';

  @override
  String get group_accumulator_my_contributions => 'Đóng góp của tôi';

  @override
  String get group_accumulator_recited => 'Lượt tụng';

  @override
  String get group_accumulator_total => 'Tổng cộng';

  @override
  String get group_accumulator_contributions_empty =>
      'Tham gia tích lũy này để theo dõi phần đóng góp của bạn';

  @override
  String get group_accumulator_leaderboard_empty => 'Chưa có lượt tụng nào';

  @override
  String get group_accumulator_recite_now => 'Tụng ngay';

  @override
  String get group_accumulator_view_practice => 'Xem pháp tu';

  @override
  String get group_accumulator_chant_again => 'Tụng tiếp';

  @override
  String get group_accumulator_finish_session => 'Kết thúc buổi tụng';

  @override
  String get group_accumulator_offline_recitation => 'Tụng ngoài ứng dụng';

  @override
  String get group_accumulator_add_offline_chants_title =>
      'Thêm lượt tụng ngoài ứng dụng:';

  @override
  String get group_accumulator_add_offline_chants_message =>
      'Thêm số lượt tụng bạn đã thực hiện ngoài ứng dụng';

  @override
  String get group_accumulator_session_complete => 'Hoàn thành buổi tụng!';

  @override
  String group_accumulator_session_recitations(int count) {
    return 'Bạn đã tụng $count lượt trong buổi này';
  }

  @override
  String group_accumulator_session_share_message(
    int count,
    String accumulation,
    String group,
  ) {
    return 'Tôi đã tụng $count lượt trong \"$accumulation\", một chương trình tích lũy của $group trên WeBuddhist. Hãy cùng tham gia với tôi!';
  }

  @override
  String group_accumulator_session_share_message_no_group(
    int count,
    String accumulation,
  ) {
    return 'Tôi đã tụng $count lượt trong chương trình tích lũy \"$accumulation\" trên WeBuddhist. Hãy cùng tham gia với tôi!';
  }

  @override
  String get group_accumulator_session_share_error =>
      'Không thể chia sẻ buổi tụng. Vui lòng thử lại';

  @override
  String group_recitation_collection_share_message(
    String collection,
    String group,
  ) {
    return 'Mời bạn xem \"$collection\", tuyển tập bài tụng của $group trên WeBuddhist. Cùng tu tập với chúng tôi nhé!';
  }

  @override
  String group_recitation_collection_share_message_no_group(String collection) {
    return 'Mời bạn xem tuyển tập bài tụng \"$collection\" trên WeBuddhist. Cùng tu tập với chúng tôi nhé!';
  }

  @override
  String group_recitation_collection_completed_title(String collection) {
    return 'Đã hoàn thành $collection';
  }

  @override
  String get group_recitation_collection_dedication =>
      'Nguyện nhờ công đức này\nchúng sinh đều thoát khổ';

  @override
  String get share_this_quote => 'Chia sẻ câu trích dẫn này';

  @override
  String get shared_from => 'Chia sẻ từ';

  @override
  String get verse_share_error =>
      'Không thể chia sẻ câu trích dẫn. Vui lòng thử lại';

  @override
  String verse_comments_title(int count) {
    return 'Bình luận · $count';
  }

  @override
  String verse_likes_title(int count) {
    return 'Lượt thích · $count';
  }

  @override
  String get verse_like_failed =>
      'Không thể cập nhật lượt thích. Vui lòng thử lại';

  @override
  String get verse_comment_failed =>
      'Không thể đăng bình luận. Vui lòng thử lại';

  @override
  String verse_comment_replying_to(String name) {
    return 'Đang trả lời $name';
  }

  @override
  String get share_app_message =>
      'Tôi đang dùng ứng dụng này để xây dựng thói quen tu tập Phật pháp hằng ngày và nghĩ rằng bạn sẽ rất thích.';

  @override
  String get share_streak_message =>
      'Tôi đang xây dựng thói quen tu tập hằng ngày và muốn chia sẻ với bạn. Có bạn đồng hành sẽ dễ duy trì hơn. Hãy cùng tôi tham gia WeBuddhist.';

  @override
  String get share_chant_message =>
      'Tôi muốn chia sẻ bài tụng này với bạn. Bạn có thể tụng bài này và tìm thấy cả một thư viện các bài tụng và kinh văn khác trên WeBuddhist.';

  @override
  String get share_quote_message =>
      'Tôi thích câu trích dẫn này từ WeBuddhist và muốn chia sẻ với bạn. Đọc thêm nhiều câu trích dẫn sâu sắc khác trên ứng dụng WeBuddhist.';

  @override
  String get share_poem_message =>
      'Tôi thích bài kệ này từ WeBuddhist và muốn chia sẻ với bạn.';

  @override
  String share_poem_title(String title) {
    return '“$title”';
  }

  @override
  String get share_mala_message =>
      'Tôi đang dùng chuỗi hạt kỹ thuật số này trên WeBuddhist và muốn chia sẻ với bạn. Đây là cách dễ dàng để tu tập ở bất cứ đâu.';

  @override
  String get share_passage_message =>
      'Tôi thích đoạn văn này và muốn chia sẻ với bạn. Bạn có thể đọc toàn bộ đoạn trích trong ngữ cảnh trên WeBuddhist.';

  @override
  String get share_timer_message =>
      'Tôi muốn chia sẻ với bạn bộ hẹn giờ thiền này từ WeBuddhist. Nó giúp việc xây dựng thói quen thiền trở nên dễ dàng.';

  @override
  String get share_plan_message =>
      'Tôi đang theo lộ trình tu tập Phật giáo này và muốn chia sẻ với bạn. Bạn có thể cùng tôi tham gia miễn phí trên WeBuddhist.';

  @override
  String get share_plan_subject => 'Hãy cùng tôi tham gia WeBuddhist';

  @override
  String get share_group_invite_message =>
      'Hãy tham gia nhóm này cùng tôi. Cùng nhau tu tập trên WeBuddhist nhé!';

  @override
  String get weekday_monday => 'T2';

  @override
  String get weekday_tuesday => 'T3';

  @override
  String get weekday_wednesday => 'T4';

  @override
  String get weekday_thursday => 'T5';

  @override
  String get weekday_friday => 'T6';

  @override
  String get weekday_saturday => 'T7';

  @override
  String get weekday_sunday => 'CN';

  @override
  String get reader_search_failed => 'Tìm kiếm thất bại.\nVui lòng thử lại';

  @override
  String get reader_swipe_up_for_more => 'Vuốt lên để xem thêm';

  @override
  String get reader_videos => 'Video';

  @override
  String get mala_no_mantras => 'Không có thần chú nào';

  @override
  String get mala_count_load_error => 'Không thể tải số đếm của bạn';

  @override
  String get bookmarks_empty_all_title => 'Chưa có dấu trang nào';

  @override
  String get bookmarks_empty_all_subtitle =>
      'Đánh dấu bất kỳ nội dung nào để lưu vào đây';

  @override
  String get bookmarks_empty_plans_title => 'Chưa đánh dấu lộ trình nào';

  @override
  String get bookmarks_empty_plans_subtitle =>
      'Đánh dấu một lộ trình để lưu vào đây';

  @override
  String get bookmarks_empty_malas_title => 'Chưa đánh dấu chuỗi hạt nào';

  @override
  String get bookmarks_empty_malas_subtitle =>
      'Đánh dấu một chuỗi hạt để lưu vào đây';

  @override
  String get bookmarks_empty_group_accumulations_title =>
      'Chưa đánh dấu tích lũy nhóm nào';

  @override
  String get bookmarks_empty_group_accumulations_subtitle =>
      'Đánh dấu một tích lũy để lưu vào đây';

  @override
  String get bookmarks_empty_timers_title => 'Chưa đánh dấu bộ hẹn giờ nào';

  @override
  String get bookmarks_empty_timers_subtitle =>
      'Đánh dấu một bộ hẹn giờ để lưu vào đây';

  @override
  String get bookmarks_empty_texts_title => 'Chưa đánh dấu kinh văn nào';

  @override
  String get bookmarks_empty_texts_subtitle =>
      'Đánh dấu một kinh văn để lưu vào đây';

  @override
  String get bookmark_removed => 'Đã xóa dấu trang';

  @override
  String get bookmark_remove_failed => 'Không thể xóa dấu trang';

  @override
  String get bookmark_saved => 'Đã lưu dấu trang';

  @override
  String get bookmark_save_failed => 'Không thể lưu dấu trang';

  @override
  String get bookmarks_yesterday => 'Hôm qua';

  @override
  String get webview_timeout_error =>
      'Trang tải quá lâu. Vui lòng kiểm tra kết nối internet';

  @override
  String get webview_load_failed => 'Không thể tải trang';

  @override
  String get privacy_policy_load_error =>
      'Không thể tải trang chính sách quyền riêng tư';

  @override
  String get terms_of_service_load_error =>
      'Không thể tải trang điều khoản dịch vụ';

  @override
  String get series_enroll_error => 'Không thể đăng ký chuỗi lộ trình';

  @override
  String series_share_message(String title, String url) {
    return 'Hãy cùng tôi tu tập $title trên WeBuddhist.\n\n$url';
  }

  @override
  String get player_back_10 => 'Lùi 10 giây';

  @override
  String get player_pause => 'Tạm dừng';

  @override
  String get player_play => 'Phát';

  @override
  String get player_forward_10 => 'Tua tới 10 giây';

  @override
  String get player_fullscreen => 'Toàn màn hình';

  @override
  String get player_exit_fullscreen => 'Thoát toàn màn hình';

  @override
  String get session_plans_load_error =>
      'Không thể tải lộ trình.\nVui lòng thử lại sau';

  @override
  String get session_chants_load_error => 'Không thể tải bài tụng';

  @override
  String get session_no_chants => 'Không tìm thấy bài tụng nào';

  @override
  String get session_malas_load_error => 'Không thể tải chuỗi hạt';

  @override
  String get session_no_malas => 'Không tìm thấy chuỗi hạt nào';

  @override
  String get session_timers_load_error => 'Không thể tải bộ hẹn giờ';

  @override
  String get session_no_timers => 'Không tìm thấy bộ hẹn giờ nào';

  @override
  String days_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày',
      one: '1 ngày',
    );
    return '$_temp0';
  }

  @override
  String timer_minute_session(int minutes) {
    return 'Buổi thiền $minutes phút';
  }

  @override
  String get timer_notification_in_progress => 'Đang thiền';

  @override
  String timer_notification_paused(String time) {
    return 'Đã tạm dừng · còn $time';
  }

  @override
  String get timer_notification_complete => 'Buổi thiền của bạn đã hoàn tất';

  @override
  String plan_day_of(int day, int total) {
    return 'Ngày $day/$total';
  }

  @override
  String pagination_position(int current, int total) {
    return '$current / $total';
  }

  @override
  String get plan_shorts_title => 'Video ngắn từ cộng đồng';

  @override
  String get author_details_load_error =>
      'Không thể tải thông tin tác giả.\nVui lòng thử lại';

  @override
  String get link_cannot_open => 'Không thể mở liên kết này';

  @override
  String get link_invalid => 'Liên kết không hợp lệ';

  @override
  String get author_no_plans => 'Chưa tạo lộ trình nào';

  @override
  String get author_plans_load_error => 'Không thể tải lộ trình';

  @override
  String get drag_to_resize => 'Kéo để đổi kích thước';

  @override
  String get day_completion_share_message =>
      'Tôi vừa hoàn thành một ngày tu tập trên WeBuddhist. Hãy cùng tôi xây dựng thói quen tu tập hằng ngày nhé.';

  @override
  String group_accumulator_share_message(String accumulation, String group) {
    return 'Tôi đang tham gia \"$accumulation\", một chương trình tích lũy của $group trên WeBuddhist. Hãy cùng tham gia với tôi!';
  }

  @override
  String group_accumulator_share_message_no_group(String accumulation) {
    return 'Tôi đang tham gia chương trình tích lũy \"$accumulation\" trên WeBuddhist. Hãy cùng tham gia với tôi!';
  }

  @override
  String get chats_title => 'Trò chuyện';

  @override
  String get chats_empty_title => 'Chưa có cuộc trò chuyện nào';

  @override
  String get chats_empty_body => 'Tham gia một nhóm để bắt đầu trò chuyện';

  @override
  String get group_chat_inappropriate =>
      'Không thể gửi tin nhắn này vì có chứa ngôn từ không được phép';

  @override
  String get group_chat_not_a_member =>
      'Chỉ thành viên mới có thể mở cuộc trò chuyện này';

  @override
  String get group_chat_open => 'Trò chuyện';

  @override
  String get group_chat_message_hint => 'Tin nhắn';

  @override
  String get group_chat_today => 'Hôm nay';

  @override
  String get group_chat_yesterday => 'Hôm qua';

  @override
  String get group_chat_empty_title => 'Chưa có tin nhắn nào';

  @override
  String get group_chat_empty_body => 'Bắt đầu trò chuyện với nhóm của bạn';

  @override
  String get group_chat_load_failed => 'Không thể tải tin nhắn';

  @override
  String get group_chat_message_not_found =>
      'Tin nhắn này không còn trong cuộc trò chuyện';

  @override
  String get group_chat_message_too_far_back =>
      'Tin nhắn này nằm xa hơn trong cuộc trò chuyện';

  @override
  String get group_chat_keep_looking => 'Tiếp tục tìm';

  @override
  String get group_chat_retry => 'Thử lại';

  @override
  String get group_chat_unknown_sender => 'Thành viên';

  @override
  String get group_chat_reactions_all => 'Tất cả';

  @override
  String get group_chat_reacted => 'Đã bày tỏ cảm xúc';

  @override
  String get group_chat_reply => 'Trả lời';

  @override
  String get group_chat_copy => 'Sao chép';

  @override
  String get group_chat_copied => 'Đã sao chép tin nhắn';

  @override
  String get group_chat_report => 'Báo cáo';

  @override
  String get group_chat_report_title => 'Vì sao bạn báo cáo nội dung này?';

  @override
  String get group_chat_report_privacy => 'Tên của bạn sẽ được giữ kín';

  @override
  String get group_chat_report_reason_harassment => 'Quấy rối hoặc bắt nạt';

  @override
  String get group_chat_report_reason_hate => 'Ngôn từ thù ghét hoặc gây hại';

  @override
  String get group_chat_report_reason_sexual =>
      'Nội dung tình dục hoặc khiêu dâm';

  @override
  String get group_chat_report_reason_spam => 'Spam hoặc lừa đảo';

  @override
  String get group_chat_report_reason_off_topic => 'Lạc đề hoặc gây rối';

  @override
  String get group_chat_report_reason_other => 'Lý do khác';

  @override
  String get group_chat_report_note_title => 'Thêm ghi chú';

  @override
  String get group_chat_report_note_hint => 'Lý do khác...';

  @override
  String get group_chat_report_submit => 'Gửi báo cáo';

  @override
  String get group_chat_report_thanks => 'Cảm ơn bạn đã phản hồi';

  @override
  String get group_chat_report_offline =>
      'Bạn đang ngoại tuyến. Hãy thử lại sau';

  @override
  String get group_chat_report_failed => 'Không thể gửi báo cáo';

  @override
  String get group_chat_report_retry => 'Thử lại';

  @override
  String get group_chat_delete => 'Xóa';

  @override
  String get group_chat_delete_title => 'Xóa tin nhắn?';

  @override
  String group_chat_delete_title_many(int count) {
    return 'Xóa $count tin nhắn?';
  }

  @override
  String group_chat_delete_confirm_body(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Các tin nhắn này sẽ bị xóa khỏi cuộc trò chuyện đối với mọi người',
      one: 'Tin nhắn này sẽ bị xóa khỏi cuộc trò chuyện đối với mọi người',
    );
    return '$_temp0';
  }

  @override
  String group_chat_delete_failed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Không thể xóa $count tin nhắn',
      one: 'Không thể xóa tin nhắn',
    );
    return '$_temp0';
  }

  @override
  String group_chat_selection_limit(int count) {
    return 'Bạn có thể chọn tối đa $count tin nhắn';
  }

  @override
  String get group_chat_message_deleted_by_sender => 'Tin nhắn này đã bị xóa';

  @override
  String get group_chat_reaction_failed => 'Không thể lưu cảm xúc của bạn';

  @override
  String group_chat_reactions_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cảm xúc',
      one: '1 cảm xúc',
    );
    return '$_temp0';
  }

  @override
  String get group_chat_you => 'Bạn';

  @override
  String get group_chat_tap_to_remove => 'Nhấn để gỡ';

  @override
  String get group_chat_reply_parent_gone =>
      'Tin nhắn đó không còn nữa nên phần trích dẫn đã được gỡ bỏ. Hãy gửi lại để đăng tin nhắn của bạn';

  @override
  String get group_tab_posts => 'Bài đăng';

  @override
  String get group_tab_events => 'Sự kiện';

  @override
  String get group_posts_empty_title => 'Chưa có bài đăng nào';

  @override
  String get group_posts_empty_message =>
      'Chia sẻ cập nhật đầu tiên của nhóm bạn';

  @override
  String get group_posts_load_error =>
      'Không thể tải bài đăng. Vui lòng thử lại';

  @override
  String get group_post_button => 'Đăng';

  @override
  String get group_post_new_title => 'Bài đăng mới';

  @override
  String get group_post_posting_to => 'Đăng lên:';

  @override
  String get group_post_caption_hint => 'Có gì mới?';

  @override
  String get group_post_photos => 'Ảnh';

  @override
  String get group_post_link => 'Liên kết';

  @override
  String get group_post_discard_title => 'Bỏ bài đăng này?';

  @override
  String get group_post_discard_message => 'Những gì bạn đã viết sẽ bị mất';

  @override
  String get group_post_keep_editing => 'Tiếp tục chỉnh sửa';

  @override
  String get group_post_discard => 'Bỏ';

  @override
  String get group_post_add_link_title => 'Thêm liên kết';

  @override
  String get group_post_add_link_hint =>
      'Dán liên kết và chúng tôi sẽ hiển thị bản xem trước';

  @override
  String get group_post_link_field_hint => 'Liên kết';

  @override
  String get group_post_attach => 'Đính kèm';

  @override
  String get group_post_attach_as_link => 'Đính kèm dưới dạng liên kết';

  @override
  String get group_post_preview_failed_title => 'Không thể tải bản xem trước';

  @override
  String get group_post_preview_failed_message =>
      'Bạn vẫn có thể đính kèm dưới dạng liên kết';

  @override
  String get group_post_invalid_link =>
      'Nhập liên kết hợp lệ, ví dụ: https://example.com';

  @override
  String get group_post_in_app_content => 'Nội dung trong ứng dụng';

  @override
  String get group_post_add_in_app_content_title =>
      'Thêm nội dung trong ứng dụng';

  @override
  String get group_post_in_app_content_empty => 'Chưa có gì để thêm';

  @override
  String group_post_photo_limit(int count) {
    return 'Bạn có thể thêm tối đa $count ảnh';
  }

  @override
  String get group_post_upload_error =>
      'Không thể tải ảnh lên. Vui lòng thử lại';

  @override
  String get group_post_publish_error => 'Không thể đăng bài. Vui lòng thử lại';

  @override
  String get group_post_published => 'Bài đăng của bạn đã được đăng.';

  @override
  String get group_post_delete_title => 'Xóa bài đăng?';

  @override
  String get group_post_delete_message => 'Bài đăng này sẽ bị xóa vĩnh viễn';

  @override
  String get group_post_delete_failed =>
      'Không thể xóa bài đăng. Vui lòng thử lại';

  @override
  String get edit => 'Chỉnh sửa';

  @override
  String get group_post_edit_title => 'Chỉnh sửa bài đăng';

  @override
  String get group_post_update_error =>
      'Không thể lưu thay đổi. Vui lòng thử lại';

  @override
  String get group_post_updated => 'Đã lưu thay đổi của bạn';

  @override
  String get practice_collection_already_added =>
      'Tuyển tập này đã có trong pháp tu của bạn';

  @override
  String get practice_group_accumulator_already_added =>
      'Tích lũy này đã có trong pháp tu của bạn';

  @override
  String get event_live_badge => 'TRỰC TIẾP';

  @override
  String get event_live_video_mode => 'Video';

  @override
  String get event_live_audio_mode => 'Âm thanh';

  @override
  String get event_live_go_live => 'Trực tiếp';

  @override
  String get event_replays => 'Xem lại';

  @override
  String event_replay_session(String day, String session) {
    return 'Ngày $day · Buổi $session';
  }

  @override
  String get event_replay_recording => 'Bản ghi';

  @override
  String get event_replay_back_to_live => 'Quay lại phát trực tiếp';

  @override
  String get event_replays_empty => 'Chưa có bản ghi nào';

  @override
  String get event_puja_starts_in => 'Pháp hội bắt đầu sau';

  @override
  String get event_puja_not_started => 'Pháp hội chưa bắt đầu';

  @override
  String get event_prayer_requests => 'Lời nhờ cầu nguyện';

  @override
  String event_prayer_request_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lời nhờ',
      one: '1 lời nhờ',
    );
    return '$_temp0';
  }

  @override
  String get event_prayer_empty_title => 'Chưa có lời nhờ cầu nguyện nào';

  @override
  String get event_prayer_empty_body =>
      'Lời nhờ của bạn và của nhóm sẽ hiển thị tại đây';

  @override
  String get event_prayer_add => 'Thêm lời nhờ cầu nguyện';

  @override
  String get event_prayer_hint => 'Chia sẻ lời nhờ cầu nguyện';

  @override
  String event_prayer_hint_intention(String topics) {
    return 'Nhờ cầu nguyện cho: $topics';
  }

  @override
  String get event_prayer_load_failed => 'Không thể tải lời nhờ cầu nguyện';

  @override
  String get event_prayer_closed =>
      'Sự kiện này đã ngừng nhận lời nhờ cầu nguyện';

  @override
  String get group_prayer_closed => 'Nhóm này đã ngừng nhận lời nhờ cầu nguyện';

  @override
  String get group_prayer_delete_body =>
      'Lời nhờ này sẽ bị xóa đối với mọi người trong nhóm.';

  @override
  String get event_prayer_pray => 'Cầu nguyện';

  @override
  String event_prayer_my_count(int count) {
    return '+$count';
  }

  @override
  String get event_prayer_new_request => 'Lời nhờ cầu nguyện mới';

  @override
  String get event_prayer_edit_request => 'Chỉnh sửa lời nhờ cầu nguyện';

  @override
  String get event_prayer_delete_title => 'Xóa lời nhờ cầu nguyện?';

  @override
  String get event_prayer_delete_body =>
      'Lời nhờ này sẽ bị xóa đối với mọi người trong sự kiện.';

  @override
  String get event_prayer_delete_failed => 'Không thể xóa lời nhờ cầu nguyện';

  @override
  String get event_prayer_choose_intention => 'Chọn ý nguyện';

  @override
  String get event_prayer_intentions_failed => 'Không thể tải các ý nguyện';

  @override
  String get event_prayer_request_button => 'Nhờ cầu nguyện';

  @override
  String get event_prayer_you => 'Bạn';

  @override
  String get event_prayer_waiting_first =>
      'Đang chờ lời cầu nguyện đầu tiên...';

  @override
  String event_prayer_more_praying(int count) {
    return '+$count người khác đã cầu nguyện';
  }

  @override
  String event_prayer_people_praying(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count người đã cầu nguyện',
      one: '$count người đã cầu nguyện',
    );
    return '$_temp0';
  }

  @override
  String get event_prayer_praying_for_you => 'Đã cầu nguyện cho bạn';

  @override
  String get event_prayer_your_request => 'Lời nhờ của bạn';

  @override
  String get event_prayer_supporters_failed =>
      'Không thể tải danh sách người cầu nguyện.';

  @override
  String get event_prayer_no_supporters => 'Chưa có ai cầu nguyện';

  @override
  String get event_prayer_sort_by => 'Cầu nguyện cho';

  @override
  String get event_prayer_sort_needs_prayers => 'Cần cầu nguyện';

  @override
  String get event_prayer_sort_most_prayed => 'Được cầu nguyện nhiều nhất';

  @override
  String get event_prayer_sort_newest => 'Mới nhất';

  @override
  String get event_prayer_sort_oldest => 'Cũ nhất';

  @override
  String get event_prayer_sort_by_intention => 'Theo ý nguyện';

  @override
  String get event_prayer_clear_intention => 'Bỏ chọn ý nguyện';

  @override
  String get event_prayer_filter_empty_title => 'Không có lời nhờ nào phù hợp';

  @override
  String get event_prayer_filter_empty_body =>
      'Hãy thử cách sắp xếp hoặc ý nguyện khác';

  @override
  String get event_prayer_see_translation => 'Xem bản dịch';

  @override
  String get event_prayer_see_original => 'Xem bản gốc';

  @override
  String event_prayer_translated_from(String language) {
    return 'Dịch từ $language';
  }

  @override
  String get event_prayer_translated => 'Đã dịch';

  @override
  String get event_prayer_sort_mine => 'Lời nhờ của tôi';

  @override
  String get event_prayer_section_active => 'Đang mở';

  @override
  String get event_prayer_section_accomplished => 'Đã thành tựu';

  @override
  String get event_prayer_mark_accomplished => 'Đã thành tựu';

  @override
  String get event_prayer_mark_active => 'Đánh dấu là đang mở';

  @override
  String get event_prayer_mine_empty_title =>
      'Bạn chưa có lời nhờ cầu nguyện nào';

  @override
  String get event_prayer_mine_empty_body =>
      'Lời nhờ bạn đăng tại đây sẽ hiển thị trong danh sách này';

  @override
  String get event_prayer_update_failed =>
      'Không thể cập nhật lời nhờ cầu nguyện';

  @override
  String get event_prayer_find => 'Tìm một lời cầu nguyện cho bạn';

  @override
  String get event_prayer_random => 'Ngẫu nhiên';

  @override
  String get event_prayer_finding => 'Đang tìm lời cầu nguyện...';

  @override
  String get event_prayer_found => 'Một lời cầu nguyện dành cho bạn';

  @override
  String get event_prayer_skip => 'Bỏ qua';

  @override
  String get event_prayer_next => 'Lời cầu nguyện tiếp theo';

  @override
  String get event_prayer_be_first => 'Hãy là người đầu tiên cầu nguyện';

  @override
  String get event_prayer_random_empty_title =>
      'Chưa có lời cầu nguyện nào để tìm';

  @override
  String get event_prayer_random_empty_body =>
      'Chưa có ai khác đăng lời nhờ tại đây';

  @override
  String get event_prayer_random_failed => 'Không thể tìm lời cầu nguyện';

  @override
  String event_prayer_people_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count người',
      one: '1 người',
    );
    return '$_temp0';
  }

  @override
  String event_prayer_prayers_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lượt cầu nguyện',
      one: '1 lượt cầu nguyện',
    );
    return '$_temp0';
  }

  @override
  String get me_prayer_requests => 'Lời nhờ cầu nguyện của tôi';

  @override
  String get me_prayer_requests_empty_title => 'Chưa có lời nhờ cầu nguyện nào';

  @override
  String get me_prayer_requests_empty_body =>
      'Lời nhờ bạn đăng trong các nhóm và sự kiện sẽ hiển thị tại đây';

  @override
  String get me_prayer_delete_body =>
      'Lời nhờ này sẽ bị xóa đối với mọi người trong nhóm hoặc sự kiện đó.';

  @override
  String get recitation_live_sync => 'Đồng bộ';

  @override
  String get recitation_live_label => 'Trực tiếp';

  @override
  String get recitation_live_session_ended => 'Buổi tụng trực tiếp đã kết thúc';

  @override
  String get feedback_add_image => 'Thêm ảnh';

  @override
  String feedback_image_limit(int count) {
    return 'Bạn có thể đính kèm tối đa $count ảnh';
  }

  @override
  String get feedback_send => 'Gửi';

  @override
  String get feedback_error_offline =>
      'Bạn đang ngoại tuyến. Vui lòng thử lại sau';

  @override
  String get feedback_error_rate_limited =>
      'Quá nhiều yêu cầu. Hãy chờ một lát rồi thử lại';

  @override
  String get feedback_error_too_large =>
      'Ảnh quá lớn. Hãy bỏ bớt một ảnh và thử lại';

  @override
  String get feedback_error_failed => 'Không thể gửi góp ý. Vui lòng thử lại';

  @override
  String get feedback_error_unavailable =>
      'Tính năng góp ý hiện không khả dụng';

  @override
  String get settings_help_contact_row => 'Trợ giúp & liên hệ';

  @override
  String get help_contact_title => 'Trợ giúp & liên hệ';

  @override
  String get help_contact_intro =>
      'Báo cáo sự cố, chia sẻ ý tưởng, hoặc đề nghị giúp đỡ hay cộng tác. Chúng tôi đọc mọi tin nhắn.';

  @override
  String get help_contact_message => 'Tin nhắn';

  @override
  String get help_contact_photos =>
      'Ảnh hoặc ảnh chụp màn hình (không bắt buộc)';

  @override
  String get help_contact_topic => 'Bạn liên hệ về vấn đề gì? (không bắt buộc)';

  @override
  String get help_contact_hint_default => 'Bạn muốn nói gì với chúng tôi?';

  @override
  String get help_contact_hint_report_problem =>
      'Chuyện gì đã xảy ra và ngay trước đó bạn đang làm gì? Ảnh chụp màn hình sẽ rất hữu ích.';

  @override
  String get help_contact_hint_idea_feedback =>
      'Điều gì sẽ giúp WeBuddhist hữu ích hơn cho việc tu tập của bạn?';

  @override
  String get help_contact_hint_suggest_content =>
      'Bạn muốn thấy giáo lý, kinh văn hoặc vị thầy nào ở đây? Bạn có thể gửi kèm liên kết.';

  @override
  String get help_contact_hint_help_collaborate =>
      'Bạn muốn giúp đỡ như thế nào? Hãy chia sẻ kỹ năng, ngôn ngữ hoặc thời gian bạn có thể đóng góp.';

  @override
  String get help_topic_report_problem => 'Báo cáo sự cố';

  @override
  String get help_topic_idea_feedback => 'Ý tưởng hoặc góp ý';

  @override
  String get help_topic_suggest_content => 'Đề xuất nội dung';

  @override
  String get help_topic_help_collaborate => 'Giúp đỡ hoặc cộng tác';

  @override
  String get help_contact_footer =>
      'Phản hồi sẽ được Đội ngũ WeBuddhist gửi đến mục Trò chuyện của bạn.';

  @override
  String get help_contact_sent_title => 'Đã gửi tin nhắn';

  @override
  String get help_contact_sent_body =>
      'Cảm ơn bạn. Chúng tôi thường trả lời trong vòng 1 ngày. Bạn sẽ thấy câu trả lời từ Đội ngũ WeBuddhist trong mục Trò chuyện.';

  @override
  String help_contact_sent_body_named(String name) {
    return 'Cảm ơn $name. Chúng tôi thường trả lời trong vòng 1 ngày. Bạn sẽ thấy câu trả lời từ Đội ngũ WeBuddhist trong mục Trò chuyện.';
  }

  @override
  String get help_contact_your_request => 'YÊU CẦU CỦA BẠN';

  @override
  String get help_contact_open_chat => 'Mở trò chuyện';

  @override
  String get help_context_sent_from => 'Gửi từ Trợ giúp & liên hệ';

  @override
  String help_context_photos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ảnh',
      one: '1 ảnh',
    );
    return '$_temp0';
  }

  @override
  String get chat_official_badge => 'Chính thức';

  @override
  String get chat_team_reply_time => 'Thường trả lời trong vòng 1 ngày';

  @override
  String get connect_failed_load_discover_groups_error =>
      'Không thể tải các nhóm';

  @override
  String get connect_failed_like_post_error => 'Không thể thích bài đăng';

  @override
  String get connect_failed_unlike_post_error => 'Không thể bỏ thích bài đăng';

  @override
  String get group_events_load_error =>
      'Không thể tải sự kiện. Vui lòng thử lại.';

  @override
  String get group_events_empty => 'Chưa có sự kiện nào';

  @override
  String get group_events_empty_message =>
      'Tạo buổi sinh hoạt đầu tiên — thành viên sẽ được thông báo.';

  @override
  String get group_event_create_button => 'Tạo sự kiện';

  @override
  String get group_event_new_title => 'Sự kiện mới';

  @override
  String group_event_step_of(int current, int total) {
    return 'Bước $current/$total';
  }

  @override
  String get group_event_step_about => 'Thông tin';

  @override
  String get group_event_cover_image => 'Ảnh bìa';

  @override
  String get group_event_add_cover_photo => 'Thêm ảnh bìa';

  @override
  String get group_event_change_cover => 'Đổi';

  @override
  String get group_event_name_and_description => 'Tên và mô tả';

  @override
  String get group_event_name_label => 'Tên sự kiện';

  @override
  String get group_event_name_hint => 'Ví dụ: Tu tập nhóm thứ Tư';

  @override
  String get group_event_description_label => 'Mô tả (không bắt buộc)';

  @override
  String get group_event_description_hint =>
      'Các bạn sẽ cùng nhau tu tập gì? Có cần mang theo gì không?';

  @override
  String get group_event_write => 'Viết';

  @override
  String get group_event_preview => 'Xem trước';

  @override
  String get group_event_preview_empty => 'Chưa có gì để xem trước';

  @override
  String get group_event_continue => 'Tiếp tục';

  @override
  String get group_event_name_required_hint => 'Thêm tên sự kiện để tiếp tục';

  @override
  String get group_event_languages_title => 'Ngôn ngữ của sự kiện';

  @override
  String get group_event_languages_add => 'Thêm ngôn ngữ';

  @override
  String get group_event_languages_hint =>
      'Được chọn sẵn theo ngôn ngữ của nhóm bạn. Người xem sẽ thấy sự kiện bằng ngôn ngữ của họ nếu có.';

  @override
  String get group_event_discard_title => 'Bỏ sự kiện này?';

  @override
  String get group_event_discard_message => 'Những gì bạn đã nhập sẽ bị mất';

  @override
  String get group_event_format_bold => 'In đậm';

  @override
  String get group_event_format_italic => 'In nghiêng';

  @override
  String get group_event_format_heading => 'Tiêu đề';

  @override
  String get group_event_format_bullet_list => 'Danh sách dấu đầu dòng';

  @override
  String get group_event_format_numbered_list => 'Danh sách đánh số';

  @override
  String get group_event_format_link => 'Liên kết';

  @override
  String get group_event_link_title => 'Chèn liên kết';

  @override
  String get group_event_link_text_hint => 'Văn bản';

  @override
  String get group_event_link_url_hint => 'https://';

  @override
  String get group_event_link_insert => 'Chèn';

  @override
  String get group_event_step_when_where => 'Thời gian & địa điểm';

  @override
  String get group_event_when => 'Thời gian';

  @override
  String get group_event_where => 'Địa điểm';

  @override
  String get group_event_one_time => 'Một lần';

  @override
  String get group_event_recurring => 'Định kỳ';

  @override
  String get group_event_date => 'Ngày';

  @override
  String get group_event_start_date => 'Ngày bắt đầu';

  @override
  String get group_event_end_date => 'Ngày kết thúc';

  @override
  String get group_event_first_date => 'Ngày đầu tiên';

  @override
  String get group_event_choose_date => 'Chọn ngày';

  @override
  String get group_event_multi_day => 'Sự kiện nhiều ngày';

  @override
  String get group_event_all_day => 'Cả ngày';

  @override
  String get group_event_all_day_hint =>
      'Hiển thị là cả ngày trên trang sự kiện.';

  @override
  String get group_event_start_time => 'Giờ bắt đầu';

  @override
  String get group_event_end_time => 'Giờ kết thúc';

  @override
  String get group_event_add_start_time => 'Thêm giờ bắt đầu';

  @override
  String get group_event_add_end_time => 'Thêm giờ kết thúc';

  @override
  String group_event_time_starts(String time) {
    return 'bắt đầu lúc $time';
  }

  @override
  String group_event_time_ends(String time) {
    return 'kết thúc lúc $time';
  }

  @override
  String get group_event_timezone => 'Múi giờ';

  @override
  String get group_event_repeats => 'Lặp lại';

  @override
  String get group_event_choose_repeats => 'Chọn cách lặp lại';

  @override
  String get group_event_duration => 'Thời lượng';

  @override
  String get group_event_duration_decrease => 'Giảm thời lượng';

  @override
  String get group_event_duration_increase => 'Tăng thời lượng';

  @override
  String group_event_duration_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày',
      one: '1 ngày',
    );
    return '$_temp0';
  }

  @override
  String group_event_repeats_weekly(String weekday) {
    return 'Hằng tuần vào $weekday';
  }

  @override
  String group_event_repeats_monthly(String day) {
    return 'Hằng tháng vào ngày $day';
  }

  @override
  String group_event_repeats_monthly_lunar(String day) {
    return 'Hằng tháng vào ngày $day âm lịch';
  }

  @override
  String group_event_repeats_yearly(String date) {
    return 'Hằng năm vào $date';
  }

  @override
  String get group_event_repeats_yearly_lunar =>
      'Hằng năm vào ngày âm lịch này';

  @override
  String get group_event_full_moon => 'Ngày rằm';

  @override
  String get group_event_new_moon => 'Ngày trăng mới';

  @override
  String get group_event_gregorian => 'Dương lịch';

  @override
  String get group_event_tibetan_lunar => 'Âm lịch Tây Tạng';

  @override
  String get group_event_next_dates => 'Các ngày tiếp theo';

  @override
  String get group_event_repeats_hint => 'Các tùy chọn dựa trên ngày đầu tiên.';

  @override
  String get group_event_in_person => 'Trực tiếp';

  @override
  String get group_event_live => 'Trực tuyến';

  @override
  String get group_event_both => 'Cả hai';

  @override
  String get group_event_venue => 'Địa điểm';

  @override
  String get group_event_add_venue => 'Thêm địa điểm';

  @override
  String get group_event_venue_search_hint =>
      'Tìm khu vực, đường phố hoặc địa danh';

  @override
  String get group_event_venue_no_results => 'Không tìm thấy địa điểm nào';

  @override
  String get group_event_venue_search_error => 'Hiện không thể tìm kiếm';

  @override
  String get group_event_drop_pin => 'Ghim vị trí';

  @override
  String get group_event_drop_pin_hint => 'Chọn vị trí trên bản đồ';

  @override
  String get group_event_pin_marker => 'Địa điểm sự kiện';

  @override
  String get group_event_selected_location => 'Địa điểm đã chọn';

  @override
  String get group_event_pin_unnamed => 'Vị trí đã ghim';

  @override
  String get group_event_confirm_location => 'Xác nhận địa điểm';

  @override
  String get group_event_name_location => 'Đặt tên địa điểm';

  @override
  String get group_event_venue_name => 'Tên địa điểm';

  @override
  String get group_event_venue_name_hint =>
      'Ví dụ: Trung tâm Phật pháp Kim Cương Tát Đỏa';

  @override
  String get group_event_save_venue => 'Lưu địa điểm';

  @override
  String get group_event_live_link => 'Liên kết phát trực tiếp';

  @override
  String get group_event_live_link_hint =>
      'youtube.com/… hoặc liên kết cuộc họp';

  @override
  String get group_event_use_channel_link => 'Dùng liên kết kênh';

  @override
  String get group_event_live_link_youtube_help =>
      'Buổi phát trực tiếp trên YouTube của nhóm bạn. Video sẽ phát ngay trong WeBuddhist. Dán liên kết khác để thay đổi.';

  @override
  String get group_event_live_link_custom_help =>
      'Liên kết tùy chỉnh. Người xem sẽ mở liên kết này bên ngoài WeBuddhist.';

  @override
  String get group_event_live_link_invalid => 'Đây có vẻ chưa phải là liên kết';

  @override
  String get group_event_pick_date_hint => 'Chọn ngày để tiếp tục';

  @override
  String get group_event_pick_repeats_hint => 'Chọn cách lặp lại để tiếp tục';

  @override
  String get group_event_end_date_hint => 'Ngày kết thúc phải sau ngày bắt đầu';

  @override
  String get group_event_end_time_hint => 'Giờ kết thúc phải sau giờ bắt đầu';

  @override
  String get group_event_venue_hint => 'Chọn địa điểm để tiếp tục';

  @override
  String get group_event_link_required_hint =>
      'Thêm liên kết cuộc họp để tiếp tục';

  @override
  String get group_event_map_attribution =>
      '© Những người đóng góp OpenStreetMap';

  @override
  String get group_event_step_practices => 'Pháp tu & video';

  @override
  String get group_event_optional_note =>
      'Mọi thông tin ở đây đều không bắt buộc. Bạn có thể thêm sau.';

  @override
  String get group_event_practices_section => 'Pháp tu của sự kiện';

  @override
  String get group_event_add_practice => 'Thêm pháp tu';

  @override
  String get group_event_practice_search_hint =>
      'Tìm kiếm pháp tu của nhóm bạn';

  @override
  String get group_event_practice_filter_all => 'Tất cả';

  @override
  String get group_event_practice_filter_content => 'Lộ trình & chuỗi';

  @override
  String get group_event_practice_filter_collections => 'Tuyển tập bài tụng';

  @override
  String get group_event_practice_filter_accumulators => 'Tích lũy';

  @override
  String get group_event_practice_rule =>
      'Mỗi sự kiện có một lộ trình hoặc chuỗi lộ trình và một tuyển tập bài tụng. Bạn có thể thêm bao nhiêu tích lũy tùy ý.';

  @override
  String group_event_practice_replaced(String chosen, String previous) {
    return 'Đã chọn $chosen thay cho $previous.';
  }

  @override
  String get group_event_practices_empty => 'Nhóm này chưa có pháp tu nào';

  @override
  String get group_event_practices_load_error =>
      'Không thể tải pháp tu. Vui lòng thử lại.';

  @override
  String get group_event_practices_none_match => 'Không có pháp tu nào phù hợp';

  @override
  String group_event_add_practices_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Thêm $count pháp tu',
      one: 'Thêm 1 pháp tu',
      zero: 'Thêm pháp tu',
    );
    return '$_temp0';
  }

  @override
  String get group_event_counted_by => 'Người ghi số';

  @override
  String get group_event_count_mode_title => 'Ai sẽ ghi số lượng?';

  @override
  String get group_event_count_mode_attendees =>
      'Người tham dự tự ghi trong ứng dụng';

  @override
  String get group_event_count_mode_attendees_hint =>
      'Mỗi người tự thêm lượt tụng của mình, trong hoặc sau sự kiện';

  @override
  String get group_event_count_mode_admin =>
      'Quản trị viên ghi số cho người tham dự trực tiếp';

  @override
  String get group_event_count_mode_admin_hint =>
      'Bạn nhập số lượng của cả nhóm, tức là số người × số vòng';

  @override
  String get group_event_count_mode_admin_short => 'Quản trị viên ghi';

  @override
  String get group_event_count_mode_attendees_taken =>
      'Một tích lũy khác đã dùng cách này. Trong mỗi sự kiện, người tham dự chỉ có thể thêm số lượng vào một tích lũy.';

  @override
  String group_event_remove_practice(String title) {
    return 'Gỡ $title';
  }

  @override
  String get group_event_videos_section => 'Video giới thiệu';

  @override
  String get group_event_videos_hint =>
      'Hiển thị trên trang Thông tin của sự kiện. Dùng để giới thiệu sự kiện hoặc cho biết những gì sẽ diễn ra.';

  @override
  String get group_event_add_video => 'Thêm video';

  @override
  String get group_event_video_link => 'Liên kết YouTube';

  @override
  String get group_event_video_link_hint => 'https://youtu.be/…';

  @override
  String get group_event_paste => 'Dán';

  @override
  String get group_event_video_loading => 'Đang lấy thông tin video…';

  @override
  String get group_event_video_invalid =>
      'Đây có vẻ không phải là liên kết YouTube. Hãy dán liên kết từ YouTube.';

  @override
  String get group_event_video_source => 'YouTube';

  @override
  String get group_event_video_untitled => 'Video YouTube';

  @override
  String get group_event_remove_video => 'Gỡ video';

  @override
  String get group_event_skip => 'Bỏ qua';

  @override
  String get group_event_step_review => 'Xem lại & đăng';

  @override
  String get group_event_review_event => 'Sự kiện';

  @override
  String get group_event_review_settings => 'Cài đặt';

  @override
  String get group_event_review_name => 'Tên';

  @override
  String get group_event_review_languages => 'Ngôn ngữ';

  @override
  String get group_event_review_when => 'Thời gian';

  @override
  String get group_event_review_where => 'Địa điểm';

  @override
  String get group_event_review_live_link => 'Liên kết phát trực tiếp';

  @override
  String get group_event_review_practices => 'Pháp tu';

  @override
  String get group_event_review_videos => 'Video giới thiệu';

  @override
  String get group_event_review_event_settings => 'Cài đặt sự kiện';

  @override
  String get group_event_review_none => 'Không có';

  @override
  String get group_event_review_tap_hint => 'Nhấn vào dòng bất kỳ để thay đổi.';

  @override
  String get group_event_review_notify_hint =>
      'Thành viên sẽ được thông báo khi bạn đăng.';

  @override
  String group_event_review_more(String first, int count) {
    return '$first + $count khác';
  }

  @override
  String group_event_review_recurring_from(
    String rule,
    String times,
    String date,
  ) {
    return '$rule · $times · từ $date';
  }

  @override
  String get group_event_review_youtube_live => 'Phát trực tiếp trên YouTube';

  @override
  String get group_event_review_online => 'Trực tuyến';

  @override
  String get group_event_chat_on => 'Đã bật trò chuyện';

  @override
  String get group_event_chat_off => 'Đã tắt trò chuyện';

  @override
  String get group_event_notifications_on => 'Đã bật thông báo';

  @override
  String get group_event_notifications_off => 'Đã tắt thông báo';

  @override
  String get group_event_all_intentions => 'Tất cả ý nguyện';

  @override
  String group_event_intentions_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ý nguyện',
      one: '1 ý nguyện',
    );
    return '$_temp0';
  }

  @override
  String get group_event_publish => 'Đăng';

  @override
  String get group_event_publish_error =>
      'Không thể đăng sự kiện. Vui lòng thử lại';

  @override
  String get group_event_settings_title => 'Cài đặt sự kiện';

  @override
  String get group_event_settings_chat => 'Trò chuyện sự kiện';

  @override
  String get group_event_settings_chat_hint =>
      'Tạo khung trò chuyện riêng cho sự kiện, nơi thành viên có thể trò chuyện và đăng lời nhờ cầu nguyện.';

  @override
  String get group_event_settings_notifications => 'Thông báo';

  @override
  String get group_event_settings_notifications_hint =>
      'Thông báo khi bạn đăng, lời nhắc trước khi bắt đầu và mọi thông báo do bạn tự gửi.';

  @override
  String get group_event_settings_intentions => 'Ý nguyện cầu nguyện';

  @override
  String get group_event_settings_intentions_hint =>
      'Không chọn mục nào để cho phép mọi ý nguyện.';

  @override
  String get group_event_settings_intentions_error =>
      'Hiện không thể tải các ý nguyện.';

  @override
  String get group_event_published_title => 'Đã đăng';

  @override
  String group_event_published_headline(String name) {
    return '$name đã được đăng';
  }

  @override
  String group_event_published_message(String group) {
    return 'Thành viên của $group đã được thông báo. Bạn có thể chỉnh sửa bất cứ lúc nào từ trang sự kiện.';
  }

  @override
  String get group_event_published_message_silent =>
      'Bạn có thể chỉnh sửa bất cứ lúc nào từ trang sự kiện.';

  @override
  String get group_event_view_event => 'Xem sự kiện';

  @override
  String get group_event_drafts_section => 'Bản nháp';

  @override
  String get group_event_draft_label => 'Bản nháp';

  @override
  String get group_event_draft_untitled => 'Sự kiện chưa đặt tên';

  @override
  String get group_event_draft_menu_continue => 'Tiếp tục chỉnh sửa';

  @override
  String get group_event_draft_menu_delete => 'Xóa bản nháp';

  @override
  String get group_event_draft_menu_delete_hint =>
      'Không thể hoàn tác thao tác này';

  @override
  String get group_event_draft_saved => 'Đã lưu bản nháp';

  @override
  String get group_event_draft_save_error =>
      'Không thể lưu bản nháp. Vui lòng thử lại';

  @override
  String get group_event_draft_deleted => 'Đã xóa bản nháp';

  @override
  String get group_event_draft_delete_error =>
      'Không thể xóa bản nháp. Vui lòng thử lại';

  @override
  String get group_event_draft_delete_title => 'Xóa bản nháp?';

  @override
  String get group_event_draft_delete_message =>
      'Bản nháp này sẽ bị xóa vĩnh viễn';

  @override
  String get group_event_edit_draft_title => 'Chỉnh sửa bản nháp';

  @override
  String get group_event_edit_title => 'Chỉnh sửa sự kiện';

  @override
  String get group_event_save_changes => 'Lưu thay đổi';

  @override
  String get group_event_changes_saved => 'Đã lưu thay đổi';

  @override
  String get group_event_manage => 'Quản lý sự kiện';

  @override
  String get group_event_manage_details => 'Chi tiết';

  @override
  String get group_event_manage_counts => 'Số lượng';

  @override
  String get group_event_manage_accumulations => 'Tích lũy';

  @override
  String get group_event_manage_admin_adds_pending => 'Quản trị viên ghi';

  @override
  String group_event_manage_admin_adds(String count) {
    return 'Quản trị viên ghi · đã có $count';
  }

  @override
  String get group_event_manage_attendees_add_pending =>
      'Người tham dự tự ghi trong ứng dụng';

  @override
  String group_event_manage_attendees_add(String count, int people) {
    String _temp0 = intl.Intl.pluralLogic(
      people,
      locale: localeName,
      other: 'Người tham dự tự ghi · $count từ $people người',
      one: 'Người tham dự tự ghi · $count từ 1 người',
    );
    return '$_temp0';
  }

  @override
  String get group_event_manage_add_count => 'Thêm số lượng';

  @override
  String get group_event_manage_no_accumulations =>
      'Sự kiện này không có tích lũy nào.';

  @override
  String get group_event_manage_recurring_note =>
      'Danh sách người tham dự không được lưu cho sự kiện định kỳ. Số lượng được cộng dồn qua tất cả các buổi.';

  @override
  String group_event_in_person_of_target(String count, String target) {
    return '$count / $target';
  }

  @override
  String group_event_in_person_in_total(String count) {
    return 'Tổng cộng $count';
  }

  @override
  String get group_event_in_person_legend_app => 'Ứng dụng';

  @override
  String get group_event_in_person_legend_in_person => 'Trực tiếp';

  @override
  String get group_event_in_person_add_day => 'Thêm ngày';

  @override
  String get group_event_in_person_day => 'Ngày';

  @override
  String get group_event_in_person_count => 'Số lượng';

  @override
  String get group_event_in_person_empty => 'Chưa có số lượng trực tiếp nào.';

  @override
  String get group_event_in_person_invalid_count =>
      'Nhập một số nguyên từ 1 trở lên';

  @override
  String get group_event_in_person_added => 'Đã thêm số lượng trực tiếp';

  @override
  String get group_event_in_person_updated => 'Đã cập nhật số lượng trực tiếp';

  @override
  String get group_event_in_person_deleted => 'Đã xóa số lượng trực tiếp';

  @override
  String get group_event_in_person_delete_title => 'Xóa số lượng trực tiếp?';

  @override
  String group_event_in_person_delete_message(String count, String day) {
    return '$count của $day sẽ bị trừ khỏi tổng số của tích lũy.';
  }

  @override
  String get group_event_in_person_exists =>
      'Ngày đó đã có số lượng. Hãy chỉnh sửa số lượng đó.';

  @override
  String get group_event_in_person_no_accumulation =>
      'Liên kết một tích lũy của nhóm với sự kiện này để ghi nhận số lượng trực tiếp.';

  @override
  String get group_event_in_person_save_error => 'Không thể lưu số lượng.';

  @override
  String get group_event_in_person_load_more => 'Tải thêm';

  @override
  String get mala_failed_load_catalogue_error => 'Không thể tải danh mục';

  @override
  String get chant_collection_reload_error =>
      'Không thể tải lại tuyển tập để sắp xếp lại';

  @override
  String get chant_collection_reorder_error =>
      'Không thể sắp xếp lại các bài tụng';

  @override
  String get timer_duration_label => 'THỜI LƯỢNG';

  @override
  String get timer_ambient_sound_label => 'ÂM THANH NỀN';

  @override
  String get timer_begin_session => 'Bắt đầu buổi thiền';

  @override
  String get timer_save_changes => 'Lưu thay đổi';

  @override
  String get timer_new_title => 'Bộ hẹn giờ mới';

  @override
  String get timer_title_hint => 'Tiêu đề...';

  @override
  String get timer_edit_title => 'Chỉnh sửa bộ hẹn giờ';

  @override
  String get timer_your_timers => 'Bộ hẹn giờ của bạn';

  @override
  String get timer_ambient_sounds_title => 'Âm thanh nền';

  @override
  String get timer_ambient_sound_none => 'Mặc định (không có âm thanh)';

  @override
  String get timer_ambient_sounds_load_error => 'Không thể tải âm thanh nền';

  @override
  String get timer_volume_label => 'ÂM LƯỢNG';

  @override
  String get timer_duration_title => 'Thời lượng';

  @override
  String get timer_edit => 'Chỉnh sửa bộ hẹn giờ';

  @override
  String get timer_delete => 'Xóa bộ hẹn giờ';

  @override
  String get timer_delete_title => 'Xóa bộ hẹn giờ?';

  @override
  String get timer_delete_message =>
      'Bộ hẹn giờ này sẽ bị xóa khỏi danh sách hẹn giờ của bạn.';

  @override
  String get timer_duration_must_be_greater_than_error =>
      'Thời lượng phải lớn hơn 0';

  @override
  String get splash_tagline_1 => 'Phật tử chúng ta cùng nhau tu tập';

  @override
  String get splash_tagline_2 => 'Phật tử chúng ta tu tập mỗi ngày';

  @override
  String get timer_create_custom => 'Tạo bộ hẹn giờ tùy chỉnh';

  @override
  String get timer_starting => 'Đang bắt đầu...';

  @override
  String get timer_duration_hours => 'giờ';

  @override
  String get timer_duration_sec => 'giây';

  @override
  String get reader_display_title => 'Display';

  @override
  String get text_size => 'Text size';

  @override
  String get reader_more_settings => 'More settings';

  @override
  String get reader_spacing => 'Line spacing';

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
  String get reader_text_smaller => 'Smaller text';

  @override
  String get reader_text_larger => 'Larger text';

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

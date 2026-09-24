/// Reader feature barrel export
///
/// Exports all reader-related classes organized by layer.
/// Usage:
/// ```dart
/// import 'package:flutter_pecha/features/reader/reader.dart';
/// ```
library;

// Domain - Entities
export 'domain/entities/text_content.dart';

// Domain - Repositories
export 'domain/repositories/reader_repository.dart';

// Domain - Use Cases
export 'domain/usecases/load_initial_text_usecase.dart';
export 'domain/usecases/load_next_page_usecase.dart';
export 'domain/usecases/navigate_to_section_usecase.dart';

// Domain - Services
export 'domain/services/navigation_service.dart';
export 'domain/services/section_merger_service.dart';
export 'domain/services/section_flattener_service.dart';

// Domain - Transliteration
export 'domain/transliteration/script_converter.dart';
export 'domain/transliteration/ewts/ewts_converter.dart';
export 'domain/transliteration/pali_script_converter.dart';
export 'domain/transliteration/tibetan_phonetics.dart';
export 'domain/transliteration/tibetan_script_converter.dart';
export 'domain/transliteration/transliteration_service.dart';

// Initial language layout per context (event / chant / plan / library)
export 'domain/layout/reader_layout_context.dart';
export 'domain/layout/reader_initial_layout.dart';

// Data - Models
export 'data/models/reader_state.dart';
export 'data/models/flattened_item.dart';
export 'data/models/flattened_content.dart';
export 'data/models/navigation_context.dart';
export 'data/models/highlight_config.dart';

// Presentation - Providers
export 'presentation/providers/reader_notifier.dart';
export 'presentation/providers/reader_providers.dart';
export 'presentation/providers/reader_script_preference_provider.dart';

// Presentation - Screens
export 'presentation/screens/reader_screen.dart';

// Presentation - Widgets
export 'presentation/widgets/reader_app_bar/reader_app_bar.dart';
export 'presentation/widgets/reader_app_bar/reader_font_size_button.dart';
export 'presentation/widgets/reader_app_bar/reader_languages_button.dart';
export 'presentation/widgets/reader_app_bar/reader_search_button.dart';
export 'presentation/widgets/reader_content/reader_content_part.dart';
export 'presentation/widgets/reader_content/segment_item.dart';
export 'presentation/widgets/reader_content/section_header.dart';
export 'presentation/widgets/reader_actions/action_button.dart';
export 'presentation/widgets/reader_actions/segement_action_bar.dart';
export 'presentation/widgets/reader_controls/reader_chapter_header.dart';
export 'presentation/widgets/reader_commentary/reader_commentary_panel.dart';
export 'presentation/widgets/reader_commentary/reader_commentary_split_view.dart';
export 'presentation/widgets/reader_search/reader_search_delegate.dart';
export 'presentation/widgets/reader_gestures/swipe_navigation_wrapper.dart';

// Constants
export 'constants/reader_constants.dart';

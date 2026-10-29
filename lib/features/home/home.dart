/// Home feature barrel export
///
/// Usage:
/// ```dart
/// import 'package:flutter_pecha/features/home/home.dart';
/// ```
library;

// Domain - Entities
export 'domain/entities/prayer.dart';
export 'domain/entities/featured_content.dart';
export 'domain/entities/daily_quote.dart';

// Domain - Repositories
export 'domain/repositories/home_repository.dart';

// Domain - Use Cases
export 'domain/usecases/home_usecases.dart';

// Data - Models
export 'data/models/prayer_data.dart';
export 'data/models/plan_item.dart';

// Data - Week Plan Content (Localized)
export 'data/week_plan.dart';
export 'data/week_plan_en.dart';
export 'data/week_plan_bo.dart';
export 'data/week_plan_zh.dart';

// Data - Datasources
export 'data/datasource/tags_remote_datasource.dart';
export 'data/datasource/featured_day_remote_datasource.dart';

// Presentation - Providers
export 'presentation/providers/tags_provider.dart';
export 'presentation/providers/plans_by_tag_provider.dart';

// Data - Repositories
export 'data/repositories/tags_repository.dart';
export 'data/repositories/featured_day_repository.dart';

// Presentation - Screens
export 'presentation/screens/main_navigation_screen.dart';
export 'presentation/screens/home_screen.dart';
export 'presentation/screens/plan_list_screen.dart';

// Presentation - Widgets
export 'presentation/widgets/tag_card.dart';
export 'presentation/widgets/action_of_the_day_card.dart';
export 'presentation/widgets/stat_button.dart';
export 'presentation/widgets/calendar_banner_card.dart';
export 'presentation/widgets/tag_search_overlay.dart';
export 'presentation/widgets/youtube_video_player.dart';

// Presentation - Constants
export 'presentation/home_screen_constants.dart';

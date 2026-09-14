/// Plans feature barrel export
///
/// Usage:
/// ```dart
/// import 'package:flutter_pecha/features/plans/plans.dart';
/// ```
library;

// Domain - Entities
export 'domain/entities/plan.dart';
export 'domain/entities/week_plan.dart';
export 'domain/entities/plan_day.dart';
export 'domain/entities/plan_task.dart';
export 'domain/entities/plan_progress.dart';
export 'domain/entities/author.dart';

// Domain - Repositories
export 'domain/repositories/plans_repository.dart';

// Domain - Use Cases
export 'domain/usecases/plans_usecases.dart';

// Domain - Exceptions
export 'exceptions/plan_exceptions.dart';

// Domain - Constants
export 'constants/plan_constants.dart';

// Data - Models
export 'data/models/plans_model.dart' hide DifficultyLevel;
export 'data/models/plan_tasks_model.dart';
export 'data/models/plan_subtasks_model.dart';
export 'data/models/plan_group_accumulation_ref.dart';
export 'data/models/plan_progress_model.dart';
export 'data/models/plan_days_model.dart';
export 'data/models/plan_video_model.dart';
export 'data/models/author/author_model.dart';
export 'data/models/user/user_plans_model.dart';
export 'data/models/user/user_tasks_dto.dart';
export 'data/models/user/user_subtasks_dto.dart';

// Response Models
export 'data/models/response/all_plan_response_model.dart';
export 'data/models/response/featured_day_response.dart';
export 'data/models/response/user_plan_list_response_model.dart';
export 'data/models/response/user_plan_day_detail_response.dart';
export 'data/models/response/user_plan_day_completion_status_response.dart';

// Data - Datasources
export 'data/datasource/plans_local_datasource.dart';
export 'data/datasource/plans_remote_datasource.dart';
export 'data/datasource/user_plans_remote_datasource.dart';
export 'data/datasource/plan_days_remote_datasource.dart';
export 'data/datasource/author_remote_datasource.dart';

// Data - Providers (moved to presentation)

// Data - Repositories
export 'data/repositories/plans_repository_impl.dart';
export 'data/repositories/user_plans_repository.dart';
export 'data/repositories/plan_days_repository.dart';
export 'data/repositories/author_repository.dart';

// Data - Utils
export 'data/utils/plan_utils.dart';
export 'data/utils/plan_date_format.dart';

// Presentation - Providers
export 'presentation/providers/plan_search_provider.dart';
export 'presentation/providers/my_plans_paginated_provider.dart';
export 'presentation/providers/find_plans_paginated_provider.dart';
export 'presentation/providers/plans_providers.dart';
export 'presentation/providers/user_plans_provider.dart';
export 'presentation/providers/plan_days_providers.dart';
export 'presentation/providers/author_providers.dart';

// Presentation - Screens
export 'presentation/screens/plans_screen.dart';
export 'presentation/plan_info.dart';
export 'presentation/author_detail_screen.dart';

// Presentation - Widgets
export 'presentation/widgets/plan_card.dart';
export 'presentation/widgets/user_plan_card.dart';
export 'presentation/widgets/day_carousel.dart';
export 'presentation/widgets/my_plan_tab.dart';
export 'presentation/widgets/find_plan_tab.dart';
export 'presentation/widgets/plan_preview/plan_preview_details.dart';
export 'presentation/widgets/plan_preview/preview_activity_list.dart';
export 'presentation/widgets/plan_track/plan_details.dart';
export 'presentation/widgets/plan_track/activity_list.dart';
export 'presentation/widgets/plan_track/missed_days_badge.dart';
export 'presentation/widgets/plan_track/on_track_badge.dart';
export 'presentation/widgets/plan_track/plan_date_range_label.dart';
export 'presentation/widgets/plan_track/enrolled_plan_status_indicator.dart';
export 'presentation/widgets/plan_cover_image.dart';

// Presentation - Search
export 'presentation/search/plan_search_delegate.dart';

// Services
export 'services/plan_share_service.dart';

/// Onboarding feature barrel export
///
/// Usage:
/// ```dart
/// import 'package:flutter_pecha/features/onboarding/onboarding.dart';
/// ```
library;

// Domain - Entities
export 'domain/entities/onboarding_preferences.dart';

// Domain - Repositories
export 'domain/repositories/onboarding_repository.dart';

// Domain - Use Cases
export 'domain/usecases/onboarding_usecases.dart';

// Data - Models
export 'data/models/onboarding_preferences.dart' hide OnboardingPreferences;
export 'data/models/onboarding_status_model.dart';

// Application
export 'application/onboarding_notifier.dart';
export 'application/onboarding_state.dart';
export 'application/onboarding_provider.dart';

// Data - Repositories
export 'data/repositories/onboarding_repository.dart';

// Data - Datasources
export 'data/datasource/onboarding_local_datasource.dart';
export 'data/datasource/onboarding_remote_datasource.dart';

// Presentation - Providers
export 'presentation/providers/onboarding_datasource_providers.dart';

// Presentation - Screens
export 'presentation/screens/onboarding_wrapper.dart';
export 'presentation/screens/onboarding_screen_1.dart';
export 'presentation/screens/onboarding_screen_language.dart';
export 'presentation/screens/onboarding_screen_5.dart';

// Presentation - Widgets
export 'presentation/widgets/onboarding_checkbox_option.dart';
export 'presentation/widgets/onboarding_choice_scaffold.dart';
export 'presentation/widgets/onboarding_option_card.dart';
export 'presentation/widgets/onboarding_progress_bar.dart';
export 'presentation/widgets/onboarding_radio_option.dart';

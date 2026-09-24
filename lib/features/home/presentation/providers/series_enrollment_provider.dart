import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/home/domain/usecases/enroll_in_series_usecase.dart';
import 'package:flutter_pecha/features/home/presentation/providers/use_case_providers.dart';
import 'package:flutter_pecha/features/home/presentation/utils/series_analytics.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for a single in-flight or completed series enrollment request.
sealed class SeriesEnrollmentState {
  const SeriesEnrollmentState();
}

class SeriesEnrollmentIdle extends SeriesEnrollmentState {
  const SeriesEnrollmentIdle();
}

class SeriesEnrollmentLoading extends SeriesEnrollmentState {
  const SeriesEnrollmentLoading();
}

class SeriesEnrollmentSuccess extends SeriesEnrollmentState {
  const SeriesEnrollmentSuccess();
}

class SeriesEnrollmentFailure extends SeriesEnrollmentState {
  final Failure failure;
  const SeriesEnrollmentFailure(this.failure);
}

class SeriesEnrollmentNotifier extends StateNotifier<SeriesEnrollmentState> {
  final EnrollInSeriesUseCase _useCase;
  final Ref _ref;
  final String _seriesId;

  SeriesEnrollmentNotifier({
    required EnrollInSeriesUseCase useCase,
    required Ref ref,
    required String seriesId,
  }) : _useCase = useCase,
       _ref = ref,
       _seriesId = seriesId,
       super(const SeriesEnrollmentIdle());

  Future<bool> enroll({String? groupId}) async {
    if (state is SeriesEnrollmentLoading) return false;
    state = const SeriesEnrollmentLoading();
    final analytics = _ref.read(seriesAnalyticsProvider);

    final result = await _useCase(
      EnrollInSeriesParams(seriesId: _seriesId, groupId: groupId),
    );

    return result.fold(
      (failure) {
        if (mounted) state = SeriesEnrollmentFailure(failure);
        return false;
      },
      (_) {
        if (mounted) {
          state = const SeriesEnrollmentSuccess();
        }
        analytics.seriesEnrolled(seriesId: _seriesId, groupId: groupId);
        // Refresh user-scoped data so downstream UIs (enrolled plans/routine)
        // reflect the newly created enrollments. Backend auto-enrolls the
        // user in all plans within the series.
        _ref.read(myPlansPaginatedProvider.notifier).refresh();
        _ref.invalidate(userRoutineProvider);
        _ref.invalidate(userSeriesEnrollmentsProvider);
        return true;
      },
    );
  }

  void reset() {
    state = const SeriesEnrollmentIdle();
  }
}

final seriesEnrollmentProvider = StateNotifierProvider.autoDispose
    .family<SeriesEnrollmentNotifier, SeriesEnrollmentState, String>((
      ref,
      seriesId,
    ) {
      return SeriesEnrollmentNotifier(
        useCase: ref.watch(enrollInSeriesUseCaseProvider),
        ref: ref,
        seriesId: seriesId,
      );
    });

/// The set of series IDs the authenticated user is enrolled in.
///
/// Returns an empty set for guests / unauthenticated users without hitting
/// the network. Returns an empty set on failure too — the Enroll button stays
/// usable and the user can retry by tapping it; a future call refreshes the
/// cache. Invalidated after a successful series enrollment.
final userSeriesEnrollmentsProvider = StreamProvider<Set<String>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth.isLoading || !auth.isLoggedIn || auth.isGuest) {
    return Stream.value(const <String>{});
  }
  final repository = ref.watch(seriesDomainRepositoryProvider);
  return repository.watchUserSeriesEnrollments().map(
    (result) => result.fold((_) => const <String>{}, (ids) => ids),
  );
});

import 'package:flutter_pecha/features/onboarding/data/models/tradition_models.dart';

class TraditionSelectionState {
  const TraditionSelectionState({
    this.paths = const [],
    this.selectedCodes = const {},
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final List<TraditionPath> paths;
  final Set<String> selectedCodes;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  bool get hasSelection => selectedCodes.isNotEmpty;

  /// "Show me everything" reads as checked once every path is checked,
  /// whether it was tapped or each path was checked one by one.
  bool get isAllSelected =>
      paths.isNotEmpty && paths.every((p) => selectedCodes.contains(p.code));

  TraditionSelectionState copyWith({
    List<TraditionPath>? paths,
    Set<String>? selectedCodes,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return TraditionSelectionState(
      paths: paths ?? this.paths,
      selectedCodes: selectedCodes ?? this.selectedCodes,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

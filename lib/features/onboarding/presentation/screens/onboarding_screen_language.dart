import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/content_language_analytics.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_provider.dart';
import 'package:flutter_pecha/features/onboarding/presentation/utils/onboarding_analytics.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_choice_scaffold.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_radio_option.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Onboarding screen: choose the app UI language.
class OnboardingScreenLanguage extends ConsumerStatefulWidget {
  const OnboardingScreenLanguage({super.key, required this.onNext});

  final VoidCallback onNext;

  static const _languages = [
    _LanguageOption(
      locale: Locale(AppConfig.englishLanguageCode),
      label: 'English',
    ),
    _LanguageOption(locale: Locale(AppConfig.chineseLanguageCode), label: '中文'),
    _LanguageOption(
      locale: Locale(AppConfig.tibetanLanguageCode),
      label: 'བོད་ཡིག',
    ),
    _LanguageOption(
      locale: Locale(AppConfig.hindiLanguageCode),
      label: 'हिन्दी',
    ),
    _LanguageOption(
      locale: Locale(AppConfig.mongolianLanguageCode),
      label: 'Монгол',
    ),
    _LanguageOption(
      locale: Locale(AppConfig.nepaliLanguageCode),
      label: 'नेपाली',
    ),
  ];

  @override
  ConsumerState<OnboardingScreenLanguage> createState() =>
      _OnboardingScreenLanguageState();
}

class _OnboardingScreenLanguageState
    extends ConsumerState<OnboardingScreenLanguage> {
  late String _selectedLanguageCode;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguageCode = ref.read(localeProvider).languageCode;
  }

  Future<void> _handleContinue() async {
    // A second tap while the language saves would advance the flow twice.
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(onboardingProvider.notifier)
          .setPreferredLanguage(_selectedLanguageCode);
      // Applies the choice to both the UI locale and the backend content
      // language so they stay in sync from the first screen.
      await selectAppLanguage(
        ref,
        _selectedLanguageCode,
        source: ContentLanguageSource.onboarding,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
    if (!mounted) return;
    ref
        .read(onboardingAnalyticsProvider)
        .languageSelected(uiLanguage: _selectedLanguageCode);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingChoiceScaffold(
      stepIndex: 0,
      title: context.l10n.onboarding_first_question,
      subtitle: context.l10n.onboarding_language_subtitle,
      isSaving: _isSubmitting,
      onContinue: _handleContinue,
      options: Column(
        children: [
          for (final language in OnboardingScreenLanguage._languages)
            OnboardingRadioOption(
              id: language.locale.languageCode,
              label: language.label,
              selectedId: _selectedLanguageCode,
              onSelect: (id) => setState(() => _selectedLanguageCode = id),
            ),
        ],
      ),
    );
  }
}

class _LanguageOption {
  const _LanguageOption({required this.locale, required this.label});

  final Locale locale;
  final String label;
}

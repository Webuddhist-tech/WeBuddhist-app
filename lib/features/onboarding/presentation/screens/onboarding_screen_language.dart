import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/config/locale/content_language_analytics.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_provider.dart';
import 'package:flutter_pecha/features/onboarding/presentation/utils/onboarding_analytics.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_question_title.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_radio_option.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// First onboarding screen: choose the app UI language.
/// Shown in English before a locale is committed so the title stays readable.
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

  @override
  void initState() {
    super.initState();
    _selectedLanguageCode = ref.read(localeProvider).languageCode;
  }

  Future<void> _handleContinue() async {
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
    if (!mounted) return;
    ref
        .read(onboardingAnalyticsProvider)
        .languageSelected(uiLanguage: _selectedLanguageCode);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              OnboardingQuestionTitle(title: l10n.onboarding_first_question),
              const SizedBox(height: 30),
              _buildLanguageOptions(),
              const Spacer(),
              _buildContinueButton(l10n.onboarding_continue),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            OnboardingScreenLanguage._languages.map((language) {
              return OnboardingRadioOption(
                id: language.locale.languageCode,
                label: language.label,
                selectedId: _selectedLanguageCode,
                onSelect: (id) {
                  setState(() => _selectedLanguageCode = id);
                },
              );
            }).toList(),
      ),
    );
  }

  Widget _buildContinueButton(String label) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _handleContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandblue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _LanguageOption {
  const _LanguageOption({required this.locale, required this.label});

  final Locale locale;
  final String label;
}

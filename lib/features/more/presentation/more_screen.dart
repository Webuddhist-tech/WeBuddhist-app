import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/content_language_analytics.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/di/core_providers.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/localization/app_language.dart';
import 'package:flutter_pecha/core/localization/languages_providers.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/theme_notifier.dart';
import 'package:flutter_pecha/shared/widgets/app_toggle_switch.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/notifications/presentation/notification_settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  /// Native-script label for a content-language [code]. Prefers the loaded
  /// backend list, then the bundled fallback, then the raw code.
  String _nativeNameForCode(String code, List<AppLanguage> languages) {
    for (final lang in languages) {
      if (lang.code == code) return lang.nativeName;
    }
    for (final lang in AppLanguage.bundledFallback) {
      if (lang.code == code) return lang.nativeName;
    }
    return code;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentLanguageCode = ref.watch(contentLanguageProvider);
    final localizations = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
        title: Text(
          localizations.nav_settings,
          strutStyle: context.tibetanStrutStyle(
            Theme.of(context).textTheme.headlineSmall?.fontSize ?? 24,
          ),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            // Personalisation Section
            _buildSectionHeader(
              context,
              localizations.settings_section_personalisation,
            ),
            const SizedBox(height: 12),
            if (authState.isLoggedIn && !authState.isGuest)
              _buildSettingsRow(
                context,
                icon: AppAssets.profile,
                title: localizations.settings_edit_profile,
                onTap: () => context.push(AppRoutes.profile),
              ),
            _buildLanguageRow(context, ref, contentLanguageCode),
            _buildNotificationRow(context, localizations),
            _buildThemeToggleRow(context, ref, isDarkMode, localizations),
            const SizedBox(height: 24),

            // More Section
            _buildSectionHeader(context, localizations.settings_section_more),
            const SizedBox(height: 12),
            _buildSettingsRow(
              context,
              icon: AppAssets.about,
              title: localizations.about_title,
              onTap: () => context.push(AppRoutes.about),
            ),
            _buildSettingsRow(
              context,
              icon: AppAssets.legal,
              title: localizations.legal_title,
              onTap: () => context.push(AppRoutes.legal),
            ),
            _buildSettingsRow(
              context,
              icon: AppAssets.feedback,
              title: localizations.settings_feedback_row,
              trailingIcon: AppAssets.arrowSquareOut,
              onTap: () async {
                final url =
                    "https://app-webuddhist.ideas.userback.io/p/5omSMHB8A9VMUrD6vLrE";
                await launchUrl(Uri.parse(url));
              },
            ),
            const SizedBox(height: 24),

            // Account Section
            _buildSectionHeader(
              context,
              localizations.settings_section_account,
            ),
            const SizedBox(height: 12),
            if (!authState.isLoggedIn || authState.isGuest) ...[
              _buildSettingsRow(
                context,
                icon: AppAssets.signIn,
                title: localizations.sign_in,
                onTap:
                    () =>
                        LoginDrawer.show(context, ref, useRootNavigator: true),
              ),
            ] else ...[
              _buildSettingsRow(
                context,
                icon: AppAssets.signOut,
                title: localizations.logout,
                onTap: () => _showLogoutDialog(context, ref),
                isDestructive: true,
              ),
            ],
            const SizedBox(height: 32),
            _buildVersionFooter(context, ref),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggleRow(
    BuildContext context,
    WidgetRef ref,
    bool isDarkMode,
    AppLocalizations localizations,
  ) {
    return _buildSettingsRow(
      context,
      icon: isDarkMode ? AppAssets.themeMoon : AppAssets.theme,
      title: localizations.settings_theme,
      onTap: () {
        ref
            .read(themeModeProvider.notifier)
            .setTheme(isDarkMode ? ThemeMode.light : ThemeMode.dark);
      },
      trailing: _ThemeToggle(
        isDarkMode: isDarkMode,
        onChanged: (value) {
          ref
              .read(themeModeProvider.notifier)
              .setTheme(value ? ThemeMode.dark : ThemeMode.light);
        },
      ),
    );
  }

  Widget _buildNotificationRow(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return _buildSettingsRow(
      context,
      icon: AppAssets.notification,
      title: localizations.settings_notification_row,
      onTap: () => context.push(NotificationSettingsScreen.routeName),
    );
  }

  Widget _buildLanguageRow(
    BuildContext context,
    WidgetRef ref,
    String contentLanguageCode,
  ) {
    // Show the loaded backend list's label when available; the bundled
    // fallback covers offline/first-launch.
    final languages = ref.watch(resolvedContentLanguagesProvider);
    final currentLanguageName = _nativeNameForCode(
      contentLanguageCode,
      languages,
    );
    return InkWell(
      onTap: () => _showLanguageBottomSheet(context, ref, contentLanguageCode),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              AppAssets.language,
              size: 24,
              color: Theme.of(context).iconTheme.color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                currentLanguageName,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Icon(AppAssets.caretRight, size: 24, color: AppColors.grey600),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    IconData? trailingIcon,
    bool isDestructive = false,
  }) {
    final color =
        isDestructive ? Colors.red.shade600 : Theme.of(context).iconTheme.color;
    final textColor = isDestructive ? Colors.red.shade600 : null;

    final rowContent = Row(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: textColor),
          ),
        ),
        if (trailing == null)
          Icon(
            trailingIcon ?? AppAssets.caretRight,
            size: 24,
            color: isDestructive ? Colors.red.shade600 : AppColors.grey600,
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: rowContent,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildVersionFooter(BuildContext context, WidgetRef ref) {
    final versionLabel = ref.watch(appVersionLabelProvider);
    if (versionLabel.isEmpty) return const SizedBox.shrink();
    return Center(
      child: Text(
        versionLabel,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.grey600),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.grey600,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  void _showLanguageBottomSheet(
    BuildContext context,
    WidgetRef ref,
    String currentContentCode,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    l10n.language,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Consumer so the picker rebuilds when the backend list resolves.
                Flexible(
                  child: Consumer(
                    builder: (context, sheetRef, _) {
                      final languages = sheetRef.watch(
                        resolvedContentLanguagesProvider,
                      );
                      return ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: languages.length,
                        separatorBuilder:
                            (_, __) => Divider(
                              height: 1,
                              color: theme.dividerColor.withValues(alpha: 0.4),
                            ),
                        itemBuilder: (_, index) {
                          final language = languages[index];
                          final isSelected =
                              language.code == currentContentCode;
                          return _buildLanguageOption(
                            sheetContext,
                            sheetRef,
                            language,
                            isSelected,
                            theme,
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref,
    AppLanguage language,
    bool isSelected,
    ThemeData theme,
  ) {
    final activeColor = theme.colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await selectAppLanguage(
            ref,
            language.code,
            source: ContentLanguageSource.settings,
          );
          if (context.mounted) context.pop();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  language.nativeName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color:
                        isSelected
                            ? activeColor
                            : theme.textTheme.titleMedium?.color,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(
                width: 18,
                child:
                    isSelected
                        ? Icon(AppAssets.check, size: 18, color: activeColor)
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Text(
              localizations.logout,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            content: Text(
              localizations.logout_confirmation,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.cancel),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await ref.read(authProvider.notifier).logout();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                ),
                child: Text(localizations.logout),
              ),
            ],
          ),
    );
  }
}

/// Custom theme toggle widget with sun and moon icons
class _ThemeToggle extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  const _ThemeToggle({required this.isDarkMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AppToggleSwitch(
      value: isDarkMode,
      onChanged: onChanged,
      thumbOnColor: AppColors.surfaceWhite,
      thumbOffColor: AppColors.surfaceWhite,
    );
  }
}

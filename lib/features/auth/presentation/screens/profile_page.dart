import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import '../../../../core/config/router/route_config.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userState = ref.watch(userProvider);
    final l10n = context.l10n;

    if (authState.isLoading || userState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!authState.isLoggedIn) {
      return Scaffold(body: Center(child: Text(l10n.notLoggedIn)));
    }

    // Guest user
    if (authState.isGuest) {
      return _buildGuestProfile(context, ref);
    }

    // Authenticated user
    if (userState.user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profileTitle)),
        body: Center(child: Text(l10n.profileError)),
      );
    }

    final user = userState.user!;
    final pictureUrl = user.avatarUrl;
    final fullName = user.fullName;
    final email = user.email ?? '';
    final bio = user.aboutMe ?? l10n.profile_default_bio;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Center(
                  child: Hero(
                    tag: 'profile-avatar',
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage:
                          pictureUrl != null && pictureUrl.isNotEmpty
                              ? pictureUrl.cachedNetworkImageProvider
                              : null,
                      child:
                          (pictureUrl == null || pictureUrl.isEmpty)
                              ? Text(
                                _initialsFromName(fullName),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              )
                              : null,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  // Personal details stay hidden in Clarity recordings.
                  child: ClarityMask(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isNotEmpty
                              ? fullName
                              : (user.username ?? l10n.anonymous),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 4),
                        if (bio.isNotEmpty)
                          Text(
                            bio,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        if (bio.isNotEmpty) const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _initialsFromName(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r"\s+"));
    final first =
        parts.isNotEmpty && parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  Widget _buildGuestProfile(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Guest Avatar
            Center(
              child: Hero(
                tag: 'profile-avatar',
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor:
                      isDarkMode ? Colors.grey[800] : Colors.grey[400],
                  child: Icon(
                    Icons.person_outline,
                    size: 48,
                    color: isDarkMode ? Colors.grey[300] : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Guest Title
            Text(
              l10n.profile_guest_title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Guest Description
            Text(
              l10n.profile_guest_subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            // Sign In Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.go(RouteConfig.login);
                },
                icon: const Icon(Icons.login),
                label: Text(l10n.signIn),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Benefits Card
            Card(
              elevation: isDarkMode ? 2 : 1,
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profile_guest_benefits_header,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitItem(
                      context,
                      Icons.bookmark,
                      l10n.profile_guest_benefit_save_progress,
                      isDarkMode,
                    ),
                    _buildBenefitItem(
                      context,
                      Icons.favorite,
                      l10n.profile_guest_benefit_personalized,
                      isDarkMode,
                    ),
                    _buildBenefitItem(
                      context,
                      Icons.notifications,
                      l10n.profile_guest_benefit_notifications,
                      isDarkMode,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    IconData icon,
    String text,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color:
                isDarkMode
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}

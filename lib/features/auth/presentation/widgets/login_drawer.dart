import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'social_login_button.dart';

/// Modern bottom sheet drawer for guest user login
class LoginDrawer extends ConsumerStatefulWidget {
  const LoginDrawer({super.key});

  /// Show the login drawer as a bottom sheet
  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    bool useRootNavigator = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: useRootNavigator,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const LoginDrawer(),
    );
  }

  @override
  ConsumerState<LoginDrawer> createState() => _LoginDrawerState();
}

class _LoginDrawerState extends ConsumerState<LoginDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isIOS = Platform.isIOS;
    final l10n = context.l10n;

    // Auto-close when user successfully authenticates
    if (!authState.isGuest && authState.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // App logo
                Image.asset(AppAssets.weBuddhistLogo, height: 80, width: 80),
                const SizedBox(height: 24),
                // Title
                Text(
                  l10n.auth_drawer_title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                // Subtitle
                Text(
                  l10n.auth_drawer_subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Sign-in buttons
                if (authState.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  )
                else
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: SocialLoginButton(
                          connection: 'google',
                          icon: Icons.g_mobiledata,
                          iconColor: Colors.black,
                          label: l10n.continueWithGoogle,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          iconWidget: Image.asset(
                            'assets/images/google-icon.png',
                            width: 20,
                            height: 20,
                          ),
                          isBorder: true,
                        ),
                      ),
                      if (isIOS) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: SocialLoginButton(
                            connection: 'apple',
                            icon: Icons.apple,
                            iconColor: Colors.white,
                            label: l10n.continueWithApple,
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            iconWidget: const Icon(
                              Icons.apple,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: SocialLoginButton(
                          connection: 'sms',
                          icon: Icons.phone_android,
                          iconColor: Colors.black,
                          label: l10n.continueWithPhone,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          iconWidget: const Icon(
                            Icons.phone_android,
                            color: Colors.black,
                            size: 20,
                          ),
                          isBorder: true,
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget for authentication buttons (social logins, guest login)
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/utils/auth_analytics.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/social_login_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthButtons extends ConsumerWidget {
  const AuthButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = Platform.isIOS;
    final l10n = context.l10n;
    final authNotifier = ref.read(authProvider.notifier);

    return Column(
      children: [
        if (isIOS) ...[
          SocialLoginButton(
            connection: 'apple',
            icon: Icons.apple,
            iconColor: Colors.white,
            label: l10n.continueWithApple,
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            iconWidget: const Icon(Icons.apple, color: Colors.white, size: 24),
            source: AuthSource.loginPage,
          ),
          const SizedBox(height: 12),
        ],
        SocialLoginButton(
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
          source: AuthSource.loginPage,
        ),
        const SizedBox(height: 12),
        SocialLoginButton(
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
          source: AuthSource.loginPage,
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed:
              () => authNotifier.continueAsGuest(source: AuthSource.loginPage),
          child: Text(
            l10n.exploreAsGuest,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

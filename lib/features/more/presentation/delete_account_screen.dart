import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/destructive_confirmation_dialog.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  static const String routeName = '/delete-account';

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool _isDeleting = false;

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    String? deleteError;

    final result = await showDestructiveConfirmationDialog(
      context,
      title: l10n.delete_account_title,
      message: l10n.delete_account_confirm_message,
      confirmLabel: l10n.delete_account_button,
      barrierDismissible: false,
      onConfirmed: () async {
        if (_isDeleting) return false;
        setState(() => _isDeleting = true);

        final errorMessage =
            await ref.read(authProvider.notifier).deleteAccount();

        if (!mounted) return false;

        setState(() => _isDeleting = false);

        if (errorMessage != null) {
          deleteError = errorMessage;
          return false;
        }
        // On success the auth state listener in GoRouter navigates to login
        // automatically because isLoggedIn becomes false.
        return true;
      },
    );

    if (result == false && deleteError != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(deleteError!),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.delete_account_title,
          style: GoogleFonts.inter(
            textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: -0.3,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.delete_account_description,
              strutStyle: context.tibetanStrutStyle(15),
              style: TextStyle(
                fontSize: 15,
                height: 1.55,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isDeleting ? null : _confirmDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  side: BorderSide(color: isDark ? Colors.white : Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child:
                    _isDeleting
                        ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        )
                        : Text(
                          AppLocalizations.of(context)!.delete_account_button,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red.shade600,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

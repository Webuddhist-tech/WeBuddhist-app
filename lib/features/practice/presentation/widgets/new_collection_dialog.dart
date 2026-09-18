import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/create_edit_collection_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/collection_name_dialog.dart';

/// Asks for a name, then opens the create screen with it.
Future<void> showNewCollectionDialog(BuildContext context) async {
  final name = await showCollectionNameDialog(
    context,
    title: context.l10n.my_recitation_collection_new_title,
    actionLabel: context.l10n.my_recitation_collection_next,
  );
  if (name == null || !context.mounted) return;

  // Root navigator, as the dialog's own pop-then-push used, so the screen
  // covers the tab shell.
  await Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      builder: (_) => CreateEditCollectionScreen(initialName: name),
    ),
  );
}

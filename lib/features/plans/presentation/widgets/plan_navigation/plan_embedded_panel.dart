import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/presentation/screens/plan_text_screen.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_embedded_host.dart';
import 'package:flutter_pecha/features/reader/presentation/screens/reader_screen.dart';

/// Renders the subtask screen for [controller]'s current item.
class PlanEmbeddedPanel extends StatelessWidget {
  final PlanEmbeddedController controller;

  const PlanEmbeddedPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          layoutBuilder:
              (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, if (current != null) current],
              ),
          child: _buildScreen(),
        );
      },
    );
  }

  Widget _buildScreen() {
    final item = controller.item;
    final navigationContext = controller.navigationContext;
    if (item == null || navigationContext == null) {
      return const SizedBox.shrink();
    }
    final key = ValueKey(controller.generation);
    if (item.isSourceReference) {
      return ReaderScreen(
        key: key,
        textId: item.textId,
        segmentId: navigationContext.targetSegmentId,
        navigationContext: navigationContext,
      );
    }
    return PlanTextScreen(key: key, navigationContext: navigationContext);
  }
}

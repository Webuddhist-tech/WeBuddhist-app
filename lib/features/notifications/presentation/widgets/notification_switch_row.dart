import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/shared/widgets/app_toggle_switch.dart';

/// One labelled switch in a notification settings list.
///
/// - [enabled] false greys the row out and ignores taps. The caller decides
///   which value to show meanwhile; the settings screens show off.
/// - [loading] replaces the switch with a spinner until the stored value is
///   known, so a default never shows and then snaps.
class NotificationSwitchRow extends StatelessWidget {
  const NotificationSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.loading = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final bool loading;
  final EdgeInsetsGeometry padding;

  static const double _fontSize = 16;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final interactive = enabled && !loading;

    return MergeSemantics(
      child: Semantics(
        toggled: value,
        enabled: interactive,
        child: InkWell(
          onTap: interactive ? () => onChanged(!value) : null,
          child: Padding(
            padding: padding,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    strutStyle: context.tibetanStrutStyle(_fontSize),
                    style: TextStyle(
                      fontSize: _fontSize,
                      color:
                          enabled
                              ? onSurface
                              : onSurface.withValues(alpha: 0.38),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (loading)
                  const SizedBox(
                    width: 64,
                    height: 32,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  ExcludeSemantics(
                    child: IgnorePointer(
                      ignoring: !enabled,
                      child: Opacity(
                        opacity: enabled ? 1 : 0.4,
                        child: AppToggleSwitch(
                          value: value,
                          onChanged: onChanged,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What to show for a plan task's Live mark. Following the recitation line
/// is separate and does not use this.
enum PlanLivePill { hidden, syncToggle, staticLabel }

/// [taskIsLive] is the current plan task's `settings.is_live`.
/// Null means this screen was not opened from a plan task, so an event
/// recitation keeps its existing pill.
PlanLivePill planLivePill({
  required bool? taskIsLive,
  required bool followsRecitation,
}) {
  if (taskIsLive == false) return PlanLivePill.hidden;
  if (taskIsLive == true) {
    return followsRecitation
        ? PlanLivePill.syncToggle
        : PlanLivePill.staticLabel;
  }
  return followsRecitation ? PlanLivePill.syncToggle : PlanLivePill.hidden;
}

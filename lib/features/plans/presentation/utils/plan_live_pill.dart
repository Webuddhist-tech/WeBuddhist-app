/// What the reader shows for Live: nothing, the follow control, or a static
/// label.
enum PlanLivePill { hidden, syncToggle, staticLabel }

/// [taskIsLive] is the current plan task's `settings.is_live`.
/// Null means this screen was not opened from a plan task, so an event
/// recitation keeps its existing pill.
///
/// The follow control stays whenever the reader follows an event. Scrolling
/// away pauses following, and that control is what resumes it. A task that
/// is not live only hides the static label.
PlanLivePill planLivePill({
  required bool? taskIsLive,
  required bool followsRecitation,
}) {
  if (taskIsLive == false) {
    return followsRecitation ? PlanLivePill.syncToggle : PlanLivePill.hidden;
  }
  if (taskIsLive == true) {
    return followsRecitation
        ? PlanLivePill.syncToggle
        : PlanLivePill.staticLabel;
  }
  return followsRecitation ? PlanLivePill.syncToggle : PlanLivePill.hidden;
}

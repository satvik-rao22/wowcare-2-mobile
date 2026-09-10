/// Canonical staffing-ratio kinds, aligned with the forecast API's
/// `blockStatus` field.
///
/// This is a domain concept — whether a classroom block is under-staffed, in
/// ratio, over-staffed, or unmonitored is a compliance fact about the schedule,
/// not a view-model detail. It used to be declared in
/// `presentation/features/scheduling/model/scheduling_models.dart`, which put
/// the rules that produce it out of the domain layer's reach.
///
/// `scheduling_models.dart` re-exports this, so existing presentation imports
/// keep resolving.
enum SchedulingBlockStatusKind {
  inRatio,
  underRatio,
  extraStaff,
  empty,
}

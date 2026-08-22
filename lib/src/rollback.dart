/// Rollback decision logic for `apply`.
///
/// The rollback rule is the all-or-nothing seam:
///
/// - When `shared_core` was modified this run, every zone that has been applied
///   (and the failing zone) is restored. Apps resolve `shared_core` via
///   `path:`, so leaving `shared_core` bumped while an app fails leaves the
///   apps broken against a version they were never verified against.
/// - When `shared_core` was unmodified, only the failing zone rolls back; the
///   other zones are independent and stay applied.
///
/// This module only decides *which* zones to restore. The actual file
/// restoration lives in the apply command so it can re-resolve each zone with
/// `pub get`.
library;

/// Which zones a failure must restore.
enum RollbackScope {
  /// Only the failing zone.
  failingZoneOnly,

  /// shared_core + every already-applied zone + the failing zone.
  allApplied,
}

/// Decide the rollback scope given whether shared_core was modified this run.
///
/// Pure function: easy to unit-test the rule without touching the filesystem.
RollbackScope decideRollbackScope({required bool sharedCoreModified}) {
  return sharedCoreModified ? RollbackScope.allApplied : RollbackScope.failingZoneOnly;
}
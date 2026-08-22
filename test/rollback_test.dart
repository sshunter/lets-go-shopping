import 'package:test/test.dart';
import 'package:lgs_tooling/lgs_tooling.dart';

void main() {
  group('decideRollbackScope', () {
    test('all-or-nothing when shared_core was modified this run', () {
      expect(
        decideRollbackScope(sharedCoreModified: true),
        RollbackScope.allApplied,
      );
    });

    test('failing zone only when shared_core was unmodified', () {
      expect(
        decideRollbackScope(sharedCoreModified: false),
        RollbackScope.failingZoneOnly,
      );
    });
  });
}
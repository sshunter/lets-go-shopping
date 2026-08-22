import 'package:test/test.dart';
import 'package:lgs_tooling/lgs_tooling.dart';

void main() {
  group('parseOutdatedJson', () {
    test('parses direct + transitive rows with all version buckets', () {
      const json = '''
{
  "packages": [
    {
      "package": "home_widget",
      "kind": "direct",
      "isDiscontinued": false,
      "isCurrentRetracted": false,
      "isCurrentAffectedByAdvisory": false,
      "current": {"version": "0.9.2"},
      "upgradable": {"version": "0.9.3"},
      "resolvable": {"version": "0.9.3"},
      "latest": {"version": "0.9.3"}
    },
    {
      "package": "jni",
      "kind": "transitive",
      "isDiscontinued": false,
      "isCurrentRetracted": false,
      "isCurrentAffectedByAdvisory": false,
      "current": {"version": "1.0.0"},
      "upgradable": {"version": "1.0.3"},
      "resolvable": {"version": "1.0.3"},
      "latest": {"version": "1.0.3"}
    }
  ]
}
''';
      final rows = parseOutdatedJson(json);
      expect(rows, hasLength(2));

      final hw = rows[0];
      expect(hw.name, 'home_widget');
      expect(hw.kind, 'direct');
      expect(hw.isDirect, isTrue);
      expect(hw.current, '0.9.2');
      expect(hw.upgradable, '0.9.3');
      expect(hw.resolvable, '0.9.3');
      expect(hw.latest, '0.9.3');
      expect(hw.isDiscontinued, isFalse);

      final jni = rows[1];
      expect(jni.kind, 'transitive');
      expect(jni.isDirect, isFalse);
      expect(jni.current, '1.0.0');
    });

    test('surfaces safety flags', () {
      const json = '''
{
  "packages": [
    {
      "package": "evil_pkg",
      "kind": "direct",
      "isDiscontinued": true,
      "isCurrentRetracted": true,
      "isCurrentAffectedByAdvisory": true,
      "current": {"version": "1.0.0"},
      "upgradable": {"version": "1.0.0"},
      "resolvable": {"version": "1.0.0"},
      "latest": {"version": "2.0.0"}
    }
  ]
}
''';
      final rows = parseOutdatedJson(json);
      expect(rows, hasLength(1));
      expect(rows.first.isDiscontinued, isTrue);
      expect(rows.first.isCurrentRetracted, isTrue);
      expect(rows.first.isCurrentAffectedByAdvisory, isTrue);
    });

    test('tolerates a leading resolving banner before the JSON blob', () {
      const output = '''
Resolving dependencies... 
Got dependencies!
{
  "packages": [
    {"package": "bloc", "kind": "direct", "current": {"version": "9.2.1"}, "upgradable": {"version": "9.2.1"}, "resolvable": {"version": "9.2.1"}, "latest": {"version": "9.2.2"}}
  ]
}
''';
      final rows = parseOutdatedJson(output);
      expect(rows, hasLength(1));
      expect(rows.first.name, 'bloc');
      expect(rows.first.latest, '9.2.2');
    });

    test('returns empty for non-JSON or empty input', () {
      expect(parseOutdatedJson(''), isEmpty);
      expect(parseOutdatedJson('not json at all'), isEmpty);
      expect(parseOutdatedJson('null'), isEmpty);
    });

    test('handles null version buckets gracefully', () {
      const json = '''
{"packages": [{"package": "x", "kind": "direct"}]}
''';
      final rows = parseOutdatedJson(json);
      expect(rows, hasLength(1));
      expect(rows.first.current, isNull);
      expect(rows.first.latest, isNull);
    });

    test('treats both `direct` and `dev` kinds as directly-declared', () {
      const json = '''
{"packages": [
  {"package": "bloc", "kind": "direct"},
  {"package": "test", "kind": "dev"},
  {"package": "jni", "kind": "transitive"}
]}
''';
      final rows = parseOutdatedJson(json);
      expect(rows.firstWhere((r) => r.name == 'bloc').isDirect, isTrue);
      expect(rows.firstWhere((r) => r.name == 'test').isDirect, isTrue);
      expect(rows.firstWhere((r) => r.name == 'jni').isDirect, isFalse);
    });
  });
}
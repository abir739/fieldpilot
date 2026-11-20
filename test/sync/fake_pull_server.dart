import 'package:fieldpilot/sync/pull_api.dart';

/// In-memory server tables for pull tests. Every [write] gets a newer
/// server time ('synced_at'), like the real trigger does.
class FakePullServer implements PullApi {
  final _tables = <String, Map<String, Map<String, dynamic>>>{};
  var _clock = DateTime.utc(2026, 1, 1);

  /// Every "since" we were asked with, per table.
  final asked = <String, List<DateTime?>>{};

  /// Next call throws (network down).
  bool offline = false;

  void write(String table, Map<String, dynamic> row) {
    _clock = _clock.add(const Duration(minutes: 1));
    (_tables[table] ??= {})[row['id'] as String] = {
      ...row,
      'synced_at': _clock.toIso8601String(),
    };
  }

  @override
  Future<List<Map<String, dynamic>>> changedSince(
    String table,
    DateTime? since,
  ) async {
    (asked[table] ??= []).add(since);
    if (offline) throw Exception('network down');
    final rows = (_tables[table] ?? {}).values.where((r) =>
        since == null || DateTime.parse(r['synced_at'] as String).isAfter(since));
    return rows.toList()
      ..sort((a, b) => (a['synced_at'] as String).compareTo(b['synced_at'] as String));
  }
}

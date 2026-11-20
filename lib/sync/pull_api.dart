import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The one read the pull engine needs from the server.
/// An interface, so tests can use a fake server instead of Supabase.
abstract class PullApi {
  /// My rows of [table] written on the server after [since] (all when null),
  /// oldest first. Each row has a server-set 'synced_at'.
  /// Throws when the network or server fails.
  Future<List<Map<String, dynamic>>> changedSince(String table, DateTime? since);
}

class SupabasePullApi implements PullApi {
  SupabasePullApi(this._client);

  final SupabaseClient _client;

  static const _pageSize = 500;
  static const _giveUpAfter = Duration(seconds: 15);

  @override
  Future<List<Map<String, dynamic>>> changedSince(
    String table,
    DateTime? since,
  ) async {
    if (_client.auth.currentSession == null) throw StateError('not signed in');

    // Read page by page, each page starting after the last row of the one before.
    final rows = <Map<String, dynamic>>[];
    var after = since;
    while (true) {
      var query = _client.from(table).select(); // RLS: only my rows
      if (after != null) {
        query = query.gt('synced_at', after.toUtc().toIso8601String());
      }
      final page = await query
          .order('synced_at', ascending: true)
          .limit(_pageSize)
          .timeout(_giveUpAfter);
      rows.addAll(page);
      if (page.length < _pageSize) return rows;
      after = DateTime.parse(page.last['synced_at'] as String);
    }
  }
}

final pullApiProvider = Provider<PullApi>(
  (ref) => SupabasePullApi(Supabase.instance.client),
);

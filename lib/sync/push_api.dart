import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The one call the push engine needs from the server.
/// An interface, so tests can use a fake server instead of Supabase.
abstract class PushApi {
  /// Calls the server's push_op. Returns its JSON answer, e.g.
  /// {"status":"applied","version":2} or {"status":"conflict","server":{...}}.
  /// Throws [OpRejected] when the server refuses this op for good,
  /// anything else when the network or server fails (try again later).
  Future<Map<String, dynamic>> pushOp(
    String opId,
    String entity,
    Map<String, dynamic> payload,
  );
}

/// The server said "no" to this op and will say "no" every time
/// (bad data, not allowed...). Retrying cannot help.
class OpRejected implements Exception {
  const OpRejected(this.reason);

  final String reason;

  @override
  String toString() => 'OpRejected: $reason';
}

/// Postgres error codes that mean "this op is wrong", not "try later":
/// 22 = bad data, 23 = broken rule (e.g. missing parent row),
/// 42 = not allowed / bad query, P0 = raised by push_op itself.
bool isPermanentError(String? code) =>
    code != null && RegExp(r'^(22|23|42|P0)').hasMatch(code);

class SupabasePushApi implements PushApi {
  SupabasePushApi(this._client);

  final SupabaseClient _client;

  static const _giveUpAfter = Duration(seconds: 15);

  @override
  Future<Map<String, dynamic>> pushOp(
    String opId,
    String entity,
    Map<String, dynamic> payload,
  ) async {
    // Signed out: the call would run as "anon" and be refused, which would
    // look permanent. It is not: wait until the user signs in again.
    if (_client.auth.currentSession == null) {
      throw StateError('not signed in');
    }
    try {
      final answer = await _client.rpc('push_op', params: {
        'op_id': opId,
        'entity': entity,
        'payload': payload,
      }).timeout(_giveUpAfter); // offline, don't spin forever: fail and retry later
      return Map<String, dynamic>.from(answer as Map);
    } on PostgrestException catch (e) {
      if (isPermanentError(e.code)) throw OpRejected('${e.code} ${e.message}');
      rethrow;
    }
  }
}

final pushApiProvider = Provider<PushApi>(
  (ref) => SupabasePushApi(Supabase.instance.client),
);

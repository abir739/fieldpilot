import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The one call the push engine needs from the server.
/// An interface, so tests can use a fake server instead of Supabase.
abstract class PushApi {
  /// Calls the server's push_op. Returns its JSON answer, e.g.
  /// {"status":"applied","version":2} or {"status":"conflict","server":{...}}.
  /// Throws when the network or server fails.
  Future<Map<String, dynamic>> pushOp(
    String opId,
    String entity,
    Map<String, dynamic> payload,
  );
}

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
    final answer = await _client.rpc('push_op', params: {
      'op_id': opId,
      'entity': entity,
      'payload': payload,
    }).timeout(_giveUpAfter); // offline, don't spin forever: fail and retry later
    return Map<String, dynamic>.from(answer as Map);
  }
}

final pushApiProvider = Provider<PushApi>(
  (ref) => SupabasePushApi(Supabase.instance.client),
);

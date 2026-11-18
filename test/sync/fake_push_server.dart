import 'package:fieldpilot/sync/push_api.dart';

/// In-memory copy of the server's push_op rules, for tests:
/// replays the first answer for a known op id, checks inspection versions
/// (server wins), and can pretend the network failed.
class FakePushServer implements PushApi {
  final inspections = <String, Map<String, dynamic>>{};
  final answers = <String, Map<String, dynamic>>{};
  final _answersByOp = <String, Map<String, dynamic>>{};
  final calls = <String>[]; // entity of every call, in order

  /// Next call throws before reaching the server (no change applied).
  bool failBeforeServer = false;

  /// Next call is applied on the server, then throws (answer lost on the way back).
  bool failAfterServer = false;

  /// Runs during a call, before answering (e.g. the user edits meanwhile).
  Future<void> Function()? whileSending;

  @override
  Future<Map<String, dynamic>> pushOp(
    String opId,
    String entity,
    Map<String, dynamic> payload,
  ) async {
    calls.add(entity);
    if (failBeforeServer) {
      failBeforeServer = false;
      throw Exception('network down');
    }
    await whileSending?.call();

    final answer = _answersByOp[opId] ?? _apply(entity, payload);
    _answersByOp[opId] = answer;

    if (failAfterServer) {
      failAfterServer = false;
      throw Exception('answer lost');
    }
    return answer;
  }

  Map<String, dynamic> _apply(String entity, Map<String, dynamic> payload) {
    if (entity == 'answer') {
      answers[payload['id'] as String] = payload;
      return {'status': 'applied'};
    }
    final id = payload['id'] as String;
    final server = inspections[id];
    if (server != null && (server['version'] as int) > (payload['version'] as int)) {
      return {'status': 'conflict', 'server': Map<String, dynamic>.from(server)};
    }
    final version = (server?['version'] as int? ?? 0) + 1;
    inspections[id] = {...payload, 'version': version};
    return {'status': 'applied', 'version': version};
  }
}

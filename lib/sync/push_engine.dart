import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/local/database_provider.dart';
import 'outbox_writer.dart';
import 'push_api.dart';

/// What one push run did.
class PushResult {
  const PushResult({this.sent = 0, this.conflicts = 0, this.failed = false});

  final int sent; // entries the server answered (applied or conflict)
  final int conflicts; // of those, how many the server won
  final bool failed; // stopped early because the network/server failed
}

/// Sends outbox entries to the server, one by one, in order.
///
/// Rules:
/// - An entry is deleted ONLY after the server answered. If the app is killed
///   before that, the entry stays and is sent again (the server replays its
///   first answer, so nothing is applied twice).
/// - On a network error we stop, count the attempt, and keep the order.
/// - On a conflict the server wins: its copy replaces ours.
class PushEngine {
  PushEngine(this._db, this._api);

  final AppDatabase _db;
  final PushApi _api;

  Future<PushResult> pushAll() async {
    var sent = 0;
    var conflicts = 0;

    for (final op in await outboxInOrder(_db)) {
      final payload = jsonDecode(op.payload) as Map<String, dynamic>;
      if (op.entity == 'inspection') {
        // Base the change on the version we have NOW (an earlier push may have
        // raised it after this entry was written).
        payload['version'] = await _localVersion(op.entityId);
      }

      final Map<String, dynamic> answer;
      try {
        answer = await _api.pushOp(op.opId, op.entity, payload);
      } catch (_) {
        await _countAttempt(op.opId);
        return PushResult(sent: sent, conflicts: conflicts, failed: true);
      }

      final conflict = answer['status'] == 'conflict';
      await _handleAnswer(op, answer);
      sent++;
      if (conflict) conflicts++;
    }
    return PushResult(sent: sent, conflicts: conflicts);
  }

  Future<void> _handleAnswer(OutboxData op, Map<String, dynamic> answer) {
    return _db.transaction(() async {
      // Delete by op id: if the user edited the row meanwhile, the entry got a
      // new op id and is kept, so the newer change is sent next time.
      await (_db.delete(_db.outbox)..where((o) => o.opId.equals(op.opId))).go();

      if (op.entity != 'inspection') return;
      if (answer['status'] == 'applied' && answer['version'] != null) {
        await _setVersion(op.entityId, answer['version'] as int);
      } else if (answer['status'] == 'conflict') {
        await _takeServerCopy(answer['server'] as Map<String, dynamic>);
      }
    });
  }

  /// Server wins: overwrite our row and drop our unsent edits of it.
  Future<void> _takeServerCopy(Map<String, dynamic> server) async {
    final id = server['id'] as String;
    await (_db.update(_db.inspections)..where((i) => i.id.equals(id))).write(
      InspectionsCompanion(
        assetCode: Value(server['asset_code'] as String),
        status: Value(server['status'] as String),
        note: Value(server['note'] as String),
        version: Value(server['version'] as int),
        updatedAt: Value(DateTime.parse(server['updated_at'] as String)),
      ),
    );
    await (_db.delete(_db.outbox)
          ..where((o) => o.entity.equals('inspection') & o.entityId.equals(id)))
        .go();
  }

  Future<int> _localVersion(String inspectionId) async {
    final row = await (_db.select(_db.inspections)
          ..where((i) => i.id.equals(inspectionId)))
        .getSingleOrNull();
    return row?.version ?? 0;
  }

  Future<void> _setVersion(String inspectionId, int version) =>
      (_db.update(_db.inspections)..where((i) => i.id.equals(inspectionId)))
          .write(InspectionsCompanion(version: Value(version)));

  Future<void> _countAttempt(String opId) => _db.customUpdate(
        'UPDATE outbox SET attempts = attempts + 1 WHERE op_id = ?',
        variables: [Variable.withString(opId)],
        updates: {_db.outbox},
      );
}

final pushEngineProvider = Provider<PushEngine>(
  (ref) => PushEngine(ref.watch(databaseProvider), ref.watch(pushApiProvider)),
);

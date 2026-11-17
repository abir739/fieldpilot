import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../data/local/app_database.dart';

/// Adds a "send this to the server" entry to the outbox.
///
/// Call it inside the same `db.transaction` as the data change, so both are
/// saved together or not at all.
///
/// If this row already has an unsent entry, that entry is replaced by a new
/// one with a NEW op id. (Reusing the old op id would be unsafe: the server
/// may already have applied it and would then skip the newer change.)
/// The entry is updated in place, so it keeps its place in line (its rowid):
/// an inspection is always sent before the answers that belong to it.
/// Send order = [outboxInOrder].
Future<void> enqueueOp(
  AppDatabase db, {
  required String entity,
  required String entityId,
  required Map<String, Object?> payload,
}) async {
  final opId = const Uuid().v4();
  final json = jsonEncode(payload);

  final replaced = await (db.update(db.outbox)
        ..where((o) => o.entity.equals(entity) & o.entityId.equals(entityId)))
      .write(OutboxCompanion(
    opId: Value(opId),
    payload: Value(json),
    attempts: const Value(0),
  ));
  if (replaced > 0) return;

  await db.into(db.outbox).insert(OutboxCompanion.insert(
        opId: opId,
        entity: entity,
        entityId: Value(entityId),
        payload: json,
        createdAt: DateTime.now(),
      ));
}

/// Outbox entries in the order they must be sent (oldest place in line first).
Future<List<OutboxData>> outboxInOrder(AppDatabase db) =>
    (db.select(db.outbox)..orderBy([(o) => OrderingTerm.asc(o.rowId)])).get();

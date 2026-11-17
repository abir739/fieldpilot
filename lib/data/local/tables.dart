import 'package:drift/drift.dart';

/// One inspection of one asset (found by scanning its QR code).
class Inspections extends Table {
  TextColumn get id => text()();
  TextColumn get assetCode => text()();
  TextColumn get status => text()(); // 'draft' or 'done'
  IntColumn get version => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))(); // added in schema 2

  @override
  Set<Column> get primaryKey => {id};
}

/// The answer to one checklist question.
class Answers extends Table {
  TextColumn get id => text()();
  TextColumn get inspectionId => text().references(Inspections, #id)();
  TextColumn get question => text()();
  BoolColumn get ok => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A photo saved on the phone, and whether it has been uploaded yet.
class Photos extends Table {
  TextColumn get id => text()();
  TextColumn get inspectionId => text().references(Inspections, #id)();
  TextColumn get localPath => text()();
  BoolColumn get uploaded => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A problem found during the inspection (suggested by the AI, approved by the user).
class Findings extends Table {
  TextColumn get id => text()();
  TextColumn get inspectionId => text().references(Inspections, #id)();
  TextColumn get description => text()();
  BoolColumn get approved => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Changes waiting to be sent to the server (the "to-do list" for sync).
class Outbox extends Table {
  TextColumn get opId => text()();
  TextColumn get entity => text()(); // e.g. 'inspection'
  TextColumn get entityId => text().withDefault(const Constant(''))(); // schema 3
  TextColumn get payload => text()(); // JSON
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {opId};
}

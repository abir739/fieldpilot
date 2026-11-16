import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'local/app_database.dart';
import 'local/database_provider.dart';

/// Keeps inspection photos on the phone: the file in the app folder,
/// and a row in the `photos` table that remembers where it is.
class PhotoRepository {
  PhotoRepository(this._db, this._photosDir);

  final AppDatabase _db;
  final Future<Directory> Function() _photosDir; // tests pass a temp folder

  /// Copies [picture] into the app's photo folder and records it.
  /// The camera's own file may be deleted by the system, so we keep a copy.
  Future<Photo> addPhoto(String inspectionId, File picture) async {
    final id = const Uuid().v4();
    final dir = await _photosDir();
    await dir.create(recursive: true);
    final saved = await picture.copy(p.join(dir.path, '$id.jpg'));

    return _db.into(_db.photos).insertReturning(PhotosCompanion.insert(
          id: id,
          inspectionId: inspectionId,
          localPath: saved.path,
          // uploaded defaults to false: the sync step will upload it later
        ));
  }

  /// Photos of one inspection. Emits again on every change.
  Stream<List<Photo>> watchPhotos(String inspectionId) {
    final query = _db.select(_db.photos)
      ..where((ph) => ph.inspectionId.equals(inspectionId));
    return query.watch();
  }
}

Future<Directory> _appPhotosDir() async {
  final docs = await getApplicationDocumentsDirectory();
  return Directory(p.join(docs.path, 'photos'));
}

final photoRepositoryProvider = Provider<PhotoRepository>(
  (ref) => PhotoRepository(ref.watch(databaseProvider), _appPhotosDir),
);

final photosProvider = StreamProvider.family<List<Photo>, String>(
  (ref, inspectionId) =>
      ref.watch(photoRepositoryProvider).watchPhotos(inspectionId),
);

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fieldpilot/data/inspection_repository.dart';
import 'package:fieldpilot/data/local/app_database.dart';
import 'package:fieldpilot/data/photo_repository.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late PhotoRepository photos;
  late String inspectionId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('fieldpilot_test');
    photos = PhotoRepository(db, () async => Directory('${tempDir.path}/photos'));
    inspectionId = (await InspectionRepository(db).openOrStartDraft('PUMP-42')).id;
  });
  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test('copies the picture into the photo folder and saves a row', () async {
    final picture = File('${tempDir.path}/camera.jpg')..writeAsBytesSync([1, 2, 3]);

    final photo = await photos.addPhoto(inspectionId, picture);

    expect(File(photo.localPath).readAsBytesSync(), [1, 2, 3]);
    expect(photo.localPath, contains('photos'));
    expect(photo.uploaded, isFalse); // waits for sync
  });

  test('keeps the copy even if the camera file is deleted', () async {
    final picture = File('${tempDir.path}/camera.jpg')..writeAsBytesSync([1]);

    final photo = await photos.addPhoto(inspectionId, picture);
    picture.deleteSync();

    expect(File(photo.localPath).existsSync(), isTrue);
  });

  test('watchPhotos returns only this inspection photos', () async {
    final picture = File('${tempDir.path}/camera.jpg')..writeAsBytesSync([1]);
    await photos.addPhoto(inspectionId, picture);

    expect(await photos.watchPhotos(inspectionId).first, hasLength(1));
    expect(await photos.watchPhotos('other').first, isEmpty);
  });
}

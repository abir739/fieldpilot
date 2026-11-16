import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/photo_repository.dart';

/// "Photos" part of the inspection: a Take photo button and small previews.
class PhotoSection extends ConsumerWidget {
  const PhotoSection({super.key, required this.inspectionId});

  final String inspectionId;

  Future<void> _takePhoto(WidgetRef ref) async {
    final picture = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1600, // smaller files = faster upload later
      imageQuality: 80,
    );
    if (picture == null) return; // user closed the camera
    await ref
        .read(photoRepositoryProvider)
        .addPhoto(inspectionId, File(picture.path));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(photosProvider(inspectionId)).value ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Photos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final photo in photos)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(photo.localPath),
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    cacheWidth: 192, // decode small: saves memory
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _takePhoto(ref),
            icon: const Icon(Icons.photo_camera),
            label: const Text('Take photo'),
          ),
        ],
      ),
    );
  }
}

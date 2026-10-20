import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event_draft.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Picks the event cover from the device photos.
class GroupEventCoverPicker {
  GroupEventCoverPicker._();

  /// Null when the reader cancelled.
  static Future<GroupEventCover?> pick() async {
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
    } catch (_) {
      picked = null;
    }
    if (picked == null) return null;
    return GroupEventCoverFile(await _prepare(picked));
  }

  /// Bakes the EXIF orientation into the pixels, like the post composer.
  static Future<File> _prepare(XFile picked) async {
    var file = File(picked.path);
    try {
      final tmpDir = await getTemporaryDirectory();
      final destPath =
          '${tmpDir.path}/group_event_cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        destPath,
        quality: 85,
        autoCorrectionAngle: true,
      );
      if (result != null) file = File(result.path);
    } catch (_) {}
    return file;
  }
}

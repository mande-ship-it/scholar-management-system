import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
// Conditional import for web/mobile
import 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart'
    if (dart.library.io) 'file_download_mobile.dart';

class FileDownloadService {
  static Future<void> downloadFile({
    required List<int> bytes,
    required String fileName,
  }) async {
    await downloadFileImplementation(bytes, fileName);
  }
}

import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file_plus/open_file_plus.dart';

Future<void> downloadFileImplementation(List<int> bytes, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes);
  await OpenFile.open(file.path);
}

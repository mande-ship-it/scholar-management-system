import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

Future<void> downloadFileImplementation(List<int> bytes, String fileName) async {
  final base64 = base64Encode(bytes);
  final anchor = html.AnchorElement(
      href: 'data:application/octet-stream;base64,$base64')
    ..setAttribute('download', fileName)
    ..click();
}

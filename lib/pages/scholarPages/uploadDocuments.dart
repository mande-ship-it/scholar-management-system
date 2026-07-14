import 'package:flutter/material.dart';
import '../../scholars/uploadDocuments.dart';

class UploadDocumentsPage extends StatelessWidget {
  const UploadDocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: UploadDocumentsComponent(),
      ),
    );
  }
}

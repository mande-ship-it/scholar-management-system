import 'package:flutter/material.dart';

class UploadDocumentsComponent extends StatelessWidget {
  const UploadDocumentsComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.upload_file),
        title: const Text("Upload Scholar Documents"),
        trailing: ElevatedButton(
          onPressed: () {},
          child: const Text("Choose Files"),
        ),
      ),
    );
  }
}
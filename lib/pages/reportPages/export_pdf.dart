import 'package:flutter/material.dart';
import '../../reports/export_pdf.dart';

class ExportPDFPage extends StatelessWidget {
  const ExportPDFPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ExportPDFComponent(),
      ),
    );
  }
}

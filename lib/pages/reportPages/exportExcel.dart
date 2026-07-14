import 'package:flutter/material.dart';
import '../../reports/exportExcel.dart';

class ExportExcelPage extends StatelessWidget {
  const ExportExcelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ExportExcelComponent(),
      ),
    );
  }
}

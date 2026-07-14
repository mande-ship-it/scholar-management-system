import 'package:flutter/material.dart';

class ExportExcelComponent extends StatelessWidget {
  const ExportExcelComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Export Excel",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text("Select parameters to generate and export ${"Export Excel".replaceAll('Export ', '')} report:"),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Choose Module",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "scholars", child: Text("Scholars")),
                DropdownMenuItem(value: "finance", child: Text("Finance")),
                DropdownMenuItem(value: "attendance", child: Text("Attendance")),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Export Excel download started")),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text("Export & Download"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(150, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

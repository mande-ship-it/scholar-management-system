import 'package:flutter/material.dart';

class DeleteSponsorComponent extends StatelessWidget {
  const DeleteSponsorComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
                const SizedBox(width: 10),
                Text(
                  "Delete Sponsor",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Warning: Deleting records is permanent and cannot be undone. Please ensure you have selected the correct entry.",
              style: TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Select Record to Remove",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "1", child: Text("Sample Entry A")),
                DropdownMenuItem(value: "2", child: Text("Sample Entry B")),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Record deleted successfully")),
                );
              },
              icon: const Icon(Icons.delete_forever),
              label: const Text("Delete Forever"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(150, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

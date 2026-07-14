import 'package:flutter/material.dart';

class UserProfileComponent extends StatelessWidget {
  const UserProfileComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.domain, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sample Users Profile",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text("ID: SMS-2026-0987 • Created: July 2026", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Details Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.location_on),
                    title: Text("Address / Location"),
                    subtitle: Text("Lilongwe, Malawi"),
                  ),
                  ListTile(
                    leading: Icon(Icons.contact_phone),
                    title: Text("Contact Info"),
                    subtitle: Text("+265 999 123 456"),
                  ),
                  ListTile(
                    leading: Icon(Icons.assignment_ind),
                    title: Text("Status"),
                    subtitle: Text("Verified"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

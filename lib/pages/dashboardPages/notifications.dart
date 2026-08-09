import 'package:flutter/material.dart';
import '../../dashBoard/notifications.dart';
import '../../academics/academics_utils.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navigator.canPop(context) 
        ? AppBar(
            title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.white,
            foregroundColor: kBrandBrown,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          )
        : null,
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: NotificationsComponent(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../dashBoard/notifications.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: NotificationsComponent(),
      ),
    );
  }
}

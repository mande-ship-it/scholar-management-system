import 'package:flutter/material.dart';
import '../../dashBoard/notifications.dart';
import '../../academics/academics_utils.dart';

class NotificationsPage extends StatelessWidget {
  final VoidCallback? onBack;
  const NotificationsPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return NotificationsComponent(onBack: onBack);
  }
}

import 'package:flutter/material.dart';
import 'statistics.dart';
import 'recentActivities.dart';
import 'notifications.dart';

class DashboardComponent extends StatelessWidget {
  const DashboardComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Dashboard",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 25),

          StatisticsComponent(),

          SizedBox(height: 30),

          RecentActivitiesComponent(),

          SizedBox(height: 30),

          NotificationsComponent(),
        ],
      ),
    );
  }
}
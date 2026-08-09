import 'package:flutter/material.dart';
import '../../dashBoard/recent_activities.dart';
import '../../academics/academics_utils.dart';

class RecentActivitiesPage extends StatelessWidget {
  const RecentActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navigator.canPop(context) 
        ? AppBar(
            title: const Text("Recent Activities", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        child: RecentActivitiesComponent(),
      ),
    );
  }
}

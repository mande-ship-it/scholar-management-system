import 'package:flutter/material.dart';
import '../../schools/view_schools.dart';

class ViewSchoolsPage extends StatelessWidget {
  const ViewSchoolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ViewSchoolsComponent(),
      ),
    );
  }
}

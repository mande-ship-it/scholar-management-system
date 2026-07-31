import 'package:flutter/material.dart';
import '../../scholars/view_scholars.dart';

class ViewScholarsPage extends StatelessWidget {
  final VoidCallback? onRegisterScholar;
  final Function(String)? onViewProfile;
  final VoidCallback? onViewGraduates;
  const ViewScholarsPage({super.key, this.onRegisterScholar, this.onViewProfile, this.onViewGraduates});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ViewScholarsComponent(
        onRegisterScholar: onRegisterScholar,
        onViewProfile: onViewProfile,
        onViewGraduates: onViewGraduates,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../scholars/view_scholars.dart';

class ViewScholarsPage extends StatelessWidget {
  final VoidCallback? onRegisterScholar;
  final Function(String)? onViewProfile;
  final VoidCallback? onViewGraduates;
  final String? forcedSchoolType;
  final bool hideRegistration;
  final bool hideUniversity;
  const ViewScholarsPage({
    super.key,
    this.onRegisterScholar,
    this.onViewProfile,
    this.onViewGraduates,
    this.forcedSchoolType,
    this.hideRegistration = false,
    this.hideUniversity = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ViewScholarsComponent(
        onRegisterScholar: onRegisterScholar,
        onViewProfile: onViewProfile,
        onViewGraduates: onViewGraduates,
        forcedSchoolType: forcedSchoolType,
        hideUniversity: hideUniversity,
      ),
    );
  }
}

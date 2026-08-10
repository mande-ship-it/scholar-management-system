import 'package:flutter/material.dart';
import '../../scholars/view_scholars.dart';
import '../../academics/academics_utils.dart';

class ViewScholarsPage extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onRegisterScholar;
  final Function(String)? onViewProfile;
  final VoidCallback? onViewGraduates;
  final String? forcedSchoolType;
  final bool hideRegistration;
  final bool hideUniversity;
  final int initialTabIndex;
  const ViewScholarsPage({
    super.key,
    this.onBack,
    this.onRegisterScholar,
    this.onViewProfile,
    this.onViewGraduates,
    this.forcedSchoolType,
    this.hideRegistration = false,
    this.hideUniversity = false,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ViewScholarsComponent(
      onBack: onBack,
      onRegisterScholar: onRegisterScholar,
      onViewProfile: onViewProfile,
      onViewGraduates: onViewGraduates,
      forcedSchoolType: forcedSchoolType,
      hideUniversity: hideUniversity,
      hideRegistration: hideRegistration,
      initialTabIndex: initialTabIndex,
    );
  }
}

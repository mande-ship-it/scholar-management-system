import 'package:flutter/material.dart';
import '../../schools/view_schools.dart';
import '../../academics/academics_utils.dart';

class ViewSchoolsPage extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onRegisterSchool;
  final String? forcedLevel;
  final bool hideRegistration;
  final bool showBackButton;
  const ViewSchoolsPage({
    super.key, 
    this.onBack, 
    this.onRegisterSchool, 
    this.forcedLevel, 
    this.hideRegistration = false,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return ViewSchoolsComponent(
      onBack: onBack,
      onRegisterSchool: onRegisterSchool,
      forcedLevel: forcedLevel,
      hideRegistration: hideRegistration,
      showBackButton: showBackButton,
    );
  }
}

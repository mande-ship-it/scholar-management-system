import 'package:flutter/material.dart';
import '../../scholars/university_graduates.dart';
import '../../academics/academics_utils.dart';

class UniversityGraduatesPage extends StatelessWidget {
  final VoidCallback? onBack;
  final bool showBackButton;
  const UniversityGraduatesPage({super.key, this.onBack, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return UniversityGraduatesComponent(onBack: onBack, showBackButton: showBackButton);
  }
}

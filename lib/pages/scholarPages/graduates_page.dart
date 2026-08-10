import 'package:flutter/material.dart';
import '../../scholars/university_graduates.dart';
import '../../academics/academics_utils.dart';

class UniversityGraduatesPage extends StatelessWidget {
  final VoidCallback? onBack;
  const UniversityGraduatesPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return UniversityGraduatesComponent(onBack: onBack);
  }
}

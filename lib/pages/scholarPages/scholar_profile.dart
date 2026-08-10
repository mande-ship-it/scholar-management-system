import 'package:flutter/material.dart';
import '../../scholars/scholar_profile.dart';
import '../../academics/academics_utils.dart';

class ScholarProfilePage extends StatelessWidget {
  final VoidCallback? onBack;
  const ScholarProfilePage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return ScholarProfileComponent(onBack: onBack);
  }
}

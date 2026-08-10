import 'package:flutter/material.dart';
import '../../schools/school_profile.dart';

class SchoolProfilePage extends StatelessWidget {
  final VoidCallback? onBack;
  const SchoolProfilePage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return SchoolProfileComponent(onBack: onBack);
  }
}

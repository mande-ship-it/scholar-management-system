import 'package:flutter/material.dart';
import '../../scholars/view_scholars.dart';
import '../../academics/academics_utils.dart';

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
      backgroundColor: Colors.white,
      appBar: Navigator.canPop(context) 
        ? AppBar(
            title: const Text("Scholars Registry", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.white,
            foregroundColor: kBrandBrown,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          )
        : null,
      body: ViewScholarsComponent(
        onRegisterScholar: onRegisterScholar,
        onViewProfile: onViewProfile,
        onViewGraduates: onViewGraduates,
        forcedSchoolType: forcedSchoolType,
        hideUniversity: hideUniversity,
        hideRegistration: hideRegistration, // Pass through the parameter
      ),
    );
  }
}

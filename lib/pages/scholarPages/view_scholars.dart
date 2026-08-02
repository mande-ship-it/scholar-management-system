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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onRegisterScholar ?? () => Navigator.pushNamed(context, '/registerScholar'),
        backgroundColor: const Color(0xFF9AB334), // kBrandOlive
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text("REGISTER SCHOLAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../schools/school_profile.dart';

class SchoolProfilePage extends StatelessWidget {
  const SchoolProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: canPop
          ? AppBar(
              title: const Text("School Profile"),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 0 : 20),
        child: const SchoolProfileComponent(),
      ),
    );
  }
}

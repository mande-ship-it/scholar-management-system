import 'package:flutter/material.dart';
import '../../schools/schoolProfile.dart';

class SchoolProfilePage extends StatelessWidget {
  const SchoolProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: canPop
          ? AppBar(
              title: const Text("School Profile"),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: SchoolProfileComponent(),
      ),
    );
  }
}

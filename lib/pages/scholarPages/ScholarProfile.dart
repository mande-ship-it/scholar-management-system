import 'package:flutter/material.dart';
import '../../scholars/ScholarProfile.dart';

class ScholarProfilePage extends StatelessWidget {
  const ScholarProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: canPop
          ? AppBar(
              title: const Text("Scholar Profile"),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: ScholarProfileComponent(),
      ),
    );
  }
}

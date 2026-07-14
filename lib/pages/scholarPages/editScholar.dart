import 'package:flutter/material.dart';
import '../../scholars/editScholar.dart';

class EditScholarPage extends StatelessWidget {
  const EditScholarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: canPop
          ? AppBar(
              title: const Text("Edit Scholar"),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: EditScholarComponent(),
      ),
    );
  }
}

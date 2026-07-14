import 'package:flutter/material.dart';
import '../../schools/editSchool.dart';

class EditSchoolPage extends StatelessWidget {
  const EditSchoolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: canPop
          ? AppBar(
              title: const Text("Edit School"),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: EditSchoolComponent(),
      ),
    );
  }
}

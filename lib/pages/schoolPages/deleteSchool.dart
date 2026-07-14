import 'package:flutter/material.dart';
import '../../schools/deleteSchool.dart';

class DeleteSchoolPage extends StatelessWidget {
  const DeleteSchoolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: canPop
          ? AppBar(
              title: const Text("Delete School"),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: DeleteSchoolComponent(),
      ),
    );
  }
}

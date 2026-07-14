import 'package:flutter/material.dart';
import '../../scholars/deleteScholar.dart';

class DeleteScholarPage extends StatelessWidget {
  const DeleteScholarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: canPop
          ? AppBar(
              title: const Text("Delete Scholar"),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: DeleteScholarComponent(),
      ),
    );
  }
}

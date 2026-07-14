import 'package:flutter/material.dart';
import '../../academics/addSubjects.dart';

class AddSubjectsPage extends StatelessWidget {
  const AddSubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: AddSubjectsComponent(),
      ),
    );
  }
}

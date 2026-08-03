import 'package:flutter/material.dart';
import '../../scholars/promote_scholars.dart';

class PromoteScholarsPage extends StatelessWidget {
  const PromoteScholarsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: PromoteScholarsComponent(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../scholars/view_scholars.dart';

class ViewScholarsPage extends StatelessWidget {
  final VoidCallback? onRegisterScholar;
  const ViewScholarsPage({super.key, this.onRegisterScholar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ViewScholarsComponent(onRegisterScholar: onRegisterScholar),
    );
  }
}

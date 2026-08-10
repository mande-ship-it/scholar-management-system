import 'package:flutter/material.dart';
import '../../scholars/promote_scholars.dart';
import '../../academics/academics_utils.dart';

class PromoteScholarsPage extends StatelessWidget {
  final VoidCallback? onBack;
  const PromoteScholarsPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return PromoteScholarsComponent(onBack: onBack);
  }
}

import 'package:flutter/material.dart';
import '../../sponsors/viewSponsors.dart';

class ViewSponsorsPage extends StatelessWidget {
  const ViewSponsorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: ViewSponsorsComponent(),
      ),
    );
  }
}

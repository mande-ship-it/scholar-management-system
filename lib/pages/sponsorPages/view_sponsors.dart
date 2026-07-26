import 'package:flutter/material.dart';
import '../../sponsors/view_sponsors.dart';

class ViewSponsorsPage extends StatelessWidget {
  final VoidCallback? onRegisterSponsor;
  const ViewSponsorsPage({super.key, this.onRegisterSponsor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ViewSponsorsComponent(onRegisterSponsor: onRegisterSponsor),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../settings/organisationProfile.dart';

class OrganisationProfilePage extends StatelessWidget {
  const OrganisationProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: OrganisationProfileComponent(),
      ),
    );
  }
}

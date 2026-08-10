import 'package:flutter/material.dart';
import '../../settings/organisation_profile.dart';
import '../../academics/academics_utils.dart';

class OrganisationProfilePage extends StatelessWidget {
  final VoidCallback? onBack;
  const OrganisationProfilePage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return OrganisationProfileComponent(onBack: onBack);
  }
}

import 'package:flutter/material.dart';
import '../../settings/organisation_profile.dart';
import '../../academics/academics_utils.dart';

class OrganisationProfilePage extends StatelessWidget {
  final VoidCallback? onBack;
  final bool showBackButton;
  const OrganisationProfilePage({super.key, this.onBack, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return OrganisationProfileComponent(onBack: onBack, showBackButton: showBackButton);
  }
}

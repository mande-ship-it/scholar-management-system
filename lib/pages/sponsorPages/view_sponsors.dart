import 'package:flutter/material.dart';
import '../../sponsors/view_sponsors.dart';
import '../../academics/academics_utils.dart';

class ViewSponsorsPage extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onRegisterSponsor;
  final bool showBackButton;
  const ViewSponsorsPage({
    super.key, 
    this.onBack, 
    this.onRegisterSponsor,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return ViewSponsorsComponent(
      onBack: onBack, 
      onRegisterSponsor: onRegisterSponsor,
      showBackButton: showBackButton,
    );
  }
}

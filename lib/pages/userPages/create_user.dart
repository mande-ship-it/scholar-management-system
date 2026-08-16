import 'package:flutter/material.dart';
import '../../users/create_user.dart';
import '../../academics/academics_utils.dart';

class CreateUserPage extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSuccess;
  final bool showBackButton;
  const CreateUserPage({super.key, this.onBack, this.onSuccess, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    return CreateUserComponent(onBack: onBack, onSuccess: onSuccess, showBackButton: showBackButton);
  }
}

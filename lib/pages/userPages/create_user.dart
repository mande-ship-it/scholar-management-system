import 'package:flutter/material.dart';
import '../../users/create_user.dart';
import '../../academics/academics_utils.dart';

class CreateUserPage extends StatelessWidget {
  final VoidCallback? onBack;
  const CreateUserPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return CreateUserComponent(onBack: onBack);
  }
}

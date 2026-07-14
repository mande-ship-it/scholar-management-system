import 'package:flutter/material.dart';
import '../../sponsors/deleteSponsor.dart';

class DeleteSponsorPage extends StatelessWidget {
  const DeleteSponsorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: DeleteSponsorComponent(),
      ),
    );
  }
}

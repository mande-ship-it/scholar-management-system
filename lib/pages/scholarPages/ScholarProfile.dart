import 'package:flutter/material.dart';
import '../../scholars/ScholarProfile.dart';
import '../../academics/academicsUtils.dart';

class ScholarProfilePage extends StatelessWidget {
  const ScholarProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: canPop
          ? AppBar(
              title: const Text("Scholar Profile", style: TextStyle(color: kBrandBrown, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              foregroundColor: kBrandBrown,
              elevation: 0,
              centerTitle: false,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: Colors.grey.shade100, height: 1),
              ),
            )
          : null,
      body: const Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: ScholarProfileComponent(),
      ),
    );
  }
}

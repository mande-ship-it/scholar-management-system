import 'package:flutter/material.dart';
import '../../sponsors/sponsor_stats.dart';
import '../../academics/academics_utils.dart';

class SponsorStatsPage extends StatelessWidget {
  final VoidCallback? onBack;
  const SponsorStatsPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      appBar: (Navigator.canPop(context) || onBack != null) 
        ? AppBar(
            title: const Text("Partnership Statistics", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.white,
            foregroundColor: kBrandBrown,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: onBack ?? () => Navigator.pop(context),
            ),
          )
        : null,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 0 : 20),
        child: SponsorStatsComponent(onBack: onBack),
      ),
    );
  }
}

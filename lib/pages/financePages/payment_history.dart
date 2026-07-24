import 'package:flutter/material.dart';
import '../../finance/payment_history.dart';

class PaymentHistoryPage extends StatelessWidget {
  const PaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: PaymentHistoryComponent(),
      ),
    );
  }
}

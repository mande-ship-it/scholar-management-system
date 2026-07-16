import 'package:flutter/material.dart';
import '../academics/academicsUtils.dart';
import 'financeUtils.dart';

class FinancialReportsComponent extends StatefulWidget {
  const FinancialReportsComponent({super.key});

  @override
  State<FinancialReportsComponent> createState() => _FinancialReportsComponentState();
}

class _FinancialReportsComponentState extends State<FinancialReportsComponent> {
  @override
  Widget build(BuildContext context) {
    final double totalPayments = kPayments.fold(0, (sum, item) => sum + item.amount);
    final double totalExpenses = kExpenses.fold(0, (sum, item) => sum + item.amount);
    final double totalDisbursed = totalPayments + totalExpenses;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- Header ----------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kBrandBrown, kBrandOlive],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Financial Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 3),
                        Text('Aggregated summaries and program expenditure analytics.',
                            style: TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.file_download, size: 18, color: Colors.white),
                    label: const Text("Export PDF", style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // High level summary
                  Row(
                    children: [
                      _StatCard(label: "Total Disbursed", value: "MWK ${totalDisbursed.toStringAsFixed(0)}", color: kBrandBrown, icon: Icons.payments),
                      const SizedBox(width: 16),
                      _StatCard(label: "Scholarship Funds", value: "MWK ${totalPayments.toStringAsFixed(0)}", color: kBrandOlive, icon: Icons.school),
                      const SizedBox(width: 16),
                      _StatCard(label: "Operational Costs", value: "MWK ${totalExpenses.toStringAsFixed(0)}", color: kBrandOrange, icon: Icons.receipt),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Text("Monthly Spending Trend", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                  const SizedBox(height: 16),
                  
                  // Chart Mock
                  Container(
                    height: 220,
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: kBrandBrown, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MockBar(label: "Apr", value: 0.4),
                        _MockBar(label: "May", value: 0.6),
                        _MockBar(label: "Jun", value: 0.35),
                        _MockBar(label: "Jul", value: 0.85, isHighlight: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text("Expense Distribution", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                  const SizedBox(height: 16),
                  
                  // Categories list
                  _DistributionItem(label: "Tuition Fees", percent: 0.65, amount: "MWK 18.5M", color: kBrandBrown),
                  _DistributionItem(label: "Scholar Stipends", percent: 0.25, amount: "MWK 7.2M", color: kBrandOlive),
                  _DistributionItem(label: "Operations", percent: 0.10, amount: "MWK 2.8M", color: kBrandOrange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});
  final String label, value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Icon(icon, color: color, size: 16)),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _MockBar extends StatelessWidget {
  const _MockBar({required this.label, required this.value, this.isHighlight = false});
  final String label;
  final double value;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 140 * value,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: isHighlight ? [kBrandOrange, kBrandOrange.withValues(alpha: 0.6)] : [kBrandOlive, kBrandOlive.withValues(alpha: 0.6)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

class _DistributionItem extends StatelessWidget {
  const _DistributionItem({required this.label, required this.percent, required this.amount, required this.color});
  final String label, amount;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: percent, minHeight: 8, backgroundColor: Colors.grey.shade100, color: color),
          ),
        ],
      ),
    );
  }
}

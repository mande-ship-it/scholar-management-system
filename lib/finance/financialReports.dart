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
            // ---------------- Header (Banner Removed) ----------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kBrandBrown.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.bar_chart_rounded,
                        color: kBrandBrown, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Financial Reports',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: kBrandBrown)),
                        SizedBox(height: 4),
                        Text('Aggregated summaries and program expenditure analytics.',
                            style: TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.file_download, size: 18, color: kBrandBrown),
                    label: const Text("Export PDF", style: TextStyle(color: kBrandBrown)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kBrandBrown)),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------- Stats (Banners Removed) ----------------

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

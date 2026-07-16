import 'package:flutter/material.dart';
import '../academics/academicsUtils.dart';
import 'financeUtils.dart';

class BudgetComponent extends StatefulWidget {
  const BudgetComponent({super.key});

  @override
  State<BudgetComponent> createState() => _BudgetComponentState();
}

class _BudgetComponentState extends State<BudgetComponent> {
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
                    child: const Icon(Icons.pie_chart_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Budget & Allocations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 3),
                        Text('Monitor budget utilization and fiscal planning.',
                            style: TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("New Allocation"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kBrandBrown, elevation: 0),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Fiscal Year 2026 Overview", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                  const SizedBox(height: 20),
                  
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: kBudgets.length,
                    itemBuilder: (context, index) {
                      final b = kBudgets[index];
                      return _BudgetCard(budget: b);
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  const Text("Detailed Utilization", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                  const SizedBox(height: 16),
                  
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(kBrandCream.withValues(alpha: 0.5)),
                      columns: const [
                        DataColumn(label: Text("Category", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Allocated", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Spent", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Utilization", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: kBudgets.map((b) => DataRow(cells: [
                        DataCell(Text(b.category)),
                        DataCell(Text("MWK ${b.allocatedAmount.toStringAsFixed(0)}")),
                        DataCell(Text("MWK ${b.spentAmount.toStringAsFixed(0)}")),
                        DataCell(LinearProgressIndicator(value: b.utilizationRate, backgroundColor: Colors.grey.shade100, color: b.utilizationRate > 0.9 ? Colors.red : kBrandOlive)),
                      ])).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget});
  final BudgetAllocation budget;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(budget.category, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Spent", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text("MWK ${budget.spentAmount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kBrandBrown)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Remaining", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text("MWK ${budget.remaining.toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kBrandOlive)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: budget.utilizationRate,
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              color: budget.utilizationRate > 0.9 ? Colors.red : kBrandOlive,
            ),
          ),
        ],
      ),
    );
  }
}

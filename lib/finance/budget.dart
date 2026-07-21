import 'package:flutter/material.dart';
import '../academics/academicsUtils.dart';
import '../services/api_service.dart';
import 'financeUtils.dart';

class BudgetComponent extends StatefulWidget {
  const BudgetComponent({super.key});

  @override
  State<BudgetComponent> createState() => _BudgetComponentState();
}

class _BudgetComponentState extends State<BudgetComponent> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBudgets();
  }

  Future<void> _fetchBudgets() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllBudgets();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        kBudgets.clear();
        for (var item in data) {
          kBudgets.add(BudgetAllocation(
            id: item['id'].toString(),
            fiscalYear: item['fiscal_year'] ?? '2026',
            category: item['category'],
            allocatedAmount: double.parse(item['allocated_amount'].toString()),
            spentAmount: double.parse(item['spent_amount'].toString()),
          ));
        }
      }
    } catch (e) {
      debugPrint('Error fetching budgets: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
      child: _isLoading 
          ? const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: kBrandOlive)))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- Header (Banner Removed) ----------------
            Container(
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
                    child: const Icon(Icons.pie_chart_rounded, color: kBrandBrown, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Budget & Allocations', 
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrandBrown)),
                        const SizedBox(height: 4),
                        Text('Monitor budget utilization and fiscal planning.',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchBudgets,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("New Allocation"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrandOlive, 
                      foregroundColor: Colors.white, 
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
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

                  const Text("Detailed Utilization",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kBrandBrown)),
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

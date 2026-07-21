import 'package:flutter/material.dart';
import '../academics/academicsUtils.dart';

class FinanceReportsComponent extends StatefulWidget {
  const FinanceReportsComponent({super.key});

  @override
  State<FinanceReportsComponent> createState() => _FinanceReportsComponentState();
}

class _FinanceReportsComponentState extends State<FinanceReportsComponent> {
  String _selectedYear = 'FY 2026';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Clean Header
          _buildHeader(),
          
          const SizedBox(height: 24),
          
          // 2. Control Row
          _buildControls(),
          
          // ---------------- Stats (Banners Removed) ----------------
          
          const SizedBox(height: 24),
          
          // 4. Main Report Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _reportSection(
                  title: "Expenditure by Category",
                  child: _buildExpenseChart(),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: _reportSection(
                  title: "Funding Sources",
                  child: _buildSourceBreakdown(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 5. Transaction Summary Preview
          _reportSection(
            title: "Major Transactions Preview",
            child: _buildTransactionTable(),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBrandOlive.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.monetization_on_rounded,
                color: kBrandOlive, size: 32),
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
                Text(
                    'Detailed fiscal analysis, budget utilization, and expenditure tracking.',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text("Export CSV"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandOlive,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _dropdownControl("Fiscal Year", _selectedYear, ['FY 2024', 'FY 2025', 'FY 2026'], (v) => setState(() => _selectedYear = v!)),
          const Spacer(),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.print_rounded),
            label: const Text("Print Full Audit"),
          ),
        ],
      ),
    );
  }

  Widget _dropdownControl(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        DropdownButton<String>(
          value: value,
          isDense: true,
          underline: const SizedBox(),
          style: const TextStyle(color: kBrandBrown, fontWeight: FontWeight.bold, fontSize: 14),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _reportSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
          const Divider(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildExpenseChart() {
    return Column(
      children: [
        _chartBar("Direct Scholar Support", 0.68, kBrandOlive),
        _chartBar("Program Operations", 0.18, kBrandBrown),
        _chartBar("Staffing & Admin", 0.10, kBrandOrange),
        _chartBar("Fundraising & Misc", 0.04, Colors.grey),
      ],
    );
  }

  Widget _chartBar(String label, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Text("${(percent * 100).toInt()}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: percent, minHeight: 8, color: color, backgroundColor: Colors.grey.shade50),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBreakdown() {
    final sources = [
      ("International Donors", 70, kBrandBrown),
      ("Local Corporates", 20, kBrandOlive),
      ("Events & Misc", 10, kBrandOrange),
    ];
    return Column(
      children: sources.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: s.$3, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(child: Text(s.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
            Text("${s.$2}%", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildTransactionTable() {
    final txns = [
      ("Tuition Disbursal - UNIMA", "Expense", "MWK 18.5M", "July 15"),
      ("Grant: PMI Foundation", "Income", "MWK 25.0M", "July 12"),
      ("Stipend Payouts (July)", "Expense", "MWK 4.2M", "July 08"),
      ("Operational: Office Rent", "Expense", "MWK 1.5M", "July 01"),
    ];
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1),
      },
      children: [
        const TableRow(
          children: [
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
          ],
        ),
        ...txns.map((t) => TableRow(
          children: [
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(t.$1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kBrandBrown))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: _badge(t.$2, t.$2 == "Income" ? Colors.green.shade50 : Colors.red.shade50, t.$2 == "Income" ? Colors.green.shade700 : Colors.red.shade700)),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(t.$3, style: TextStyle(fontWeight: FontWeight.bold, color: t.$2 == "Income" ? Colors.green.shade700 : kBrandBrown))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(t.$4, style: const TextStyle(fontSize: 12))),
          ],
        )),
      ],
    );
  }

  Widget _badge(String label, Color bgColor, Color textColor) {
    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
        child: Text(label, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

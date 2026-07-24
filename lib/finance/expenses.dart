import 'package:flutter/material.dart';
import '../academics/academics_utils.dart';
import 'finance_utils.dart';

class ExpensesComponent extends StatefulWidget {
  const ExpensesComponent({super.key});

  @override
  State<ExpensesComponent> createState() => _ExpensesComponentState();
}

class _ExpensesComponentState extends State<ExpensesComponent> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _refController = TextEditingController();
  String _selectedCategory = 'Admin';
  String _selectedMethod = 'Bank Transfer';
  DateTime _date = DateTime.now();

  final List<String> _categories = ['Admin', 'Travel', 'Marketing', 'Utilities', 'Maintenance', 'Salaries'];
  final List<String> _methods = ['Bank Transfer', 'Cash', 'Check', 'Mobile Money'];

  void _saveExpense() {
    if (!_formKey.currentState!.validate()) return;

    final newExp = OperationalExpense(
      id: 'e${kExpenses.length + 1}',
      description: _descController.text,
      category: _selectedCategory,
      amount: double.parse(_amountController.text),
      date: _date,
      paymentMethod: _selectedMethod,
      refNumber: _refController.text,
    );

    setState(() {
      kExpenses.add(newExp);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Operational expense recorded.'), backgroundColor: kBrandOlive),
    );
    _descController.clear();
    _amountController.clear();
    _refController.clear();
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
                    child: const Icon(Icons.receipt_long_rounded, color: kBrandBrown, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Operational Expenses',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: kBrandBrown)),
                        SizedBox(height: 4),
                        Text('Record and manage organization operational costs.',
                            style: TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form
                  Expanded(
                    flex: 2,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Record New Expense", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _descController,
                            decoration: _inputDeco("Description", Icons.description_outlined),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedCategory,
                                  decoration: _inputDeco("Category", Icons.category_outlined),
                                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  onChanged: (v) => setState(() => _selectedCategory = v!),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDeco("Amount (MWK)", Icons.money_rounded),
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedMethod,
                                  decoration: _inputDeco("Payment Method", Icons.payments_outlined),
                                  items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                                  onChanged: (v) => setState(() => _selectedMethod = v!),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _refController,
                                  decoration: _inputDeco("Reference #", Icons.tag_rounded),
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
                              if (picked != null) setState(() => _date = picked);
                            },
                            child: InputDecorator(
                              decoration: _inputDeco("Expense Date", Icons.calendar_today_rounded),
                              child: Text("${_date.day}/${_date.month}/${_date.year}"),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveExpense,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kBrandOlive,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text("Save Expense Record", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Recent List
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Recent Expenses", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                        const SizedBox(height: 20),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: kExpenses.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final e = kExpenses[kExpenses.length - 1 - index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                              child: Row(
                                children: [
                                  CircleAvatar(backgroundColor: kBrandBrown.withValues(alpha: 0.1), child: const Icon(Icons.receipt_rounded, color: kBrandBrown, size: 18)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(e.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                                        Text("${e.category} • ${e.date.day}/${e.date.month}/${e.date.year}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                  ),
                                  Text("MWK ${e.amount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
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

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: kBrandBrown),
      isDense: true,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
    );
  }
}

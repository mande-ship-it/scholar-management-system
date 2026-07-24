import 'package:flutter/material.dart';
import '../academics/academics_utils.dart';
import '../services/api_service.dart';
import 'finance_utils.dart';

class ScholarshipPaymentsComponent extends StatefulWidget {
  const ScholarshipPaymentsComponent({super.key});

  @override
  State<ScholarshipPaymentsComponent> createState() => _ScholarshipPaymentsComponentState();
}

class _ScholarshipPaymentsComponentState extends State<ScholarshipPaymentsComponent> {
  final _formKey = GlobalKey<FormState>();
  Student? _selectedStudent;
  PaymentCategory _selectedCategory = PaymentCategory.tuition;
  String? _selectedBank;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _dueDate = DateTime.now();
  bool _isSaving = false;

  void _submitPayment() async {
    if (!_formKey.currentState!.validate() || _selectedStudent == null) return;

    setState(() => _isSaving = true);
    
    try {
      final paymentData = {
        'scholarId': _selectedStudent!.id,
        'category': _selectedCategory.label,
        'amount': double.parse(_amountController.text),
        'dueDate': _dueDate.toIso8601String().split('T')[0],
        'referenceNumber': _referenceController.text.trim(),
        'bankName': _selectedBank,
        'notes': _notesController.text.trim(),
        'status': 'Pending',
      };

      final response = await ApiService.createPayment(paymentData);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final newPayment = ScholarshipPayment(
          id: response.data['data']['id']?.toString() ?? 'p${kPayments.length + 1}',
          studentId: _selectedStudent!.id,
          category: _selectedCategory,
          amount: double.parse(_amountController.text),
          dueDate: _dueDate,
          reference: _referenceController.text,
          notes: _notesController.text,
          status: PaymentStatus.pending,
          bankName: _selectedBank,
        );

        setState(() {
          kPayments.add(newPayment);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scholarship payment recorded as pending.'),
              backgroundColor: kBrandOlive,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Reset form
        _amountController.clear();
        _referenceController.clear();
        _notesController.clear();
        setState(() {
          _selectedStudent = null;
          _selectedBank = null;
        });
      }
    } catch (e) {
      debugPrint('Error saving payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to record payment. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: kBrandBrown, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Scholarship Payments',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: kBrandBrown)),
                        SizedBox(height: 4),
                        Text('Manage and issue scholarship fund disbursements.',
                            style: TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Record Disbursement", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown)),
                    const SizedBox(height: 20),

                    // Scholar Selection
                    Autocomplete<Student>(
                      displayStringForOption: (s) => s.name,
                      optionsBuilder: (textValue) {
                        if (textValue.text.isEmpty) return kStudents;
                        return kStudents.where((s) => s.name.toLowerCase().contains(textValue.text.toLowerCase()));
                      },
                      onSelected: (s) => setState(() => _selectedStudent = s),
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: _inputDeco("Select Scholar", Icons.person_search_rounded),
                          validator: (v) => _selectedStudent == null ? 'Please select a scholar' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<PaymentCategory>(
                            initialValue: _selectedCategory,
                            decoration: _inputDeco("Category", Icons.category_outlined),
                            items: PaymentCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
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
                          child: DropdownButtonFormField<String?>(
                            initialValue: _selectedBank,
                            decoration: _inputDeco("Bank / Payment Channel", Icons.account_balance_rounded),
                            items: kMalawiBanks.map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (v) => setState(() => _selectedBank = v),
                            isExpanded: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _referenceController,
                            decoration: _inputDeco("Reference #", Icons.tag_rounded),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                              if (picked != null) setState(() => _dueDate = picked);
                            },
                            child: InputDecorator(
                              decoration: _inputDeco("Due Date", Icons.calendar_today_rounded),
                              child: Text("${_dueDate.day}/${_dueDate.month}/${_dueDate.year}"),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Spacer(), // Placeholder for row balance
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: _inputDeco("Notes", Icons.note_alt_outlined),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _submitPayment,
                        icon: _isSaving 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.add_task_rounded),
                        label: Text(_isSaving ? "Processing..." : "Record Disbursement", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: kBrandOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
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
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBrandOlive, width: 2)),
    );
  }
}

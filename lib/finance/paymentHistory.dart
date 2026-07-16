import 'package:flutter/material.dart';
import '../academics/academicsUtils.dart';
import 'financeUtils.dart';

class PaymentHistoryComponent extends StatefulWidget {
  const PaymentHistoryComponent({super.key});

  @override
  State<PaymentHistoryComponent> createState() => _PaymentHistoryComponentState();
}

class _PaymentHistoryComponentState extends State<PaymentHistoryComponent> {
  PaymentStatus? _filterStatus;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = kPayments.where((p) {
      final student = kStudents.firstWhere((s) => s.id == p.studentId);
      final matchesQuery = student.name.toLowerCase().contains(_searchQuery.toLowerCase()) || p.reference.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _filterStatus == null || p.status == _filterStatus;
      return matchesQuery && matchesStatus;
    }).toList()..sort((a, b) => b.dueDate.compareTo(a.dueDate));

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
                    child: const Icon(Icons.history_edu_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Payment History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 3),
                        Text('Track disbursement status and scholar payment logs.',
                            style: TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Filters
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: _inputDeco("Search scholar or reference", Icons.search_rounded),
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<PaymentStatus?>(
                          initialValue: _filterStatus,
                          decoration: _inputDeco("Status", Icons.filter_list_rounded),
                          items: [
                            const DropdownMenuItem(value: null, child: Text("All Statuses")),
                            DropdownMenuItem(value: PaymentStatus.pending, child: Text("Pending")),
                            DropdownMenuItem(value: PaymentStatus.paid, child: Text("Paid")),
                            DropdownMenuItem(value: PaymentStatus.cancelled, child: Text("Cancelled")),
                          ],
                          onChanged: (v) => setState(() => _filterStatus = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      final student = kStudents.firstWhere((s) => s.id == p.studentId);
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          isThreeLine: true,
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: kBrandBrown.withValues(alpha: 0.1),
                            child: Icon(p.category.icon, color: kBrandBrown, size: 20),
                          ),
                          title: Row(
                            children: [
                              Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const Spacer(),
                              Text("MWK ${p.amount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text("${p.category.label} • Ref: ${p.reference}", style: const TextStyle(fontSize: 12)),
                              if (p.bankName != null) 
                                Text("Bank: ${p.bankName}", style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                              Text("Due: ${p.dueDate.day}/${p.dueDate.month}/${p.dueDate.year}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                          trailing: _StatusBadge(status: p.status, onMarkPaid: () {
                            setState(() {
                              p.status = PaymentStatus.paid;
                            });
                          }),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.onMarkPaid});
  final PaymentStatus status;
  final VoidCallback onMarkPaid;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case PaymentStatus.paid: color = kBrandOlive; label = "PAID"; break;
      case PaymentStatus.pending: color = kBrandOrange; label = "PENDING"; break;
      case PaymentStatus.cancelled: color = Colors.red; label = "CANCELLED"; break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.3))),
          child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
        ),
        if (status == PaymentStatus.pending)
          TextButton(
            onPressed: onMarkPaid,
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
            child: const Text("Mark Paid", style: TextStyle(fontSize: 11, color: kBrandOlive, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}

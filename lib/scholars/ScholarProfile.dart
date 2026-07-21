import 'package:flutter/material.dart';
import '../academics/academicsUtils.dart';
import '../finance/financeUtils.dart';
import '../services/api_service.dart';

class ScholarProfileComponent extends StatefulWidget {
  const ScholarProfileComponent({super.key});

  @override
  State<ScholarProfileComponent> createState() => _ScholarProfileComponentState();
}

class _ScholarProfileComponentState extends State<ScholarProfileComponent> {
  int _selectedTab = 0; // 0 = Overview, 1 = Statistics, 2 = Finances
  bool _isLoading = true;
  Student? _student;
  Map<String, dynamic>? _extraData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_student == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final String id = args?['id'] ?? 's1';
      _fetchScholarData(id, args);
    }
  }

  Future<void> _fetchScholarData(String id, Map<String, dynamic>? args) async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getScholarById(id);
      if (response.statusCode == 200) {
        final item = response.data['data'];
        _student = Student(
          id: item['id'].toString(),
          name: item['full_name'],
          age: item['dob'] != null ? DateTime.now().year - DateTime.parse(item['dob']).year : 16,
          schoolType: item['school_type'] == 'University' ? SchoolType.university : SchoolType.secondary,
          schoolName: item['display_school_name'] ?? 'N/A',
          currentClass: item['academic_year'] ?? 'N/A',
          status: item['status'] ?? 'Active',
          district: item['district'] ?? 'N/A',
          village: item['village'] ?? 'N/A',
          donor: item['donor'] ?? 'N/A',
          phone: item['phone'] ?? 'N/A',
          email: item['email'] ?? 'N/A',
          sex: item['sex'] ?? 'Female',
          dob: item['dob'] ?? '',
          programType: item['program_type'] ?? '',
          startYear: item['start_year'] ?? '2026',
          endYear: item['end_year'] ?? '2030',
        );
        
        _extraData = {
          'class': _student!.currentClass,
          'sex': _student!.sex,
          'dob': _student!.dob,
          'phone': _student!.phone,
          'district': _student!.district,
          'village': _student!.village,
          'donor': _student!.donor,
          'status': _student!.status,
        };

        // Fetch academic results
        final resultsRes = await ApiService.getResultsByScholar(id);
        if (resultsRes.statusCode == 200) {
          final List<dynamic> rData = resultsRes.data['data'];
          setState(() {
            kResults.removeWhere((r) => r.studentId == id);
            for (var rItem in rData) {
              kResults.add(ResultRecord(
                studentId: rItem['scholar_id'].toString(),
                code: rItem['subject_code'] ?? 'N/A',
                subject: rItem['subject_name'] ?? 'N/A',
                marks: double.parse(rItem['marks'].toString()),
                gpa: rItem['gpa'] != null ? double.parse(rItem['gpa'].toString()) : null,
                points: rItem['points'] != null ? double.parse(rItem['points'].toString()) : null,
                year: rItem['academic_year'].toString(),
                term: rItem['term'],
                semester: rItem['semester'],
              ));
            }
          });
        }

        // Fetch financial payments
        final paymentsRes = await ApiService.getPaymentsByScholar(id);
        if (paymentsRes.statusCode == 200) {
          final List<dynamic> pData = paymentsRes.data['data'];
          setState(() {
            kPayments.removeWhere((p) => p.studentId == id);
            for (var pItem in pData) {
              final paymentDate = pItem['payment_date'] != null 
                  ? DateTime.parse(pItem['payment_date']) 
                  : DateTime.now();
              
              kPayments.add(ScholarshipPayment(
                id: pItem['id'].toString(),
                studentId: pItem['scholar_id'].toString(),
                category: PaymentCategory.values.firstWhere(
                  (c) => c.label == pItem['category'],
                  orElse: () => PaymentCategory.tuition,
                ),
                amount: double.parse(pItem['amount'].toString()),
                dueDate: paymentDate,
                paidDate: pItem['status'] == 'Paid' ? paymentDate : null,
                status: pItem['status'] == 'Paid' ? PaymentStatus.paid : PaymentStatus.pending,
                reference: pItem['reference_number'] ?? 'N/A',
              ));
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching scholar profile data: $e');
      // Fallback if error
      if (_student == null && kStudents.isNotEmpty) {
        _student = kStudents.firstWhere((s) => s.id == id, orElse: () => kStudents.first);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: kBrandOlive)));
    }
    
    if (_student == null) {
      return const Center(child: Text("Scholar not found."));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Clean Header (No Banners)
        _buildHeader(_student!, _extraData),
        
        const SizedBox(height: 24),
        
        // 2. Tab Navigation
        _buildTabBar(),
        
        const SizedBox(height: 24),
        
        // 3. Tab Content
        Expanded(
          child: SingleChildScrollView(
            child: _buildTabContent(_student!, _extraData),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Student student, Map<String, dynamic>? args) {
    final String status = args?['status'] ?? 'Active';
    final bool isActive = status == 'Active';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: kBrandOlive.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              student.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(''),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kBrandOlive),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrandBrown)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _badge("Scholar ID: ${student.id}", Colors.grey.shade100, Colors.grey.shade600),
                    const SizedBox(width: 8),
                    _badge(status, isActive ? Colors.green.shade50 : Colors.red.shade50, isActive ? Colors.green.shade700 : Colors.red.shade700),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text("Edit"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandBrown,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final items = [
      ("Overview", Icons.person_outline_rounded),
      ("Academic Stats", Icons.auto_graph_rounded),
      ("Financial Record", Icons.payments_outlined),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = index),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(items[index].$2, size: 18, color: isSelected ? kBrandOlive : Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      items[index].$1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? kBrandBrown : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(Student student, Map<String, dynamic>? args) {
    switch (_selectedTab) {
      case 0: return _buildOverviewTab(student, args);
      case 1: return _buildStatisticsTab(student);
      case 2: return _buildFinancialTab(student);
      default: return const SizedBox();
    }
  }

  // --- TAB 1: OVERVIEW ---
  Widget _buildOverviewTab(Student student, Map<String, dynamic>? args) {
    return Column(
      children: [
        _infoSection(
          title: "Institutional Affiliation",
          icon: Icons.school_outlined,
          child: Column(
            children: [
              _infoTile("Current Institution", student.schoolName, isBold: true),
              const Divider(height: 32),
              Row(
                children: [
                  Expanded(child: _infoTile("Level", student.schoolType == SchoolType.secondary ? "Secondary" : "University")),
                  Expanded(child: _infoTile("Class / Year", args?['class'] ?? 'N/A')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _infoSection(
                title: "Personal Details",
                icon: Icons.badge_outlined,
                child: Column(
                  children: [
                    _infoRow(Icons.wc, "Sex", args?['sex'] ?? 'Female'),
                    _infoRow(Icons.cake_outlined, "DOB", args?['dob'] ?? '2009-05-12'),
                    _infoRow(Icons.phone_outlined, "Phone", args?['phone'] ?? '+265 888 123 456'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _infoSection(
                title: "Home & Origin",
                icon: Icons.map_outlined,
                child: Column(
                  children: [
                    _infoRow(Icons.location_on_outlined, "District", args?['district'] ?? 'Mzimba'),
                    _infoRow(Icons.home_outlined, "Village", args?['village'] ?? 'Chilinde'),
                    _infoRow(Icons.volunteer_activism_outlined, "Donor", args?['donor'] ?? 'PMI'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- TAB 2: ACADEMIC STATISTICS ---
  Widget _buildStatisticsTab(Student student) {
    final records = kResults.where((r) => r.studentId == student.id).toList();
    final double avg = records.isEmpty ? 0.0 : records.map((r) => r.marks).reduce((a, b) => a + b) / records.length;
    final band = performanceBand(avg);
    
    final bestResult = records.isEmpty ? null : records.reduce((a, b) => a.marks > b.marks ? a : b);
    
    // Improved Logic: Calculate GPA for University Students
    double totalGpa = 0;
    if (student.schoolType == SchoolType.university && records.isNotEmpty) {
      final gpaRecords = records.where((r) => r.gpa != null).toList();
      if (gpaRecords.isNotEmpty) {
        totalGpa = gpaRecords.map((r) => r.gpa!).reduce((a, b) => a + b) / gpaRecords.length;
      }
    }

    return Column(
      children: [
        // Top Stats Row
        Row(
          children: [
            Expanded(child: _statCard("Average Mark", "${avg.toStringAsFixed(1)}%", band.color, Icons.analytics_rounded)),
            const SizedBox(width: 16),
            if (student.schoolType == SchoolType.university) ...[
              Expanded(child: _statCard("Cumulative GPA", totalGpa.toStringAsFixed(2), kBrandOlive, Icons.school_rounded)),
              const SizedBox(width: 16),
            ],
            Expanded(child: _statCard("Standing", band.label, band.color, Icons.stars_rounded)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _statCard("Best Subject", bestResult?.subject ?? 'N/A', kBrandOlive, Icons.emoji_events_outlined)),
            const SizedBox(width: 16),
            Expanded(child: _statCard("Total Records", "${records.length}", kBrandBrown, Icons.inventory_2_outlined)),
          ],
        ),
        const SizedBox(height: 24),
        
        _infoSection(
          title: "Subject Performance Breakdown",
          icon: Icons.bar_chart_rounded,
          child: Column(
            children: [
              if (records.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text("No academic records found for this scholar.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                )
              else
                ...records.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(r.subject, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
                          Text("${r.marks.toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: r.marks >= 50 ? kBrandOlive : Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: r.marks / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade100,
                          color: r.marks >= 80 ? Colors.green : (r.marks >= 50 ? kBrandOlive : Colors.orange),
                        ),
                      ),
                    ],
                  ),
                )),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 3: FINANCIAL RECORD ---
  Widget _buildFinancialTab(Student student) {
    final payments = kPayments.where((p) => p.studentId == student.id).toList();
    final paid = payments.where((p) => p.status == PaymentStatus.paid).toList();
    final pending = payments.where((p) => p.status == PaymentStatus.pending).toList();
    
    final totalDisbursed = paid.isEmpty ? 0.0 : paid.map((p) => p.amount).reduce((a, b) => a + b);
    final totalPending = pending.isEmpty ? 0.0 : pending.map((p) => p.amount).reduce((a, b) => a + b);

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statCard("Paid to Date", "MWK ${totalDisbursed.toStringAsFixed(0)}", kBrandOlive, Icons.check_circle_outline)),
            const SizedBox(width: 16),
            Expanded(child: _statCard("Pending", "MWK ${totalPending.toStringAsFixed(0)}", kBrandOrange, Icons.hourglass_empty_rounded)),
          ],
        ),
        const SizedBox(height: 24),
        
        _infoSection(
          title: "Payment History",
          icon: Icons.history_rounded,
          child: payments.isEmpty 
            ? const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text("No financial transactions found.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: payments.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final p = payments[index];
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: kBrandBrown.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                        child: Icon(p.category.icon, size: 20, color: kBrandBrown),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.category.label, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
                            Text("Ref: ${p.reference}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("MWK ${p.amount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
                          Text(
                            p.status == PaymentStatus.paid ? "Paid" : "Pending",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: p.status == PaymentStatus.paid ? Colors.green : kBrandOrange),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
        ),
      ],
    );
  }

  // --- REUSABLE COMPONENTS ---

  Widget _infoSection({required String title, required IconData icon, required Widget child}) {
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
          Row(
            children: [
              Icon(icon, size: 18, color: kBrandOlive),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kBrandBrown)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrandBrown), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: isBold ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: kBrandBrown)),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kBrandBrown)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

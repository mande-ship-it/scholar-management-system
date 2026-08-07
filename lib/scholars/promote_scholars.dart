import 'package:flutter/material.dart';
import '../academics/academics_utils.dart';
import '../services/api_service.dart';

class PromoteScholarsComponent extends StatefulWidget {
  const PromoteScholarsComponent({super.key});

  @override
  State<PromoteScholarsComponent> createState() => _PromoteScholarsComponentState();
}

class _PromoteScholarsComponentState extends State<PromoteScholarsComponent> {
  String _selectedSchool = 'All Schools';
  String _selectedYear = '2026';
  bool _isLoading = false;

  List<String> get _schoolOptions => ['All Schools', ...kStudents.map((s) => s.schoolName).toSet().toList()..sort()];
  List<String> get _yearOptions => kResults.map((r) => r.year).toSet().toList()..sort((a, b) => b.compareTo(a));

  @override
  void initState() {
    super.initState();
    _fetchScholars();
  }

  Future<void> _fetchScholars() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllScholars();
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        setState(() {
          kStudents.clear();
          for (var item in data) {
            kStudents.add(Student(
              id: item['id'].toString(),
              scholarId: item['scholar_id']?.toString() ?? 'N/A',
              name: item['full_name'] ?? 'N/A',
              age: 16,
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
              startYear: item['start_year']?.toString() ?? '2026',
              endYear: item['end_year']?.toString() ?? '2030',
            ));
          }
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _promoteStudent(Student student) async {
    final current = student.currentClass;
    String nextClass = current;
    
    if (student.schoolType == SchoolType.secondary) {
      if (current.startsWith('Form ')) {
        final formNum = int.tryParse(current.replaceFirst('Form ', ''));
        if (formNum != null) nextClass = 'Form ${formNum + 1}';
      } else {
        nextClass = 'Form 1';
      }
    } else {
      if (current.startsWith('Year ')) {
        final yearNum = int.tryParse(current.replaceFirst('Year ', ''));
        if (yearNum != null) nextClass = 'Year ${yearNum + 1}';
      } else {
        nextClass = 'Year 1';
      }
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.promoteScholar(student.id, nextClass);
      if (response.statusCode == 200) {
        setState(() {
          final index = kStudents.indexWhere((s) => s.id == student.id);
          if (index != -1) {
            kStudents[index] = kStudents[index].copyWith(currentClass: nextClass);
          }
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Promoted ${student.name} from $current to $nextClass."),
            backgroundColor: const Color(0xFF9AB334),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _promoteAllFiltered(List<Student> filtered) async {
    if (filtered.isEmpty) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Bulk Promotion"),
        content: Text("Are you sure you want to promote all ${filtered.length} scholars in the current view?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9AB334), foregroundColor: Colors.white),
            child: const Text("Promote All"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    int successCount = 0;

    for (final student in filtered) {
      final current = student.currentClass;
      String nextClass = current;

      if (student.schoolType == SchoolType.secondary) {
        if (current.startsWith('Form ')) {
          final formNum = int.tryParse(current.replaceFirst('Form ', ''));
          if (formNum != null) nextClass = 'Form ${formNum + 1}';
        } else {
          nextClass = 'Form 1';
        }
      } else {
        if (current.startsWith('Year ')) {
          final yearNum = int.tryParse(current.replaceFirst('Year ', ''));
          if (yearNum != null) nextClass = 'Year ${yearNum + 1}';
        } else {
          nextClass = 'Year 1';
        }
      }

      try {
        final response = await ApiService.promoteScholar(student.id, nextClass);
        if (response.statusCode == 200) {
          successCount++;
          final index = kStudents.indexWhere((s) => s.id == student.id);
          if (index != -1) {
            kStudents[index] = kStudents[index].copyWith(currentClass: nextClass);
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Successfully promoted $successCount scholars."),
          backgroundColor: const Color(0xFF9AB334),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    final filteredStudents = kStudents.where((s) {
      final matchesSchool = _selectedSchool == 'All Schools' || s.schoolName == _selectedSchool;
      return matchesSchool;
    }).toList();

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPortalHeader(isMobile, filteredStudents),
          _buildPortalFilterToolbar(isMobile),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
                : ListView.separated(
                    padding: EdgeInsets.all(isMobile ? 12 : 32),
                    itemCount: filteredStudents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => _buildPromotionCard(filteredStudents[index], isMobile),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortalHeader(bool isMobile, List<Student> filtered) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Progression Audit Portal",
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16, 
                    fontWeight: FontWeight.w900, 
                    color: const Color(0xFF4C3C32), 
                    letterSpacing: -0.2
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile && filtered.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _promoteAllFiltered(filtered),
              icon: const Icon(Icons.verified_user_rounded, size: 14),
              label: const Text("BULK UPGRADE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE05B1C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPortalFilterToolbar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: isMobile
        ? Column(
            children: [
              _compactDropdown("Target Institution", _selectedSchool, _schoolOptions, (v) => setState(() => _selectedSchool = v!)),
              const SizedBox(height: 12),
              _compactDropdown("Cycle Year", _selectedYear, _yearOptions.isEmpty ? ['2026'] : _yearOptions, (v) => setState(() => _selectedYear = v!)),
            ],
          )
        : Row(
            children: [
              SizedBox(
                width: 320,
                child: _compactDropdown("Target Institution", _selectedSchool, _schoolOptions, (v) => setState(() => _selectedSchool = v!)),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 180,
                child: _compactDropdown("Cycle Year", _selectedYear, _yearOptions.isEmpty ? ['2026'] : _yearOptions, (v) => setState(() => _selectedYear = v!)),
              ),
              const Spacer(),
              _miniStat(Icons.info_outline_rounded, "Manual upgrade required per individual."),
            ],
          ),
    );
  }

  Widget _miniStat(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF4C3C32).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4C3C32)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4C3C32))),
        ],
      ),
    );
  }

  Widget _compactDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPromotionCard(Student s, bool isMobile) {
    const passed = true; // Business logic for promotion eligibility
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF2DB),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                getInitials(s.name),
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4C3C32), fontSize: 14),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF4C3C32), letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 4),
                  Text("${s.schoolName} • CURRENT: ${s.currentClass}", 
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                ],
              ),
            ),
            if (!isMobile) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF9AB334).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF9AB334)),
                    SizedBox(width: 8),
                    Text("ELIGIBLE FOR UPGRADE", 
                      style: TextStyle(color: Color(0xFF9AB334), fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
            ],
            ElevatedButton.icon(
              onPressed: passed ? () => _promoteStudent(s) : null,
              icon: const Icon(Icons.upgrade_rounded, size: 16),
              label: const Text("PROMOTIONAL ACTION"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C3C32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

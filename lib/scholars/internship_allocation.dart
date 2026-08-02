import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';
import 'package:intl/intl.dart';

class InternshipAllocationComponent extends StatefulWidget {
  const InternshipAllocationComponent({super.key});

  @override
  State<InternshipAllocationComponent> createState() => _InternshipAllocationComponentState();
}

class _InternshipAllocationComponentState extends State<InternshipAllocationComponent> {
  bool _isLoading = true;
  List<dynamic> _graduates = [];
  List<dynamic> _internships = [];

  // Selection
  dynamic _selectedGraduate;
  final _workplaceController = TextEditingController();
  final _locationController = TextEditingController();
  final _supervisorController = TextEditingController();
  final _emailController = TextEditingController();
  final _detailsController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final resGrads = await ApiService.getUniversityGraduates();
      final resInterns = await ApiService.getAllInternships();

      if (mounted) {
        setState(() {
          _graduates = resGrads.data['data'];
          _internships = resInterns.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching internship data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAllocation() async {
    if (_selectedGraduate == null || _workplaceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a scholar and enter workplace."), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = {
        'scholarId': _selectedGraduate['id'],
        'workplaceName': _workplaceController.text,
        'location': _locationController.text,
        'supervisor': _supervisorController.text,
        'email': _emailController.text,
        'startDate': _startDate.toIso8601String().split('T')[0],
        'endDate': _endDate.toIso8601String().split('T')[0],
        'details': _detailsController.text,
      };

      final response = await ApiService.allocateInternship(data);
      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Internship allocated successfully! Scholar notified."), backgroundColor: Colors.green),
          );
          _resetForm();
          _fetchData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? "Allocation failed.")),
          );
        }
      }
    } catch (e) {
      debugPrint('Allocation error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedGraduate = null;
      _workplaceController.clear();
      _locationController.clear();
      _supervisorController.clear();
      _emailController.clear();
      _detailsController.clear();
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 365));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildAllocationForm()),
                      const SizedBox(width: 32),
                      Expanded(flex: 2, child: _buildRecentAllocations()),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kBrandOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.handshake_rounded, color: kBrandOrange, size: 28),
          ),
          const SizedBox(width: 20),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Internship Allocation Hub", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
              Text("Strategic workforce placement for AGE Africa alumni.", style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
            ],
          ),
          const Spacer(),
          IconButton(onPressed: _fetchData, icon: const Icon(Icons.sync_rounded, color: kBrandOlive)),
        ],
      ),
    );
  }

  Widget _buildAllocationForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("NEW ALLOCATION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kBrandOrange, letterSpacing: 1.5)),
          const SizedBox(height: 24),

          _formLabel("SELECT GRADUATED SCHOLAR"),
          _buildScholarDropdown(),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(child: _buildTextField("WORKPLACE NAME", _workplaceController, Icons.business_rounded)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField("LOCATION / DISTRICT", _locationController, Icons.place_rounded)),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(child: _buildTextField("ASSIGNED SUPERVISOR", _supervisorController, Icons.person_pin_rounded)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField("SCHOLAR EMAIL (VERIFY)", _emailController, Icons.alternate_email_rounded)),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(child: _buildDatePicker("START DATE", _startDate, (d) => setState(() => _startDate = d))),
              const SizedBox(width: 16),
              Expanded(child: _buildDatePicker("END DATE (1 YEAR TYPICAL)", _endDate, (d) => setState(() => _endDate = d))),
            ],
          ),
          const SizedBox(height: 24),

          _formLabel("ALLOCATION DETAILS / TERMS"),
          TextField(
            controller: _detailsController,
            maxLines: 4,
            decoration: InputDecoration(
              filled: true, fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _submitAllocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("FINALIZE ALLOCATION & NOTIFY SCHOLAR", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScholarDropdown() {
    // Only show graduates who aren't already allocated
    final unallocated = _graduates.where((g) => g['internship_status'] == null).toList();

    return DropdownButtonFormField<dynamic>(
      value: _selectedGraduate,
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.school_rounded, size: 20, color: kBrandOlive),
        filled: true, fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      hint: const Text("Search unallocated graduates..."),
      items: unallocated.map((g) => DropdownMenuItem(
        value: g,
        child: Text(
          "${g['full_name']} (${g['scholar_id']}) - ${g['display_school_name']}",
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
      )).toList(),
      onChanged: (v) {
        setState(() {
          _selectedGraduate = v;
          _emailController.text = v['email'] ?? '';
        });
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formLabel(label),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: kBrandOlive),
            filled: true, fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime date, Function(DateTime) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formLabel(label),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2030));
            if (picked != null) onSelect(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 18, color: kBrandOlive),
                const SizedBox(width: 12),
                Text(DateFormat('dd MMM yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _formLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
  );

  Widget _buildRecentAllocations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ACTIVE INTERNSHIPS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kBrandBrown)),
        const SizedBox(height: 16),
        ..._internships.map((i) => _allocationCard(i)),
        if (_internships.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text("No active allocations found.", style: TextStyle(color: Colors.grey)))),
      ],
    );
  }

  Widget _allocationCard(dynamic i) {
    final bool isCompleted = i['status'] == 'Completed';
    final scholarName = i['scholar_name'] ?? (i['scholarId'] != null ? i['scholarId']['fullName'] ?? i['scholarId']['full_name'] : 'N/A');
    final workplace = i['workplace_name'] ?? i['workplaceName'] ?? 'N/A';
    final status = i['status'] ?? 'Active';

    String durationStr = "TBD";
    try {
      final start = i['start_date'] ?? i['startDate'];
      final end = i['end_date'] ?? i['endDate'];
      if (start != null && end != null) {
        durationStr = "${DateFormat('MMM yyyy').format(DateTime.parse(start.toString()))} - ${DateFormat('MMM yyyy').format(DateTime.parse(end.toString()))}";
      } else if (start != null) {
        durationStr = "From ${DateFormat('MMM yyyy').format(DateTime.parse(start.toString()))}";
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCompleted ? Colors.grey.shade100 : kBrandOlive.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(scholarName.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 4),
          Text(workplace.toString(),
            style: TextStyle(color: kBrandOrange, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text(durationStr,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final bool active = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: active ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: active ? Colors.green : Colors.grey, fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }
}

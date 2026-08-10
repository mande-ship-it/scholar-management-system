import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';
import 'package:intl/intl.dart';
import 'allocation_list.dart';

class InternshipAllocationComponent extends StatefulWidget {
  const InternshipAllocationComponent({super.key});

  @override
  State<InternshipAllocationComponent> createState() => _InternshipAllocationComponentState();
}

class _InternshipAllocationComponentState extends State<InternshipAllocationComponent> {
  bool _isLoading = true;
  List<dynamic> _graduates = [];

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
      if (mounted) {
        setState(() {
          _graduates = resGrads.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching graduates: $e');
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
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          _buildHeader(isMobile),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 40),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: _buildAllocationForm(isMobile),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 12 : 24, vertical: 8),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
      child: Row(
        children: [
          if (Navigator.canPop(context)) ...[
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: kBrandBrown),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text("Internship Allotment", 
              style: TextStyle(fontSize: isVerySmall ? 13 : 16, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.2)),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AllocationListPage()));
            },
            icon: Icon(Icons.list_alt_rounded, color: kBrandOlive, size: 22),
            tooltip: "View Allocated",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationForm(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("ALLOTMENT DETAILS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kBrandOrange, letterSpacing: 1.5)),
          const SizedBox(height: 32),

          _formLabel("SEARCH GRADUATED SCHOLAR"),
          _buildScholarDropdown(),
          const SizedBox(height: 24),

          if (isMobile) ...[
            _buildTextField("WORKPLACE NAME", _workplaceController, Icons.business_rounded),
            const SizedBox(height: 24),
            _buildTextField("LOCATION / DISTRICT", _locationController, Icons.place_rounded),
          ] else ...[
            Row(
              children: [
                Expanded(child: _buildTextField("WORKPLACE NAME", _workplaceController, Icons.business_rounded)),
                const SizedBox(width: 24),
                Expanded(child: _buildTextField("LOCATION / DISTRICT", _locationController, Icons.place_rounded)),
              ],
            ),
          ],
          const SizedBox(height: 24),

          if (isMobile) ...[
            _buildTextField("ASSIGNED SUPERVISOR", _supervisorController, Icons.person_pin_rounded),
            const SizedBox(height: 24),
            _buildTextField("CONTACT EMAIL", _emailController, Icons.alternate_email_rounded),
          ] else ...[
            Row(
              children: [
                Expanded(child: _buildTextField("ASSIGNED SUPERVISOR", _supervisorController, Icons.person_pin_rounded)),
                const SizedBox(width: 24),
                Expanded(child: _buildTextField("CONTACT EMAIL", _emailController, Icons.alternate_email_rounded)),
              ],
            ),
          ],
          const SizedBox(height: 24),

          if (isMobile) ...[
            _buildDatePicker("PLACEMENT START", _startDate, (d) => setState(() => _startDate = d)),
            const SizedBox(height: 24),
            _buildDatePicker("EXPECTED COMPLETION", _endDate, (d) => setState(() => _endDate = d)),
          ] else ...[
            Row(
              children: [
                Expanded(child: _buildDatePicker("PLACEMENT START", _startDate, (d) => setState(() => _startDate = d))),
                const SizedBox(width: 24),
                Expanded(child: _buildDatePicker("EXPECTED COMPLETION", _endDate, (d) => setState(() => _endDate = d))),
              ],
            ),
          ],
          const SizedBox(height: 24),

          _formLabel("PLACEMENT TERMS & NOTES"),
          TextField(
            controller: _detailsController,
            maxLines: 4,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              filled: true, fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(16),
              hintText: "Enter specific duties or scholarship terms...",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
            ),
          ),
          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitAllocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Text("SAVE & NOTIFY SCHOLAR", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScholarDropdown() {
    final unallocated = _graduates.where((g) => g['internship_status'] == null).toList();

    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (g) => "${g['full_name']} (${g['scholar_id']})",
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Map<String, dynamic>>.empty();
        }
        return unallocated.where((g) {
          return g['full_name'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                 g['scholar_id'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase());
        }).map((e) => e as Map<String, dynamic>);
      },
      onSelected: (v) {
        setState(() {
          _selectedGraduate = v;
          _emailController.text = v['email'] ?? '';
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: (v) => onFieldSubmitted(),
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kBrandOlive),
            filled: true, fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            hintText: "Type scholar name or ID...",
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400, fontWeight: FontWeight.normal),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: MediaQuery.of(context).size.width * (MediaQuery.of(context).size.width < 900 ? 0.8 : 0.4),
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade100),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final Map<String, dynamic> option = options.elementAt(index);
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    title: Text(option['full_name'] ?? 'N/A', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kBrandBrown)),
                    subtitle: Text("${option['scholar_id'] ?? 'N/A'} • ${option['display_school_name'] ?? 'N/A'}", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    hoverColor: kBrandOlive.withOpacity(0.05),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
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
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: kBrandOlive),
            filled: true, fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
            final picked = await showDatePicker(
              context: context, 
              initialDate: date, 
              firstDate: DateTime(2020), 
              lastDate: DateTime(2035),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(primary: kBrandBrown, onPrimary: Colors.white, onSurface: kBrandBrown),
                ),
                child: child!,
              ),
            );
            if (picked != null) onSelect(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 18, color: kBrandOlive),
                const SizedBox(width: 12),
                Text(DateFormat('dd MMMM yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.w700, color: kBrandBrown)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _formLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4),
    child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1.2)),
  );
}

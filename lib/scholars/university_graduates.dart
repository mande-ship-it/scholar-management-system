import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';
import 'package:intl/intl.dart';

class UniversityGraduatesComponent extends StatefulWidget {
  const UniversityGraduatesComponent({super.key});

  @override
  State<UniversityGraduatesComponent> createState() => _UniversityGraduatesComponentState();
}

class _UniversityGraduatesComponentState extends State<UniversityGraduatesComponent> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _graduates = [];
  List<dynamic> _alumni = [];
  List<dynamic> _filteredData = [];
  late TabController _tabController;

  // Filters
  String _selectedInstitution = 'All';
  String _selectedYear = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _applyFilters();
      }
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final responses = await Future.wait([
        ApiService.getUniversityGraduates(),
        ApiService.getAlumni(),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        if (mounted) {
          setState(() {
            _graduates = responses[0].data['data'];
            _alumni = responses[1].data['data'];
            _applyFilters();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching graduates/alumni: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final bool showingGraduates = _tabController.index == 0;
    final sourceList = showingGraduates ? _graduates : _alumni;

    setState(() {
      _filteredData = sourceList.where((g) {
        final matchesInstitution = _selectedInstitution == 'All' ||
            g['display_school_name'] == _selectedInstitution;
        final matchesYear = _selectedYear == 'All' ||
            g['end_year'].toString() == _selectedYear;
        final name = g['full_name'].toString().toLowerCase();
        final sid = g['scholar_id'].toString().toLowerCase();
        final matchesSearch = name.contains(_searchQuery.toLowerCase()) ||
                             sid.contains(_searchQuery.toLowerCase());

        return matchesInstitution && matchesYear && matchesSearch;
      }).toList();
    });
  }

  List<String> get _institutions {
    final bool showingGraduates = _tabController.index == 0;
    final sourceList = showingGraduates ? _graduates : _alumni;
    final set = sourceList.map((g) => g['display_school_name']?.toString() ?? 'N/A').toSet();
    return ['All', ...set.toList()..sort()];
  }

  List<String> get _graduatingYears {
    final bool showingGraduates = _tabController.index == 0;
    final sourceList = showingGraduates ? _graduates : _alumni;
    final set = sourceList.map((g) => g['end_year']?.toString() ?? 'N/A').toSet();
    final list = set.toList()..sort((a, b) => b.compareTo(a));
    return ['All', ...list];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfessionalHeader(),
          _buildControlPanel(),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
              : _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kBrandOlive.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: kBrandOlive, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Alumni & Graduates Registry",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
                    Text("Centralized database of scholars who have completed their university program cycle.",
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _fetchData,
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text("SYNC DATA"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: kBrandOlive,
              unselectedLabelColor: Colors.grey,
              indicatorColor: kBrandOlive,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: "GRADUATES (Pending Allocation)"),
                Tab(text: "ALUMNI (Allocated)"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildSearchField(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownFilter(
                label: "INSTITUTION",
                value: _selectedInstitution,
                items: _institutions,
                onChanged: (v) {
                  setState(() => _selectedInstitution = v!);
                  _applyFilters();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownFilter(
                label: "GRADUATION YEAR",
                value: _selectedYear,
                items: _graduatingYears,
                onChanged: (v) {
                  setState(() => _selectedYear = v!);
                  _applyFilters();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final bool showingGraduates = _tabController.index == 0;
    return TextField(
      onChanged: (v) {
        _searchQuery = v;
        _applyFilters();
      },
      decoration: InputDecoration(
        hintText: showingGraduates ? "Search graduates by name or Scholar ID..." : "Search alumni by name or Scholar ID...",
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kBrandOlive),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdownFilter({required String label, required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    if (_filteredData.isEmpty) return _buildEmptyState();

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTableHeader(),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredData.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                itemBuilder: (context, index) => _buildAlumniRow(_filteredData[index]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    final bool showingGraduates = _tabController.index == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFFF8F9FA),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(showingGraduates ? "GRADUATE INFORMATION" : "ALUMNI INFORMATION", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5))),
          Expanded(flex: 2, child: Text("PROGRAM & INSTITUTION", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5))),
          Expanded(child: Text("GRAD YEAR", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5))),
          Expanded(child: Text("STATUS", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5))),
        ],
      ),
    );
  }

  Widget _buildAlumniRow(dynamic g) {
    final bool showingGraduates = _tabController.index == 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Navigate to profile details if needed
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [kBrandBrown, Color(0xFF2C241D)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text((g['full_name']?.toString() ?? '?').isNotEmpty ? g['full_name'].toString()[0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g['full_name']?.toString() ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown, fontSize: 15)),
                        Text(g['scholar_id']?.toString() ?? 'N/A', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g['display_school_name'] ?? 'N/A', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black87)),
                    Text(g['program_name'] ?? 'N/A', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: kBrandBrown.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: Text("Class of ${g['end_year']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kBrandBrown)),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: showingGraduates ? kBrandOrange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle
                      ),
                      child: Icon(
                        showingGraduates ? Icons.school_rounded : Icons.verified_user_rounded,
                        color: showingGraduates ? kBrandOrange : Colors.green,
                        size: 14
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      showingGraduates ? "GRADUATE" : "ALUMNI",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: showingGraduates ? kBrandOrange : Colors.green,
                        letterSpacing: 0.5
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool showingGraduates = _tabController.index == 0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 20),
          Text(showingGraduates ? "No pending graduates found." : "No alumni records found.",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';
import 'package:intl/intl.dart';

class UniversityGraduatesComponent extends StatefulWidget {
  final VoidCallback? onBack;
  final bool showBackButton;
  const UniversityGraduatesComponent({super.key, this.onBack, this.showBackButton = true});

  @override
  State<UniversityGraduatesComponent> createState() => _UniversityGraduatesComponentState();
}

class _UniversityGraduatesComponentState extends State<UniversityGraduatesComponent> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _graduates = [];
  List<dynamic> _alumni = [];
  List<dynamic> _filteredData = [];
  late TabController _tabController;
  String _userRole = 'User';

  // Filters
  String _selectedInstitution = 'All';
  String _selectedYear = 'All';
  String _searchQuery = '';
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedInstitution = 'All';
          _selectedYear = 'All';
        });
        _applyFilters();
      }
    });
    _fetchData();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    try {
      final response = await ApiService.getAccountProfile();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && mounted) {
          setState(() {
            _userRole = data['role_name'] ?? 'User';
          });
        }
      }
    } catch (_) {}
  }

  bool get _canDelete {
    final String role = _userRole.toLowerCase();
    return ['administrator', 'program coordinator', 'country director'].contains(role);
  }

  Future<void> _deleteScholar(dynamic g) async {
    final scholarId = g['_id'] ?? g['id'];
    final name = g['full_name'] ?? g['fullName'] ?? 'Scholar';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Archive Record", style: TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown)),
        content: Text("Are you sure you want to permanently delete the records for $name? This will remove all academic history and personal data. This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Delete Permanently"),
          ),
        ],
      ),
    );

    if (confirm == true && scholarId != null) {
      setState(() => _isLoading = true);
      try {
        final res = await ApiService.deleteScholar(scholarId.toString());
        if (res.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Scholar record removed from archive."), backgroundColor: Colors.red),
          );
          _fetchData();
        }
      } catch (e) {
        debugPrint('Delete error: $e');
        if (mounted) setState(() => _isLoading = false);
      }
    }
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
            _graduates = responses[0].data['data'] ?? [];
            _alumni = responses[1].data['data'] ?? [];
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
        final scholarName = (g['full_name'] ?? g['fullName'] ?? 'N/A').toString();
        final schoolName = (g['display_school_name'] ?? g['schoolName'] ?? 'N/A').toString();
        final scholarId = (g['scholar_id'] ?? g['scholarId'] ?? '').toString();
        final endYearValue = (g['endYear'] ?? g['end_year'] ?? 'N/A').toString();
        
        final matchesInstitution = _selectedInstitution == 'All' ||
            schoolName == _selectedInstitution;
            
        final matchesYear = _selectedYear == 'All' ||
            endYearValue == _selectedYear;
            
        final matchesSearch = scholarName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                             scholarId.toLowerCase().contains(_searchQuery.toLowerCase());

        return matchesInstitution && matchesYear && matchesSearch;
      }).toList();
    });
  }

  List<String> get _institutions {
    final bool showingGraduates = _tabController.index == 0;
    final sourceList = showingGraduates ? _graduates : _alumni;
    final set = sourceList.map((g) => (g['display_school_name'] ?? g['schoolName'] ?? 'N/A').toString()).toSet();
    final list = set.where((s) => s != 'N/A').toList();
    list.sort();
    return ['All', ...list];
  }

  List<String> get _graduatingYears {
    final bool showingGraduates = _tabController.index == 0;
    final sourceList = showingGraduates ? _graduates : _alumni;
    final set = sourceList.map((g) => (g['endYear'] ?? g['end_year'] ?? 'N/A').toString()).toSet();
    final list = set.where((y) => y != 'N/A').toList();
    list.sort((a, b) => b.compareTo(a));
    return ['All', ...list];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfessionalHeader(isMobile),
          _buildTabNavigation(isMobile),
          _buildControlPanel(isMobile),
          Expanded(
            child: _isLoading
              ? const SizedBox.shrink()
              : _buildMainContent(isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalHeader(bool isMobile) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 12 : 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          if (widget.showBackButton) ...[
            IconButton(
              onPressed: widget.onBack ?? () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              },
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: kBrandBrown),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
          ],
          if (!_isSearchExpanded)
            Expanded(
              child: Text(
                "Alumni Registry",
                style: TextStyle(
                  fontSize: isVerySmall ? 13 : 16, 
                  fontWeight: FontWeight.w900, 
                  color: const Color(0xFF4C3C32), 
                  letterSpacing: -0.2
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          _buildSearchField(),
          if (!_isSearchExpanded) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: _fetchData,
              icon: Icon(Icons.refresh_rounded, color: kBrandOlive, size: 22),
              tooltip: "Sync Registry",
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabNavigation(bool isMobile) {
    final bool isVerySmall = MediaQuery.of(context).size.width < 500;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: kBrandOlive,
          unselectedLabelColor: Colors.grey,
          indicatorColor: kBrandOlive,
          indicatorWeight: 2,
          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: isVerySmall ? 11 : 12),
          tabs: [
            Tab(text: "GRADUATES", height: isVerySmall ? 40 : 48),
            Tab(text: "ALUMNI", height: isVerySmall ? 40 : 48),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel(bool isMobile) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 32, 24, isMobile ? 16 : 32, 24),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: isMobile 
          ? Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 16),
                Row(
                  children: [
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdownFilter(
                        label: "GRAD YEAR",
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
              ],
            )
          : Row(
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
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    if (!_isSearchExpanded) {
      return IconButton(
        onPressed: () => setState(() => _isSearchExpanded = true),
        icon: const Icon(Icons.search, color: kBrandBrown),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFF8F9FA),
          padding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
      );
    }

    return Container(
      width: isMobile ? double.infinity : 320,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: TextField(
        onChanged: (v) {
          _searchQuery = v;
          _applyFilters();
        },
        autofocus: true,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: showingGraduates ? "Search graduates..." : "Search alumni...",
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: kBrandOlive),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, size: 18), 
            onPressed: () => setState(() {
              _isSearchExpanded = false;
              _searchQuery = '';
              _applyFilters();
            }),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
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

  Widget _buildMainContent(bool isMobile) {
    if (_filteredData.isEmpty) return _buildEmptyState();

    return Padding(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 32, 0, isMobile ? 16 : 32, 32),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isMobile) _buildTableHeader(),
            Expanded(
              child: ListView.separated(
                itemCount: _filteredData.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                itemBuilder: (context, index) => _buildAlumniRow(_filteredData[index], isMobile),
              ),
            ),
          ],
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

  Widget _buildAlumniRow(dynamic g, bool isMobile) {
    final bool showingGraduates = _tabController.index == 0;
    final scholarName = g['full_name'] ?? g['fullName'] ?? 'N/A';
    final scholarId = g['scholar_id'] ?? g['scholarId'] ?? 'N/A';
    final schoolName = g['display_school_name'] ?? g['schoolName'] ?? 'N/A';
    final programName = g['program_name'] ?? g['programName'] ?? 'N/A';
    final endYear = g['endYear'] ?? g['end_year'] ?? 'N/A';

    if (isMobile) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [kBrandBrown, Color(0xFF2C241D)]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text((scholarName.toString()).isNotEmpty ? scholarName.toString()[0] : '?', 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(scholarName.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown, fontSize: 14)),
                          Text(scholarId.toString(), style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    _statusLabel(showingGraduates),
                    if (_canDelete)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey),
                        onSelected: (val) {
                          if (val == 'delete') _deleteScholar(g);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete', 
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text("Delete Record", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                            )
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.school_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(schoolName.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black87)),
                          Text(programName.toString(), style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: kBrandBrown.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
                  child: Text("Class of $endYear", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                      child: Text((scholarName.toString()).isNotEmpty ? scholarName.toString()[0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scholarName.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBrown, fontSize: 15)),
                        Text(scholarId.toString(), style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w700)),
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
                    Text(schoolName.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black87)),
                    Text(programName.toString(), style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: kBrandBrown.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: Text("Class of $endYear", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kBrandBrown)),
                ),
              ),
              Expanded(
                child: _statusLabel(showingGraduates),
              ),
              if (_canDelete)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                  onPressed: () => _deleteScholar(g),
                  tooltip: "Delete Record",
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusLabel(bool showingGraduates) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
          Text(showingGraduates ? "No university graduates found." : "No alumni records found.",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey)),
          const SizedBox(height: 8),
          Text("Registry synchronization status: ${_isLoading ? 'Loading...' : 'Online'}",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

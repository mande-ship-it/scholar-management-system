import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'scholar_attendance.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';
import '../widgets/custom_loaders.dart';

class AttendanceHistoryComponent extends StatefulWidget {
  const AttendanceHistoryComponent({super.key});

  @override
  State<AttendanceHistoryComponent> createState() => _AttendanceHistoryComponentState();
}

class _AttendanceHistoryComponentState extends State<AttendanceHistoryComponent> {
  String? _filterSchool;
  AttendanceModuleType? _filterType;
  bool _isLoading = true;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAttendanceHistory(
        type: _filterType?.label,
        schoolName: _filterSchool,
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _history = response.data['data'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching attendance history: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isMobile) _buildProfessionalHeader(isMobile),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(isMobile ? 0 : 40, isMobile ? 16 : 24, isMobile ? 0 : 40, 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 0),
                        child: _buildFilterBar(isMobile),
                      ),
                      const SizedBox(height: 32),
                      if (_isLoading)
                        Center(child: Padding(padding: const EdgeInsets.all(100), child: BeautifulLoader(isOverlay: false, message: "Retrieving Archive Data")))
                      else if (_history.isEmpty)
                        _buildEmptyState(isMobile)
                      else
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 0),
                          child: _buildHistoryList(isMobile),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalHeader(bool isMobile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : Colors.white,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kBrandBrown.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.history_edu_rounded, color: kBrandBrown, size: 20),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Attendance Archives",
                  style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : kBrandBrown, letterSpacing: -0.2)),
                const Text("Historical program engagement.",
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() {
              _filterType = null;
              _filterSchool = null;
              _fetchHistory();
            }),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.white12 : Colors.grey.shade100,
              padding: const EdgeInsets.all(8),
            ),
            icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white : kBrandBrown, size: 18),
            tooltip: "Reload Archives",
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isMobile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: isMobile 
        ? Column(
            children: [
              _dropdownFilter("MODULE", _filterType, [
                const DropdownMenuItem(value: null, child: Text("All Modules")),
                ...AttendanceModuleType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))),
              ], (v) {
                setState(() => _filterType = v);
                _fetchHistory();
              }),
              const SizedBox(height: 16),
              _textFilter("INSTITUTION", Icons.search_rounded, "Search school or partner...", (v) {
                setState(() => _filterSchool = v.isEmpty ? null : v);
                _fetchHistory();
              }),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: _dropdownFilter("MODULE", _filterType, [
                  const DropdownMenuItem(value: null, child: Text("All Modules")),
                  ...AttendanceModuleType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))),
                ], (v) {
                  setState(() => _filterType = v);
                  _fetchHistory();
                }),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _textFilter("INSTITUTION", Icons.search_rounded, "Search school or partner...", (v) {
                  setState(() => _filterSchool = v.isEmpty ? null : v);
                  _fetchHistory();
                }),
              ),
            ],
          ),
    );
  }

  Widget _dropdownFilter(String label, dynamic value, List<DropdownMenuItem<AttendanceModuleType>> items, ValueChanged<AttendanceModuleType?> onChanged) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AttendanceModuleType>(
              value: value,
              isExpanded: true,
              dropdownColor: theme.cardColor,
              items: items,
              onChanged: onChanged,
              style: TextStyle(color: isDark ? Colors.white : kBrandBrown, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _textFilter(String label, IconData icon, String hint, ValueChanged<String> onChanged) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dividerColor),
          ),
          child: TextField(
            onChanged: onChanged,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : kBrandBrown, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white24 : Colors.grey),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              icon: Icon(icon, size: 18, color: kBrandOlive),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(bool isMobile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("ARCHIVED LOGS (${_history.length})",
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
            if (!isMobile)
              Text("Sort: Chronological Recency",
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey.shade500, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 24),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _history.length,
          separatorBuilder: (_, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final item = _history[index];
            final typeLabel = item['type'] ?? 'CHATs';
            final moduleType = typeLabel == 'CHATs' ? AttendanceModuleType.chats : AttendanceModuleType.studyCircle;
            final String dateStr = item['session_date'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(item['session_date'])) : 'N/A';

            if (isMobile) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(moduleType.icon, color: kBrandOlive, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['display_school_name'] ?? item['school_name'] ?? 'N/A', 
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : kBrandBrown)),
                              Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Facilitator", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey.shade500)),
                            Text(item['facilitator'] ?? 'N/A', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : kBrandBrown, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text("${item['present_count'] ?? 0}/${item['total_count'] ?? 0} PRESENT", 
                            style: const TextStyle(fontWeight: FontWeight.w900, color: kBrandOlive, fontSize: 10)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: kBrandOlive.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(moduleType.icon, color: kBrandOlive, size: 24),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['display_school_name'] ?? item['school_name'] ?? 'N/A', 
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : kBrandBrown)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text("Facilitator: ${item['facilitator'] ?? 'N/A'}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateStr, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : kBrandBrown, letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: kBrandBrown.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                          child: Text(moduleType.label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: 1.0)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("${item['present_count'] ?? 0}/${item['total_count'] ?? 0}", 
                        style: TextStyle(fontWeight: FontWeight.w900, color: kBrandOlive, fontSize: 22, letterSpacing: -1)),
                      const Text("QUORUM", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? Colors.white24 : Colors.grey.shade300),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isMobile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 60 : 100),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(Icons.history_toggle_off_rounded, size: isMobile ? 48 : 64, color: isDark ? Colors.white12 : Colors.grey.shade200),
          const SizedBox(height: 24),
          Text("No attendance archives found",
            style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

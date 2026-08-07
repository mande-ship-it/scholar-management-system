import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../academics/academics_utils.dart';
import 'package:scholar_management_system/services/api_service.dart';

class AllocationListPage extends StatefulWidget {
  const AllocationListPage({super.key});

  @override
  State<AllocationListPage> createState() => _AllocationListPageState();
}

class _AllocationListPageState extends State<AllocationListPage> {
  bool _isLoading = true;
  List<dynamic> _internships = [];
  List<dynamic> _filteredInternships = [];
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchInternships();
  }

  Future<void> _fetchInternships() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getAllInternships();
      if (mounted) {
        setState(() {
          _internships = response.data['data'] ?? [];
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching internships: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredInternships = _internships.where((i) {
        final name = (i['scholar_name'] ?? (i['scholarId'] != null ? i['scholarId']['fullName'] ?? i['scholarId']['full_name'] : 'N/A')).toString().toLowerCase();
        final workplace = (i['workplace_name'] ?? i['workplaceName'] ?? 'N/A').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || workplace.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Search allocated scholars...",
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                filled: false,
              ),
              onChanged: (v) {
                _searchQuery = v;
                _applyFilter();
              },
            )
          : const Text("Allocated Scholars"),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _applyFilter();
                }
              });
            },
          ),
          IconButton(onPressed: _fetchInternships, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kBrandOlive))
          : _filteredInternships.isEmpty
              ? const Center(child: Text("No allocations found."))
              : ListView.separated(
                  padding: EdgeInsets.all(isMobile ? 16 : 32),
                  itemCount: _filteredInternships.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => _allocationCard(_filteredInternships[index]),
                ),
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
      }
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCompleted ? Colors.grey.shade100 : kBrandOlive.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(scholarName.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 4),
          Text(workplace.toString(),
            style: const TextStyle(color: kBrandOrange, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text(durationStr,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const Spacer(),
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(i['location'] ?? 'N/A', style: const TextStyle(fontSize: 12)),
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
      decoration: BoxDecoration(color: active ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: active ? Colors.green : Colors.grey, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }
}

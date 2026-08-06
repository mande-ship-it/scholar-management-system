import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class ApprovalsPage extends StatefulWidget {
  final String? userRole;
  const ApprovalsPage({super.key, this.userRole});

  @override
  State<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends State<ApprovalsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<dynamic> _pendingScholars = [];
  List<dynamic> _pendingEvents = [];
  List<dynamic> _pendingPayments = [];

  final Color brandBrown = const Color(0xFF4C3C32);
  final Color brandOlive = const Color(0xFF9AB334);
  final Color brandOrange = const Color(0xFFE05B1C);

  bool get _canApproveScholars {
    final role = widget.userRole?.toLowerCase() ?? '';
    return role == 'administrator' ||
           role == 'admin' ||
           role == 'country director' ||
           role == 'program coordinator' ||
           role == 'program manager';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _canApproveScholars ? 2 : 1, vsync: this);
    _fetchPending();
  }

  Future<void> _fetchPending() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getPendingActivities();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        setState(() {
          _pendingScholars = data['scholars'] ?? [];
          _pendingEvents = data['events'] ?? [];
          _pendingPayments = data['payments'] ?? [];
        });
      }
    } catch (e) {
      _showError("Failed to load pending activities: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processApproval(String type, String id, bool approve) async {
    try {
      final response = approve
        ? await ApiService.approveActivity(type, id)
        : await ApiService.rejectActivity(type, id);

      if (response.statusCode == 200) {
        _showSuccess("${approve ? 'Approved' : 'Rejected'} successfully.");
        _fetchPending();
      }
    } catch (e) {
      _showError("Action failed: $e");
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: brandOlive, behavior: SnackBarBehavior.floating),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Pending Approvals", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 18 : 20)),
        backgroundColor: Colors.white,
        foregroundColor: brandBrown,
        elevation: 0,
        actions: [
          IconButton(onPressed: _fetchPending, icon: const Icon(Icons.refresh, size: 20)),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: brandBrown,
          indicatorColor: brandOlive,
          labelStyle: TextStyle(fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.bold),
          tabs: [
            if (_canApproveScholars) Tab(text: "Scholars (${_pendingScholars.length})"),
            Tab(text: "Events (${_pendingEvents.length})"),
          ],
        ),
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator(color: brandOlive))
        : TabBarView(
            controller: _tabController,
            children: [
              if (_canApproveScholars) _buildScholarsList(isMobile),
              _buildEventsList(isMobile),
            ],
          ),
    );
  }

  Widget _buildScholarsList(bool isMobile) {
    if (_pendingScholars.isEmpty) return _buildEmptyState("No scholars awaiting approval.");

    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      itemCount: _pendingScholars.length,
      itemBuilder: (context, index) {
        final scholar = _pendingScholars[index];
        final id = (scholar['id'] ?? scholar['_id'] ?? '').toString();
        final name = scholar['fullName'] ?? scholar['full_name'] ?? 'Unknown Scholar';
        final scholarIdStr = scholar['scholarId'] ?? scholar['scholar_id'] ?? 'Pending';
        final school = scholar['schoolName'] ?? scholar['school_name'] ?? 'No School';

        String createdStr = 'N/A';
        try {
          final date = scholar['createdAt'] ?? scholar['created_at'];
          if (date != null) createdStr = DateFormat('dd MMM yyyy').format(DateTime.parse(date));
        } catch (_) {}

        return _buildApprovalCard(
          isMobile: isMobile,
          title: name,
          subtitle: "ID: $scholarIdStr • $school",
          details: "Registered on: $createdStr",
          onApprove: () => _processApproval('scholar', id, true),
          onReject: () => _processApproval('scholar', id, false),
        );
      },
    );
  }

  Widget _buildEventsList(bool isMobile) {
    if (_pendingEvents.isEmpty) return _buildEmptyState("No events awaiting approval.");

    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      itemCount: _pendingEvents.length,
      itemBuilder: (context, index) {
        final event = _pendingEvents[index];
        final id = (event['id'] ?? event['_id'] ?? '').toString();
        final title = event['title'] ?? 'Unknown Event';
        final category = event['category'] ?? 'General';
        final location = event['location'] ?? 'N/A';
        final time = event['eventTime'] ?? event['time'] ?? 'N/A';

        String dateStr = 'N/A';
        try {
          final date = event['eventDate'] ?? event['date'];
          if (date != null) dateStr = DateFormat('dd MMM yyyy').format(DateTime.parse(date));
        } catch (_) {}

        return _buildApprovalCard(
          isMobile: isMobile,
          title: title,
          subtitle: "$category • $location",
          details: "Scheduled for: $dateStr at $time",
          onApprove: () => _processApproval('event', id, true),
          onReject: () => _processApproval('event', id, false),
        );
      },
    );
  }

  Widget _buildApprovalCard({
    required String title,
    required String subtitle,
    required String details,
    required VoidCallback onApprove,
    required VoidCallback onReject,
    bool isMobile = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.all(isMobile ? 16 : 20),
            title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 18)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(subtitle, style: TextStyle(color: brandBrown, fontWeight: FontWeight.w600, fontSize: isMobile ? 12 : 14)),
                const SizedBox(height: 4),
                Text(details, style: TextStyle(color: Colors.grey.shade600, fontSize: isMobile ? 11 : 13)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                  label: Text("REJECT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: isMobile ? 11 : 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 18),
                  label: Text("APPROVE", style: TextStyle(fontSize: isMobile ? 11 : 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandOlive,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 10 : 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }
}

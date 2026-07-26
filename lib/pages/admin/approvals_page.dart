import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class ApprovalsPage extends StatefulWidget {
  const ApprovalsPage({super.key});

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Pending Approvals", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: brandBrown,
        elevation: 0,
        actions: [
          IconButton(onPressed: _fetchPending, icon: const Icon(Icons.refresh)),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: brandBrown,
          indicatorColor: brandOlive,
          tabs: [
            Tab(text: "Scholars (${_pendingScholars.length})"),
            Tab(text: "Events (${_pendingEvents.length})"),
            Tab(text: "Payments (${_pendingPayments.length})"),
          ],
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildScholarsList(),
              _buildEventsList(),
              _buildPaymentsList(),
            ],
          ),
    );
  }

  Widget _buildScholarsList() {
    if (_pendingScholars.isEmpty) return _buildEmptyState("No scholars awaiting approval.");

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingScholars.length,
      itemBuilder: (context, index) {
        final scholar = _pendingScholars[index];
        return _buildApprovalCard(
          title: scholar['full_name'] ?? 'Unknown Scholar',
          subtitle: "ID: ${scholar['scholar_id'] ?? 'Pending'} • ${scholar['display_school_name'] ?? 'No School'}",
          details: "Registered on: ${DateFormat('dd MMM yyyy').format(DateTime.parse(scholar['created_at']))}",
          onApprove: () => _processApproval('scholar', scholar['id'].toString(), true),
          onReject: () => _processApproval('scholar', scholar['id'].toString(), false),
        );
      },
    );
  }

  Widget _buildEventsList() {
    if (_pendingEvents.isEmpty) return _buildEmptyState("No events awaiting approval.");

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingEvents.length,
      itemBuilder: (context, index) {
        final event = _pendingEvents[index];
        return _buildApprovalCard(
          title: event['title'] ?? 'Unknown Event',
          subtitle: "${event['category']} • ${event['location']}",
          details: "Scheduled for: ${DateFormat('dd MMM yyyy').format(DateTime.parse(event['date']))} at ${event['time']}",
          onApprove: () => _processApproval('event', event['id'].toString(), true),
          onReject: () => _processApproval('event', event['id'].toString(), false),
        );
      },
    );
  }

  Widget _buildPaymentsList() {
    if (_pendingPayments.isEmpty) return _buildEmptyState("No payments awaiting approval.");

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingPayments.length,
      itemBuilder: (context, index) {
        final payment = _pendingPayments[index];
        return _buildApprovalCard(
          title: "MWK ${payment['amount']}",
          subtitle: "Scholar: ${payment['scholar_name']} (${payment['scholar_id_str']})",
          details: "Purpose: ${payment['purpose']} • Requested: ${DateFormat('dd MMM yyyy').format(DateTime.parse(payment['created_at']))}",
          onApprove: () => _processApproval('payment', payment['id'].toString(), true),
          onReject: () => _processApproval('payment', payment['id'].toString(), false),
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(20),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(subtitle, style: TextStyle(color: brandBrown, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(details, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  label: const Text("REJECT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check),
                  label: const Text("APPROVE"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandOlive,
                    foregroundColor: Colors.white,
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

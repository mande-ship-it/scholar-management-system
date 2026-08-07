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

  // Brand Color Palette
  static const Color brandBrown = Color(0xFF4C3C32);
  static const Color brandCream = Color(0xFFFAF2DB);
  static const Color brandOlive = Color(0xFF9AB334);
  static const Color brandOrange = Color(0xFFE05B1C);

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
    _tabController = TabController(length: _canApproveScholars ? 3 : 2, vsync: this);
    _fetchPending();
  }

  Future<void> _fetchPending() async {
    if (!mounted) return;
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
      _showError("Failed to load pending activities.");
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
      } else {
        _showError(response.data['message'] ?? "Action failed.");
      }
    } catch (e) {
      _showError("An error occurred. Please try again.");
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: brandOlive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 12 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildTabs(isMobile),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: brandOlive))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        if (_canApproveScholars) _buildScholarsList(isMobile),
                        _buildEventsList(isMobile),
                        _buildPaymentsList(isMobile),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pending Approvals",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: brandBrown,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _fetchPending,
          icon: const Icon(Icons.refresh_rounded, color: brandBrown, size: 20),
          tooltip: "Refresh",
        ),
      ],
    );
  }

  Widget _buildTabs(bool isMobile) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: brandBrown,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: [
          if (_canApproveScholars) Tab(text: "Scholars (${_pendingScholars.length})"),
          Tab(text: "Events (${_pendingEvents.length})"),
          Tab(text: "Payments (${_pendingPayments.length})"),
        ],
      ),
    );
  }

  Widget _buildScholarsList(bool isMobile) {
    if (_pendingScholars.isEmpty) return _buildEmptyState("No scholars awaiting approval.");

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
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
          icon: Icons.person_add_alt_1_rounded,
        );
      },
    );
  }

  Widget _buildEventsList(bool isMobile) {
    if (_pendingEvents.isEmpty) return _buildEmptyState("No events awaiting approval.");

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
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
          icon: Icons.event_available_rounded,
        );
      },
    );
  }

  Widget _buildPaymentsList(bool isMobile) {
    if (_pendingPayments.isEmpty) return _buildEmptyState("No payments awaiting approval.");

    final currencyFormat = NumberFormat.currency(symbol: 'MWK ', decimalDigits: 0);

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: _pendingPayments.length,
      itemBuilder: (context, index) {
        final payment = _pendingPayments[index];
        final id = (payment['id'] ?? payment['_id'] ?? '').toString();
        final amount = double.tryParse(payment['amount']?.toString() ?? '0') ?? 0;
        final purpose = payment['purpose'] ?? 'General Disbursement';
        final scholar = payment['scholarId'] != null ? (payment['scholarId']['fullName'] ?? 'Scholar') : 'Unassigned';

        String dateStr = 'N/A';
        try {
          final date = payment['paymentDate'] ?? payment['date'] ?? payment['created_at'];
          if (date != null) dateStr = DateFormat('dd MMM yyyy').format(DateTime.parse(date));
        } catch (_) {}

        return _buildApprovalCard(
          isMobile: isMobile,
          title: scholar,
          subtitle: "${currencyFormat.format(amount)} • $purpose",
          details: "Requested on: $dateStr",
          onApprove: () => _processApproval('payment', id, true),
          onReject: () => _processApproval('payment', id, false),
          icon: Icons.payments_rounded,
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
    required IconData icon,
    bool isMobile = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: brandOlive.withOpacity(0.1),
                  child: Icon(icon, color: brandOlive, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: brandBrown,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: brandBrown,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        details,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded, color: brandOrange, size: 18),
                  label: const Text(
                    "REJECT",
                    style: TextStyle(
                      color: brandOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text(
                    "APPROVE",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandOlive,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            msg,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

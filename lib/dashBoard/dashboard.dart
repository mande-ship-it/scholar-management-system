import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'statistics.dart';
import 'package:scholar_management_system/services/api_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../academics/academics_utils.dart';

class DashboardComponent extends StatefulWidget {
  final Function(String)? onNavigate;
  final String? userRole;
  const DashboardComponent({super.key, this.onNavigate, this.userRole});

  @override
  State<DashboardComponent> createState() => _DashboardComponentState();
}

class _DashboardComponentState extends State<DashboardComponent> with TickerProviderStateMixin {
  bool _isLoading = true;
  String _selectedLevel = 'University';
  List<dynamic> _approvals = [];
  int _pendingCount = 0;
  bool _showApprovalsPanel = false;
  IO.Socket? _socket;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Faster pulse for higher alert
    )..repeat(reverse: true);
    _fetchSummary();
    _initSocket();
  }

  void _initSocket() {
    try {
      _socket = IO.io('http://localhost:5000', IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build());
      _socket!.connect();
      _socket!.on('notification', (_) => _fetchSummary());
    } catch (e) {
      debugPrint('Socket error: $e');
    }
  }

  Future<void> _fetchSummary() async {
    try {
      final response = await ApiService.getDashboardStats(level: _selectedLevel);
      if (response.statusCode == 200 && mounted) {
        final data = response.data['data'];
        setState(() {
          _approvals = data['approvals'] ?? [];
          _pendingCount = data['pendingCount'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: Stack(
        children: [
          Column(
            children: [
              _buildCleanHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      _buildQuickActions(),
                      if (widget.userRole == 'Administrator') ...[
                        const SizedBox(height: 24),
                        _buildAdminControlPanel(),
                      ],
                      const SizedBox(height: 24),
                      StatisticsComponent(level: _selectedLevel),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showApprovalsPanel) _buildApprovalsOverlay(),
        ],
      ),
    );
  }

  Widget _buildCleanHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("PROGRAM ANALYTICS", 
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1.2)),
              const SizedBox(height: 2),
              Text("$_selectedLevel Overview", 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
            ],
          ),
          Row(
            children: [
              _buildLevelToggle(),
              const SizedBox(width: 16),
              _buildAIQuickAccess(),
              const SizedBox(width: 16),
              _buildStatusApprovalIndicator(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIQuickAccess() {
    return GestureDetector(
      onTap: () => widget.onNavigate?.call("AI Assistant"),
      child: Tooltip(
        message: "Launch AI Strategy Assistant",
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: kBrandOlive.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: kBrandOlive.withOpacity(0.2), width: 1.5),
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: kBrandOlive, size: 20),
        ),
      ),
    );
  }

  Widget _buildLevelToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _toggleBtn("University"),
          _toggleBtn("Secondary"),
        ],
      ),
    );
  }

  Widget _toggleBtn(String level) {
    final bool isSelected = _selectedLevel == level;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedLevel = level);
        _fetchSummary();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? kBrandOlive : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          level,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusApprovalIndicator() {
    final bool hasPending = _pendingCount > 0;
    return GestureDetector(
      onTap: () => setState(() => _showApprovalsPanel = !_showApprovalsPanel),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          // Rapidly changing colors for "alert" state when pending
          Color iconColor = kBrandOlive;
          if (hasPending) {
            // Cycle through red, orange, and deep orange
            if (_pulseController.value < 0.33) {
              iconColor = Colors.red;
            } else if (_pulseController.value < 0.66) {
              iconColor = kBrandOrange;
            } else {
              iconColor = Colors.deepOrange;
            }
          }
          
          return Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withOpacity(hasPending ? 0.8 : 0.2),
                width: 2
              ),
              boxShadow: hasPending ? [
                BoxShadow(
                  color: iconColor.withOpacity(0.4 * _pulseController.value),
                  blurRadius: 12 * _pulseController.value,
                  spreadRadius: 4 * _pulseController.value,
                )
              ] : null,
            ),
            child: Icon(
              hasPending ? Icons.notification_important_rounded : Icons.verified_user_rounded,
              color: iconColor, 
              size: 22
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _actionBtn("View Scholars", Icons.people_outline_rounded, kBrandBrown),
        const SizedBox(width: 14),
        _actionBtn("Academics", Icons.school_outlined, kBrandOlive),
      ],
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color) {
    String target = label == "View Scholars" ? "View Scholars" : "View Results";

    return Expanded(
      child: InkWell(
        onTap: () => widget.onNavigate?.call(target),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2), width: 1.2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: -0.2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminControlPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kBrandBrown,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: kBrandBrown.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ADMINISTRATIVE HUB",
                    style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  SizedBox(height: 4),
                  Text("System Overview & Approvals",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => widget.onNavigate?.call("Pending Approvals"),
                icon: const Icon(Icons.rule_rounded, size: 16),
                label: const Text("ACCESS APPROVALS"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandOlive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _adminStat("Pending Records", _pendingCount.toString(), Icons.pending_actions_rounded),
              _adminStat("Security Alerts", "0", Icons.security_rounded),
              _adminStat("Backup Status", "Healthy", Icons.cloud_done_rounded),
              _adminStat("AI Confidence", "98%", Icons.psychology_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adminStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalsOverlay() {
    return Positioned(
      top: 100,
      right: 32,
      child: Container(
        width: 340,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: kBrandBrown),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Pending Approvals ($_pendingCount)", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  GestureDetector(
                    onTap: () => setState(() => _showApprovalsPanel = false),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
            if (_approvals.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: Text("No actions pending.", style: TextStyle(color: Colors.grey, fontSize: 13))))
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _approvals.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final a = _approvals[index];
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a['title'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text(a['desc'] ?? '', style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                          const SizedBox(height: 3),
                          Text(a['time'] ?? '', style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    setState(() => _showApprovalsPanel = false);
                    widget.onNavigate?.call("Pending Approvals");
                  },
                  child: const Text("VIEW ALL APPROVALS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kBrandOlive)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

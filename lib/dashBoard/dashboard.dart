import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      _socket = IO.io(ApiService.baseUrl, IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .build());
      
      _socket!.on('notification', (_) {
        if (mounted) _fetchSummary();
      });
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
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Column(
            children: [
              _buildPortalHeader(isSmallScreen),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 32,
                    vertical: isSmallScreen ? 16 : 32
                  ),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Column(
                        children: [
                          _buildQuickActions(isSmallScreen),
                          if (widget.userRole == 'Administrator') ...[
                            const SizedBox(height: 32),
                            _buildAdminExecutivePanel(isSmallScreen),
                          ],
                          const SizedBox(height: 32),
                          StatisticsComponent(level: _selectedLevel),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showApprovalsPanel) _buildApprovalsOverlay(isMobile),
        ],
      ),
    );
  }

  Widget _buildPortalHeader(bool isSmallScreen) {
    if (isSmallScreen) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildLevelToggle(true),
            ),
            _buildStatusApprovalIndicator(),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("PROGRAM ANALYTICS", 
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF9AB334), letterSpacing: 1.5)),
                const SizedBox(height: 2),
                Text("$_selectedLevel Dashboard",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4C3C32),
                    letterSpacing: -0.5
                  )),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildLevelToggle(false),
          const SizedBox(width: 12),
          _buildStatusApprovalIndicator(),
        ],
      ),
    );
  }


  Widget _buildLevelToggle(bool isSmall) {
    return Container(
      width: isSmall ? double.infinity : null,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        mainAxisSize: isSmall ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          isSmall ? Expanded(child: _toggleBtn("University", isSmall)) : _toggleBtn("University", isSmall),
          const SizedBox(width: 4),
          isSmall ? Expanded(child: _toggleBtn("Secondary", isSmall)) : _toggleBtn("Secondary", isSmall),
        ],
      ),
    );
  }

  Widget _toggleBtn(String level, bool isSmall) {
    final bool isSelected = _selectedLevel == level;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedLevel = level);
        _fetchSummary();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 4 : 16, 
          vertical: isSmall ? 10 : 8
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4C3C32) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            isSmall ? "${level.toUpperCase()} DASHBOARD" : level.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmall ? 11 : 10,
              fontWeight: FontWeight.w900,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              letterSpacing: isSmall ? 0.2 : 0.5,
            ),
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

  Widget _buildQuickActions(bool isSmallScreen) {
    final actions = [
      ("Scholars Registry", Icons.people_outline_rounded, kBrandBrown, "View Scholars"),
      ("Academic Records", Icons.school_outlined, kBrandOlive, "View Results"),
      ("Session Attendance", Icons.forum_rounded, kBrandOrange, "Scholar Attendance"),
      ("Program Events", Icons.event_available_rounded, const Color(0xFF1976D2), "Events & Programs"),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 2 : 4,
        crossAxisSpacing: isSmallScreen ? 12 : 20,
        mainAxisSpacing: isSmallScreen ? 12 : 20,
        childAspectRatio: isSmallScreen ? 1.1 : 1.6,
      ),
      itemCount: actions.length,
      itemBuilder: (context, i) => _buildPortalActionCard(
        actions[i].$1, 
        actions[i].$2, 
        actions[i].$3, 
        actions[i].$4,
        isSmallScreen
      ),
    );
  }

  Widget _buildPortalActionCard(String label, IconData icon, Color color, String target, bool isSmallScreen) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          if (target == "Scholar Attendance") {
            Navigator.pushNamed(context, '/scholarAttendance', arguments: {
              'forcedSchoolType': SchoolType.university,
              'forcedModuleType': 'chats'
            });
          } else {
            widget.onNavigate?.call(target);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: isSmallScreen 
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF4C3C32),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4C3C32),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildAdminExecutivePanel(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
      decoration: BoxDecoration(
        color: const Color(0xFF4C3C32),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Color(0xFF4C3C32).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isSmallScreen 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("SYSTEM CONTROL CENTER",
                    style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                  const SizedBox(height: 6),
                  const Text("Executive Operations",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onNavigate?.call("Pending Approvals"),
                      icon: const Icon(Icons.rule_folder_rounded, size: 14),
                      label: const Text("ACCESS REGISTRY", style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9AB334),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("SYSTEM CONTROL CENTER",
                          style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                        SizedBox(height: 6),
                        Text("Executive Operations Overview",
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => widget.onNavigate?.call("Pending Approvals"),
                    icon: const Icon(Icons.rule_folder_rounded, size: 16),
                    label: const Text("ACCESS REGISTRY"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9AB334),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
          SizedBox(height: isSmallScreen ? 24 : 40),
          isSmallScreen 
            ? GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _adminExecutiveStat("Pending", _pendingCount.toString(), Icons.pending_actions_rounded, true),
                  _adminExecutiveStat("Security", "Secured", Icons.verified_user_rounded, true),
                  _adminExecutiveStat("Continuity", "Healthy", Icons.cloud_done_rounded, true),
                  _adminExecutiveStat("Confidence", "98%", Icons.psychology_rounded, true),
                ],
              )
            : Row(
                children: [
                  _adminExecutiveStat("Pending", _pendingCount.toString(), Icons.pending_actions_rounded, false),
                  const SizedBox(width: 24),
                  _adminExecutiveStat("Security", "Secured", Icons.verified_user_rounded, false),
                  const SizedBox(width: 24),
                  _adminExecutiveStat("Continuity", "Healthy", Icons.cloud_done_rounded, false),
                  const SizedBox(width: 24),
                  _adminExecutiveStat("Confidence", "98%", Icons.psychology_rounded, false),
                ],
              ),
        ],
      ),
    );
  }

  Widget _adminExecutiveStat(String label, String value, IconData icon, bool isSmall) {
    final content = _buildStatContainer(label, value, icon, isSmall);
    return isSmall ? content : Expanded(child: content);
  }

  Widget _buildStatContainer(String label, String value, IconData icon, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: isSmall ? 14 : 18),
          ),
          SizedBox(width: isSmall ? 8 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, 
                  style: TextStyle(color: Colors.white, fontSize: isSmall ? 14 : 18, fontWeight: FontWeight.w900, letterSpacing: -0.5), 
                  overflow: TextOverflow.ellipsis),
                Text(label.toUpperCase(), 
                  style: TextStyle(color: Colors.white38, fontSize: isSmall ? 7 : 9, fontWeight: FontWeight.w900, letterSpacing: 1.0), 
                  overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalsOverlay(bool isMobile) {
    return Positioned(
      top: 100,
      right: isMobile ? 16 : 32,
      left: isMobile ? 16 : null,
      child: Container(
        width: isMobile ? null : 340,
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _approvals.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final a = _approvals[index];
                      final timeStr = _formatTime(a['time']);
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a['title'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            Text(a['desc'] ?? '', style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                            const SizedBox(height: 3),
                            Text(timeStr, style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
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

  String _formatTime(String? dateStr) {
    if (dateStr == null) return "Action Required";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return "Just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "${diff.inHours}h ago";
      return DateFormat('dd MMM').format(date);
    } catch (_) {
      return "Action Required";
    }
  }

}

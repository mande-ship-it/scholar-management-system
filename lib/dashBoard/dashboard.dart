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
      backgroundColor: const Color(0xFFF0F2F5), // Facebook-style background
      body: Stack(
        children: [
          Column(
            children: [
              _buildCleanHeader(isSmallScreen),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 32,
                    vertical: isSmallScreen ? 12 : 24
                  ),
                  child: Column(
                    children: [
                      _buildQuickActions(isSmallScreen),
                      if (widget.userRole == 'Administrator') ...[
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        _buildAdminControlPanel(isSmallScreen),
                      ],
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      StatisticsComponent(level: _selectedLevel),
                    ],
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

  Widget _buildCleanHeader(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 16 : 24,
        12,
        isSmallScreen ? 16 : 24,
        12
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("PROGRAM ANALYTICS", 
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1.2)),
                const SizedBox(height: 2),
                Text("$_selectedLevel Overview", 
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 18,
                    fontWeight: FontWeight.w900,
                    color: kBrandBrown,
                    letterSpacing: -0.5
                  )),
              ],
            ),
          ),
          Row(
            children: [
              if (!isSmallScreen) _buildLevelToggle(false),
              const SizedBox(width: 12),
              _buildAIQuickAccess(),
              const SizedBox(width: 12),
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

  Widget _buildLevelToggle(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn("University", isMobile),
          _toggleBtn("Secondary", isMobile),
        ],
      ),
    );
  }

  Widget _toggleBtn(String level, bool isMobile) {
    final bool isSelected = _selectedLevel == level;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedLevel = level);
        _fetchSummary();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? kBrandOlive : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          level,
          style: TextStyle(
            fontSize: isMobile ? 10 : 11,
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
        childAspectRatio: isSmallScreen ? 1.3 : 1.6,
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
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          decoration: BoxDecoration(
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: isSmallScreen ? 20 : 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 13,
                  fontWeight: FontWeight.w900,
                  color: kBrandBrown,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminControlPanel(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: kBrandBrown,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        boxShadow: isSmallScreen ? null : [BoxShadow(color: kBrandBrown.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ADMINISTRATIVE HUB",
                      style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text("System Overview",
                      style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => widget.onNavigate?.call("Pending Approvals"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandOlive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("APPROVALS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          if (isSmallScreen)
            Column(
              children: [
                Row(
                  children: [
                    _adminStat("Pending", _pendingCount.toString(), Icons.pending_actions_rounded),
                    const SizedBox(width: 12),
                    _adminStat("Alerts", "0", Icons.security_rounded),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _adminStat("Backup", "Healthy", Icons.cloud_done_rounded),
                    const SizedBox(width: 12),
                    _adminStat("AI Confidence", "98%", Icons.psychology_rounded),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                _adminStat("Pending Records", _pendingCount.toString(), Icons.pending_actions_rounded),
                const SizedBox(width: 12),
                _adminStat("Security Alerts", "0", Icons.security_rounded),
                const SizedBox(width: 12),
                _adminStat("Backup Status", "Healthy", Icons.cloud_done_rounded),
                const SizedBox(width: 12),
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
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
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

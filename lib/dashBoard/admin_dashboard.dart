import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:scholar_management_system/services/api_service.dart';
import '../academics/academics_utils.dart';

class AdminDashboardComponent extends StatefulWidget {
  final Function(String)? onNavigate;
  const AdminDashboardComponent({super.key, this.onNavigate});

  @override
  State<AdminDashboardComponent> createState() => _AdminDashboardComponentState();
}

class _AdminDashboardComponentState extends State<AdminDashboardComponent> {
  bool _isLoading = true;
  bool _isBackingUp = false;

  // KPI Metrics
  int _totalUsers = 0;
  int _pendingApprovals = 0;
  int _totalSchools = 0;
  int _totalSponsors = 0;
  int _backupCount = 0;

  // Chart Data
  Map<String, int> _roleDistribution = {};
  int _pendingScholars = 0;
  int _pendingEvents = 0;
  int _pendingPayments = 0;

  // School Performance and Risk Data
  List<Map<String, dynamic>> _schoolsRiskData = [];
  String _searchQuery = "";

  // Activity Log / Active Users
  List<dynamic> _recentActivities = [];
  List<dynamic> _activeUsers = [];

  static const List<Color> chartColors = [
    Color(0xFF9AB334), // Olive
    Color(0xFFE05B1C), // Orange
    Color(0xFF4C3C32), // Brown
    Color(0xFF1976D2), // Blue
    Color(0xFF8E24AA), // Purple
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final statsRes = await ApiService.getDashboardStats(level: 'University');
      if (statsRes.statusCode == 200) {
        final data = statsRes.data['data'] ?? {};

        _pendingApprovals = data['pendingCount'] ?? 0;
        _pendingScholars = data['pendingScholarsCount'] ?? 0;

        final system = data['system'] ?? {};
        _totalUsers = system['totalUsers'] ?? 0;
        _totalSchools = system['totalSchools'] ?? 0;
        _backupCount = system['backupCount'] ?? 0;

        final List schoolsStats = data['schools'] ?? [];
        _schoolsRiskData = schoolsStats.map((s) => {
          'name': s['name']?.toString() ?? 'Unknown',
          'level': s['level']?.toString() ?? 'medium',
          'avg': double.tryParse(s['avg']?.toString() ?? '0.0') ?? 0.0,
          'pass_rate': double.tryParse(s['pass_rate']?.toString() ?? '0.0') ?? 0.0,
          'atrisk': int.tryParse(s['atrisk']?.toString() ?? '0') ?? 0,
          'reason': s['reason']?.toString() ?? 'General flags',
        }).toList();

        final usersRes = await ApiService.getAllUsers();
        if (usersRes.statusCode == 200) {
          final List users = usersRes.data['data'] ?? [];
          _roleDistribution = {};
          for (var user in users) {
            final role = user['role_name'] ?? 'User';
            _roleDistribution[role] = (_roleDistribution[role] ?? 0) + 1;
          }
        }

        final pendingRes = await ApiService.getPendingActivities();
        if (pendingRes.statusCode == 200) {
          final pData = pendingRes.data['data'] ?? {};
          final List events = pData['events'] ?? [];
          final List payments = pData['payments'] ?? [];
          _pendingEvents = events.length;
          _pendingPayments = payments.length;
        }

        final sponsorsRes = await ApiService.getAllSponsors();
        if (sponsorsRes.statusCode == 200) {
          final List sponsors = sponsorsRes.data['data'] ?? [];
          _totalSponsors = sponsors.length;
        }

        final activitiesRes = await ApiService.getRecentActivities();
        if (activitiesRes.statusCode == 200) {
          _recentActivities = activitiesRes.data['data'] ?? [];
        }

        final activeUsersRes = await ApiService.getActiveUsers();
        if (activeUsersRes.statusCode == 200) {
          _activeUsers = activeUsersRes.data['data'] ?? [];
        }
      }
    } catch (e) {
      debugPrint("Error loading admin dashboard stats: $e");
      _loadFallbackMockData();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadFallbackMockData() {
    _totalUsers = 12;
    _roleDistribution = {
      'Administrator': 2,
      'Field Coordinator': 4,
      'Donor / Sponsor': 3,
      'Staff': 3,
    };
    _pendingScholars = 3;
    _pendingEvents = 2;
    _pendingPayments = 1;
    _pendingApprovals = 6;
    _totalSchools = 8;
    _totalSponsors = 15;
    _backupCount = 4;
    _recentActivities = [
      {'message': 'User role changed for Edward', 'created_at': DateTime.now().subtract(const Duration(minutes: 10)).toString(), 'actor': 'SYSTEM'},
      {'message': 'Database backup generated successfully', 'created_at': DateTime.now().subtract(const Duration(hours: 2)).toString(), 'actor': 'SYSTEM'},
    ];
    _schoolsRiskData = [
      {'name': 'Chinsapo Secondary', 'level': 'high', 'avg': 62.4, 'pass_rate': 45.0, 'atrisk': 4, 'reason': 'Attendance flags'},
      {'name': 'Lilongwe Girls', 'level': 'medium', 'avg': 74.8, 'pass_rate': 82.5, 'atrisk': 2, 'reason': 'Pending reports'},
      {'name': 'Zomba Catholic', 'level': 'low', 'avg': 81.2, 'pass_rate': 95.0, 'atrisk': 0, 'reason': 'Excellent marks'},
    ];
  }

  Future<void> _triggerBackup() async {
    setState(() => _isBackingUp = true);
    try {
      final response = await ApiService.runBackup("Manual admin panel backup");
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Database backup executed successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadDashboardData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Backup failed: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kBrandOlive));
    }

    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdminHeroHeader(isMobile),
            const SizedBox(height: 32),
            _buildKPISection(isMobile),
            const SizedBox(height: 32),
            if (isMobile)
              Column(
                children: [
                  _buildUserDistributionCard(isMobile),
                  const SizedBox(height: 24),
                  _buildApprovalsDensityCard(isMobile),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildUserDistributionCard(isMobile)),
                  const SizedBox(width: 32),
                  Expanded(flex: 3, child: _buildApprovalsDensityCard(isMobile)),
                ],
              ),
            const SizedBox(height: 32),
            if (isMobile)
              Column(
                children: [
                  _buildActivityLogCard(isMobile),
                  const SizedBox(height: 24),
                  _buildDatabaseControlsCard(isMobile),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: _buildActivityLogCard(isMobile)),
                  const SizedBox(width: 32),
                  Expanded(flex: 3, child: _buildDatabaseControlsCard(isMobile)),
                ],
              ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminHeroHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translator.translate("ADMINISTRATIVE CONTROL"),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: kBrandBrown.withOpacity(0.5),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              Translator.translate("System Insights & Operations"),
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w900,
                color: kBrandBrown,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        if (!isMobile)
          ElevatedButton.icon(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text("REFRESH", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: kBrandOlive,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: kBrandOlive.withOpacity(0.2)),
              ),
            ),
          )
        else
          IconButton(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh_rounded, color: kBrandOlive),
          )
      ],
    );
  }

  Widget _buildKPISection(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildKPICard("Users", "$_totalUsers", Icons.people_alt_rounded, kBrandOlive, () => widget.onNavigate?.call("Manage Users"), isMobile)),
              const SizedBox(width: 12),
              Expanded(child: _buildKPICard("Pending", "$_pendingApprovals", Icons.gavel_rounded, kBrandOrange, () => widget.onNavigate?.call("Pending Approvals"), isMobile)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildKPICard("Schools", "$_totalSchools", Icons.business_rounded, kBrandBrown, () => widget.onNavigate?.call("Manage Institutions"), isMobile)),
              const SizedBox(width: 12),
              Expanded(child: _buildKPICard("Sponsors", "$_totalSponsors", Icons.volunteer_activism_rounded, const Color(0xFF1976D2), () => widget.onNavigate?.call("Sponsors Directory"), isMobile)),
            ],
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildKPICard("Total Users", "$_totalUsers", Icons.people_alt_rounded, kBrandOlive, () => widget.onNavigate?.call("Manage Users"), isMobile)),
        const SizedBox(width: 24),
        Expanded(child: _buildKPICard("Pending Actions", "$_pendingApprovals", Icons.gavel_rounded, kBrandOrange, () => widget.onNavigate?.call("Pending Approvals"), isMobile)),
        const SizedBox(width: 24),
        Expanded(child: _buildKPICard("Institutions", "$_totalSchools", Icons.business_rounded, kBrandBrown, () => widget.onNavigate?.call("Manage Institutions"), isMobile)),
        const SizedBox(width: 24),
        Expanded(child: _buildKPICard("Active Sponsors", "$_totalSponsors", Icons.volunteer_activism_rounded, const Color(0xFF1976D2), () => widget.onNavigate?.call("Sponsors Directory"), isMobile)),
        const SizedBox(width: 24),
        Expanded(child: _buildKPICard("System Backups", "$_backupCount", Icons.cloud_done_rounded, Colors.purple, () => widget.onNavigate?.call("Backup & Restore"), isMobile)),
      ],
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color, VoidCallback? onTap, bool isMobile) {
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEEEEEE)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: isMobile ? 18 : 24),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: TextStyle(fontSize: isMobile ? 20 : 26, fontWeight: FontWeight.w900, color: kBrandBrown),
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: isMobile ? 8 : 10, color: kBrandBrown.withOpacity(0.5), fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserDistributionCard(bool isMobile) {
    final List<PieChartSectionData> sections = [];
    int index = 0;
    
    _roleDistribution.forEach((role, count) {
      final double value = count.toDouble();
      final Color color = chartColors[index % chartColors.length];
      sections.add(
        PieChartSectionData(
          color: color,
          value: value,
          title: '',
          radius: isMobile ? 30 : 50,
        ),
      );
      index++;
    });

    Widget chart = SizedBox(
      height: isMobile ? 120 : 160,
      child: sections.isEmpty
        ? const Center(child: Text("No users recorded"))
        : PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: isMobile ? 30 : 40,
              sections: sections,
            ),
          ),
    );

    Widget legend = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _roleDistribution.keys.toList().asMap().entries.map((e) {
        final color = chartColors[e.key % chartColors.length];
        final count = _roleDistribution[e.value];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kBrandBrown),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "$count",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kBrandOlive),
              )
            ],
          ),
        );
      }).toList(),
    );

    return _DashboardCard(
      isMobile: isMobile,
      title: "User Composition",
      subtitle: "System profile role mappings",
      child: isMobile 
        ? Column(
            children: [
              chart,
              const SizedBox(height: 24),
              legend,
            ],
          )
        : Row(
            children: [
              Expanded(flex: 4, child: chart),
              const SizedBox(width: 24),
              Expanded(flex: 5, child: legend),
            ],
          ),
    );
  }

  Widget _buildApprovalsDensityCard(bool isMobile) {
    final int maxVal = [1, _pendingEvents, _pendingPayments].reduce((a, b) => a > b ? a : b);

    return _DashboardCard(
      isMobile: isMobile,
      title: "Queue Workloads",
      subtitle: "Items requiring sign-off",
      child: SizedBox(
        height: 160,
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (maxVal + 2).toDouble(),
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const style = TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey);
                      switch (value.toInt()) {
                        case 0: return const Padding(padding: EdgeInsets.only(top: 8.0), child: Text("Events", style: style));
                        case 1: return const Padding(padding: EdgeInsets.only(top: 8.0), child: Text("Payments", style: style));
                        default: return const Text("");
                      }
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: _pendingEvents.toDouble(), color: kBrandOrange, width: isMobile ? 24 : 32, borderRadius: BorderRadius.circular(6))]),
                BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: _pendingPayments.toDouble(), color: kBrandBrown, width: isMobile ? 24 : 32, borderRadius: BorderRadius.circular(6))]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityLogCard(bool isMobile) {
    return _DashboardCard(
      isMobile: isMobile,
      title: "Operations Ledger",
      subtitle: "Active users recently engaged",
      child: _activeUsers.isEmpty
        ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text("No active sessions detected.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12))))
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activeUsers.take(6).length,
            separatorBuilder: (_, __) => const Divider(height: 24, color: Color(0xFFF1F4F8)),
            itemBuilder: (context, idx) {
              final user = _activeUsers[idx];
              String timeStr = "Active now";
              try {
                final date = DateTime.tryParse(user['lastLogin'] ?? '');
                if (date != null) {
                  final diff = DateTime.now().difference(date);
                  if (diff.inMinutes < 1) {
                    timeStr = "Active now";
                  } else if (diff.inMinutes < 60) {
                    timeStr = "${diff.inMinutes}m ago";
                  } else if (diff.inHours < 24) {
                    timeStr = "${diff.inHours}h ago";
                  } else {
                    timeStr = DateFormat('MMM dd, HH:mm').format(date);
                  }
                }
              } catch (_) {}

              return Row(
                children: [
                  CircleAvatar(
                    radius: isMobile ? 14 : 18,
                    backgroundColor: kBrandOlive.withOpacity(0.1),
                    child: ClipOval(
                      child: user['profilePicture'] != null
                        ? Image.network(
                            ApiService.getFullUrl(user['profilePicture']),
                            fit: BoxFit.cover,
                            width: isMobile ? 28 : 36,
                            height: isMobile ? 28 : 36,
                            errorBuilder: (context, error, stackTrace) =>
                              _initialsAvatar(user['fullName'] ?? '?', isMobile),
                          )
                        : _initialsAvatar(user['fullName'] ?? '?', isMobile),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['fullName'] ?? 'User Identity',
                          style: TextStyle(fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.bold, color: kBrandBrown),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user['roleId']?['name']?.toUpperCase() ?? 'STAFF',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: kBrandBrown.withOpacity(0.4), letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: timeStr == "Active now" ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        if (timeStr == "Active now")
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                          ),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: timeStr == "Active now" ? Colors.green : Colors.grey.shade600
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  Widget _buildDatabaseControlsCard(bool isMobile) {
    return _DashboardCard(
      isMobile: isMobile,
      title: "System Integrity",
      subtitle: "Maintenance and security",
      child: Column(
        children: [
          _buildOpButton("Run Database Backup", Icons.backup_rounded, kBrandOlive, _isBackingUp ? null : _triggerBackup, loading: _isBackingUp),
          const SizedBox(height: 16),
          _buildOpButton("Access Permissions", Icons.security_rounded, kBrandBrown, () => widget.onNavigate?.call("Permissions")),
          const SizedBox(height: 16),
          _buildOpButton("Onboard Institution", Icons.add_business_rounded, kBrandBrown, () => widget.onNavigate?.call("Register School"), outlined: true),
        ],
      ),
    );
  }

  Widget _buildOpButton(String label, IconData icon, Color color, VoidCallback? onTap, {bool loading = false, bool outlined = false}) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5)),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: loading 
        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
        : Icon(icon, size: 18),
      label: Text(loading ? "EXECUTING..." : label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _initialsAvatar(String name, bool isMobile) {
    return Container(
      width: isMobile ? 28 : 36,
      height: isMobile ? 28 : 36,
      alignment: Alignment.center,
      color: kBrandOlive.withOpacity(0.1),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(color: kBrandBrown, fontWeight: FontWeight.bold, fontSize: isMobile ? 10 : 12),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  final bool isMobile;
  const _DashboardCard({required this.title, required this.subtitle, required this.child, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: isMobile ? 15 : 18, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
          Text(subtitle, style: TextStyle(fontSize: isMobile ? 10 : 12, color: kBrandBrown.withOpacity(0.4), fontWeight: FontWeight.w600)),
          SizedBox(height: isMobile ? 20 : 32),
          child,
        ],
      ),
    );
  }
}

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

  int _totalUsers = 0;
  int _pendingApprovals = 0;
  int _totalSchools = 0;
  int _totalSponsors = 0;
  int _backupCount = 0;

  Map<String, int> _roleDistribution = {};
  int _pendingEvents = 0;
  int _pendingPayments = 0;

  List<Map<String, dynamic>> _schoolsRiskData = [];
  List<dynamic> _activeUsers = [];
  List<dynamic> _approvals = [];

  static const List<Color> chartColors = [
    Color(0xFF9AB334), Color(0xFFE05B1C), Color(0xFF4C3C32), Color(0xFF1976D2), Color(0xFF8E24AA),
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

        final system = data['system'] ?? {};
        _totalUsers = system['totalUsers'] ?? 0;
        _totalSchools = system['totalSchools'] ?? 0;
        _backupCount = system['backupCount'] ?? 0;

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
          final List scholars = pData['scholars'] ?? [];
          final List events = pData['events'] ?? [];
          final List payments = pData['payments'] ?? [];

          _approvals = [];
          for (var s in scholars) _approvals.add({...s, 'type': 'scholar'});
          for (var e in events) _approvals.add({...e, 'type': 'event'});
          for (var p in payments) _approvals.add({...p, 'type': 'payment'});

          _pendingEvents = events.length;
          _pendingPayments = payments.length;
        }

        final sponsorsRes = await ApiService.getAllSponsors();
        if (sponsorsRes.statusCode == 200) {
          _totalSponsors = (sponsorsRes.data['data'] ?? []).length;
        }

        final activeUsersRes = await ApiService.getActiveUsers();
        if (activeUsersRes.statusCode == 200) {
          _activeUsers = activeUsersRes.data['data'] ?? [];
        }
      }
    } catch (e) {
      _loadFallbackMockData();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadFallbackMockData() {
    _totalUsers = 12;
    _roleDistribution = {'Administrator': 2, 'Field Coordinator': 4, 'Donor': 3, 'Staff': 3};
    _pendingApprovals = 6; _pendingEvents = 2; _pendingPayments = 1;
    _totalSchools = 8; _totalSponsors = 15; _backupCount = 4;
    _activeUsers = [
      {'fullName': 'Edward Shaba', 'roleId': {'name': 'Administrator'}, 'lastLogin': DateTime.now().toString()},
      {'fullName': 'Grace Banda', 'roleId': {'name': 'Staff'}, 'lastLogin': DateTime.now().subtract(const Duration(minutes: 5)).toString()},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 950;
    final bool isVerySmall = screenWidth < 500;

    return Container(
      color: const Color(0xFFF8F9FA),
      width: double.infinity,
      height: double.infinity,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isVerySmall ? 8 : (isMobile ? 12 : 32)),
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isMobile) ...[
                  _buildAdminPortalHeader(isMobile),
                  const SizedBox(height: 32),
                ],

                // KPI Cards - Small and responsive
                _buildKPISection(isMobile, isVerySmall),

                SizedBox(height: isVerySmall ? 16 : 32),

                // Multi-column row or vertical stack
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (isMobile) {
                      return Column(
                        children: [
                          _buildUserDistributionCard(isMobile, isVerySmall),
                          const SizedBox(height: 16),
                          _buildApprovalsDensityCard(isMobile, isVerySmall),
                          const SizedBox(height: 16),
                          _buildActivityLogCard(isMobile, isVerySmall),
                          const SizedBox(height: 16),
                          _buildDatabaseControlsCard(isMobile, isVerySmall),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              _buildUserDistributionCard(isMobile, isVerySmall),
                              const SizedBox(height: 32),
                              _buildActivityLogCard(isMobile, isVerySmall),
                            ],
                          )
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              _buildApprovalsDensityCard(isMobile, isVerySmall),
                              const SizedBox(height: 32),
                              _buildDatabaseControlsCard(isMobile, isVerySmall),
                            ],
                          )
                        ),
                      ],
                    );
                  }
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminPortalHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "System Intelligence Hub",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4C3C32),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF4C3C32)),
          )
        ],
      ),
    );
  }

  Widget _buildKPISection(bool isMobile, bool isVerySmall) {
    final kpis = [
      ("System Users", "$_totalUsers", Icons.people_alt_rounded, kBrandOlive, "Manage Users"),
      ("Pending Approvals", "$_pendingApprovals", Icons.gavel_rounded, kBrandOrange, "Pending Approvals"),
      ("Institutions", "$_totalSchools", Icons.business_rounded, kBrandBrown, "Manage Institutions"),
      ("Global Sponsors", "$_totalSponsors", Icons.volunteer_activism_rounded, const Color(0xFF1976D2), "Sponsors Directory"),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildPortalCard(kpis[0].$1, kpis[0].$2, kpis[0].$3, kpis[0].$4, () => widget.onNavigate?.call(kpis[0].$5))),
              const SizedBox(width: 12),
              Expanded(child: _buildPortalCard(kpis[1].$1, kpis[1].$2, kpis[1].$3, kpis[1].$4, () => widget.onNavigate?.call(kpis[1].$5))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildPortalCard(kpis[2].$1, kpis[2].$2, kpis[2].$3, kpis[2].$4, () => widget.onNavigate?.call(kpis[2].$5))),
              const SizedBox(width: 12),
              Expanded(child: _buildPortalCard(kpis[3].$1, kpis[3].$2, kpis[3].$3, kpis[3].$4, () => widget.onNavigate?.call(kpis[3].$5))),
            ],
          ),
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.8,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, i) => _buildPortalCard(
        kpis[i].$1, 
        kpis[i].$2, 
        kpis[i].$3, 
        kpis[i].$4, 
        () => widget.onNavigate?.call(kpis[i].$5),
      ),
    );
  }

  Widget _buildPortalCard(String label, String value, IconData icon, Color color, VoidCallback onTap) {
    final bool isMobile = MediaQuery.of(context).size.width < 950;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 16 : 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: isMobile ? 20 : 24),
              ),
              SizedBox(width: isMobile ? 12 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 26,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF4C3C32),
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: isMobile ? 8 : 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade400,
                        letterSpacing: 1.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserDistributionCard(bool isMobile, bool isVerySmall) {
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
          radius: isVerySmall ? 15 : (isMobile ? 25 : 40),
        ),
      );
      index++;
    });

    final content = [
      SizedBox(
        height: isVerySmall ? 70 : (isMobile ? 100 : 140),
        width: isVerySmall ? 70 : (isMobile ? 100 : 140),
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: isVerySmall ? 15 : (isMobile ? 25 : 35),
            sections: sections,
          ),
        ),
      ),
      SizedBox(width: isVerySmall ? 0 : 20, height: isVerySmall ? 16 : 0),
      Expanded(
        flex: isVerySmall ? 0 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _roleDistribution.keys.take(4).map((role) {
            final idx = _roleDistribution.keys.toList().indexOf(role);
            final color = chartColors[idx % chartColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      role,
                      style: TextStyle(
                        fontSize: isVerySmall ? 9 : 11,
                        fontWeight: FontWeight.bold,
                        color: kBrandBrown,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      )
    ];

    return _DashboardCard(
      isMobile: isMobile,
      isVerySmall: isVerySmall,
      title: "Account Allocation",
      child: isVerySmall
        ? Column(children: content)
        : Row(children: content),
    );
  }

  Widget _buildApprovalsDensityCard(bool isMobile, bool isVerySmall) {
    return _DashboardCard(
      isMobile: isMobile,
      isVerySmall: isVerySmall,
      title: "Queue Workloads",
      child: Column(
        children: [
          SizedBox(
            height: isVerySmall ? 90 : 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        final style = TextStyle(
                          fontSize: isVerySmall ? 8 : 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        );
                        if (v.toInt() == 0) return Text("Scholars", style: style);
                        if (v.toInt() == 1) return Text("Events", style: style);
                        if (v.toInt() == 2) return Text("Payments", style: style);
                        return const Text("");
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
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: (_approvals.where((a) => a['type'] == 'scholar').length).toDouble(), color: kBrandOlive, width: isVerySmall ? 18 : 24)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: _pendingEvents.toDouble(), color: kBrandOrange, width: isVerySmall ? 18 : 24)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: _pendingPayments.toDouble(), color: kBrandBrown, width: isVerySmall ? 18 : 24)]),
                ],
              ),
            ),
          ),
          SizedBox(height: isVerySmall ? 12 : 16),
          _opButton("View Full Queue", Icons.checklist_rtl_rounded, kBrandBrown, isMobile, 
            onPressed: () => widget.onNavigate?.call("Pending Approvals"),
            isVerySmall: isVerySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLogCard(bool isMobile, bool isVerySmall) {
    return _DashboardCard(
      isMobile: isMobile,
      isVerySmall: isVerySmall,
      title: "Active Operators",
      child: Column(
        children: _activeUsers.take(4).map((u) => Padding(
          padding: EdgeInsets.only(bottom: isVerySmall ? 8 : 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: isVerySmall ? 10 : 14, 
                backgroundColor: kBrandOlive.withOpacity(0.1), 
                child: Text(
                  u['fullName']?[0].toUpperCase() ?? '?', 
                  style: TextStyle(fontSize: isVerySmall ? 8 : 10, fontWeight: FontWeight.bold, color: kBrandBrown)
                )
              ),
              SizedBox(width: isVerySmall ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u['fullName'] ?? 'Staff', 
                      style: TextStyle(fontSize: isVerySmall ? 11 : 13, fontWeight: FontWeight.bold, color: kBrandBrown),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      u['roleId']?['name']?.toString().toUpperCase() ?? 'USER', 
                      style: TextStyle(fontSize: isVerySmall ? 6 : 8, color: Colors.grey.shade500, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.circle, size: isVerySmall ? 4 : 6, color: Colors.green),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildDatabaseControlsCard(bool isMobile, bool isVerySmall) {
    return _DashboardCard(
      isMobile: isMobile,
      isVerySmall: isVerySmall,
      title: "System Integrity",
      child: Column(
        children: [
          _opButton("Run Cloud Backup", Icons.backup_rounded, kBrandOlive, isMobile, 
            isVerySmall: isVerySmall,
            onPressed: _isBackingUp ? null : () async {
              setState(() => _isBackingUp = true);
              try {
                final res = await ApiService.runBackup("Dashboard Manual Sync");
                if (res.statusCode == 201 && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cloud backup initialized successfully."), backgroundColor: kBrandOlive));
                  _loadDashboardData();
                }
              } catch (e) {
                debugPrint('Backup error: $e');
              } finally {
                if (mounted) setState(() => _isBackingUp = false);
              }
            }
          ),
          const SizedBox(height: 12),
          _opButton("Security Audit", Icons.security_rounded, kBrandBrown, isMobile, 
            isVerySmall: isVerySmall,
            onPressed: () {}
          ),
        ],
      ),
    );
  }

  Widget _opButton(String label, IconData icon, Color color, bool isMobile, {VoidCallback? onPressed, bool isVerySmall = false}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: _isBackingUp && label.contains("Backup") 
        ? SizedBox(width: isVerySmall ? 12 : 14, height: isVerySmall ? 12 : 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Icon(icon, size: isVerySmall ? 14 : 16),
      label: Text(label.toUpperCase(), style: TextStyle(fontSize: isVerySmall ? 9 : 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, isVerySmall ? 44 : 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isVerySmall ? 10 : 12)),
        elevation: 0,
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isMobile;
  final bool isVerySmall;
  const _DashboardCard({required this.title, required this.child, this.isMobile = false, this.isVerySmall = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isVerySmall ? 12 : (isMobile ? 16 : 32)),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(isVerySmall ? 12 : 20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(), 
            style: TextStyle(
              fontSize: isVerySmall ? 9 : 11,
              fontWeight: FontWeight.w900, 
              color: const Color(0xFF9AB334),
              letterSpacing: 1.5
            ),
          ),
          SizedBox(height: isVerySmall ? 16 : 24),
          child,
        ],
      ),
    );
  }
}

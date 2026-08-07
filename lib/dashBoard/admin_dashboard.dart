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
          _approvals = pData['scholars'] ?? [];
          _pendingEvents = (pData['events'] ?? []).length;
          _pendingPayments = (pData['payments'] ?? []).length;
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kBrandOlive));
    }

    final bool isMobile = MediaQuery.of(context).size.width < 950;

    return Container(
      color: const Color(0xFFF8F9FA),
      width: double.infinity,
      height: double.infinity,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 32),
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
                _buildKPISection(isMobile),

                const SizedBox(height: 32),

                // Multi-column row or vertical stack
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (isMobile) {
                      return Column(
                        children: [
                          _buildUserDistributionCard(isMobile),
                          const SizedBox(height: 16),
                          _buildApprovalsDensityCard(isMobile),
                          const SizedBox(height: 16),
                          _buildActivityLogCard(isMobile),
                          const SizedBox(height: 16),
                          _buildDatabaseControlsCard(isMobile),
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
                              _buildUserDistributionCard(isMobile),
                              const SizedBox(height: 32),
                              _buildActivityLogCard(isMobile),
                            ],
                          )
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              _buildApprovalsDensityCard(isMobile),
                              const SizedBox(height: 32),
                              _buildDatabaseControlsCard(isMobile),
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

  Widget _buildKPISection(bool isMobile) {
    final kpis = [
      ("System Users", "$_totalUsers", Icons.people_alt_rounded, kBrandOlive, "Manage Users"),
      ("Pending Approvals", "$_pendingApprovals", Icons.gavel_rounded, kBrandOrange, "Pending Approvals"),
      ("Institutions", "$_totalSchools", Icons.domain_rounded, kBrandBrown, "Manage Institutions"),
      ("Global Sponsors", "$_totalSponsors", Icons.volunteer_activism_rounded, const Color(0xFF1976D2), "Sponsors Directory"),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: isMobile ? 1.4 : 1.8,
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEEEEEE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4C3C32),
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
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

  Widget _buildUserDistributionCard(bool isMobile) {
    final List<PieChartSectionData> sections = [];
    int index = 0;
    _roleDistribution.forEach((role, count) {
      sections.add(PieChartSectionData(color: chartColors[index % chartColors.length], value: count.toDouble(), title: '', radius: isMobile ? 25 : 40));
      index++;
    });

    return _DashboardCard(
      isMobile: isMobile,
      title: "Account Allocation",
      child: Row(
        children: [
          SizedBox(
            height: isMobile ? 100 : 140,
            width: isMobile ? 100 : 140,
            child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: isMobile ? 25 : 35, sections: sections)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _roleDistribution.keys.take(4).map((role) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: chartColors[_roleDistribution.keys.toList().indexOf(role) % chartColors.length], shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(role, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  ],
                ),
              )).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildApprovalsDensityCard(bool isMobile) {
    return _DashboardCard(
      isMobile: isMobile,
      title: "Queue Workloads",
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                    const style = TextStyle(fontSize: 9, fontWeight: FontWeight.bold);
                    if (v.toInt() == 0) return const Text("Scholars", style: style);
                    if (v.toInt() == 1) return const Text("Events", style: style);
                    if (v.toInt() == 2) return const Text("Payments", style: style);
                    return const Text("");
                  })),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: (_approvals.where((a) => a['type'] == 'scholar').length).toDouble(), color: kBrandOlive, width: 24)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: _pendingEvents.toDouble(), color: kBrandOrange, width: 24)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: _pendingPayments.toDouble(), color: kBrandBrown, width: 24)]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _opButton("View Full Queue", Icons.checklist_rtl_rounded, kBrandBrown, isMobile, onPressed: () => widget.onNavigate?.call("Pending Approvals")),
        ],
      ),
    );
  }

  Widget _buildActivityLogCard(bool isMobile) {
    return _DashboardCard(
      isMobile: isMobile,
      title: "Active Operators",
      child: Column(
        children: _activeUsers.take(4).map((u) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              CircleAvatar(radius: 14, backgroundColor: kBrandOlive.withOpacity(0.1), child: Text(u['fullName']?[0].toUpperCase() ?? '?', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kBrandBrown))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u['fullName'] ?? 'Staff', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(u['roleId']?['name'] ?? 'USER', style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const Icon(Icons.circle, size: 6, color: Colors.green),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildDatabaseControlsCard(bool isMobile) {
    return _DashboardCard(
      isMobile: isMobile,
      title: "System Integrity",
      child: Column(
        children: [
          _opButton("Run Cloud Backup", Icons.backup_rounded, kBrandOlive, isMobile, 
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
          _opButton("Security Audit", Icons.security_rounded, kBrandBrown, isMobile, onPressed: () {}),
        ],
      ),
    );
  }

  Widget _opButton(String label, IconData icon, Color color, bool isMobile, {VoidCallback? onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: _isBackingUp && label.contains("Backup") 
        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Icon(icon, size: 16),
      label: Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isMobile;
  const _DashboardCard({required this.title, required this.child, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
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
            style: const TextStyle(
              fontSize: 11, 
              fontWeight: FontWeight.w900, 
              color: Color(0xFF9AB334), 
              letterSpacing: 1.5
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

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
      // 1. Fetch High-Fidelity Dashboard Metrics (KPIs, Risk Heatmap, and Counts)
      final statsRes = await ApiService.getDashboardStats(level: 'University');
      if (statsRes.statusCode == 200) {
        final data = statsRes.data['data'] ?? {};

        // Use proper counting from backend source of truth
        _pendingApprovals = data['pendingCount'] ?? 0;
        _pendingScholars = data['pendingScholarsCount'] ?? 0;

        // System-level actual counts
        final system = data['system'] ?? {};
        _totalUsers = system['totalUsers'] ?? 0;
        _totalSchools = system['totalSchools'] ?? 0;
        _backupCount = system['backupCount'] ?? 0;

        // Institutional performance data
        final List schoolsStats = data['schools'] ?? [];
        _schoolsRiskData = schoolsStats.map((s) => {
          'name': s['name']?.toString() ?? 'Unknown',
          'level': s['level']?.toString() ?? 'medium',
          'avg': double.tryParse(s['avg']?.toString() ?? '0.0') ?? 0.0,
          'pass_rate': double.tryParse(s['pass_rate']?.toString() ?? '0.0') ?? 0.0,
          'atrisk': int.tryParse(s['atrisk']?.toString() ?? '0') ?? 0,
          'reason': s['reason']?.toString() ?? 'General institutional flags',
        }).toList();

        // 2. Fetch User Role Distribution
        final usersRes = await ApiService.getAllUsers();
        if (usersRes.statusCode == 200) {
          final List users = usersRes.data['data'] ?? [];
          _roleDistribution = {};
          for (var user in users) {
            final role = user['role_name'] ?? 'User';
            _roleDistribution[role] = (_roleDistribution[role] ?? 0) + 1;
          }
        }

        // 3. Fetch Detailed Pending Breakdown (for Bar Chart)
        final pendingRes = await ApiService.getPendingActivities();
        if (pendingRes.statusCode == 200) {
          final pData = pendingRes.data['data'] ?? {};
          final List events = pData['events'] ?? [];
          final List payments = pData['payments'] ?? [];
          _pendingEvents = events.length;
          _pendingPayments = payments.length;
        }

        // 4. Fetch Sponsors
        final sponsorsRes = await ApiService.getAllSponsors();
        if (sponsorsRes.statusCode == 200) {
          final List sponsors = sponsorsRes.data['data'] ?? [];
          _totalSponsors = sponsors.length;
        }

        // 5. Fetch Recent activities
        final activitiesRes = await ApiService.getRecentActivities();
        if (activitiesRes.statusCode == 200) {
          _recentActivities = activitiesRes.data['data'] ?? [];
        }

        // 6. Fetch Active Users
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
      {'message': 'New School Register requested: Lilongwe Secondary', 'created_at': DateTime.now().subtract(const Duration(days: 1)).toString(), 'actor': 'Staff Member'},
    ];
    _schoolsRiskData = [
      {'name': 'Chinsapo Secondary School', 'level': 'high', 'avg': 62.4, 'pass_rate': 45.0, 'atrisk': 4, 'reason': 'Drop in attendance & Term 1 performance flags'},
      {'name': 'Lilongwe Girls Secondary', 'level': 'medium', 'avg': 74.8, 'pass_rate': 82.5, 'atrisk': 2, 'reason': 'Pending performance reports'},
      {'name': 'Zomba Catholic Secondary', 'level': 'low', 'avg': 81.2, 'pass_rate': 95.0, 'atrisk': 0, 'reason': 'Excellent academic marks density'},
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdminHeroHeader(),
            const SizedBox(height: 32),
            _buildKPISection(),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildUserDistributionCard()),
                const SizedBox(width: 32),
                Expanded(flex: 3, child: _buildApprovalsDensityCard()),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: _buildActivityLogCard()),
                const SizedBox(width: 32),
                Expanded(flex: 3, child: _buildDatabaseControlsCard()),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminHeroHeader() {
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: kBrandBrown,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
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
      ],
    );
  }

  Widget _buildKPISection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildKPICard("Total Users", "$_totalUsers", Icons.people_alt_rounded, kBrandOlive, () => widget.onNavigate?.call("Manage Users"))),
        const SizedBox(width: 24),
        Expanded(child: _buildKPICard("Pending Actions", "$_pendingApprovals", Icons.gavel_rounded, kBrandOrange, () => widget.onNavigate?.call("Pending Approvals"))),
        const SizedBox(width: 24),
        Expanded(child: _buildKPICard("Institutions", "$_totalSchools", Icons.business_rounded, kBrandBrown, () => widget.onNavigate?.call("Manage Institutions"))),
        const SizedBox(width: 24),
        Expanded(child: _buildKPICard("Active Sponsors", "$_totalSponsors", Icons.volunteer_activism_rounded, const Color(0xFF1976D2), () => widget.onNavigate?.call("Sponsors Directory"))),
        const SizedBox(width: 24),
        Expanded(child: _buildKPICard("System Backups", "$_backupCount", Icons.cloud_done_rounded, Colors.purple, () => widget.onNavigate?.call("Backup & Restore"))),
      ],
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color, VoidCallback? onTap) {
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kBrandBrown),
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: kBrandBrown.withOpacity(0.5), fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserDistributionCard() {
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
          radius: 50,
        ),
      );
      index++;
    });

    return _DashboardCard(
      title: "User Composition",
      subtitle: "System profile role mappings & distribution",
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: SizedBox(
              height: 160,
              child: sections.isEmpty
                ? const Center(child: Text("No users recorded"))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: sections,
                    ),
                  ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _roleDistribution.keys.toList().asMap().entries.map((e) {
                final color = chartColors[e.key % chartColors.length];
                final count = _roleDistribution[e.value];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kBrandBrown),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        "$count",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrandOlive),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalsDensityCard() {
    final int maxVal = [1, _pendingEvents, _pendingPayments].reduce((a, b) => a > b ? a : b);

    return _DashboardCard(
      title: "Queue Workloads",
      subtitle: "Outstanding items requiring sign-off",
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
                BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: _pendingEvents.toDouble(), color: kBrandOrange, width: 32, borderRadius: BorderRadius.circular(6))]),
                BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: _pendingPayments.toDouble(), color: kBrandBrown, width: 32, borderRadius: BorderRadius.circular(6))]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolsRiskSection() {
    final filtered = _schoolsRiskData.where((s) => s['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Container(
      padding: const EdgeInsets.all(32),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("INSTITUTIONAL INTEGRITY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
                  SizedBox(height: 6),
                  Text("Performance & Risk Heatmap", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kBrandBrown)),
                ],
              ),
              Container(
                width: 300,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E6ED)),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: "Filter by institution name...",
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                    prefixIcon: Icon(Icons.search_rounded, color: kBrandOlive, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48.0),
              child: Center(child: Text("No institutions map this search criteria.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.2),
                4: FlexColumnWidth(1.8),
                5: FlexColumnWidth(4),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1.5)),
                  ),
                  children: const [
                    Padding(padding: EdgeInsets.all(16), child: Text("SCHOOL NAME", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey))),
                    Padding(padding: EdgeInsets.all(16), child: Text("RISK STATE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey))),
                    Padding(padding: EdgeInsets.all(16), child: Text("AVG %", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey))),
                    Padding(padding: EdgeInsets.all(16), child: Text("PASS %", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey))),
                    Padding(padding: EdgeInsets.all(16), child: Text("FLAGS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey))),
                    Padding(padding: EdgeInsets.all(16), child: Text("PRIMARY RISK FACTOR", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey))),
                  ],
                ),
                ...filtered.map((s) {
                  final Color riskColor = _getRiskStateColor(s['level']);
                  return TableRow(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFF4F6F8))),
                    ),
                    children: [
                      Padding(padding: const EdgeInsets.all(16), child: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kBrandBrown))),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: riskColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(s['level'].toString().toUpperCase(), textAlign: TextAlign.center, style: TextStyle(color: riskColor, fontSize: 9, fontWeight: FontWeight.w900)),
                        ),
                      ),
                      Padding(padding: const EdgeInsets.all(16), child: Text("${s['avg']}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kBrandBrown))),
                      Padding(padding: const EdgeInsets.all(16), child: Text("${s['pass_rate']}%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: s['pass_rate'] < 50 ? Colors.red : kBrandOlive))),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          "${s['atrisk']} scholars",
                          style: TextStyle(color: s['atrisk'] > 0 ? Colors.red : Colors.grey.shade400, fontWeight: s['atrisk'] > 0 ? FontWeight.w900 : FontWeight.normal, fontSize: 13),
                        ),
                      ),
                      Padding(padding: const EdgeInsets.all(16), child: Text(s['reason'], style: const TextStyle(fontSize: 12, color: Colors.black54))),
                    ],
                  );
                }).toList(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActivityLogCard() {
    return _DashboardCard(
      title: "Operations Ledger",
      subtitle: "Active users recently engaged with the system",
      child: _activeUsers.isEmpty
        ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text("No active user sessions detected.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))))
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
                    radius: 18,
                    backgroundColor: kBrandOlive.withOpacity(0.1),
                    child: ClipOval(
                      child: user['profilePicture'] != null
                        ? Image.network(
                            ApiService.getFullUrl(user['profilePicture']),
                            fit: BoxFit.cover,
                            width: 36,
                            height: 36,
                            errorBuilder: (context, error, stackTrace) =>
                              _initialsAvatar(user['fullName'] ?? '?'),
                          )
                        : _initialsAvatar(user['fullName'] ?? '?'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['fullName'] ?? 'User Identity',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kBrandBrown),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user['roleId']?['name']?.toUpperCase() ?? 'STAFF',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: kBrandBrown.withOpacity(0.4), letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                            fontSize: 10,
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

  Widget _buildDatabaseControlsCard() {
    return _DashboardCard(
      title: "System Integrity",
      subtitle: "Infrastructure and security maintenance",
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
          minimumSize: const Size(double.infinity, 56),
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
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Color _getRiskStateColor(String level) {
    if (level == 'high') return Colors.red.shade700;
    if (level == 'medium') return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  Widget _initialsAvatar(String name) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      color: kBrandOlive.withOpacity(0.1),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(color: kBrandBrown, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const _DashboardCard({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
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
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kBrandBrown, letterSpacing: -0.5)),
          Text(subtitle, style: TextStyle(fontSize: 12, color: kBrandBrown.withOpacity(0.4), fontWeight: FontWeight.w600)),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}

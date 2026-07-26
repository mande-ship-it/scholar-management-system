import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../services/api_service.dart';

// Dashboard
import '../dashboardPages/dashboard.dart';
import '../dashboardPages/recent_activities.dart';
import '../dashboardPages/notifications.dart';

// Scholars
import '../scholarPages/register_scholar.dart';
import '../scholarPages/view_scholars.dart';
import '../scholarPages/promote_scholars.dart';
import '../scholarPages/scholar_stats.dart';
import '../attendancePages/scholar_attendance.dart';

// Schools
import '../schoolPages/register_school.dart';
import '../schoolPages/view_schools.dart';
import '../schoolPages/school_stats.dart';

// Sponsors
import '../sponsorPages/register_sponsor.dart';
import '../sponsorPages/view_sponsors.dart';
import '../sponsorPages/sponsor_stats.dart';

// Academics
import '../academicPages/enter_results.dart';
import '../academicPages/view_results.dart';
import '../academicPages/report_cards.dart';
import '../academicPages/performance_analysis.dart';
import '../academicPages/academic_stats.dart';

// Attendance
import '../attendancePages/attendance_history.dart';
import '../attendancePages/attendance_reports.dart';

// Events
import '../eventPages/events.dart';

// Reports
import '../reportPages/scholar_reports.dart';
import '../reportPages/school_reports.dart';
import '../reportPages/sponsor_reports.dart';
import '../reportPages/export_pdf.dart';
import '../reportPages/export_excel.dart';

// Users
import '../userPages/create_user.dart';
import '../userPages/manage_users.dart';
import '../userPages/user_roles.dart';
import '../userPages/permissions.dart';
import '../userPages/user_profile.dart';

// Admin
import '../admin/approvals_page.dart';

// Settings
import '../settingsPages/organisation_profile.dart';
import '../settingsPages/backup_restore.dart';
import '../settingsPages/system_settings.dart';
import '../settingsPages/account_settings.dart';

class SidebarCategory {
  final String title;
  final IconData icon;
  final List<SidebarSubItem> subItems;

  const SidebarCategory({
    required this.title,
    required this.icon,
    required this.subItems,
  });
}

class SidebarSubItem {
  final String title;
  final Widget page;
  final IconData icon;

  const SidebarSubItem({
    required this.title,
    required this.page,
    required this.icon,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int activeCategoryIndex = 0;
  int activeSubIndex = 0;
  bool _isSidebarVisible = true;
  int _notificationCount = 0;
  IO.Socket? _socket;
  int? _currentUserId;

  late AnimationController _notificationIconController;
  late Animation<double> _notificationIconAnimation;

  String _fullName = "User";
  String _userRole = "Staff";
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _notificationIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _notificationIconAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _notificationIconController, curve: Curves.elasticOut),
    );

    _initSocket();
    _fetchNotificationCount();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await ApiService.getAccountProfile();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && mounted) {
          setState(() {
            _fullName = data['full_name'] ?? "User";
            _userRole = data['role_name'] ?? "Staff";
            _profileImageUrl = data['profile_picture'];
            _currentUserId = data['id'];
          });

          if (_currentUserId != null && _socket != null && _socket!.connected) {
            debugPrint('Connected and joining socket room for user $_currentUserId');
            _socket!.emit('join', _currentUserId);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching user profile in Home: $e');
    }
  }

  void _initSocket() {
    // In production, use your actual server IP
    _socket = IO.io('http://localhost:5000', IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('Connected to Notification Server');
      if (_currentUserId != null) {
        debugPrint('Socket connected: joining room for user $_currentUserId');
        _socket!.emit('join', _currentUserId);
      } else {
        _socket!.emit('join', 1); // Fallback join user 1
      }
    });

    _socket!.on('notification', (data) {
      if (mounted) {
        setState(() {
          _notificationCount++;
        });
        _notificationIconController.forward(from: 0.0).then((_) => _notificationIconController.reverse());
        _playNotificationSound();
        _showNotificationOverlay(
          message: data['message'] ?? 'New update received',
          actor: data['actorName'] ?? 'System',
          type: data['type'] ?? 'info',
        );
      }
    });
  }

  void _playNotificationSound() {
    SystemSound.play(SystemSoundType.click);
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final response = await ApiService.getNotifications();
      if (response.statusCode == 200) {
        final List notifications = response.data['data'];
        if (mounted) {
          final int newCount = notifications.where((n) => n['is_read'] == false).length;
          if (newCount > _notificationCount) {
            _notificationIconController.forward(from: 0.0).then((_) => _notificationIconController.reverse());
          }
          setState(() {
            _notificationCount = newCount;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  void _showNotificationOverlay({required String message, required String actor, String type = 'info'}) {
    final Color brandOlive = const Color(0xFF9AB334);
    final Color brandOrange = const Color(0xFFE05B1C);

    IconData icon = Icons.notifications_active;
    Color color = brandOlive;
    if (type == 'success') { icon = Icons.check_circle; color = Colors.green; }
    if (type == 'warning') { icon = Icons.warning; color = brandOrange; }
    if (type == 'error') { icon = Icons.error; color = Colors.red; }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      actor.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OPEN',
          textColor: Colors.white,
          onPressed: () {
            setState(() => _notificationCount = 0);
            ApiService.markAllNotificationsRead();
            _navigateToSubItem("Notifications");
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _notificationIconController.dispose();
    super.dispose();
  }

  void _navigateToSubItem(String title) {
    for (int i = 0; i < categories.length; i++) {
      for (int j = 0; j < categories[i].subItems.length; j++) {
        if (categories[i].subItems[j].title == title) {
          setState(() {
            activeCategoryIndex = i;
            activeSubIndex = j;
          });
          return;
        }
      }
    }
  }

  final List<SidebarCategory> categories = const [
    SidebarCategory(
      title: "Dashboard",
      icon: Icons.dashboard,
      subItems: [
        SidebarSubItem(title: "Overview", page: DashboardPage(), icon: Icons.view_quilt),
        SidebarSubItem(title: "Events & Programs", page: EventsPage(), icon: Icons.event_available),
        SidebarSubItem(title: "Recent Activities", page: RecentActivitiesPage(), icon: Icons.history),
        SidebarSubItem(title: "Notifications", page: NotificationsPage(), icon: Icons.notifications_active),
      ],
    ),
    SidebarCategory(
      title: "Scholars",
      icon: Icons.school,
      subItems: [
        SidebarSubItem(title: "Register Scholar", page: RegisterScholarPage(), icon: Icons.person_add),
        SidebarSubItem(title: "View Scholars", page: ViewScholarsPage(), icon: Icons.people),
        SidebarSubItem(title: "Promote Scholar", page: PromoteScholarsPage(), icon: Icons.upgrade),
        SidebarSubItem(title: "Scholar Statistics", page: ScholarStatsPage(), icon: Icons.insights_rounded),
      ],
    ),
    SidebarCategory(
      title: "Schools",
      icon: Icons.domain,
      subItems: [
        SidebarSubItem(title: "Register School", page: RegisterSchoolPage(), icon: Icons.add_business),
        SidebarSubItem(title: "View Schools", page: ViewSchoolsPage(), icon: Icons.store),
        SidebarSubItem(title: "School Statistics", page: SchoolStatsPage(), icon: Icons.analytics_outlined),
      ],
    ),
    SidebarCategory(
      title: "Sponsors",
      icon: Icons.handshake,
      subItems: [
        SidebarSubItem(title: "Register Sponsor", page: RegisterSponsorPage(), icon: Icons.add_moderator),
        SidebarSubItem(title: "View Sponsors", page: ViewSponsorsPage(), icon: Icons.supervisor_account),
        SidebarSubItem(title: "Sponsor Statistics", page: SponsorStatsPage(), icon: Icons.analytics_rounded),
      ],
    ),
    SidebarCategory(
      title: "Academics",
      icon: Icons.menu_book,
      subItems: [
        SidebarSubItem(title: "Enter Results", page: EnterResultsPage(), icon: Icons.edit_note),
        SidebarSubItem(title: "View Results", page: ViewResultsPage(), icon: Icons.pageview),
        SidebarSubItem(title: "Report Cards", page: ReportCardsPage(), icon: Icons.badge),
        SidebarSubItem(title: "Performance Analysis", page: PerformanceAnalysisPage(), icon: Icons.analytics),
        SidebarSubItem(title: "Academic Statistics", page: AcademicStatsPage(), icon: Icons.insights_rounded),
      ],
    ),
    SidebarCategory(
      title: "Attendance",
      icon: Icons.event_available,
      subItems: [
        SidebarSubItem(title: "Scholar Attendance", page: ScholarAttendancePage(), icon: Icons.how_to_reg),
        SidebarSubItem(title: "Attendance History", page: AttendanceHistoryPage(), icon: Icons.calendar_month),
        SidebarSubItem(title: "Attendance Reports", page: AttendanceModuleReportsPage(), icon: Icons.summarize),
      ],
    ),
    SidebarCategory(
      title: "Reports",
      icon: Icons.analytics,
      subItems: [
        SidebarSubItem(title: "Scholar Reports", page: ScholarReportsPage(), icon: Icons.description),
        SidebarSubItem(title: "School Reports", page: SchoolReportsPage(), icon: Icons.domain_verification),
        SidebarSubItem(title: "Sponsor Reports", page: SponsorReportsPage(), icon: Icons.admin_panel_settings),
        SidebarSubItem(title: "Export PDF", page: ExportPDFPage(), icon: Icons.picture_as_pdf),
        SidebarSubItem(title: "Export Excel", page: ExportExcelPage(), icon: Icons.table_view),
      ],
    ),
    SidebarCategory(
      title: "Users",
      icon: Icons.people_alt,
      subItems: [
        SidebarSubItem(title: "Create User", page: CreateUserPage(), icon: Icons.person_add_alt_1),
        SidebarSubItem(title: "Manage Users", page: ManageUsersPage(), icon: Icons.manage_accounts),
        SidebarSubItem(title: "User Roles", page: UserRolesPage(), icon: Icons.security),
        SidebarSubItem(title: "Permissions", page: PermissionsPage(), icon: Icons.rule),
        SidebarSubItem(title: "User Profile", page: UserProfilePage(), icon: Icons.assignment_ind),
      ],
    ),
    SidebarCategory(
      title: "Settings",
      icon: Icons.settings,
      subItems: [
        SidebarSubItem(title: "Organisation Profile", page: OrganisationProfilePage(), icon: Icons.corporate_fare),
        SidebarSubItem(title: "Backup & Restore", page: BackupRestorePage(), icon: Icons.backup),
        SidebarSubItem(title: "System Settings", page: SystemSettingsPage(), icon: Icons.settings_applications),
        SidebarSubItem(title: "Account Settings", page: AccountSettingsPage(), icon: Icons.manage_accounts),
      ],
    ),
    SidebarCategory(
      title: "Administration",
      icon: Icons.admin_panel_settings,
      subItems: [
        SidebarSubItem(title: "Pending Approvals", page: ApprovalsPage(), icon: Icons.rule_folder),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final activeCategory = categories[activeCategoryIndex];
    final activeSubItem = activeCategory.subItems[activeSubIndex];

    // Brand Color Palette
    const Color brandBrown = Color(0xFF4C3C32);
    const Color brandCream = Color(0xFFFAF2DB);
    const Color brandCreamDark = Color(0xFFF3E7C4);
    const Color brandOlive = Color(0xFF9AB334);
    const Color brandOrange = Color(0xFFE05B1C);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 2,
        shadowColor: brandBrown.withValues(alpha: 0.3),
        backgroundColor: brandBrown,
        leadingWidth: 280,
        leading: Row(
          children: [
            Container(
              width: 220,
              height: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Image.asset(
                'assets/images/age-logo.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(
              width: 60,
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                tooltip: "Toggle Sidebar",
                onPressed: () {
                  setState(() {
                    _isSidebarVisible = !_isSidebarVisible;
                  });
                },
              ),
            ),
          ],
        ),
        title: const Text(
          "Scholar Management System",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            tooltip: "Search Portal",
            onPressed: () async {
              final String? selected = await showSearch<String>(
                context: context,
                delegate: ComponentSearchDelegate(
                  allSubItems: categories.expand((c) => c.subItems).toList(),
                ),
              );
              if (selected != null) {
                _navigateToSubItem(selected);
              }
            },
          ),
          Stack(
            children: [
              ScaleTransition(
                scale: _notificationIconAnimation,
                child: IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  tooltip: "Notifications",
                  onPressed: () {
                    setState(() => _notificationCount = 0); // Clear count locally
                    ApiService.markAllNotificationsRead(); // Mark as read in backend
                    _navigateToSubItem("Notifications");
                  },
                ),
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: ScaleTransition(
                    scale: _notificationIconAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: brandOrange,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: brandBrown, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$_notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          const VerticalDivider(
            color: Colors.white24,
            width: 1,
            indent: 12,
            endIndent: 12,
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _navigateToSubItem("User Profile"),
            child: Text(
              _fullName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              onTap: () => _navigateToSubItem("User Profile"),
              child: CircleAvatar(
                backgroundColor: brandCream,
                radius: 18,
                backgroundImage: _profileImageUrl != null
                  ? NetworkImage('http://localhost:5000${_profileImageUrl}')
                  : null,
                child: _profileImageUrl == null
                  ? Icon(Icons.person, color: brandBrown, size: 20)
                  : null,
              ),
            ),
          )
        ],
      ),
      body: Row(
        children: [
          /// 1. Collapsible Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isSidebarVisible ? 280 : 0,
            child: ClipRect(
              child: OverflowBox(
                minWidth: 280,
                maxWidth: 280,
                alignment: Alignment.centerLeft,
                child: Container(
                  color: brandCream,
                  child: Column(
                    children: [
                      // Sidebar Profile Header Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        color: brandCreamDark,
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: brandBrown,
                              backgroundImage: _profileImageUrl != null
                                ? NetworkImage('http://localhost:5000${_profileImageUrl}')
                                : null,
                              child: _profileImageUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 45,
                                    color: brandCream,
                                  )
                                : null,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _fullName,
                              style: const TextStyle(
                                color: brandBrown,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userRole,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFDCD1B4)),

                      // Navigation Menu Header
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "MAIN NAVIGATION MENU",
                            style: TextStyle(
                              color: brandBrown.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),

                      // Scrollable list of ExpansionTiles
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: categories.length + 1,
                          itemBuilder: (context, index) {
                            if (index == categories.length) {
                              // Logout Button at the bottom
                              return Column(
                                children: [
                                  const Divider(height: 1, color: Color(0xFFDCD1B4)),
                                  ListTile(
                                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                                    title: const Text(
                                      "Logout Session",
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    onTap: () {
                                      ApiService.logout();
                                      Navigator.pushReplacementNamed(context, '/login');
                                    },
                                  ),
                                ],
                              );
                            }

                            final category = categories[index];
                            final isSelectedCategory = activeCategoryIndex == index;

                            return Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                key: PageStorageKey('category_$index'),
                                initiallyExpanded: isSelectedCategory,
                                collapsedIconColor: brandBrown,
                                iconColor: brandOrange,
                                collapsedTextColor: brandBrown,
                                textColor: brandBrown,
                                leading: Icon(category.icon),
                                title: Text(
                                  category.title,
                                  style: TextStyle(
                                    fontWeight: isSelectedCategory ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                children: category.subItems.asMap().entries.map((entry) {
                                  final subIndex = entry.key;
                                  final subItem = entry.value;
                                  final isSelectedSubItem = isSelectedCategory && activeSubIndex == subIndex;

                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelectedSubItem
                                          ? brandOlive.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListTile(
                                      dense: true,
                                      leading: Icon(
                                        subItem.icon,
                                        size: 18,
                                        color: isSelectedSubItem ? brandOrange : Colors.black54,
                                      ),
                                      title: Text(
                                        subItem.title,
                                        style: TextStyle(
                                          color: isSelectedSubItem ? brandOrange : Colors.black87,
                                          fontWeight: isSelectedSubItem ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 13,
                                        ),
                                      ),
                                      trailing: isSelectedSubItem
                                          ? const Icon(Icons.circle, size: 8, color: brandOrange)
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          activeCategoryIndex = index;
                                          activeSubIndex = subIndex;
                                        });
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// 2. Main Content Area
          Expanded(
            child: Column(
              children: [
                // Module Breadcrumb Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Text(
                        activeCategory.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        activeSubItem.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Sub-page Content Render
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: activeSubItem.page,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AgeAfricaHeaderLogo extends StatelessWidget {
  const AgeAfricaHeaderLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/age-logo.png',
          height: 34,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 12),
        Container(
          height: 20,
          width: 1.5,
          color: Colors.white24,
        ),
        const SizedBox(width: 12),
        const Text(
          "Scholar Management System",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class AgeAfricaLogo extends StatelessWidget {
  final Color color;
  final Color accentColor;
  final Color textColor;
  final Color textAccentColor;

  const AgeAfricaLogo({
    super.key,
    this.color = const Color(0xFF6E5637),
    this.accentColor = const Color(0xFF9E8667),
    this.textColor = const Color(0xFF6E5637),
    this.textAccentColor = const Color(0xFF9E8667),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CustomPaint(
          size: const Size(26, 26),
          painter: AgeAfricaLogoPainter(color: color, accentColor: accentColor),
        ),
        const SizedBox(height: 2),
        Text(
          "age",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            fontFamily: 'serif',
            color: textColor,
            height: 0.9,
          ),
        ),
        Text(
          "AFRICA",
          style: TextStyle(
            fontSize: 7,
            letterSpacing: 0.8,
            fontFamily: 'serif',
            color: textAccentColor,
            height: 0.9,
          ),
        ),
      ],
    );
  }
}

class AgeAfricaLogoPainter extends CustomPainter {
  final Color color;
  final Color accentColor;

  const AgeAfricaLogoPainter({
    this.color = const Color(0xFF6E5637),
    this.accentColor = const Color(0xFF9E8667),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 1. Draw head
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.28), size.width * 0.1, paint);

    // 2. Draw mortarboard cap (tilted slightly)
    final capPath = Path();
    capPath.moveTo(size.width * 0.5, size.height * 0.05);
    capPath.lineTo(size.width * 0.72, size.height * 0.14);
    capPath.lineTo(size.width * 0.5, size.height * 0.23);
    capPath.lineTo(size.width * 0.28, size.height * 0.14);
    capPath.close();
    canvas.drawPath(capPath, paint);

    // Cap tassel
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width * 0.72, size.height * 0.14), Offset(size.width * 0.8, size.height * 0.28), linePaint);

    // 3. Draw active leaping body (gown)
    final gownPath = Path();
    gownPath.moveTo(size.width * 0.5, size.height * 0.38);
    gownPath.quadraticBezierTo(size.width * 0.35, size.height * 0.5, size.width * 0.3, size.height * 0.72);
    gownPath.lineTo(size.width * 0.65, size.height * 0.68);
    gownPath.quadraticBezierTo(size.width * 0.6, size.height * 0.5, size.width * 0.5, size.height * 0.38);
    gownPath.close();
    canvas.drawPath(gownPath, paint);

    // 4. Draw legs (leaping stance)
    final legsPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // Left leg
    canvas.drawLine(Offset(size.width * 0.4, size.height * 0.7), Offset(size.width * 0.25, size.height * 0.9), legsPaint);
    // Right leg (bent back)
    final rightLeg = Path();
    rightLeg.moveTo(size.width * 0.58, size.height * 0.68);
    rightLeg.lineTo(size.width * 0.7, size.height * 0.82);
    rightLeg.lineTo(size.width * 0.6, size.height * 0.92);
    canvas.drawPath(rightLeg, legsPaint);

    // 5. Draw diploma/book in hand
    final diplomaPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(size.width * 0.15, size.height * 0.42, size.width * 0.15, size.height * 0.08), diplomaPaint);
  }

  @override
  bool shouldRepaint(covariant AgeAfricaLogoPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.accentColor != accentColor;
  }
}

class ComponentSearchDelegate extends SearchDelegate<String> {
  final List<SidebarSubItem> allSubItems;

  ComponentSearchDelegate({required this.allSubItems});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, "");
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final List<SidebarSubItem> results = allSubItems
        .where((item) => item.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          leading: Icon(item.icon),
          title: Text(item.title),
          onTap: () {
            close(context, item.title);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final List<SidebarSubItem> suggestions = allSubItems
        .where((item) => item.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final item = suggestions[index];
        return ListTile(
          leading: Icon(item.icon),
          title: Text(item.title),
          onTap: () {
            close(context, item.title);
          },
        );
      },
    );
  }
}

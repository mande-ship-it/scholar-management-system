import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../services/api_service.dart';
import '../../academics/academics_utils.dart';

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
  final Widget Function(VoidCallback onBack, Function(String) onPush)? builder;

  const SidebarSubItem({
    required this.title,
    required this.page,
    required this.icon,
    this.builder,
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
  final List<(int, int)> _navigationHistory = [];

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
    IconData icon = Icons.notifications_active;
    Color color = kBrandOlive;
    if (type == 'success') { icon = Icons.check_circle; color = Colors.green; }
    if (type == 'warning') { icon = Icons.warning; color = kBrandOrange; }
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
            _navigationHistory.clear(); // Top-level menu navigation clears history
            activeCategoryIndex = i;
            activeSubIndex = j;
          });
          return;
        }
      }
    }
  }

  void _pushSubItem(String title) {
    for (int i = 0; i < categories.length; i++) {
      for (int j = 0; j < categories[i].subItems.length; j++) {
        if (categories[i].subItems[j].title == title) {
          setState(() {
            _navigationHistory.add((activeCategoryIndex, activeSubIndex));
            activeCategoryIndex = i;
            activeSubIndex = j;
          });
          return;
        }
      }
    }
  }

  void _popSubItem() {
    if (_navigationHistory.isNotEmpty) {
      final prev = _navigationHistory.removeLast();
      setState(() {
        activeCategoryIndex = prev.$1;
        activeSubIndex = prev.$2;
      });
    }
  }

  final List<SidebarCategory> categories = [
    SidebarCategory(
      title: "Dashboard",
      icon: Icons.dashboard,
      subItems: [
        SidebarSubItem(title: "Overview", page: const DashboardPage(), icon: Icons.view_quilt),
        SidebarSubItem(title: "Events & Programs", page: const EventsPage(), icon: Icons.event_available),
        SidebarSubItem(title: "Recent Activities", page: const RecentActivitiesPage(), icon: Icons.history),
        SidebarSubItem(title: "Notifications", page: const NotificationsPage(), icon: Icons.notifications_active),
      ],
    ),
    SidebarCategory(
      title: "Scholars",
      icon: Icons.school,
      subItems: [
        SidebarSubItem(
          title: "Register Scholar",
          page: const RegisterScholarPage(),
          icon: Icons.person_add,
          builder: (onBack, onPush) => RegisterScholarPage(onSuccess: onBack),
        ),
        SidebarSubItem(
          title: "View Scholars",
          page: const ViewScholarsPage(),
          icon: Icons.people,
          builder: (onBack, onPush) => ViewScholarsPage(onRegisterScholar: () => onPush("Register Scholar")),
        ),
        SidebarSubItem(title: "Promote Scholar", page: const PromoteScholarsPage(), icon: Icons.upgrade),
        SidebarSubItem(title: "Scholar Statistics", page: const ScholarStatsPage(), icon: Icons.insights_rounded),
      ],
    ),
    SidebarCategory(
      title: "Schools",
      icon: Icons.domain,
      subItems: [
        SidebarSubItem(
          title: "Register School",
          page: const RegisterSchoolPage(),
          icon: Icons.add_business,
          builder: (onBack, onPush) => RegisterSchoolPage(onSuccess: onBack),
        ),
        SidebarSubItem(
          title: "View Schools",
          page: const ViewSchoolsPage(),
          icon: Icons.store,
          builder: (onBack, onPush) => ViewSchoolsPage(onRegisterSchool: () => onPush("Register School")),
        ),
        SidebarSubItem(title: "School Statistics", page: const SchoolStatsPage(), icon: Icons.analytics_outlined),
      ],
    ),
    SidebarCategory(
      title: "Sponsors",
      icon: Icons.handshake,
      subItems: [
        SidebarSubItem(
          title: "Register Sponsor",
          page: const RegisterSponsorPage(),
          icon: Icons.add_moderator,
          builder: (onBack, onPush) => RegisterSponsorPage(onSuccess: onBack),
        ),
        SidebarSubItem(
          title: "View Sponsors",
          page: const ViewSponsorsPage(),
          icon: Icons.supervisor_account,
          builder: (onBack, onPush) => ViewSponsorsPage(onRegisterSponsor: () => onPush("Register Sponsor")),
        ),
        SidebarSubItem(title: "Sponsor Statistics", page: const SponsorStatsPage(), icon: Icons.analytics_rounded),
      ],
    ),
    SidebarCategory(
      title: "Academics",
      icon: Icons.menu_book,
      subItems: [
        SidebarSubItem(title: "Enter Results", page: const EnterResultsPage(), icon: Icons.edit_note),
        SidebarSubItem(title: "View Results", page: const ViewResultsPage(), icon: Icons.pageview),
        SidebarSubItem(title: "Report Cards", page: const ReportCardsPage(), icon: Icons.badge),
        SidebarSubItem(title: "Performance Analysis", page: const PerformanceAnalysisPage(), icon: Icons.analytics),
        SidebarSubItem(title: "Academic Statistics", page: const AcademicStatsPage(), icon: Icons.insights_rounded),
      ],
    ),
    SidebarCategory(
      title: "Attendance",
      icon: Icons.event_available,
      subItems: [
        SidebarSubItem(title: "Scholar Attendance", page: const ScholarAttendancePage(), icon: Icons.how_to_reg),
        SidebarSubItem(title: "Attendance History", page: const AttendanceHistoryPage(), icon: Icons.calendar_month),
        SidebarSubItem(title: "Attendance Reports", page: const AttendanceModuleReportsPage(), icon: Icons.summarize),
      ],
    ),
    SidebarCategory(
      title: "Reports",
      icon: Icons.analytics,
      subItems: [
        SidebarSubItem(title: "Scholar Reports", page: const ScholarReportsPage(), icon: Icons.description),
        SidebarSubItem(title: "School Reports", page: const SchoolReportsPage(), icon: Icons.domain_verification),
        SidebarSubItem(title: "Sponsor Reports", page: const SponsorReportsPage(), icon: Icons.admin_panel_settings),
        SidebarSubItem(title: "Export PDF", page: const ExportPDFPage(), icon: Icons.picture_as_pdf),
        SidebarSubItem(title: "Export Excel", page: const ExportExcelPage(), icon: Icons.table_view),
      ],
    ),
    SidebarCategory(
      title: "Users",
      icon: Icons.people_alt,
      subItems: [
        SidebarSubItem(title: "Create User", page: const CreateUserPage(), icon: Icons.person_add_alt_1),
        SidebarSubItem(title: "Manage Users", page: const ManageUsersPage(), icon: Icons.manage_accounts),
        SidebarSubItem(title: "User Roles", page: const UserRolesPage(), icon: Icons.security),
        SidebarSubItem(title: "Permissions", page: const PermissionsPage(), icon: Icons.rule),
        SidebarSubItem(title: "User Profile", page: const UserProfilePage(), icon: Icons.assignment_ind),
      ],
    ),
    SidebarCategory(
      title: "Settings",
      icon: Icons.settings,
      subItems: [
        SidebarSubItem(title: "Organisation Profile", page: const OrganisationProfilePage(), icon: Icons.corporate_fare),
        SidebarSubItem(title: "Backup & Restore", page: const BackupRestorePage(), icon: Icons.backup),
        SidebarSubItem(title: "System Settings", page: const SystemSettingsPage(), icon: Icons.settings_applications),
        SidebarSubItem(title: "Account Settings", page: const AccountSettingsPage(), icon: Icons.manage_accounts),
      ],
    ),
    SidebarCategory(
      title: "Administration",
      icon: Icons.admin_panel_settings,
      subItems: [
        SidebarSubItem(title: "Pending Approvals", page: const ApprovalsPage(), icon: Icons.rule_folder),
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
              width: 200,
              height: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Image.asset(
                'assets/images/age-logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
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
                  ? NetworkImage(_profileImageUrl!.startsWith('http')
                      ? _profileImageUrl!
                      : '${ApiService.baseUrl}${_profileImageUrl!.startsWith('/') ? '' : '/'}$_profileImageUrl')
                  : null,
                child: _profileImageUrl == null
                  ? const Icon(Icons.person, color: brandBrown, size: 20)
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
                                ? NetworkImage(_profileImageUrl!.startsWith('http')
                                    ? _profileImageUrl!
                                    : '${ApiService.baseUrl}${_profileImageUrl!.startsWith('/') ? '' : '/'}$_profileImageUrl')
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
                      if (_navigationHistory.isNotEmpty) ...[
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87),
                          onPressed: _popSubItem,
                        ),
                        const SizedBox(width: 8),
                      ],
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
                    child: activeSubItem.builder != null
                        ? activeSubItem.builder!(_popSubItem, _pushSubItem)
                        : activeSubItem.page,
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

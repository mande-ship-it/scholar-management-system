import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../services/api_service.dart';
import '../../academics/academics_utils.dart';

// Admin Dashboard Component
import '../../dashboard/admin_dashboard.dart';

// School Components
import '../schoolPages/register_school.dart';
import '../schoolPages/view_schools.dart';

// Scholar Components
import '../scholarPages/view_scholars.dart';
import '../scholarPages/register_scholar.dart';
import '../scholarPages/graduates_page.dart';

// Sponsor Components
import '../sponsorPages/register_sponsor.dart';
import '../sponsorPages/view_sponsors.dart';

// Academic Components
import '../academicPages/view_results.dart';
import '../academicPages/enter_results.dart';
import '../academicPages/report_cards.dart';
import '../academicPages/performance_analysis.dart';
import '../academicPages/academic_stats.dart';

// User Components
import '../userPages/create_user.dart';
import '../userPages/manage_users.dart';
import '../userPages/user_roles.dart';
import '../userPages/permissions.dart';
import '../userPages/user_profile.dart';
import '../userPages/manage_departments.dart';

// Admin Approvals
import '../admin/approvals_page.dart';

// Settings Components
import '../settingsPages/organisation_profile.dart';
import '../settingsPages/backup_restore.dart';
import '../settingsPages/system_settings.dart';
import '../settingsPages/account_settings.dart';

import '../dashboardPages/notifications.dart';

class AdminSidebarCategory {
  final String title;
  final IconData icon;
  final List<AdminSidebarSubItem> subItems;

  const AdminSidebarCategory({
    required this.title,
    required this.icon,
    required this.subItems,
  });
}

class AdminSidebarSubItem {
  final String title;
  final Widget page;
  final IconData icon;
  final bool isVisible;
  final Widget Function(VoidCallback onBack, Function(String) onPush)? builder;

  const AdminSidebarSubItem({
    required this.title,
    required this.page,
    required this.icon,
    this.isVisible = true,
    this.builder,
  });
}

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> with TickerProviderStateMixin {
  int activeCategoryIndex = 0;
  int activeSubIndex = 0;
  final List<(int, int)> _navigationHistory = [];
  bool _isLoading = true;

  bool _isSidebarVisible = true;
  int _notificationCount = 0;
  IO.Socket? _socket;
  String? _currentUserId;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<AdminSidebarSubItem> _searchResults = [];
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _searchOverlayEntry;

  late AnimationController _notificationIconController;
  late Animation<double> _notificationIconAnimation;

  String _fullName = "Admin";
  String _userRole = "Administrator";
  String? _profileImageUrl;

  late List<AdminSidebarCategory> _categories;

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

    _categories = _getAdminCategories();
    _checkAccess();
    _initSocket();
    _fetchNotificationCount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _fullName == "Admin") {
      setState(() {
        _fullName = args['username'] ?? "Admin";
        _userRole = args['role'] ?? "Administrator";
        _profileImageUrl = args['profilePicture'];
      });
    }
  }

  Future<void> _checkAccess() async {
    try {
      final response = await ApiService.getAccountProfile();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && mounted) {
          final String role = (data['role_name'] ?? "").toString().trim();
          final String normalizedRole = role.toLowerCase();
          
          // Case-insensitive check for Admin access
          if (normalizedRole != 'administrator') {
            _redirectToHome();
          } else {
            setState(() {
              _fullName = data['full_name'] ?? "Admin User";
              _userRole = role;
              _profileImageUrl = data['profile_picture'];
              _currentUserId = data['id'];
              _isLoading = false;
            });
            _joinUserRoom();
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Access check error: $e');
    }
    _redirectToHome();
  }

  void _redirectToHome() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Access Denied: Administrators Only"),
          backgroundColor: Colors.redAccent,
        ),
      );
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _initSocket() {
    _socket = IO.io(ApiService.baseUrl, IO.OptionBuilder()
      .setTransports(['websocket', 'polling'])
      .enableAutoConnect()
      .build());

    _socket!.onConnect((_) {
      debugPrint('Admin connected to Notification Server');
      _joinUserRoom();
    });

    _socket!.onDisconnect((_) {
      debugPrint('Admin disconnected from Notification Server');
    });

    _socket!.on('notification', (data) {
      if (mounted) {
        setState(() {
          _notificationCount++;
        });
        _notificationIconController.forward(from: 0.0).then((_) => _notificationIconController.reverse());
        SystemSound.play(SystemSoundType.click);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            backgroundColor: kBrandBrown,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.security, color: kBrandOlive, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['message'] ?? 'Administrative update received', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                      Text("Synced at: ${DateTime.now().toString().split(' ')[1].split('.')[0]}",
                        style: const TextStyle(fontSize: 10, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  void _joinUserRoom() {
    if (_socket != null && _socket!.connected && _currentUserId != null) {
      _socket!.emit('join', _currentUserId);
    }
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final response = await ApiService.getNotifications();
      if (response.statusCode == 200) {
        final List notifications = response.data['data'];
        if (mounted) {
          final int newCount = notifications.where((n) => n['is_read'] == false).length;
          setState(() {
            _notificationCount = newCount;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _notificationIconController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _removeSearchOverlay();
    super.dispose();
  }

  void _showSearchOverlay() {
    _removeSearchOverlay();
    
    _searchOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _stopSearching,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent, width: double.infinity, height: double.infinity),
          ),
          Positioned(
            width: 450,
            child: CompositedTransformFollower(
              link: _searchLayerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 8),
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 450),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            Text(
                              "ADMIN FEATURES",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey.shade500,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const Spacer(),
                            Text("${_searchResults.length} items found", style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Flexible(
                        child: _searchResults.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  const Text("No admin features found matching your search.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                              itemBuilder: (context, index) {
                                final item = _searchResults[index];
                                return ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: kBrandOlive.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(item.icon, color: kBrandBrown, size: 18),
                                  ),
                                  title: Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kBrandBrown)),
                                  trailing: const Icon(Icons.chevron_right, size: 16),
                                  onTap: () {
                                    _navigateToSubItem(item.title);
                                    _stopSearching();
                                  },
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
        ],
      ),
    );

    Overlay.of(context).insert(_searchOverlayEntry!);
  }

  void _removeSearchOverlay() {
    _searchOverlayEntry?.remove();
    _searchOverlayEntry = null;
  }

  void _startSearching() {
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });
    _searchFocusNode.requestFocus();
  }

  void _stopSearching() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchResults = [];
    });
    _removeSearchOverlay();
    _searchFocusNode.unfocus();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      _removeSearchOverlay();
      return;
    }

    final allSubItems = _getAdminCategories().expand((c) => c.subItems).toList();
    final filtered = allSubItems.where((item) => 
      item.title.toLowerCase().contains(query.toLowerCase())
    ).toList();

    setState(() {
      _searchResults = filtered;
    });

    if (_searchOverlayEntry == null) {
      _showSearchOverlay();
    } else {
      _searchOverlayEntry!.markNeedsBuild();
    }
  }

  void _navigateToSubItem(String title) {
    final categories = _getAdminCategories();
    for (int i = 0; i < categories.length; i++) {
      for (int j = 0; j < categories[i].subItems.length; j++) {
        if (categories[i].subItems[j].title == title) {
          setState(() {
            _navigationHistory.clear();
            activeCategoryIndex = i;
            activeSubIndex = j;
          });
          return;
        }
      }
    }
  }

  void _pushSubItem(String title) {
    final categories = _getAdminCategories();
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

  List<AdminSidebarCategory> _getAdminCategories() {
    return [
      AdminSidebarCategory(
        title: Translator.translate("Dashboard"),
        icon: Icons.dashboard,
        subItems: [
          AdminSidebarSubItem(
            title: Translator.translate("Admin Overview"),
            page: AdminDashboardComponent(onNavigate: _pushSubItem),
            icon: Icons.admin_panel_settings_rounded,
          ),
          AdminSidebarSubItem(title: Translator.translate("Notifications"), page: const NotificationsPage(), icon: Icons.notifications_active),
        ],
      ),
      AdminSidebarCategory(
        title: Translator.translate("Schools"),
        icon: Icons.domain,
        subItems: [
          AdminSidebarSubItem(
            title: Translator.translate("Manage Institutions"),
            page: const ViewSchoolsPage(),
            icon: Icons.domain_verification_rounded,
            builder: (onBack, onPush) => ViewSchoolsPage(onRegisterSchool: () => onPush("Register School")),
          ),
          AdminSidebarSubItem(
            title: Translator.translate("Register School"),
            page: const RegisterSchoolPage(),
            icon: Icons.add_business_rounded,
            isVisible: false,
            builder: (onBack, onPush) => RegisterSchoolPage(onSuccess: onBack),
          ),
        ],
      ),
      AdminSidebarCategory(
        title: "Sponsorship & Funds",
        icon: Icons.volunteer_activism_rounded,
        subItems: [
          AdminSidebarSubItem(
            title: "Sponsors Directory",
            page: const ViewSponsorsPage(),
            icon: Icons.supervised_user_circle_rounded,
            builder: (onBack, onPush) => ViewSponsorsPage(onRegisterSponsor: () => onPush("Register Sponsor")),
          ),
          AdminSidebarSubItem(
            title: "Register Sponsor",
            page: const RegisterSponsorPage(),
            icon: Icons.person_add_alt_1_rounded,
            isVisible: false,
            builder: (onBack, onPush) => RegisterSponsorPage(onSuccess: () => onPush("Sponsors Directory")),
          ),
        ],
      ),
      AdminSidebarCategory(
        title: "Users",
        icon: Icons.people_alt,
        subItems: [
          AdminSidebarSubItem(
            title: "Manage Users",
            page: ManageUsersPage(
              onAddUser: () => _pushSubItem("Create User"),
              onViewRoles: () => _pushSubItem("User Roles"),
              onViewDepartments: () => _pushSubItem("Manage Departments"),
              onViewPermissions: () => _pushSubItem("Permissions"),
              onViewProfile: () => _pushSubItem("User Profile"),
            ),
            icon: Icons.manage_accounts,
          ),
          AdminSidebarSubItem(
            title: "Create User",
            page: const CreateUserPage(),
            icon: Icons.person_add_alt_1,
            isVisible: false,
          ),
          AdminSidebarSubItem(title: "User Roles", page: const UserRolesPage(), icon: Icons.security, isVisible: false),
          AdminSidebarSubItem(title: "Manage Departments", page: const ManageDepartmentsPage(), icon: Icons.apartment_rounded, isVisible: false),
          AdminSidebarSubItem(title: "Permissions", page: const PermissionsPage(), icon: Icons.rule, isVisible: false),
          AdminSidebarSubItem(title: "User Profile", page: const UserProfilePage(), icon: Icons.assignment_ind, isVisible: false),
        ],
      ),
      AdminSidebarCategory(
        title: "System Operations",
        icon: Icons.settings_system_daydream_rounded,
        subItems: [
          AdminSidebarSubItem(
            title: "Pending Approvals",
            page: ApprovalsPage(userRole: _userRole),
            icon: Icons.rule_folder_rounded,
            builder: (onBack, onPush) => ApprovalsPage(userRole: _userRole),
          ),
        ],
      ),
      AdminSidebarCategory(
        title: "Settings",
        icon: Icons.settings,
        subItems: [
          AdminSidebarSubItem(title: "User Profile", page: const UserProfilePage(), icon: Icons.assignment_ind),
          AdminSidebarSubItem(title: "Organisation Profile", page: const OrganisationProfilePage(), icon: Icons.corporate_fare),
          AdminSidebarSubItem(title: "Backup & Restore", page: const BackupRestorePage(), icon: Icons.backup),
          AdminSidebarSubItem(title: "System Settings", page: const SystemSettingsPage(), icon: Icons.settings_applications),
          AdminSidebarSubItem(title: "Account Settings", page: const AccountSettingsPage(), icon: Icons.manage_accounts),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: kBrandOlive)),
      );
    }

    final activeCategory = _categories[activeCategoryIndex];
    final activeSubItem = activeCategory.subItems[activeSubIndex];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        elevation: 2,
        shadowColor: kBrandBrown.withOpacity(0.3),
        backgroundColor: kBrandBrown,
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
        title: _isSearching
          ? Container(
              alignment: Alignment.centerLeft,
              width: 450,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: CompositedTransformTarget(
                link: _searchLayerLink,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: kBrandBrown, fontSize: 14, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: "Search admin features, pages, controls...",
                    hintStyle: TextStyle(color: kBrandBrown.withOpacity(0.4)),
                    prefixIcon: const Icon(Icons.search, color: kBrandOlive, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                      onPressed: _stopSearching,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            )
          : Row(
              children: [
                const Text(
                  "AGE Africa System",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kBrandOrange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "SECURE",
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                  ),
                ),
              ],
            ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              tooltip: "Search Portal",
              onPressed: _startSearching,
            ),
          Stack(
            children: [
              ScaleTransition(
                scale: _notificationIconAnimation,
                child: IconButton(
                  icon: const Icon(Icons.notifications_active_rounded, color: Colors.white),
                  tooltip: "Notifications",
                  onPressed: () {
                    setState(() => _notificationCount = 0);
                    ApiService.markAllNotificationsRead();
                    _navigateToSubItem("Notifications");
                  },
                ),
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: kBrandOrange,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kBrandBrown, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$_notificationCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          const VerticalDivider(color: Colors.white24, width: 1, indent: 12, endIndent: 12),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _navigateToSubItem("User Profile"),
            child: SizedBox(
              width: 120,
              child: _MovingText(
                text: _fullName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'profile') {
                  _navigateToSubItem("User Profile");
                } else if (value == 'logout') {
                  ApiService.logout();
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 20, color: kBrandBrown),
                      const SizedBox(width: 12),
                      const Text("View Profile", style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
              child: CircleAvatar(
                backgroundColor: kBrandCream,
                radius: 18,
                child: ClipOval(
                  child: _profileImageUrl != null
                      ? Image.network(
                          ApiService.getFullUrl(_profileImageUrl),
                          fit: BoxFit.cover,
                          width: 36,
                          height: 36,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person_rounded, color: kBrandBrown, size: 20),
                        )
                      : const Icon(Icons.person_rounded, color: kBrandBrown, size: 20),
                ),
              ),
            ),
          )
        ],
      ),
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isSidebarVisible ? 280 : 0,
            child: _isSidebarVisible 
              ? Container(
                  color: kBrandCream,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        color: kBrandCreamDark,
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: kBrandBrown,
                              child: ClipOval(
                                child: _profileImageUrl != null
                                    ? Image.network(
                                        ApiService.getFullUrl(_profileImageUrl),
                                        fit: BoxFit.cover,
                                        width: 80,
                                        height: 80,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.person_rounded, size: 45, color: kBrandCream),
                                      )
                                    : const Icon(Icons.person_rounded, size: 45, color: kBrandCream),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _fullName,
                              style: const TextStyle(color: kBrandBrown, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userRole.toUpperCase(),
                              style: const TextStyle(color: kBrandOrange, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFDCD1B4)),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "ADMINISTRATIVE SERVICES",
                            style: TextStyle(
                              color: kBrandBrown.withOpacity(0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: _categories.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _categories.length) {
                              return Column(
                                children: [
                                  const Divider(height: 1, color: Color(0xFFDCD1B4)),
                                  ListTile(
                                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                                    title: const Text(
                                      "Logout Session",
                                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    onTap: () {
                                      ApiService.logout();
                                      Navigator.pushReplacementNamed(context, '/login');
                                    },
                                  ),
                                ],
                              );
                            }

                            final category = _categories[index];
                            final isSelectedCategory = activeCategoryIndex == index;

                            return Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                key: PageStorageKey('admin_cat_${category.title}'),
                                initiallyExpanded: isSelectedCategory,
                                collapsedIconColor: kBrandBrown,
                                iconColor: kBrandOrange,
                                collapsedTextColor: kBrandBrown,
                                textColor: kBrandBrown,
                                leading: Icon(category.icon),
                                title: Text(
                                  category.title,
                                  style: TextStyle(fontWeight: isSelectedCategory ? FontWeight.bold : FontWeight.w500, fontSize: 14),
                                ),
                                children: category.subItems.where((s) => s.isVisible).map((subItem) {
                                  int subIdx = category.subItems.indexOf(subItem);
                                  final isSelectedSubItem = isSelectedCategory && activeSubIndex == subIdx;

                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelectedSubItem ? kBrandOlive.withOpacity(0.15) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListTile(
                                      dense: true,
                                      leading: Icon(subItem.icon, size: 18, color: isSelectedSubItem ? kBrandOrange : Colors.black54),
                                      title: Text(
                                        subItem.title,
                                        style: TextStyle(
                                          color: isSelectedSubItem ? kBrandOrange : Colors.black87,
                                          fontWeight: isSelectedSubItem ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 13,
                                        ),
                                      ),
                                      trailing: isSelectedSubItem ? const Icon(Icons.circle, size: 8, color: kBrandOrange) : null,
                                      onTap: () {
                                        setState(() {
                                          activeCategoryIndex = index;
                                          activeSubIndex = subIdx;
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
                )
              : const SizedBox.shrink(),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      if (_navigationHistory.isNotEmpty && activeSubItem.title != "Pending Approvals") ...[
                        IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: _popSubItem),
                        const SizedBox(width: 8),
                      ],
                      Text(activeCategory.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black54)),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(activeSubItem.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ),
                const Divider(height: 1),
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

  bool isSubSelected(bool catSelected, int activeSub, int currentSub) {
    return catSelected && activeSub == currentSub;
  }
}

class _MovingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _MovingText({required this.text, required this.style});

  @override
  State<_MovingText> createState() => _MovingTextState();
}

class _MovingTextState extends State<_MovingText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    while (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) break;
      await _scrollController.animateTo(
        maxScroll,
        duration: Duration(milliseconds: (maxScroll * 40).toInt()),
        curve: Curves.linear,
      );
      if (!mounted) break;
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) break;
      _scrollController.jumpTo(0.0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(widget.text, style: widget.style, maxLines: 1),
    );
  }
}

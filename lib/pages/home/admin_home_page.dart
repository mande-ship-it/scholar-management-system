import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:scholar_management_system/services/api_service.dart';
import 'package:scholar_management_system/services/socket_service.dart';
import 'package:scholar_management_system/academics/academics_utils.dart';
import 'package:scholar_management_system/dashBoard/admin_dashboard.dart';
import 'package:scholar_management_system/pages/eventPages/events.dart';
import 'package:scholar_management_system/pages/schoolPages/register_school.dart';
import 'package:scholar_management_system/pages/schoolPages/view_schools.dart';
import 'package:scholar_management_system/pages/sponsorPages/register_sponsor.dart';
import 'package:scholar_management_system/pages/sponsorPages/view_sponsors.dart';
import 'package:scholar_management_system/pages/userPages/create_user.dart';
import 'package:scholar_management_system/pages/userPages/manage_users.dart';
import 'package:scholar_management_system/pages/userPages/user_roles.dart';
import 'package:scholar_management_system/pages/userPages/permissions.dart';
import 'package:scholar_management_system/pages/userPages/user_profile.dart';
import 'package:scholar_management_system/pages/userPages/manage_departments.dart';
import 'package:scholar_management_system/pages/admin/approvals_page.dart';
import 'package:scholar_management_system/pages/settingsPages/organisation_profile.dart';
import 'package:scholar_management_system/pages/settingsPages/backup_restore.dart';
import 'package:scholar_management_system/pages/settingsPages/system_settings.dart';
import 'package:scholar_management_system/pages/settingsPages/account_settings.dart';
import 'package:scholar_management_system/pages/dashboardPages/notifications.dart';

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
    SocketService.addCallListener(_handleIncomingCall);
    _fetchNotificationCount();
  }

  void _handleIncomingCall(Map<String, dynamic> data) {
    if (!mounted) return;
    
    final String caller = data['callerName'] ?? 'Someone';
    final String meetingId = data['meetingId'];
    final bool isVideo = data['isVideo'] ?? true;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Incoming Call",
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: kBrandOlive.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: kBrandOlive, width: 2),
                  ),
                  child: const Icon(Icons.person_rounded, size: 60, color: kBrandOlive),
                ),
                const SizedBox(height: 24),
                Text(caller.toUpperCase(), 
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text("Incoming ${isVideo ? 'Video' : 'Audio'} Call...", 
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _callActionBtn(Icons.close_rounded, Colors.red, () => Navigator.pop(ctx)),
                    const SizedBox(width: 40),
                    _callActionBtn(Icons.videocam_rounded, kBrandOlive, () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, '/events/live-meeting-join', arguments: {'id': meetingId});
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _callActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
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
          
          final bool isStrictAdmin = normalizedRole == 'administrator';

          if (!isStrictAdmin) {
            _redirectToHome();
          } else {
            setState(() {
              _fullName = data['full_name'] ?? "Admin User";
              _userRole = role;
              _profileImageUrl = data['profile_picture'];
              _currentUserId = data['id'];
              _isLoading = false;
              if (_currentUserId != null) SocketService.init(_currentUserId!);
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Access check error: $e');
    }
    // Only redirect if we explicitly failed the checks above
    if (mounted && _isLoading) {
      _redirectToHome();
    }
  }

  void _redirectToHome() {
    if (mounted) {
      debugPrint('ADMIN PORTAL: Access Denied. Redirecting to General Dashboard.');
      Navigator.pushReplacementNamed(context, '/home');
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
    SocketService.removeCallListener(_handleIncomingCall);
    _notificationIconController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _removeSearchOverlay();
    super.dispose();
  }

  void _showSearchOverlay() {
    _removeSearchOverlay();
    
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;
    
    _searchOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _stopSearching,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent, width: double.infinity, height: double.infinity),
          ),
          Positioned(
            width: isMobile ? screenWidth * 0.9 : 450,
            left: isMobile ? screenWidth * 0.05 : null,
            child: CompositedTransformFollower(
              link: _searchLayerLink,
              showWhenUnlinked: false,
              targetAnchor: isMobile ? Alignment.bottomCenter : Alignment.bottomLeft,
              followerAnchor: isMobile ? Alignment.topCenter : Alignment.topLeft,
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
        title: "Activities",
        icon: Icons.event_available_rounded,
        subItems: [
          const AdminSidebarSubItem(
            title: "Events & Programs",
            page: EventsPage(),
            icon: Icons.calendar_month_rounded,
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

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;

    final activeCategory = _categories[activeCategoryIndex];
    final activeSubItem = activeCategory.subItems[activeSubIndex];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: isMobile ? _buildDrawer(context) : null,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: kBrandBrown,
        foregroundColor: Colors.white,
        leadingWidth: isMobile ? null : 280,
        leading: isMobile 
          ? IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            )
          : Row(
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
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 20),
                  tooltip: "Toggle Sidebar",
                  onPressed: () {
                    setState(() {
                      _isSidebarVisible = !_isSidebarVisible;
                    });
                  },
                ),
              ],
            ),
        title: _isSearching
          ? Container(
              alignment: Alignment.centerLeft,
              width: isMobile ? null : 450,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: CompositedTransformTarget(
                link: _searchLayerLink,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: isMobile ? "Search..." : "Search admin features, pages, controls...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                      onPressed: _stopSearching,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            )
          : Text(isMobile ? activeSubItem.title : "AGE Africa Management Portal", 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.5)),
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
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
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
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 18),
                    child: Text(
                      '$_notificationCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            VerticalDivider(color: Colors.white.withOpacity(0.2), width: 1, indent: 16, endIndent: 16),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _navigateToSubItem("User Profile"),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 120,
                    child: _MovingText(
                      text: _fullName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),
                  Text(_userRole.toUpperCase(), style: const TextStyle(color: kBrandOlive, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ],
              ),
            ),
          ],
          const SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(right: isMobile ? 12 : 20),
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
          if (!isMobile)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: _isSidebarVisible ? 280 : 0,
              child: _isSidebarVisible ? _buildSidebar() : const SizedBox.shrink(),
            ),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  child: Row(
                    children: [
                      if (_navigationHistory.isNotEmpty && activeSubItem.title != "Pending Approvals") ...[
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kBrandBrown, size: 14), 
                          onPressed: _popSubItem,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (!isMobile) ...[
                        GestureDetector(
                          onTap: () => _navigateToSubItem("Admin Overview"),
                          child: Text(activeCategory.title.toUpperCase(), 
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1))),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 12),
                        ),
                      ],
                      Expanded(
                        child: Text(activeSubItem.title, 
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: isMobile ? 14 : 12, fontWeight: FontWeight.w900, color: kBrandBrown)),
                      ),
                      if (!isMobile) ...[
                        const SizedBox(width: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: kBrandOlive.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 10, color: kBrandOlive),
                              const SizedBox(width: 6),
                              Text(DateFormat('d MMM yyyy').format(DateTime.now()), 
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: kBrandOlive)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 0 : 20),
                    child: activeSubItem.builder != null
                      ? activeSubItem.builder!(_popSubItem, _pushSubItem)
                      : activeSubItem.page,
                  ),
                ),
                _buildPortalFooter(isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortalFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("© 2026 AGE Africa Management Portal", 
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
          if (!isMobile)
            Row(
              children: [
                _footerLink("System Privacy"),
                const SizedBox(width: 20),
                _footerLink("User Manual"),
                const SizedBox(width: 20),
                _footerLink("Technical Support"),
              ],
            ),
        ],
      ),
    );
  }

  Widget _footerLink(String label) {
    return Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kBrandOlive));
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      width: 280,
      backgroundColor: kBrandCream,
      child: _buildSidebar(isDrawer: true),
    );
  }

  Widget _buildSidebar({bool isDrawer = false}) {
    const Color brandBrown = Color(0xFF4C3C32);
    const Color brandCream = Color(0xFFFAF2DB);
    const Color brandCreamDark = Color(0xFFF3E7C4);
    const Color brandOlive = Color(0xFF9AB334);

    return Container(
      decoration: const BoxDecoration(
        color: brandCream,
        border: Border(right: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        children: [
          // Sidebar Profile Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            color: brandCreamDark,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: brandOlive.withOpacity(0.2), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: brandBrown,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(ApiService.getFullUrl(_profileImageUrl))
                        : null,
                    child: _profileImageUrl == null
                        ? const Icon(Icons.admin_panel_settings_rounded, size: 40, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: brandBrown, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: brandOlive.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _userRole.toUpperCase(),
                    style: const TextStyle(color: brandOlive, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Navigation Menu Header
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 24, right: 16, bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "SYSTEM NAVIGATION",
                style: TextStyle(
                  color: brandBrown.withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          // Scrollable list of ExpansionTiles
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelectedCategory = activeCategoryIndex == index;

                return Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    hoverColor: brandCreamDark.withOpacity(0.3),
                  ),
                  child: ExpansionTile(
                    key: PageStorageKey('admin_cat_${category.title}'),
                    initiallyExpanded: isSelectedCategory,
                    collapsedIconColor: brandBrown.withOpacity(0.5),
                    iconColor: brandOlive,
                    collapsedTextColor: brandBrown,
                    textColor: brandBrown,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(category.icon, size: 20),
                    title: Text(
                      category.title,
                      style: TextStyle(
                        fontWeight: isSelectedCategory ? FontWeight.w900 : FontWeight.w600,
                        fontSize: 13,
                        color: isSelectedCategory ? brandBrown : brandBrown.withOpacity(0.7),
                      ),
                    ),
                    children: category.subItems.where((s) => s.isVisible).map((subItem) {
                      int subIdx = category.subItems.indexOf(subItem);
                      final isSelectedSubItem = isSelectedCategory && activeSubIndex == subIdx;

                      return Container(
                        margin: const EdgeInsets.only(left: 8, bottom: 2),
                        decoration: BoxDecoration(
                          color: isSelectedSubItem
                              ? brandOlive.withOpacity(0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                          leading: Icon(
                            subItem.icon,
                            size: 16,
                            color: isSubSelected(isSelectedCategory, activeSubIndex, subIdx) ? brandOlive : brandBrown.withOpacity(0.4),
                          ),
                          title: Text(
                            subItem.title,
                            style: TextStyle(
                              color: isSubSelected(isSelectedCategory, activeSubIndex, subIdx) ? brandBrown : brandBrown.withOpacity(0.6),
                              fontWeight: isSubSelected(isSelectedCategory, activeSubIndex, subIdx) ? FontWeight.w900 : FontWeight.w500,
                              fontSize: 12.5,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              activeCategoryIndex = index;
                              activeSubIndex = subIdx;
                            });
                            if (isDrawer) Navigator.pop(context);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
              title: const Text(
                "End Session",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 13),
              ),
              onTap: () {
                ApiService.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
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

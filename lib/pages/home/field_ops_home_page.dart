import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../services/api_service.dart';
import '../../academics/academics_utils.dart';

// Dashboard & Core Components
import '../../dashBoard/field_operations_dashboard.dart';
import '../dashboardPages/notifications.dart';
import '../../users/user_profile.dart';

// Operations Components (Direct Components)
import '../../academics/enter_results.dart';
import '../../academics/performance_analysis.dart';
import '../../scholars/scholar_profile.dart';
import '../../scholars/view_scholars.dart';

// Operation Pages (Scaffolded Page)
import 'package:scholar_management_system/pages/scholarPages/view_scholars.dart';
import 'package:scholar_management_system/pages/scholarPages/register_scholar.dart';
import 'package:scholar_management_system/pages/schoolPages/view_schools.dart';
import 'package:scholar_management_system/pages/schoolPages/register_school.dart';
import 'package:scholar_management_system/pages/attendancePages/scholar_attendance.dart';
import 'package:scholar_management_system/pages/academicPages/performance_analysis.dart';

class FieldOpsSidebarCategory {
  final String title;
  final IconData icon;
  final List<FieldOpsSidebarSubItem> subItems;

  const FieldOpsSidebarCategory({
    required this.title,
    required this.icon,
    required this.subItems,
  });
}

class FieldOpsSidebarSubItem {
  final String title;
  final Widget page;
  final IconData icon;
  final bool isVisible;
  final Widget Function(VoidCallback onBack, Function(String) onPush, Function(String) onPushProfile)? builder;

  const FieldOpsSidebarSubItem({
    required this.title,
    required this.page,
    required this.icon,
    this.isVisible = true,
    this.builder,
  });
}

class FieldOpsHomePage extends StatefulWidget {
  const FieldOpsHomePage({super.key});

  @override
  State<FieldOpsHomePage> createState() => _FieldOpsHomePageState();
}

class _FieldOpsHomePageState extends State<FieldOpsHomePage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int activeCategoryIndex = 0;
  int activeSubIndex = 0;
  final List<(int, int, String?)> _navigationHistory = [];
  String? _currentDetailScholarId;

  bool _isLoading = true;
  bool _isSidebarVisible = true;
  int _notificationCount = 0;
  IO.Socket? _socket;
  String? _currentUserId;

  String _fullName = "Field Officer";
  String _userRole = "Field Officer";
  String? _profileImageUrl;

  late List<FieldOpsSidebarCategory> _categories;

  bool _isAccessChecked = false;

  @override
  void initState() {
    super.initState();
    activeCategoryIndex = 0;
    activeSubIndex = 0;
    _categories = _getFieldOpsCategories();
    _initSocket();
    _fetchNotificationCount();
    
    // Safety: ensure loading spinner doesn't stay forever
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        if (_isLoading) {
          debugPrint("FIELD OPS: Safety timeout reached, forcing load completion.");
          setState(() => _isLoading = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isAccessChecked) {
      _isAccessChecked = true;
      // Use microtask or delay to ensure initState is fully complete
      Future.microtask(() => _checkAccess());
    }
  }

  Future<void> _checkAccess() async {
    if (!mounted) return;
    debugPrint('FIELD OPS: Starting access check...');

    final List<String> fieldRoles = [
      'field officer',
      'field coordinator',
      'field operations',
      'operational officer'
    ];

    // 1. Try to use arguments from navigation if available
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('role')) {
      final String role = args['role'].toString().trim();
      final String normalizedRole = role.toLowerCase();
      
      if (fieldRoles.contains(normalizedRole)) {
        debugPrint('FIELD OPS: Using navigation arguments.');
        if (mounted) {
          setState(() {
            _fullName = args['username'] ?? "Field User";
            _userRole = role;
            _profileImageUrl = args['profilePicture'];
            _isLoading = false;
          });
        }
        return;
      }
    }

    // 2. Fallback to API check
    bool granted = false;
    try {
      debugPrint('FIELD OPS: Calling profile API...');
      final response = await ApiService.getAccountProfile();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && mounted) {
          final String role = (data['role_name'] ?? "").toString().trim();
          final String normalizedRole = role.toLowerCase();

          debugPrint('FIELD OPS CHECK: role=$role, isFieldOfficer=${fieldRoles.contains(normalizedRole)}');

          if (fieldRoles.contains(normalizedRole)) {
            granted = true;
            setState(() {
              _fullName = data['full_name'] ?? "Field User";
              _userRole = role;
              _profileImageUrl = data['profile_picture'];
              _currentUserId = data['id'];
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('FIELD OPS Error: $e');
    }

    if (!granted && mounted) {
      debugPrint('FIELD OPS: Access not granted, redirecting...');
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _initSocket() {
    _socket = IO.io(ApiService.baseUrl, IO.OptionBuilder()
      .setTransports(['websocket', 'polling'])
      .enableAutoConnect()
      .build());
    _socket!.onConnect((_) => debugPrint('Field Ops connected to socket'));
  }

  Future<void> _fetchNotificationCount() async {
    try {
      final response = await ApiService.getNotifications();
      if (response.statusCode == 200 && mounted) {
        final List? notifications = response.data['data'];
        if (notifications != null) {
          setState(() {
            _notificationCount = notifications.where((n) => n['is_read'] == false).length;
          });
        }
      }
    } catch (e) {
      debugPrint("NOTIFICATION COUNT Error: $e");
    }
  }

  List<FieldOpsSidebarCategory> _getFieldOpsCategories() {
    return [
      FieldOpsSidebarCategory(
        title: "Main Dashboard",
        icon: Icons.dashboard_rounded,
        subItems: [
          FieldOpsSidebarSubItem(
            title: "Command Center",
            page: const SizedBox(),
            icon: Icons.analytics_rounded,
            builder: (onBack, onPush, onPushProfile) => FieldOperationsDashboard(onNavigate: onPush),
          ),
          FieldOpsSidebarSubItem(
            title: "Notifications",
            page: const SizedBox(),
            icon: Icons.notifications_active_rounded,
            builder: (onBack, onPush, onPushProfile) => const NotificationsPage(),
          ),
        ],
      ),
      FieldOpsSidebarCategory(
        title: "Field Operations",
        icon: Icons.explore_rounded,
        subItems: [
          FieldOpsSidebarSubItem(
            title: "Secondary Registry",
            page: const SizedBox(),
            icon: Icons.school_outlined,
            builder: (onBack, onPush, onPushProfile) => ViewScholarsPage(
              onViewProfile: onPushProfile,
              forcedSchoolType: 'Secondary',
              hideUniversity: true,
              onRegisterScholar: () => onPush("Register Scholar"),
              onViewGraduates: () => onPush("University Graduates"),
            ),
          ),
          FieldOpsSidebarSubItem(
            title: "University Registry",
            page: const SizedBox(),
            icon: Icons.account_balance_outlined,
            builder: (onBack, onPush, onPushProfile) => ViewScholarsPage(
              onViewProfile: onPushProfile,
              forcedSchoolType: 'University',
              hideUniversity: false,
              hideRegistration: true, // Universities usually handled by HQ
              onRegisterScholar: () => onPush("Register Scholar"),
              onViewGraduates: () => onPush("University Graduates"),
            ),
          ),
          FieldOpsSidebarSubItem(
            title: "Register Scholar",
            page: const SizedBox(),
            icon: Icons.person_add_rounded,
            isVisible: false,
            builder: (onBack, onPush, onPushProfile) => RegisterScholarPage(onSuccess: onBack, forcedSchoolType: 'Secondary'),
          ),
          FieldOpsSidebarSubItem(
            title: "Institutions",
            page: const SizedBox(),
            icon: Icons.domain_rounded,
            builder: (onBack, onPush, onPushProfile) => const ViewSchoolsPage(
              forcedLevel: 'Secondary School',
              hideRegistration: true,
            ),
          ),
          FieldOpsSidebarSubItem(
            title: "Take Attendance",
            page: const SizedBox(),
            icon: Icons.how_to_reg_rounded,
            builder: (onBack, onPush, onPushProfile) => const ScholarAttendancePage(forcedSchoolType: SchoolType.secondary),
          ),
          FieldOpsSidebarSubItem(
            title: "Enter Results",
            page: const SizedBox(),
            icon: Icons.edit_note_rounded,
            builder: (onBack, onPush, onPushProfile) => const AcademicsManagementComponent(forcedSchoolType: SchoolType.secondary),
          ),
          FieldOpsSidebarSubItem(
            title: "Performance Analysis",
            page: const SizedBox(),
            icon: Icons.insights_rounded,
            builder: (onBack, onPush, onPushProfile) => PerformanceAnalysisPage(forcedSchoolType: SchoolType.secondary),
          ),
        ],
      ),
      FieldOpsSidebarCategory(
        title: "Account",
        icon: Icons.person_rounded,
        subItems: [
          FieldOpsSidebarSubItem(
            title: "User Profile",
            page: const SizedBox(),
            icon: Icons.assignment_ind_rounded,
            builder: (onBack, onPush, onPushProfile) => const UserProfileComponent(),
          ),
        ],
      ),
    ];
  }

  void _navigateToSubItem(String title) {
    for (int i = 0; i < _categories.length; i++) {
      for (int j = 0; j < _categories[i].subItems.length; j++) {
        if (_categories[i].subItems[j].title == title) {
          setState(() {
            _navigationHistory.clear();
            _currentDetailScholarId = null;
            activeCategoryIndex = i;
            activeSubIndex = j;
          });
          return;
        }
      }
    }
  }

  void _pushSubItem(String title) {
    for (int i = 0; i < _categories.length; i++) {
      for (int j = 0; j < _categories[i].subItems.length; j++) {
        if (_categories[i].subItems[j].title == title) {
          setState(() {
            _navigationHistory.add((activeCategoryIndex, activeSubIndex, _currentDetailScholarId));
            _currentDetailScholarId = null;
            activeCategoryIndex = i;
            activeSubIndex = j;
          });
          return;
        }
      }
    }
  }

  void _pushScholarProfile(String id) {
    setState(() {
      _navigationHistory.add((activeCategoryIndex, activeSubIndex, _currentDetailScholarId));
      _currentDetailScholarId = id;
    });
  }

  void _popSubItem() {
    if (_navigationHistory.isNotEmpty) {
      final prev = _navigationHistory.removeLast();
      setState(() {
        activeCategoryIndex = prev.$1;
        activeSubIndex = prev.$2;
        _currentDetailScholarId = prev.$3;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;

    final activeCategory = _categories[activeCategoryIndex];
    final activeSubItem = activeCategory.subItems[activeSubIndex];
    debugPrint("FIELD OPS BUILD: Rendering Category=$activeCategoryIndex, SubItem=$activeSubIndex (${activeSubItem.title})");

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: isMobile ? _buildDrawer(context) : null,
      endDrawer: isMobile ? _buildEndDrawer(context) : null,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: kBrandBrown,
        foregroundColor: Colors.white,
        leadingWidth: isMobile ? 56 : 280,
        leading: isMobile 
          ? IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 24),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            )
          : Row(
              children: [
                Container(
                  width: 200,
                  height: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Image.asset('assets/images/age-logo.png', fit: BoxFit.contain),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 20), 
                  onPressed: () => setState(() => _isSidebarVisible = !_isSidebarVisible)),
              ],
            ),
        title: Text(isMobile ? activeSubItem.title : "Field Operations Portal", 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Colors.white), onPressed: () {
            for (int i = 0; i < _categories.length; i++) {
              final idx = _categories[i].subItems.indexWhere((s) => s.title == "Notifications");
              if (idx != -1) {
                setState(() { activeCategoryIndex = i; activeSubIndex = idx; });
                break;
              }
            }
          }),
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
            child: isMobile 
              ? GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: kBrandCream,
                    child: ClipOval(
                      child: _profileImageUrl != null
                          ? Image.network(
                              ApiService.getFullUrl(_profileImageUrl),
                              fit: BoxFit.cover,
                              width: 36,
                              height: 36,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person, color: kBrandBrown, size: 20),
                            )
                          : const Icon(Icons.person, color: kBrandBrown, size: 20),
                    ),
                  ),
                )
              : PopupMenuButton<String>(
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
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 20, color: kBrandBrown),
                          SizedBox(width: 12),
                          Text("View Profile", style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
                          SizedBox(width: 12),
                          Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: kBrandCream,
                    child: ClipOval(
                      child: _profileImageUrl != null
                          ? Image.network(
                              ApiService.getFullUrl(_profileImageUrl),
                              fit: BoxFit.cover,
                              width: 36,
                              height: 36,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person, color: kBrandBrown, size: 20),
                            )
                          : const Icon(Icons.person, color: kBrandBrown, size: 20),
                    ),
                  ),
                ),
          ),
        ],
      ),
      body: Row(
        children: [
          if (!isMobile && _isSidebarVisible)
            _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                if (!isMobile)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  child: Row(
                    children: [
                      if (_navigationHistory.isNotEmpty && activeSubItem.title != "Pending Approvals") ...[
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kBrandBrown, size: 12), 
                          onPressed: _popSubItem,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (!isMobile) ...[
                        GestureDetector(
                          onTap: () => setState(() {
                            activeCategoryIndex = 0;
                            activeSubIndex = 0;
                            _navigationHistory.clear();
                            _currentDetailScholarId = null;
                          }),
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
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kBrandBrown)),
                      ),
                    ],
                  ),
                ),
                if (!isMobile) const Divider(height: 1),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 0 : 24),
                    child: _currentDetailScholarId != null
                      ? ScholarProfileComponent(scholarId: _currentDetailScholarId, onBack: _popSubItem)
                      : activeSubItem.builder != null
                        ? activeSubItem.builder!(_popSubItem, _pushSubItem, _pushScholarProfile)
                        : const Center(child: Text("Component not configured.")),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      width: 280,
      backgroundColor: kBrandCream,
      child: _buildSidebar(isDrawer: true),
    );
  }

  Widget _buildEndDrawer(BuildContext context) {
    return Drawer(
      width: 280,
      backgroundColor: kBrandCream,
      child: Column(
        children: [
          _buildUserHeader(),
          const Divider(height: 1),
          const Spacer(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person_outline, color: kBrandBrown),
            title: const Text("View Profile", style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context);
              _navigateToSubItem("User Profile");
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              ApiService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebar({bool isDrawer = false}) {

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: kBrandCream,
        border: Border(right: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        children: [
          _buildUserHeader(),
          const Divider(height: 1),
          
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 24, right: 16, bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "FIELD OPERATIONS",
                style: TextStyle(
                  color: kBrandBrown.withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = activeCategoryIndex == index;

                return Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    hoverColor: kBrandCreamDark.withOpacity(0.3),
                  ),
                  child: ExpansionTile(
                    initiallyExpanded: isSelected,
                    collapsedIconColor: kBrandBrown.withOpacity(0.5),
                    iconColor: kBrandOlive,
                    collapsedTextColor: kBrandBrown,
                    textColor: kBrandBrown,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(category.icon, size: 20),
                    title: Text(category.title, 
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, 
                        fontSize: 13,
                        color: isSelected ? kBrandBrown : kBrandBrown.withOpacity(0.7),
                      )),
                    children: category.subItems.where((s) => s.isVisible).map((subItem) {
                      final subIdx = category.subItems.indexOf(subItem);
                      final isSubSelected = isSelected && activeSubIndex == subIdx;
                      
                      return Container(
                        margin: const EdgeInsets.only(left: 8, bottom: 2),
                        decoration: BoxDecoration(
                          color: isSubSelected ? kBrandOlive.withOpacity(0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                          leading: Icon(subItem.icon, size: 16, color: isSubSelected ? kBrandOlive : kBrandBrown.withOpacity(0.4)),
                          title: Text(subItem.title, 
                            style: TextStyle(
                              color: isSubSelected ? kBrandBrown : kBrandBrown.withOpacity(0.6),
                              fontWeight: isSubSelected ? FontWeight.w900 : FontWeight.w500, 
                              fontSize: 12.5)),
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
              title: Text("End Session", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 13)), 
              onTap: () { 
                ApiService.logout(); 
                Navigator.pushReplacementNamed(context, '/login'); 
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      color: kBrandCreamDark,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kBrandOlive.withOpacity(0.2), width: 2),
            ),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: kBrandBrown,
              child: ClipOval(
                child: _profileImageUrl != null
                    ? Image.network(
                        ApiService.getFullUrl(_profileImageUrl),
                        fit: BoxFit.cover,
                        width: 76,
                        height: 76,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person, size: 40, color: Colors.white),
                      )
                    : const Icon(Icons.person, size: 40, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(_fullName, 
            textAlign: TextAlign.center,
            style: const TextStyle(color: kBrandBrown, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kBrandOlive.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_userRole.toUpperCase(), 
              style: const TextStyle(color: kBrandOlive, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ListTile(
      leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
      title: Text("Logout Session", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
      onTap: () {
        ApiService.logout();
        Navigator.pushReplacementNamed(context, '/login');
      },
    );
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

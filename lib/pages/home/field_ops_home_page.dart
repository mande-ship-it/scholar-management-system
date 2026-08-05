import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../services/api_service.dart';
import '../../academics/academics_utils.dart';

// Dashboard & Core Components
import '../../dashboard/field_operations_dashboard.dart';
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
      if (mounted && _isLoading) {
        debugPrint("FIELD OPS: Safety timeout reached, forcing load completion.");
        setState(() => _isLoading = false);
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
            title: "Scholar Registry",
            page: const SizedBox(),
            icon: Icons.people_rounded,
            builder: (onBack, onPush, onPushProfile) => ViewScholarsPage(
              onViewProfile: onPushProfile,
              forcedSchoolType: 'Secondary',
              hideUniversity: true,
              onRegisterScholar: () => onPush("Register Scholar"),
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
            builder: (onBack, onPush, onPushProfile) => const PerformanceAnalysisComponent(forcedSchoolType: SchoolType.secondary),
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
    if (_isLoading) {
      debugPrint("FIELD OPS: Still loading access check...");
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: kBrandOlive)));
    }

    final activeCategory = _categories[activeCategoryIndex];
    final activeSubItem = activeCategory.subItems[activeSubIndex];
    debugPrint("FIELD OPS BUILD: Rendering Category=$activeCategoryIndex, SubItem=$activeSubIndex (${activeSubItem.title})");

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        elevation: 2,
        backgroundColor: kBrandBrown,
        leadingWidth: 280,
        leading: Row(
          children: [
            Container(
              width: 200,
              height: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Image.asset('assets/images/age-logo.png', fit: BoxFit.contain),
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () => setState(() => _isSidebarVisible = !_isSidebarVisible)),
          ],
        ),
        title: const Text("Field Operations Portal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications, color: Colors.white), onPressed: () {
            for (int i = 0; i < _categories.length; i++) {
              final idx = _categories[i].subItems.indexWhere((s) => s.title == "Notifications");
              if (idx != -1) {
                setState(() { activeCategoryIndex = i; activeSubIndex = idx; });
                break;
              }
            }
          }),
          const SizedBox(width: 20),
          CircleAvatar(
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
          const SizedBox(width: 20),
        ],
      ),
      body: Row(
        children: [
          if (_isSidebarVisible)
            Container(
              width: 280,
              color: kBrandCream,
              child: Column(
                children: [
                  _buildUserHeader(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = activeCategoryIndex == index;
                        return ExpansionTile(
                          initiallyExpanded: isSelected,
                          leading: Icon(category.icon, color: isSelected ? kBrandOrange : kBrandBrown),
                          title: Text(category.title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
                          children: category.subItems.where((s) => s.isVisible).map((sub) {
                            final subIdx = category.subItems.indexOf(sub);
                            final isSubSelected = isSelected && activeSubIndex == subIdx;
                            return ListTile(
                              dense: true,
                              leading: Icon(sub.icon, size: 18, color: isSubSelected ? kBrandOrange : Colors.black54),
                              title: Text(sub.title, style: TextStyle(color: isSubSelected ? kBrandOrange : Colors.black87, fontWeight: isSubSelected ? FontWeight.bold : FontWeight.normal)),
                              onTap: () => setState(() { activeCategoryIndex = index; activeSubIndex = subIdx; }),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                  _buildLogoutButton(),
                ],
              ),
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
                      if (_navigationHistory.isNotEmpty && activeSubItem.title != "Pending Approvals")
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87),
                          onPressed: _popSubItem
                        ),
                      Text(activeCategory.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black54)),
                      const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                      Text(activeSubItem.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
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

  Widget _buildUserHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
                          const Icon(Icons.person, size: 40, color: kBrandCream),
                    )
                  : const Icon(Icons.person, size: 40, color: kBrandCream),
            ),
          ),
          const SizedBox(height: 12),
          Text(_fullName, style: const TextStyle(color: kBrandBrown, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(_userRole.toUpperCase(), style: const TextStyle(color: kBrandOrange, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ListTile(
      leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
      title: const Text("Logout Session", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
      onTap: () {
        ApiService.logout();
        Navigator.pushReplacementNamed(context, '/login');
      },
    );
  }
}

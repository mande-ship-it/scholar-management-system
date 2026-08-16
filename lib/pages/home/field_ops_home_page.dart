import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scholar_management_system/services/api_service.dart';
import 'package:scholar_management_system/services/socket_service.dart';
import 'package:scholar_management_system/academics/academics_utils.dart';

// Dashboard & Core Components
import '../../dashBoard/field_operations_dashboard.dart';
import '../dashboardPages/notifications.dart';
import '../userPages/user_profile.dart';

// Operations Components (Direct Components)
import '../../academics/enter_results.dart';
import '../../academics/performance_analysis.dart';
import '../../scholars/scholar_profile.dart';
import '../../scholars/view_scholars.dart';
import 'package:scholar_management_system/services/permission_service.dart';

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
  final Widget Function(VoidCallback onBack, Function(String) onPush, Function(String) onPushProfile, Function(String) onPushAnalysis)? builder;

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
  final List<(int, int, String?, String?)> _navigationHistory = [];
  String? _currentDetailScholarId;
  String? _currentAnalysisScholarId;

  bool _isLoading = true;
  bool _isSidebarVisible = true;
  int _notificationCount = 0;
  String? _currentUserId;
  bool _isApprovalView = false;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<FieldOpsSidebarSubItem> _searchResults = [];
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _searchOverlayEntry;

  late AnimationController _notificationIconController;
  late Animation<double> _notificationIconAnimation;

  String _fullName = "Field Officer";
  String _userRole = "Field Officer";
  String? _profileImageUrl;

  late List<FieldOpsSidebarCategory> _categories;

  bool _isAccessChecked = false;

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

    activeCategoryIndex = 0;
    activeSubIndex = 0;
    _categories = _getFieldOpsCategories();
    SocketService.addCallListener(_handleIncomingCall);
    SocketService.addNotificationListener(_handleNewNotification);
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
    SocketService.removeCallListener(_handleIncomingCall);
    SocketService.removeNotificationListener(_handleNewNotification);
    _notificationIconController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _removeSearchOverlay();
    super.dispose();
  }

  void _handleNewNotification(Map<String, dynamic> data) {
    if (!mounted) return;

    final String title = data['title'] ?? 'New Notification';
    final String message = data['message'] ?? '';
    final String type = data['type'] ?? 'info';

    setState(() {
      _notificationCount++;
    });

    _notificationIconController.forward(from: 0.0);
    HapticFeedback.lightImpact();

    _showPopNotification(title, message, type);
  }

  void _showPopNotification(String title, String message, String type) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * -20),
                  child: child,
                ),
              );
            },
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(type).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getNotificationIcon(type), color: _getNotificationColor(type), size: 18),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: kBrandBrown, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(message, style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => entry.remove(),
                    icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 5), () {
      if (entry.mounted) entry.remove();
    });
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'success': return kBrandOlive;
      case 'warning': return kBrandOrange;
      case 'error': return Colors.redAccent;
      default: return kBrandBrown;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'success': return Icons.check_circle_outline_rounded;
      case 'warning': return Icons.warning_amber_rounded;
      case 'error': return Icons.error_outline_rounded;
      default: return Icons.notifications_active_outlined;
    }
  }

  void _handleIncomingCall(Map<String, dynamic> data) {
    if (!mounted) return;

    final String caller = data['callerName'] ?? 'Someone';
    final String meetingId = data['meetingId'];
    final bool isVideo = data['isVideo'] ?? true;

    // Trigger feedback
    HapticFeedback.vibrate();
    SystemSound.play(SystemSoundType.click);

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
    try {
      debugPrint('FIELD OPS: Calling profile API...');
      final response = await ApiService.getAccountProfile();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && mounted) {
          final String role = (data['role_name'] ?? data['role'] ?? data['roleName'] ?? "").toString().trim();
          final String normalizedRole = role.toLowerCase();

          debugPrint('FIELD OPS CHECK: role=$role, isFieldOfficer=${fieldRoles.contains(normalizedRole)}');

          if (fieldRoles.contains(normalizedRole)) {
            PermissionService.init(data);
            setState(() {
              _fullName = data['full_name'] ?? "Field User";
              _userRole = role;
              _profileImageUrl = data['profile_picture'];
              _currentUserId = data['id'];
              _isLoading = false;
              if (_currentUserId != null) SocketService.init(_currentUserId!);
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('FIELD OPS Error: $e');
    }

    if (mounted) {
      debugPrint('FIELD OPS: Access not granted, redirecting...');
      Navigator.pushReplacementNamed(context, '/home');
    }
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
            builder: (onBack, onPush, onPushProfile, onPushAnalysis) => FieldOperationsDashboard(onNavigate: onPush),
          ),
          FieldOpsSidebarSubItem(
            title: "Notifications",
            page: const SizedBox(),
            icon: Icons.notifications_active_rounded,
            builder: (onBack, onPush, onPushProfile, onPushAnalysis) => NotificationsPage(onBack: onBack),
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
            builder: (onBack, onPush, onPushProfile, onPushAnalysis) => ViewScholarsPage(
              onBack: onBack,
              onViewProfile: onPushProfile,
              onViewAnalysis: onPushAnalysis,
              forcedSchoolType: 'Secondary',
              hideUniversity: true,
              initialTabIndex: _isApprovalView ? 1 : 0,
              onRegisterScholar: () => onPush("Register Scholar"),
            ),
          ),
          FieldOpsSidebarSubItem(
            title: "Register Scholar",
            page: const SizedBox(),
            icon: Icons.person_add_rounded,
            isVisible: false,
            builder: (onBack, onPush, onPushProfile, onPushAnalysis) => RegisterScholarPage(
              onBack: onBack,
              onSuccess: () {
                setState(() => _isApprovalView = true);
                onBack();
              }, 
              forcedSchoolType: 'Secondary'
            ),
          ),
          FieldOpsSidebarSubItem(
            title: "Institutions",
            page: const SizedBox(),
            icon: Icons.domain_rounded,
            builder: (onBack, onPush, onPushProfile, onPushAnalysis) => ViewSchoolsPage(
              onBack: onBack,
              forcedLevel: 'Secondary School',
              hideRegistration: true,
            ),
          ),
          FieldOpsSidebarSubItem(
            title: "Take Attendance",
            page: const SizedBox(),
            icon: Icons.how_to_reg_rounded,
            builder: (onBack, onPush, onPushProfile, onPushAnalysis) => ScholarAttendancePage(
              onBack: onBack,
              forcedSchoolType: SchoolType.secondary
            ),
          ),
          FieldOpsSidebarSubItem(
            title: "Enter Results",
            page: const SizedBox(),
            icon: Icons.edit_note_rounded,
            builder: (onBack, onPush, onPushProfile, onPushAnalysis) => AcademicsManagementComponent(
              onBack: onBack,
              forcedSchoolType: SchoolType.secondary
            ),
          ),
          FieldOpsSidebarSubItem(
            title: "Performance Analysis",
            page: const SizedBox(),
            icon: Icons.insights_rounded,
            builder: (onBack, onPush, onPushProfile, onPushAnalysis) => PerformanceAnalysisPage(
              onBack: onBack,
              forcedSchoolType: SchoolType.secondary
            ),
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
            builder: (onBack, onPush, onPushProfile, onPushAnalysis) => UserProfilePage(onBack: onBack),
          ),
        ],
      ),
    ];
  }

  void _showSearchOverlay() {
    _removeSearchOverlay();
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
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
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 450),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, size: 16, color: kBrandOlive),
                            const SizedBox(width: 8),
                            Text("SEARCH RESULTS (${_searchResults.length})", 
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kBrandOlive, letterSpacing: 1)),
                            const Spacer(),
                            GestureDetector(
                              onTap: _stopSearching,
                              child: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Flexible(
                        child: _searchResults.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Column(
                                children: [
                                  Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  const Text("No features found matching your search.", 
                                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final res = _searchResults[index];
                                return ListTile(
                                  leading: Icon(res.icon, size: 20, color: kBrandBrown),
                                  title: Text(res.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  onTap: () {
                                    _navigateToSubItem(res.title);
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

    final allSubItems = _getFieldOpsCategories().expand((c) => c.subItems).toList();
    final filtered = allSubItems.where((item) => 
      item.title.toLowerCase().contains(query.toLowerCase())).toList();

    setState(() => _searchResults = filtered);
    if (_searchOverlayEntry == null) {
      _showSearchOverlay();
    } else {
      _searchOverlayEntry!.markNeedsBuild();
    }
  }

  void _navigateToSubItem(String title) {
    for (int i = 0; i < _categories.length; i++) {
      for (int j = 0; j < _categories[i].subItems.length; j++) {
        if (_categories[i].subItems[j].title == title) {
          setState(() {
            _navigationHistory.clear();
            _currentDetailScholarId = null;
            _isApprovalView = false; // Reset when navigating directly
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
            _navigationHistory.add((activeCategoryIndex, activeSubIndex, _currentDetailScholarId, _currentAnalysisScholarId));
            _currentDetailScholarId = null;
            _currentAnalysisScholarId = null;
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
      _navigationHistory.add((activeCategoryIndex, activeSubIndex, _currentDetailScholarId, _currentAnalysisScholarId));
      _currentDetailScholarId = id;
    });
  }

  void _pushScholarAnalysis(String id) {
    setState(() {
      _navigationHistory.add((activeCategoryIndex, activeSubIndex, _currentDetailScholarId, _currentAnalysisScholarId));
      _currentAnalysisScholarId = id;
    });
  }

  void _popSubItem() {
    if (_navigationHistory.isNotEmpty) {
      final prev = _navigationHistory.removeLast();
      setState(() {
        activeCategoryIndex = prev.$1;
        activeSubIndex = prev.$2;
        _currentDetailScholarId = prev.$3;
        _currentAnalysisScholarId = prev.$4;
      });
    } else if (_currentDetailScholarId != null || _currentAnalysisScholarId != null) {
      setState(() {
        _currentDetailScholarId = null;
        _currentAnalysisScholarId = null;
      });
    } else if (activeCategoryIndex != 0 || activeSubIndex != 0) {
      setState(() {
        activeCategoryIndex = 0;
        activeSubIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;

    final activeCategory = _categories[activeCategoryIndex];
    final activeSubItem = activeCategory.subItems[activeSubIndex];

    return PopScope(
      canPop: _navigationHistory.isEmpty && _currentDetailScholarId == null && activeCategoryIndex == 0 && activeSubIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _popSubItem();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8F9FA),
        drawer: isMobile ? _buildDrawer(context) : null,
        endDrawer: _buildEndDrawer(context),
        appBar: AppBar(
          elevation: 2,
          backgroundColor: kBrandBrown,
          foregroundColor: Colors.white,
          leadingWidth: isMobile ? null : 280,
          leading: isMobile 
            ? IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              )
            : Row(
                children: [
                  Container(
                    width: 200,
                    height: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Image.asset('assets/images/age-logo.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(_isSidebarVisible ? Icons.menu_open_rounded : Icons.menu_rounded, color: Colors.white, size: 22),
                    tooltip: _isSidebarVisible ? "Collapse Sidebar" : "Expand Sidebar",
                    onPressed: () => setState(() => _isSidebarVisible = !_isSidebarVisible),
                  ),
                ],
              ),
          title: _isSearching
            ? Container(
                alignment: Alignment.centerLeft,
                width: 450,
                height: 42,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: CompositedTransformTarget(
                  link: _searchLayerLink,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: kBrandBrown, fontWeight: FontWeight.bold, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Search features...",
                      prefixIcon: const Icon(Icons.search, color: kBrandOlive, size: 20),
                      suffixIcon: IconButton(icon: const Icon(Icons.close, color: Colors.grey, size: 18), onPressed: _stopSearching),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              )
            : Text(isMobile ? activeSubItem.title : "Field Operations Portal", 
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
              child: GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
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
                  Expanded(
                    child: _currentAnalysisScholarId != null
                        ? PerformanceAnalysisComponent(scholarId: _currentAnalysisScholarId, onBack: _popSubItem)
                        : _currentDetailScholarId != null
                            ? ScholarProfileComponent(scholarId: _currentDetailScholarId, onBack: _popSubItem)
                            : activeSubItem.builder != null
                              ? activeSubItem.builder!(_popSubItem, _pushSubItem, _pushScholarProfile, _pushScholarAnalysis)
                              : const Center(child: Text("Component not configured.")),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      width: 320,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Executive Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: const BoxDecoration(
              color: kBrandBrown,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: ClipOval(
                      child: _profileImageUrl != null
                          ? Image.network(
                              ApiService.getFullUrl(_profileImageUrl),
                              fit: BoxFit.cover,
                              width: 88,
                              height: 88,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person_rounded, size: 48, color: Colors.white70),
                            )
                          : const Icon(Icons.person_rounded, size: 48, color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: kBrandOlive.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _userRole.toUpperCase(),
                    style: const TextStyle(
                      color: kBrandOlive,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Menu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildDrawerAction(
                  icon: Icons.assignment_ind_rounded,
                  label: "Personal Profile",
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToSubItem("User Profile");
                  },
                ),
                const SizedBox(height: 8),
                _buildDrawerAction(
                  icon: Icons.notifications_active_rounded,
                  label: "System Notifications",
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToSubItem("Notifications");
                  },
                ),
                const Divider(height: 48, indent: 8, endIndent: 8),
                _buildDrawerAction(
                  icon: Icons.power_settings_new_rounded,
                  label: "Sign Out",
                  isDestructive: true,
                  onTap: () {
                    ApiService.logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Branding Footer
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Image.asset('assets/images/age-logo.png', height: 40, opacity: const AlwaysStoppedAnimation(0.5)),
                const SizedBox(height: 8),
                const Text(
                  "AGE AFRICA SYSTEM v2.0",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.grey,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final Color color = isDestructive ? Colors.redAccent : kBrandBrown;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: color.withOpacity(0.3)),
            ],
          ),
        ),
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
                          contentPadding: const EdgeInsets.only(left: 20, right: 8),
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

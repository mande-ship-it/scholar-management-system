import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../services/api_service.dart';
import '../../academics/academics_utils.dart';

// Dashboard
import '../dashboardPages/dashboard.dart';
import '../dashboardPages/notifications.dart';

// Scholars
import '../scholarPages/register_scholar.dart';
import '../scholarPages/view_scholars.dart';
import '../../scholars/scholar_profile.dart'; 
import '../scholarPages/graduates_page.dart';
import '../attendancePages/scholar_attendance.dart';
import '../../attendance/scholar_attendance.dart' show AttendanceModuleType;

// Academics
import '../academicPages/enter_results.dart';
import '../academicPages/view_results.dart';
import '../academicPages/report_cards.dart';
import '../academicPages/performance_analysis.dart';
import '../../academics/subject_registry.dart';

// Attendance
import '../attendancePages/attendance_history.dart';

// Events
import '../eventPages/events.dart';

// Users
import '../userPages/user_profile.dart';

// Admin
import '../aiPages/ai_assistant.dart';
import '../../scholars/internship_allocation.dart';

// Settings
import '../settingsPages/organisation_profile.dart';
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
  final bool isVisible;
  final Widget Function(VoidCallback backFunc, Function(String) onPush, Function(String) onPushProfile)? builder;

  const SidebarSubItem({
    required this.title,
    required this.page,
    required this.icon,
    this.isVisible = true,
    this.builder,
  });
}

enum EndDrawerContent { ai, profile }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int activeCategoryIndex = 0;
  int activeSubIndex = 0;
  final List<(int, int, String?)> _navigationHistory = [];
  String? _currentDetailScholarId;

  bool _isSidebarVisible = true;
  int _notificationCount = 0;
  IO.Socket? _socket;
  String? _currentUserId;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSearching = false;
  EndDrawerContent _endDrawerContent = EndDrawerContent.ai;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<SidebarSubItem> _searchResults = [];
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _searchOverlayEntry;

  late AnimationController _notificationIconController;
  late Animation<double> _notificationIconAnimation;

  String _fullName = "User";
  String _userRole = "Staff";
  String? _profileImageUrl;
  Map<String, dynamic> _userPermissions = {};
  
  late List<SidebarCategory> _categories;

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

    _categories = _getRawCategories();
    _initSocket();
    _fetchNotificationCount();
    _fetchUserProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _fullName == "User") {
      setState(() {
        _fullName = args['username'] ?? "User";
        _userRole = args['role'] ?? "Staff";
        _profileImageUrl = args['profilePicture'];
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await ApiService.getAccountProfile();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && mounted) {
          final String role = (data['role_name'] ?? data['role'] ?? data['roleName'] ?? "").toString().trim();
          final String normalizedRole = role.toLowerCase();
          
          if (['administrator', 'admin'].contains(normalizedRole)) {
            Navigator.pushReplacementNamed(context, '/admin/home');
            return;
          }
          
          if ([
            'field officer', 
            'field coordinator', 
            'field operations', 
            'operational officer'
          ].contains(normalizedRole)) {
            Navigator.pushReplacementNamed(
              context,
              '/field-operations/home',
              arguments: {
                'username': data['full_name'] ?? data['username'],
                'role': role,
                'profilePicture': data['profile_picture'],
              },
            );
            return;
          }

          setState(() {
            _fullName = data['full_name'] ?? "User";
            _userRole = role;
            _profileImageUrl = data['profile_picture'];
            _currentUserId = data['id'];
            _userPermissions = data['permissions'] ?? {};
          });

          _joinUserRoom();
        }
      }
    } catch (e) {
      debugPrint('Error fetching user profile in Home: $e');
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        final fileName = result.files.single.name;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Uploading new profile picture..."), behavior: SnackBarBehavior.floating),
        );

        final response = await ApiService.uploadProfilePicture(bytes, fileName);

        if (response.statusCode == 200) {
          setState(() {
            _profileImageUrl = response.data['data']['profilePicture'];
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profile avatar updated successfully."), backgroundColor: Color(0xFF9AB334)),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
    }
  }

  void _initSocket() {
    _socket = IO.io(ApiService.baseUrl, IO.OptionBuilder()
      .setTransports(['websocket', 'polling'])
      .enableAutoConnect()
      .build());

    _socket!.onConnect((_) {
      debugPrint('Connected to Notification Server');
      _joinUserRoom();
    });

    _socket!.onDisconnect((_) {
      debugPrint('Disconnected from Notification Server');
    });

    _socket!.on('notification', (data) {
      if (mounted) {
        final String title = data['title'] ?? 'Real-time Update';
        final String message = data['message'] ?? '';
        final String type = data['type'] ?? 'info';

        setState(() {
          _notificationCount++;
        });
        _notificationIconController.forward(from: 0.0);
        HapticFeedback.lightImpact();
        
        _showPopNotification(title, message, type);
      }
    });

    _socket!.onDisconnect((_) => debugPrint('Disconnected from Notification Server'));
    _socket!.onConnectError((err) => debugPrint('Socket Connection Error: $err'));
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
                              "SEARCH RESULTS",
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
                                  const Text("No features found matching your search.", style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                                      color: const Color(0xFF9AB334).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(item.icon, color: const Color(0xFF4C3C32), size: 18),
                                  ),
                                  title: Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4C3C32))),
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

    final allCategories = _getRawCategories();
    final allSubItems = allCategories.expand((c) => c.subItems).toList();
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
    final allCategories = _getRawCategories();
    for (int i = 0; i < allCategories.length; i++) {
      for (int j = 0; j < allCategories[i].subItems.length; j++) {
        if (allCategories[i].subItems[j].title == title) {
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
    if (title == "AI Assistant" || title == "AI Analyst") {
      _openEndDrawer(EndDrawerContent.ai);
      return;
    }
    final allCategories = _getRawCategories();
    for (int i = 0; i < allCategories.length; i++) {
      for (int j = 0; j < allCategories[i].subItems.length; j++) {
        if (allCategories[i].subItems[j].title == title) {
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

  List<SidebarCategory> _getRawCategories() {
    return [
      SidebarCategory(
        title: Translator.translate("Dashboard"),
        icon: Icons.dashboard,
        subItems: [
          SidebarSubItem(
            title: Translator.translate("Overview"), 
            page: DashboardPage(),
            icon: Icons.view_quilt,
            builder: (backFunc, onPush, onPushProfile) => DashboardPage(onNavigate: onPush, userRole: _userRole, onBack: backFunc),
          ),
          SidebarSubItem(
            title: "Events & Programs", 
            page: const EventsPage(), 
            icon: Icons.event_available,
            builder: (backFunc, onPush, onPushProfile) => EventsPage(onBack: backFunc),
          ),
          SidebarSubItem(
            title: "Notifications", 
            page: const NotificationsPage(), 
            icon: Icons.notifications_active,
            builder: (backFunc, onPush, onPushProfile) => NotificationsPage(onBack: backFunc),
          ),
        ],
      ),
      SidebarCategory(
        title: Translator.translate("Scholars"),
        icon: Icons.school,
        subItems: [
          SidebarSubItem(
            title: "Secondary Scholars",
            page: const ViewScholarsPage(forcedSchoolType: 'Secondary'),
            icon: Icons.school_outlined,
            builder: (backFunc, onPush, onPushProfile) => ViewScholarsPage(
              onBack: backFunc,
              forcedSchoolType: 'Secondary',
              hideRegistration: true, // Restricted on Standard Dashboard
              onViewProfile: onPushProfile,
              onViewGraduates: () => onPush("University Graduates"),
            ),
          ),
          SidebarSubItem(
            title: "University Registry",
            page: const ViewScholarsPage(forcedSchoolType: 'University'),
            icon: Icons.account_balance_outlined,
            builder: (backFunc, onPush, onPushProfile) => ViewScholarsPage(
              onBack: backFunc,
              forcedSchoolType: 'University',
              onRegisterScholar: () => onPush("Register Scholar"),
              onViewProfile: onPushProfile,
              onViewGraduates: () => onPush("University Graduates"),
            ),
          ),
          SidebarSubItem(
            title: "Register Scholar", 
            page: RegisterScholarPage(), 
            icon: Icons.person_add,
            isVisible: false,
            builder: (backFunc, onPush, onPushProfile) => RegisterScholarPage(onBack: backFunc),
          ),
        ],
      ),
      SidebarCategory(
        title: "Graduates",
        icon: Icons.workspace_premium_rounded,
        subItems: [
          SidebarSubItem(
            title: "University Graduates", 
            page: UniversityGraduatesPage(), 
            icon: Icons.school_rounded,
            builder: (backFunc, onPush, onPushProfile) => UniversityGraduatesPage(onBack: backFunc),
          ),
          SidebarSubItem(
            title: "Internship Allocation", 
            page: InternshipAllocationComponent(),
            icon: Icons.handshake_rounded,
            builder: (backFunc, onPush, onPushProfile) => InternshipAllocationComponent(onBack: backFunc),
          ),
        ],
      ),
      SidebarCategory(
        title: "Academics",
        icon: Icons.menu_book,
        subItems: [
          SidebarSubItem(
            title: "View Results",
            page: ViewResultsPage(),
            icon: Icons.pageview,
            builder: (backFunc, onPush, onPushProfile) => ViewResultsPage(
              onBack: backFunc,
              onEnterResults: () => onPush("Enter Results"),
              onViewPerformance: () => onPush("Performance Analysis"),
              onViewReports: () => onPush("Report Cards"),
            ),
          ),
          SidebarSubItem(
            title: "Enter Results", 
            page: EnterResultsPage(forcedSchoolType: SchoolType.university), 
            icon: Icons.edit_note,
            isVisible: false,
            builder: (backFunc, onPush, onPushProfile) => EnterResultsPage(onBack: backFunc, onPush: onPush, forcedSchoolType: SchoolType.university),
          ),
          SidebarSubItem(
            title: "Report Cards", 
            page: ReportCardsPage(), 
            icon: Icons.badge,
            builder: (backFunc, onPush, onPushProfile) => ReportCardsPage(onBack: backFunc),
          ),
          SidebarSubItem(
            title: "Performance Analysis", 
            page: PerformanceAnalysisPage(), 
            icon: Icons.analytics,
            builder: (backFunc, onPush, onPushProfile) => PerformanceAnalysisPage(onBack: backFunc),
          ),
          SidebarSubItem(
            title: "Subject Registry", 
            page: SubjectRegistryPage(), 
            icon: Icons.library_books,
            builder: (backFunc, onPush, onPushProfile) => SubjectRegistryPage(onBack: backFunc),
          ),
        ],
      ),
      SidebarCategory(
        title: "Attendance",
        icon: Icons.event_available,
        subItems: [
          SidebarSubItem(
            title: "Scholar Attendance", 
            page: ScholarAttendancePage(
              forcedSchoolType: SchoolType.university,
              forcedModuleType: AttendanceModuleType.chats,
            ), 
            icon: Icons.how_to_reg,
            builder: (backFunc, onPush, onPushProfile) => ScholarAttendancePage(
              onBack: backFunc,
              forcedSchoolType: SchoolType.university,
              forcedModuleType: AttendanceModuleType.chats,
            ),
          ),
          SidebarSubItem(
            title: "Attendance Archives",
            page: AttendanceHistoryPage(),
            icon: Icons.history_rounded,
            builder: (backFunc, onPush, onPushProfile) => AttendanceHistoryPage(onBack: backFunc),
          ),
        ],
      ),
      SidebarCategory(
        title: "AI Strategy",
        icon: Icons.auto_awesome,
        subItems: [
          SidebarSubItem(
            title: "AI Analyst", 
            page: AIAssistantPage(), 
            icon: Icons.bolt,
            builder: (backFunc, onPush, onPushProfile) => AIAssistantPage(onBack: backFunc),
          ),
        ],
      ),
      SidebarCategory(
        title: "Settings",
        icon: Icons.settings,
        subItems: [
          SidebarSubItem(
            title: "User Profile", 
            page: UserProfilePage(), 
            icon: Icons.assignment_ind,
            builder: (backFunc, onPush, onPushProfile) => UserProfilePage(onBack: backFunc),
          ),
          SidebarSubItem(
            title: "Organisation Profile", 
            page: OrganisationProfilePage(), 
            icon: Icons.corporate_fare,
            builder: (backFunc, onPush, onPushProfile) => OrganisationProfilePage(onBack: backFunc),
          ),
          SidebarSubItem(
            title: "System Settings", 
            page: SystemSettingsPage(), 
            icon: Icons.settings_applications,
            builder: (backFunc, onPush, onPushProfile) => SystemSettingsPage(onBack: backFunc),
          ),
          SidebarSubItem(
            title: "Account Settings", 
            page: AccountSettingsPage(), 
            icon: Icons.manage_accounts,
            builder: (backFunc, onPush, onPushProfile) => AccountSettingsPage(onBack: backFunc),
          ),
        ],
      ),
    ];
  }

  List<SidebarCategory> _getVisibleCategories(List<SidebarCategory> allCategories) {
    List<SidebarCategory> filtered = [];
    final elevatedRoles = ['Administrator', 'Program Coordinator', 'Country Director'];
    
    for (var category in allCategories) {
      if (_userPermissions.isNotEmpty) {
        var modulePerms = _userPermissions[category.title];
        if (modulePerms != null && modulePerms['view'] == false) {
           if (category.title != "Dashboard" && category.title != "Settings") {
              continue;
           }
        }
      }

      final filteredSubItems = category.subItems.where((item) {
        if (!item.isVisible) return false;
        
        final String normalizedRole = _userRole.toLowerCase();
        final bool isAdmin = normalizedRole == 'administrator';
        
        if (isAdmin && (category.title == "Academics" || category.title == "Attendance")) return false;
        if (item.title == "Pending Approvals" && !elevatedRoles.contains(_userRole)) return false;

        return true;
      }).toList();

      if (filteredSubItems.isEmpty) continue;

      filtered.add(SidebarCategory(
        title: category.title,
        icon: category.icon,
        subItems: filteredSubItems,
      ));
    }
    return filtered;
  }

  void _openEndDrawer(EndDrawerContent content) {
    setState(() {
      _endDrawerContent = content;
    });
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;
    final visibleCategories = _getVisibleCategories(_categories);

    if (activeCategoryIndex >= _categories.length) activeCategoryIndex = 0;

    final activeCategory = _categories[activeCategoryIndex];
    final activeSubItem = activeCategory.subItems[activeSubIndex];

    const Color brandBrown = Color(0xFF4C3C32);
    const Color brandCream = Color(0xFFFAF2DB);
    const Color brandOlive = Color(0xFF9AB334);
    const Color brandOrange = Color(0xFFE05B1C);

    return PopScope(
      canPop: _navigationHistory.isEmpty && _currentDetailScholarId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentDetailScholarId != null || _navigationHistory.isNotEmpty) {
          _popSubItem();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey.shade50,
        drawer: isMobile ? Drawer(width: 280, child: _buildSidebar(visibleCategories, isMobile)) : null,
        endDrawer: _buildEndDrawer(context, isMobile, screenWidth, activeSubItem),
        appBar: AppBar(
          elevation: 2,
          toolbarHeight: 48,
          shadowColor: brandBrown.withOpacity(0.3),
          backgroundColor: brandBrown,
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
                  IconButton(icon: const Icon(Icons.menu, color: Colors.white, size: 20), onPressed: () => setState(() => _isSidebarVisible = !_isSidebarVisible)),
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
                    style: const TextStyle(color: brandBrown, fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: "Search features...",
                      prefixIcon: const Icon(Icons.search, color: brandOlive, size: 20),
                      suffixIcon: IconButton(icon: const Icon(Icons.close, color: Colors.grey, size: 18), onPressed: _stopSearching),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              )
            : Text(isMobile ? "AGE System" : "AGE Africa System", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16)),
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: Colors.white), 
              onPressed: () => _openEndDrawer(EndDrawerContent.ai),
            ),
            if (!isMobile) IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: _startSearching),
            Stack(
              children: [
                IconButton(icon: const Icon(Icons.notifications, color: Colors.white), onPressed: () {
                  setState(() => _notificationCount = 0);
                  ApiService.markAllNotificationsRead();
                  _navigateToSubItem("Notifications");
                }),
                if (_notificationCount > 0)
                  Positioned(right: 8, top: 8, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: brandOrange, shape: BoxShape.circle), constraints: const BoxConstraints(minWidth: 18, minHeight: 18), child: Text('$_notificationCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
              ],
            ),
            const SizedBox(width: 8),
            if (!isMobile) const VerticalDivider(color: Colors.white24, width: 1, indent: 12, endIndent: 12),
            if (!isMobile) const SizedBox(width: 12),
            if (!isMobile)
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
              child: GestureDetector(
                onTap: () => _openEndDrawer(EndDrawerContent.profile),
                child: CircleAvatar(
                  backgroundColor: brandCream,
                  radius: 18,
                  child: ClipOval(
                    child: _profileImageUrl != null
                        ? Image.network(
                            ApiService.getFullUrl(_profileImageUrl),
                            fit: BoxFit.cover,
                            width: 36,
                            height: 36,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person, color: brandBrown, size: 20),
                          )
                        : const Icon(Icons.person, color: brandBrown, size: 20),
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
                width: _isSidebarVisible ? 280 : 0,
                child: _isSidebarVisible 
                  ? _buildSidebar(visibleCategories, false)
                  : const SizedBox.shrink(),
              ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _currentDetailScholarId != null
                        ? ScholarProfileComponent(scholarId: _currentDetailScholarId, onBack: _popSubItem)
                        : activeSubItem.builder != null
                          ? activeSubItem.builder!(_popSubItem, _pushSubItem, _pushScholarProfile)
                          : activeSubItem.page,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndDrawer(BuildContext context, bool isMobile, double screenWidth, SidebarSubItem activeSubItem) {
    if (_endDrawerContent == EndDrawerContent.ai) {
      return Drawer(
        width: isMobile ? screenWidth * 0.85 : 450,
        child: AIAssistantPage(
          isDrawer: true, 
          currentPage: activeSubItem.title,
          targetId: _currentDetailScholarId != null ? kStudents.firstWhere((s) => s.id == _currentDetailScholarId).scholarId : null,
          onBack: () => Navigator.pop(context),
        ),
      );
    } else {
      return Drawer(
        width: isMobile ? (screenWidth < 350 ? screenWidth * 0.9 : 320) : 320,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF4C3C32), // brandBrown
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
                      color: const Color(0xFF9AB334).withOpacity(0.2), // brandOlive
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _userRole.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF9AB334),
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
  }

  Widget _buildDrawerAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    const Color brandBrown = Color(0xFF4C3C32);
    final Color color = isDestructive ? Colors.redAccent : brandBrown;
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

  Widget _buildSidebar(List<SidebarCategory> visibleCategories, bool isMobile) {
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            color: brandCreamDark,
            child: Column(
              children: [
                if (isMobile) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset('assets/images/age-logo.png', height: 40, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 20),
                ],
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: brandBrown,
                        child: ClipOval(
                          child: _profileImageUrl != null
                              ? Image.network(
                                  ApiService.getFullUrl(_profileImageUrl),
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.person, size: 45, color: brandCream),
                                )
                              : const Icon(Icons.person, size: 45, color: brandCream),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: brandOlive, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(_fullName, style: const TextStyle(color: brandBrown, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_userRole, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFDCD1B4)),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: visibleCategories.length + 1,
              itemBuilder: (context, index) {
                if (index == visibleCategories.length) {
                  return ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent), 
                    title: const Text("Logout Session", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)), 
                    onTap: () { 
                      ApiService.logout(); 
                      Navigator.pushReplacementNamed(context, '/login'); 
                    }
                  );
                }
                final category = visibleCategories[index];
                int originalIdx = _categories.indexWhere((c) => c.title == category.title);
                final isSelected = activeCategoryIndex == originalIdx;

                return Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    hoverColor: brandOlive.withOpacity(0.1),
                  ),
                  child: ExpansionTile(
                    initiallyExpanded: isSelected,
                    collapsedIconColor: brandBrown.withOpacity(0.5),
                    iconColor: brandOlive,
                    collapsedTextColor: brandBrown,
                    textColor: brandBrown,
                    leading: Icon(category.icon),
                    title: Text(category.title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 14)),
                    children: category.subItems.where((s) => s.isVisible).map((subItem) {
                      int subIdx = _categories[originalIdx].subItems.indexWhere((s) => s.title == subItem.title);
                      final isSubSelected = isSelected && activeSubIndex == subIdx;
                      return ListTile(
                        dense: true,
                        leading: Icon(subItem.icon, size: 18, color: isSubSelected ? brandOlive : Colors.black54),
                        title: Text(subItem.title, style: TextStyle(color: isSubSelected ? brandOlive : Colors.black87, fontWeight: isSubSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                        onTap: () {
                          setState(() { 
                            activeCategoryIndex = originalIdx; 
                            activeSubIndex = subIdx; 
                          });
                          if (isMobile) Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
  late double _scrollPosition;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollPosition = 0.0;
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

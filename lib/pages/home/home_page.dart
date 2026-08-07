import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../services/api_service.dart';
import '../../academics/academics_utils.dart';
import 'package:intl/intl.dart';

// Dashboard
import '../dashboardPages/dashboard.dart';
import '../dashboardPages/notifications.dart';

// Scholars
import '../scholarPages/register_scholar.dart';
import '../scholarPages/view_scholars.dart';
import '../../scholars/scholar_profile.dart'; 
import '../scholarPages/graduates_page.dart';
import '../attendancePages/scholar_attendance.dart';

// Schools
import '../schoolPages/register_school.dart';
import '../schoolPages/view_schools.dart';

// Sponsors
import '../sponsorPages/register_sponsor.dart';
import '../sponsorPages/view_sponsors.dart';

// Academics
import '../academicPages/enter_results.dart';
import '../academicPages/view_results.dart';
import '../academicPages/report_cards.dart';
import '../academicPages/performance_analysis.dart';

// Attendance
import '../attendancePages/attendance_history.dart';
import '../attendancePages/attendance_reports.dart';

// Events
import '../eventPages/events.dart';

// Users
import '../userPages/create_user.dart';
import '../userPages/manage_users.dart';
import '../userPages/user_roles.dart';
import '../userPages/permissions.dart';
import '../userPages/user_profile.dart';

// Admin
import '../admin/approvals_page.dart';
import '../aiPages/ai_assistant.dart';
import '../../scholars/internship_allocation.dart';

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
  final bool isVisible;
  final Widget Function(VoidCallback onBack, Function(String) onPush, Function(String) onPushProfile)? builder;

  const SidebarSubItem({
    required this.title,
    required this.page,
    required this.icon,
    this.isVisible = true,
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
  final List<(int, int, String?)> _navigationHistory = [];
  String? _currentDetailScholarId;

  bool _isSidebarVisible = true;
  int _notificationCount = 0;
  IO.Socket? _socket;
  String? _currentUserId;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSearching = false;
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
          final String role = data['role_name'] ?? "";
          final String normalizedRole = role.trim().toLowerCase();
          
          final bool hasAdminAccess = [
            'administrator', 'program manager', 'program coordinator', 'country director'
          ].contains(normalizedRole);

          if (hasAdminAccess) {
            Navigator.pushReplacementNamed(context, '/admin/home');
            return;
          }
          
          final bool isFieldOfficer = [
            'field officer', 
            'field coordinator', 
            'field operations', 
            'operational officer'
          ].contains(normalizedRole);

          if (isFieldOfficer) {
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
        setState(() {
          _notificationCount++;
        });
        _notificationIconController.forward(from: 0.0).then((_) => _notificationIconController.reverse());
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF4C3C32),
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Color(0xFF9AB334), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['message'] ?? 'Real-time update received', 
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

    _socket!.onDisconnect((_) => debugPrint('Disconnected from Notification Server'));
    _socket!.onConnectError((err) => debugPrint('Socket Connection Error: $err'));
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
                                      color: Color(0xFF9AB334).withOpacity(0.1),
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
      _scaffoldKey.currentState?.openEndDrawer();
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
            builder: (onBack, onPush, onPushProfile) => DashboardPage(onNavigate: onPush, userRole: _userRole),
          ),
          SidebarSubItem(title: "Events & Programs", page: const EventsPage(), icon: Icons.event_available),
          SidebarSubItem(title: "Notifications", page: const NotificationsPage(), icon: Icons.notifications_active),
        ],
      ),
      SidebarCategory(
        title: Translator.translate("Scholars"),
        icon: Icons.school,
        subItems: [
          SidebarSubItem(
            title: "Secondary Registry",
            page: const ViewScholarsPage(forcedSchoolType: 'Secondary'),
            icon: Icons.school_outlined,
            builder: (onBack, onPush, onPushProfile) => ViewScholarsPage(
              forcedSchoolType: 'Secondary',
              onRegisterScholar: () => onPush("Register Scholar"),
              onViewProfile: onPushProfile,
              onViewGraduates: () => onPush("University Graduates"),
            ),
          ),
          SidebarSubItem(
            title: "University Registry",
            page: const ViewScholarsPage(forcedSchoolType: 'University'),
            icon: Icons.account_balance_outlined,
            builder: (onBack, onPush, onPushProfile) => ViewScholarsPage(
              forcedSchoolType: 'University',
              onRegisterScholar: () => onPush("Register Scholar"),
              onViewProfile: onPushProfile,
              onViewGraduates: () => onPush("University Graduates"),
            ),
          ),
          const SidebarSubItem(
            title: "Register Scholar", 
            page: RegisterScholarPage(), 
            icon: Icons.person_add,
            isVisible: false,
          ),
          SidebarSubItem(title: "University Graduates", page: const UniversityGraduatesPage(), icon: Icons.workspace_premium_rounded),
          SidebarSubItem(title: "Internship Allocation", page: const InternshipAllocationComponent(), icon: Icons.handshake_rounded),
        ],
      ),
      SidebarCategory(
        title: "Schools",
        icon: Icons.domain,
        subItems: [
          SidebarSubItem(
            title: "View Schools", 
            page: const ViewSchoolsPage(), 
            icon: Icons.store,
            builder: (onBack, onPush, onPushProfile) => ViewSchoolsPage(onRegisterSchool: () => onPush("Register School")),
          ),
          SidebarSubItem(
            title: "Register School", 
            page: const RegisterSchoolPage(), 
            icon: Icons.add_business,
            isVisible: false,
            builder: (onBack, onPush, onPushProfile) => RegisterSchoolPage(onSuccess: onBack),
          ),
        ],
      ),
      SidebarCategory(
        title: "Sponsors",
        icon: Icons.handshake,
        subItems: [
          SidebarSubItem(
            title: "View Sponsors", 
            page: const ViewSponsorsPage(), 
            icon: Icons.supervisor_account,
            builder: (onBack, onPush, onPushProfile) => ViewSponsorsPage(onRegisterSponsor: () => onPush("Register Sponsor")),
          ),
          SidebarSubItem(
            title: "Register Sponsor", 
            page: const RegisterSponsorPage(), 
            icon: Icons.add_moderator,
            isVisible: false,
            builder: (onBack, onPush, onPushProfile) => RegisterSponsorPage(onSuccess: onBack),
          ),
        ],
      ),
      SidebarCategory(
        title: "Academics",
        icon: Icons.menu_book,
        subItems: [
          SidebarSubItem(
            title: "View Results",
            page: const ViewResultsPage(),
            icon: Icons.pageview,
            builder: (onBack, onPush, onPushProfile) => ViewResultsPage(
              onEnterResults: () => onPush("Enter Results"),
              onViewPerformance: () => onPush("Performance Analysis"),
              onViewReports: () => onPush("Report Cards"),
            ),
          ),
          const SidebarSubItem(
            title: "Enter Results", 
            page: EnterResultsPage(), 
            icon: Icons.edit_note,
            isVisible: false,
          ),
          SidebarSubItem(title: "Report Cards", page: const ReportCardsPage(), icon: Icons.badge),
          SidebarSubItem(title: "Performance Analysis", page: const PerformanceAnalysisPage(), icon: Icons.analytics),
        ],
      ),
      SidebarCategory(
        title: "Attendance",
        icon: Icons.event_available,
        subItems: [
          SidebarSubItem(
            title: "View Attendance",
            page: const AttendanceHistoryPage(),
            icon: Icons.calendar_month,
            builder: (onBack, onPush, onPushProfile) => AttendanceHistoryPage(
              onMarkAttendance: () => onPush("Scholar Attendance"),
            ),
          ),
          SidebarSubItem(title: "Scholar Attendance", page: const ScholarAttendancePage(), icon: Icons.how_to_reg),
        ],
      ),
      SidebarCategory(
        title: "AI Strategy",
        icon: Icons.auto_awesome,
        subItems: [
          const SidebarSubItem(title: "AI Analyst", page: AIAssistantPage(), icon: Icons.bolt),
        ],
      ),
      SidebarCategory(
        title: "Settings",
        icon: Icons.settings,
        subItems: [
          SidebarSubItem(title: "User Profile", page: const UserProfilePage(), icon: Icons.assignment_ind),
          SidebarSubItem(title: "Organisation Profile", page: const OrganisationProfilePage(), icon: Icons.corporate_fare),
          SidebarSubItem(title: "System Settings", page: const SystemSettingsPage(), icon: Icons.settings_applications),
          SidebarSubItem(title: "Account Settings", page: const AccountSettingsPage(), icon: Icons.manage_accounts),
        ],
      ),
      SidebarCategory(
        title: "Operations",
        icon: Icons.settings_suggest_rounded,
        subItems: [
          SidebarSubItem(title: "Pending Approvals", page: const ApprovalsPage(), icon: Icons.rule_folder),
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
           if (category.title != "Dashboard" && category.title != "Settings" && category.title != "Operations") {
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
    const Color brandCreamDark = Color(0xFFF3E7C4);
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
        endDrawer: Drawer(
          width: isMobile ? screenWidth * 0.85 : 450,
          child: AIAssistantPage(
            isDrawer: true, 
            currentPage: activeSubItem.title,
            targetId: _currentDetailScholarId != null ? kStudents.firstWhere((s) => s.id == _currentDetailScholarId).scholarId : null,
          ),
        ),
        appBar: AppBar(
          elevation: 1,
          toolbarHeight: 48,
          shadowColor: Colors.black.withOpacity(0.05),
          backgroundColor: Colors.white,
          foregroundColor: brandBrown,
          leadingWidth: isMobile ? 56 : 280,
          leading: isMobile 
            ? IconButton(
                icon: const Icon(Icons.menu, color: brandBrown, size: 24),
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
                    icon: const Icon(Icons.menu, color: brandBrown, size: 20), 
                    onPressed: () => setState(() => _isSidebarVisible = !_isSidebarVisible)),
                ],
              ),
          title: _isSearching
            ? Container(
                alignment: Alignment.centerLeft,
                width: 450,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(10),
                ),
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
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              )
            : Text(isMobile ? "AGE System" : "AGE Africa Student Portal", 
                style: const TextStyle(color: brandBrown, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
          actions: [
            IconButton(icon: const Icon(Icons.auto_awesome_outlined, color: brandOlive), onPressed: () => _scaffoldKey.currentState?.openEndDrawer()),
            if (!isMobile) IconButton(icon: const Icon(Icons.search, color: brandBrown), onPressed: _startSearching),
            Stack(
              children: [
                IconButton(icon: const Icon(Icons.notifications_none_rounded, color: brandBrown), onPressed: () {
                  setState(() => _notificationCount = 0);
                  ApiService.markAllNotificationsRead();
                  _navigateToSubItem("Notifications");
                }),
                if (_notificationCount > 0)
                  Positioned(
                    right: 8, 
                    top: 8, 
                    child: Container(
                      padding: const EdgeInsets.all(2), 
                      decoration: BoxDecoration(color: brandOrange, shape: BoxShape.circle), 
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 18), 
                      child: Text('$_notificationCount', 
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), 
                        textAlign: TextAlign.center))),
              ],
            ),
            const SizedBox(width: 8),
            if (!isMobile) const VerticalDivider(color: Color(0xFFEEEEEE), width: 1, indent: 16, endIndent: 16),
            if (!isMobile) const SizedBox(width: 12),
            if (!isMobile)
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
                        style: const TextStyle(color: brandBrown, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ),
                    Text(_userRole.toUpperCase(), style: TextStyle(color: brandOlive, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ],
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
                        const Icon(Icons.person_outline, size: 20, color: brandBrown),
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
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                    ),
                    child: Row(
                      children: [
                        if (_navigationHistory.isNotEmpty || _currentDetailScholarId != null) 
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4C3C32), size: 16), 
                            onPressed: _popSubItem,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        if (_navigationHistory.isNotEmpty || _currentDetailScholarId != null) const SizedBox(width: 16),
                        if (!isMobile) ...[
                          GestureDetector(
                            onTap: () => _navigateToSubItem("Overview"),
                            child: Text(activeCategory.title.toUpperCase(), 
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1))),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 14),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            _currentDetailScholarId != null ? "Scholar Profile" : activeSubItem.title, 
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF4C3C32)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isMobile) ...[
                          const SizedBox(width: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(0xFF9AB334).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF9AB334)),
                                const SizedBox(width: 8),
                                Text(DateFormat('EEE, d MMM yyyy').format(DateTime.now()), 
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF9AB334))),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 24),
                      child: _currentDetailScholarId != null
                        ? ScholarProfileComponent(scholarId: _currentDetailScholarId, onBack: _popSubItem)
                        : activeSubItem.builder != null
                          ? activeSubItem.builder!(_popSubItem, _pushSubItem, _pushScholarProfile)
                          : activeSubItem.page,
                    ),
                  ),
                  _buildPortalFooter(isMobile),
                ],
              ),
            ),
          ],
        ),
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
          Text("© 2026 AGE Africa Student Portal", 
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
          if (!isMobile)
            Row(
              children: [
                _footerLink("Privacy Policy"),
                const SizedBox(width: 20),
                _footerLink("Help Center"),
                const SizedBox(width: 20),
                _footerLink("Contact Registrar"),
              ],
            ),
        ],
      ),
    );
  }

  Widget _footerLink(String label) {
    return Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9AB334)));
  }

  Widget _buildSidebar(List<SidebarCategory> visibleCategories, bool isMobile) {
    const Color brandBrown = Color(0xFF4C3C32);
    const Color brandCream = Color(0xFFFAF2DB);
    const Color brandCreamDark = Color(0xFFF3E7C4);
    const Color brandOrange = Color(0xFFE05B1C);
    const Color brandOlive = Color(0xFF9AB334);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            color: Colors.white,
            child: Column(
              children: [
                if (isMobile) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset('assets/images/age-logo.png', height: 36, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 20),
                ],
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: brandOlive.withOpacity(0.2), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: brandBrown,
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
                ),
                const SizedBox(height: 16),
                Text(_fullName, 
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: brandBrown, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: brandOlive.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_userRole.toUpperCase(), 
                    style: const TextStyle(color: brandOlive, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 24, right: 16, bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "MAIN NAVIGATION",
                style: TextStyle(
                  color: Colors.grey.shade400,
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
              itemCount: visibleCategories.length,
              itemBuilder: (context, index) {
                final category = visibleCategories[index];
                int originalIdx = _categories.indexWhere((c) => c.title == category.title);
                final isSelected = activeCategoryIndex == originalIdx;

                return Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    hoverColor: brandCream.withOpacity(0.3),
                  ),
                  child: ExpansionTile(
                    initiallyExpanded: isSelected,
                    collapsedIconColor: Colors.grey.shade500,
                    iconColor: brandOlive,
                    collapsedTextColor: brandBrown,
                    textColor: brandBrown,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(category.icon, size: 20),
                    title: Text(category.title, 
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, 
                        fontSize: 13,
                        color: isSelected ? brandBrown : Colors.grey.shade700,
                      )),
                    children: category.subItems.where((s) => s.isVisible).map((subItem) {
                      int subIdx = _categories[originalIdx].subItems.indexWhere((s) => s.title == subItem.title);
                      final isSubSelected = isSelected && activeSubIndex == subIdx;
                      
                      return Container(
                        margin: const EdgeInsets.only(left: 8, bottom: 2),
                        decoration: BoxDecoration(
                          color: isSubSelected ? brandOlive.withOpacity(0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                          leading: Icon(subItem.icon, size: 16, color: isSubSelected ? brandOlive : Colors.grey.shade500),
                          title: Text(subItem.title, 
                            style: TextStyle(
                              color: isSubSelected ? brandBrown : Colors.grey.shade600, 
                              fontWeight: isSubSelected ? FontWeight.w900 : FontWeight.w500, 
                              fontSize: 12.5)),
                          onTap: () {
                            setState(() { 
                              activeCategoryIndex = originalIdx; 
                              activeSubIndex = subIdx; 
                            });
                            if (isMobile) Navigator.pop(context);
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
              title: const Text("End Session", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 13)), 
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

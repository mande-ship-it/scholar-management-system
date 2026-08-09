import 'package:flutter/material.dart';

// Home Page
import 'pages/home/home_page.dart';
import 'pages/home/admin_home_page.dart';
import 'pages/home/field_ops_home_page.dart';

// Dashboard Pages
import 'pages/dashboardPages/dashboard.dart';
import 'pages/dashboardPages/field_operations.dart';
import 'pages/dashboardPages/statistics.dart';
import 'pages/dashboardPages/recent_activities.dart';
import 'pages/dashboardPages/notifications.dart';

// Authentication
import 'authentication/sign_in.dart';
import 'authentication/password_reset.dart';
import 'authentication/forgot_password.dart';

// Scholar Pages
import 'pages/scholarPages/register_scholar.dart';
import 'pages/scholarPages/view_scholars.dart';
import 'pages/scholarPages/scholar_profile.dart';
import 'pages/scholarPages/scholar_stats.dart';
import 'pages/scholarPages/promote_scholars.dart';
import 'pages/scholarPages/graduates_page.dart';
import 'pages/attendancePages/scholar_attendance.dart';

// School Pages
import 'pages/schoolPages/register_school.dart';
import 'pages/schoolPages/view_schools.dart';
import 'pages/schoolPages/school_profile.dart';
import 'pages/schoolPages/school_stats.dart';

// Sponsor Pages
import 'pages/sponsorPages/register_sponsor.dart';
import 'pages/sponsorPages/view_sponsors.dart';
import 'pages/sponsorPages/sponsor_stats.dart';

// Academic Pages
import 'pages/academicPages/enter_results.dart';
import 'pages/academicPages/view_results.dart';
import 'pages/academicPages/report_cards.dart';
import 'pages/academicPages/performance_analysis.dart';
import 'pages/academicPages/academic_stats.dart';

// Attendance Pages
import 'pages/attendancePages/attendance_history.dart';
import 'pages/attendancePages/attendance_reports.dart';

// User Pages
import 'pages/userPages/create_user.dart';
import 'pages/userPages/manage_users.dart';
import 'pages/userPages/user_roles.dart';
import 'pages/userPages/permissions.dart';
import 'pages/userPages/user_profile.dart';
import 'pages/userPages/manage_departments.dart';
import 'pages/admin/approvals_page.dart';

// Interactive Map
import 'dashBoard/districts_map.dart';

// Event Pages
import 'pages/eventPages/events.dart';
import 'events/live_meeting_page.dart';
import 'events/meeting_conversation_page.dart';
import 'events/meeting_room_page.dart';

// Settings Pages
import 'pages/settingsPages/organisation_profile.dart';
import 'pages/settingsPages/backup_restore.dart';
import 'pages/settingsPages/system_settings.dart';
import 'pages/settingsPages/account_settings.dart';

import 'settings/theme_controller.dart';
import 'package:scholar_management_system/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'AGE Africa System',
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              primary: const Color(0xFF4C3C32),
              secondary: const Color(0xFF9AB334),
              surface: Colors.white,
              error: const Color(0xFFE05B1C),
              brightness: Brightness.light,
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF4C3C32),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF1F3F4),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF9AB334), width: 1.5),
              ),
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C3C32),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF4C3C32), letterSpacing: -1),
              titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4C3C32), letterSpacing: -0.5),
              bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
              bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.dark,
            ),
          ),
          initialRoute: '/login',
          routes: {
            '/': (context) => const SignInPage(),
            '/splash': (context) => const SignInPage(),
            '/login': (context) => const SignInPage(),
            '/password-reset': (context) => const PasswordResetPage(),
            '/forgot-password': (context) => const ForgotPasswordPage(),
            '/home': (context) => const HomePage(),
            '/admin/home': (context) => const AdminHomePage(),
            '/field-operations/home': (context) => const FieldOpsHomePage(),

            // Dashboard
            '/dashboard': (context) => DashboardPage(),
            '/dashboard/statistics': (context) => StatisticsPage(),
            '/dashboard/recentActivities': (context) => RecentActivitiesPage(),
            '/dashboard/notifications': (context) => NotificationsPage(),
            '/dashboard/map': (context) => const DistrictsMapPage(),

            // Events
            '/events': (context) => const EventsPage(),
            '/events/liveMeeting': (context) => const LiveMeetingPage(),
            '/events/conversation': (context) => const MeetingConversationPage(),
            '/events/live-meeting-join': (context) => const MeetingRoomPage(),

            // Scholars
            '/registerScholar': (context) => RegisterScholarPage(),
            '/viewScholars': (context) => ViewScholarsPage(),
            '/scholarProfile': (context) => ScholarProfilePage(),
            '/scholarAttendance': (context) => ScholarAttendancePage(),
            '/scholars/stats': (context) => ScholarStatsPage(),
            '/scholars/promote': (context) => const PromoteScholarsPage(),
            '/scholars/graduates': (context) => const UniversityGraduatesPage(),

            // Schools
            '/schools/register': (context) => RegisterSchoolPage(),
            '/schools/view': (context) => ViewSchoolsPage(),
            '/schools/profile': (context) => SchoolProfilePage(),
            '/schools/stats': (context) => SchoolStatsPage(),

            // Sponsors
            '/sponsors/register': (context) => RegisterSponsorPage(),
            '/sponsors/view': (context) => ViewSponsorsPage(),
            '/sponsors/stats': (context) => SponsorStatsPage(),

            // Academics
            '/academics/enterResults': (context) => EnterResultsPage(),
            '/academics/viewResults': (context) => ViewResultsPage(),
            '/academics/reportCards': (context) => ReportCardsPage(),
            '/academics/performanceAnalysis': (context) => PerformanceAnalysisPage(),
            '/academics/academicStats': (context) => AcademicStatsPage(),

            // Attendance
            '/attendance/attendanceHistory': (context) => AttendanceHistoryPage(),
            '/attendance/attendanceReports': (context) => AttendanceModuleReportsPage(),

            // Users
            '/users/create': (context) => CreateUserPage(),
            '/users/manage': (context) => ManageUsersPage(),
            '/users/roles': (context) => UserRolesPage(),
            '/users/permissions': (context) => PermissionsPage(),
            '/users/departments': (context) => ManageDepartmentsPage(),
            '/users/profile': (context) => UserProfilePage(),
            '/admin/approvals': (context) => const ApprovalsPage(),

            // Settings
            '/settings/organisationProfile': (context) => OrganisationProfilePage(),
            '/settings/backupRestore': (context) => BackupRestorePage(),
            '/settings/systemSettings': (context) => SystemSettingsPage(),
            '/settings/accountSettings': (context) => AccountSettingsPage(),
          },
        );
      },
    );
  }
}

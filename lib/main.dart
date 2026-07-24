import 'package:flutter/material.dart';

// Home Page
import 'pages/home/home_page.dart';

// Dashboard Pages
import 'pages/dashboardPages/dashboard.dart';
import 'pages/dashboardPages/statistics.dart';
import 'pages/dashboardPages/recent_activities.dart';
import 'pages/dashboardPages/notifications.dart';

// Authentication
import 'authentication/sign_in.dart';

// Scholar Pages
import 'pages/scholarPages/register_scholar.dart';
import 'pages/scholarPages/view_scholars.dart';
import 'pages/scholarPages/scholar_profile.dart';
import 'pages/scholarPages/promote_scholars.dart';
import 'pages/scholarPages/scholar_stats.dart';
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

// Finance Pages
import 'pages/financePages/scholarship_payments.dart';
import 'pages/financePages/payment_history.dart';
import 'pages/financePages/expenses.dart';
import 'pages/financePages/budget.dart';
import 'pages/financePages/financial_reports.dart';

// Report Pages
import 'pages/reportPages/scholar_reports.dart';
import 'pages/reportPages/school_reports.dart';
import 'pages/reportPages/sponsor_reports.dart';
import 'pages/reportPages/finance_reports.dart';
import 'pages/reportPages/export_pdf.dart';
import 'pages/reportPages/export_excel.dart';

// User Pages
import 'pages/userPages/create_user.dart';
import 'pages/userPages/manage_users.dart';
import 'pages/userPages/user_roles.dart';
import 'pages/userPages/permissions.dart';
import 'pages/userPages/user_profile.dart';

// Splash Screen
import 'pages/splash/splash_screen.dart';

// Settings Pages
import 'pages/settingsPages/organisation_profile.dart';
import 'pages/settingsPages/backup_restore.dart';
import 'pages/settingsPages/system_settings.dart';
import 'pages/settingsPages/account_settings.dart';

import 'settings/theme_controller.dart';

void main() {
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
          title: 'AGE Africa Scholar Management System',
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.dark,
            ),
          ),
          initialRoute: '/splash',
          routes: {
            '/': (context) => const SplashScreen(),
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => SignInPage(),
            '/home': (context) => HomePage(),

            // Dashboard
            '/dashboard': (context) => DashboardPage(),
            '/dashboard/statistics': (context) => StatisticsPage(),
            '/dashboard/recentActivities': (context) => RecentActivitiesPage(),
            '/dashboard/notifications': (context) => NotificationsPage(),

            // Scholars
            '/registerScholar': (context) => RegisterScholarPage(),
            '/viewScholars': (context) => ViewScholarsPage(),
            '/scholarProfile': (context) => ScholarProfilePage(),
            '/scholarAttendance': (context) => ScholarAttendancePage(),
            '/scholars/promote': (context) => PromoteScholarsPage(),
            '/scholars/stats': (context) => ScholarStatsPage(),

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

            // Finance
            '/finance/scholarshipPayments': (context) => ScholarshipPaymentsPage(),
            '/finance/paymentHistory': (context) => PaymentHistoryPage(),
            '/finance/expenses': (context) => ExpensesPage(),
            '/finance/budget': (context) => BudgetPage(),
            '/finance/financialReports': (context) => FinancialReportsPage(),

            // Reports
            '/reports/scholar': (context) => ScholarReportsPage(),
            '/reports/school': (context) => SchoolReportsPage(),
            '/reports/sponsor': (context) => SponsorReportsPage(),
            '/reports/finance': (context) => FinanceReportsPage(),
            '/reports/exportPDF': (context) => ExportPDFPage(),
            '/reports/exportExcel': (context) => ExportExcelPage(),

            // Users
            '/users/create': (context) => CreateUserPage(),
            '/users/manage': (context) => ManageUsersPage(),
            '/users/roles': (context) => UserRolesPage(),
            '/users/permissions': (context) => PermissionsPage(),
            '/users/profile': (context) => UserProfilePage(),

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

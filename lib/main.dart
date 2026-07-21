import 'package:flutter/material.dart';

// Home Page
import 'pages/home/homePage.dart';

// Dashboard Pages
import 'pages/dashboardPages/dashboard.dart';
import 'pages/dashboardPages/statistics.dart';
import 'pages/dashboardPages/recentActivities.dart';
import 'pages/dashboardPages/notifications.dart';

// Authentication
import 'authentication/signIn.dart';

// Scholar Pages
import 'pages/scholarPages/registerScholar.dart';
import 'pages/scholarPages/viewScholars.dart';
import 'pages/scholarPages/ScholarProfile.dart';
import 'pages/scholarPages/promoteScholars.dart';
import 'pages/scholarPages/scholarStats.dart';
import 'pages/attendancePages/scholarAttendance.dart';

// School Pages
import 'pages/schoolPages/registerSchool.dart';
import 'pages/schoolPages/viewSchools.dart';
import 'pages/schoolPages/schoolProfile.dart';
import 'pages/schoolPages/schoolStats.dart';

// Sponsor Pages
import 'pages/sponsorPages/registerSponsor.dart';
import 'pages/sponsorPages/viewSponsors.dart';
import 'pages/sponsorPages/sponsorStats.dart';

// Academic Pages
import 'pages/academicPages/enterResults.dart';
import 'pages/academicPages/viewResults.dart';
import 'pages/academicPages/reportCards.dart';
import 'pages/academicPages/performanceAnalysis.dart';
import 'pages/academicPages/academicStats.dart';

// Attendance Pages
import 'pages/attendancePages/attendanceHistory.dart';
import 'pages/attendancePages/attendanceReports.dart';

// Finance Pages
import 'pages/financePages/scholarshipPayments.dart';
import 'pages/financePages/paymentHistory.dart';
import 'pages/financePages/expenses.dart';
import 'pages/financePages/budget.dart';
import 'pages/financePages/financialReports.dart';

// Report Pages
import 'pages/reportPages/scholarReports.dart';
import 'pages/reportPages/schoolReports.dart';
import 'pages/reportPages/sponsorReports.dart';
import 'pages/reportPages/financeReports.dart';
import 'pages/reportPages/exportPDF.dart';
import 'pages/reportPages/exportExcel.dart';

// User Pages
import 'pages/userPages/createUser.dart';
import 'pages/userPages/manageUsers.dart';
import 'pages/userPages/userRoles.dart';
import 'pages/userPages/permissions.dart';
import 'pages/userPages/userProfile.dart';

// Settings Pages
import 'pages/settingsPages/organisationProfile.dart';
import 'pages/settingsPages/backupRestore.dart';
import 'pages/settingsPages/systemSettings.dart';
import 'pages/settingsPages/accountSettings.dart';

import 'settings/themeController.dart';

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
          initialRoute: '/login',
          routes: {
            '/': (context) => const HomePage(),
            '/login': (context) => const SignInPage(),
            '/home': (context) => const HomePage(),

            // Dashboard
            '/dashboard': (context) => const DashboardPage(),
            '/dashboard/statistics': (context) => const StatisticsPage(),
            '/dashboard/recentActivities': (context) => const RecentActivitiesPage(),
            '/dashboard/notifications': (context) => const NotificationsPage(),

            // Scholars
            '/registerScholar': (context) => const RegisterScholarPage(),
            '/viewScholars': (context) => const ViewScholarsPage(),
            '/scholarProfile': (context) => const ScholarProfilePage(),
            '/scholarAttendance': (context) => const ScholarAttendancePage(),
            '/scholars/promote': (context) => const PromoteScholarsPage(),
            '/scholars/stats': (context) => const ScholarStatsPage(),

            // Schools
            '/schools/register': (context) => const RegisterSchoolPage(),
            '/schools/view': (context) => const ViewSchoolsPage(),
            '/schools/profile': (context) => const SchoolProfilePage(),
            '/schools/stats': (context) => const SchoolStatsPage(),

            // Sponsors
            '/sponsors/register': (context) => const RegisterSponsorPage(),
            '/sponsors/view': (context) => const ViewSponsorsPage(),
            '/sponsors/stats': (context) => const SponsorStatsPage(),

            // Academics
            '/academics/enterResults': (context) => const EnterResultsPage(),
            '/academics/viewResults': (context) => const ViewResultsPage(),
            '/academics/reportCards': (context) => const ReportCardsPage(),
            '/academics/performanceAnalysis': (context) => const PerformanceAnalysisPage(),
            '/academics/academicStats': (context) => const AcademicStatsPage(),

            // Attendance
            '/attendance/attendanceHistory': (context) => const AttendanceHistoryPage(),
            '/attendance/attendanceReports': (context) => const AttendanceModuleReportsPage(),

            // Finance
            '/finance/scholarshipPayments': (context) => const ScholarshipPaymentsPage(),
            '/finance/paymentHistory': (context) => const PaymentHistoryPage(),
            '/finance/expenses': (context) => const ExpensesPage(),
            '/finance/budget': (context) => const BudgetPage(),
            '/finance/financialReports': (context) => const FinancialReportsPage(),

            // Reports
            '/reports/scholar': (context) => const ScholarReportsPage(),
            '/reports/school': (context) => const SchoolReportsPage(),
            '/reports/sponsor': (context) => const SponsorReportsPage(),
            '/reports/finance': (context) => const FinanceReportsPage(),
            '/reports/exportPDF': (context) => const ExportPDFPage(),
            '/reports/exportExcel': (context) => const ExportExcelPage(),

            // Users
            '/users/create': (context) => const CreateUserPage(),
            '/users/manage': (context) => const ManageUsersPage(),
            '/users/roles': (context) => const UserRolesPage(),
            '/users/permissions': (context) => const PermissionsPage(),
            '/users/profile': (context) => const UserProfilePage(),

            // Settings
            '/settings/organisationProfile': (context) => const OrganisationProfilePage(),
            '/settings/backupRestore': (context) => const BackupRestorePage(),
            '/settings/systemSettings': (context) => const SystemSettingsPage(),
            '/settings/accountSettings': (context) => const AccountSettingsPage(),
          },
        );
      },
    );
  }
}

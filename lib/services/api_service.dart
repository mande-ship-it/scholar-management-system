import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiService {
  static String? _token;
  static const String _tokenKey = 'auth_token';
  static const String _useLocalKey = 'use_local_backend';
  static bool _useLocalOverride = false;

  static const String remoteUrl = 'https://age-systems-backend.onrender.com';

  static String get localUrl {
    if (kIsWeb) return 'http://localhost:5000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000'; // Emulator
      default:
        return 'http://localhost:5000';
    }
  }

  static String get baseUrl {
    // If user explicitly chose local via settings
    final prefs = _prefs;
    if (prefs != null && prefs.containsKey(_useLocalKey)) {
      return prefs.getBool(_useLocalKey)! ? localUrl : remoteUrl;
    }

    // Default logic
    if (kReleaseMode) return remoteUrl;
    if (kIsWeb) return remoteUrl;

    return localUrl;
  }

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs!.getString(_tokenKey);
    _dio.options.baseUrl = '$baseUrl/api';
  }

  static bool get isUsingLocal => baseUrl == localUrl;

  static Future<void> toggleBackend(bool useLocal) async {
    if (_prefs != null) {
      await _prefs!.setBool(_useLocalKey, useLocal);
      _dio.options.baseUrl = '$baseUrl/api';
    }
  }

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://age-systems-backend.onrender.com/api', // Initial placeholder, updated in init()
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    validateStatus: (status) => status != null && status < 500,
  ))..interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      if (_token != null) {
        options.headers['Authorization'] = 'Bearer $_token';
      }
      return handler.next(options);
    },
  ));

  static Dio get dio => _dio;

  static void setToken(String token, {bool persist = false}) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (persist) {
      await prefs.setString(_tokenKey, token);
    } else {
      await prefs.remove(_tokenKey);
    }
  }

  static Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static bool get isAuthenticated => _token != null;

  static String getFullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    // Remove leading ./ or / if present
    String cleanPath = path;
    if (cleanPath.startsWith('./')) {
      cleanPath = cleanPath.substring(2);
    }
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    return '$baseUrl/$cleanPath';
  }

  static Future<Response> login(String email, String password) async {
    return await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
  }

  static Future<Response> verifyOTP(String userId, String otp) async {
    return await _dio.post('/auth/verify-otp', data: {
      'userId': userId,
      'otp': otp,
    });
  }

  static Future<Response> forgotPassword(String email) async {
    return await _dio.post('/auth/forgot-password', data: {'email': email});
  }

  static Future<Response> resetPassword(String email, String otp, String newPassword) async {
    return await _dio.post('/auth/reset-password', data: {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
  }

  static Future<Response> changeFirstPassword(String newPassword) async {
    return await _dio.post('/auth/change-password', data: {
      'newPassword': newPassword,
    });
  }

  // Scholars
  static Future<Response> getAllScholars() async {
    return await _dio.get('/scholars');
  }

  static Future<Response> getScholarById(String id) async {
    return await _dio.get('/scholars/$id');
  }

  static Future<Response> createScholar(Map<String, dynamic> data) async {
    return await _dio.post('/scholars', data: data);
  }

  static Future<Response> updateScholar(String id, Map<String, dynamic> data) async {
    return await _dio.put('/scholars/$id', data: data);
  }

  static Future<Response> deleteScholar(String id) async {
    return await _dio.delete('/scholars/$id');
  }

  static Future<Response> promoteScholar(String id, String nextClass) async {
    return await _dio.put('/scholars/$id', data: {'currentClass': nextClass});
  }

  static Future<Response> getScholarsBySchool({String? schoolId, String? schoolName}) async {
    return await _dio.get('/scholars/by-school', queryParameters: {
      'schoolId': schoolId,
      'schoolName': schoolName,
    });
  }

  static Future<Response> getUniversityGraduates() async {
    return await _dio.get('/scholars/graduates');
  }

  static Future<Response> getAlumni() async {
    return await _dio.get('/scholars/alumni');
  }

  static Future<Response> getScholarStats() async {
    return await _dio.get('/scholars/stats');
  }

  // Attendance
  static Future<Response> getAttendanceHistory({
    String? type,
    String? schoolId,
    String? schoolName,
    int? month,
    int? weekNumber,
    String? term,
    String? semester,
  }) async {
    return await _dio.get('/attendance/history', queryParameters: {
      'type': type,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'month': month,
      'week_number': weekNumber,
      'term': term,
      'semester': semester,
    });
  }

  static Future<Response> getSchoolAttendanceReport(
    String schoolId, {
    int? month,
    int? weekNumber,
    String? term,
    String? semester,
    String? year,
  }) async {
    return await _dio.get('/attendance/school-report/$schoolId', queryParameters: {
      'month': month,
      'week_number': weekNumber,
      'term': term,
      'semester': semester,
      'year': year,
    });
  }

  static Future<Response> getAttendanceAnalytics() async {
    return await _dio.get('/attendance/analytics');
  }

  static Future<Response> saveAttendance(Map<String, dynamic> data) async {
    return await _dio.post('/attendance/record', data: data);
  }

  // Payments
  static Future<Response> getPaymentsByScholar(String scholarId) async {
    return await _dio.get('/payments/scholar/$scholarId');
  }

  static Future<Response> recordPayment(Map<String, dynamic> data) async {
    return await _dio.post('/payments/record', data: data);
  }

  // Academics
  static Future<Response> getResultsByScholar(String scholarId, {String? year}) async {
    return await _dio.get('/academic/results', queryParameters: {
      'scholarId': scholarId,
      if (year != null) 'year': year,
    });
  }

  static Future<Response> getResultsBySchool(String? schoolName, {String? schoolId, int? year, String? term, String? semester}) async {
    return await _dio.get('/academic/results/by-school', queryParameters: {
      'schoolName': schoolName,
      'schoolId': schoolId,
      'year': year,
      'term': term,
      'semester': semester,
    });
  }

  static Future<Response> recordResults(Map<String, dynamic> data) async {
    return await _dio.post('/academic/record', data: data);
  }

  static Future<Response> getSubjects({String? level}) async {
    return await _dio.get('/academic/subjects', queryParameters: level != null ? {'level': level} : null);
  }

  static Future<Response> getYearlyStats(String year) async {
    return await _dio.get('/academic/stats/$year');
  }

  static Future<Response> checkResultCompleteness(String scholarId, int year) async {
    return await _dio.get('/academic/completeness/$scholarId/$year');
  }

  static Future<Response> getSchoolsWithResults() async {
    return await _dio.get('/academic/schools-with-results');
  }

  // Schools
  static Future<Response> getAllSchools() async {
    return await _dio.get('/schools');
  }

  static Future<Response> getSchoolById(String id) async {
    return await _dio.get('/schools/$id');
  }

  static Future<Response> createSchool(Map<String, dynamic> data) async {
    return await _dio.post('/schools', data: data);
  }

  static Future<Response> updateSchool(String id, Map<String, dynamic> data) async {
    return await _dio.put('/schools/$id', data: data);
  }

  static Future<Response> toggleSchoolStatus(String id) async {
    return await _dio.patch('/schools/$id/status');
  }

  static Future<Response> deleteSchool(String id) async {
    return await _dio.delete('/schools/$id');
  }

  // Sponsors
  static Future<Response> getAllSponsors() async {
    return await _dio.get('/sponsors');
  }

  static Future<Response> getSponsorById(String id) async {
    return await _dio.get('/sponsors/$id');
  }

  static Future<Response> createSponsor(Map<String, dynamic> data) async {
    return await _dio.post('/sponsors', data: data);
  }

  static Future<Response> updateSponsor(String id, Map<String, dynamic> data) async {
    return await _dio.put('/sponsors/$id', data: data);
  }

  static Future<Response> deleteSponsor(String id) async {
    return await _dio.delete('/sponsors/$id');
  }

  static Future<Response> getSponsorStats() async {
    return await _dio.get('/sponsors/stats');
  }

  // Users
  static Future<Response> getAllUsers() async {
    return await _dio.get('/users');
  }

  static Future<Response> getUserById(String id) async {
    return await _dio.get('/users/$id');
  }

  static Future<Response> createUser(Map<String, dynamic> data) async {
    return await _dio.post('/users', data: data);
  }

  static Future<Response> updateUser(String id, Map<String, dynamic> data) async {
    return await _dio.put('/users/$id', data: data);
  }

  static Future<Response> deleteUser(String id) async {
    return await _dio.delete('/users/$id');
  }

  static Future<Response> getActiveUsers() async {
    return await _dio.get('/users/active');
  }

  static Future<Response> getDirector() async {
    return await _dio.get('/users/director');
  }

  // Roles
  static Future<Response> getAllRoles() async {
    return await _dio.get('/roles');
  }

  static Future<Response> createRole(Map<String, dynamic> data) async {
    return await _dio.post('/roles', data: data);
  }

  static Future<Response> updateRole(String id, Map<String, dynamic> data) async {
    return await _dio.put('/roles/$id', data: data);
  }

  static Future<Response> deleteRole(String id) async {
    return await _dio.delete('/roles/$id');
  }

  static Future<Response> getPermissionGroups() async {
    return await _dio.get('/roles/permissions');
  }

  static Future<Response> updateRolePermissions(String id, List<String> permissions) async {
    return await _dio.patch('/roles/$id/permissions', data: {'permissions': permissions});
  }

  // Departments
  static Future<Response> getAllDepartments() async {
    return await _dio.get('/departments');
  }

  static Future<Response> getAllDepartmentsWithCounts() async {
    return await _dio.get('/departments/with-counts');
  }

  static Future<Response> getDepartmentUsers(String id) async {
    return await _dio.get('/departments/$id/users');
  }

  static Future<Response> createDepartment(Map<String, dynamic> data) async {
    return await _dio.post('/departments', data: data);
  }

  static Future<Response> updateDepartment(String id, Map<String, dynamic> data) async {
    return await _dio.put('/departments/$id', data: data);
  }

  static Future<Response> deleteDepartment(String id) async {
    return await _dio.delete('/departments/$id');
  }

  // Settings
  static Future<Response> getAccountProfile() async {
    return await _dio.get('/settings/profile');
  }

  static Future<Response> updateAccountProfile(Map<String, dynamic> data) async {
    return await _dio.put('/settings/profile', data: data);
  }

  static Future<Response> uploadProfilePicture(List<int> bytes, String fileName) async {
    FormData formData = FormData.fromMap({
      "profilePicture": MultipartFile.fromBytes(bytes, filename: fileName),
    });
    return await _dio.post('/settings/profile/upload', data: formData);
  }

  static Future<Response> changePassword(String currentPassword, String newPassword) async {
    return await _dio.post('/settings/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  static Future<Response> getOrganisationProfile() async {
    return await _dio.get('/settings/organisation');
  }

  static Future<Response> updateOrganisationProfile(Map<String, dynamic> data) async {
    return await _dio.put('/settings/organisation', data: data);
  }

  static Future<Response> getUserSettings() async {
    return await _dio.get('/settings/preferences');
  }

  static Future<Response> updateUserSettings(Map<String, dynamic> data) async {
    return await _dio.put('/settings/preferences', data: data);
  }

  static Future<Response> getBackupInfo() async {
    return await _dio.get('/settings/backup');
  }

  static Future<Response> updateBackupSettings(Map<String, dynamic> data) async {
    return await _dio.put('/settings/backup/settings', data: data);
  }

  static Future<Response> runBackup(String label) async {
    return await _dio.post('/settings/backup/run', data: {'label': label});
  }

  static Future<Response> restoreBackup(String backupId) async {
    return await _dio.post('/settings/backup/restore', data: {'backupId': backupId});
  }

  // Notifications
  static Future<Response> getNotifications() async {
    return await _dio.get('/notifications');
  }

  static Future<Response> markNotificationRead(String id) async {
    return await _dio.patch('/notifications/$id/read');
  }

  static Future<Response> markAllNotificationsRead() async {
    return await _dio.patch('/notifications/read-all');
  }

  static Future<Response> deleteNotification(String id) async {
    return await _dio.delete('/notifications/$id');
  }

  static Future<Response> getRecentActivities() async {
    return await _dio.get('/notifications/recent');
  }

  // Approvals
  static Future<Response> getPendingActivities() async {
    return await _dio.get('/approvals/pending');
  }

  static Future<Response> approveActivity(String type, String id) async {
    return await _dio.patch('/approvals/approve/$type/$id');
  }

  static Future<Response> rejectActivity(String type, String id) async {
    return await _dio.delete('/approvals/reject/$type/$id');
  }

  // Events
  static Future<Response> getAllEvents() async {
    return await _dio.get('/events');
  }

  static Future<Response> createEvent(Map<String, dynamic> data) async {
    return await _dio.post('/events', data: data);
  }

  static Future<Response> updateEvent(String id, Map<String, dynamic> data) async {
    return await _dio.put('/events/$id', data: data);
  }

  static Future<Response> deleteEvent(String id) async {
    return await _dio.delete('/events/$id');
  }

  static Future<Response> approveEvent(String id) async {
    return await _dio.patch('/events/$id/approve');
  }

  // Dashboard
  static Future<Response> getDashboardStats({String? level, String? schoolId}) async {
    return await _dio.get('/dashboard', queryParameters: {
      if (level != null) 'level': level,
      if (schoolId != null) 'schoolId': schoolId,
    });
  }

  static Future<Response> getDistrictsMapData() async {
    return await _dio.get('/dashboard/districts-map');
  }

  // AI Assistant
  static Future<Response> chatWithAI(String message, {String? currentPage, String? targetId}) async {
    return await _dio.post('/ai/chat', data: {
      'message': message,
      'currentPage': currentPage ?? 'Global Navigation',
      if (targetId != null) 'targetId': targetId,
    });
  }

  // Internships
  static Future<Response> getAllInternships() async {
    return await _dio.get('/internships');
  }

  static Future<Response> allocateInternship(Map<String, dynamic> data) async {
    return await _dio.post('/internships/allocate', data: data);
  }

  // Performance Intelligence (New)
  static Future<Response> getScholarTrend(String id) async {
    return await _dio.get('/performance/scholar/$id');
  }

  static Future<Response> getCohortAnalytics(String type) async {
    return await _dio.get('/performance/cohort', queryParameters: {'schoolType': type});
  }

  static Future<Response> getSubjectInsights(String type) async {
    return await _dio.get('/performance/subjects', queryParameters: {'schoolType': type});
  }

  static Future<Response> getEarlyWarningRisk() async {
    return await _dio.get('/performance/risk-indicators');
  }
}

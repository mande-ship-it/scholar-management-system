import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String? _token;
  static const String _tokenKey = 'auth_token';
  static const String baseUrl = 'http://localhost:5000';

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: '$baseUrl/api', // Use http://10.0.2.2:5000 for Android emulator
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ))..interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      if (_token != null) {
        options.headers['Authorization'] = 'Bearer $_token';
      }
      return handler.next(options);
    },
  ));

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  static void setToken(String token, {bool persist = false}) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (persist) {
      await prefs.setString(_tokenKey, token);
    } else {
      // Clear any previously saved token if the user doesn't want to be remembered
      await prefs.remove(_tokenKey);
    }
  }

  static Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static bool get isAuthenticated => _token != null;

  static Future<Response> login(String email, String password) async {
    return await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
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

  // Attendance
  static Future<Response> getAttendanceHistory({String? type, String? schoolId, String? schoolName}) async {
    return await _dio.get('/attendance/history', queryParameters: {
      'type': type,
      'schoolId': schoolId,
      'schoolName': schoolName,
    });
  }

  static Future<Response> getAttendanceAnalytics() async {
    return await _dio.get('/attendance/analytics');
  }

  static Future<Response> saveAttendance(Map<String, dynamic> data) async {
    return await _dio.post('/attendance/record', data: data);
  }

  // Academics
  static Future<Response> getResultsByScholar(String scholarId) async {
    return await _dio.get('/academic/results', queryParameters: {'scholarId': scholarId});
  }

  static Future<Response> getResultsBySchool(String schoolName) async {
    return await _dio.get('/academic/results/by-school', queryParameters: {'schoolName': schoolName});
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

  static Future<Response> getScholarsForPromotion({String? schoolId, String? schoolName, String? year}) async {
    return await _dio.get('/schools/progression/review', queryParameters: {
      'schoolId': schoolId,
      'schoolName': schoolName,
      'year': year,
    });
  }

  static Future<Response> promoteScholarViaSchool(String scholarId) async {
    return await _dio.post('/schools/promote/$scholarId');
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

  static Future<Response> getScholarsBySponsor(String sponsorId) async {
    return await _dio.get('/sponsors/$sponsorId/scholars');
  }

  // Users
  static Future<Response> getAllUsers() async {
    return await _dio.get('/users');
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

  // Dashboard
  static Future<Response> getDashboardStats() async {
    return await _dio.get('/dashboard');
  }

  static Future<Response> getDashboardPredictions() async {
    return await _dio.get('/dashboard/predictions');
  }

  // Reports
  static Future<Response> getScholarReport({String? period, String? type}) async {
    return await _dio.get('/reports/scholars', queryParameters: {'period': period, 'type': type});
  }

  static Future<Response> getSchoolReport({String? level}) async {
    return await _dio.get('/reports/schools', queryParameters: {'level': level});
  }

  static Future<Response> getSponsorReport({String? region}) async {
    return await _dio.get('/reports/sponsors', queryParameters: {'region': region});
  }

  static Future<Response> getAttendanceReport({String? month}) async {
    return await _dio.get('/reports/attendance', queryParameters: {'month': month});
  }

  // Reports / Exports
  static Future<Response> exportToExcel(List<String> datasets) async {
    return await _dio.post(
      '/reports/export/excel',
      data: {'datasets': datasets},
      options: Options(responseType: ResponseType.bytes),
    );
  }

  static Future<Response> exportToPDF(List<String> modules) async {
    return await _dio.post(
      '/reports/export/pdf',
      data: {'modules': modules},
      options: Options(responseType: ResponseType.bytes),
    );
  }
}

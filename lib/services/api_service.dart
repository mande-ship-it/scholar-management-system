import 'package:dio/dio.dart';

class ApiService {
  static String? _token;

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:5000/api', // Use http://10.0.2.2:5000 for Android emulator
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

  static void setToken(String token) {
    _token = token;
  }

  static Future<Response> login(String email, String password) async {
    return await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
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
  static Future<Response> getAttendanceBySchool({String? schoolId, String? schoolName, String? date}) async {
    return await _dio.get('/attendance', queryParameters: {
      'schoolId': schoolId,
      'schoolName': schoolName,
      'date': date,
    });
  }

  static Future<Response> saveAttendance(Map<String, dynamic> data) async {
    return await _dio.post('/attendance', data: data);
  }

  // Finance
  static Future<Response> getAllBudgets() async {
    return await _dio.get('/finance/budgets');
  }

  static Future<Response> getAllPayments() async {
    return await _dio.get('/finance/payments');
  }

  static Future<Response> getPaymentsByScholar(String scholarId) async {
    return await _dio.get('/finance/payments', queryParameters: {'scholarId': scholarId});
  }

  static Future<Response> createPayment(Map<String, dynamic> data) async {
    return await _dio.post('/finance/payments', data: data);
  }

  static Future<Response> updatePaymentStatus(String id, String status) async {
    return await _dio.patch('/finance/payments/$id/status', data: {'status': status});
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
}

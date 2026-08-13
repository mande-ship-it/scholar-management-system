import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scholar_management_system/services/api_service.dart';

void main() {
  test('Test API connection and authentication with local backend', () async {
    // Override platform to Windows/macOS/Linux so the localUrl defaults to localhost:5000
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    // Mock shared preferences to enforce local backend connection
    SharedPreferences.setMockInitialValues({
      'use_local_backend': true,
    });
    
    await ApiService.init();
    
    // Verify base URL points to localhost:5000
    expect(ApiService.baseUrl, 'http://localhost:5000');
    
    try {
      // Test 1: Query API Health Check
      final healthResponse = await ApiService.dio.get('/health');
      expect(healthResponse.statusCode, 200);
      expect(healthResponse.data['status'], 'UP');
      print('✅ API Health connection test passed!');
      
      // Test 2: Query API Login authentication
      final loginResponse = await ApiService.login('edward', 'Password123!');
      expect(loginResponse.statusCode, 200);
      expect(loginResponse.data['success'], true);
      expect(loginResponse.data['data']['token'], isNotEmpty);
      print('✅ API Authentication connection test passed!');
    } catch (e) {
      fail('Failed to connect to local backend api: $e');
    } finally {
      // Reset the platform override
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

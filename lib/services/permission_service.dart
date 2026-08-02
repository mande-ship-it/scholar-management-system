import 'package:flutter/foundation.dart';
import 'api_service.dart';

class PermissionService {
  static List<String> _userPermissions = [];
  static String? _userRole;

  static void init(Map<String, dynamic> userData) {
    _userRole = userData['role_name'] ?? userData['role'] ?? 'User';
    final List<dynamic> perms = userData['roleId']?['permissions'] ?? userData['permissions'] ?? [];
    _userPermissions = perms.map((e) => e.toString()).toList();
    debugPrint('Permissions initialized for role: $_userRole');
  }

  static bool hasPermission(String permission) {
    // 1. Administrators have full system bypass
    if (_userRole == 'Administrator') return true;

    // 2. Check specific permission
    return _userPermissions.contains(permission);
  }

  static bool hasAnyPermission(List<String> permissions) {
    if (_userRole == 'Administrator') return true;
    return permissions.any((p) => _userPermissions.contains(p));
  }

  static String? get userRole => _userRole;
  static List<String> get userPermissions => List.unmodifiable(_userPermissions);
}

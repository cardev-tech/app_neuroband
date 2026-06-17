// lib/services/auth_service.dart

import 'package:flutter/foundation.dart';

class UserSession {
  final String username;
  final String role; // 'admin' | 'patient'
  UserSession(this.username, this.role);
}

class AuthService extends ChangeNotifier {
  static const _users = {
    'admin':  ('admin2026',  'admin'),
    'oscar':  ('neuro2026',  'patient'),
    'maria':  ('neuro2026',  'patient'),
  };

  UserSession? _session;
  UserSession? get session => _session;
  bool get isLoggedIn => _session != null;

  /// Returns null on success, error string on failure.
  String? login(String username, String password) {
    final entry = _users[username.trim().toLowerCase()];
    if (entry == null || entry.$1 != password) {
      return 'Usuario o contraseña incorrectos';
    }
    _session = UserSession(username.trim().toLowerCase(), entry.$2);
    notifyListeners();
    return null;
  }

  void logout() {
    _session = null;
    notifyListeners();
  }
}

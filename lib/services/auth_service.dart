import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  final ApiService _api = ApiService();

  String? _email;
  String? _lastError;

  Future<void> init() async {
    await _api.init();
    if (_api.isLoggedIn) {
      try {
        await _api.verify();
      } catch (_) {
        await _api.logout();
      }
    }
  }

  String? get loggedInEmail => _email;
  String? get userUuid => _api.userId;
  String? get lastError => _lastError;
  bool get isLoggedIn => _api.isLoggedIn;

  Future<bool> signup(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) return false;
    _lastError = null;

    try {
      await _api.signup(normalizedEmail, password);
      _email = normalizedEmail;
      return true;
    } catch (e) {
      _lastError = e is ApiException ? e.message : e.toString();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) return false;
    _lastError = null;

    try {
      await _api.login(normalizedEmail, password);
      _email = normalizedEmail;
      return true;
    } catch (e) {
      _lastError = e is ApiException ? e.message : e.toString();
      return false;
    }
  }

  Future<void> logout() async {
    _email = null;
    _lastError = null;
    await _api.logout();
  }
}

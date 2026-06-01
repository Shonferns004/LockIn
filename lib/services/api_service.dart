import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  static const _tokenKey = 'api_token';
  static const _userIdKey = 'api_user_id';

  String _baseUrl = AppConstants.apiUrl;
  String? _token;
  String? _userId;

  Future<void> init({String? baseUrl}) async {
    if (baseUrl != null) _baseUrl = baseUrl;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _userId = prefs.getString(_userIdKey);
  }

  String? get token => _token;
  String? get userId => _userId;
  bool get isLoggedIn => _token != null && _userId != null;

  void setBaseUrl(String url) => _baseUrl = url;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) await prefs.setString(_tokenKey, _token!);
    if (_userId != null) await prefs.setString(_userIdKey, _userId!);
  }

  Future<void> _clearSession() async {
    _token = null;
    _userId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final res = await http
        .get(Uri.parse('$_baseUrl$path'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) throw ApiException(res.statusCode, res.body);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getList(String path) async {
    final res = await http
        .get(Uri.parse('$_baseUrl$path'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) throw ApiException(res.statusCode, res.body);
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final res = await http
        .post(Uri.parse('$_baseUrl$path'),
            headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) throw ApiException(res.statusCode, res.body);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> put(
      String path, Map<String, dynamic> body) async {
    final res = await http
        .put(Uri.parse('$_baseUrl$path'),
            headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) throw ApiException(res.statusCode, res.body);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patch(
      String path, Map<String, dynamic> body) async {
    final res = await http
        .patch(Uri.parse('$_baseUrl$path'),
            headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) throw ApiException(res.statusCode, res.body);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final res = await http
        .delete(Uri.parse('$_baseUrl$path'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode >= 400) throw ApiException(res.statusCode, res.body);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Auth helpers ──

  Future<Map<String, dynamic>> signup(
      String email, String password) async {
    final res = await post('/auth/signup', {
      'email': email,
      'password': password,
    });
    _token = res['token'] as String;
    _userId = res['userId'] as String;
    await _saveSession();
    return res;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await post('/auth/login', {
      'email': email,
      'password': password,
    });
    _token = res['token'] as String;
    _userId = res['userId'] as String;
    await _saveSession();
    return res;
  }

  Future<void> verify() async {
    if (_token == null) throw ApiException(401, 'No token');
    await get('/auth/verify');
  }

  Future<void> logout() async {
    await _clearSession();
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  String get message {
    try {
      return (jsonDecode(body) as Map)['error'] as String? ?? body;
    } catch (_) {
      return body;
    }
  }

  @override
  String toString() => 'ApiException($statusCode): ${message}';
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/energy_drink.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      statusCode != null ? 'ApiException($statusCode): $message' : message;
}

class DrinkApiService {
  final http.Client _client;
  String? _authToken;

  DrinkApiService({http.Client? client}) : _client = client ?? http.Client();

  bool get isAuthenticated => _authToken != null;

  static String get _apiRoot =>
      kDebugMode ? 'http://localhost:8080/api' : '/api';

  static String get _drinksUrl => '$_apiRoot/drinks';

  Future<void> login(String username, String password) async {
    final response = await _client.post(
      Uri.parse('$_apiRoot/auth/login'),
      headers: const {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _extractErrorMessage(response),
        statusCode: response.statusCode,
      );
    }

    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    _authToken = body['token'] as String?;
  }

  Future<void> logout() async {
    final token = _authToken;
    _authToken = null;
    if (token == null) return;

    try {
      await _client.post(
        Uri.parse('$_apiRoot/auth/logout'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      debugPrint('Logout request failed: $e');
    }
  }

  Future<List<EnergyDrink>> rollThree() async {
    return _getDrinkList('$_drinksUrl/roll');
  }

  Future<List<EnergyDrink>> fetchAll() async {
    return _getDrinkList(_drinksUrl);
  }

  Future<void> addDrink(EnergyDrink drink) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };

    final response = await _client.post(
      Uri.parse(_drinksUrl),
      headers: headers,
      body: jsonEncode(drink.toJson()),
    );

    if (response.statusCode == 401) {
      _authToken = null;
      throw const ApiException(
        'Session expired or unauthorized.',
        statusCode: 401,
      );
    }

    if (response.statusCode != 201) {
      throw ApiException(
        _extractErrorMessage(response),
        statusCode: response.statusCode,
      );
    }
  }

  Future<List<EnergyDrink>> _getDrinkList(String url) async {
    final response = await _client.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw ApiException(
        _extractErrorMessage(response),
        statusCode: response.statusCode,
      );
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return decoded
        .map((item) => EnergyDrink.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic> && body['error'] != null) {
        return body['error'].toString();
      }
    } catch (_) {
      // Response body is not valid JSON
    }
    return 'Server communication error (HTTP ${response.statusCode})';
  }

  void dispose() {
    _client.close();
  }
}
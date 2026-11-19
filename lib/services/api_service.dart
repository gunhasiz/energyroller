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
      statusCode != null ? '[$statusCode] $message' : message;
}

class DrinkApiService {
  final http.Client _client;

  DrinkApiService({http.Client? client}) : _client = client ?? http.Client();

  static String get _baseUrl =>
      kDebugMode ? 'http://localhost:8080/api/drinks' : '/api/drinks';

  Future<List<EnergyDrink>> rollThree() async {
    return _getDrinkList('$_baseUrl/roll');
  }

  Future<List<EnergyDrink>> fetchAll() async {
    return _getDrinkList(_baseUrl);
  }

  Future<void> addDrink(EnergyDrink drink) async {
    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: const {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(drink.toJson()),
    );

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

    final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
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
      // TODO: Ignore at the moment
    }
    return 'Błąd komunikacji z serwerem';
  }

  void dispose() {
    _client.close();
  }
}
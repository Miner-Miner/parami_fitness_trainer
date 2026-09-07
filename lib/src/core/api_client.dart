import 'dart:convert';

import 'package:http/http.dart' as http;

import 'session_store.dart';

class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this.session);

  static const defaultBaseUrl = 'https://parami.coreaxistechnologies.website';
  static const defaultDatabase = 'parami_demo';

  final TrainerSession session;

  static Future<TrainerSession> login({
    required String baseUrl,
    required String database,
    required String login,
    required String password,
  }) async {
    final normalisedUrl = _normaliseBaseUrl(baseUrl);
    final response = await http
        .post(
          Uri.parse('$normalisedUrl/gym/api/login'),
          headers: {
            'Content-Type': 'application/json',
            'X-Odoo-Database': database.trim(),
          },
          body: jsonEncode({
            'login': login.trim(),
            'password': password,
            'user_role': 'trainer',
          }),
        )
        .timeout(const Duration(seconds: 20));

    final payload = _readPayload(response);
    final data = _asMap(payload['data']);
    final sessionId = _text(data['session_id']);
    final userId = _int(data['user_id']);

    if (sessionId.isEmpty || userId == null) {
      throw const ApiFailure('The server did not return a trainer session.');
    }

    if (_text(data['user_role']) != 'trainer') {
      throw const ApiFailure('This account is not configured as a trainer.');
    }

    return TrainerSession(
      baseUrl: normalisedUrl,
      database: database.trim(),
      sessionId: sessionId,
      userId: userId,
      name: _text(data['name'], fallback: 'Trainer'),
      login: _text(data['login']),
      memberId: _text(data['member_id']),
    );
  }

  Future<List<Map<String, dynamic>>> customers({
    bool activeOnly = false,
  }) async {
    final data = await _request(
      'GET',
      '/gym/api/trainer/customers',
      query: {
        'trainer_id': '${session.userId}',
        if (activeOnly) 'state': 'active',
      },
    );
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> classes() async {
    final data = await _request(
      'GET',
      '/gym/api/trainer/classes',
      query: {'trainer_id': '${session.userId}'},
    );
    return _asMapList(data);
  }

  Future<List<Map<String, dynamic>>> schedule({
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    final data = await _request(
      'GET',
      '/gym/api/trainer/schedule',
      query: {
        'trainer_id': '${session.userId}',
        'date_from': _apiDate(dateFrom),
        'date_to': _apiDate(dateTo),
      },
    );
    return _asMapList(data);
  }

  Future<Map<String, dynamic>> profile() async {
    final data = await _request(
      'GET',
      '/gym/api/profile',
      query: {'user_id': '${session.userId}'},
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> consumeSession({
    required int customerUserId,
  }) async {
    final data = await _request(
      'POST',
      '/gym/api/trainer/session/consume',
      body: {'trainer_id': session.userId, 'user_id': customerUserId},
    );
    return _asMap(data);
  }

  Future<Map<String, dynamic>> markClassDone({
    required int customerUserId,
    required int classId,
    required DateTime date,
    int? scheduleId,
  }) async {
    final data = await _request(
      'POST',
      '/gym/api/trainer/class/done',
      body: {
        'trainer_id': session.userId,
        'user_id': customerUserId,
        'class_id': classId,
        'date': _apiDate(date),
        if (scheduleId != null) 'schedule_id': scheduleId,
      },
    );
    return _asMap(data);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(
      '${_normaliseBaseUrl(session.baseUrl)}$path',
    ).replace(queryParameters: query);
    final headers = <String, String>{
      'Accept': 'application/json',
      'X-Odoo-Database': session.database,
      'Cookie': 'session_id=${session.sessionId}',
    };
    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }

    late http.Response response;
    try {
      response = body == null
          ? await http
                .get(uri, headers: headers)
                .timeout(const Duration(seconds: 20))
          : await http
                .post(uri, headers: headers, body: jsonEncode(body))
                .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const ApiFailure(
        'Could not reach the gym server. Check the URL and connection.',
      );
    }

    return _readPayload(response)['data'];
  }

  static Map<String, dynamic> _readPayload(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw ApiFailure(
        response.statusCode >= 400
            ? 'The server returned an error (${response.statusCode}).'
            : 'The server returned an invalid response.',
        statusCode: response.statusCode,
      );
    }

    final payload = _asMap(decoded);
    final message = _text(
      payload['message'],
      fallback: _text(payload['error']),
    );
    if (response.statusCode >= 400 || payload['status'] == 'error') {
      throw ApiFailure(
        message.isEmpty
            ? 'The server returned an error (${response.statusCode}).'
            : message,
        statusCode: response.statusCode,
      );
    }
    return payload;
  }

  static String _normaliseBaseUrl(String value) {
    final clean = value.trim().replaceFirst(RegExp(r'/+$'), '');
    if (clean.isEmpty) {
      throw const ApiFailure('Enter the gym server URL.');
    }
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      return 'https://$clean';
    }
    return clean;
  }

  static List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(_asMap).toList();
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static String _apiDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static String _text(dynamic value, {String fallback = ''}) {
    if (value == null || value == false) return fallback;
    return value.toString();
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}

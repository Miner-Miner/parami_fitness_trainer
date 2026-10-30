import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainerSession {
  const TrainerSession({
    required this.baseUrl,
    required this.database,
    required this.sessionId,
    required this.userId,
    required this.name,
    required this.login,
    required this.memberId,
  });

  final String baseUrl;
  final String database;
  final String sessionId;
  final int userId;
  final String name;
  final String login;
  final String memberId;

  Map<String, Object> toPreferences() => {
    'base_url': baseUrl,
    'database': database,
    'session_id': sessionId,
    'user_id': userId,
    'name': name,
    'login': login,
    'member_id': memberId,
  };

  static TrainerSession? fromPreferences(SharedPreferences preferences) {
    final baseUrl = preferences.getString('base_url');
    final database = preferences.getString('database');
    final sessionId = preferences.getString('session_id');
    final userId = preferences.getInt('user_id');

    if (baseUrl == null ||
        database == null ||
        sessionId == null ||
        userId == null) {
      return null;
    }

    return TrainerSession(
      baseUrl: baseUrl,
      database: database,
      sessionId: sessionId,
      userId: userId,
      name: preferences.getString('name') ?? 'Trainer',
      login: preferences.getString('login') ?? '',
      memberId: preferences.getString('member_id') ?? '',
    );
  }
}

class SessionStore extends ChangeNotifier {
  TrainerSession? _session;
  TrainerTheme _theme = TrainerTheme.monochrome;
  TrainerTheme get theme => _theme;
  bool _isDark = false;
  bool get isDark => _isDark;

  Future<void> setDarkMode(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setBool('trainer_dark_mode', value)) {
      throw StateError('Could not save appearance');
    }
    _isDark = value;
    notifyListeners();
  }

  Future<void> setTheme(TrainerTheme theme) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString('trainer_theme', theme.name)) {
      throw StateError('Could not save theme');
    }
    _theme = theme;
    notifyListeners();
  }

  TrainerSession? get session => _session;
  bool get isAuthenticated => _session != null;

  Future<void> restore() async {
    final preferences = await SharedPreferences.getInstance();
    _session = TrainerSession.fromPreferences(preferences);
    _isDark = preferences.getBool('trainer_dark_mode') ?? false;
    final savedTheme = preferences.getString('trainer_theme');
    _theme = TrainerTheme.values.firstWhere(
      (theme) => theme.name == savedTheme,
      orElse: () => TrainerTheme.monochrome,
    );
  }

  Future<void> save(TrainerSession session) async {
    final preferences = await SharedPreferences.getInstance();
    for (final entry in session.toPreferences().entries) {
      final value = entry.value;
      if (value is String) {
        await preferences.setString(entry.key, value);
      } else if (value is int) {
        await preferences.setInt(entry.key, value);
      }
    }
    _session = session;
    notifyListeners();
  }

  Future<void> signOut() async {
    final preferences = await SharedPreferences.getInstance();
    for (final key in _session?.toPreferences().keys ?? <String>[]) {
      await preferences.remove(key);
    }
    _session = null;
    notifyListeners();
  }
}

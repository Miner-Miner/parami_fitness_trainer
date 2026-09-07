import 'package:flutter/widgets.dart';

import 'src/app.dart';
import 'src/core/session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sessionStore = SessionStore();
  await sessionStore.restore();
  runApp(TrainerApp(sessionStore: sessionStore));
}

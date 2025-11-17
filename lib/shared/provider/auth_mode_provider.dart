import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthMode { login, guest, register }

final authModeProvider = StateProvider<AuthMode>((_) => AuthMode.login);

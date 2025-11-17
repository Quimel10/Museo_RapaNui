import 'package:flutter_riverpod/flutter_riverpod.dart';

/// true = mostrar ForgotForm, false = mostrar LoginForm
final forgotModeProvider = StateProvider.autoDispose<bool>((_) => false);

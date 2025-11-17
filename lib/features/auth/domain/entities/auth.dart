import 'package:disfruta_antofagasta/features/auth/domain/entities/guest.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/session.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/user.dart';

class Auth {
  final String message;
  final String? code;
  final String? type;
  final Session? session;
  final User? profile;
  final Guest? guest;

  Auth({
    required this.message,
    this.type,
    this.code,
    this.session,
    this.profile,
    this.guest,
  });
}

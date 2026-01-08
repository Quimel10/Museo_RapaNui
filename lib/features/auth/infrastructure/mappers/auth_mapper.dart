import 'package:disfruta_antofagasta/features/auth/domain/entities/auth.dart';
import 'package:disfruta_antofagasta/features/auth/infrastructure/mappers/guest_mapper.dart';
import 'package:disfruta_antofagasta/features/auth/infrastructure/mappers/session_mapper.dart';
import 'package:disfruta_antofagasta/features/auth/infrastructure/mappers/user_mapper.dart';

class AuthMapper {
  static Auth fromLoginJson(Map<String, dynamic> json) => Auth(
    message: json['message'],
    type: json['type'],
    session: json['session'] != null
        ? SessionMapper.jsonToEnitity(
            Map<String, dynamic>.from(json['session']),
          )
        : null,
    profile: json['profile'] != null
        ? UserMapper.jsonToEnitity(Map<String, dynamic>.from(json['profile']))
        : null,
    guest: null,
  );

  static Auth fromRegisterJson(Map<String, dynamic> json) => Auth(
    message: json['message'],
    type: json['type'],
    session: json['session'] != null
        ? SessionMapper.jsonToEnitity(
            Map<String, dynamic>.from(json['session']),
          )
        : null,
    profile: json['profile'] != null
        ? UserMapper.jsonToEnitity(Map<String, dynamic>.from(json['profile']))
        : null,
    guest: null,
  );

  static Auth fromGuestJson(Map<String, dynamic> json) => Auth(
    message: json['message'],
    type: json['type'],
    session: json['session'] != null
        ? SessionMapper.jsonToEnitity(
            Map<String, dynamic>.from(json['session']),
          )
        : null,
    profile: null,
    guest: json['guest'] != null
        ? GuestMapper.jsonToEnitity(Map<String, dynamic>.from(json['guest']))
        : null,
  );
}

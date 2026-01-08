// lib/features/auth/domain/datasources/auth_datasource.dart
import 'package:dio/dio.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/auth.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/check_auth.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/register_user.dart';

abstract class AuthDataSource {
  Future<Map<String, String>> forgot(String email);

  Future<Auth> guest({
    required String name,
    required String countryCode,
    int? regionId,
    String? device,
    int? age,
    int? daysStay,
    String? visitorType, // ✅ NUEVO
  });

  Future<Auth> login(String email, String password);

  Future<void> logout(String token);

  Future<Auth> register(RegisterUser register);

  Future<Auth?> reset(String email, String password);

  Future<Auth> me();

  Future<CheckAuthStatus> checkAuthStatus();

  Future<List<Country>> countries({CancelToken? cancelToken});

  Future<List<Region>> regions(int countryId, {CancelToken? cancelToken});

  Future<void> forgotPassword(String email);

  Future<Auth> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}

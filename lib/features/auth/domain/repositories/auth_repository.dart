import 'package:disfruta_antofagasta/features/auth/domain/entities/auth.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/check_auth.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/register_user.dart';

abstract class AuthRepository {
  Future<Auth> login(String email, String password);
  Future<Auth> register(RegisterUser register);
  Future<Map<String, String>> forgot(String email);
  Future<void> logout(String token);
  Future<List<Country>> countries();
  Future<List<Region>> regions(int countryId);
  Future<Auth?> reset(String email, String password);
  Future<Auth?> guest({
    required String name,
    required String countryCode,
    int? regionId,
    int? day,
    int? age,
    String? device,
  });
  Future<Auth> me();
  Future<CheckAuthStatus> checkAuthStatus();
  Future<void> forgotPassword(String email);
  Future<Auth> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}

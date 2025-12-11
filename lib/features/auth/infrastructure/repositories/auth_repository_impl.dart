import 'package:disfruta_antofagasta/features/auth/domain/datasources/auth_datasource.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/auth.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/check_auth.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/register_user.dart';
import 'package:disfruta_antofagasta/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl extends AuthRepository {
  final AuthDataSource dataSource;

  AuthRepositoryImpl({required this.dataSource});

  @override
  Future<Map<String, String>> forgot(String email) {
    throw UnimplementedError();
  }

  @override
  Future<Auth?> guest({
    required String name,
    required String countryCode,
    int? regionId,
    String? device,
    int? age,
    int? daysStay, // 👈 mismo nombre que en el abstract
  }) {
    return dataSource.guest(
      name: name,
      countryCode: countryCode,
      regionId: regionId,
      device: device,
      age: age,
      daysStay: daysStay, // 👈 pasa tal cual al datasource
    );
  }

  @override
  Future<Auth> login(String email, String password) {
    return dataSource.login(email, password);
  }

  @override
  Future<void> logout(String token) {
    throw UnimplementedError();
  }

  @override
  Future<Auth> register(RegisterUser register) {
    return dataSource.register(register);
  }

  @override
  Future<Auth?> reset(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<Auth> me() {
    return dataSource.me();
  }

  @override
  Future<CheckAuthStatus> checkAuthStatus() {
    return dataSource.checkAuthStatus();
  }

  @override
  Future<List<Country>> countries() {
    return dataSource.countries();
  }

  @override
  Future<List<Region>> regions(int countryId) {
    return dataSource.regions(countryId);
  }

  @override
  Future<void> forgotPassword(String email) {
    return dataSource.forgotPassword(email);
  }

  @override
  Future<Auth> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return dataSource.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }
}

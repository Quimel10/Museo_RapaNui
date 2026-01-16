// lib/features/auth/infrastructure/repositories/auth_repository_impl.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'package:disfruta_antofagasta/features/auth/domain/datasources/auth_datasource.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/auth.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/check_auth.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/register_user.dart';
import 'package:disfruta_antofagasta/features/auth/domain/repositories/auth_repository.dart';
import 'package:disfruta_antofagasta/features/auth/infrastructure/mappers/country_mapper.dart';

class AuthRepositoryImpl extends AuthRepository {
  final AuthDataSource dataSource;

  // ✅ FIX: constructor nombrado para que calce con: AuthRepositoryImpl(dataSource: ds)
  AuthRepositoryImpl({required this.dataSource});

  @override
  Future<Map<String, String>> forgot(String email) {
    return dataSource.forgot(email);
  }

  @override
  Future<Auth?> guest({
    required String name,
    required String countryCode,
    int? regionId,
    String? device,
    int? age,
    int? daysStay,
    String? visitorType,
  }) async {
    final auth = await dataSource.guest(
      name: name,
      countryCode: countryCode,
      regionId: regionId,
      device: device,
      age: age,
      daysStay: daysStay,
      visitorType: visitorType,
    );
    return auth;
  }

  @override
  Future<Auth> login(String email, String password) {
    return dataSource.login(email, password);
  }

  @override
  Future<void> logout(String token) {
    return dataSource.logout(token);
  }

  @override
  Future<Auth> register(RegisterUser register) {
    return dataSource.register(register);
  }

  @override
  Future<Auth?> reset(String email, String password) {
    return dataSource.reset(email, password);
  }

  @override
  Future<Auth> me() {
    return dataSource.me();
  }

  @override
  Future<CheckAuthStatus> checkAuthStatus() {
    return dataSource.checkAuthStatus();
  }

  // ===========================================================================
  // ✅ SOLUCIÓN DEFINITIVA: countries SIEMPRE debe devolver lista aunque no haya red
  // - Primero intenta backend
  // - Si falla (offline/DNS/etc) => fallback local (assets) como "tipo visitante"
  // ===========================================================================
  @override
  Future<List<Country>> countries() async {
    try {
      final list = await dataSource.countries(cancelToken: null);

      // Si por alguna razón el backend devuelve vacío, igual caemos a fallback
      if (list.isNotEmpty) return list;

      // ignore: avoid_print
      print('⚠️ countries() backend returned empty list -> using fallback');
      return await _countriesFallbackFromAsset();
    } catch (e) {
      // ignore: avoid_print
      print('❌ countries() backend error -> using fallback: $e');
      return await _countriesFallbackFromAsset();
    }
  }

  Future<List<Country>> _countriesFallbackFromAsset() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/data/countries_fallback.json',
      );
      final decoded = jsonDecode(raw);

      if (decoded is! List) return <Country>[];

      return decoded
          .cast<Map<String, dynamic>>()
          .map(CountryMapper.jsonToEnitity)
          .where((c) => c.active)
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ countries() fallback asset error: $e');
      return <Country>[];
    }
  }

  @override
  Future<List<Region>> regions(int countryId) {
    return dataSource.regions(countryId, cancelToken: null);
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

import 'package:disfruta_antofagasta/features/auth/domain/datasources/auth_datasource.dart';
import 'package:disfruta_antofagasta/features/auth/domain/repositories/auth_repository.dart';
import 'package:disfruta_antofagasta/features/auth/infrastructure/datasources/auth_datasource_impl.dart';
import 'package:disfruta_antofagasta/features/auth/infrastructure/repositories/auth_repository_impl.dart';
import 'package:disfruta_antofagasta/shared/provider/dio_provider.dart';
import 'package:disfruta_antofagasta/shared/services/key_value_storage_service.dart';
import 'package:disfruta_antofagasta/shared/services/key_value_storage_service_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final keyValueStorageServiceProvider = Provider<KeyValueStorageService>((ref) {
  return KeyValueStorageServiceImpl();
});

final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  final dio = ref.read(dioProvider);
  final storage = ref.read(keyValueStorageServiceProvider);
  return AuthDataSourceImpl(dio: dio, keyValueStorageService: storage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final ds = ref.read(authDataSourceProvider);
  return AuthRepositoryImpl(dataSource: ds);
});

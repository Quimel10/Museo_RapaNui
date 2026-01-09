// lib/features/home/presentation/provider/home_repository_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:disfruta_antofagasta/features/home/domain/repositories/home_repository.dart';
import 'package:disfruta_antofagasta/features/home/infrastructure/datasources/home_datasource_impl.dart';
import 'package:disfruta_antofagasta/features/home/infrastructure/repositories/home_repository_impl.dart';
import 'package:disfruta_antofagasta/shared/provider/provider.dart'; // keyValueStorageServiceProvider

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final storage = ref.read(keyValueStorageServiceProvider);

  final dataSource = HomeDatasourceImpl(
    accessToken: '',
    storage: storage, // ✅ cache real en datasource
  );

  return HomeRepositoryImpl(
    dataSource: dataSource,
    storage: storage, // (lo dejamos por si quieres cache extra arriba)
  );
});

import 'package:disfruta_antofagasta/features/home/domain/repositories/home_repository.dart';
import 'package:disfruta_antofagasta/features/home/infrastructure/datasources/home_datasource_impl.dart';
import 'package:disfruta_antofagasta/features/home/infrastructure/repositories/home_repository_impl.dart';
import 'package:disfruta_antofagasta/shared/provider/dio_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final homeRepository = HomeRepositoryImpl(
    HomeDatasourceImpl(accessToken: '', dio: dio),
  );
  return homeRepository;
});

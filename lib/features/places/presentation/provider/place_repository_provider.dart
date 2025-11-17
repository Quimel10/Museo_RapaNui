import 'package:disfruta_antofagasta/features/places/domain/repositories/place_repository.dart';
import 'package:disfruta_antofagasta/features/places/infrastructure/datasources/place_datasource_impl.dart';
import 'package:disfruta_antofagasta/features/places/infrastructure/repositories/place_repository_impl.dart';
import 'package:disfruta_antofagasta/shared/provider/dio_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final placeRepositoryProvider = Provider<PlaceRepository>((ref) {
  final dio = ref.watch(dioProvider);

  final placeRepository = PlaceRepositoryImpl(
    PlaceDatasourceImpl(accessToken: '', dio: dio),
  );
  return placeRepository;
});

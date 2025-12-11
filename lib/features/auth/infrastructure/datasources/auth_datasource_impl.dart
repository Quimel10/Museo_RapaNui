import 'package:dio/dio.dart';
import 'package:disfruta_antofagasta/config/constants/enviroment.dart';
import 'package:disfruta_antofagasta/features/auth/domain/datasources/auth_datasource.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/auth.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/check_auth.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/register_user.dart';
import 'package:disfruta_antofagasta/features/auth/infrastructure/errors/auth_errors.dart';
import 'package:disfruta_antofagasta/features/auth/infrastructure/mappers/auth_mapper.dart';
import 'package:disfruta_antofagasta/features/auth/infrastructure/mappers/check_auth_mapper.dart';
import 'package:disfruta_antofagasta/features/auth/infrastructure/mappers/country_mapper.dart';
import 'package:disfruta_antofagasta/features/auth/infrastructure/mappers/region_mapper.dart';
import 'package:disfruta_antofagasta/shared/services/key_value_storage_service.dart';

class AuthDataSourceImpl extends AuthDataSource {
  final Dio dio;
  late final KeyValueStorageService keyValueStorageService;

  AuthDataSourceImpl({Dio? dio, required this.keyValueStorageService})
    : dio = dio ?? Dio(BaseOptions(baseUrl: Environment.apiUrl)) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await keyValueStorageService.getValue<String>('token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  @override
  Future<Map<String, String>> forgot(String email) {
    throw UnimplementedError();
  }

  // ⬇⬇⬇ MÉTODO GUEST (con daysStay en la firma)
  @override
  Future<Auth> guest({
    required String name,
    required String countryCode,
    int? regionId,
    String? device,
    int? age,
    int? daysStay,
  }) async {
    try {
      final res = await dio.post(
        '/antofa/auth/guest/start',
        data: {
          'name': name,
          'country_code': countryCode,
          'region_id': regionId,
          'device': device,
          'age': age,
          'days_stay': daysStay,
        },
      );

      final data = res.data as Map<String, dynamic>;
      return AuthMapper.fromGuestJson(data);
    } catch (e) {
      throw CustomError('Error desconocido');
    }
  }
  // ⬆⬆⬆ FIN GUEST

  @override
  Future<Auth> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/antofa/auth/login',
        data: {'email': email, 'password': password},
        options: Options(),
      );
      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Error de conexión');
      }
      final apiResponse = AuthMapper.fromLoginJson(response.data);
      return apiResponse;
    } on DioException {
      rethrow;
    } catch (_) {
      throw Exception('Error desconocido');
    }
  }

  @override
  Future<void> logout(String token) {
    throw UnimplementedError();
  }

  @override
  Future<Auth> register(RegisterUser register) async {
    final response = await dio.post(
      '/antofa/auth/register',
      data: register.toJson(),
    );
    final data = response.data as Map<String, dynamic>;
    return AuthMapper.fromRegisterJson(data);
  }

  @override
  Future<Auth?> reset(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<Auth> me() async {
    try {
      final res = await dio.get('/me');
      return AuthMapper.fromLoginJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final res = await dio.get('/me');
        return AuthMapper.fromLoginJson(res.data as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  @override
  Future<CheckAuthStatus> checkAuthStatus() async {
    final res = await dio.get('/antofa/checkAuthStatus');
    return CheckAuthMapper.checkJsonToEntity(res.data);
  }

  @override
  Future<List<Country>> countries({CancelToken? cancelToken}) async {
    final res = await dio.get(
      '/antofa/geo/countries',
      cancelToken: cancelToken,
    );
    final list = (res.data['countries'] as List).cast<Map<String, dynamic>>();
    return list.map(CountryMapper.jsonToEnitity).toList();
  }

  @override
  Future<List<Region>> regions(
    int countryId, {
    CancelToken? cancelToken,
  }) async {
    final res = await dio.get(
      '/antofa/geo/regions',
      queryParameters: {'country_id': countryId},
      cancelToken: cancelToken,
    );
    final list = (res.data['regions'] as List).cast<Map<String, dynamic>>();
    return list.map(RegionMapper.jsonToEnitity).toList();
  }

  @override
  Future<void> forgotPassword(String email) async {
    await dio.post('/antofa/auth/forgot', data: {'email': email});
  }

  @override
  Future<Auth> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final res = await dio.post(
      '/antofa/auth/reset',
      data: {'email': email, 'code': code, 'new_password': newPassword},
      options: Options(validateStatus: (s) => s != null && s >= 200 && s < 300),
    );
    return AuthMapper.fromLoginJson(res.data);
  }
}

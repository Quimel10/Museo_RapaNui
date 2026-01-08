// lib/features/auth/infrastructure/datasources/auth_datasource_impl.dart
import 'package:dio/dio.dart';
import 'package:disfruta_antofagasta/config/constants/enviroment.dart';
import 'package:disfruta_antofagasta/features/auth/domain/datasources/auth_datasource.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/auth.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/check_auth.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/register_user.dart';
import 'package:disfruta_antofagasta/features/auth/infrastructure/mappers/auth_mapper.dart';
import 'package:disfruta_antofagasta/features/auth/infrastructure/mappers/check_auth_mapper.dart';
import 'package:disfruta_antofagasta/features/auth/infrastructure/mappers/country_mapper.dart';
import 'package:disfruta_antofagasta/features/auth/infrastructure/mappers/region_mapper.dart';
import 'package:disfruta_antofagasta/shared/services/key_value_storage_service.dart';

class AuthDataSourceImpl extends AuthDataSource {
  final Dio dio;
  late final KeyValueStorageService keyValueStorageService;

  // Cache: countryId -> countryCode
  final Map<int, String> _countryIdToCode = {};

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

  // ===========================================================================
  // Helpers
  // ===========================================================================

  String _normalizeLang(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v.isEmpty) return 'es';
    final cleaned = v.replaceAll('_', '-');
    final base = cleaned.split('-').first;

    const allowed = {'es', 'en', 'pt', 'fr', 'it', 'ja'};
    if (allowed.contains(base)) return base;
    if (base == 'jp') return 'ja';
    return 'es';
  }

  Future<String> _getLangForApi() async {
    final stored = await keyValueStorageService.getValue<String>('lang');
    return _normalizeLang(stored);
  }

  /// ✅ Construye el WP root de forma segura desde Environment.apiUrl
  /// - Si incluye /ant_q/... => usa /ant_q
  /// - Si no => usa dominio
  Uri _wpRoot() {
    final u = Uri.parse(Environment.apiUrl);

    final seg = u.pathSegments.toList();
    final idx = seg.indexOf('ant_q');

    final wpPathSegments = (idx >= 0) ? seg.take(idx + 1).toList() : <String>[];

    return Uri(
      scheme: u.scheme,
      userInfo: u.userInfo,
      host: u.host,
      port: u.hasPort ? u.port : null,
      pathSegments: wpPathSegments,
    );
  }

  /// ✅ Construye la URI final: /ant_q + /wp-json/app/v1/...
  Uri _wpEndpointUri(List<String> extraSegments, Map<String, String> query) {
    final root = _wpRoot();

    final merged = <String>[
      ...root.pathSegments.where((s) => s.isNotEmpty),
      ...extraSegments.where((s) => s.isNotEmpty),
    ];

    return Uri(
      scheme: root.scheme,
      userInfo: root.userInfo,
      host: root.host,
      port: root.hasPort ? root.port : null,
      pathSegments: merged,
      queryParameters: query,
    );
  }

  // ===========================================================================
  // AuthDataSource
  // ===========================================================================

  @override
  Future<Map<String, String>> forgot(String email) {
    throw UnimplementedError();
  }

  @override
  Future<Auth> guest({
    required String name,
    required String countryCode,
    int? regionId,
    String? device,
    int? age,
    int? daysStay,
    String? visitorType,
  }) async {
    final safeName = name.trim();
    final safeCountry = countryCode.trim().toUpperCase();
    final safeVisitor = (visitorType ?? '').trim();

    final payload = <String, dynamic>{
      'name': safeName,
      'country_code': safeCountry,
      'region_id': regionId,
      'device': device,
      'age': age,
      'days_stay': daysStay,
      if (safeVisitor.isNotEmpty) 'visitor_type': safeVisitor,
    };

    // ignore: avoid_print
    print('👤 POST GUEST START => /antofa/auth/guest/start');
    // ignore: avoid_print
    print('👤 payload => $payload');

    final res = await dio.post('/antofa/auth/guest/start', data: payload);

    return AuthMapper.fromGuestJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<Auth> login(String email, String password) async {
    final response = await dio.post(
      '/antofa/auth/login',
      data: {'email': email, 'password': password},
    );

    if (response.statusCode != 200 || response.data == null) {
      throw Exception('Error de conexión');
    }

    return AuthMapper.fromLoginJson(response.data);
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
    return AuthMapper.fromRegisterJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Auth?> reset(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<Auth> me() async {
    final res = await dio.get('/me');
    return AuthMapper.fromLoginJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<CheckAuthStatus> checkAuthStatus() async {
    final res = await dio.get('/antofa/checkAuthStatus');
    return CheckAuthMapper.checkJsonToEntity(res.data);
  }

  // ===========================================================================
  // ✅ WP GEO
  // ===========================================================================

  @override
  Future<List<Country>> countries({CancelToken? cancelToken}) async {
    final lang = await _getLangForApi();

    final uri = _wpEndpointUri(
      ['wp-json', 'app', 'v1', 'countries'],
      {'lang': lang},
    );

    // ignore: avoid_print
    print('🌍 GET COUNTRIES => $uri');

    final res = await dio.getUri(
      uri,
      options: Options(headers: {'Accept-Language': lang}),
      cancelToken: cancelToken,
    );

    final data = res.data;

    if (data is! List) {
      // ignore: avoid_print
      print('⚠️ COUNTRIES unexpected payload: ${data.runtimeType}');
      return <Country>[];
    }

    final list = data.cast<Map<String, dynamic>>();
    final out = list.map(CountryMapper.jsonToEnitity).toList();

    _countryIdToCode.clear();
    for (final c in out) {
      final code = c.code.trim().toUpperCase();
      if (code.isNotEmpty) _countryIdToCode[c.id] = code;
    }

    return out.where((c) => c.active).toList();
  }

  Future<List<Region>> regionsByCountryCode(
    String countryCode, {
    CancelToken? cancelToken,
  }) async {
    final lang = await _getLangForApi();
    final code = countryCode.trim().toUpperCase();
    if (code.isEmpty) return <Region>[];

    final uri = _wpEndpointUri(
      ['wp-json', 'app', 'v1', 'regions'],
      {'country': code, 'lang': lang},
    );

    // ignore: avoid_print
    print('🗺️ GET REGIONS => $uri');

    final res = await dio.getUri(
      uri,
      options: Options(headers: {'Accept-Language': lang}),
      cancelToken: cancelToken,
    );

    final data = res.data;

    if (data is! List) {
      // ignore: avoid_print
      print('⚠️ REGIONS unexpected payload: ${data.runtimeType}');
      return <Region>[];
    }

    final list = data.cast<Map<String, dynamic>>();
    final out = list.map(RegionMapper.jsonToEnitity).toList();
    return out.where((r) => r.active).toList();
  }

  @override
  Future<List<Region>> regions(
    int countryId, {
    CancelToken? cancelToken,
  }) async {
    final code = _countryIdToCode[countryId];
    if (code == null || code.isEmpty) return <Region>[];
    return regionsByCountryCode(code, cancelToken: cancelToken);
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

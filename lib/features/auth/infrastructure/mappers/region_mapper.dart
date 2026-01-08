import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';

class RegionMapper {
  static int _stableIdFrom(String countryCode, String regionCode) {
    final s =
        '${countryCode.trim().toUpperCase()}_${regionCode.trim().toUpperCase()}';
    if (s.trim().isEmpty) return 1;
    var sum = 0;
    for (final u in s.codeUnits) {
      sum = (sum * 31 + u) & 0x7fffffff;
    }
    return sum == 0 ? 1 : sum;
  }

  static Region jsonToEnitity(Map<String, dynamic> json) {
    final code = (json['code'] ?? '').toString().trim();
    final name = (json['name'] ?? code).toString();

    final rawId = json['id'];
    final id = int.tryParse(rawId?.toString() ?? '') ?? _stableIdFrom('', code);

    final rawCountryId = json['country_id'];
    final countryId = int.tryParse(rawCountryId?.toString() ?? '') ?? 0;

    final activeRaw = json['active'];
    final active = activeRaw == null
        ? true
        : (activeRaw.toString() == '1' ||
              activeRaw.toString().toLowerCase() == 'true');

    return Region(
      id: id,
      countryId: countryId,
      code: code,
      name: name,
      active: active,
    );
  }
}

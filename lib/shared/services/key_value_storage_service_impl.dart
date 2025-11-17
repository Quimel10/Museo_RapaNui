import 'package:shared_preferences/shared_preferences.dart';
import 'key_value_storage_service.dart';

class KeyValueStorageServiceImpl extends KeyValueStorageService {
  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  @override
  Future<T?> getValue<T>(String key) async {
    final prefs = await _prefs;

    // Soporta tipos comunes y evita casts inválidos
    if (T == String || T == dynamic) return prefs.getString(key) as T?;
    if (T == bool) return prefs.getBool(key) as T?;
    if (T == int) return prefs.getInt(key) as T?;
    if (T == double) return prefs.getDouble(key) as T?;
    if (T == List<String>) return prefs.getStringList(key) as T?;
    return null; // Si necesitas objetos, serialízalos a String (JSON)
  }

  @override
  Future<void> setKeyValue<T>(String key, T value) async {
    final prefs = await _prefs;

    if (value is String) {
      await prefs.setString(key, value);
      return;
    }
    if (value is bool) {
      await prefs.setBool(key, value);
      return;
    }
    if (value is int) {
      await prefs.setInt(key, value);
      return;
    }
    if (value is double) {
      await prefs.setDouble(key, value);
      return;
    }
    if (value is List<String>) {
      await prefs.setStringList(key, value);
      return;
    }

    // Fallback: guarda .toString() si meten otro tipo
    await prefs.setString(key, value.toString());
  }

  @override
  Future<bool> removeKey(String key) async {
    final prefs = await _prefs;
    return prefs.remove(key);
  }
}

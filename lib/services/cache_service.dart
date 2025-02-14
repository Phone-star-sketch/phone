import 'package:get/get.dart';

class CacheService extends GetxService {
  static CacheService get to => Get.find();

  final Map<String, dynamic> _cache = {};

  T? get<T>(String key) => _cache[key] as T?;

  void set<T>(String key, T value) => _cache[key] = value;

  void clear() => _cache.clear();

  bool has(String key) => _cache.containsKey(key);
}

import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

abstract class BaseCacheManager {
  Future<CacheStore> getCacheStore();
}

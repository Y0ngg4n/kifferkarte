import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:kifferkarte/cachemanager_stub.dart';

class CacheManager extends BaseCacheManager {
  Future<CacheStore> getCacheStore() async {
    return MemCacheStore();
  }
}

import 'package:dio/dio.dart';

import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';

abstract class BaseCacheManager {
  Future<CacheStore> getCacheStore();
}

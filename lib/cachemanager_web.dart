import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:kifferkarte/cachemanager_stub.dart';
import 'package:dio_cache_interceptor_db_store/dio_cache_interceptor_db_store.dart';

class CacheManager extends BaseCacheManager {
  Future<CacheStore> getCacheStore() async {
    return DbCacheStore(
      databasePath: '', // ignored on web
      databaseName: 'DbCacheStore',
    );
    // return MemCacheStore();
  }
}

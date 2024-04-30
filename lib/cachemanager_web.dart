import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:kifferkarte/cachemanager_stub.dart';

class CacheManager extends BaseCacheManager {
  @override
  Future<CacheStore> getCacheStore() async {
    return HiveCacheStore(null);
  }
}

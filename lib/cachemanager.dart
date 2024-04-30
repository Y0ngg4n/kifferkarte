import 'dart:io' if (dart.library.html) 'dart:html';

import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:kifferkarte/cachemanager_stub.dart';
import 'package:path_provider/path_provider.dart';

class CacheManager extends BaseCacheManager {
  @override
  Future<CacheStore> getCacheStore() async {
    Directory path = await getTemporaryDirectory();
    return HiveCacheStore(path.path);
  }
}

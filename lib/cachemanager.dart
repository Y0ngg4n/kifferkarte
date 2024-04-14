import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor_db_store/dio_cache_interceptor_db_store.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:dio_cache_interceptor_db_store/dio_cache_interceptor_db_store.dart';
import 'package:kifferkarte/cachemanager_stub.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' if (dart.library.html) 'dart:html';

class CacheManager extends BaseCacheManager {
  Future<CacheStore> getCacheStore() async {
    Directory path = await getTemporaryDirectory();
    return DbCacheStore(
      databasePath: path.path,
      databaseName: 'DbCacheStore',
    );
  }
}

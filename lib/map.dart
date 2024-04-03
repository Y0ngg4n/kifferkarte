import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_db_store/dio_cache_interceptor_db_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kifferkarte/location_manager.dart';
import 'package:kifferkarte/overpass.dart';
import 'package:kifferkarte/provider_manager.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

class MapWidget extends ConsumerStatefulWidget {
  MapWidget({super.key});

  @override
  ConsumerState<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  LocationManager locationManager = LocationManager();
  CacheStore _cacheStore = MemCacheStore();
  final _dio = Dio();

  @override
  void initState() {
    super.initState();
    LocationManager().determinePosition();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      mapController.move(LatLng(51.351, 10.591), 6);
      ref.read(poiProvider.notifier).getPois();
      if (kIsWeb)
        setState(() {
          _cacheStore = DbCacheStore(
            databasePath: '', // ignored on web
            databaseName: 'DbCacheStore',
          );
        });
      else {
        getNormalCache();
      }
    });
  }

  Future<void> getNormalCache() async {
    Directory path = await getTemporaryDirectory();
    setState(() {
      _cacheStore = DbCacheStore(
        databasePath: path.path,
        databaseName: 'DbCacheStore',
      );
      print("Set cache store");
    });
  }

  List<Marker> getPoiMarker(List<Poi> elements) {
    return elements
        .map((e) => Marker(
              // Experimentation
              // anchorPos: AnchorPos.exactly(Anchor(40, 30)),
              point: LatLng(e.poiElement.lat!, e.poiElement.lon!),
              width: 80,
              height: 80,

              child: Icon(
                Icons.location_pin,
                size: 25,
                color: Colors.black,
              ),
            ))
        .toList();
  }

  List<CircleMarker> getCircles(List<Poi> elements) {
    return elements
        .map((e) => CircleMarker(
            // Experimentation
            // anchorPos: AnchorPos.exactly(Anchor(40, 30)),
            point: LatLng(e.poiElement.lat!, e.poiElement.lon!),
            color: Colors.red.withOpacity(0.5),
            borderColor: Colors.red,
            borderStrokeWidth: 3,
            radius: 100,
            useRadiusInMeter: true))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    List<Poi> pois = ref.watch(poiProvider);
    return Stack(
      children: [
        FlutterMap(
            mapController: mapController,
            children: [
              TileLayer(
                  maxZoom: 19,
                  minZoom: 0,
                  userAgentPackageName: "pro.obco.kifferkarte",
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  tileProvider: CachedTileProvider(
                      dio: _dio,
                      // maxStale keeps the tile cached for the given Duration and
                      // tries to revalidate the next time it gets requested
                      maxStale: const Duration(days: 30),
                      store: _cacheStore)),
              CurrentLocationLayer(
                alignPositionOnUpdate: AlignOnUpdate.once,
                alignDirectionOnUpdate: AlignOnUpdate.once,
              ),
              MarkerLayer(
                markers: getPoiMarker(pois),
              ),
              CircleLayer(circles: getCircles(pois)),
              RichAttributionWidget(
                animationConfig:
                    const ScaleRAWA(), // Or `FadeRAWA` as is default
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => launchUrl(
                        Uri.parse('https://openstreetmap.org/copyright')),
                  ),
                ],
              ),
            ],
            options: MapOptions(
              maxZoom: 19,
              minZoom: 0,
              onPositionChanged: (event, point) {
                ref.read(poiProvider.notifier).getPois();
              },
              onPointerUp: (event, point) {
                ref.read(poiProvider.notifier).getPois();
              },
            )),
        Positioned(
            bottom: 10,
            right: 10,
            child: FloatingActionButton(
              heroTag: "myLocation",
              child: const Icon(Icons.my_location),
              onPressed: () async {
                Position? position = await locationManager.determinePosition();
                if (position == null) return;
                mapController.move(
                    LatLng(position.latitude, position.longitude),
                    mapController.camera.zoom);
              },
            )),
        Positioned(
            bottom: 80,
            right: 10,
            child: FloatingActionButton(
              heroTag: "myLocation",
              child: Icon(locationManager.listeningToPosition
                  ? (Icons.smartphone)
                  : (Icons.vibration)),
              onPressed: () async {
                if (locationManager.listeningToPosition) {
                  locationManager.stopPositionCheck(ref);
                } else {
                  locationManager.startPositionCheck(ref);
                }
              },
            )),
      ],
    );
  }
}

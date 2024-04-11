import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_db_store/dio_cache_interceptor_db_store.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kifferkarte/location_manager.dart';
import 'package:kifferkarte/overpass.dart';
import 'package:kifferkarte/provider_manager.dart';
import 'package:kifferkarte/search.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:polybool/polybool.dart' as polybool;
import 'package:vibration/vibration.dart';

const double radius = 100.0;

class MapWidget extends ConsumerStatefulWidget {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  MapWidget({super.key, required this.flutterLocalNotificationsPlugin});
  @override
  ConsumerState<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  LocationManager locationManager = LocationManager();

  CacheStore _cacheStore = MemCacheStore();
  final _dio = Dio();
  List<Marker> marker = [];
  List<CircleMarker> circles = [];
  List<Polygon> polys = [];
  Timer? _debounce;
  bool rotateMap = false;
  bool followPosition = true;
  bool hasVibrator = false;
  var platformNotification;
  bool mapReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      locationManager.determinePosition();
      checkVibrator();
      if (kIsWeb)
        setState(() {
          // _cacheStore = DbCacheStore(
          //   databasePath: '', // ignored on web
          //   databaseName: 'DbCacheStore',
          // );
          _cacheStore = MemCacheStore();
        });
      else {
        getNormalCache();
      }
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      var android =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      var linux =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              LinuxFlutterLocalNotificationsPlugin>();
      if (android != null) {
        android.requestNotificationsPermission();
        setState(() {
          platformNotification = android;
        });
      }
      if (linux != null) {
        setState(() {
          platformNotification = linux;
        });
      }
    });
  }

  Future<void> checkVibrator() async {
    bool? vib = await Vibration.hasVibrator();
    if (vib == null) return;
    setState(() {
      this.hasVibrator = vib;
    });
  }

  Future<void> update() async {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () async {
      ref.read(updatingProvider.notifier).set(true);
      await ref.read(poiProvider.notifier).getPois(ref);
      await ref.read(wayProvider.notifier).getWays(ref);
      var pois = await ref.read(poiProvider.notifier).getState();
      var ways = await ref.read(wayProvider.notifier).getState();
      getPoiMarker(pois);
      getCircles(pois);
      getWays(ways);
      ref.read(updatingProvider.notifier).set(false);
    });
  }

  void getWays(List<Way> elements) {
    DateTime now = DateTime.now();
    bool clear = now.hour < 7 || now.hour >= 20;
    setState(() {
      polys += elements
          .map((e) => Polygon(
              points: e.boundaries,
              color: clear
                  ? Colors.green.withOpacity(0.5)
                  : Colors.yellow.withOpacity(0.5),
              isFilled: true))
          .toList();
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

  void getPoiMarker(List<Poi> elements) {
    setState(() {
      marker = elements
          .where((element) =>
              element.poiElement.lat != null && element.poiElement.lon != null)
          .map((e) => Marker(
                // Experimentation
                // anchorPos: AnchorPos.exactly(Anchor(40, 30)),
                point: LatLng(e.poiElement.lat!, e.poiElement.lon!),
                width: 80,
                height: 80,

                child: const Icon(
                  Icons.location_pin,
                  size: 25,
                  color: Colors.red,
                ),
              ))
          .toList();
    });
  }

  double toRadians(double degree) {
    return degree * pi / 180;
  }

  double toDegrees(double degree) {
    return degree * 180 / pi;
  }

  LatLng offset(LatLng center, double radius, double bearing) {
    double lat1 = toRadians(center.latitude);
    double lon1 = toRadians(center.longitude);
    double dByR = radius /
        6378137; // distance divided by 6378137 (radius of the earth) wgs84
    var lat =
        asin(sin(lat1) * cos(dByR) + cos(lat1) * sin(dByR) * cos(bearing));
    var lon = lon1 +
        atan2(sin(bearing) * sin(dByR) * cos(lat1),
            cos(dByR) - sin(lat1) * sin(lat));
    var offset = LatLng(toDegrees(lat), toDegrees(lon));
    return offset;
  }

  // https://github.com/bcalik/php-circle-to-polygon/blob/master/CircleToPolygon.php
  List<LatLng> circleToPolygon(
      LatLng center, double radius, int numberOfSegments) {
    List<LatLng> coordinates = [];
    for (int i = 0; i < numberOfSegments; i++) {
      coordinates.add(offset(center, radius, 2 * pi * i / numberOfSegments));
    }
    return coordinates;
  }

  void getCircles(List<Poi> elements) {
    Map<LatLng, CircleMarker> circleMarker = Map();
    List<Polygon> polys = [];
    for (Poi poi in elements) {
      if (poi.poiElement.lat == null || poi.poiElement.lon == null) continue;
      LatLng position = LatLng(poi.poiElement.lat!, poi.poiElement.lon!);
      circleMarker[position] = CircleMarker(
          // Experimentation
          // anchorPos: AnchorPos.exactly(Anchor(40, 30)),
          point: position,
          color: Colors.blue.withOpacity(0.25),
          borderColor: Colors.blue,
          borderStrokeWidth: 3,
          radius: radius,
          useRadiusInMeter: true);
    }

    Map<Poi, List<Poi>> polyMapping = new Map();
    for (Poi currentElement in elements) {
      for (Poi checkElement in elements) {
        if (currentElement.poiElement.lat == null ||
            currentElement.poiElement.lon == null ||
            checkElement.poiElement.lat == null ||
            checkElement.poiElement.lon == null) continue;
        LatLng currentPosition = LatLng(
            currentElement.poiElement.lat!, currentElement.poiElement.lon!);
        LatLng checkPosition =
            LatLng(checkElement.poiElement.lat!, checkElement.poiElement.lon!);
        Distance distance = new Distance();
        if (distance.as(LengthUnit.Meter, currentPosition, checkPosition) <=
            radius * 2) {
          bool isMapped = false;
          for (List<Poi> mappedPois in polyMapping.values) {
            if (mappedPois.contains(checkElement)) {
              isMapped = true;
            }
          }

          if (isMapped) continue;

          if (!polyMapping.containsKey(currentElement)) {
            polyMapping[currentElement] = [checkElement];
          } else {
            polyMapping[currentElement]!.add(checkElement);
          }
        }
      }
    }

    for (var outerPoly in polyMapping.entries) {
      if (outerPoly.key.poiElement.lat == null ||
          outerPoly.key.poiElement.lon == null) continue;
      LatLng position =
          LatLng(outerPoly.key.poiElement.lat!, outerPoly.key.poiElement.lon!);
      List<LatLng> points = circleToPolygon(position, radius, 32);
      polybool.Polygon united = polybool.Polygon(regions: [
        points.map((e) => polybool.Coordinate(e.latitude, e.longitude)).toList()
      ]);
      circleMarker.remove(position);
      for (int i = 0; i < outerPoly.value.length; i++) {
        LatLng innerPosition = LatLng(outerPoly.value[i].poiElement.lat!,
            outerPoly.value[i].poiElement.lon!);
        circleMarker.remove(innerPosition);
        List<LatLng> innerPoints = circleToPolygon(innerPosition, radius, 32);
        united = united.union(polybool.Polygon(regions: [
          innerPoints
              .map((e) => polybool.Coordinate(e.latitude, e.longitude))
              .toList()
        ]));
      }
      polys.add(Polygon(
          points: united.regions.first.map((e) => LatLng(e.x, e.y)).toList(),
          color: Colors.red.withOpacity(0.25),
          borderColor: Colors.red,
          borderStrokeWidth: 3,
          isFilled: true));
    }

    print(polyMapping);
    print(polys);

    setState(() {
      circles = circleMarker.values.toList();
      this.polys = polys;
      print("set newpolys");
      // circles = circleMarker.values.toList();
    });
  }

  Future<void> startPositionCheck() async {
    if (!(await locationManager.startPositionCheck(ref, () {
      update();
    }))) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Konnte aktuelle Position nicht finden. Überprüfe dass dein GPS aktiviert ist")));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool vibrate = ref.watch(vibrateProvider);
    Position? position = ref.watch(lastPositionProvider);
    bool updating = ref.watch(updatingProvider);

    return Stack(
      children: [
        FlutterMap(
            mapController: mapController,
            children: [
              TileLayer(
                  maxZoom: 19,
                  minZoom: 0,
                  userAgentPackageName: "pro.obco.kifferkarte",
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  tileProvider: CachedTileProvider(
                      dio: _dio,
                      // maxStale keeps the tile cached for the given Duration and
                      // tries to revalidate the next time it gets requested
                      maxStale: const Duration(days: 30),
                      store: _cacheStore)),
              CurrentLocationLayer(
                alignPositionOnUpdate:
                    followPosition ? AlignOnUpdate.always : AlignOnUpdate.never,
                alignDirectionOnUpdate:
                    rotateMap ? AlignOnUpdate.always : AlignOnUpdate.never,
              ),
              PolygonLayer(
                polygons: polys,
                polygonCulling: true,
              ),
              MarkerLayer(
                markers: marker,
              ),
              CircleLayer(circles: circles),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 50),
                child: RichAttributionWidget(
                  alignment: AttributionAlignment.bottomLeft,
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
              ),
            ],
            options: MapOptions(
                maxZoom: 19,
                minZoom: 0,
                onPointerUp: (event, point) {
                  update();
                },
                onMapReady: () async {
                  await startPositionCheck();
                  setState(() {
                    mapReady = true;
                  });

                  if (position != null) {
                    ref.read(poiProvider.notifier).getPois(ref);
                    mapController.move(
                        LatLng(position.latitude, position.longitude), 12);
                  }
                },
                initialCenter: LatLng(51.351, 10.591),
                initialZoom: 7)),
        if (mapReady && 15 - mapController.camera.zoom.toInt() > 0)
          Positioned(
              child: Container(
            color: Colors.white.withOpacity(0.75),
            height: 40,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Zoome an einen Ort um die Zonen zu sehen (noch ${15 - mapController.camera.zoom.toInt()} Stufen)",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
            ),
          )),
        Positioned(
            bottom: 80,
            right: 10,
            child: FloatingActionButton(
              heroTag: "myLocation",
              child:
                  Icon(followPosition ? Icons.navigation : Icons.my_location),
              onPressed: () async {
                await startPositionCheck();
                setState(() {
                  followPosition = !followPosition;
                });
                if (position == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Keine Position bekannt")));
                  return;
                } else {
                  await locationManager.checkPositionInCircle(ref, position);
                  mapController.move(
                      LatLng(position!.latitude, position!.longitude), 19);
                  update();
                }
              },
            )),
        Positioned(
            top: 80,
            left: 10,
            child: FloatingActionButton(
              heroTag: "rotateMap",
              child: Icon(rotateMap ? (Icons.crop_rotate) : (Icons.map)),
              onPressed: () {
                setState(() {
                  rotateMap = !rotateMap;
                });
              },
            )),
        if (hasVibrator)
          Positioned(
              bottom: 150,
              right: 10,
              child: FloatingActionButton(
                heroTag: "vibrate",
                child: Icon(vibrate ? (Icons.vibration) : (Icons.smartphone)),
                onPressed: () async {
                  ref.read(vibrateProvider.notifier).set(!vibrate);
                },
              )),
        Positioned(
            top: 10,
            right: 10,
            child: FloatingActionButton(
              heroTag: "zoomUp",
              child: const Icon(Icons.add),
              onPressed: () {
                mapController.move(
                    mapController.camera.center, mapController.camera.zoom + 1);
                update();
              },
            )),
        Positioned(
            top: 80,
            right: 10,
            child: FloatingActionButton(
              heroTag: "zoomDown",
              child: const Icon(Icons.remove),
              onPressed: () {
                mapController.move(
                    mapController.camera.center, mapController.camera.zoom - 1);
                update();
              },
            )),
        Positioned(
            top: 10,
            left: 10,
            child: FloatingActionButton(
              heroTag: "Search",
              child: const Icon(Icons.search),
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => SearchView(
                    locationManager: locationManager,
                  ),
                ));
                update();
              },
            )),
        if (updating)
          Container(
            color: Colors.white.withOpacity(0.25),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
      ],
    );
  }
}

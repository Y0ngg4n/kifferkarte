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
import 'package:kifferkarte/lockscreen.dart';
import 'package:kifferkarte/overpass.dart';
import 'package:kifferkarte/provider_manager.dart';
import 'package:kifferkarte/search.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:polybool/polybool.dart' as polybool;
import 'package:vibration/vibration.dart';
import 'package:flutter_map_supercluster/flutter_map_supercluster.dart';

const double radius = 100.0;

class ClusterResult {
  polybool.Polygon cluster;
  List<Poi> unvisited;

  ClusterResult({required this.cluster, required this.unvisited});
}

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
    _debounce = Timer(const Duration(milliseconds: 2000), () async {
      ref.read(updatingProvider.notifier).set(true);
      await ref.read(poiProvider.notifier).getPois(ref);
      await ref.read(wayProvider.notifier).getWays(ref);
      var pois = await ref.read(poiProvider.notifier).getState();
      var ways = await ref.read(wayProvider.notifier).getState();
      getPoiMarker(pois);
      getCircles(pois);
      getWays(ways);
      getBuildings();
      ref.read(poiProvider.notifier).set(Overpass.mapBuildingsToPoi(
          ref.read(buildingProvider.notifier).getState(),
          ref.read(poiProvider.notifier).getState()));
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

  void getBuildings() async {
    List<Polygon> polys = List.of(this.polys);
    await ref.read(buildingProvider.notifier).getBuildingBoundaries(ref);
    List<Poi> pois = ref.read(poiProvider.notifier).getState();
    List<Building> buildings = ref.read(buildingProvider.notifier).getState();
    for (Poi poi in pois) {
      for (Building building in buildings) {
        bool isSelected = poi != null &&
            poi.building != null &&
            poi.building!.id == building.id;
        polys.add(Polygon(
            points: building.boundaries,
            isFilled: isSelected,
            color: Color.fromRGBO(Colors.orangeAccent.red,
                Colors.orangeAccent.green, Colors.orangeAccent.blue, 0.15),
            borderColor: Colors.orange,
            borderStrokeWidth: isSelected ? 2 : 0));
      }
    }
    setState(() {
      this.polys = polys;
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

                child: Icon(
                  Icons.location_pin,
                  size: 25,
                  color: getPoiColor(e),
                ),
              ))
          .toList();
      circles = elements
          .where((element) =>
              element.poiElement.lat != null && element.poiElement.lon != null)
          .map((e) => CircleMarker(
                radius: 3,
                // Experimentation
                // anchorPos: AnchorPos.exactly(Anchor(40, 30)),
                point: LatLng(e.poiElement.lat!, e.poiElement.lon!),
                color: getPoiColor(e),
              ))
          .toList();
    });
  }

  Color getPoiColor(Poi poi) {
    Color color = Colors.red;
    if (poi.poiElement.tags == null) return color;
    print("Tags");
    print(poi.poiElement.tags);
    if (poi.poiElement.tags!.containsKey("leisure") &&
        poi.poiElement.tags!.containsValue("playground")) {
      color = Colors.black;
    } else if ((poi.poiElement.tags!.containsKey("amenity") &&
            poi.poiElement.tags!["amenity"] == "kindergarten") ||
        (poi.poiElement.tags!.containsKey("building") &&
            poi.poiElement.tags!["building"] == "kindergarten") ||
        (poi.poiElement.tags!.containsKey("amenity") &&
            poi.poiElement.tags!["building"] == "childcare") ||
        (poi.poiElement.tags!.containsKey("social_facility"))) {
      color = Colors.pink;
    } else if (poi.poiElement.tags!.containsKey("amenity") &&
        poi.poiElement.tags!["amenity"] == "school") {
      color = Colors.blue;
    } else if (poi.poiElement.tags!.containsKey("leisure")) {
      color = Colors.green;
    }

    return color;
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
    List<Polygon> polys = [];
    for (Poi poi in elements) {
      if (poi.poiElement.lat == null || poi.poiElement.lon == null) continue;
      LatLng position = LatLng(poi.poiElement.lat!, poi.poiElement.lon!);
      List<LatLng> points = circleToPolygon(position, radius, 32);
      polys.add(Polygon(
          points: points, isFilled: true, color: Colors.red.withOpacity(0.25)));
    }

    setState(() {
      this.polys = polys;
    });
  }

  Future<void> startPositionCheck() async {
    if (!(await locationManager.startPositionCheck(ref, () async {
      print("startPositionCheck");
      await update();
      Position? position = ref.read(lastPositionProvider.notifier).getState();
      if (position != null) {
        locationManager.checkPositionInCircle(ref, position);
      }
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
                    TextSourceAttribution(
                      'Nomatim',
                      onTap: () => launchUrl(Uri.parse(
                          'https://operations.osmfoundation.org/policies/nominatim/')),
                    ),
                    TextSourceAttribution(
                      'Overpass',
                      onTap: () =>
                          launchUrl(Uri.parse('https://overpass-api.de/')),
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
                  Timer.new(
                    Duration(seconds: 10),
                    () async {
                      await update();
                      Position? position =
                          ref.read(lastPositionProvider.notifier).getState();
                      if (position != null) {
                        mapController.move(
                            LatLng(position.latitude, position.longitude), 19);
                        locationManager.checkPositionInCircle(ref, position);
                      }
                    },
                  );
                },
                initialCenter: LatLng(51.351, 10.591),
                initialZoom: 7)),
        if (mapReady && 13 - mapController.camera.zoom.toInt() > 0)
          Positioned(
              child: Container(
            color: Colors.white.withOpacity(0.75),
            height: 50,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(50, 8, 50, 8),
              child: Text(
                "Zoome an einen Ort um die Zonen zu sehen\n(noch ${13 - mapController.camera.zoom.toInt()} Stufen)",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
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

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Folgen deiner Position " +
                        (followPosition ? "aktiviert" : "deaktiviert"))));
                if (position == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Keine Position bekannt")));
                  return;
                } else {
                  update();
                  await locationManager.checkPositionInCircle(ref, position);
                  mapController.move(
                      LatLng(position!.latitude, position!.longitude), 19);
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Rotation der Karte " +
                          (rotateMap ? "deaktiviert" : "aktiviert"))));
                  rotateMap = !rotateMap;
                });
              },
            )),
        Positioned(
            top: 150,
            left: 10,
            child: FloatingActionButton(
              heroTag: "lock",
              child: Icon(Icons.lock),
              onPressed: () {
                Navigator.of(context).push(DialogRoute(
                  context: context,
                  builder: (context) {
                    return Lockscreen();
                  },
                ));
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Vibration " +
                          (vibrate ? "deaktiviert" : "aktiviert"))));
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

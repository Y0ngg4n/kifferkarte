import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:kifferkarte/nomatim.dart';
import 'package:kifferkarte/poi_manager.dart';
import 'package:latlong2/latlong.dart';
import 'package:point_in_polygon/point_in_polygon.dart';

String overpassUrl = "https://overpass-api.de/api/interpreter";

class Overpass {
  static CacheOptions getCacheOptions(CacheStore cacheStore) {
    return CacheOptions(
      store: cacheStore,
      allowPostMethod: true,
      hitCacheOnErrorExcept: [401, 403],
      maxStale: const Duration(days: 7),
    );
  }

  static List<Poi> mapBuildingsToPoi(List<Building> buildings, List<Poi> pois) {
    for (Building building in buildings) {
      List<Point> bounds = building.boundaries
          .map((e) => Point(y: e.latitude, x: e.longitude))
          .toList();
      for (Poi poi in pois) {
        if (poi.poiElement.lat != null &&
            poi.poiElement.lon != null &&
            Poly.isPointInPolygon(
                Point(y: poi.poiElement.lat!, x: poi.poiElement.lon!),
                bounds)) {
          print("its in poly");
          poi.building = building;
        }
      }
    }
    return pois;
  }

  static Future<OverpassResponse?> cachedPostRequest(
      CacheStore? cacheStore, body) async {
    if (cacheStore != null) {
      final dio = Dio()
        ..interceptors
            .add(DioCacheInterceptor(options: getCacheOptions(cacheStore)));
      var response = await dio.post(overpassUrl,
          options: Options(headers: {"charset": "utf-8"}), data: body);
      if (response.statusCode == 200) {
        try {
          OverpassResponse overpassResponse =
              OverpassResponse.fromJson(response.data);
          return overpassResponse;
        } catch (e) {
          print(e);
        }
        return null;
      } else {
        return null;
      }
    } else {
      http.Response response = await http.post(Uri.parse(overpassUrl),
          headers: {"charset": "utf-8"}, body: body);
      if (response.statusCode == 200) {
        return OverpassResponse.fromJson(
            jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        return null;
      }
    }
  }

  static Future<OverpassResponse?> getAllPoiInRadius(
      int radius, LatLng position, CacheStore? cacheStore) async {
    String body = "[out:json][timeout:20][maxsize:536870912];";
    body += "node(around:$radius,${position.latitude}, ${position.longitude});";
    body += "out;";
    http.Response response = await http.post(Uri.parse(overpassUrl),
        headers: {"charset": "utf-8"}, body: body);
    if (response.statusCode == 200) {
      return OverpassResponse.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      return null;
    }
  }

  static Future<OverpassResponse?> getKifferPoiInBounds(
      LatLngBounds? latLngBounds, CacheStore? cacheStore) async {
    if (latLngBounds == null) return null;

    final List<String> tags = [
      "[leisure=playground]",
      "[amenity=school]",
      "[amenity=kindergarten]",
      "[building=kindergarten]",
      "[community_centre=youth_centre]",
      "[amenity=childcare]",
      "[name~'Jugendherberge']",
      "[amenity=social_facility][\"social_facility:for\"=\"child\"]",
      "[amenity=social_facility][\"social_facility:for\"=\"childcare\"]",
      "[amenity=social_facility][\"social_facility:for\"=\"juvenile\"]",
      "[leisure=pitch]",
      "[leisure=sports_hall]",
      "[leisure=sports_centre]",
      "[leisure=horse_riding]",
      "[leisure=swimming_pool]",
      "[leisure=track]",
      "[leisure=stadium]",
      "[leisure=water_park]",
      "[leisure=golf_course]"
    ];
    Distance distance = const Distance();
    print(
        "${latLngBounds.south},${latLngBounds.west},${latLngBounds.north},${latLngBounds.east}");
    LatLng northWest = latLngBounds.northWest;
    LatLng southEast = latLngBounds.southEast;
    northWest = distance.offset(northWest, 100, 315);
    southEast = distance.offset(southEast, 100, 135);
    latLngBounds = LatLngBounds(northWest, southEast);
    print(
        "${latLngBounds.south},${latLngBounds.west},${latLngBounds.north},${latLngBounds.east}");
    String body = "[out:json][timeout:20][maxsize:536870912];\(";
    // Generate Overpass queries for each tag
    tags.forEach((value) {
      body += '''
      nw${value}(${latLngBounds!.south},${latLngBounds.west},${latLngBounds.north},${latLngBounds.east});
      ''';
    });
    body += "\);(._;>;);out;";
    print(body);
    return await cachedPostRequest(cacheStore, body);
  }

  static Future<OverpassResponse?> getKifferPoiInRadius(
      LatLng position, int radius, CacheStore? cacheStore) async {
    final List<String> tags = [
      "[leisure=playground]",
      "[amenity=school]",
      "[amenity=kindergarten]",
      "[building=kindergarten]",
      "[community_centre=youth_centre]",
      "[amenity=childcare]",
      "[name~'Jugendherberge']",
      "[amenity=social_facility][\"social_facility:for\"=\"child\"]",
      "[amenity=social_facility][\"social_facility:for\"=\"childcare\"]",
      "[amenity=social_facility][\"social_facility:for\"=\"juvenile\"]",
      "[leisure=pitch]",
      "[leisure=sports_hall]",
      "[leisure=sports_centre]",
      "[leisure=horse_riding]",
      "[leisure=swimming_pool]",
      "[leisure=track]",
      "[leisure=stadium]",
      "[leisure=water_park]",
      "[leisure=golf_course]"
    ];
    String body = "[out:json][timeout:20][maxsize:536870912];\(";
    // Generate Overpass queries for each tag
    tags.forEach((value) {
      body += '''
      nw${value}(around:${radius},${position.latitude},${position.longitude});
      ''';
    });
    body += "\);(._;>;);out;";
    print(body);
    return await cachedPostRequest(cacheStore, body);
  }

  static Future<OverpassResponse?> getPedestrianWaysBoundariesInBounds(
      LatLngBounds? latLngBounds, CacheStore? cacheStore) async {
    if (latLngBounds == null) return null;
    String body = "[out:json][timeout:20][maxsize:536870912];\n";
    body +=
        "way[highway=pedestrian](${latLngBounds.south}, ${latLngBounds.west},${latLngBounds.north}, ${latLngBounds.east});";
    body += "(._;>;);out body;";
    return await cachedPostRequest(cacheStore, body);
  }

  static Future<OverpassResponse?> getPedestrianWaysBoundariesInRadius(
      LatLng? position, int radius, CacheStore? cacheStore) async {
    if (position == null) return null;
    String body = "[out:json][timeout:20][maxsize:536870912];\n";
    body +=
        "way[highway=pedestrian](around:${radius},${position.latitude},${position.longitude});";
    body += "(._;>;);out body;";
    return await cachedPostRequest(cacheStore, body);
  }

  static Future<OverpassResponse?> getBuildingBoundariesInBounds(
      LatLngBounds? latLngBounds,
      LatLng position,
      CacheStore? cacheStore) async {
    if (latLngBounds == null) return null;
    String body = "[out:json][timeout:20][maxsize:536870912];\n";
    body +=
        "way[\"building\"](${latLngBounds.south}, ${latLngBounds.west},${latLngBounds.north}, ${latLngBounds.east});";
    body += "(._;>;);out body;";
    return await cachedPostRequest(cacheStore, body);
  }
}

class Poi {
  PoiElement poiElement;
  Building? building;
  NomatimLookupElement? nomatimLookupElement;

  Poi(this.poiElement);
}

class Building {
  int id;
  List<LatLng> boundaries;

  Building(this.id, this.boundaries);
}

class Way {
  int id;
  List<LatLng> boundaries;

  Way(this.id, this.boundaries);
}

class OverpassResponse {
  double version;
  String generator;
  List<PoiElement> elements;
  List<Map<String, String>> tags;

  OverpassResponse(
      {required this.version,
      required this.generator,
      required this.elements,
      required this.tags});

  factory OverpassResponse.fromJson(Map<String, dynamic> json) {
    return OverpassResponse(
        version: json['version'],
        generator: json['generator'],
        elements: json['elements']
            .map((e) => PoiElement.fromJson(e))
            .toList()
            .cast<PoiElement>(),
        tags: json['tags'] != null
            ? json['tags'].toList().cast < Map<String, String>()
            : []);
  }
}

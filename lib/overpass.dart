import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import 'package:kifferkarte/poi_manager.dart';
import 'package:kifferkarte/location_manager.dart';

String overpassUrl = "https://overpass-api.de/api/interpreter";

class Overpass {
  static Future<OverpassResponse?> getAllPoiInRadius(
      int radius, LatLng position) async {
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
      LatLngBounds? latLngBounds) async {
    if (latLngBounds == null) return null;

    final List<String> tags = [
      "[leisure=playground]",
      "[amenity=school]",
      "[amenity=kindergarten]",
      "[building=kindergarten]",
      "[community_centre=youth_centre]",
      "[amenity=childcare]",
      "[name~'Jugendherberge']",
      "[amenity=social_facility][childcare=yes]",
      "[amenity=social_facility][juvenile=yes]",
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
      node$value(${latLngBounds.south},${latLngBounds.west},${latLngBounds.north},${latLngBounds.east});
      ''';
    });
    body += "\);out;";
    print(body);
    http.Response response = await http.post(Uri.parse(overpassUrl),
        headers: {"charset": "utf-8"}, body: body);
    if (response.statusCode == 200) {
      return OverpassResponse.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      return null;
    }
  }

  static Future<OverpassResponse?> getBuildingBoundariesInBounds(
      LatLngBounds? latLngBounds, LatLng position) async {
    if (latLngBounds == null) return null;
    String body = "[out:json][timeout:20][maxsize:536870912];\n";
    body +=
        "way[\"building\"](${latLngBounds.south}, ${latLngBounds.west},${latLngBounds.north}, ${latLngBounds.east});";
    body += "(._;>;);out body;";
    http.Response response = await http.post(Uri.parse(overpassUrl),
        headers: {"charset": "utf-8"}, body: body);
    if (response.statusCode == 200) {
      return OverpassResponse.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      print(response.body);
      return null;
    }
  }
}

class Poi {
  PoiElement poiElement;
  Building? building;

  Poi(this.poiElement);
}

class Building {
  int id;
  List<LatLng> boundaries;

  Building(this.id, this.boundaries);
}

class OverpassResponse {
  double version;
  String generator;
  Map<String, dynamic> osm3s;
  List<PoiElement> elements;

  OverpassResponse(
      {required this.version,
      required this.generator,
      required this.osm3s,
      required this.elements});

  factory OverpassResponse.fromJson(Map<String, dynamic> json) {
    return OverpassResponse(
        version: json['version'],
        generator: json['generator'],
        osm3s: json['osm3s'],
        elements: json['elements']
            .map((e) => PoiElement.fromJson(e))
            .toList()
            .cast<PoiElement>());
  }
}

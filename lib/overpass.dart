import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:kifferkarte/nomatim.dart';
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
    Distance distance = Distance();
    print(
        "${latLngBounds!.south},${latLngBounds.west},${latLngBounds.north},${latLngBounds.east}");
    LatLng northWest = latLngBounds.northWest;
    LatLng southEast = latLngBounds.southEast;
    northWest = distance.offset(northWest, 100, 315);
    southEast = distance.offset(southEast, 100, 135);
    latLngBounds = LatLngBounds(northWest, southEast);
    print(
        "${latLngBounds!.south},${latLngBounds.west},${latLngBounds.north},${latLngBounds.east}");
    String body = "[out:json][timeout:20][maxsize:536870912];\(";
    // Generate Overpass queries for each tag
    tags.forEach((value) {
      body += '''
      nw${value}(${latLngBounds!.south},${latLngBounds.west},${latLngBounds.north},${latLngBounds.east});
      ''';
    });
    body += "\);(._;>;);out;";
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

  static Future<OverpassResponse?> getKifferPoiInRadius(
      LatLng position, int radius) async {
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
    http.Response response = await http.post(Uri.parse(overpassUrl),
        headers: {"charset": "utf-8"}, body: body);
    if (response.statusCode == 200) {
      return OverpassResponse.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      return null;
    }
  }

  static Future<OverpassResponse?> getPedestrianWaysBoundariesInBounds(
      LatLngBounds? latLngBounds) async {
    if (latLngBounds == null) return null;
    String body = "[out:json][timeout:20][maxsize:536870912];\n";
    body +=
        "way[highway=pedestrian](${latLngBounds.south}, ${latLngBounds.west},${latLngBounds.north}, ${latLngBounds.east});";
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

  static Future<OverpassResponse?> getPedestrianWaysBoundariesInRadius(
      LatLng? position, int radius) async {
    if (position == null) return null;
    String body = "[out:json][timeout:20][maxsize:536870912];\n";
    body +=
        "way[highway=pedestrian](around:${radius},${position.latitude},${position.longitude});";
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

  OverpassResponse(
      {required this.version, required this.generator, required this.elements});

  factory OverpassResponse.fromJson(Map<String, dynamic> json) {
    return OverpassResponse(
        version: json['version'],
        generator: json['generator'],
        elements: json['elements']
            .map((e) => PoiElement.fromJson(e))
            .toList()
            .cast<PoiElement>());
  }
}

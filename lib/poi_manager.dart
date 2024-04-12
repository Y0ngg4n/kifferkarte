import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PoiElement {
  String type;
  int id;
  double? lat;
  double? lon;
  Map<String, String>? tags;
  List<int>? nodes;

  PoiElement(
      {required this.type,
      required this.id,
      required this.lat,
      required this.lon,
      required this.tags,
      this.nodes});

  factory PoiElement.fromJson(Map<String, dynamic> json) {
    return PoiElement(
        type: json['type'],
        id: json['id'],
        lat: json['lat'],
        lon: json['lon'],
        tags: json['tags'] != null
            ? Map<String, String>.from(json['tags'])
            : null,
        nodes: json['nodes'] != null ? List<int>.from(json['nodes']) : null);
  }
}

class PoiManager {}

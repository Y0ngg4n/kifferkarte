import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:kifferkarte/overpass.dart';
import 'package:latlong2/latlong.dart';

class SearchElement {
  int place_id;
  String licence;
  String osm_type;
  int osm_id;
  List<dynamic> boundingbox;
  String lat;
  String lon;
  String diplay_name;
  int place_rank;
  String category;
  String type;
  double importance;
  String? icon;
  double? distanceInMeter;

  SearchElement(
      {required this.place_id,
      required this.licence,
      required this.osm_type,
      required this.osm_id,
      required this.boundingbox,
      required this.lat,
      required this.lon,
      required this.diplay_name,
      required this.place_rank,
      required this.category,
      required this.type,
      required this.importance,
      required this.icon});

  factory SearchElement.fromJson(Map<String, dynamic> json) {
    return SearchElement(
      place_id: json['place_id'],
      licence: json['licence'],
      osm_type: json['osm_type'],
      osm_id: json['osm_id'],
      boundingbox: json['boundingbox'],
      lat: json['lat'],
      lon: json['lon'],
      diplay_name: json['display_name'],
      place_rank: json['place_rank'],
      category: json['category'],
      type: json['type'],
      importance: json['importance'],
      icon: json['icon'],
    );
  }
}

class NomatimResponse {
  List<SearchElement> elements;

  NomatimResponse({required this.elements});

  factory NomatimResponse.fromJson(List<dynamic> json) {
    return NomatimResponse(
        elements: json
            .map((e) => SearchElement.fromJson(e))
            .toList()
            .cast<SearchElement>());
  }
}

class NomatimLookupElementAddress {
  String tourism;
  String road;
  String suburb;
  String city;
  String state;
  String postcode;
  String country;
  String countryCode;

  NomatimLookupElementAddress({
    required this.tourism,
    required this.road,
    required this.suburb,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
    required this.countryCode,
  });

  factory NomatimLookupElementAddress.fromJson(Map<String, dynamic> json) {
    return NomatimLookupElementAddress(
      tourism: json['tourism'],
      road: json['road'],
      suburb: json['suburb'],
      city: json['city'],
      state: json['state'],
      postcode: json['postcode'],
      country: json['country'],
      countryCode: json['country_code'],
    );
  }
}

class NomatimLookupElement {
  int placeId;
  String licence;
  String osmType;
  int osmId;
  List<double> boundingbox;
  double lat;
  double lon;
  String displayName;
  String classValue;
  String type;
  double importance;
  Map<String, String> address;

  NomatimLookupElement({
    required this.placeId,
    required this.licence,
    required this.osmType,
    required this.osmId,
    required this.boundingbox,
    required this.lat,
    required this.lon,
    required this.displayName,
    required this.classValue,
    required this.type,
    required this.importance,
    required this.address,
  });

  factory NomatimLookupElement.fromJson(Map<String, dynamic> json) {
    return NomatimLookupElement(
      placeId: json['place_id'],
      licence: json['licence'],
      osmType: json['osm_type'],
      osmId: json['osm_id'],
      boundingbox:
          json['boundingbox'].map<double>((e) => double.parse(e)).toList(),
      lat: double.parse(json['lat']),
      lon: double.parse(json['lon']),
      displayName: json['display_name'],
      classValue: json['class'],
      type: json['type'],
      importance: double.parse(json['importance'].toString()),
      address: Map<String, String>.from(json['address']),
    );
  }
}

class Nomatim {
  static Future<NomatimResponse?> searchNomatim(
      Position? position, searchText) async {
    http.Response response = await http.get(
        Uri.parse(
          "https://nominatim.openstreetmap.org/search.php?q=$searchText&format=jsonv2",
        ),
        headers: {"charset": "utf-8"});
    if (response.statusCode == 200) {
      NomatimResponse nomatimResponse =
          NomatimResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      if (position == null) return nomatimResponse;
      if (nomatimResponse.elements.length > 1) {
        nomatimResponse.elements.sort(
          (a, b) {
            Distance distance = const Distance();
            double ma = distance.as(
                LengthUnit.Meter,
                LatLng(position.latitude, position.longitude),
                LatLng(double.parse(a.lat), double.parse(a.lon)));
            a.distanceInMeter = ma;
            double mb = distance.as(
                LengthUnit.Meter,
                LatLng(position.latitude, position.longitude),
                LatLng(double.parse(b.lat), double.parse(b.lon)));
            b.distanceInMeter = mb;
            return ma.compareTo(mb);
          },
        );
      } else {
        Distance distance = const Distance();
        SearchElement searchElement = nomatimResponse.elements.first;
        double ma = distance.as(
            LengthUnit.Meter,
            LatLng(position.latitude, position.longitude),
            LatLng(double.parse(searchElement.lat),
                double.parse(searchElement.lon)));
        searchElement.distanceInMeter = ma;
      }
      return nomatimResponse;
    } else {
      return null;
    }
  }

  static Future<List<NomatimLookupElement>> getNominatimLookupElements(
      List<int> osmIds) async {
    const String baseUrl = 'https://nominatim.openstreetmap.org/lookup';

    List<NomatimLookupElement> elements = [];

    for (int i = 0; i < osmIds.length; i += 50) {
      List<int> sublist =
          osmIds.sublist(i, i + 50 > osmIds.length ? osmIds.length : i + 50);

      Uri url = Uri.parse(
          '$baseUrl?format=json&osm_ids=${sublist.map((id) => 'N$id').join(',')}');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));

        for (var json in jsonList) {
          elements.add(NomatimLookupElement.fromJson(json));
        }
      }
    }

    return elements;
  }

  static List<Poi> mapLookupElementToPoi(
      List<NomatimLookupElement> nomatimElements, List<Poi> pois) {
    for (NomatimLookupElement nomatimLookupElement in nomatimElements) {
      Poi poi = pois.firstWhere(
          (element) => element.poiElement.id == nomatimLookupElement.osmId);
      poi.nomatimLookupElement = nomatimLookupElement;
    }
    return pois;
  }
}

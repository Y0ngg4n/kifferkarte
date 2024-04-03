import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kifferkarte/location_manager.dart';
import 'package:kifferkarte/overpass.dart';
import 'package:kifferkarte/poi_manager.dart';
import 'package:latlong2/latlong.dart';

MapController mapController = MapController();

class PoiNotifier extends StateNotifier<List<Poi>> {
  PoiNotifier() : super([]);

  void init() {
    state = [];
  }

  Future<void> getPois() async {
    if (mapController.camera.zoom < 13) {
      state = [];
      return;
    }
    OverpassResponse? overpassResponse =
        await Overpass.getKifferPoiInBounds(mapController.camera.visibleBounds);
    if (overpassResponse != null) {
      List<Poi> pois = [];
      List<int> osmIds = [];
      for (PoiElement element in overpassResponse.elements) {
        pois.add(Poi(element));
        osmIds.add(element.id);
      }
      state = pois;
    } else {
      print("null");
    }
  }

  void set(List<Poi> pois) {
    state = pois;
  }

  getState() => state;
}

class InCircleNotifier extends StateNotifier<bool> {
  InCircleNotifier() : super(false);

  void init() {
    state = false;
  }

  void set(bool value) {
    state = value;
  }

  getState() => state;
}

final poiProvider = StateNotifierProvider<PoiNotifier, List<Poi>>((ref) {
  return PoiNotifier();
});

final inCircleProvider = StateNotifierProvider<InCircleNotifier, bool>((ref) {
  return InCircleNotifier();
});

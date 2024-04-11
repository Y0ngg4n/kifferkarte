import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kifferkarte/location_manager.dart';
import 'package:kifferkarte/map.dart';
import 'package:kifferkarte/overpass.dart';
import 'package:kifferkarte/poi_manager.dart';
import 'package:latlong2/latlong.dart';

MapController mapController = MapController();

class PoiNotifier extends StateNotifier<List<Poi>> {
  PoiNotifier() : super([]);

  void init() {
    state = [];
  }

  Future<void> getPois(WidgetRef ref) async {
    OverpassResponse? overpassResponse;
    try {
      if (mapController.camera.zoom < 13) {
        Position? position = ref.read(lastPositionProvider.notifier).getState();
        if (position != null) {
          overpassResponse = await Overpass.getKifferPoiInRadius(
              LatLng(position.latitude, position.longitude),
              radius.toInt() * 3);
        } else {
          overpassResponse = await Overpass.getKifferPoiInRadius(
              mapController.camera.center, radius.toInt() * 3);
        }
      } else {
        overpassResponse = await Overpass.getKifferPoiInBounds(
            mapController.camera.visibleBounds);
      }
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
    } catch (Exception) {
      ScaffoldMessenger.of(ref.context).showSnackBar(SnackBar(
          content: Text(
              "Konnte die Overpass API nicht erreichen. Überprüfe deine Internetverbindung oder versuche es zu einem späteren Zeitpunkt erneut")));
    }
  }

  void set(List<Poi> pois) {
    state = pois;
  }

  getState() => state;
}

class WayNotifier extends StateNotifier<List<Way>> {
  WayNotifier() : super([]);

  void init() {
    state = [];
  }

  Future<void> getWays(WidgetRef ref) async {
    OverpassResponse? overpassResponse;
    try {
      if (mapController.camera.zoom < 13) {
        Position? position = ref.read(lastPositionProvider.notifier).getState();
        if (position != null) {
          overpassResponse = await Overpass.getPedestrianWaysBoundariesInRadius(
              LatLng(position.latitude, position.longitude),
              radius.toInt() * 3);
        } else {
          overpassResponse = await Overpass.getPedestrianWaysBoundariesInRadius(
              mapController.camera.center, radius.toInt() * 3);
        }
      } else {
        overpassResponse = await Overpass.getPedestrianWaysBoundariesInBounds(
            mapController.camera.visibleBounds);
      }
      if (overpassResponse != null) {
        List<Way> ways = [];
        for (PoiElement building in overpassResponse.elements
            .where((element) => element.type == "way")) {
          List<LatLng> bounds = [];
          if (building.nodes != null) {
            for (int node in building.nodes!) {
              bounds.addAll(overpassResponse.elements
                  .where((element) => element.id == node)
                  .map((e) => LatLng(e.lat!, e.lon!))
                  .toList());
            }
          }
          ways.add(Way(building.id, bounds));
        }
        state = ways;
      }
    } catch (Exception) {
      ScaffoldMessenger.of(ref.context).showSnackBar(SnackBar(
          content: Text(
              "Konnte die Overpass API nicht erreichen. Überprüfe deine Internetverbindung oder versuche es zu einem späteren Zeitpunkt erneut")));
    }
  }

  void set(List<Way> ways) {
    state = ways;
  }

  getState() => state;
}

class InCircleNotifier extends StateNotifier<bool> {
  InCircleNotifier() : super(true);

  void init() {
    state = false;
  }

  void set(bool value) {
    state = value;
  }

  getState() => state;
}

class InWayNotifier extends StateNotifier<bool> {
  InWayNotifier() : super(true);

  void init() {
    state = false;
  }

  void set(bool value) {
    state = value;
  }

  getState() => state;
}

class VibrateNotifier extends StateNotifier<bool> {
  VibrateNotifier() : super(false);

  void init() {
    state = false;
  }

  void set(bool value) {
    state = value;
  }

  getState() => state;
}

class UpdatingNotifier extends StateNotifier<bool> {
  UpdatingNotifier() : super(false);

  void init() {
    state = false;
  }

  void set(bool value) {
    state = value;
  }

  getState() => state;
}

class LastPositionNotifier extends StateNotifier<Position?> {
  LastPositionNotifier() : super(null);

  void init() {
    state = null;
  }

  void set(Position value) {
    state = value;
  }

  getState() => state;
}

final poiProvider = StateNotifierProvider<PoiNotifier, List<Poi>>((ref) {
  return PoiNotifier();
});

final wayProvider = StateNotifierProvider<WayNotifier, List<Way>>((ref) {
  return WayNotifier();
});
final inCircleProvider = StateNotifierProvider<InCircleNotifier, bool>((ref) {
  return InCircleNotifier();
});

final inWayProvider = StateNotifierProvider<InWayNotifier, bool>((ref) {
  return InWayNotifier();
});

final lastPositionProvider =
    StateNotifierProvider<LastPositionNotifier, Position?>((ref) {
  return LastPositionNotifier();
});

final vibrateProvider = StateNotifierProvider<VibrateNotifier, bool>((ref) {
  return VibrateNotifier();
});

final updatingProvider = StateNotifierProvider<UpdatingNotifier, bool>((ref) {
  return UpdatingNotifier();
});

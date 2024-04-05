import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kifferkarte/overpass.dart';
import 'package:kifferkarte/provider_manager.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibration/vibration.dart';

class LocationManager {
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool listeningToPosition = false;
  Position? lastPosition;

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position?> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (kIsWeb) {
        print("Location on web");
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            // Permissions are denied, next time you could try
            // requesting permissions again (this is also where
            // Android's shouldShowRequestPermissionRationale
            // returned true. According to Android guidelines
            // your App should show an explanatory UI now
            print('Location permissions are denied');
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied) {
              print('Location permissions are denied');
              permission = await Geolocator.requestPermission();
              return null;
            }
          }
        }

        if (permission == LocationPermission.deniedForever) {
          // Permissions are denied forever, handle appropriately.
          print(
              'Location permissions are permanently denied, we cannot request permissions.');
          return null;
        } else {
          print("Permissions should be fine");
        }

        // When we reach here, permissions are granted and we can
        // continue accessing the position of the device.
        Position currentPosition = await Geolocator.getCurrentPosition();
        lastPosition = currentPosition;
        print("Got location");
        return currentPosition;
      }
      if (!serviceEnabled) {
        // Location services are not enabled don't continue
        // accessing the position and request users of the
        // App to enable the location services.
        print('Location services are disabled.');
        Geolocator.openLocationSettings();

        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            // Permissions are denied, next time you could try
            // requesting permissions again (this is also where
            // Android's shouldShowRequestPermissionRationale
            // returned true. According to Android guidelines
            // your App should show an explanatory UI now
            print('Location permissions are denied');
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied) {
              print('Location permissions are denied');
              permission = await Geolocator.requestPermission();
              return null;
            }
          }
        }

        if (permission == LocationPermission.deniedForever) {
          // Permissions are denied forever, handle appropriately.
          print(
              'Location permissions are permanently denied, we cannot request permissions.');
          return null;
        }

        // When we reach here, permissions are granted and we can
        // continue accessing the position of the device.
        var currentPosition = await Geolocator.getCurrentPosition();
        lastPosition = currentPosition;
        return currentPosition;
      } else {
        print("No location services enabled");
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> startPositionCheck(WidgetRef ref) async {
    _positionStreamSubscription?.cancel();
    var stream = _geolocatorPlatform.getPositionStream();
    _positionStreamSubscription = stream.listen((event) {
      checkPositionInCircle(ref, event);
    });
    listeningToPosition = true;
  }

  void stopPositionCheck(WidgetRef ref) async {
    _positionStreamSubscription?.cancel();
    listeningToPosition = false;
  }

  Future<void> checkPositionInCircle(WidgetRef ref, Position? position) async {
    if (position == null) return;
    List<Poi> pois = ref.watch(poiProvider);
    Distance distance = const Distance();
    bool inCircle = false;
    for (Poi poi in pois) {
      if (poi.poiElement.lat != null &&
          poi.poiElement.lon != null &&
          distance.as(
                  LengthUnit.Meter,
                  LatLng(position.latitude, position.longitude),
                  LatLng(poi.poiElement.lat!, poi.poiElement.lon!)) <
              100) {
        inCircle = true;
      }
    }
    bool currentInCircleState = ref.read(inCircleProvider);
    if (currentInCircleState != inCircle) {
      if (inCircle) {
        vibrate();
        await Future.delayed(const Duration(seconds: 1));
        vibrate();
      } else {
        vibrate();
      }
    }
  }

  Future<void> vibrate() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != null && hasVibrator) {
      Vibration.vibrate();
    }
  }
}

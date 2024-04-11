import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kifferkarte/map.dart';
import 'package:kifferkarte/overpass.dart';
import 'package:kifferkarte/provider_manager.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibration/vibration.dart';
import 'package:point_in_polygon/point_in_polygon.dart' as pip;

class LocationManager {
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<Position>? _updatePositionStreamSubscription;
  bool listeningToPosition = false;
  Position? lastPosition;
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.always;

  Future<Position?> determinePosition() async {
    await checkPermissions();
    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
        forceAndroidLocationManager: true,
        timeLimit: Duration(seconds: 5),
      );
      lastPosition = currentPosition;
      return lastPosition;
    } catch (Exception) {
      return lastPosition;
    }
  }

  Future<bool> checkPermissions() async {
    // // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      print('Location services are disabled.');
      Geolocator.openLocationSettings();
    }

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
          return false;
        }
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      print(
          'Location permissions are permanently denied, we cannot request permissions.');
      return false;
    }
    return true;
  }

  Future<bool> startPositionCheck(WidgetRef ref, Function callUpdate) async {
    bool wasNull = _positionStreamSubscription == null;
    _positionStreamSubscription?.cancel();
    _updatePositionStreamSubscription?.cancel();
    if (!(await checkPermissions())) {
      print("Check permission faileds");
      return false;
    }
    print(
        "Service Status ${await _geolocatorPlatform.isLocationServiceEnabled()}");
    var stream = _geolocatorPlatform.getPositionStream(
        locationSettings: LocationSettings(distanceFilter: 3));
    _positionStreamSubscription = stream.listen((event) {
      print("position via stream");
      checkPositionInCircle(ref, event);
      lastPosition = event;
      ref.read(lastPositionProvider.notifier).set(event);
    });

    var updateStream = _geolocatorPlatform.getPositionStream(
        locationSettings: LocationSettings(distanceFilter: 10));

    _updatePositionStreamSubscription = updateStream.listen((event) {
      callUpdate();
    });
    listeningToPosition = true;
    if (wasNull) callUpdate();
    return true;
  }

  void stopPositionCheck(WidgetRef ref) async {
    _positionStreamSubscription?.cancel();
    listeningToPosition = false;
  }

  Future<void> checkPositionInCircle(WidgetRef ref, Position? position) async {
    if (position == null) return;
    List<Poi> pois = ref.watch(poiProvider);
    List<Way> ways = ref.watch(wayProvider);
    Distance distance = const Distance();
    bool inCircle = false;
    bool inWay = false;
    for (Poi poi in pois) {
      if (poi.poiElement.lat != null &&
          poi.poiElement.lon != null &&
          distance.as(
                  LengthUnit.Meter,
                  LatLng(position.latitude, position.longitude),
                  LatLng(poi.poiElement.lat!, poi.poiElement.lon!)) <
              radius) {
        inCircle = true;
      }
    }
    DateTime now = DateTime.now();
    if (now.hour >= 7 && now.hour < 20) {
      for (Way way in ways) {
        List<pip.Point> bounds = way.boundaries
            .map((e) => pip.Point(x: e.latitude, y: e.longitude))
            .toList();
        if (pip.Poly.isPointInPolygon(
            pip.Point(x: position.latitude, y: position.longitude), bounds)) {
          inWay = true;
        }
      }
    }
    bool currentInCircleState = ref.read(inCircleProvider);
    bool currentInWayState = ref.read(inWayProvider);
    print("currentInCirclestate $currentInCircleState");
    print("inCircle $inCircle");
    if (currentInCircleState != inCircle) {
      if (inCircle) {
        vibrate(ref);
        await Future.delayed(const Duration(seconds: 1));
        vibrate(ref);
      } else {
        vibrate(ref);
      }
      ref.read(inCircleProvider.notifier).set(inCircle);
    }
    if (currentInWayState != inWay) {
      if (inWay) {
        vibrate(ref);
        await Future.delayed(const Duration(milliseconds: 500));
        vibrate(ref);
        await Future.delayed(const Duration(milliseconds: 500));
        vibrate(ref);
      } else {
        vibrate(ref);
      }
      ref.read(inWayProvider.notifier).set(inWay);
    } else {
      print("Chek position in circle");
    }
  }

  Future<void> vibrate(WidgetRef ref) async {
    if (!ref.watch(vibrateProvider)) return;
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != null && hasVibrator) {
      Vibration.vibrate();
    }
  }
}

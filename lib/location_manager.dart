import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kifferkarte/map.dart';
import 'package:kifferkarte/overpass.dart';
import 'package:kifferkarte/provider_manager.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibration/vibration.dart';
import 'package:point_in_polygon/point_in_polygon.dart' as pip;
import 'package:location/location.dart';

class LocationManager {
  StreamSubscription<LocationData>? _positionStreamSubscription;
  StreamSubscription<LocationData>? _updatePositionStreamSubscription;
  bool listeningToPosition = false;
  Location location = Location();
  bool serviceEnabled = true;

  Future<bool> checkPermissions() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return false;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  Future<bool> startPositionCheck(WidgetRef ref, Function callUpdate) async {
    _positionStreamSubscription?.cancel();
    _updatePositionStreamSubscription?.cancel();
    bool wasNull = _positionStreamSubscription == null;
    _positionStreamSubscription?.cancel();
    _updatePositionStreamSubscription?.cancel();
    if (!(await checkPermissions())) {
      print("Check permission faileds");
      return false;
    }
    _positionStreamSubscription =
        location.onLocationChanged.listen((LocationData currentLocation) {
      print("position via stream");
      checkPositionInCircle(ref, currentLocation);
      ref.read(lastPositionProvider.notifier).set(currentLocation);
    });

    _updatePositionStreamSubscription =
        location.onLocationChanged.listen((LocationData currentLocation) {
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

  Future<void> checkPositionInCircle(
      WidgetRef ref, LocationData? position) async {
    if (position == null ||
        position.latitude == null ||
        position.longitude == null) return;
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
                  LatLng(position.latitude!, position.longitude!),
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
            pip.Point(x: position.latitude!, y: position.longitude!), bounds)) {
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

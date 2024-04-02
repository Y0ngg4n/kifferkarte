import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kifferkarte/location_manager.dart';
import 'package:kifferkarte/overpass.dart';
import 'package:kifferkarte/provider_manager.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends ConsumerStatefulWidget {
  MapWidget({super.key});

  @override
  ConsumerState<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  LocationManager locationManager = LocationManager();
  @override
  void initState() {
    super.initState();
    LocationManager().determinePosition();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mapController.move(mapController.camera.center, 19);
      ref.read(poiProvider.notifier).getPois();
    });
  }

  List<Marker> getPoiMarker(List<Poi> elements) {
    return elements
        .map((e) => Marker(
              // Experimentation
              // anchorPos: AnchorPos.exactly(Anchor(40, 30)),
              point: LatLng(e.poiElement.lat!, e.poiElement.lon!),
              width: 80,
              height: 80,

              child: Icon(
                Icons.location_pin,
                size: 25,
                color: Colors.black,
              ),
            ))
        .toList();
  }

  List<CircleMarker> getCircles(List<Poi> elements) {
    return elements
        .map((e) => CircleMarker(
            // Experimentation
            // anchorPos: AnchorPos.exactly(Anchor(40, 30)),
            point: LatLng(e.poiElement.lat!, e.poiElement.lon!),
            color: Colors.red.withOpacity(0.5),
            borderColor: Colors.red,
            borderStrokeWidth: 3,
            radius: 100,
            useRadiusInMeter: true))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    List<Poi> pois = ref.watch(poiProvider);
    print(pois.length);
    return Stack(
      children: [
        FlutterMap(
            mapController: mapController,
            children: [
              TileLayer(
                maxZoom: 19,
                minZoom: 0,
                userAgentPackageName: "pro.obco.kifferkarte",
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              CurrentLocationLayer(
                alignPositionOnUpdate: AlignOnUpdate.once,
                alignDirectionOnUpdate: AlignOnUpdate.once,
              ),
              MarkerLayer(
                markers: getPoiMarker(pois),
              ),
              CircleLayer(circles: getCircles(pois))
            ],
            options: MapOptions(
              maxZoom: 19,
              minZoom: 0,
              onPointerUp: (event, point) {
                ref.read(poiProvider.notifier).getPois();
              },
            )),
        Positioned(
            bottom: 10,
            right: 10,
            child: FloatingActionButton(
              heroTag: "myLocation",
              child: const Icon(Icons.my_location),
              onPressed: () async {
                Position? position = await locationManager.determinePosition();
                if (position == null) return;
                mapController.move(
                    LatLng(position.latitude, position.longitude),
                    mapController.camera.zoom);
              },
            )),
      ],
    );
  }
}

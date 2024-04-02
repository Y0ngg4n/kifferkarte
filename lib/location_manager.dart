import 'package:geolocator/geolocator.dart';

class LocationManager {
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
        return currentPosition;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }
}

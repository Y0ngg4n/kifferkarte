import 'dart:async';

import 'package:kifferkarte/location_manager.dart';
import 'package:kifferkarte/nomatim.dart';
import 'package:kifferkarte/overpass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kifferkarte/provider_manager.dart';
import 'package:latlong2/latlong.dart';

class SearchView extends ConsumerStatefulWidget {
  LocationManager locationManager;
  SearchView({Key? key, required this.locationManager}) : super(key: key);

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  TextEditingController textEditingController = TextEditingController();
  NomatimResponse? nomatimSearch;
  bool searching = false;
  Timer? _debounce;

  void search() {
    setState(() {
      searching = true;
    });
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      // Execute API call here

      Future.delayed(
        const Duration(seconds: 1),
        () async {
          Position? position = await widget.locationManager.determinePosition();
          NomatimResponse? response =
              await Nomatim.searchNomatim(position, textEditingController.text);
          setState(() {
            nomatimSearch = response;
            searching = false;
          });
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Search"),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                autofocus: true,
                decoration: new InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(50))),
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search ...',
                ),
                controller: textEditingController,
                onChanged: (_) => search(),
                onEditingComplete: search,
              ),
            ),
            searching
                ? CircularProgressIndicator()
                : (nomatimSearch == null || textEditingController.text.isEmpty
                    ? Container()
                    : Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (SearchElement element
                                in nomatimSearch!.elements)
                              ListTile(
                                leading: element.icon != null
                                    ? Image.network(element.icon!)
                                    : Text(""),
                                title: Text(element.diplay_name),
                                subtitle: Text(element.type),
                                trailing: Text(element.distanceInMeter == null
                                    ? ""
                                    : (element.distanceInMeter! > 1000
                                        ? "${round(element.distanceInMeter! / 1000, decimals: 2)} km"
                                        : "${round(element.distanceInMeter!)} m")),
                                onTap: () async {
                                  mapController.moveAndRotate(
                                      LatLng(double.parse(element.lat),
                                          double.parse(element.lon)),
                                      19,
                                      0);
                                  Navigator.pop(context);
                                },
                              )
                          ],
                        ),
                      ))
          ],
        ),
      ),
    );
  }
}

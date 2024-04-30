import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kifferkarte/location_manager.dart';
import 'package:kifferkarte/nomatim.dart';
import 'package:kifferkarte/provider_manager.dart';
import 'package:latlong2/latlong.dart';

class SearchView extends ConsumerStatefulWidget {
  final LocationManager locationManager;

  const SearchView({Key? key, required this.locationManager}) : super(key: key);

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
    _debounce = Timer(const Duration(milliseconds: 2000), () {
      // Execute API call here

      Future.delayed(
        const Duration(seconds: 1),
        () async {
          Position? position =
              ref.read(lastPositionProvider.notifier).getState();
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
          title: const Text("Search"),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(50))),
                        hintText: 'Search ...',
                      ),
                      onFieldSubmitted: (newValue) => search(),
                      controller: textEditingController,
                    ),
                  ),
                  IconButton(
                      onPressed: () => search(), icon: const Icon(Icons.search))
                ],
              ),
            ),
            searching
                ? const CircularProgressIndicator()
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
                                    : const Text(""),
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

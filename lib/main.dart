import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GpsMapApp(),
    );
  }
}

class GpsMapApp extends StatefulWidget {
  const GpsMapApp({super.key});

  @override
  State<GpsMapApp> createState() => GpsMapAppState();
}

class GpsMapAppState extends State<GpsMapApp> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    // 위도 & 경도
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  CameraPosition? _initialCameraPosition;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future init() async {
    final position = await _determinePosition();

    _initialCameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude), zoom: 17);

    setState(() {});

    final localtionSettings = LocationSettings();
    print('LocationSettings $localtionSettings}');
    Geolocator.getPositionStream(locationSettings: localtionSettings)
    .listen((Position position) {
      _moveCamera(position);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _initialCameraPosition == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              mapType: MapType.hybrid,
              initialCameraPosition: _initialCameraPosition!,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _goToTheLake,
      //   label: const Text('To the lake!'),
      //   icon: const Icon(Icons.directions_boat),
      // ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    final position = await Geolocator.getCurrentPosition();
    final cameraPosition = CameraPosition(
        target: LatLng(position.longitude, position.latitude), zoom: 20);
    await controller
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  Future<void> _moveCamera(Position position) async {
    final GoogleMapController controller = await _controller.future;
    // final position = await Geolocator.getCurrentPosition();
    final cameraPosition = CameraPosition(
        target: LatLng(position.longitude, position.latitude), zoom: 20);
    print('position.longitude : ${position.longitude}');
    print('position.longitude : ${position.latitude}');
    await controller
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }
}

Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  final LatLng storeLocation;
  final double storeRadius;
  const MapPage({super.key, required this.storeLocation, required this.storeRadius});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;
  late LatLng storeLocation;
  late double maxStoreRadiusDistance;
  LatLng? currentLocation;
  Circle? absensiCircle;
  Marker? userMarker;
  Marker? absensiMarker;
  Polyline? distanceLine;
  String distanceText = '';
  StreamSubscription<Position>? positionStream;

  void _initializeMapRenderer() {
    final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
    }
  }

  @override
  void initState() {
    super.initState();
    storeLocation = widget.storeLocation;
    maxStoreRadiusDistance = widget.storeRadius;
    _initializeMapRenderer();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );

    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);

      // Buat lingkaran untuk radius absensi
      absensiCircle = Circle(
        circleId: const CircleId('absensiCircle'),
        center: storeLocation,
        radius: maxStoreRadiusDistance, // radius 10 meter
        fillColor: Colors.blue.withOpacity(0.3),
        strokeColor: Colors.blue,
        strokeWidth: 1,
      );

      // Marker untuk lokasi pengguna
      userMarker = Marker(
        markerId: const MarkerId('userMarker'),
        position: currentLocation!,
        infoWindow: const InfoWindow(title: 'Lokasi Anda'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );

      // Marker untuk lokasi absensi (tujuan)
      absensiMarker = Marker(
        markerId: const MarkerId('absensiMarker'),
        position: storeLocation,
        infoWindow: const InfoWindow(title: 'Lokasi Absensi'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    });
  }

  void _fitMarkersToMap() {
    if (currentLocation == null || storeLocation == null) return;

    // Buat LatLngBounds yang mencakup posisi pengguna dan lokasi tujuan
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        currentLocation!.latitude < storeLocation.latitude
            ? currentLocation!.latitude
            : storeLocation.latitude,
        currentLocation!.longitude < storeLocation.longitude
            ? currentLocation!.longitude
            : storeLocation.longitude,
      ),
      northeast: LatLng(
        currentLocation!.latitude > storeLocation.latitude
            ? currentLocation!.latitude
            : storeLocation.latitude,
        currentLocation!.longitude > storeLocation.longitude
            ? currentLocation!.longitude
            : storeLocation.longitude,
      ),
    );

    // Geser kamera agar mencakup kedua marker dengan padding agar tidak terlalu dekat
    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100), // Padding 100 untuk memberi ruang pada tampilan
    );
  }

  void _calculateDistanceAndZoom() {
    if (currentLocation == null || storeLocation == null) return;

    // Hitung jarak
    double distanceInMeters = Geolocator.distanceBetween(
      currentLocation!.latitude,
      currentLocation!.longitude,
      storeLocation.latitude,
      storeLocation.longitude,
    );

    setState(() {
      distanceText = '${(distanceInMeters / 1000).toStringAsFixed(2)} km';

      // Buat garis antara lokasi pengguna dan absensi
      distanceLine = Polyline(
        polylineId: const PolylineId('distanceLine'),
        points: [currentLocation!, storeLocation],
        color: Colors.red,
        width: 2,
        patterns: [PatternItem.dash(10), PatternItem.gap(10)],
      );

      // Panggil fungsi untuk menampilkan kedua marker dalam satu frame
      _fitMarkersToMap();
    });
  }

  void _listenToLocationChanges() {
    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Ubah jarak setiap 10 meter
      ),
    ).listen((Position position) {
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);

        // Perbarui marker pengguna
        userMarker = Marker(
          markerId: const MarkerId('userMarker'),
          position: currentLocation!,
          infoWindow: const InfoWindow(title: 'Lokasi Anda'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );

        // Hitung ulang jarak dan update peta
        _calculateDistanceAndZoom();
      });
    });
  }

  @override
  void dispose() {
    // Jangan lupa berhenti mendengarkan stream lokasi ketika widget dihapus
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Absensi'),
      ),
      body: currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: currentLocation!,
              zoom: 20,
            ),
            markers: {
              if (userMarker != null) userMarker!,
              if (absensiMarker != null) absensiMarker!,
            },
            circles: absensiCircle != null ? {absensiCircle!} : Set(),
            polylines: distanceLine != null ? {distanceLine!} : Set(),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
              _listenToLocationChanges();
              // _calculateDistanceAndZoom(); // Panggil setelah map siap
            },
          ),
          if (distanceText.isNotEmpty)
            Positioned(
              top: 50,
              left: 10,
              child: Container(
                padding: const EdgeInsets.all(10),
                color: Colors.white,
                child: Text(
                  distanceText,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

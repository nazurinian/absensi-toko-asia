import 'package:absensitoko/ui/screens/absensi_page.dart';
import 'package:absensitoko/ui/screens/home_page.dart';
import 'package:absensitoko/ui/screens/login_page.dart';
import 'package:absensitoko/ui/screens/map_page.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AppRouter {
  // Method untuk menangani routing dengan onGenerateRoute
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomePage());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/absensi':
        final String employeeName = settings.arguments as String;
        return MaterialPageRoute(
            builder: (_) => AbsensiPage(employeeName: employeeName));
      case '/map':
        // Menerima LatLng sebagai arguments
        final args = settings.arguments as MapPageArguments;
        final LatLng storeLocation = args.storeLocation;
        final double storeRadius = args.storeRadius;
        return MaterialPageRoute(
          builder: (_) => MapPage(storeLocation: storeLocation, storeRadius: storeRadius,),
        );
      default:
        // Route tidak ditemukan
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Halaman tidak ditemukan!')),
          ),
        );
    }
  }
}

class MapPageArguments {
  final LatLng storeLocation;
  final double storeRadius;

  MapPageArguments({required this.storeLocation, required this.storeRadius});
}
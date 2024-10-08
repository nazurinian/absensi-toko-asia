import 'package:absensitoko/views/AbsensiPage.dart';
import 'package:absensitoko/views/HomePage.dart';
import 'package:absensitoko/views/LoginPage.dart';
import 'package:absensitoko/views/MapPage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AppRouter {
  // Method untuk menangani routing dengan onGenerateRoute
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomePage());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/absensi':
        final String employeeName = settings.arguments as String;
        return MaterialPageRoute(
            builder: (_) => AbsensiPage(employeeName: employeeName));
      case '/map':
        // Menerima LatLng sebagai arguments
        final LatLng currentLocation = settings.arguments as LatLng;
        return MaterialPageRoute(
          builder: (_) => MapPage(currentLocation: currentLocation),
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

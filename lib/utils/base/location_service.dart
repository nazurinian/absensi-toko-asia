
import 'package:absensitoko/locator.dart';
import 'package:absensitoko/utils/dialogs/loading_dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Minta izin akses lokasi
  Future<PermissionStatusResult> cekIzinLokasi() async {
    LocationPermission permission = await Geolocator.checkPermission();

    String statusMessage;
    bool isGranted;

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        statusMessage = 'Izin lokasi ditolak, harap berikan izin lokasi';
        isGranted = false;
      } else {
        statusMessage = 'Izin lokasi diberikan';
        isGranted = true;
      }
    } else if (permission == LocationPermission.deniedForever) {
      openAppSettings();
      statusMessage = 'Izin lokasi ditolak permanen, harap berikan izin di pengaturan';
      isGranted = false;
    } else {
      statusMessage = 'Izin lokasi diberikan';
      isGranted = true;
    }

    return PermissionStatusResult(statusMessage: statusMessage, isGranted: isGranted);
  }

  // Cek apakah pengguna berada dalam radius absensi
  Future<LocationCheckResult> cekLokasiSekali() async {
    LoadingDialog.show(navigatorKey.currentContext!);
    try {
      Position posisiPengguna = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Lokasi menggunakan mock atau fake GPS
      if (posisiPengguna.isMocked) {
        return LocationCheckResult(
          statusMessage: 'Lokasi palsu terdeteksi!',
          position: posisiPengguna,
          isMocked: true,
        );
      } else {
        return LocationCheckResult(
          statusMessage: 'Lokasi asli terdeteksi.',
          position: posisiPengguna,
          isMocked: false,
        );
      }
    } catch (e) {
      _safeContext((context) => LoadingDialog.hide(context));
      return LocationCheckResult(
        statusMessage: 'Terjadi kesalahan: $e',
        isMocked: false,
      );
    }
  }

  // Helper untuk akses context yang aman
  void _safeContext(Function(BuildContext) action) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      action(context);
    }
  }
}

class PermissionStatusResult {
  final String statusMessage;
  final bool isGranted;

  PermissionStatusResult({
    required this.statusMessage,
    required this.isGranted,
  });
}

class LocationCheckResult {
  final String statusMessage;
  final Position? position;
  final bool isMocked;

  LocationCheckResult({
    required this.statusMessage,
    this.position,
    required this.isMocked,
  });
}

// Contoh penggunaan ValueNotifier ini sama kayak Consumer State Provider:
/*
  // Menampilkan lokasi absensi (LatLng)
  ValueListenableBuilder<LatLng?>(
    valueListenable: locationService.attendanceLocation,
    builder: (context, lokasi, child) {
      return lokasi != null
          ? Text(
              'Lokasi: ${lokasi.latitude}, ${lokasi.longitude}',
              style: TextStyle(fontSize: 16),
            )
          : Text(
              'Lokasi belum tersedia',
              style: TextStyle(fontSize: 16),
            );
    },
  ),
*/
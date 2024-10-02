import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerWidget extends StatefulWidget {
  final Widget Function() permittedBuilder;
  final Future<Widget> Function() notPermittedBuilder;

  const PermissionHandlerWidget({
    super.key,
    required this.permittedBuilder,
    required this.notPermittedBuilder,
  });

  @override
  State<PermissionHandlerWidget> createState() =>
      _PermissionHandlerWidgetState();
}

class _PermissionHandlerWidgetState extends State<PermissionHandlerWidget> {
  // bool locationGranted = false;
  bool storageGranted = false;
  bool manageExternalStorageGranted = false;
  bool mediaLibraryGranted = false;

  // bool bluetoothGranted = false;
  bool permissionsRequested = false;

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  Future<void> requestPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      // Permission.bluetooth,
      // Permission.bluetoothScan,
      // Permission.bluetoothConnect,
      // Permission.bluetoothAdvertise,
      // Permission.location,
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.mediaLibrary,
    ].request();

    statuses.forEach(
      (permission, status) {
        // if (permission == Permission.location) {
        //   if (status.isGranted) {
        //     locationGranted = true;
        //   }
        //   if (status.isPermanentlyDenied) {
        //     openAppSettings();
        //   }
        // }
        if (permission == Permission.storage) {
          if (status.isGranted) {
            storageGranted = true;
          }
          if (status.isPermanentlyDenied) {
            openAppSettings();
          }
        }
        if (permission == Permission.manageExternalStorage) {
          if (status.isGranted) {
            manageExternalStorageGranted = true;
          }
          if (status.isPermanentlyDenied) {
            openAppSettings();
          }
        }
        if (permission == Permission.mediaLibrary) {
          if (status.isGranted) {
            mediaLibraryGranted = true;
          }
          if (status.isPermanentlyDenied) {
            openAppSettings();
          }
        }
        // if (permission == Permission.bluetoothScan) {
        //   if (status.isGranted) {
        //     bluetoothGranted = true;
        //   }
        //   if (status.isPermanentlyDenied) {
        //     openAppSettings();
        //   }
        // }
      },
    );

    setState(() {
      permissionsRequested = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!permissionsRequested) {
      return const Center(child: CircularProgressIndicator());
    }
    print(
        'taia: $storageGranted, $manageExternalStorageGranted, $mediaLibraryGranted');
    // return (locationGranted && bluetoothGranted)
    return (mediaLibraryGranted)
        ? widget.permittedBuilder()
        : FutureBuilder<Widget>(
            future: widget.notPermittedBuilder(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              return snapshot.data ?? Container();
            },
          );
  }
}

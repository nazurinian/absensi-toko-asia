import 'package:absensitoko/provider/ConnectionProvider.dart';
import 'package:absensitoko/utils/Helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ConnectionChecker extends StatelessWidget {
  final Widget connectedWidget;
  final Widget? disconnectedWidget;

  ConnectionChecker({
    super.key,
    required this.connectedWidget,
    this.disconnectedWidget,
  });

  bool _hasShownDialog = false;
  bool _lastConnectionStatus = true;

  void _showConnectionStatusDialog(bool isConnected) {
    if (isConnected && _hasShownDialog) {
      ToastUtil.showToast('Kembali terhubung ke internet', ToastStatus.success);
    } else if (!isConnected && _lastConnectionStatus) {
      _hasShownDialog = true;
      ToastUtil.showToast('Koneksi internet terputus', ToastStatus.error);
    }

    _lastConnectionStatus = isConnected; // Update status koneksi terakhir
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
        builder: (context, connectionProvider, child) {
      if (connectionProvider.isConnected != _lastConnectionStatus) {
        _showConnectionStatusDialog(connectionProvider.isConnected);
      }
      return StreamBuilder<List<ConnectivityResult>>(
        stream: Connectivity().onConnectivityChanged,
        initialData: const [ConnectivityResult.mobile, ConnectivityResult.wifi],
        builder: (context, snapshot) {
          final connectionStatus = snapshot.data!;

          if (kIsWeb) {
            return connectedWidget;
          } else {
            return !connectionStatus.contains(ConnectivityResult.none)
                ? connectedWidget
                : disconnectedWidget ?? _defaultDisconnectedWidget();
          }
        },
      );
    });
  }

  Widget _defaultDisconnectedWidget() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          const SizedBox(width: 8.0), // Spacer
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 65,
            child: CustomPaint(
              size: const Size(120, 120),
              painter: SlashPainter(),
            ),
          ),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mobiledata_off,
                    size: 120.0,
                  ),
                  SizedBox(width: 8.0), // Spacer
                ],
              ),
              SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off,
                    size: 120.0,
                  ),
                ],
              ),
            ],
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "Koneksi internet anda bermasalah\n harap cek koneksi internet anda!",
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0;

    canvas.drawLine(
      Offset(0, size.height), // start point
      Offset(size.width, 0), // end point
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

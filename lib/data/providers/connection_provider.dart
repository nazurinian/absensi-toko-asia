import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectionProvider with ChangeNotifier {
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  ConnectionProvider() {
    _initializeConnectionListener();
  }

  void _initializeConnectionListener() {
    InternetConnectionChecker().onStatusChange.listen((status) {
      bool isConnected = status == InternetConnectionStatus.connected;
      if (isConnected != _isConnected) {
        _isConnected = isConnected;
        notifyListeners();
      }
    });
  }
}

import 'package:absensitoko/utils/base/location_service.dart';
import 'package:absensitoko/utils/base/version_checker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

// Instance global dari GetIt
final GetIt locator = GetIt.instance;
final navigatorKey = GlobalKey<NavigatorState>();

// Fungsi untuk register dependensi
void setupLocator() {
  locator.registerLazySingleton(() => navigatorKey);
  locator.registerLazySingleton<VersionChecker>(() => VersionChecker());
  locator.registerLazySingleton<LocationService>(() => LocationService());
}



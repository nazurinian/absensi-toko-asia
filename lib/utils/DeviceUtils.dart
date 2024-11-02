import 'package:absensitoko/ServiceLocator.dart';
import 'package:absensitoko/models/AppVersionModel.dart';
import 'package:absensitoko/provider/DataProvider.dart';
import 'package:absensitoko/utils/DialogUtils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceUtils {
  final DataProvider _dataProvider = locator<DataProvider>();
  final DialogUtils _dialogUtils = locator<DialogUtils>();

  // Mendapatkan id perangkat
  static Future<String> getDeviceName(BuildContext context) async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Theme.of(context).platform == TargetPlatform.android) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name ?? 'Unknown Device';
    } else {
      return 'Unsupported Platform';
    }
  }

  static Future<AppVersionModel> getAppInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;

    return AppVersionModel(
      version: version,
      buildNumber: int.parse(buildNumber),
    );
  }
}
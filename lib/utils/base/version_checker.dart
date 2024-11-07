import 'package:absensitoko/data/models/version_model.dart';
import 'package:absensitoko/data/providers/data_provider.dart';
import 'package:absensitoko/locator.dart';
import 'package:absensitoko/utils/device_util.dart';
import 'package:absensitoko/utils/dialogs/dialog_utils.dart';
import 'package:absensitoko/utils/popup_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class VersionChecker {
  static Future<void> checkForUpdates() async {
    final context = navigatorKey.currentContext!;

    AppVersionModel thisAppVer = await DeviceUtils.getAppInfo();

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    String title = 'Pembaruan Diperlukan';
    String content = '';

    AppVersionModel? newAppVer = dataProvider.appVersion ?? AppVersionModel();
    if (dataProvider.appVersion == null) {
      await dataProvider.getAppVersion();

      newAppVer = dataProvider.appVersion!;

      if (context.mounted) {
        if ((thisAppVer.version != newAppVer.version ||
                thisAppVer.buildNumber != newAppVer.buildNumber) &&
            newAppVer.mandatory!) {
          content =
              'Aplikasi Anda saat ini versi: ${thisAppVer.version} sudah tidak dapat digunakan, silahkan update ke versi terbaru: ${newAppVer.version} dengan mengklik tombol Perbarui';
          bool result = await DialogUtils.showExpiredDialog(context,
                  title: title, content: content, buttonText: 'Perbarui') ??
              false;
          if (result) {
            final updateLink =
                Uri.parse(newAppVer.link ?? "https://flutter.dev");
            if (!await launchUrl(updateLink)) {
              ToastUtil.showToast('Gagal membuka browser', ToastStatus.error);
            }
          }
        }
      }
    } else {
      if (context.mounted) {
        content =
            'Anda masih belum melakukan update aplikasi saaat ini, silahkan update ke versi terbaru: ${newAppVer.version} dengan mengklik tombol Perbarui';
        if ((thisAppVer.version != newAppVer.version ||
                thisAppVer.buildNumber != newAppVer.buildNumber) &&
            newAppVer.mandatory!) {
          bool result = await DialogUtils.showExpiredDialog(context,
                  title: title, content: content, buttonText: 'Perbarui') ??
              false;
          if (result) {
            final updateLink =
                Uri.parse(newAppVer.link ?? "https://flutter.dev");
            if (!await launchUrl(updateLink)) {
              ToastUtil.showToast('Gagal membuka browser', ToastStatus.error);
            }
          }
        }
      }
    }
  }

  static Future<void> setAppVersion(AppVersionModel appVersion) async {
    final context = locator<GlobalKey<NavigatorState>>().currentContext!;

    Provider.of<DataProvider>(context, listen: false).updateAppVersion(appVersion);

  }
}

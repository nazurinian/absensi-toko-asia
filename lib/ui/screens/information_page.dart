import 'package:absensitoko/core/themes/fonts/fonts.dart';
import 'package:absensitoko/data/providers/data_provider.dart';
import 'package:absensitoko/ui/widgets/custom_list_tile.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InformationPage extends StatelessWidget {
  final Future<AndroidDeviceInfo> _dataFuture = _getDeviceName();

  InformationPage({super.key});

  static Future<AndroidDeviceInfo> _getDeviceName() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo;
  }

  @override
  Widget build(BuildContext context) {
    final thisAppVersion =
        Provider
            .of<DataProvider>(context, listen: false)
            .appVersion;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Information Page'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<AndroidDeviceInfo>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else {
              final AndroidDeviceInfo androidInfo = snapshot.data!;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Device Information',
                        textAlign: TextAlign.center,
                        style: FontTheme.bodyMedium(context, fontSize: 24)),
                    const SizedBox(height: 20),
                    CustomListTile(
                      title: 'Manufacturer',
                      trailing: Text(androidInfo.manufacturer,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16)),
                    ),
                    CustomListTile(
                      title: 'Model',
                      trailing: Text(androidInfo.model,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16)),
                    ),
                    CustomListTile(
                      title: 'Android Version',
                      trailing: Text('Android ${androidInfo.version.release}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16)),
                    ),
                    CustomListTile(
                      title: 'API Level',
                      trailing: Text(androidInfo.version.sdkInt.toString(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16)),
                    ),
                    CustomListTile(
                      title: 'Security Patch',
                      trailing: Text(androidInfo.version.securityPatch ?? 'N/A',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16)),
                    ),
                    CustomListTile(
                      title: 'Hardware',
                      trailing: Text(androidInfo.hardware,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16)),
                    ),
                    CustomListTile(
                      title: 'Device',
                      trailing: Text(androidInfo.device,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16)),
                    ),
                    CustomListTile(
                      title: 'Product',
                      trailing: Text(androidInfo.product,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16)),
                    ),
                    const SizedBox(height: 20),
                    const Divider(thickness: 2),
                    const SizedBox(height: 20),
                    Text('Application Version',
                        textAlign: TextAlign.center,
                        style: FontTheme.bodyMedium(context, fontSize: 24)),
                    const SizedBox(height: 20),
                    CustomListTile(
                      title: 'Versi Aplikasi',
                      trailing: Text(thisAppVersion?.version ?? '',
                          style: FontTheme.bodyMedium(context, fontSize: 16)),
                    ),
                    CustomListTile(
                      title: 'Build Number',
                      trailing: Text(thisAppVersion?.buildNumber.toString() ?? '',
                          style: FontTheme.bodyMedium(context, fontSize: 16)),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

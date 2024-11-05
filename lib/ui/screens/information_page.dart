import 'package:absensitoko/core/themes/fonts/fonts.dart';
import 'package:absensitoko/data/models/version_model.dart';
import 'package:absensitoko/data/providers/data_provider.dart';
import 'package:absensitoko/ui/widgets/custom_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InformationPage extends StatelessWidget {
  const InformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final thisAppVersion = Provider.of<DataProvider>(context, listen: false).appVersion;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Information Page'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Application Version', textAlign: TextAlign.center, style: FontTheme.bodyMedium(context, fontSize: 24)),
            const SizedBox(height: 20),
            CustomListTile(
              title: 'Versi Aplikasi',
              trailing: Text(thisAppVersion?.version ?? '', style: FontTheme.bodyMedium(context, fontSize: 16)),
            ),
            CustomListTile(
              title: 'Build Number',
              trailing: Text(thisAppVersion?.buildNumber.toString() ?? '', style: FontTheme.bodyMedium(context, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

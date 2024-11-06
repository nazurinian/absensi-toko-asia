// Halaman ini tidak digunakan dalam aplikasi Flutter ini.
/*
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdatePage extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;
  final String downloadLink;

  const UpdatePage(
      {super.key,
      required this.currentVersion,
      required this.latestVersion,
      required this.downloadLink});

  Future<void> openBrowser(String url) async {
    final Uri uri = Uri.parse(url); // Mengonversi string URL menjadi Uri
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri); // Menggunakan launchUrl untuk membuka URL
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembaruan Diperlukan')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Aplikasi Anda saat ini versi: $currentVersion'),
            Text('Versi terbaru: $latestVersion'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Mengarahkan pengguna ke tautan unduhan
                await openBrowser(downloadLink);
              },
              child: const Text('Perbarui Sekarang'),
            ),
          ],
        ),
      ),
    );
  }
}
*/

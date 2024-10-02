import 'package:absensitoko/utils/Helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dart_ping/dart_ping.dart';

class NoInternetApp extends StatelessWidget {
  final String errorMessage;

  const NoInternetApp({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: NoInternetScreen(errorMessage: errorMessage),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NoInternetScreen extends StatelessWidget {
  final String errorMessage;

  const NoInternetScreen({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off,
                  size: 100,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (await checkInternetConnection()) {
                      await FirebaseAuth.instance.signInAnonymously();
                      // await initializeDateFormatting('id_ID', null).then((_) => runApp(const MyApp()));
                    }
                  },
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> checkInternetConnection() async {
  try {
    final ping = Ping('google.com', count: 2);
    final result = await ping.stream.first;

    if(result.response != null) {
      ToastUtil.showToast("Mencoba kembali koneksi ke server", ToastStatus.success);
      return true;
    } else {
      ToastUtil.showToast("Harap cek koneksi internet", ToastStatus.error);
      return false;
    }
  } catch (e) {
    print('Error checking internet connection: $e');
    return false;
  }
}

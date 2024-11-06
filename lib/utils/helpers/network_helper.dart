import 'package:internet_connection_checker/internet_connection_checker.dart';

class NetworkHelper {
  // Fungsi statis untuk mengecek koneksi internet
  static Future<bool> hasInternetConnection() async {
    return await InternetConnectionChecker().hasConnection;
  }

  // Fungsi statis untuk memantau perubahan koneksi
  static void listenToConnectionChanges(Function(bool) onStatusChange) {
    InternetConnectionChecker().onStatusChange.listen((status) {
      bool isConnected = status == InternetConnectionStatus.connected;
      onStatusChange(isConnected);
    });
  }
}

/*
  // Contoh penggunaan Untuk memeriksa koneksi internet
    bool isConnected = await NetworkHelper.hasInternetConnection();
    if (isConnected) {
      print("Koneksi internet tersedia");
    } else {
      print("Tidak ada koneksi internet");
    }

  // Contoh penggunaan Untuk memantau perubahan koneksi
    NetworkHelper.listenToConnectionChanges((isConnected) {
      if (isConnected) {
        print("Terhubung ke internet");
      } else {
        print("Terputus dari internet");
      }
    });
*/

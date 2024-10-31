import 'package:absensitoko/AppRouter.dart';
import 'package:absensitoko/provider/ConnectionProvider.dart';
import 'package:absensitoko/themes/theme.dart';
import 'package:absensitoko/utils/DeviceUtils.dart';
import 'package:absensitoko/utils/ThemeUtil.dart';
import 'package:absensitoko/views/UpdatePage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:absensitoko/provider/DataProvider.dart';
import 'package:absensitoko/provider/StorageProvider.dart';
import 'package:absensitoko/provider/TimeProvider.dart';
import 'package:absensitoko/provider/UserProvider.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:absensitoko/views/LoginPage.dart';
import 'package:absensitoko/views/HomePage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id_ID', null);

  final prefs = await SharedPreferences.getInstance();
  bool? isLoggedIn = prefs.getBool('isLogin') ?? false;

  // Memeriksa pembaruan sebelum melanjutkan
  // Map<String, String> updateInfo = await checkForUpdates();
  Map<String, String> updateInfo = {
    'needsUpdate': 'false',
    'currentVersion': '0.0.0',
    'latestVersion': '0.0.0',
    'downloadLink': '',
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => StorageProvider()),
        ChangeNotifierProvider(create: (_) => TimeProvider()),
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
      ],
      child: MyApp(
        isLoggedIn: isLoggedIn,
        needsUpdate: updateInfo['needsUpdate'] == 'true',
        currentVersion: updateInfo['currentVersion']!,
        latestVersion: updateInfo['latestVersion']!,
        downloadLink: updateInfo['downloadLink']!,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool needsUpdate;
  final String currentVersion;
  final String latestVersion;
  final String downloadLink;

  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.needsUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadLink,
  });

  @override
  Widget build(BuildContext context) {
    // Retrieves the default theme for the platform
    //TextTheme textTheme = Theme.of(context).textTheme;

    // Use with Google Fonts package to use downloadable fonts
    TextTheme textTheme = createTextTheme(context, "Lato", "Aclonica");
    MaterialTheme theme = MaterialTheme(textTheme);

    print(
        'Needs update: $needsUpdate | Current version: $currentVersion | Latest version: $latestVersion');
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        SfGlobalLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        // CupertinoLocalizations is not included in the Flutter framework by default, delegasi locale id_ID (Bahasa Indonesia) untuk elemen Cupertino.
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English, United States
        Locale('id', 'ID'), // Indonesian
        Locale('ar', 'AE'), // Arabic, United Arab Emirates
        Locale('zh', 'CN'), // Chinese, China
      ],
      theme: theme.light(),
      darkTheme: theme.dark(),
      onGenerateRoute: AppRouter.generateRoute,
      home: needsUpdate
          ? UpdatePage(
              currentVersion: currentVersion,
              latestVersion: latestVersion,
              downloadLink: downloadLink,
            )
          : isLoggedIn
              ? const HomePage()
              : const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

Future<Map<String, String>> checkForUpdates() async {
  Map<String, String> appInfo = await DeviceUtils.getAppInfo();
  String currentVersion = appInfo['version'] ?? '0.0.0'; // Default jika null

  // Ambil versi terbaru dan link dari Firestore
  DocumentSnapshot snapshot = await FirebaseFirestore.instance
      .collection('information')
      .doc('latest_version')
      .get();

  String latestVersion = snapshot['version'];
  String downloadLink = snapshot['link']; // Link unduhan

  // Bandingkan versi
  bool needsUpdate = currentVersion != latestVersion;

  return {
    'needsUpdate': needsUpdate.toString(), // "true" atau "false"
    'currentVersion': currentVersion,
    'latestVersion': latestVersion,
    'downloadLink': downloadLink, // Menyimpan link
  };
}

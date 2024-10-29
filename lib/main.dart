import 'package:absensitoko/AppRouter.dart';
import 'package:absensitoko/themes/theme.dart';
import 'package:absensitoko/utils/ThemeUtil.dart';
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

import 'NoInternetApp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id_ID', null);

  final prefs = await SharedPreferences.getInstance();
  bool? isLoggedIn = prefs.getBool('isLogin') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => StorageProvider()),
        ChangeNotifierProvider(create: (_) => TimeProvider()),
      ],
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    // Retrieves the default theme for the platform
    //TextTheme textTheme = Theme.of(context).textTheme;

    // Use with Google Fonts package to use downloadable fonts
    TextTheme textTheme = createTextTheme(context, "Lato", "Aclonica");

    MaterialTheme theme = MaterialTheme(textTheme);
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

      home: isLoggedIn ? const HomePage() : const LoginPage(),

      debugShowCheckedModeBanner: false,
    );
  }
}

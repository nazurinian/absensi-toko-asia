import 'package:absensitoko/routes.dart';
import 'package:absensitoko/locator.dart';
import 'package:absensitoko/data/providers/connection_provider.dart';
import 'package:absensitoko/core/themes/theme.dart';
import 'package:absensitoko/utils/device_util.dart';
import 'package:absensitoko/utils/theme_util.dart';
import 'package:absensitoko/ui/screens/update_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:absensitoko/data/providers/data_provider.dart';
import 'package:absensitoko/data/providers/storage_provider.dart';
import 'package:absensitoko/data/providers/time_provider.dart';
import 'package:absensitoko/data/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'core/config/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:absensitoko/ui/screens/login_page.dart';
import 'package:absensitoko/ui/screens/home_page.dart';
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

  setupLocator();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => StorageProvider()),
        ChangeNotifierProvider(create: (_) => TimeProvider()),
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
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
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/models/store.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'Services/nsfw_detect_service.dart';
import 'View/splash_view.dart';
import 'for_ads/utils/app_constants.dart';
import 'for_ads/utils/shared_prefrence_service.dart';
import 'for_ads/utils/store_config.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('saved_projects');
  await NsfwDetectService.init();
  await SharedPrefService.init();
  await MobileAds.instance.initialize();
  await Firebase.initializeApp();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  if (Platform.isIOS || Platform.isMacOS) {
    if (kDebugMode) {
      print("object");
    }
    StoreConfig(store: Store.appStore, apiKey: appleApiKey);
  } else if (Platform.isAndroid) {
    // Run the app passing --dart-define=AMAZON=true
    const useAmazon = bool.fromEnvironment("amazon");
    StoreConfig(store: useAmazon ? Store.amazon : Store.playStore, apiKey: useAmazon ? amazonApiKey : googleApiKey);
  }
  await configureSDK();
  runApp(const MyApp());
}

Future<void> configureSDK() async {
  try {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (StoreConfig.isForAmazonAppstore()) {
      configuration = AmazonConfiguration(StoreConfig.instance.apiKey);
    } else {
      configuration = PurchasesConfiguration(StoreConfig.instance.apiKey);
    }

    configuration.entitlementVerificationMode = EntitlementVerificationMode.informational;
    await Purchases.configure(configuration);

    // ✅ ADD THIS — register renewal listener immediately after configure
    // SubscriptionCreditService.initUpdateListener();

    await Purchases.enableAdServicesAttributionTokenCollection();

    final offerings = await Purchases.getOfferings();
    if (offerings.current != null) {
      ('✅ Offering found: ${offerings.current!.identifier}');
      for (final pkg in offerings.current!.availablePackages) {
        if (kDebugMode) {
          print('👉 Package: ${pkg.identifier}');
        }
        if (kDebugMode) {
          print('👉 Product: ${pkg.storeProduct.identifier}');
        }
      }
    } else {
      if (kDebugMode) {
        print('⚠️ No current offering found');
      }
    }
  } catch (e, st) {
    if (kDebugMode) {
      print('❌ Error configuring SDK or fetching offerings: $e');
    }
    if (kDebugMode) {
      print(st);
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
        home: const SplashScreen(),
      ),
    );
  }
}

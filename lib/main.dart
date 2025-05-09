import 'dart:ui';
import 'package:adic_poc/services/telementry_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/staff_screen.dart';
import 'screens/staff_form_screen.dart';
import 'screens/staff_ai_chat_screen.dart';
import 'screens/api_key_screen.dart';
import 'screens/main_layout.dart';
import 'screens/settings_screen.dart';
import 'services/database_service.dart';
import 'services/sync_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print('🔔 User granted permission: ${settings.authorizationStatus}');

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    // ✅ Wait until the APNs token is set
    String? apnsToken;
    int attempts = 0;
    while ((apnsToken = await messaging.getAPNSToken()) == null && attempts < 10) {
      print("⌛ Waiting for APNs token...");
      await Future.delayed(Duration(seconds: 1));
      attempts++;
    }

    if (apnsToken != null) {
      print("📲 APNs Token received: $apnsToken");
      String? fcmToken = await messaging.getToken();
      print("🔑 FCM Token: $fcmToken");

      if (fcmToken != null) {
        const connectionString = 'YOUR_AZURE_CONNECTION_STRING';
        const hubName = 'YOUR_NOTIFICATION_HUB_NAME';

        // final azHub = AzureNotificationHub(
        //
        // )
        //
        // await azHub.register(token: fcmToken);
      }
    } else {
      print("❌ APNs token not set. Could not retrieve FCM token.");
    }
  } else {
    print("❌ Notification permission not granted.");
  }

  // 🔔 Foreground handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📩 Message in foreground: ${message.notification?.title}');
  });

  // 📬 Background notification tap handler
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('🟢 Opened from push: ${message.notification?.title}');
  });

  // 🛠 Initialize other services
  final databaseService = DatabaseService();
  await databaseService.init();

  final syncService = SyncService();
  syncService.init();

  FlutterError.onError = (FlutterErrorDetails details) {
    TelemetryService().logError(details.exceptionAsString(), details.stack);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    TelemetryService().logError(error.toString(), stack);
    return true;
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'AAD SSO Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.teal.shade600,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
             style: ElevatedButton.styleFrom(
               backgroundColor: Colors.teal.shade600,
               foregroundColor: Colors.white,
             ),
          ),
           bottomNavigationBarTheme: BottomNavigationBarThemeData(
            selectedItemColor: Colors.teal.shade700,
            unselectedItemColor: Colors.grey.shade600,
          ),
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/staff': (context) => const StaffScreen(),
          '/main': (context) => const MainLayout(),
          '/staff/ai': (context) => const StaffAIChatScreen(),
          '/settings/api-key': (context) => const ApiKeyScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/staff/form': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            if (args != null && args['isEditing'] == true && args['staff'] != null) {
              // Edit existing staff
              return EditStaffScreen(staff: args['staff']);
            } else if (args != null && args['prefillData'] != null) {
              // New staff with prefilled data from AI
              return AddStaffScreen(prefillData: args['prefillData']);
            } else {
              // New staff without prefilled data
              return const AddStaffScreen();
            }
          },
        },
      ),
    );
  }
}

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
  
  // Initialize database
  final databaseService = DatabaseService();
  await databaseService.init();
  
  // Initialize sync service
  final syncService = SyncService();
  syncService.init();
  
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
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
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

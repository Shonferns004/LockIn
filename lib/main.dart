import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'providers/app_provider.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/database_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await NotificationService.init();

  final api = ApiService();
  await api.init();

  final db = DatabaseService(api);
  final auth = AuthService();
  await auth.init();
  final currentUserId = auth.userUuid;
  if (currentUserId != null && currentUserId.isNotEmpty) {
    db.setUserId(currentUserId);
  }
  runApp(LockInApp(db: db));
}

class LockInApp extends StatelessWidget {
  final DatabaseService db;

  const LockInApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(db: db)..init(),
      child: MaterialApp(
        title: 'LockIn',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: 'splash',
        routes: {
          'splash': (_) => const SplashScreen(),
          'login': (_) => const LoginScreen(),
          'signup': (_) => const SignupScreen(),
          'onboarding': (_) => const OnboardingScreen(),
          'home': (_) => const HomeScreen(),
        },
      ),
    );
  }
}

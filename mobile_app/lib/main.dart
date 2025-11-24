import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/baseline_service.dart';
import 'services/baseline_recording_service.dart';
import 'services/notification_service.dart';
import 'services/device_service.dart';
import 'services/event_service.dart';
import 'services/fall_detection_service.dart';
import 'services/feeling_good_service.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/setup/firebase_setup_screen.dart';
import 'utils/app_theme.dart';
import 'firebase_options.dart';

bool _firebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  // Try to initialize Firebase, but handle errors gracefully if not configured
  try {
    // Check if Firebase is already initialized
    try {
      Firebase.app(); // This will throw if not initialized
      _firebaseInitialized = true;
    } catch (_) {
      // Not initialized, try to initialize
      final options = DefaultFirebaseOptions.currentPlatform;

      // Check if Firebase options are still placeholders
      if (options.apiKey.contains('YOUR_') ||
          options.projectId.contains('YOUR_')) {
        _firebaseInitialized = false;
        debugPrint(
            'Firebase not configured. Please run: flutterfire configure');
      } else {
        await Firebase.initializeApp(options: options);
        _firebaseInitialized = true;
      }
    }
  } catch (e) {
    // Firebase not configured - app will show setup screen
    _firebaseInitialized = false;
    debugPrint('Firebase initialization failed: $e');
    debugPrint('Please run: flutterfire configure');
  }

  // Initialize notification service
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
  } catch (e) {
    debugPrint('Notification service initialization error: $e');
  }

  runApp(MyApp(isFirebaseInitialized: _firebaseInitialized));
}

class MyApp extends StatelessWidget {
  final bool isFirebaseInitialized;

  const MyApp({super.key, required this.isFirebaseInitialized});

  @override
  Widget build(BuildContext context) {
    final List<SingleChildWidget> providers = [
      Provider<NotificationService>(create: (_) => NotificationService()),
    ];

    // Only add Firebase-dependent services if Firebase is initialized
    if (isFirebaseInitialized) {
      providers.addAll([
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirebaseService>(create: (_) => FirebaseService()),
        Provider<BaselineService>(create: (_) => BaselineService()),
        Provider<BaselineRecordingService>(create: (_) => BaselineRecordingService()),
        Provider<DeviceService>(create: (_) => DeviceService()),
        Provider<EventService>(create: (_) => EventService()),
        Provider<FallDetectionService>(
          create: (_) => FallDetectionService(
            Provider.of<EventService>(_, listen: false),
            Provider.of<NotificationService>(_, listen: false),
          ),
        ),
        Provider<FeelingGoodService>(create: (_) => FeelingGoodService()),
      ]);
    }

    return MultiProvider(
      providers: providers,
      child: MaterialApp(
        title: 'Mental Health Monitor',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: isFirebaseInitialized
            ? const AuthWrapper()
            : const FirebaseSetupScreen(),
        routes: {
          '/signin': (context) => const SignInScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/home': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const DashboardScreen();
        }

        return const SignInScreen();
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'screens/login_selection_page.dart';
import 'screens/home_page.dart';
import 'screens/profile_page.dart';
import 'screens/student_login_screen.dart';
import 'screens/student_registration_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/faculty_registration_page.dart';
import 'screens/public_login_screen.dart';
import 'screens/public_registration_screen.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    // Wrap the app with ProviderScope for Riverpod
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// Firebase service provider
final firebaseServiceProvider = Provider((ref) => FirebaseService());

// Auth state provider
final authStateProvider = StreamProvider((ref) {
  return ref.watch(firebaseServiceProvider).authStateChanges;
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to auth state changes
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MAHITHI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      routes: {
        '/student-login': (context) => const StudentLoginScreen(),
        '/student-register': (context) => const StudentRegistrationScreen(),
        '/faculty-register': (context) => const FacultyRegistrationPage(),
        '/public-login': (context) => const PublicLoginScreen(),
        '/public-register': (context) => const PublicRegistrationScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/profile': (context) => const ProfilePage(),
        '/home': (context) => const HomePage(),
      },
      home: authState.when(
        data: (user) {
          // If user is authenticated, go to home page, otherwise login
          return user != null ? const HomePage() : const LoginSelectionPage();
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stackTrace) => Scaffold(
          body: Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
    );
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:rate_my_fit/screens/login_screen.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/shell_screen.dart';
import 'screens/login_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // if (kDebugMode) {
  //   await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  // }

  // try {
  //   final userCredential = await FirebaseAuth.instance.signInAnonymously();
  //   print('✅ Firebase connected! UID: ${userCredential.user?.uid}');
  // } catch (e) {
  //   print('❌ Firebase error: $e');
  // }
  runApp(const RateMyFitApp());
}

class RateMyFitApp extends StatelessWidget {
  const RateMyFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rate My Fit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const LoginScreen(),
    );
  }
}

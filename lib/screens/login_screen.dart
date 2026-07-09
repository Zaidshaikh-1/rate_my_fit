import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rate_my_fit/screens/shell_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme/app_theme.dart';
import 'package:flutter/foundation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn();


  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      // TODO: step 1 — trigger Google sign-in popup
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // TODO: step 2 — get auth credentials from the Google account
      // always await the authentication
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // TODO: step 3 — sign into Firebase with those credentials
      await FirebaseAuth.instance.signInWithCredential(credential);

      // TODO: step 4 — navigate to ShellScreen on success
      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ShellScreen()),
        );
      }
    } catch (e) {
      // TODO: show a snackbar with the error message
      final snackBar = SnackBar(
        content: const Text('Something did not pass the vibe check :('),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
            label: 'Run it Back',
            onPressed: () {},
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }

    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: app name or logo
            Container(
              child: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'rate',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: 'myfit',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48,),

            const Text('Sign In using your Google Account',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600
            ),
            ),

            const SizedBox(height: 48),

            // TODO: Google sign-in button
            // hint: use _isLoading to show a loading spinner vs the button
            SizedBox(
              width: double.infinity, // stretches button full width
              child: ElevatedButton(
                onPressed: () {
                  // what happens when tapped
                  _isLoading ? null : _handleGoogleSignIn();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                child:
                    _isLoading ? const SizedBox(
                      height: 20,
                      width: 20,

                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )

                :const Text(
                  'Sign Up',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ShellScreen()),
                  );
                },
                child: const Text(
                  '⚡ Dev Skip (debug only)',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
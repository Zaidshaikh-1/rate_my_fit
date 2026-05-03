import 'package:flutter/material.dart';
import '';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      // TODO: step 1 — trigger Google sign-in popup
      // TODO: step 2 — get auth credentials from the Google account
      // TODO: step 3 — sign into Firebase with those credentials
      // TODO: step 4 — navigate to ShellScreen on success
    } catch (e) {
      // TODO: show a snackbar with the error message
    } finally {
      setState(() => _isLoading = false);
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

            ),

            const SizedBox(height: 48),

            // TODO: Google sign-in button
            // hint: use _isLoading to show a loading spinner vs the button
          ],
        ),
      ),
    );
  }
}
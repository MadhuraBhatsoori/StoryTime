import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:storytime/pages/frontend/navbar.dart';
import 'package:storytime/pages/frontend/auth_services/options.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('An error occurred. Please try again later.'));
          } else if (snapshot.hasData) {
            // If user is logged in, pass the user email to Navbar
            final userEmail = snapshot.data?.email ?? '';
            return Navbar(userEmail: userEmail);
          } else {
            return const Options(); // If user is not logged in, show login options page
          }
        },
      ),
    );
  }
}

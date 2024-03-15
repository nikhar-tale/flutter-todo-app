import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LogoutScreen extends StatefulWidget {
  const LogoutScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LogoutScreenState createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  late User? user = _auth.currentUser;

  bool loading = false;

  Future<void> _logout(BuildContext context) async {
    try {
      setState(() {
        loading = true;
      });
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();

      // Provide feedback to the user
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
      // Pop the LogoutScreen
      // ignore: use_build_context_synchronously
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      setState(() {
        loading = false;
      });
      if (kDebugMode) {
        print('Error logging out: $e');
      }
      // Provide feedback to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while logging out')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logout'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              CircularProgressIndicator()
            else if (user != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(user.photoURL ?? ''),
                      radius: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${user.displayName ?? ''}!',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ElevatedButton(
              onPressed: () {
                _logout(context);
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'manager/dashboard/manager_dashboard.dart';
import 'user/dashboard/user_dashboard.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _managerUsernameController = TextEditingController();
  final TextEditingController _managerPasswordController = TextEditingController();

  bool _loading = false;
  String _error = '';

  void _managerLogin() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final username = _managerUsernameController.text.trim();
    final password = _managerPasswordController.text.trim();

    if (username == 'admin' && password == 'admin') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', username);
      await prefs.setString('email', username + '@manager.com'); // fake email for admin manager
      await prefs.setString('uid', username);
      await prefs.setString('role', 'manager');

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ManagerDashboard()));
      setState(() {
        _loading = false;
      });
      return;
    }


    try {
      final manager = await FirebaseFirestore.instance
          .collection('managers')
          .doc(username)
          .get();

      if (manager.exists && manager.data()!['password'] == password) {
        if (!mounted) return;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('name', username);
        await prefs.setString('email', username + '@manager.com'); // fake email for manager
        await prefs.setString('uid', username);
        await prefs.setString('role', 'manager');

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ManagerDashboard()));

      } else {
        setState(() {
          _error = "Invalid credentials.";
        });
      }
    } catch (e) {
      setState(() {
        _error = "Login error: ${e.toString()}";
      });
    }

    setState(() {
      _loading = false;
    });
  }

  void _userLogin() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final email = googleUser.email;

      if (!email.endsWith('@rubrik.com')) {
        setState(() {
          _error = "Only @rubrik.com emails allowed.";
          _loading = false;
        });
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

        final docSnapshot = await userDoc.get();
        if (!docSnapshot.exists) {
          await userDoc.set({
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'uid': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (!mounted) return;

// Save to shared preferences

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', user?.displayName ?? '');
      await prefs.setString('email', user?.email ?? '');
      await prefs.setString('uid', user!.uid);
      await prefs.setString('role', 'user');

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UserDashboard()));


    } catch (e) {
      setState(() {
        _error = "Login failed: ${e.toString()}";
      });
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 500),
          child: Container(
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Welcome to Proactive Portal",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("Login to continue",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),

                SizedBox(height: 32),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Manager Login", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                ),
                SizedBox(height: 12),

                TextField(
                  controller: _managerUsernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _managerPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _managerLogin,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text("Login as Manager"),
                  ),
                ),

                SizedBox(height: 24),
                Divider(),
                SizedBox(height: 24),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("User Login", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                ),
                SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _userLogin,
                    icon: Icon(Icons.login),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    label: Text("Login with Google"),
                  ),
                ),

                if (_error.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(_error, style: TextStyle(color: Colors.red)),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

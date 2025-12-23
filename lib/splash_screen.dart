import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import all the destination pages
import 'login_page.dart';
import 'admin_dashboard_page.dart';
import 'user_main_layout.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    // 1. Show the splash screen for at least 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    // 2. Check if a user is currently logged in
    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user == null) {
      // --- NOT LOGGED IN: Go to Login Page ---
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      // --- LOGGED IN: Check their Role in Database ---
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (mounted) {
          if (userDoc.exists && userDoc.get('role') == 'admin') {
            // -> Go to Admin Panel
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
            );
          } else {
            // -> Go to User App (Home/Quiz/Leaderboard)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserMainLayout()),
            );
          }
        }
      } catch (e) {
        // If there's an error (e.g., internet issue), go to Login Page
        print("Error fetching user role: $e");
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
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
            // --- YOUR LOGO ---
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 24),
            
            // --- APP NAME ---
            const Text(
              'Quiz App', 
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 48),
            
            // --- LOADING SPINNER ---
            const CircularProgressIndicator(
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
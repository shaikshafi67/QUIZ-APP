import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quize_app1/lib/admin_signup_page.dart';

// --- IMPORTS FOR NAVIGATION ---
import 'signup_page.dart';
import 'admin_dashboard_page.dart';
import 'user_main_layout.dart';
import 'logo_background.dart';
import 'admin_signup_page.dart'; // <-- THIS IS THE IMPORT YOU WERE MISSING

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  
  // State to track if we are in "Admin Mode"
  bool _isAdminMode = false; 

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    try {
      // 1. Sign In
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Check Role in Database
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (mounted) {
        if (userDoc.exists && userDoc['role'] == 'admin') {
          // If Admin -> Go to Admin Dashboard
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboardPage()));
        } else {
          // If User -> Go to User App (Home/Quiz/Leaderboard)
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const UserMainLayout()));
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login failed'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _toggleAdminMode() {
    setState(() {
      _isAdminMode = !_isAdminMode;
      // Clear fields when switching to avoid confusion
      _emailController.clear();
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Toggle Button (User <-> Admin)
          TextButton.icon(
            onPressed: _toggleAdminMode,
            icon: Icon(
              _isAdminMode ? Icons.person : Icons.admin_panel_settings, 
              color: Colors.grey
            ),
            label: Text(
              _isAdminMode ? "User Login" : "Admin Login", 
              style: const TextStyle(color: Colors.grey)
            ),
          )
        ],
      ),
      extendBodyBehindAppBar: true, 
      
      body: LogoBackground( 
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo.png', width: 100, height: 100),
                  const SizedBox(height: 24),
                  
                  // Title changes based on mode
                  Text(
                    _isAdminMode ? 'Admin Portal' : 'Welcome Back!',
                    style: TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.bold,
                      color: _isAdminMode ? Colors.redAccent : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isAdminMode 
                        ? 'Please enter your administrative credentials' 
                        : 'Log in to continue your quiz journey',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 48),
                  
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: _isAdminMode ? 'admin@gmail.com' : 'Enter your email',
                      prefixIcon: Icon(Icons.email, color: _isAdminMode ? Colors.redAccent : Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      focusedBorder: _isAdminMode ? OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                      ) : null,
                    ),
                    validator: (v) => (v == null || v.isEmpty || !v.contains('@')) ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 20),
                  
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock, color: _isAdminMode ? Colors.redAccent : Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      focusedBorder: _isAdminMode ? OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                      ) : null,
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () { setState(() { _isPasswordVisible = !_isPasswordVisible; }); },
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Password must be 6+ chars' : null,
                  ),
                  const SizedBox(height: 30),
                  
                  // Login Button
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isAdminMode ? Colors.redAccent : Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 3,
                          ),
                          child: Text(_isAdminMode ? 'Access Dashboard' : 'Login', style: const TextStyle(fontSize: 20)),
                        ),
                  const SizedBox(height: 20),
                  
                  // --- SWITCH LINK BASED ON MODE ---
                  if (!_isAdminMode)
                    // USER MODE: Link to User Sign Up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?", style: TextStyle(fontSize: 16)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage()));
                          },
                          child: const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ),
                      ],
                    )
                  else
                    // ADMIN MODE: Link to Admin Sign Up (with Secret Key)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("New Admin?", style: TextStyle(fontSize: 16)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSignUpPage()));
                          },
                          child: const Text('Register Here', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'logo_background.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPage();
}

class _SignUpPage extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _adminCodeController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  
  // --- IMAGE VARIABLES ---
  Uint8List? _imageBytes;
  bool _isImagePicked = false;

  final String _secretAdminKey = "12345"; 

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _isImagePicked = true;
      });
    }
  }

  Future<void> _signUpUser() async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorDialog("Please enter your Full Name");
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog("Passwords do not match!");
      return;
    }

    setState(() { _isLoading = true; });

    try {
      String role = 'user';
      if (_adminCodeController.text.trim().isNotEmpty) {
        if (_adminCodeController.text.trim() == _secretAdminKey) {
          role = 'admin'; 
        } else {
          _showErrorDialog("Invalid Admin Code.");
          setState(() { _isLoading = false; });
          return; 
        }
      }

      // 1. Create Auth User
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? newUser = userCredential.user;

      if (newUser != null) {
        await newUser.updateDisplayName(_nameController.text.trim());
        
        // 2. Upload Image (If selected)
        String photoUrl = '';
        if (_isImagePicked && _imageBytes != null) {
          try {
            final Reference storageRef = FirebaseStorage.instance
                .ref()
                .child('profile_images/${newUser.uid}.jpg');
            await storageRef.putData(_imageBytes!);
            photoUrl = await storageRef.getDownloadURL();
          } catch (e) {
            print("Error uploading image: $e");
          }
        }

        // 3. Save to Firestore
        await FirebaseFirestore.instance.collection('users').doc(newUser.uid).set({
          'fullName': _nameController.text.trim(),
          'email': newUser.email,
          'role': role,
          'photoUrl': photoUrl, // <-- Save the image URL
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        if (role == 'admin') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin Account Created!"), backgroundColor: Colors.green));
        }
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      setState(() { _isLoading = false; });
      _showErrorDialog(e.message ?? 'Registration failed');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Up Failed'),
        content: Text(message),
        actions: [ TextButton(child: const Text('Okay'), onPressed: () { Navigator.of(ctx).pop(); }) ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: LogoBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // --- PROFILE IMAGE PICKER ---
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                          child: _isImagePicked
                              ? ClipOval(child: Image.memory(_imageBytes!, fit: BoxFit.cover))
                              : const Icon(Icons.person, size: 60, color: Colors.grey),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                            child: const Icon(Icons.add_a_photo, size: 20, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text("Add Profile Photo", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  // Text Fields
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Full Name', prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () { setState(() { _obscurePassword = !_obscurePassword; }); }),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white.withOpacity(0.9)
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility), onPressed: () { setState(() { _obscureConfirmPassword = !_obscureConfirmPassword; }); }),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.white.withOpacity(0.9)
                    ),
                  ),
                  
                  // Admin Code Section
                  const SizedBox(height: 24),
                  const Divider(),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text("For Admins Only (Optional)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                  TextFormField(
                    controller: _adminCodeController,
                    decoration: InputDecoration(labelText: 'Admin Secret Code', prefixIcon: const Icon(Icons.security, color: Colors.redAccent), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)), filled: true, fillColor: Colors.white.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 24),
                  
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _signUpUser,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Sign Up', style: TextStyle(fontSize: 18)),
                        ),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("Already have an account?"), TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold)))]),
                  const SizedBox(height: 20), 
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AdminSignUpPage extends StatefulWidget {
  const AdminSignUpPage({super.key});

  @override
  State<AdminSignUpPage> createState() => _AdminSignUpPageState();
}

class _AdminSignUpPageState extends State<AdminSignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _secretKeyController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- IMAGE VARIABLES ---
  Uint8List? _imageBytes;
  bool _isImagePicked = false;

  final String _masterAdminKey = "12345"; 

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

  Future<void> _registerAdmin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_secretKeyController.text.trim() != _masterAdminKey) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⛔ ACCESS DENIED: Incorrect Master Key'), backgroundColor: Colors.red));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Upload Image if selected
      String photoUrl = '';
      if (_isImagePicked && _imageBytes != null) {
        try {
          final Reference storageRef = FirebaseStorage.instance.ref().child('profile_images/${userCredential.user!.uid}.jpg');
          await storageRef.putData(_imageBytes!);
          photoUrl = await storageRef.getDownloadURL();
        } catch (e) { print("Error uploading image: $e"); }
      }

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'admin',
        'photoUrl': photoUrl, // <-- Save URL
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Admin Account Created! Please Login.'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Error'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text("New Admin Registration", style: TextStyle(color: Colors.white)), iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // --- IMAGE PICKER ---
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle, border: Border.all(color: Colors.redAccent, width: 2)),
                        child: _isImagePicked
                            ? ClipOval(child: Image.memory(_imageBytes!, fit: BoxFit.cover))
                            : const Icon(Icons.person, size: 60, color: Colors.white54),
                      ),
                      Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), child: const Icon(Icons.add_a_photo, size: 20, color: Colors.white))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                _buildTextField(controller: _nameController, label: 'Full Name', icon: Icons.person),
                const SizedBox(height: 16),
                _buildTextField(controller: _emailController, label: 'Email', icon: Icons.email),
                const SizedBox(height: 16),
                _buildTextField(controller: _passwordController, label: 'Password', icon: Icons.lock, isPassword: true),
                const SizedBox(height: 24),
                const Divider(color: Colors.white24),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _secretKeyController,
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(labelText: 'Master Key (Required)', labelStyle: const TextStyle(color: Colors.redAccent), prefixIcon: const Icon(Icons.vpn_key, color: Colors.redAccent), enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.redAccent), borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.red, width: 2), borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.redAccent.withOpacity(0.1)),
                  validator: (v) => v!.isEmpty ? 'Master Key is required' : null,
                ),
                const SizedBox(height: 32),
                _isLoading ? const CircularProgressIndicator(color: Colors.redAccent) : SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _registerAdmin, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('REGISTER ADMIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false}) {
    return TextFormField(
      controller: controller, obscureText: isPassword, style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white70), prefixIcon: Icon(icon, color: Colors.white70), enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white38), borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(12))),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }
}
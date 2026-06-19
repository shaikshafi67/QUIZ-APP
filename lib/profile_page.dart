import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'main.dart';
import 'logo_background.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _photoUrl;
  String _fullName = "Loading...";
  String _role = "Loading...";
  String _email = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    setState(() => _email = user.email ?? '');

    try {
      final data = await supabase
          .from('users')
          .select('full_name, role, photo_url')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        setState(() {
          _fullName = data['full_name'] ?? 'User';
          _role = data['role'] ?? 'user';
          _photoUrl = data['photo_url'];
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  Future<void> _uploadProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 600,
    );
    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final Uint8List imageBytes = await image.readAsBytes();
      final path = 'profiles/${user.id}.jpg';

      await supabase.storage.from('app-images').uploadBinary(
            path,
            imageBytes,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg', upsert: true),
          );

      final downloadUrl =
          supabase.storage.from('app-images').getPublicUrl(path);

      await supabase
          .from('users')
          .update({'photo_url': downloadUrl}).eq('id', user.id);

      setState(() {
        _photoUrl = downloadUrl;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated!')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: LogoBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 4),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withAlpha(128),
                            blurRadius: 10,
                            spreadRadius: 2)
                      ],
                    ),
                    child: ClipOval(
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : (_photoUrl != null && _photoUrl!.isNotEmpty)
                              ? Image.network(_photoUrl!, fit: BoxFit.cover)
                              : const Icon(Icons.person,
                                  size: 80, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _uploadProfilePicture,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            color: Colors.blue, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _fullName.toUpperCase(),
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(_role.toUpperCase()),
                backgroundColor: _role == 'admin'
                    ? Colors.red.shade100
                    : Colors.blue.shade100,
                labelStyle: TextStyle(
                    color: _role == 'admin' ? Colors.red : Colors.blue,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_email,
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';
import 'login_page.dart';
import 'main.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});
  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage>
    with SingleTickerProviderStateMixin {
  // ── Profile controllers ──
  final _nameCtrl     = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();

  // ── Edit-mode state ──
  bool   _isEditing  = false;
  String _origName = '', _origUsername = '', _origPhone = '';

  // ── Photo ──
  String     _photoUrl = '';
  Uint8List? _picBytes;
  bool       _hasPic   = false;

  // ── Password reset – 3-step ──
  int  _pwStep        = 0; // 0=trigger, 1=otp, 2=new pass
  bool _obscureNew    = true;
  bool _obscureConf   = true;
  final _newPassCtrl  = TextEditingController();
  final _confPassCtrl = TextEditingController();
  final List<TextEditingController> _otpCtls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpNodes =
      List.generate(6, (_) => FocusNode());

  // ── Loading ──
  bool _initialLoading = true;
  bool _savingProfile  = false;
  bool _savingPhoto    = false;
  bool _sendingOtp     = false;
  bool _resendingOtp   = false;
  bool _verifyingOtp   = false;
  bool _savingPass     = false;

  String? _uid;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _loadProfile();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in [
      _nameCtrl, _usernameCtrl, _emailCtrl,
      _phoneCtrl, _newPassCtrl, _confPassCtrl
    ]) { c.dispose(); }
    for (final c in _otpCtls) { c.dispose(); }
    for (final f in _otpNodes) { f.dispose(); }
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Data
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    _uid = supabase.auth.currentUser?.id;
    if (_uid == null) return;
    try {
      final data = await supabase
          .from('users')
          .select('full_name, username, email, phone, photo_url')
          .eq('id', _uid!)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _nameCtrl.text     = data?['full_name'] ?? '';
          _usernameCtrl.text = data?['username']  ?? '';
          _emailCtrl.text    = data?['email']     ?? '';
          _phoneCtrl.text    = data?['phone']     ?? '';
          _photoUrl          = data?['photo_url'] ?? '';
          _initialLoading    = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _initialLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Profile actions
  // ─────────────────────────────────────────────────────────────────────────────

  void _startEdit() {
    _origName     = _nameCtrl.text;
    _origUsername = _usernameCtrl.text;
    _origPhone    = _phoneCtrl.text;
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    _nameCtrl.text     = _origName;
    _usernameCtrl.text = _origUsername;
    _phoneCtrl.text    = _origPhone;
    setState(() => _isEditing = false);
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { _snack('Name cannot be empty', error: true); return; }
    if (_uid == null) return;
    setState(() => _savingProfile = true);
    try {
      await supabase.from('users').update({
        'full_name': name,
        'username':  _usernameCtrl.text.trim(),
        'phone':     _phoneCtrl.text.trim(),
      }).eq('id', _uid!);
      if (mounted) {
        setState(() => _isEditing = false);
        _snack('Profile updated!');
      }
    } catch (e) {
      _snack('Failed to update: $e', error: true);
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Photo actions
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 400);
    if (img == null) return;
    final bytes = await img.readAsBytes();
    if (mounted) setState(() { _picBytes = bytes; _hasPic = true; });
  }

  Future<void> _uploadPhoto() async {
    if (_picBytes == null || _uid == null) return;
    setState(() => _savingPhoto = true);
    try {
      final path = 'profiles/$_uid.jpg';
      await supabase.storage.from('app-images').uploadBinary(
        path, _picBytes!,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );
      final url = supabase.storage.from('app-images').getPublicUrl(path);
      await supabase.from('users').update({'photo_url': url}).eq('id', _uid!);
      if (mounted) {
        setState(() { _photoUrl = url; _picBytes = null; _hasPic = false; });
        _snack('Photo updated!');
      }
    } catch (e) {
      _snack('Upload failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _savingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    final ok = await _confirm('Remove Photo',
        'Your profile photo will be permanently removed.');
    if (!ok || _uid == null) return;
    setState(() => _savingPhoto = true);
    try {
      await supabase.storage.from('app-images').remove(['profiles/$_uid.jpg']);
      await supabase.from('users').update({'photo_url': ''}).eq('id', _uid!);
      if (mounted) {
        setState(() { _photoUrl = ''; _picBytes = null; _hasPic = false; });
        _snack('Photo removed.');
      }
    } catch (e) {
      _snack('Failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _savingPhoto = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Password OTP steps
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _sendResetOtp() async {
    setState(() => _sendingOtp = true);
    try {
      await supabase.auth.resetPasswordForEmail(_emailCtrl.text.trim());
      if (mounted) {
        setState(() => _pwStep = 1);
        _snack('OTP sent to ${_emailCtrl.text.trim()}');
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => _otpNodes[0].requestFocus());
      }
    } on AuthException catch (e) {
      _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _resendingOtp = true);
    try {
      await supabase.auth.resetPasswordForEmail(_emailCtrl.text.trim());
      _snack('OTP resent!');
    } on AuthException catch (e) {
      _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _resendingOtp = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtls.map((c) => c.text).join();
    if (otp.length < 6) { _snack('Enter all 6 digits', error: true); return; }
    setState(() => _verifyingOtp = true);
    try {
      await supabase.auth.verifyOTP(
        email: _emailCtrl.text.trim(),
        token: otp,
        type: OtpType.recovery,
      );
      if (mounted) {
        for (final c in _otpCtls) { c.clear(); }
        setState(() => _pwStep = 2);
        _snack('OTP verified! Set your new password.');
      }
    } on AuthException catch (e) {
      _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _verifyingOtp = false);
    }
  }

  Future<void> _saveNewPassword() async {
    final np = _newPassCtrl.text.trim();
    final cp = _confPassCtrl.text.trim();
    if (np.length < 6) { _snack('Min 6 characters', error: true); return; }
    if (np != cp)       { _snack('Passwords do not match', error: true); return; }
    setState(() => _savingPass = true);
    try {
      await supabase.auth.updateUser(UserAttributes(password: np));
      if (mounted) {
        _newPassCtrl.clear(); _confPassCtrl.clear();
        setState(() => _pwStep = 0);
        _snack('Password changed successfully!');
      }
    } on AuthException catch (e) {
      _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _savingPass = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Logout
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    final ok = await _confirm('Logout', 'Are you sure you want to logout?');
    if (!ok) return;
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: error ? const Color(0xFFE74C3C) : const Color(0xFF27AE60),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<bool> _confirm(String title, String body) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(body,
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final name     = _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Admin';
    final initial  = name[0].toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: _buildAppBar(),
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : GradientBackground(
              child: FadeTransition(
                opacity: _animCtrl,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: Column(children: [
                    // ── Hero avatar section ──
                    _HeroSection(
                      photoUrl: _hasPic && _picBytes != null ? '' : _photoUrl,
                      picBytes: _picBytes,
                      initial:  initial,
                      name:     name,
                      email:    _emailCtrl.text,
                    ),
                    const SizedBox(height: 20),

                    // ── Photo card ──
                    _buildPhotoCard(),
                    const SizedBox(height: 16),

                    // ── Profile info card ──
                    _buildProfileCard(),
                    const SizedBox(height: 16),

                    // ── Security card ──
                    _buildSecurityCard(),
                    const SizedBox(height: 24),

                    // ── Logout ──
                    _buildLogoutBtn(),
                  ]),
                ),
              ),
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A3E),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Admin Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
              fontSize: 18)),
      actions: [
        if (!_isEditing)
          TextButton.icon(
            onPressed: _startEdit,
            icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.cyan),
            label: const Text('Edit', style: TextStyle(color: AppColors.cyan,
                fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ─── Photo card ───────────────────────────────────────────────────────────────

  Widget _buildPhotoCard() {
    return _Card(
      icon:  Icons.photo_camera_outlined,
      title: 'Profile Photo',
      child: Column(children: [
        // Preview
        if (_hasPic && _picBytes != null) ...[
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                  image: MemoryImage(_picBytes!), fit: BoxFit.cover),
              boxShadow: [
                BoxShadow(color: AppColors.purple.withValues(alpha: 0.3),
                    blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        Row(children: [
          // Change / Pick
          Expanded(
            child: _GradBtn(
              label: _hasPic ? 'Upload Photo' : 'Change Photo',
              icon:  _hasPic ? Icons.upload_rounded : Icons.photo_library_outlined,
              colors: AppColors.primaryGradient,
              loading: _hasPic && _savingPhoto,
              onTap: _hasPic ? _uploadPhoto : _pickPhoto,
              small: true,
            ),
          ),

          // Remove (only if has existing or new photo)
          if (_photoUrl.isNotEmpty || _hasPic) ...[
            const SizedBox(width: 10),
            Expanded(
              child: _GradBtn(
                label: 'Remove',
                icon:  Icons.delete_outline_rounded,
                colors: const [Color(0xFFE74C3C), Color(0xFFC0392B)],
                loading: !_hasPic && _savingPhoto,
                onTap: _hasPic
                    ? () => setState(() { _picBytes = null; _hasPic = false; })
                    : _removePhoto,
                small: true,
              ),
            ),
          ],
        ]),
      ]),
    );
  }

  // ─── Profile info card ────────────────────────────────────────────────────────

  Widget _buildProfileCard() {
    return _Card(
      icon:  Icons.person_outline_rounded,
      title: 'Profile Information',
      trailing: _isEditing
          ? null
          : IconButton(
              onPressed: _startEdit,
              icon: const Icon(Icons.edit_rounded,
                  color: AppColors.cyan, size: 18),
              tooltip: 'Edit Profile',
            ),
      child: Column(children: [
        _InfoField(
          label:    'Full Name',
          icon:     Icons.badge_outlined,
          ctrl:     _nameCtrl,
          editing:  _isEditing,
          required: true,
        ),
        _InfoField(
          label:   'Username',
          icon:    Icons.alternate_email_rounded,
          ctrl:    _usernameCtrl,
          editing: _isEditing,
          hint:    '@username',
        ),
        _InfoField(
          label:    'Email Address',
          icon:     Icons.email_outlined,
          ctrl:     _emailCtrl,
          editing:  false, // always read-only
          readOnly: true,
          hint:     'Cannot be changed',
        ),
        _InfoField(
          label:   'Mobile Number',
          icon:    Icons.phone_outlined,
          ctrl:    _phoneCtrl,
          editing: _isEditing,
          type:    TextInputType.phone,
          hint:    '+91 00000 00000',
          last:    true,
        ),

        // Save / Cancel (edit mode only)
        if (_isEditing) ...[
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: _GradBtn(
                label:   'Cancel',
                icon:    Icons.close_rounded,
                colors:  const [Color(0xFF636E72), Color(0xFF2D3436)],
                loading: false,
                onTap:   _cancelEdit,
                small:   true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _GradBtn(
                label:   'Save Changes',
                icon:    Icons.save_rounded,
                colors:  AppColors.primaryGradient,
                loading: _savingProfile,
                onTap:   _saveProfile,
                small:   true,
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  // ─── Security card ────────────────────────────────────────────────────────────

  Widget _buildSecurityCard() {
    return _Card(
      icon:  Icons.security_rounded,
      title: 'Security',
      child: _buildPasswordStep(),
    );
  }

  Widget _buildPasswordStep() {
    // Step 0 — trigger
    if (_pwStep == 0) {
      return Column(children: [
        const _SecurityInfoRow(
          icon:    Icons.lock_reset_rounded,
          color:   Color(0xFFFC5C7D),
          title:   'Reset Password',
          subtitle: 'An OTP will be sent to your registered email',
        ),
        const SizedBox(height: 16),
        _GradBtn(
          label:   'Send OTP to Email',
          icon:    Icons.send_rounded,
          colors:  const [Color(0xFFFC5C7D), Color(0xFF6A3093)],
          loading: _sendingOtp,
          onTap:   _sendResetOtp,
        ),
      ]);
    }

    // Step 1 — OTP entry
    if (_pwStep == 1) {
      return Column(children: [
        // Info banner
        _OtpBanner(email: _emailCtrl.text.trim()),
        const SizedBox(height: 20),

        // 6 digit boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            final filled = _otpCtls[i].text.isNotEmpty;
            return _OtpBox(
              ctrl:  _otpCtls[i],
              node:  _otpNodes[i],
              filled: filled,
              onChanged: (v) {
                if (v.isNotEmpty && i < 5) _otpNodes[i + 1].requestFocus();
                if (v.isEmpty   && i > 0) _otpNodes[i - 1].requestFocus();
                setState(() {});
              },
            );
          }),
        ),
        const SizedBox(height: 20),

        _GradBtn(
          label:   'Verify OTP',
          icon:    Icons.verified_rounded,
          colors:  const [Color(0xFFFC5C7D), Color(0xFF6A3093)],
          loading: _verifyingOtp,
          onTap:   _verifyOtp,
        ),
        const SizedBox(height: 14),

        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TextButton(
            onPressed: () => setState(() {
              _pwStep = 0;
              for (final c in _otpCtls) { c.clear(); }
            }),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton.icon(
            onPressed: _resendingOtp ? null : _resendOtp,
            icon: _resendingOtp
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFFC5C7D)))
                : const Icon(Icons.refresh_rounded, size: 16,
                    color: Color(0xFFFC5C7D)),
            label: const Text('Resend OTP',
                style: TextStyle(color: Color(0xFFFC5C7D),
                    fontWeight: FontWeight.bold)),
          ),
        ]),
      ]);
    }

    // Step 2 — new password
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Success banner
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF27AE60).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF27AE60).withValues(alpha: 0.30)),
        ),
        child: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF27AE60), size: 18),
          SizedBox(width: 10),
          Expanded(child: Text('OTP verified! Set your new password.',
              style: TextStyle(color: Colors.white70, fontSize: 12))),
        ]),
      ),
      const SizedBox(height: 16),

      _PassField(
        ctrl:    _newPassCtrl,
        label:   'New Password',
        obscure: _obscureNew,
        onToggle: () => setState(() => _obscureNew = !_obscureNew),
      ),
      const SizedBox(height: 12),
      _PassField(
        ctrl:    _confPassCtrl,
        label:   'Confirm Password',
        obscure: _obscureConf,
        onToggle: () => setState(() => _obscureConf = !_obscureConf),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 4, top: 6, bottom: 16),
        child: Text('Minimum 6 characters',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11)),
      ),

      _GradBtn(
        label:   'Save New Password',
        icon:    Icons.lock_rounded,
        colors:  const [Color(0xFF11998E), Color(0xFF38EF7D)],
        loading: _savingPass,
        onTap:   _saveNewPassword,
      ),
      const SizedBox(height: 10),
      Center(
        child: TextButton(
          onPressed: () => setState(() => _pwStep = 0),
          child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
        ),
      ),
    ]);
  }

  // ─── Logout button ────────────────────────────────────────────────────────────

  Widget _buildLogoutBtn() {
    return _GradBtn(
      label:  'Logout',
      icon:   Icons.logout_rounded,
      colors: const [Color(0xFFE74C3C), Color(0xFFC0392B)],
      loading: false,
      onTap:  _logout,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final String photoUrl, initial, name, email;
  final Uint8List? picBytes;
  const _HeroSection({
    required this.photoUrl, required this.picBytes,
    required this.initial,  required this.name, required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(children: [
        // Avatar ring
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                colors: [AppColors.purple, AppColors.cyan],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Container(
            width: 90, height: 90,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.darkBg,
            ),
            child: ClipOval(
              child: picBytes != null
                  ? Image.memory(picBytes!, fit: BoxFit.cover)
                  : photoUrl.isNotEmpty
                      ? Image.network(photoUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _Initial(initial))
                      : _Initial(initial),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(name,
            style: const TextStyle(
                color: Colors.white, fontSize: 22,
                fontWeight: FontWeight.bold, letterSpacing: 0.3)),
        const SizedBox(height: 4),
        Text(email,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFC5C7D), Color(0xFF6A3093)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('ADMINISTRATOR',
              style: TextStyle(color: Colors.white, fontSize: 10,
                  fontWeight: FontWeight.w800, letterSpacing: 2)),
        ),
      ]),
    );
  }
}

class _Initial extends StatelessWidget {
  final String letter;
  const _Initial(this.letter);
  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.darkCard,
        alignment: Alignment.center,
        child: Text(letter,
            style: const TextStyle(color: Colors.white, fontSize: 34,
                fontWeight: FontWeight.bold)),
      );
}

// ─── Card wrapper ─────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;
  const _Card({required this.icon, required this.title,
      required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Text(title,
              style: const TextStyle(color: Colors.white,
                  fontSize: 15, fontWeight: FontWeight.bold)),
          if (trailing != null) ...[const Spacer(), trailing!],
        ]),
        Divider(color: Colors.white.withValues(alpha: 0.08), height: 24),
        child,
      ]),
    );
  }
}

// ─── Info field (read/edit) ───────────────────────────────────────────────────

class _InfoField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController ctrl;
  final bool editing;
  final bool readOnly;
  final bool required;
  final bool last;
  final String? hint;
  final TextInputType? type;

  const _InfoField({
    required this.label,
    required this.icon,
    required this.ctrl,
    required this.editing,
    this.readOnly  = false,
    this.required  = false,
    this.last      = false,
    this.hint,
    this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = editing && !readOnly;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: isActive
          // ── Edit mode ──
          ? TextFormField(
              controller: ctrl,
              keyboardType: type,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                prefixIcon: Icon(icon, color: AppColors.purple, size: 18),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.purple, width: 1.8)),
              ),
            )
          // ── Read mode ──
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11, fontWeight: FontWeight.w600,
                      letterSpacing: 0.8)),
              const SizedBox(height: 6),
              Row(children: [
                Icon(icon,
                    color: readOnly
                        ? Colors.white30
                        : AppColors.purple,
                    size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ctrl.text.isNotEmpty ? ctrl.text : (hint ?? '—'),
                    style: TextStyle(
                        color: ctrl.text.isNotEmpty
                            ? Colors.white
                            : Colors.white30,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                if (readOnly)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('read-only',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.30),
                            fontSize: 10)),
                  ),
              ]),
              if (!last)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Divider(height: 1,
                      color: Colors.white.withValues(alpha: 0.07)),
                ),
            ]),
    );
  }
}

// ─── Password field ───────────────────────────────────────────────────────────

class _PassField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  const _PassField({
    required this.ctrl, required this.label,
    required this.obscure, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: Color(0xFFFC5C7D), size: 18),
        suffixIcon: IconButton(
          icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.white38, size: 18),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFFFC5C7D), width: 1.8)),
      ),
    );
  }
}

// ─── Security info row ────────────────────────────────────────────────────────

class _SecurityInfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  const _SecurityInfoRow({
    required this.icon, required this.color,
    required this.title, required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 3),
            Text(subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }
}

// ─── OTP banner ──────────────────────────────────────────────────────────────

class _OtpBanner extends StatelessWidget {
  final String email;
  const _OtpBanner({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        const Icon(Icons.mark_email_read_outlined,
            color: AppColors.purple, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text('OTP sent to $email',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}

// ─── OTP box ──────────────────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode node;
  final bool filled;
  final void Function(String) onChanged;
  const _OtpBox({
    required this.ctrl, required this.node,
    required this.filled, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44, height: 52,
      child: TextFormField(
        controller: ctrl,
        focusNode:  node,
        textAlign:  TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold,
            color: filled ? const Color(0xFFFC5C7D) : Colors.white),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: filled
              ? const Color(0xFFFC5C7D).withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.06),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: filled
                      ? const Color(0xFFFC5C7D).withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.12),
                  width: filled ? 1.5 : 1)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFFFC5C7D), width: 2.5)),
        ),
      ),
    );
  }
}

// ─── Gradient button ──────────────────────────────────────────────────────────

class _GradBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final bool loading;
  final VoidCallback onTap;
  final bool small;
  const _GradBtn({
    required this.label, required this.icon, required this.colors,
    required this.loading, required this.onTap, this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: small ? 44 : 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: colors.first.withValues(alpha: 0.30),
                blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.2))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, color: Colors.white, size: small ? 16 : 18),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: small ? 12 : 14,
                        letterSpacing: 0.4)),
              ]),
      ),
    );
  }
}

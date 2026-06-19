import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'admin_dashboard_page.dart';
import 'user_main_layout.dart';

const _kBlue1 = Color(0xFF4776E6);
const _kBlue2 = Color(0xFF8E54E9);
const _kRed1  = Color(0xFFc0392b);
const _kRed2  = Color(0xFFe74c3c);
const _kGold1 = Color(0xFFf7971e);
const _kGold2 = Color(0xFFffd200);
const _kBg    = Color(0xFFF0F4FF);

class OtpVerificationPage extends StatefulWidget {
  final String email;
  final String fullName;
  final String role;
  final String userId;
  final Uint8List? picBytes;

  const OtpVerificationPage({
    super.key,
    required this.email,
    required this.fullName,
    required this.role,
    required this.userId,
    this.picBytes,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _ctls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  bool _isLoading  = false;
  bool _isResending = false;
  late AnimationController _bgCtrl;

  Color get c1 => widget.role == 'admin' ? _kRed1 : _kBlue1;
  Color get c2 => widget.role == 'admin' ? _kRed2 : _kBlue2;

  String get _otp => _ctls.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    // Auto-focus first box
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _nodes[0].requestFocus());
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    for (final c in _ctls) { c.dispose(); }
    for (final f in _nodes) { f.dispose(); }
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otp;
    if (otp.length < 6) {
      _snack('Enter all 6 digits', error: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await supabase.auth.verifyOTP(
        email: widget.email,
        token: otp,
        type: OtpType.signup,
      );

      // Upload profile picture if provided
      String photoUrl = '';
      if (widget.picBytes != null) {
        final path = 'profiles/${widget.userId}.jpg';
        await supabase.storage.from('app-images').uploadBinary(
          path,
          widget.picBytes!,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
        photoUrl = supabase.storage.from('app-images').getPublicUrl(path);
      }

      // Insert user record after successful verification
      await supabase.from('users').upsert({
        'id': widget.userId,
        'full_name': widget.fullName,
        'email': widget.email,
        'role': widget.role,
        'photo_url': photoUrl,
      });

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => widget.role == 'admin'
              ? const AdminDashboardPage()
              : const UserMainLayout(),
        ),
        (_) => false,
      );
    } on AuthException catch (e) {
      _snack(e.message, error: true);
    } catch (e) {
      _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );
      _snack('Code resent to ${widget.email}');
    } on AuthException catch (e) {
      _snack(e.message, error: true);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _onDigitChanged(int i, String val) {
    if (val.isNotEmpty && i < 5) {
      _nodes[i + 1].requestFocus();
    } else if (val.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
    }
    // Auto-submit when last digit filled
    if (i == 5 && val.isNotEmpty && _otp.length == 6) {
      _verify();
    }
    setState(() {}); // update styling
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(children: [
        // Animated blobs
        AnimatedBuilder(
          animation: _bgCtrl,
          builder: (_, __) {
            final t = _bgCtrl.value;
            return Stack(children: [
              Positioned(
                top:   -60 + 40 * sin(t * pi),
                right: -60 + 30 * cos(t * pi),
                child: _Blob(size: 260, color: c1.withValues(alpha: 0.18)),
              ),
              Positioned(
                bottom: -40 + 30 * cos(t * pi),
                left:   -40 + 40 * sin(t * pi + 1),
                child: _Blob(size: 220, color: c2.withValues(alpha: 0.14)),
              ),
              Positioned(
                top:   MediaQuery.of(context).size.height * 0.5 + 50 * sin(t * pi + 2),
                right: 60 + 30 * cos(t * pi + 1),
                child: _Blob(size: 120, color: _kGold1.withValues(alpha: 0.10)),
              ),
            ]);
          },
        ),

        // Content
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                        color: c1.withValues(alpha: 0.22),
                        blurRadius: 48, offset: const Offset(0, 16)),
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // ── Gradient header ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [c1, c2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(children: [
                      // Icon with ring
                      Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.40),
                              width: 2),
                        ),
                        child: const Icon(Icons.mark_email_read_outlined,
                            color: Colors.white, size: 34),
                      ),
                      const SizedBox(height: 18),
                      const Text('Check Your Email',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3)),
                      const SizedBox(height: 10),
                      Text(
                        'We sent a 6-digit code to',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.80),
                            fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.email,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ]),
                  ),

                  // ── OTP input + actions ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
                    child: Column(children: [
                      // 6 digit boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (i) {
                          final filled = _ctls[i].text.isNotEmpty;
                          return SizedBox(
                            width: 44,
                            height: 54,
                            child: TextFormField(
                              controller: _ctls[i],
                              focusNode: _nodes[i],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              onChanged: (v) => _onDigitChanged(i, v),
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: c1),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: filled
                                    ? c1.withValues(alpha: 0.07)
                                    : const Color(0xFFF7F8FC),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade200)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: filled ? c1 : Colors.grey.shade300,
                                        width: filled ? 1.5 : 1)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        BorderSide(color: c1, width: 2.5)),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 36),

                      // Verify button
                      GestureDetector(
                        onTap: _isLoading ? null : _verify,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 52,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [_kGold1, _kGold2]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: _kGold1.withValues(alpha: 0.40),
                                  blurRadius: 18,
                                  offset: const Offset(0, 7)),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : const Text('VERIFY & CONTINUE',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      letterSpacing: 1.8)),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Resend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Didn't receive the code?  ",
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13)),
                          GestureDetector(
                            onTap: _isResending ? null : _resend,
                            child: _isResending
                                ? SizedBox(
                                    width: 14, height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: c1))
                                : Text('Resend',
                                    style: TextStyle(
                                        color: c1,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        decorationColor: c1)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Back
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 13, color: Colors.grey.shade500),
                        label: Text('Back to Sign Up',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

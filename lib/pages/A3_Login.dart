import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/auth_service.dart';


class LoginPage extends StatefulWidget {
  final VoidCallback onCreateAccount;
  const LoginPage({super.key, required this.onCreateAccount});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _auth = AuthService();
  bool _hide = true;
  bool _loading = false;

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      _msg(e.message ?? 'Something went wrong');
    } catch (e) {
      _msg(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _forgot() async {
    if (_email.text.trim().isEmpty) {
      _msg('Enter your email first');
      return;
    }
    await _run(() async {
      await _auth.resetPassword(_email.text);
      _msg('Password reset email sent');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                          color: kTealLight, shape: BoxShape.circle),
                      child: const Icon(Icons.location_on_outlined,
                          color: kTeal, size: 32),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text('Welcome back',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: kTextDark)),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text('Log in to see your reminders',
                        style: TextStyle(color: kTextGrey, fontSize: 15)),
                  ),
                  const SizedBox(height: 30),
                  const FieldLabel('Email'),
                  AppField(
                    controller: _email,
                    hint: 'name@example.com',
                    icon: Icons.chat_bubble_outline,
                    keyboard: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  const FieldLabel('Password'),
                  AppField(
                    controller: _pass,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    obscure: _hide,
                    suffix: IconButton(
                      icon: Icon(
                          _hide
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: kTextGrey),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgot,
                      child: const Text('Forgot password?',
                          style: TextStyle(
                              color: kTeal, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  PrimaryButton(
                    text: 'Log in',
                    loading: _loading,
                    onTap: () =>
                        _run(() => _auth.login(_email.text, _pass.text)),
                  ),
                  const SizedBox(height: 22),
                  Row(children: const [
                    Expanded(child: Divider(color: kBorder)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text('or', style: TextStyle(color: kTextGrey)),
                    ),
                    Expanded(child: Divider(color: kBorder)),
                  ]),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kBorder),
                        shape: const StadiumBorder(),
                      ),
                      onPressed:
                          _loading ? null : () => _run(_auth.googleLogin),
                      child: const Text('Continue with Google',
                          style: TextStyle(
                              color: kTextDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 60),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('New here?',
                          style: TextStyle(color: kTextGrey)),
                      TextButton(
  onPressed: widget.onCreateAccount,
  child: const Text('Create account',
      style: TextStyle(color: kTeal, fontWeight: FontWeight.w700)),
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

// ---------- Shared widgets (register page pan hech vaparto) ----------

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(color: kTextGrey, fontSize: 14)),
      );
}

class AppField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboard;

  const AppField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboard,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9AA0A6)),
        prefixIcon: Icon(icon, color: kTextGrey),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kTeal, width: 1.6),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool loading;
  const PrimaryButton(
      {super.key,
      required this.text,
      required this.onTap,
      this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: kTeal,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        onPressed: loading ? null : onTap,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : Text(text,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
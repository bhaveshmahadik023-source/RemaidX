import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/auth_service.dart';
import 'A3_Login.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback onLogin;
  const RegisterPage({super.key, required this.onLogin});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final _auth = AuthService();
  bool _hide = true;
  bool _agree = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _register() async {
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty) {
      return _msg('Name and email are required');
    }
    if (_pass.text.length < 6) {
      return _msg('Password must be at least 6 characters');
    }
    if (_pass.text != _confirm.text) return _msg('Passwords do not match');
    if (!_agree) return _msg('Please accept the Terms and Privacy Policy');

    setState(() => _loading = true);
    try {
      await _auth.register(_name.text, _email.text, _pass.text);
    } on FirebaseAuthException catch (e) {
      _msg(e.message ?? 'Registration failed');
    } catch (e) {
      _msg(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onLogin,
        ),
        title: const Text('Create account',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('Name'),
                  AppField(
                      controller: _name,
                      hint: 'Your name',
                      icon: Icons.person_outline),
                  const SizedBox(height: 16),
                  const FieldLabel('Email'),
                  AppField(
                      controller: _email,
                      hint: 'name@example.com',
                      icon: Icons.chat_bubble_outline,
                      keyboard: TextInputType.emailAddress),
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
                  const SizedBox(height: 16),
                  const FieldLabel('Confirm password'),
                  AppField(
                      controller: _confirm,
                      hint: 'Repeat password',
                      icon: Icons.lock_outline,
                      obscure: _hide),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Checkbox(
                        value: _agree,
                        activeColor: kTeal,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)),
                        onChanged: (v) => setState(() => _agree = v ?? false),
                      ),
                      const Expanded(
                          child:
                              Text('I agree to the Terms and Privacy Policy')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                      text: 'Create account',
                      loading: _loading,
                      onTap: _register),
                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already registered?',
                          style: TextStyle(color: kTextGrey)),
                      TextButton(
                        onPressed: widget.onLogin,
                        child: const Text('Log in',
                            style: TextStyle(
                                color: kTeal, fontWeight: FontWeight.w700)),
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
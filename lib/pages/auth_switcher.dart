import 'package:flutter/material.dart';
import 'A3_Login.dart';
import 'A4_Sign_up.dart';

class AuthSwitcher extends StatefulWidget {
  const AuthSwitcher({super.key});
  @override
  State<AuthSwitcher> createState() => _AuthSwitcherState();
}

class _AuthSwitcherState extends State<AuthSwitcher> {
  bool _showRegister = false;

  @override
  Widget build(BuildContext context) {
    return _showRegister
        ? RegisterPage(onLogin: () => setState(() => _showRegister = false))
        : LoginPage(
            onCreateAccount: () => setState(() => _showRegister = true));
  }
}

import 'package:flutter/material.dart';
import 'package:remindx/A1__wlcome.dart';
import 'package:remindx/pages/A3_Login.dart';
import 'package:remindx/pages/A4_Sign_up.dart';

class AuthSwitcher extends StatefulWidget {
  const AuthSwitcher({super.key});

  @override
  State<AuthSwitcher> createState() => _AuthSwitcherState();
}

class _AuthSwitcherState extends State<AuthSwitcher> {
  String _currentPage = 'welcome';

  @override
  Widget build(BuildContext context) {
    switch (_currentPage) {
      case 'signup':
        return RegisterPage(
          onLogin: () {
            setState(() {
              _currentPage = 'login';
            });
          },
        );

      case 'login':
        return A3_Login(
          onCreateAccount: () {
            setState(() {
              _currentPage = 'signup';
            });
          },
        );

      default:
        return welcomepage(
          onGetStarted: () {
            setState(() {
              _currentPage = 'signup';
            });
          },
          onLogin: () {
            setState(() {
              _currentPage = 'login';
            });
          },
        );
    }
  }
}

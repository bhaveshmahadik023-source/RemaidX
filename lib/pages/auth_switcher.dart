
import 'package:flutter/material.dart';
import 'package:remindx/A1__wlcome.dart';
import 'package:remindx/pages/A3_Login.dart';
import 'package:remindx/pages/A4_Sign_up.dart';

class AuthSwitcher extends StatefulWidget {
  final String initialPage;

  const AuthSwitcher({
    super.key,
    this.initialPage = 'welcome',
  });

  @override
  State<AuthSwitcher> createState() => _AuthSwitcherState();
}

class _AuthSwitcherState extends State<AuthSwitcher> {
  late String _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
  }

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

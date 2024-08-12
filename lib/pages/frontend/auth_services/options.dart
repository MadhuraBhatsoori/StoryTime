import 'package:flutter/material.dart';
import 'package:storytime/pages/frontend/auth_services/login_page.dart';
import 'package:storytime/pages/frontend/auth_services/register_page.dart';

class Options extends StatefulWidget {
  const Options({Key? key}) : super(key: key);

  @override
  State<Options> createState() => _OptionsState();
}

class _OptionsState extends State<Options> {
  bool _showLoginPage = true;

  void toggleScreens() {
    setState(() {
      _showLoginPage = !_showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
  //Toggle between register and login page
    if (_showLoginPage) {
      return LoginPage(showRegisterPage: toggleScreens);
    } else {
      return RegisterPage(showLoginPage: toggleScreens);
    }
  }
}

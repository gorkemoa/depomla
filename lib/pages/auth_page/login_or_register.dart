import 'package:flutter/material.dart';

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {

bool showloginPage=true;

void togglePages(){
  setState(() {
    showloginPage=!showloginPage;
  });
}

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      
    );
  }
}
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:depomla/pages/login_page.dart';
import 'package:depomla/pages/profile_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:depomla/services/auth_service.dart';
import 'package:depomla/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DepomlaApp());
}

class DepomlaApp extends StatelessWidget {
  const DepomlaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamProvider<User?>.value(
      value: AuthService().authStateChanges(),
      initialData: null,
      catchError: (context, error) => null,
      child: MaterialApp(
        title: 'Depomla',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomePage(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/profile': (context) => const ProfilePage(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}
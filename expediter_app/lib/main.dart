import 'package:flutter/material.dart';
import 'package:expediter_app/screens/login_screen.dart';

void main() {
  runApp(const ExpediterApp());
}

class ExpediterApp extends StatelessWidget {
  const ExpediterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منصة معقب',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      // يبدأ التطبيق من شاشة تسجيل الدخول التي تنقلك لشاشة العميل الرئيسية
      home: const LoginScreen(),
    );
  }
}
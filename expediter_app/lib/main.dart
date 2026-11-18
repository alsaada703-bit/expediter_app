import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:expediter_app/screens/login_screen.dart';

void main() async {
  // التأكد من تهيئة أدوات فلاتر الأساسية قبل أي اتصال
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة اتصال Firebase مع التطبيق
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منصة معقب',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      // يبدأ التطبيق من شاشة تسجيل الدخول
      home: const LoginScreen(),
    );
  }
}
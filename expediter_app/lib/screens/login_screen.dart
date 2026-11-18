import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'client_home_screen.dart'; // استيراد مباشر وصحيح لأن الملفين في نفس المجلد

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  bool isLoading = false;

  void _handleNafathLogin() async {
    String idNumber = _idController.text.trim();

    // التحقق من أن رقم الهوية أو الإقامة صحيح (10 أرقام ويبدأ بـ 1 أو 2)
    if (idNumber.length != 10 || (!idNumber.startsWith('1') && !idNumber.startsWith('2'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رقم الهوية أو الإقامة غير صحيح (يجب أن يكون 10 أرقام ويبدأ بـ 1 أو 2)'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // توليد رقم عشوائي للمحاكاة (من 10 إلى 99)
      int randomCode = Random().nextInt(90) + 10;
      
      // محاكاة الاتصال والانتظار قليلاً
      await Future.delayed(const Duration(seconds: 2));

      // حفظ محاولة تسجيل الدخول والبيانات في Firestore
      await FirebaseFirestore.instance.collection('verified_users').add({
        'nationalId': idNumber,
        'randomCode': randomCode.toString(),
        'status': 'APPROVED',
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      // الانتقال المباشر إلى الصفحة الرئيسية بعد نجاح الحفظ
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ClientHomeScreen()),
      );

    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول - تطبيق معقب'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'تسجيل الدخول برقم الهوية',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _idController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'رقم الهوية الوطنية أو الإقامة',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _handleNafathLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('تحقق ودخول', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
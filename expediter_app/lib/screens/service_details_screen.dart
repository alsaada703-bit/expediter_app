import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceName;
  final String nationalId;

  const ServiceDetailsScreen({
    super.key,
    required this.serviceName,
    this.nationalId = '',
  });

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final _phoneController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPhone();
  }

  Future<void> _loadSavedPhone() async {
    if (widget.nationalId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(widget.nationalId)
          .get();
      if (doc.exists && mounted) {
        final savedPhone = (doc.data()?['phone'] ?? '').toString();
        if (savedPhone.isNotEmpty && _phoneController.text.isEmpty) {
          _phoneController.text = savedPhone;
        }
      }
    } catch (_) {
      // تجاهل في حال عدم وجود ملف شخصي محفوظ بعد
    }
  }

  Future<void> _submitRequest() async {
    final phone = _phoneController.text.trim();
    final details = _detailsController.text.trim();

    if (phone.length != 10 || !phone.startsWith('05')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال رقم جوال سعودي صحيح (يبدأ بـ 05 ومكون من 10 أرقام)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء كتابة تفاصيل المعاملة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('requests').add({
        'serviceName': widget.serviceName,
        'nationalId': widget.nationalId,
        'phone': phone,
        'details': details,
        'status': 'قيد المعالجة',
        'price': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // حفظ رقم الجوال تلقائياً للمرات القادمة
      if (widget.nationalId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('user_profiles')
            .doc(widget.nationalId)
            .set({
          'nationalId': widget.nationalId,
          'phone': phone,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال طلبك بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceName),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'طلب خدمة: ${widget.serviceName}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'أدخل بياناتك وتفاصيل المعاملة وسيتواصل معك المعقب فوراً.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: 'رقم الجوال للتواصل',
                  hintText: '05XXXXXXXX',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _detailsController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'تفاصيل المعاملة',
                  hintText: 'اكتب شرحاً مختصراً لطلبك...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'إرسال الطلب',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
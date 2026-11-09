import 'package:flutter/material.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final String serviceTitle;
  const ServiceDetailsScreen({Key? key, required this.serviceTitle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(serviceTitle)),
      body: Center(
        child: Text(
          'أهلاً بك في صفحة: $serviceTitle',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
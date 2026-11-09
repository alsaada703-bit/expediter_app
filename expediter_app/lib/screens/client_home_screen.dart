import 'package:flutter/material.dart';
import 'service_details_screen.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة معقب - الخدمات السريعة'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أهلاً بك، عبد الله',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'انجز طلباتك بسرعة وسهولة',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text(
              'الخدمات السريعة:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: ListView(
                children: [
                  _buildServiceCard(
                    context,
                    title: 'تخليص معاملات',
                    subtitle: 'إنجاز المراجعات والخطابات الرسمية',
                    icon: Icons.description,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ServiceDetailsScreen(serviceName: 'تخليص معاملات'),
                        ),
                      );
                    },
                  ),
                  _buildServiceCard(
                    context,
                    title: 'استمارات',
                    subtitle: 'تعبئة وتحديث النماذج الحكومية',
                    icon: Icons.assignment,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ServiceDetailsScreen(serviceName: 'استمارات'),
                        ),
                      );
                    },
                  ),
                  _buildServiceCard(
                    context,
                    title: 'الطلبات النشطة',
                    subtitle: 'متابعة حالة معاملاتك الحالية',
                    icon: Icons.hourglass_top,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('جاري تحميل الطلبات النشطة...')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, size: 30, color: Colors.blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
        onTap: onTap,
      ),
    );
  }
}
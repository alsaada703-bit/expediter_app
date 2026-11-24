import 'package:flutter/material.dart';
import 'service_details_screen.dart';
import 'active_requests_screen.dart';
import 'login_screen.dart';

class ClientHomeScreen extends StatelessWidget {
  final String nationalId;

  const ClientHomeScreen({
    super.key,
    this.nationalId = '',
  });

  Future<void> _openExpediterPanel(BuildContext context) async {
    final pinController = TextEditingController();
    const adminPin = '1234';

    final authorized = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('دخول لوحة المعقب'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          decoration: const InputDecoration(
            labelText: 'أدخل الرمز السري (1234)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text.trim() == adminPin) {
                Navigator.pop(dialogContext, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرمز السري غير صحيح!'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('دخول'),
          ),
        ],
      ),
    );

    if (authorized == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActiveRequestsScreen(
            isExpediter: true,
            nationalId: nationalId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'منصة معقب - الخدمات السريعة',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade400],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'أهلاً بك، عبد الله 👋',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nationalId.isNotEmpty
                        ? 'رقم الهوية المسجل: $nationalId'
                        : 'أنجز معاملاتك وطلباتك الحكومية بسرعة وموثوقية',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'الخدمات المتاحة:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  _buildServiceCard(
                    context,
                    title: 'تخليص معاملات',
                    subtitle: 'إنجاز المراجعات والخطابات الرسمية',
                    icon: Icons.description_outlined,
                    iconColor: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceDetailsScreen(
                            serviceName: 'تخليص معاملات',
                            nationalId: nationalId,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildServiceCard(
                    context,
                    title: 'استمارات',
                    subtitle: 'تعبئة وتحديث النماذج الحكومية',
                    icon: Icons.assignment_outlined,
                    iconColor: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceDetailsScreen(
                            serviceName: 'استمارات',
                            nationalId: nationalId,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildServiceCard(
                    context,
                    title: 'الطلبات النشطة',
                    subtitle: 'متابعة حالة معاملاتك الحالية مباشرة',
                    icon: Icons.hourglass_top_rounded,
                    iconColor: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActiveRequestsScreen(
                            isExpediter: false,
                            nationalId: nationalId,
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 28),
                  _buildServiceCard(
                    context,
                    title: 'لوحة تحكم المعقب',
                    subtitle: 'إدارة الطلبات، تحديث الحالات، والتواصل مع العملاء',
                    icon: Icons.admin_panel_settings_outlined,
                    iconColor: Colors.indigo,
                    onTap: () => _openExpediterPanel(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(icon, size: 28, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.arrow_forward_ios, size: 14, color: iconColor),
        ),
        onTap: onTap,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ActiveRequestsScreen extends StatefulWidget {
  final bool isExpediter;
  final String nationalId;

  const ActiveRequestsScreen({
    super.key,
    this.isExpediter = false,
    this.nationalId = '',
  });

  @override
  State<ActiveRequestsScreen> createState() => _ActiveRequestsScreenState();
}

class _ActiveRequestsScreenState extends State<ActiveRequestsScreen> {
  String _selectedFilter = 'الكل';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is! Timestamp) return 'الآن';
    final dt = timestamp.toDate().toLocal();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}/${dt.month}/${dt.day} - $hour:$minute';
  }

  String _formatPhoneForWhatsApp(String rawPhone) {
    String digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('05') && digits.length == 10) {
      digits = '966${digits.substring(1)}';
    } else if (digits.startsWith('5') && digits.length == 9) {
      digits = '966$digits';
    }
    return digits;
  }

  Future<void> _callPhone(BuildContext context, String phone) async {
    try {
      await launchUrl(Uri.parse('tel:$phone'));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إجراء الاتصال: $e')),
      );
    }
  }

  Future<void> _openWhatsApp(
    BuildContext context,
    String phone,
    String serviceName,
  ) async {
    final formattedPhone = _formatPhoneForWhatsApp(phone);
    final message = Uri.encodeComponent(
      'السلام عليكم، بخصوص طلبك في منصة معقب ($serviceName)...',
    );
    final uri = Uri.parse('https://wa.me/$formattedPhone?text=$message');

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح واتساب على هذا الجهاز'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء فتح واتساب: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    String docId,
    String currentStatus,
  ) async {
    final newStatus =
        currentStatus == 'قيد المعالجة' ? 'مكتمل' : 'قيد المعالجة';

    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(docId)
          .update({'status': newStatus});

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث حالة الطلب إلى: $newStatus'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء التحديث: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editPrice(
    BuildContext context,
    String docId,
    num currentPrice,
  ) async {
    final priceController = TextEditingController(
      text: currentPrice > 0 ? currentPrice.toString() : '',
    );

    final newPrice = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسعير المعاملة (ر.س)'),
        content: TextField(
          controller: priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'المبلغ بالريال السعودي',
            hintText: 'مثال: 150',
            prefixIcon: Icon(Icons.payments_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = double.tryParse(priceController.text.trim()) ?? 0;
              Navigator.pop(dialogContext, parsed);
            },
            child: const Text('حفظ السعر'),
          ),
        ],
      ),
    );

    if (newPrice == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(docId)
          .update({'price': newPrice});

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('تم تحديث السعر إلى ${newPrice.toStringAsFixed(0)} ر.س'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء حفظ السعر: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editAdminNote(
    BuildContext context,
    String docId,
    String currentNote,
  ) async {
    final noteController = TextEditingController(text: currentNote);

    final savedNote = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ملاحظة المعقب للعميل'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'مثال: تم رفع المعاملة، بانتظار سداد الرسوم...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, noteController.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (savedNote == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(docId)
          .update({'adminNote': savedNote});

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ ملاحظة المعقب'),
          backgroundColor: Colors.indigo,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء حفظ الملاحظة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmAndDelete(BuildContext context, String docId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من رغبتك في حذف هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await FirebaseFirestore.instance.collection('requests').doc(docId).delete();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف الطلب بنجاح'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء الحذف: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _selectedFilter = label),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isExpediter ? 'لوحة تحكم المعقب' : 'طلباتي النشطة',
        ),
        backgroundColor: widget.isExpediter ? Colors.indigo : Colors.blue,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data?.docs ?? [];
          final userDocs = (!widget.isExpediter && widget.nationalId.isNotEmpty)
              ? allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['nationalId'] == widget.nationalId;
                }).toList()
              : allDocs;

          final pendingCount = userDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['status'] ?? 'قيد المعالجة') == 'قيد المعالجة';
          }).length;
          final completedCount = userDocs.length - pendingCount;

          double totalRevenue = 0;
          for (final doc in userDocs) {
            final data = doc.data() as Map<String, dynamic>;
            if ((data['status'] ?? '') == 'مكتمل') {
              final p = data['price'];
              if (p is num) totalRevenue += p.toDouble();
            }
          }

          final q = _searchQuery.trim().toLowerCase();
          final filteredDocs = userDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'قيد المعالجة';
            final matchesStatus =
                _selectedFilter == 'الكل' || status == _selectedFilter;

            if (!matchesStatus) return false;
            if (q.isEmpty) return true;

            final serviceName =
                (data['serviceName'] ?? '').toString().toLowerCase();
            final phone = (data['phone'] ?? '').toString().toLowerCase();
            final details = (data['details'] ?? '').toString().toLowerCase();
            return serviceName.contains(q) ||
                phone.contains(q) ||
                details.contains(q);
          }).toList();

          return Column(
            children: [
              if (widget.isExpediter)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      _buildStatCard(
                          'الإجمالي', '${userDocs.length}', Colors.indigo),
                      const SizedBox(width: 6),
                      _buildStatCard(
                          'قيد المعالجة', '$pendingCount', Colors.orange),
                      const SizedBox(width: 6),
                      _buildStatCard(
                          'مكتملة', '$completedCount', Colors.green),
                      const SizedBox(width: 6),
                      _buildStatCard(
                        'الأرباح',
                        '${totalRevenue.toStringAsFixed(0)} ر.س',
                        Colors.teal,
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'ابحث برقم الجوال، الخدمة، أو التفاصيل...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFilterChip('الكل'),
                    _buildFilterChip('قيد المعالجة'),
                    _buildFilterChip('مكتمل'),
                  ],
                ),
              ),
              Expanded(
                child: filteredDocs.isEmpty
                    ? Center(
                        child: Text(
                          q.isNotEmpty
                              ? 'لا توجد نتائج مطابقة لبحثك'
                              : _selectedFilter == 'الكل'
                                  ? 'لا توجد طلبات حالياً'
                                  : 'لا توجد طلبات بحالة "$_selectedFilter"',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final docId = filteredDocs[index].id;
                          final data = filteredDocs[index].data()
                              as Map<String, dynamic>;
                          final serviceName =
                              data['serviceName'] ?? 'خدمة عامة';
                          final phone = data['phone'] ?? 'بدون رقم';
                          final details = data['details'] ?? 'بدون تفاصيل';
                          final adminNote =
                              (data['adminNote'] ?? '').toString();
                          final num price =
                              (data['price'] is num) ? data['price'] : 0;
                          final status = data['status'] ?? 'قيد المعالجة';
                          final createdAtText =
                              _formatTimestamp(data['createdAt']);
                          final isCompleted = status == 'مكتمل';

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          serviceName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: widget.isExpediter
                                            ? () => _updateStatus(
                                                context, docId, status)
                                            : null,
                                        child: Chip(
                                          label: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                status,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if (widget.isExpediter) ...[
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.swap_horiz,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            ],
                                          ),
                                          backgroundColor: isCompleted
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        createdAtText,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      if (price > 0) ...[
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.teal
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'الرسوم: ${price.toStringAsFixed(0)} ر.س',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text('رقم التواصل: $phone'),
                                      ),
                                      if (widget.isExpediter)
                                        IconButton(
                                          tooltip: 'اتصال مباشر',
                                          icon: const Icon(
                                            Icons.call,
                                            size: 18,
                                            color: Colors.green,
                                          ),
                                          onPressed: () =>
                                              _callPhone(context, phone),
                                        ),
                                      IconButton(
                                        tooltip: 'نسخ الرقم',
                                        icon: const Icon(
                                          Icons.copy,
                                          size: 18,
                                          color: Colors.blueGrey,
                                        ),
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(text: phone),
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text('تم نسخ رقم الجوال'),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.note_alt_outlined,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'التفاصيل: $details',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (adminNote.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.indigo
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Text(
                                        'ملاحظة المعقب: $adminNote',
                                        style: const TextStyle(
                                          color: Colors.indigo,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (widget.isExpediter) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () => _openWhatsApp(
                                            context,
                                            phone,
                                            serviceName,
                                          ),
                                          icon: const Icon(
                                            Icons.chat,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            'واتساب',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.green.shade600,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: () => _editPrice(
                                            context,
                                            docId,
                                            price,
                                          ),
                                          icon: const Icon(
                                            Icons.payments_outlined,
                                            size: 16,
                                            color: Colors.teal,
                                          ),
                                          label: const Text(
                                            'تسعير',
                                            style:
                                                TextStyle(color: Colors.teal),
                                          ),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: () => _editAdminNote(
                                            context,
                                            docId,
                                            adminNote,
                                          ),
                                          icon: const Icon(
                                            Icons.edit_note,
                                            size: 16,
                                            color: Colors.indigo,
                                          ),
                                          label: const Text(
                                            'ملاحظة',
                                            style:
                                                TextStyle(color: Colors.indigo),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'حذف الطلب',
                                          onPressed: () =>
                                              _confirmAndDelete(context, docId),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
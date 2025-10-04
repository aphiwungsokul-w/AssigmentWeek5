
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

final String baseUrl = kIsWeb
    ? 'http://localhost:3000/products'
    : 'http://10.0.2.2:3000/products';

class AssignmentWeek5 extends StatefulWidget {
  const AssignmentWeek5({super.key, required String title});

  @override
  State<AssignmentWeek5> createState() => _AssignmentWeek5State();
}

class _AssignmentWeek5State extends State<AssignmentWeek5> {
  bool _loading = false;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse(baseUrl));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _products = data
            .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map),
            )
            .toList();
      } else {
        _showSnack('Failed to load products (${res.statusCode})', error: true);
      }
    } catch (e) {
      _showSnack('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createOrUpdate(
    Map<String, dynamic> payload, {
    dynamic id,
  }) async {
    try {
      final uri = id == null ? Uri.parse(baseUrl) : Uri.parse('$baseUrl/$id');
      final res = await (id == null
          ? http.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
          : http.put(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            ));

      if (res.statusCode == 200 || res.statusCode == 201) {
        await _fetchProducts();
        _showSnack(id == null ? 'เพิ่มสินค้าสำเร็จ' : 'แก้ไขสินค้าสำเร็จ');
      } else {
        _showSnack('บันทึกไม่สำเร็จ (${res.statusCode})', error: true);
      }
    } catch (e) {
      _showSnack('Error: $e', error: true);
    }
  }

  Future<void> _delete(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบสินค้า'),
        content: const Text('ยืนยันการลบรายการนี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await http.delete(Uri.parse('$baseUrl/$id'));
      if (res.statusCode == 200 || res.statusCode == 204) {
        await _fetchProducts();
        _showSnack('ลบรายการแล้ว');
      } else {
        _showSnack('ลบไม่สำเร็จ (${res.statusCode})', error: true);
      }
    } catch (e) {
      _showSnack('Error: $e', error: true);
    }
  }

  void _openForm({Map<String, dynamic>? product}) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormPage(product: product)),
    );
    if (result == null) return;
    await _createOrUpdate(result, id: product?['id']);
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 213, 247, 255),
      appBar: AppBar(
        title: const Text('Product'),
        backgroundColor: const Color.fromARGB(255, 65, 166, 197),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProducts,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _products.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (context, index) {
                  final p = _products[index];
                  final name = p['name']?.toString() ?? '-';
                  final desc = p['description']?.toString() ?? '';
                  final price = (p['price'] is num)
                      ? (p['price'] as num).toDouble()
                      : double.tryParse('${p['price']}') ?? 0;
                  return ListTile(
                    
                    leading: Text(
                      '${index + 1}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: desc.isEmpty
                        ? null
                        : Text(desc, style: const TextStyle(fontSize: 12)),
                    
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          price.toStringAsFixed(0),
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          tooltip: 'แก้ไข',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _openForm(product: p),
                        ),
                        IconButton(
                          tooltip: 'ลบ',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: p['id'] == null
                              ? null
                              : () => _delete(p['id']),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class ProductFormPage extends StatefulWidget {
  final Map<String, dynamic>? product;
  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _nameCtrl.text = p['name']?.toString() ?? '';
      _descCtrl.text = p['description']?.toString() ?? '';
      _priceCtrl.text = '${p['price'] ?? ''}';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final payload = {
      "name": _nameCtrl.text.trim(),
      "description": _descCtrl.text.trim(),
      "price": price,
    };
    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'แก้ไขสินค้า' : 'เพิ่มสินค้า')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อสินค้า'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'กรอกชื่อสินค้า' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'รายละเอียด'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ราคา'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'กรอกราคา' : null,
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ยกเลิก'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: Text(isEdit ? 'บันทึก' : 'เพิ่ม'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

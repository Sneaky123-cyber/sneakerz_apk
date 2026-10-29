import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const apiBase = 'https://black-paper-38ac.joshuamenor0123.workers.dev';

class XenditService {
  static Future<Map<String, dynamic>> createInvoice({
    required int amount,
    required String email,
    required String description,
  }) async {
    final res = await http
        .post(
          Uri.parse('$apiBase/create-invoice'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'amount': amount,
            'email': email,
            'description': description,
          }),
        )
        .timeout(const Duration(seconds: 20));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? 'Failed to create invoice');
    }
    return data;
  }

  static Future<bool> isPaid(String invoiceId) async {
    final res = await http
        .get(Uri.parse('$apiBase/payment-status?id=$invoiceId'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return false;
    return jsonDecode(res.body)['paid'] == true;
  }

  /// Ginagamit ng main.dart (web lang): binubuksan ang invoice sa bagong tab/browser.
  static Future<void> openInvoice(String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) throw Exception('Cannot open payment page');
  }

  /// Ginagamit ng main.dart: nagbabalik ng 'PAID', 'EXPIRED' o 'PENDING'.
  static Future<String> getStatus(String invoiceId) async {
    final res = await http
        .get(Uri.parse('$apiBase/payment-status?id=$invoiceId'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return 'PENDING';
    final data = jsonDecode(res.body);
    if (data is! Map) return 'PENDING';
    // Kung nagbabalik ang worker mo ng 'status', gamitin ito
    final status = data['status']?.toString().toUpperCase();
    if (status != null && status.isNotEmpty) return status;
    // Kung 'paid' lang (true/false) ang ibinabalik ng worker
    return data['paid'] == true ? 'PAID' : 'PENDING';
  }
}

class CheckoutButton extends StatefulWidget {
  final int amount;
  final String email;
  final String description;
  final VoidCallback onPaid;

  const CheckoutButton({
    super.key,
    required this.amount,
    required this.email,
    required this.description,
    required this.onPaid,
  });

  @override
  State<CheckoutButton> createState() => _CheckoutButtonState();
}

class _CheckoutButtonState extends State<CheckoutButton>
    with WidgetsBindingObserver {
  String? _invoiceId;
  Timer? _timer;
  bool _loading = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  // Pagbalik ng user sa app mula sa browser, i-check agad
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _invoiceId != null) {
      _check();
    }
  }

  Future<void> _check() async {
    if (_done || _invoiceId == null) return;
    try {
      if (await XenditService.isPaid(_invoiceId!)) {
        _done = true;
        _timer?.cancel();
        widget.onPaid();
      }
    } catch (_) {}
  }

  Future<void> _pay() async {
    setState(() => _loading = true);
    try {
      final invoice = await XenditService.createInvoice(
        amount: widget.amount,
        email: widget.email,
        description: widget.description,
      );
      _invoiceId = invoice['id'];
      _done = false;

      final ok = await launchUrl(
        Uri.parse(invoice['invoice_url']),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) throw Exception('Cannot open payment page');

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 4), (_) => _check());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Payment error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _loading ? null : _pay,
      child: _loading
          ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Text('Pay ₱${widget.amount}'),
    );
  }
}
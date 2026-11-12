import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ayx_widgets.dart';

/// Connect WhatsApp: scan a QR from the Node gateway, or request a
/// pairing code by phone number. The gateway starts with the app, so
/// while it warms up we show a waiting state — never a "start the
/// backend" message. Once WhatsApp links, we auto-advance to Home.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  bool _checking = false;
  bool _gatewayOk = false;
  String? _code;
  String? _error;
  int _tab = 0; // 0 = QR code, 1 = phone number.
  String? _qr;
  bool _qrLoading = true;
  Timer? _qrTimer;
  Timer? _meTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _checkGateway();
    _fetchQr();
    _qrTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchQr());
    _meTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkMe());
  }

  @override
  void dispose() {
    _qrTimer?.cancel();
    _meTimer?.cancel();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkGateway() async {
    setState(() => _checking = true);
    final ok = await widget.api.health();
    if (!mounted) return;
    setState(() {
      _gatewayOk = ok;
      _checking = false;
    });
  }

  Future<void> _fetchQr() async {
    final qr = await widget.api.fetchQr();
    if (!mounted) return;
    if (qr == _qr && !_qrLoading) return;
    setState(() {
      _qr = qr;
      _qrLoading = false;
    });
  }

  /// WhatsApp linked? Then leave the login screen exactly once.
  Future<void> _checkMe() async {
    if (_navigated) return;
    final me = await widget.api.fetchMe();
    if (!mounted || _navigated) return;
    if (me != null) {
      _navigated = true;
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<void> _requestCode() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      setState(() => _error = 'Enter a valid phone number with country code.');
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
      _code = null;
    });
    final code = await widget.api.requestPairingCode(phone);
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (code == null) {
        _error = 'Gateway did not answer. Please wait a moment and try again.';
      } else {
        _code = code;
      }
    });
  }

  void _continueDemo() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/icon/ayx-logo.png',
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Connect WhatsApp',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.text,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Link your WhatsApp once. Chats, status and tools stay in this app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 28),
              AyxInfoCard(
                icon: Icons.qr_code_2,
                title: 'Gateway status',
                subtitle: _checking
                    ? 'Checking…'
                    : _gatewayOk
                        ? 'Node gateway is running.'
                        : 'Gateway is starting… please wait.',
                trailing: AyxStatusPill(connected: _gatewayOk),
              ),
              const SizedBox(height: 20),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(
                    value: 0,
                    icon: Icon(Icons.qr_code_2),
                    label: Text('QR code'),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    icon: Icon(Icons.phone),
                    label: Text('Phone number'),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
              const SizedBox(height: 20),
              if (_tab == 0) _buildQrTab() else _buildPhoneTab(),
              const SizedBox(height: 28),
              const Divider(color: AppTheme.border),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _continueDemo,
                child: const Text(
                  'Continue without connecting (demo)',
                  style: TextStyle(color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _checkGateway,
                child: const Text(
                  'Recheck gateway',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrTab() {
    if (_qrLoading || _qr == null) {
      return const Column(
        children: [
          SizedBox(height: 24),
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.primary,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Starting gateway… please wait',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          ),
          SizedBox(height: 8),
        ],
      );
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: QrImageView(
            data: _qr!,
            version: QrVersions.auto,
            size: 220,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Scan with WhatsApp → Linked devices → Link a device. It will appear as “iMAyX”.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Waiting for scan…',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            setState(() => _qrLoading = true);
            _fetchQr();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh QR'),
        ),
      ],
    );
  }

  Widget _buildPhoneTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Pair with phone number',
          style: TextStyle(
            color: AppTheme.text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: AppTheme.text),
          decoration: const InputDecoration(
            hintText: 'e.g. 919876543210',
            prefixIcon: Icon(Icons.phone, color: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: _checking ? null : _requestCode,
          child: _checking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.black,
                  ),
                )
              : const Text('Get pairing code'),
        ),
        if (_code != null) ...[
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Your pairing code',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _code!,
                    style: const TextStyle(
                      color: AppTheme.text,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter this in WhatsApp → Linked devices → Link with phone number. It will appear as “iMAyX” in your linked devices.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 14),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.danger),
          ),
        ],
      ],
    );
  }
}

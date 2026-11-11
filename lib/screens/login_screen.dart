import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ayx_widgets.dart';

/// Connect WhatsApp: scan a QR from the Node gateway, or request a
/// pairing code by phone number. Falls back to a clear demo state
/// when the gateway is not running.
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

  @override
  void initState() {
    super.initState();
    _checkGateway();
  }

  @override
  void dispose() {
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
        _error =
            'Gateway did not answer. Start the Node gateway (backend/) and try again.';
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
                        : 'Gateway not reachable. Start backend/ to connect.',
                trailing: AyxStatusPill(connected: _gatewayOk),
              ),
              const SizedBox(height: 20),
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
                  prefixIcon:
                      Icon(Icons.phone, color: AppTheme.textSecondary),
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
}

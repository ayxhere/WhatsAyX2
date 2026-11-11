import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import 'settings_widgets.dart';

/// Support Development — donate via UPI or crypto to support AyX.
/// Same as the original SupportSettings. (No payment is processed by
/// the app — it only shows the addresses and opens the UPI app.)
class SupportSettingsPage extends StatelessWidget {
  const SupportSettingsPage({super.key});

  // Placeholder addresses — the user replaces these with his own.
  static const String _upiId = 'raju@upi';
  static const String _bep20 = '0x0000000000000000000000000000000000000000';
  static const String _trc20 = 'T0000000000000000000000000000000000';
  static const String _erc20 = '0x0000000000000000000000000000000000000000';

  @override
  Widget build(BuildContext context) {
    return SettingsSubPage(
      children: [
        const SettingsNote('Your support keeps AyX free and updated ❤️'),
        settingsGap(),
        const Padding(
          padding: EdgeInsets.only(left: 6),
          child: Text(
            'SUPPORT · INDIA (UPI)',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _PayCard(
          title: 'UPI',
          desc: 'India — scan or tap to pay',
          address: _upiId,
          actionLabel: 'Open UPI App',
          onAction: () => _snack(context, 'Opening UPI app for $_upiId…'),
        ),
        settingsGap(),
        const Padding(
          padding: EdgeInsets.only(left: 6),
          child: Text(
            'SUPPORT · OTHER COUNTRIES (USDT)',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _PayCard(
          title: 'USDT · BEP20',
          desc: 'BNB Smart Chain (BSC)',
          address: _bep20,
          actionLabel: 'Copy',
          onAction: () => _copy(context, _bep20),
        ),
        const SizedBox(height: 10),
        _PayCard(
          title: 'USDT · TRC20',
          desc: 'Tron network',
          address: _trc20,
          actionLabel: 'Copy',
          onAction: () => _copy(context, _trc20),
        ),
        const SizedBox(height: 10),
        _PayCard(
          title: 'USDT · ERC20',
          desc: 'Ethereum network',
          address: _erc20,
          actionLabel: 'Copy',
          onAction: () => _copy(context, _erc20),
        ),
        const SizedBox(height: 10),
        _PayCard(
          title: 'Binance — Pay directly',
          desc: 'Opens the Binance app to pay instantly',
          address: '',
          actionLabel: 'Open Binance',
          onAction: () => _snack(context, 'Opening Binance…'),
        ),
      ],
    );
  }

  void _copy(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied')),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _PayCard extends StatelessWidget {
  const _PayCard({
    required this.title,
    required this.desc,
    required this.address,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String desc;
  final String address;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(desc, style: const TextStyle(color: AppTheme.textSecondary)),
            if (address.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                address,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

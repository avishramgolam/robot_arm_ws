import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import 'models/hotline.dart';
import 'providers/hotlines_provider.dart';

/// Offline-cached directory of support services, grouped by category, with
/// tap-to-call / tap-to-text / open-website actions via url_launcher.
class HotlinesScreen extends ConsumerWidget {
  const HotlinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(hotlinesByCategoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // Reassurance banner: works offline, calls are their own choice.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.wifi_off_outlined,
                    size: 20, color: AppColors.slateDark),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This list works without internet. Calls and texts go '
                    'directly to the service — never through this app.',
                    style:
                        TextStyle(fontSize: 12.5, color: AppColors.slateDark),
                  ),
                ),
              ],
            ),
          ),
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
              child: Text(entry.key.label,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final hotline in entry.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _HotlineCard(hotline: hotline),
              ),
          ],
        ],
      ),
    );
  }
}

class _HotlineCard extends StatelessWidget {
  const _HotlineCard({required this.hotline});

  final Hotline hotline;

  // url_launcher deep links: tel: opens the dialer (user still presses call),
  // sms: opens messages pre-filled with the keyword — nothing auto-sends.
  Future<void> _call(String number) async =>
      launchUrl(Uri(scheme: 'tel', path: number));

  Future<void> _text(String number, String? keyword) async => launchUrl(
        Uri(
          scheme: 'sms',
          path: number,
          queryParameters: keyword != null ? {'body': keyword} : null,
        ),
      );

  Future<void> _open(String url) async =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(hotline.name,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.lavenderTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    hotline.region,
                    style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slateDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(hotline.description,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.inkMuted, height: 1.4)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (hotline.phone != null)
                  _ActionButton(
                    icon: Icons.call_outlined,
                    label: 'Call ${hotline.phone}',
                    color: AppColors.teal,
                    onTap: () => _call(hotline.phone!),
                  ),
                if (hotline.smsNumber != null)
                  _ActionButton(
                    icon: Icons.sms_outlined,
                    label: hotline.smsKeyword != null
                        ? 'Text ${hotline.smsKeyword} to ${hotline.smsNumber}'
                        : 'Text ${hotline.smsNumber}',
                    color: AppColors.slate,
                    onTap: () =>
                        _text(hotline.smsNumber!, hotline.smsKeyword),
                  ),
                if (hotline.website != null)
                  _ActionButton(
                    icon: Icons.public,
                    label: 'Website',
                    color: AppColors.lavender,
                    onTap: () => _open(hotline.website!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

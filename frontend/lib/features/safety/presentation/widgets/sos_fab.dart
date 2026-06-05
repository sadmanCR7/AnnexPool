import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/providers/safety_provider.dart';

class SosFab extends ConsumerWidget {
  const SosFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      heroTag: 'sos_fab',
      backgroundColor: AppTheme.errorColor,
      onPressed: () => _triggerSOS(context, ref),
      child: const Text('SOS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Future<void> _triggerSOS(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: const Text('Alert your emergency contacts and ride participants now?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SEND SOS', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(safetyServiceProvider).triggerSOS(
            locationNote: 'Quick SOS from floating button',
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOS sent — help is on the way'), backgroundColor: AppTheme.errorColor),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

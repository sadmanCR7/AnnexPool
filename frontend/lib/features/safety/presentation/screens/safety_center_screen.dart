import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/providers/safety_provider.dart';
import '../../../auth/data/providers/auth_provider.dart';

class SafetyCenterScreen extends ConsumerStatefulWidget {
  const SafetyCenterScreen({super.key});

  @override
  ConsumerState<SafetyCenterScreen> createState() => _SafetyCenterScreenState();
}

class _SafetyCenterScreenState extends ConsumerState<SafetyCenterScreen> {
  String _gender = 'Prefer not to say';
  bool _preferWomenOnly = false;
  bool _saving = false;
  bool _prefsLoaded = false;

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(safetyPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Safety Center')),
      body: prefsAsync.when(
        data: (prefs) {
          if (!_prefsLoaded) {
            _gender = prefs['gender'] ?? _gender;
            _preferWomenOnly = prefs['preferWomenOnlyRides'] == true;
            _prefsLoaded = true;
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield, color: AppTheme.primaryColor),
                          SizedBox(width: 8),
                          Text('Women Safety', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (prefs['isVerifiedFemale'] == true)
                        const Chip(
                          label: Text('Verified female rider'),
                          backgroundColor: Color(0xFFE8F5E9),
                        ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        items: const [
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                          DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
                        ],
                        onChanged: (v) => setState(() => _gender = v!),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Prefer women-only rides'),
                        subtitle: const Text('Filter and highlight women-only offers'),
                        value: _preferWomenOnly,
                        onChanged: (v) => setState(() => _preferWomenOnly = v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: AppTheme.errorColor.withValues(alpha: 0.05),
                child: ListTile(
                  leading: const Icon(Icons.sos, color: AppTheme.errorColor, size: 36),
                  title: const Text('Emergency SOS', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Instantly alert emergency contacts and ride participants'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _confirmSOS(context),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : () => _save(prefs),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Safety Preferences'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _save(Map<String, dynamic> prefs) async {
    setState(() => _saving = true);
    try {
      await ref.read(safetyServiceProvider).updatePreferences({
        'gender': _gender,
        'preferWomenOnlyRides': _preferWomenOnly,
        'emergencyContacts': prefs['emergencyContacts'],
      });
      ref.invalidate(safetyPreferencesProvider);
      ref.read(authStateProvider.notifier).restoreSession();
      if (mounted) {
        setState(() => _prefsLoaded = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Safety preferences saved')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmSOS(BuildContext context) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trigger SOS?'),
        content: const Text(
          'This will notify your emergency contacts and anyone on your active ride.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send SOS', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;

    try {
      await ref.read(safetyServiceProvider).triggerSOS(
            locationNote: 'SOS triggered from Safety Center',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS alert sent successfully'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

import 'package:flutter/material.dart';

import 'package:zentask/providers/app_lock_controller.dart';
import 'package:zentask/providers/auth_controller.dart';
import 'package:zentask/services/security/data_privacy_service.dart';
import 'package:zentask/services/security/hive_encryption_service.dart';

/// Security & Privacy (Phase 12): biometric app lock, at-rest encryption,
/// cloud session management, and local data deletion — all in one
/// screen reachable from Settings.
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final AppLockController _appLock = AppLockController.instance;
  final AuthController _auth = AuthController.instance;
  final HiveEncryptionService _encryptionService = HiveEncryptionService();
  final DataPrivacyService _privacyService = const DataPrivacyService();

  bool? _biometricAvailable;
  bool _encryptionEnabled = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _appLock.addListener(_handleChanged);
    _auth.addListener(_handleChanged);
    _loadStatus();
  }

  void _handleChanged() => setState(() {});

  @override
  void dispose() {
    _appLock.removeListener(_handleChanged);
    _auth.removeListener(_handleChanged);
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final available = await _appLock.isBiometricAvailable();
    final encrypted = await _encryptionService.isEnabled();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _encryptionEnabled = encrypted;
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleAppLock(bool value) async {
    if (value && _biometricAvailable != true) {
      _showSnackBar('No biometrics or device passcode is available on this device.');
      return;
    }
    if (value) {
      final authenticated = await _appLock.authenticate(
        reason: 'Authenticate to enable App Lock',
      );
      if (!authenticated) {
        _showSnackBar('Authentication failed — App Lock was not enabled.');
        return;
      }
    }
    await _appLock.setEnabled(value);
  }

  Future<void> _enableEncryption() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable encryption?'),
        content: const Text(
          'ZenTask will encrypt all of its local data at rest. This takes a '
          'few seconds and requires restarting the app immediately '
          'afterward — please don\'t close the app until the restart '
          'prompt appears.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await _encryptionService.enableEncryption();
      if (!mounted) return;
      setState(() {
        _encryptionEnabled = true;
        _busy = false;
      });
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Restart required'),
          content: const Text(
            'Encryption is now enabled. Please close and reopen ZenTask to '
            'finish switching over.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showSnackBar('Could not enable encryption: $e');
    }
  }

  Future<void> _signOutEverywhere() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out everywhere?'),
        content: const Text(
          'This ends your session on every device signed in to this '
          'account, not just this one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out everywhere'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _auth.signOutEverywhere();
    _showSnackBar('Signed out everywhere.');
  }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all my data?'),
        content: const Text(
          'This permanently deletes every project, task, event, and other '
          'item stored on this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    await _privacyService.deleteAllData();
    if (!mounted) return;
    setState(() => _busy = false);
    _showSnackBar('All local data deleted. Restart ZenTask for a clean state.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security & Privacy')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Opacity(
          opacity: _busy ? 0.6 : 1,
          child: ListView(
            children: [
              const _SectionHeader('App Lock'),
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: const Text('Require biometrics to open ZenTask'),
                subtitle: Text(
                  _biometricAvailable == false
                      ? 'Not available on this device'
                      : 'Also locks again after the app has been in the '
                          'background for a while',
                ),
                value: _appLock.enabled,
                onChanged: _biometricAvailable == null ? null : _toggleAppLock,
              ),
              const Divider(),
              const _SectionHeader('Encryption'),
              ListTile(
                leading: const Icon(Icons.enhanced_encryption_outlined),
                title: const Text('Encrypt local data'),
                subtitle: Text(
                  _encryptionEnabled
                      ? 'Enabled — data on this device is encrypted at rest'
                      : 'Not enabled',
                ),
                trailing: _encryptionEnabled ? const Icon(Icons.check_circle, color: Colors.green) : null,
                onTap: _encryptionEnabled ? null : _enableEncryption,
              ),
              const Divider(),
              const _SectionHeader('Sessions'),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out everywhere'),
                subtitle: Text(
                  _auth.isSignedIn
                      ? 'Ends this account\'s session on every device'
                      : 'Sign in first to manage sessions',
                ),
                onTap: _auth.isSignedIn ? _signOutEverywhere : null,
              ),
              const Divider(),
              const _SectionHeader('Privacy'),
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined),
                title: const Text('Delete all my data'),
                subtitle: const Text('Permanently erases everything stored on this device'),
                onTap: _deleteAllData,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

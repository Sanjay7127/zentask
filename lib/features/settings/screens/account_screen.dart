import 'package:flutter/material.dart';
import 'package:zentask/providers/auth_controller.dart';
import 'package:zentask/providers/sync_controller.dart';
import 'package:zentask/services/cloud/sync_service.dart';

/// Account & Cloud Sync screen (Phase 11): email/anonymous sign-in,
/// profile, and sync status — reachable from Settings.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthController _auth = AuthController.instance;
  final SyncController _sync = SyncController.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isSignUp = false;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_handleChanged);
    _sync.addListener(_handleChanged);
  }

  void _handleChanged() => setState(() {});

  @override
  void dispose() {
    _auth.removeListener(_handleChanged);
    _sync.removeListener(_handleChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: _auth.isSignedIn ? _buildSignedIn(context) : _buildSignedOut(context),
    );
  }

  Widget _buildSignedOut(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_auth.lastError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_auth.lastError!,
                  style: TextStyle(color: colorScheme.onErrorContainer)),
            ),
          ),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _auth.isLoading ? null : _submitEmailForm,
          child: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
        ),
        TextButton(
          onPressed: () => setState(() => _isSignUp = !_isSignUp),
          child: Text(_isSignUp
              ? 'Already have an account? Sign In'
              : 'New here? Sign Up'),
        ),
        const Divider(height: 32),
        OutlinedButton.icon(
          onPressed: _auth.isLoading ? null : _auth.signInAnonymously,
          icon: const Icon(Icons.person_outline),
          label: const Text('Continue without an account'),
        ),
        const SizedBox(height: 12),
        Tooltip(
          message: 'Needs a Google OAuth client — not configured yet',
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.g_mobiledata),
            label: const Text('Sign in with Google'),
          ),
        ),
        const SizedBox(height: 12),
        Tooltip(
          message: 'Needs an Apple Developer Sign in with Apple config — not configured yet',
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.apple),
            label: const Text('Sign in with Apple'),
          ),
        ),
        if (_auth.isLoading) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }

  void _submitEmailForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (_isSignUp) {
      _auth.signUpWithEmail(email, password);
    } else {
      _auth.signInWithEmail(email, password);
    }
  }

  Widget _buildSignedIn(BuildContext context) {
    final user = _auth.currentUser!;
    _displayNameController.text = user.displayName ?? '';

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.isAnonymous ? 'Anonymous account' : (user.email ?? 'Signed in'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (!user.isAnonymous) ...[
                TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(labelText: 'Display name'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _auth.isLoading
                      ? null
                      : () => _auth.updateProfile(
                          displayName: _displayNameController.text.trim()),
                  child: const Text('Save profile'),
                ),
              ],
            ],
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.cloud_sync_outlined),
          title: const Text('Cloud Sync'),
          subtitle: Text(_syncStatusLabel(_sync.status)),
          trailing: FilledButton(
            onPressed: _sync.status == SyncStatus.syncing ? null : _sync.syncNow,
            child: const Text('Sync now'),
          ),
        ),
        if (_sync.lastError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _sync.lastError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign Out'),
          onTap: _auth.signOut,
        ),
      ],
    );
  }

  String _syncStatusLabel(SyncStatus status) {
    switch (status) {
      case SyncStatus.unavailable:
        return 'Not configured';
      case SyncStatus.idle:
        return 'Up to date';
      case SyncStatus.syncing:
        return 'Syncing…';
      case SyncStatus.offline:
        return 'Offline — will retry';
      case SyncStatus.error:
        return 'Sync failed — tap to retry';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:zentask/providers/reminder_settings_controller.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  final ReminderSettingsController _controller = ReminderSettingsController();
  TimeOfDay _testTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleChanged);
  }

  void _handleChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_handleChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickTestTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _testTime);
    if (picked != null) setState(() => _testTime = picked);
  }

  Future<void> _sendTestNotification() async {
    final now = DateTime.now();
    var scheduled = DateTime(
        now.year, now.month, now.day, _testTime.hour, _testTime.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _controller.sendTestNotification(scheduled);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Test reminder scheduled for ${_testTime.format(context)}'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final permission = _controller.permissionGranted;

    return Scaffold(
      appBar: AppBar(title: const Text('Reminder Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable Reminders'),
            subtitle:
                const Text('Task reminders will schedule OS notifications'),
            value: _controller.remindersEnabled,
            onChanged: _controller.setRemindersEnabled,
          ),
          ListTile(
            leading: Icon(
              permission == true
                  ? Icons.check_circle
                  : permission == false
                      ? Icons.cancel
                      : Icons.help_outline,
              color: permission == true
                  ? Colors.green
                  : permission == false
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
            ),
            title: const Text('Notification permission'),
            subtitle: Text(
              permission == true
                  ? 'Granted'
                  : permission == false
                      ? 'Denied — enable in system settings'
                      : 'Not available on this platform',
            ),
            trailing: permission == true
                ? null
                : TextButton(
                    onPressed: _controller.requestPermission,
                    child: const Text('Request'),
                  ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Test notification',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Time'),
            subtitle: Text(_testTime.format(context)),
            onTap: _pickTestTime,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _sendTestNotification,
              icon: const Icon(Icons.notifications_active),
              label: const Text('Send Test Notification'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Reminders use inexact scheduling and may fire a few '
              'minutes after the chosen time.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

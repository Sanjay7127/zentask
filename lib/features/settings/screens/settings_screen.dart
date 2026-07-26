import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zentask/core/app_info.dart';
import 'package:zentask/features/achievements/screens/achievements_screen.dart';
import 'package:zentask/features/focus/screens/focus_mode_screen.dart';
import 'package:zentask/features/goals/screens/goals_screen.dart';
import 'package:zentask/features/habits/screens/habits_screen.dart';
import 'package:zentask/features/labels/screens/labels_screen.dart';
import 'package:zentask/features/search/screens/advanced_search_screen.dart';
import 'package:zentask/features/settings/screens/account_screen.dart';
import 'package:zentask/features/settings/screens/reminder_settings_screen.dart';
import 'package:zentask/features/settings/screens/security_screen.dart';
import 'package:zentask/features/tasks/screens/pinned_tasks_screen.dart';
import 'package:zentask/providers/app_settings_controller.dart';
import 'package:zentask/services/calendar_sync/ics_calendar_sync_service.dart';
import 'package:zentask/services/import_export/import_export_service.dart';
import 'package:zentask/theme/accent_color.dart';

/// The Settings tab: Appearance, Notifications, Data, and About.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ImportExportService _service = JsonImportExportService();
  final IcsCalendarSyncService _icsService = IcsCalendarSyncService();
  final AppSettingsController _settings = AppSettingsController.instance;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_handleSettingsChanged);
  }

  void _handleSettingsChanged() => setState(() {});

  @override
  void dispose() {
    _settings.removeListener(_handleSettingsChanged);
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _exportJson() async {
    final json = await _service.exportToJson();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export JSON'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              json,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: json));
              if (context.mounted) Navigator.of(context).pop();
              _showSnackBar('Copied to clipboard');
            },
            child: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyJson() async {
    final json = await _service.exportToJson();
    await Clipboard.setData(ClipboardData(text: json));
    _showSnackBar('Copied to clipboard');
  }

  Future<void> _importJson() async {
    final json = await showDialog<String>(
      context: context,
      builder: (context) => const _ImportJsonDialog(),
    );

    if (json == null || json.trim().isEmpty) return;
    await _runImport(json);
  }

  Future<void> _pasteJson() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      _showSnackBar('Clipboard is empty');
      return;
    }
    await _runImport(text);
  }

  Future<void> _runImport(String json) async {
    try {
      await _service.importFromJson(json);
      _showSnackBar('Import complete');
    } catch (_) {
      _showSnackBar('Import failed — that doesn\'t look like valid ZenTask JSON');
    }
  }

  Future<void> _exportIcs() async {
    final ics = await _icsService.exportAll();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Calendar (.ics)'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(ics, style: Theme.of(context).textTheme.bodySmall),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: ics));
              if (context.mounted) Navigator.of(context).pop();
              _showSnackBar('Copied to clipboard');
            },
            child: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _importIcs() async {
    final ics = await showDialog<String>(
      context: context,
      builder: (context) => const _ImportIcsDialog(),
    );
    if (ics == null || ics.trim().isEmpty) return;
    try {
      final count = await _icsService.importFrom(ics);
      _showSnackBar('Imported $count event${count == 1 ? '' : 's'}');
    } catch (_) {
      _showSnackBar('Import failed — that doesn\'t look like a valid .ics file');
    }
  }

  void _showPrivacyPolicy() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy'),
        content: const SingleChildScrollView(
          child: Text(
            'ZenTask stores all of your data — tasks, projects, events, '
            'and settings — locally on this device using Hive, an '
            'on-device database.\n\n'
            'Nothing is sent to a server: this app makes no network '
            'requests and has no account system or analytics. Exporting '
            'or importing JSON (see Data, above) is the only way data '
            'ever leaves or enters this device, and only when you '
            'explicitly choose to copy, paste, or share it.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openGithub() {
    if (AppInfo.githubUrl.isEmpty) {
      _showSnackBar('GitHub repository not configured yet');
      return;
    }
  }

  void _reportIssue() {
    if (AppInfo.reportIssueUrl.isEmpty) {
      _showSnackBar('Issue tracker not configured yet');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Cloud'),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Account & Cloud Sync'),
            subtitle: const Text('Sign in, sync across devices'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccountScreen()),
            ),
          ),
          const Divider(),
          const _SectionHeader('Appearance'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Dark'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text('System'),
                    ),
                  ],
                  selected: {_settings.themeMode},
                  onSelectionChanged: (selection) =>
                      _settings.setThemeMode(selection.first),
                ),
                const SizedBox(height: 20),
                Text('Accent color',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: AccentColor.values
                      .map((accent) => _AccentSwatch(
                            accent: accent,
                            selected: _settings.accentColor == accent,
                            onTap: () => _settings.setAccentColor(accent),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const Divider(),
          const _SectionHeader('Productivity'),
          ListTile(
            leading: const Icon(Icons.push_pin_outlined),
            title: const Text('Pinned Tasks'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PinnedTasksScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Labels'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LabelsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Advanced Search'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdvancedSearchScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Focus Mode'),
            subtitle: const Text('Pomodoro timer and focus statistics'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FocusModeScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('Habits'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HabitsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Goals'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GoalsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('Achievements'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AchievementsScreen()),
            ),
          ),
          const Divider(),
          const _SectionHeader('Security'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Security & Privacy'),
            subtitle: const Text('App lock, encryption, sessions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SecurityScreen()),
            ),
          ),
          const Divider(),
          const _SectionHeader('Data'),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Export JSON'),
            subtitle: const Text('View all your data as JSON'),
            onTap: _exportJson,
          ),
          ListTile(
            leading: const Icon(Icons.copy_outlined),
            title: const Text('Copy JSON'),
            subtitle: const Text('Copy all your data to the clipboard'),
            onTap: _copyJson,
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Import JSON'),
            subtitle: const Text('Paste JSON to restore projects, tasks, and events'),
            onTap: _importJson,
          ),
          ListTile(
            leading: const Icon(Icons.paste_outlined),
            title: const Text('Paste JSON'),
            subtitle: const Text('Import directly from the clipboard'),
            onTap: _pasteJson,
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Export Calendar (.ics)'),
            subtitle: const Text('Task due dates, reminders, and events as a standard calendar file'),
            onTap: _exportIcs,
          ),
          ListTile(
            leading: const Icon(Icons.event_available_outlined),
            title: const Text('Import Calendar (.ics)'),
            subtitle: const Text('Paste a .ics file\'s contents to add its events'),
            onTap: _importIcs,
          ),
          const Divider(),
          const _SectionHeader('Notifications'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Reminder Settings'),
            subtitle: const Text('Permissions, test notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ReminderSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          const _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('${AppInfo.appName} ${AppInfo.version}'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy'),
            subtitle: const Text('What ZenTask does and doesn\'t do with your data'),
            onTap: _showPrivacyPolicy,
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Licenses'),
            subtitle: const Text('Open-source licenses used by this app'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppInfo.appName,
              applicationVersion: AppInfo.version,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.code_outlined),
            title: const Text('GitHub'),
            subtitle: const Text('View the source code'),
            onTap: _openGithub,
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Report Issue'),
            subtitle: const Text('Let us know about a bug or request a feature'),
            onTap: _reportIssue,
          ),
        ],
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  final AccentColor accent;
  final bool selected;
  final VoidCallback onTap;

  const _AccentSwatch({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: accent.label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Semantics(
          label: '${accent.label} accent color',
          selected: selected,
          button: true,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.color,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2)
                  : null,
            ),
            child: selected
                ? Icon(Icons.check, color: _iconColorFor(accent.color))
                : null,
          ),
        ),
      ),
    );
  }

  Color _iconColorFor(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
          ? Colors.white
          : Colors.black;
}

/// Own `StatefulWidget` so the `TextEditingController` is disposed
/// through the dialog's own lifecycle (once its exit animation actually
/// completes) rather than manually right after `showDialog` returns —
/// disposing it that early races the dialog's still-animating-out
/// route and throws "used after being disposed."
class _ImportJsonDialog extends StatefulWidget {
  const _ImportJsonDialog();

  @override
  State<_ImportJsonDialog> createState() => _ImportJsonDialogState();
}

class _ImportJsonDialogState extends State<_ImportJsonDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import JSON'),
      content: TextField(
        controller: _controller,
        maxLines: 8,
        decoration: const InputDecoration(
          hintText: 'Paste exported ZenTask JSON here',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Import'),
        ),
      ],
    );
  }
}

class _ImportIcsDialog extends StatefulWidget {
  const _ImportIcsDialog();

  @override
  State<_ImportIcsDialog> createState() => _ImportIcsDialogState();
}

class _ImportIcsDialogState extends State<_ImportIcsDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Calendar (.ics)'),
      content: TextField(
        controller: _controller,
        maxLines: 8,
        decoration: const InputDecoration(
          hintText: 'Paste .ics calendar contents here',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Import'),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

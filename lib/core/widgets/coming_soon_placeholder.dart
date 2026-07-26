import 'package:flutter/material.dart';

/// Stub shown for a bottom-nav tab whose real screen hasn't been built
/// yet. Deliberately honest about being unfinished rather than showing a
/// blank screen.
class ComingSoonPlaceholder extends StatelessWidget {
  final String label;
  final IconData icon;

  const ComingSoonPlaceholder({
    super.key,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              '$label is coming soon',
              style: textTheme.titleMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

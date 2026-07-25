import 'package:flutter/material.dart';
import 'package:zentask/widgets/app_button.dart';

class QuickAddBar extends StatelessWidget {
  final controller;
  VoidCallback onSave;
  QuickAddBar({super.key, required this.controller, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 15,
        );
    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 0, right: 0),
      child: Container(
        padding: EdgeInsets.only(top: 30, left: 30, right: 30, bottom: 30),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12, left: 12),
                child: TextField(
                  controller: controller,
                  style: bodyStyle,
                  decoration: InputDecoration(
                    filled: true, // Enables the fill color
                    fillColor: colorScheme.surfaceContainerHigh,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colorScheme.outline),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colorScheme.primary),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    hintText: "What To Do...",
                    hintStyle: bodyStyle?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            // SizedBox(width: 2),
            AppButton(
              text: "+",
              onPressed: onSave,
            ),
          ],
        ),
      ),
    );
  }
}

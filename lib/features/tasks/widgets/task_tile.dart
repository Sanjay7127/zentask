import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TaskTile extends StatelessWidget {
  final String taskname;
  final bool taskcomplete;
  Function(bool?)? onChanged;
  Function(BuildContext)? deletefunction;

  TaskTile(
      {super.key,
      required this.taskname,
      required this.taskcomplete,
      required this.onChanged,
      required this.deletefunction});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20, right: 10, left: 10),
      child: Slidable(
        startActionPane: ActionPane(
          motion: ScrollMotion(),
          children: [
            SlidableAction(
              spacing: -10,
              borderRadius: BorderRadius.circular(25),
              onPressed: deletefunction,
              backgroundColor: colorScheme.error,
              icon: Icons.delete,
            )
          ],
        ),
        endActionPane: ActionPane(
          motion: ScrollMotion(),
          children: [
            SlidableAction(
              // label:"X",
              spacing: -10,
              borderRadius: BorderRadius.circular(25),
              onPressed: deletefunction,
              backgroundColor: colorScheme.error,
              icon: Icons.delete,
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            top: 0,
            left: 25,
            right: 25,
            bottom: 5,
          ),
          child: Container(
            padding: EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 10),
            decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(25)),
            child: Row(
              children: [
                Transform.scale(
                  scale: 1.75,
                  child: Checkbox(
                    value: taskcomplete,
                    onChanged: onChanged,
                    activeColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    checkColor: colorScheme.onPrimary,
                    visualDensity: VisualDensity(vertical: 3, horizontal: 3),
                  ),
                ),
                Text(taskname,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        decoration: taskcomplete
                            ? TextDecoration.lineThrough
                            : TextDecoration.none)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

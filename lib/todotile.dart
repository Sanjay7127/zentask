import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';

class ToDoTile extends StatelessWidget {
  final String taskname;
  final bool taskcomplete;
  Function(bool?)? onChanged;
  Function(BuildContext)? deletefunction;

  ToDoTile(
      {super.key,
      required this.taskname,
      required this.taskcomplete,
      required this.onChanged,
      required this.deletefunction});

  @override
  Widget build(BuildContext context) {
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
              backgroundColor: const Color.fromARGB(255, 251, 128, 109),
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
              backgroundColor: const Color.fromARGB(255, 251, 128, 109),
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
                color: Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(25)),
            child: Row(
              children: [
                Transform.scale(
                  scale: 1.75,
                  child: Checkbox(
                    value: taskcomplete,
                    onChanged: onChanged,
                    activeColor: Color.fromARGB(255, 20, 20, 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    checkColor: Color.fromARGB(255, 255, 255, 255),
                    visualDensity: VisualDensity(vertical: 3, horizontal: 3),
                  ),
                ),
                Text(taskname,
                    style: GoogleFonts.poppins(
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

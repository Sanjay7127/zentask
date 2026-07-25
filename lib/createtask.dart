import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fulltodoapp/button.dart';

class Create extends StatelessWidget {
  final controller;
  VoidCallback onSave;
  Create({super.key, required this.controller, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, left: 0, right: 0),
      child: Container(
        padding: EdgeInsets.only(top: 30, left: 30, right: 30, bottom: 30),
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12, left: 12),
                child: TextField(
                  controller: controller,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    filled: true, // Enables the fill color
                    fillColor: Color.fromARGB(255, 250, 250, 250),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    hintText: "What To Do...",
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            // SizedBox(width: 2),
            mybutton(
              text: "+",
              onPressed: onSave,
            ),
          ],
        ),
      ),
    );
  }
}

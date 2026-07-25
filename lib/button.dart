import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class mybutton extends StatelessWidget {
  final String text;
  VoidCallback onPressed;
  mybutton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      elevation: 0,
      minWidth: 60,
      onPressed: onPressed,
      color: Color.fromARGB(255, 1, 209, 175),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
            fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fulltodoapp/database.dart';
import 'package:fulltodoapp/todotile.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:fulltodoapp/createtask.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // @override
  // void initState() {
  //     db.loaddata();
  //   super.initState();
  // }

  final mybox1 = Hive.box('mybox');
  tododatabase db = tododatabase();
  final controller1 = TextEditingController();

  void checkboxchanged(bool? value, int index) {
    setState(() {
      db.toDoList[index][1] = !db.toDoList[index][1];
      db.updatedata();
    });
  }

  void savenewtask() {
    setState(() {
      if (controller1.text != "") {
        db.toDoList.add([controller1.text, false]);
        controller1.clear();
        db.updatedata();
      }
    });
  }

  void deletetask(int index) {
    setState(() {
      db.toDoList.removeAt(index);
      db.updatedata();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 250, 250, 250),
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        title: Center(
          child: Text('\nTo Do',
              style: GoogleFonts.poppins(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0))),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Create(
            controller: controller1,
            onSave: savenewtask,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: Text('Tasks',
                        style: GoogleFonts.poppins(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 20, 20, 20))),
                  ),
                  ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: db.toDoList.length,
                    itemBuilder: (context, index) {
                      return ToDoTile(
                        taskname: db.toDoList[index][0],
                        taskcomplete: db.toDoList[index][1],
                        onChanged: (value) => checkboxchanged(value, index),
                        deletefunction: (context) => deletetask(index),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

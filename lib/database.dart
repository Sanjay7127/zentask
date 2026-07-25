import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class tododatabase {
  List toDoList = [
  ];

  final mybox1 = Hive.box('mybox');

  // void createinitialdata() {
  //   toDoList = [
  //     ["Your Tasks Will Look Like This", false],
  //     ["You Can Swipe To Delete", false]
  //   ];
  // }

  void loaddata() {
    toDoList = mybox1.get("TODOLIST");
  }

  void updatedata() {
    mybox1.put("TODOLIST", toDoList);
  }
}

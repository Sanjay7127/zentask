import 'package:flutter/material.dart';
import 'package:zentask/features/ai_planner/screens/ai_planner_screen.dart';
import 'package:zentask/features/tasks/widgets/quick_add_bar.dart';
import 'package:zentask/features/tasks/widgets/task_tile.dart';
import 'package:zentask/providers/task_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TaskController _controller = TaskController();
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerChanged);
  }

  void _handleControllerChanged() => setState(() {});

  void _saveNewTask() {
    _controller.addTask(_titleController.text);
    _titleController.clear();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tasks = _controller.tasks;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Center(
          child: Text('\nZenTask',
              style: textTheme.headlineMedium?.copyWith(
                  fontSize: 35, fontWeight: FontWeight.bold)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: 'AI Planner',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AIPlannerScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuickAddBar(
            controller: _titleController,
            onSave: _saveNewTask,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: Text('Tasks',
                        style: textTheme.bodyLarge?.copyWith(
                            fontSize: 25, fontWeight: FontWeight.bold)),
                  ),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return RepaintBoundary(
                        child: TaskTile(
                          taskname: task.title,
                          taskcomplete: task.isDone,
                          onChanged: (value) => _controller.toggleTask(index),
                          deletefunction: (context) =>
                              _controller.deleteTask(index),
                        ),
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

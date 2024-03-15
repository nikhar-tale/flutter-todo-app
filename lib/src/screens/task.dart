import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tasks/src/screens/logout.dart';
import 'package:flutter_tasks/src/view_models/task_view_model.dart';
import 'package:provider/provider.dart';

class Task extends StatelessWidget {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _taskController = TextEditingController();

  Task({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final taskViewModel = Provider.of<TaskViewModel>(context, listen: false);
    final User? currentUser = FirebaseAuth.instance.currentUser;

    // Get current user's profile image URL
    String? userProfileImageUrl = currentUser?.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: Text('TODO'),
        actions: [
          if (currentUser != null)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LogoutScreen()),
                );
              },
              icon: userProfileImageUrl != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(userProfileImageUrl),
                    )
                  : Icon(Icons.account_circle),
            ),
        ],
      ),
      body: StreamBuilder(
        stream: taskViewModel.getTasks(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final tasks = snapshot.data!.docs;
            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final document = tasks[index];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(document['task']),
                    subtitle: document['userName'] == null
                        ? null
                        : Text('Created by: ${document['userName']}'),
                    leading: Icon(Icons.check),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.share),
                          onPressed: () {
                            _shareTask(context, document.id, document['task']);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            _editTask(context, document.id, document['task']);
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      _editTask(context, document.id, document['task']);
                    },
                    onLongPress: () {
                      _deleteTask(context, document.id);
                    },
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => _buildAddTaskDialog(context, taskViewModel),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildAddTaskDialog(
      BuildContext context, TaskViewModel taskViewModel) {
    return AlertDialog(
      title: Text('Add Task'),
      content: TextField(
        controller: _taskController,
        decoration: InputDecoration(hintText: 'Enter your task'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _taskController.clear();
            Navigator.pop(context);
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_taskController.text.isNotEmpty) {
              taskViewModel.addTask(_taskController.text);
              _taskController.clear();
            }
            Navigator.pop(context);
          },
          child: Text('Add'),
        ),
      ],
    );
  }

  void _shareTask(BuildContext context, String taskId, String taskTitle) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Share Task'),
              content: TextFormField(
                controller: _recipientController,
                decoration: InputDecoration(
                  hintText: 'Recipient Email',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email address';
                  } else if (!isValidEmail(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {}); // Update the state when the input changes
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (_recipientController.text.isNotEmpty &&
                        isValidEmail(_recipientController.text)) {
                      _shareTaskWithRecipient(context, taskId, taskTitle);
                    }
                  },
                  child: Text('Share'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool isValidEmail(String email) {
    // Use regex to validate email format
    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _shareTaskWithRecipient(
      BuildContext context, String taskId, String taskTitle) {
    String recipientEmail = _recipientController.text;
    if (recipientEmail.isNotEmpty) {
      Provider.of<TaskViewModel>(context, listen: false)
          .shareTask(taskId, taskTitle, recipientEmail);
    }
    Navigator.pop(context);
  }

  void _editTask(BuildContext context, String taskId, String currentTask) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Task'),
          content: TextField(
            controller: _taskController..text = currentTask,
            decoration: InputDecoration(hintText: 'Enter updated task'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _taskController.clear();
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_taskController.text.isNotEmpty) {
                  Provider.of<TaskViewModel>(context, listen: false)
                      .editTask(taskId, _taskController.text);
                  _taskController.clear();
                }
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTask(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: const Text('Are you sure you want to delete this task?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<TaskViewModel>(context, listen: false)
                    .deleteTask(taskId);
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TaskViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getTasks() {
    User? user = _auth.currentUser;
    if (user != null) {
      var query = _firestore.collection('tasks').where(Filter.or(
            Filter('userId', isEqualTo: user.uid),
            Filter("collaborators", arrayContains: user.email),
          ));
      Stream<QuerySnapshot> myStream = query.snapshots();

      return myStream;
    } else {
      return Stream.empty();
    }
  }

  Future<void> addTask(
    String task,
  ) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('tasks').add({
        'userId': user.uid,
        'userName': user.displayName, // Add user's name
        'task': task,
        'timestamp': FieldValue.serverTimestamp(),
        'collaborators': [], // Initialize as empty list
      });
    }
  }

  Future<void> shareTask(
      String taskId, String taskTitle, String recipientEmail) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('tasks').doc(taskId).update({
          'collaborators': FieldValue.arrayUnion([recipientEmail]),
        });

        String subject = 'Task Sharing';
        String body = 'Check out this task: $taskTitle';
        Uri emailUri =
            Uri.parse("mailto:$recipientEmail?subject=$subject&body=$body");
        await launch(emailUri.toString());
      }
    } catch (e) {
      print("Error sharing task: $e");
    }
  }

  Future<void> editTask(String taskId, String newTask) async {
    try {
      await _firestore
          .collection('tasks')
          .doc(taskId)
          .update({'task': newTask});
    } catch (e) {
      print("Error editing task: $e");
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
    } catch (e) {
      print("Error deleting task: $e");
    }
  }

  void setUpFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received message: ${message.notification?.body}');
    });
  }
}

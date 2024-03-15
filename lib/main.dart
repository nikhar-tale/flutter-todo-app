import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_tasks/firebase_options.dart';

import 'src/screens/login.dart';
import 'src/view_models/task_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TaskViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Your App Title',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          // Add your app's theme configuration here
        ),
        // ignore: prefer_const_constructors
        home: Login(), // Set initial screen to Login
      ),
    );
  }
}
